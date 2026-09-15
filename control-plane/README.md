# AL Cloud control plane

This is the timer/wake control plane for Azur Lane Cloud. It is intentionally separate from the existing `alvmgetter` Cloudflare Worker, which must remain unchanged because it owns the Oracle A1 retry job.

## Purpose

The Worker stores arbitrary future wake events in one SQLite-backed Durable Object and keeps one Cloudflare alarm pointed at the earliest runnable event. When an alarm fires it processes every due event, then moves the alarm to the next event.

The scheduler contains no game intelligence. ChatGPT/AL Cloud decides why and when to wake; this component only stores, fires, retries, cancels, lists, and acknowledges wake events.

## HTTP API

`GET /health` is public and returns service/version information.

Every `/v1/*` route requires `Authorization: Bearer <CONTROL_TOKEN>`.

- `GET /v1/status` - scheduler status and next physical alarm.
- `GET /v1/wakes` - list stored wake events.
- `POST /v1/wakes` - schedule a wake. JSON body: `{ "at": "2026-09-15T22:42:00-07:00", "reason": "commission", "payload": {} }`.
- `GET /v1/wakes/:id` - inspect one wake.
- `DELETE /v1/wakes/:id` - cancel a pending wake.
- `POST /v1/wakes/:id/ack` - acknowledge a fired wake.

`at` must be epoch milliseconds or an ISO-8601 timestamp that includes `Z` or an explicit UTC offset. Wake events may be scheduled up to 366 days ahead.

## Wake transports

`WAKE_MODE=log` is the safe default. Due events are written to Worker logs and marked fired.

`WAKE_MODE=github` posts an `ALCLOUD_WAKE` comment to the dedicated long-lived wake-bus pull request, currently `Ritrodan-Corp/al-cloud-build#4`, using the GitHub Issues comments API. Required configuration:

- Worker secret `GITHUB_TOKEN`: fine-grained token able to write pull-request/issue comments in `Ritrodan-Corp/al-cloud-build`.
- Worker variable `WAKE_REPO`: defaults to `Ritrodan-Corp/al-cloud-build`.
- Worker variable `WAKE_ISSUE_NUMBER`: currently `4` and committed in `wrangler.jsonc`.

The GitHub build integration does not grant runtime API credentials to Worker code. Do not reuse or modify the `alvmgetter` Worker's token; give this Worker its own least-privilege token.

A wake comment includes a stable `event_id`. Delivery is designed to be at least once: failures are retried with bounded exponential backoff, so downstream Work logic should deduplicate by `event_id` before performing game actions.

## Cloudflare deployment

Create a **new** Worker, suggested name `al-cloud-control`, from the existing GitHub repository:

- Repository: `Ritrodan-Corp/al-cloud-build`
- Production branch during prototyping: `vm-control`
- Root directory: `control-plane/`
- Deploy command: `npx wrangler deploy`

Cloudflare Builds is configured so the production trigger includes only `vm-control`; the non-production trigger excludes `vm-control`. This prevents a `vm-control` push from starting both production and preview deployments.

The `wrangler.jsonc` file is the source of truth. It declares one SQLite-backed Durable Object, `WakeScheduler`, using Cloudflare's current declarative `exports` configuration.

After the Worker exists, set `CONTROL_TOKEN` as a Worker secret before using `/v1/*`.

## Local commands

```sh
npm install
npm run check
npm run dev
npm run deploy
```

For local development, place secrets in `.dev.vars` and do not commit that file.

## Initial proof

1. Deploy with `WAKE_MODE=log` and confirm `/health`.
2. Set `CONTROL_TOKEN`.
3. Schedule a wake a few minutes in the future and verify it becomes `fired`.
4. Add this Worker's own GitHub token and switch `WAKE_MODE` to `github`.
5. Schedule another wake and verify the Worker posts an `ALCLOUD_WAKE` comment to PR #4.
6. Configure ChatGPT Work to trigger on wake-bus PR activity and acknowledge the event.

No Android VM or Azur Lane process is required for this proof.
