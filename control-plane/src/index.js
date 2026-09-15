import { DurableObject } from "cloudflare:workers";

const SERVICE = "al-cloud-control";
const VERSION = "0.1.0";
const SCHEDULER_NAME = "primary";
const EVENTS_KEY = "wake-events";
const MAX_REASON_LENGTH = 500;
const MAX_PAYLOAD_BYTES = 16 * 1024;
const HISTORY_RETENTION_MS = 7 * 24 * 60 * 60 * 1000;
const MAX_SCHEDULE_AHEAD_MS = 366 * 24 * 60 * 60 * 1000;

function json(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store"
    }
  });
}

function schedulerStub(env) {
  return env.WAKE_SCHEDULER.getByName(SCHEDULER_NAME);
}

function bearerToken(request) {
  const value = request.headers.get("authorization") || "";
  if (!value.startsWith("Bearer ")) return null;
  return value.slice("Bearer ".length).trim();
}

function requireControlAuth(request, env) {
  if (!env.CONTROL_TOKEN) {
    return json({ ok: false, error: "CONTROL_TOKEN_NOT_CONFIGURED" }, 503);
  }
  const supplied = bearerToken(request);
  if (!supplied || supplied !== env.CONTROL_TOKEN) {
    return json({ ok: false, error: "UNAUTHORIZED" }, 401);
  }
  return null;
}

function internalRequest(path, request, method = request.method) {
  const headers = new Headers();
  const contentType = request.headers.get("content-type");
  if (contentType) headers.set("content-type", contentType);
  const init = { method, headers };
  if (method !== "GET" && method !== "HEAD") init.body = request.body;
  return new Request(`https://wake-scheduler.internal${path}`, init);
}

function parseWakePath(pathname) {
  const match = pathname.match(/^\/v1\/wakes\/([^/]+)(?:\/(ack))?$/);
  if (!match) return null;
  return { id: decodeURIComponent(match[1]), action: match[2] || null };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return json({ ok: true, service: SERVICE, version: VERSION });
    }

    if (!url.pathname.startsWith("/v1/")) {
      return json({ ok: false, error: "NOT_FOUND" }, 404);
    }

    const authFailure = requireControlAuth(request, env);
    if (authFailure) return authFailure;

    const stub = schedulerStub(env);

    if (url.pathname === "/v1/status" && request.method === "GET") {
      return stub.fetch(new Request("https://wake-scheduler.internal/status"));
    }

    if (url.pathname === "/v1/wakes") {
      if (request.method === "GET") {
        return stub.fetch(new Request("https://wake-scheduler.internal/wakes"));
      }
      if (request.method === "POST") {
        return stub.fetch(internalRequest("/wakes", request, "POST"));
      }
      return json({ ok: false, error: "METHOD_NOT_ALLOWED" }, 405);
    }

    const wake = parseWakePath(url.pathname);
    if (wake) {
      const encodedId = encodeURIComponent(wake.id);
      if (!wake.action && request.method === "GET") {
        return stub.fetch(new Request(`https://wake-scheduler.internal/wakes/${encodedId}`));
      }
      if (!wake.action && request.method === "DELETE") {
        return stub.fetch(new Request(`https://wake-scheduler.internal/wakes/${encodedId}`, { method: "DELETE" }));
      }
      if (wake.action === "ack" && request.method === "POST") {
        return stub.fetch(new Request(`https://wake-scheduler.internal/wakes/${encodedId}/ack`, { method: "POST" }));
      }
      return json({ ok: false, error: "METHOD_NOT_ALLOWED" }, 405);
    }

    return json({ ok: false, error: "NOT_FOUND" }, 404);
  }
};

export class WakeScheduler extends DurableObject {
  constructor(ctx, env) {
    super(ctx, env);
    this.ctx = ctx;
    this.env = env;
  }

  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname === "/status" && request.method === "GET") {
      const events = await this.readEvents();
      const alarmAtMs = await this.ctx.storage.getAlarm();
      return json({
        ok: true,
        service: SERVICE,
        version: VERSION,
        wake_mode: this.env.WAKE_MODE || "log",
        alarm_at: alarmAtMs == null ? null : new Date(alarmAtMs).toISOString(),
        pending: events.filter((event) => event.status === "pending").length,
        fired: events.filter((event) => event.status === "fired").length,
        acknowledged: events.filter((event) => event.status === "acknowledged").length
      });
    }

    if (url.pathname === "/wakes" && request.method === "GET") {
      const events = await this.readEvents();
      return json({ ok: true, wakes: this.publicEvents(events) });
    }

    if (url.pathname === "/wakes" && request.method === "POST") {
      return this.scheduleWake(request);
    }

    const match = url.pathname.match(/^\/wakes\/([^/]+)(?:\/(ack))?$/);
    if (!match) return json({ ok: false, error: "NOT_FOUND" }, 404);

    const id = decodeURIComponent(match[1]);
    const action = match[2] || null;

    if (!action && request.method === "GET") return this.getWake(id);
    if (!action && request.method === "DELETE") return this.cancelWake(id);
    if (action === "ack" && request.method === "POST") return this.acknowledgeWake(id);
    return json({ ok: false, error: "METHOD_NOT_ALLOWED" }, 405);
  }

  async alarm() {
    const now = Date.now();
    let events = await this.readEvents();
    const runnable = events.filter(
      (event) => event.status === "pending" && event.nextAttemptAtMs <= now + 1000
    );

    for (const event of runnable) {
      try {
        const dispatch = await this.dispatchWake(event);
        event.status = "fired";
        event.firedAt = new Date().toISOString();
        event.lastError = null;
        event.dispatch = dispatch;
        console.log(`Wake ${event.id} dispatched for ${event.reason}.`);
      } catch (error) {
        event.attempts += 1;
        event.lastError = error instanceof Error ? error.message : String(error);
        const backoffMs = Math.min(30_000 * 2 ** Math.min(event.attempts - 1, 5), 15 * 60_000);
        event.nextAttemptAtMs = Date.now() + backoffMs;
        console.error(`Wake ${event.id} dispatch failed; retrying in ${backoffMs} ms: ${event.lastError}`);
      }
    }

    events = this.pruneHistory(events);
    await this.writeEvents(events);
    await this.setNextAlarm(events);
  }

  async scheduleWake(request) {
    let body;
    try {
      body = await request.json();
    } catch {
      return json({ ok: false, error: "INVALID_JSON" }, 400);
    }

    const reason = typeof body?.reason === "string" ? body.reason.trim() : "";
    if (!reason || reason.length > MAX_REASON_LENGTH) {
      return json({ ok: false, error: "INVALID_REASON", max_length: MAX_REASON_LENGTH }, 400);
    }

    const dueAtMs = this.parseDueTime(body?.at);
    if (dueAtMs == null) {
      return json({ ok: false, error: "INVALID_AT", detail: "Use an ISO-8601 timestamp with an offset or epoch milliseconds." }, 400);
    }
    if (dueAtMs > Date.now() + MAX_SCHEDULE_AHEAD_MS) {
      return json({ ok: false, error: "AT_TOO_FAR_IN_FUTURE" }, 400);
    }

    let payload = body?.payload ?? null;
    let payloadJson;
    try {
      payloadJson = JSON.stringify(payload);
    } catch {
      return json({ ok: false, error: "INVALID_PAYLOAD" }, 400);
    }
    if (new TextEncoder().encode(payloadJson).byteLength > MAX_PAYLOAD_BYTES) {
      return json({ ok: false, error: "PAYLOAD_TOO_LARGE", max_bytes: MAX_PAYLOAD_BYTES }, 413);
    }

    let events = this.pruneHistory(await this.readEvents());
    const nowIso = new Date().toISOString();
    const event = {
      id: crypto.randomUUID(),
      reason,
      payload,
      dueAt: new Date(dueAtMs).toISOString(),
      dueAtMs,
      nextAttemptAtMs: dueAtMs,
      status: "pending",
      attempts: 0,
      createdAt: nowIso,
      firedAt: null,
      acknowledgedAt: null,
      cancelledAt: null,
      lastError: null,
      dispatch: null
    };
    events.push(event);
    await this.writeEvents(events);
    await this.setNextAlarm(events);

    return json({ ok: true, wake: this.publicEvent(event) }, 201);
  }

  async getWake(id) {
    const events = await this.readEvents();
    const event = events.find((candidate) => candidate.id === id);
    if (!event) return json({ ok: false, error: "WAKE_NOT_FOUND" }, 404);
    return json({ ok: true, wake: this.publicEvent(event) });
  }

  async cancelWake(id) {
    const events = await this.readEvents();
    const event = events.find((candidate) => candidate.id === id);
    if (!event) return json({ ok: false, error: "WAKE_NOT_FOUND" }, 404);
    if (event.status !== "pending") {
      return json({ ok: false, error: "WAKE_NOT_PENDING", status: event.status }, 409);
    }

    event.status = "cancelled";
    event.cancelledAt = new Date().toISOString();
    await this.writeEvents(events);
    await this.setNextAlarm(events);
    return json({ ok: true, wake: this.publicEvent(event) });
  }

  async acknowledgeWake(id) {
    const events = await this.readEvents();
    const event = events.find((candidate) => candidate.id === id);
    if (!event) return json({ ok: false, error: "WAKE_NOT_FOUND" }, 404);
    if (event.status !== "fired" && event.status !== "acknowledged") {
      return json({ ok: false, error: "WAKE_NOT_FIRED", status: event.status }, 409);
    }

    if (event.status !== "acknowledged") {
      event.status = "acknowledged";
      event.acknowledgedAt = new Date().toISOString();
      await this.writeEvents(events);
    }
    return json({ ok: true, wake: this.publicEvent(event) });
  }

  async readEvents() {
    const stored = await this.ctx.storage.get(EVENTS_KEY);
    return Array.isArray(stored) ? stored : [];
  }

  async writeEvents(events) {
    await this.ctx.storage.put(EVENTS_KEY, events);
  }

  async setNextAlarm(events) {
    const pending = events
      .filter((event) => event.status === "pending")
      .sort((a, b) => a.nextAttemptAtMs - b.nextAttemptAtMs);
    if (pending.length === 0) {
      await this.ctx.storage.deleteAlarm();
      return;
    }
    await this.ctx.storage.setAlarm(Math.max(Date.now(), pending[0].nextAttemptAtMs));
  }

  parseDueTime(value) {
    if (typeof value === "number" && Number.isFinite(value)) {
      return Math.trunc(value);
    }
    if (typeof value !== "string" || value.trim() === "") return null;
    const trimmed = value.trim();
    if (!/(Z|[+-]\d{2}:\d{2})$/i.test(trimmed)) return null;
    const parsed = Date.parse(trimmed);
    return Number.isFinite(parsed) ? parsed : null;
  }

  pruneHistory(events) {
    const cutoff = Date.now() - HISTORY_RETENTION_MS;
    return events.filter((event) => {
      if (event.status === "pending" || event.status === "fired") return true;
      const terminalAt = Date.parse(event.acknowledgedAt || event.cancelledAt || event.createdAt);
      return !Number.isFinite(terminalAt) || terminalAt >= cutoff;
    });
  }

  publicEvents(events) {
    return events
      .slice()
      .sort((a, b) => a.dueAtMs - b.dueAtMs)
      .map((event) => this.publicEvent(event));
  }

  publicEvent(event) {
    return {
      id: event.id,
      reason: event.reason,
      payload: event.payload,
      due_at: event.dueAt,
      status: event.status,
      attempts: event.attempts,
      created_at: event.createdAt,
      fired_at: event.firedAt,
      acknowledged_at: event.acknowledgedAt,
      cancelled_at: event.cancelledAt,
      last_error: event.lastError,
      dispatch: event.dispatch
    };
  }

  async dispatchWake(event) {
    const mode = (this.env.WAKE_MODE || "log").toLowerCase();
    if (mode === "log") {
      console.log(`ALCLOUD_WAKE ${event.id} ${event.reason} due ${event.dueAt}`);
      return { mode: "log" };
    }
    if (mode !== "github") {
      throw new Error(`Unsupported WAKE_MODE: ${mode}`);
    }

    const token = this.env.GITHUB_TOKEN;
    const repo = this.env.WAKE_REPO || "Ritrodan-Corp/al-cloud-build";
    const issueNumber = Number.parseInt(this.env.WAKE_ISSUE_NUMBER || "", 10);
    if (!token) throw new Error("GITHUB_TOKEN is not configured");
    if (!Number.isInteger(issueNumber) || issueNumber <= 0) {
      throw new Error("WAKE_ISSUE_NUMBER is not configured");
    }

    const payloadText = JSON.stringify(event.payload ?? null);
    const body = [
      "ALCLOUD_WAKE",
      `event_id: ${event.id}`,
      `reason: ${event.reason}`,
      `due_at: ${event.dueAt}`,
      `payload: ${payloadText}`,
      `<!-- al-cloud-wake:${event.id} -->`
    ].join("\n");

    const response = await fetch(`https://api.github.com/repos/${repo}/issues/${issueNumber}/comments`, {
      method: "POST",
      headers: {
        Accept: "application/vnd.github+json",
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "al-cloud-control-plane"
      },
      body: JSON.stringify({ body })
    });

    if (!response.ok) {
      const detail = (await response.text()).slice(0, 1000);
      throw new Error(`GitHub wake comment failed with HTTP ${response.status}: ${detail}`);
    }

    const result = await response.json();
    return { mode: "github", comment_id: result.id, comment_url: result.html_url };
  }
}
