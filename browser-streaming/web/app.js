import { AnnexBParser, AccessUnitAssembler, codecFromSps, nalType } from './player.js';

let inputWidth = 1280;
let inputHeight = 720;
let videoWidth = 854;
let videoHeight = 480;
const canvas = document.getElementById('screen');
const ctx = canvas.getContext('2d', { alpha: false, desynchronized: true });
const fallback = document.getElementById('fallback');
const statusEl = document.getElementById('status');
const statsEl = document.getElementById('stats');
const liveBadge = document.getElementById('live-badge');
const textInput = document.getElementById('text');

let streamAbort = null;
let decoder = null;
let parser = null;
let assembler = null;
let running = false;
let connecting = false;
let retryTimer = null;
let pngTimer = null;
let down = null;
let sequence = 0;
let configuredCodec = null;
let bytes = 0;
let decodedFrames = 0;
let renderedFrames = 0;
let reconnects = 0;
let lastStatsTime = performance.now();
let lastStatsFrames = 0;

function setStatus(text, kind = '') {
  statusEl.textContent = text;
  statusEl.dataset.kind = kind;
}

async function post(path, obj = {}) {
  const res = await fetch(path, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(obj),
    cache: 'no-store',
  });
  const text = await res.text();
  if (!res.ok) throw new Error(text || `${res.status}`);
  return text;
}

function xy(target, e) {
  const r = target.getBoundingClientRect();
  return [
    Math.round((e.clientX - r.left) * inputWidth / r.width),
    Math.round((e.clientY - r.top) * inputHeight / r.height),
  ];
}

function installPointerControls(target) {
  target.addEventListener('pointerdown', (e) => {
    down = xy(target, e);
    target.setPointerCapture(e.pointerId);
  });
  target.addEventListener('pointerup', async (e) => {
    if (!down) return;
    const up = xy(target, e);
    const dx = up[0] - down[0];
    const dy = up[1] - down[1];
    const start = down;
    down = null;
    try {
      if (Math.hypot(dx, dy) < 18) await post('/tap', { x: up[0], y: up[1] });
      else await post('/swipe', { x1: start[0], y1: start[1], x2: up[0], y2: up[1], ms: 350 });
    } catch (err) {
      setStatus(`Input error: ${err.message}`, 'error');
    }
  });
}

installPointerControls(canvas);
installPointerControls(fallback);

for (const button of document.querySelectorAll('[data-key]')) {
  button.addEventListener('click', () => post('/key', { key: Number(button.dataset.key) }).catch(showInputError));
}
document.getElementById('launch').addEventListener('click', () => post('/launch').catch(showInputError));
document.getElementById('settings').addEventListener('click', () => post('/settings').catch(showInputError));
document.getElementById('appinfo').addEventListener('click', () => post('/appinfo').catch(showInputError));
document.getElementById('smaller').addEventListener('click', () => post('/density', { density: 240 }).catch(showInputError));
document.getElementById('normal').addEventListener('click', () => post('/density', { density: 320 }).catch(showInputError));
document.getElementById('send-text').addEventListener('click', () => post('/text', { text: textInput.value }).catch(showInputError));
textInput.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') document.getElementById('send-text').click();
});
document.getElementById('restart').addEventListener('click', () => restartStream('manual restart'));

function showInputError(err) {
  setStatus(`Input error: ${err.message}`, 'error');
}

function closeDecoder() {
  if (decoder) {
    try { decoder.close(); } catch (_) {}
  }
  decoder = null;
  configuredCodec = null;
}

async function configureDecoderFromSps(sps) {
  if (decoder && configuredCodec) return true;
  const codec = codecFromSps(sps);
  if (!codec) throw new Error('unable to derive AVC codec from SPS');
  const config = {
    codec,
    codedWidth: videoWidth,
    codedHeight: videoHeight,
    hardwareAcceleration: 'prefer-hardware',
    optimizeForLatency: true,
  };
  const support = await VideoDecoder.isConfigSupported(config);
  if (!support.supported) throw new Error(`WebCodecs does not support ${codec}`);
  decoder = new VideoDecoder({
    output(frame) {
      decodedFrames++;
      try {
        ctx.drawImage(frame, 0, 0, canvas.width, canvas.height);
        renderedFrames++;
      } finally {
        frame.close();
      }
    },
    error(err) {
      setStatus(`Decoder error: ${err.message}`, 'error');
      if (streamAbort) streamAbort.abort();
    },
  });
  decoder.configure(support.config);
  configuredCodec = codec;
  return true;
}

async function consumeNal(nal) {
  const type = nalType(nal);
  if (type === 7) await configureDecoderFromSps(nal);
  const unit = assembler.push(nal);
  if (!unit || !decoder) return;
  if (decoder.decodeQueueSize > 12) {
    setStatus('Decoder fell behind; resyncing from a fresh keyframe…', 'warn');
    if (streamAbort) streamAbort.abort();
    return;
  }
  const timestamp = Math.round(sequence * (1_000_000 / 30));
  sequence++;
  decoder.decode(new EncodedVideoChunk({
    type: unit.type,
    timestamp,
    duration: Math.round(1_000_000 / 30),
    data: unit.data,
  }));
}

async function loadServerConfig() {
  try {
    const res = await fetch('/api/status', { cache: 'no-store' });
    if (!res.ok) return;
    const cfg = await res.json();
    if (cfg.input) {
      inputWidth = Number(cfg.input.width) || inputWidth;
      inputHeight = Number(cfg.input.height) || inputHeight;
    }
    if (cfg.video) {
      videoWidth = Number(cfg.video.width) || videoWidth;
      videoHeight = Number(cfg.video.height) || videoHeight;
      canvas.width = videoWidth;
      canvas.height = videoHeight;
    }
  } catch (_) {}
}

async function connectStream() {
  if (connecting || running || document.hidden) return;
  if (!('VideoDecoder' in window) || !window.isSecureContext) {
    startPngFallback(!window.isSecureContext ? 'WebCodecs requires a secure/loopback context' : 'WebCodecs unavailable');
    return;
  }
  connecting = true;
  await loadServerConfig();
  stopPngFallback();
  parser = new AnnexBParser();
  assembler = new AccessUnitAssembler();
  sequence = 0;
  closeDecoder();
  streamAbort = new AbortController();
  setStatus('Connecting live H.264…');
  liveBadge.textContent = 'CONNECTING';
  try {
    const res = await fetch('/stream.h264', { cache: 'no-store', signal: streamAbort.signal });
    if (!res.ok) throw new Error(`${res.status} ${await res.text()}`);
    if (!res.body) throw new Error('streaming response body unavailable');
    running = true;
    connecting = false;
    liveBadge.textContent = 'LIVE';
    setStatus('Live H.264');
    const reader = res.body.getReader();
    while (running && !document.hidden) {
      const { value, done } = await reader.read();
      if (done) break;
      bytes += value.byteLength;
      for (const nal of parser.feed(value)) await consumeNal(nal);
    }
    if (parser) {
      for (const nal of parser.flush()) await consumeNal(nal);
    }
    if (running && !document.hidden) throw new Error('stream ended');
  } catch (err) {
    if (err.name !== 'AbortError' && !document.hidden) {
      setStatus(`Stream interrupted: ${err.message}`, 'error');
    }
  } finally {
    connecting = false;
    running = false;
    liveBadge.textContent = 'OFFLINE';
    if (streamAbort) streamAbort = null;
    closeDecoder();
    if (!document.hidden) scheduleReconnect();
  }
}

function stopStream(reason = 'stopped') {
  clearTimeout(retryTimer);
  retryTimer = null;
  running = false;
  connecting = false;
  if (streamAbort) {
    streamAbort.abort();
    streamAbort = null;
  }
  closeDecoder();
  liveBadge.textContent = 'OFFLINE';
  setStatus(reason);
}

function restartStream(reason = 'restart') {
  stopStream(reason);
  reconnects++;
  setTimeout(connectStream, 150);
}

function scheduleReconnect() {
  if (retryTimer || document.hidden) return;
  reconnects++;
  retryTimer = setTimeout(() => {
    retryTimer = null;
    connectStream();
  }, 1000);
}

function startPngFallback(reason) {
  stopStream(reason);
  fallback.hidden = false;
  canvas.hidden = true;
  liveBadge.textContent = 'PNG';
  setStatus(`${reason}; using PNG fallback`, 'warn');
  const refresh = () => { fallback.src = `/screen.png?t=${Date.now()}`; };
  refresh();
  pngTimer = setInterval(refresh, 2000);
}

function stopPngFallback() {
  if (pngTimer) clearInterval(pngTimer);
  pngTimer = null;
  fallback.hidden = true;
  canvas.hidden = false;
}

async function refreshStats() {
  const now = performance.now();
  const elapsed = (now - lastStatsTime) / 1000;
  const fps = elapsed > 0 ? (renderedFrames - lastStatsFrames) / elapsed : 0;
  lastStatsTime = now;
  lastStatsFrames = renderedFrames;
  let server = null;
  try {
    const res = await fetch('/api/status', { cache: 'no-store' });
    if (res.ok) server = await res.json();
  } catch (_) {}
  const queue = decoder ? decoder.decodeQueueSize : 0;
  const parts = [
    `${fps.toFixed(1)} fps`,
    `${(bytes / 1_000_000).toFixed(1)} MB`,
    `queue ${queue}`,
    `reconnects ${reconnects}`,
  ];
  if (configuredCodec) parts.push(configuredCodec);
  if (server) parts.push(server.adb ? 'ADB up' : 'ADB down');
  statsEl.textContent = parts.join(' · ');
}

setInterval(refreshStats, 1000);
document.addEventListener('visibilitychange', () => {
  if (document.hidden) stopStream('paused while tab hidden');
  else connectStream();
});
window.addEventListener('beforeunload', () => stopStream('closing'));
connectStream();
