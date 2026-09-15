import { AnnexBParser, AccessUnitAssembler, codecFromSps, nalType } from './player.js';

let inputWidth = 1280;
let inputHeight = 720;
let videoWidth = 854;
let videoHeight = 480;

const stage = document.getElementById('stage');
const canvas = document.getElementById('screen');
const ctx = canvas.getContext('2d', { alpha: false, desynchronized: true });
const fallback = document.getElementById('fallback');
const statusEl = document.getElementById('status');
const statsEl = document.getElementById('stats');
const liveBadge = document.getElementById('live-badge');
const textPanel = document.getElementById('text-panel');
const textInput = document.getElementById('text');

let streamAbort = null;
let decoder = null;
let parser = null;
let assembler = null;
let running = false;
let connecting = false;
let retryTimer = null;
let pngTimer = null;
let sequence = 0;
let configuredCodec = null;
let bytes = 0;
let renderedFrames = 0;
let reconnects = 0;
let lastStatsTime = performance.now();
let lastStatsFrames = 0;
let controlsTimer = null;
let imeHideTimer = null;

let gesture = null;
let touchStartPromise = null;
let latestMove = null;
let movePumpRunning = false;

let textBuffer = '';
let textTimer = null;

function setStatus(text, kind = '') {
  statusEl.textContent = text;
  statusEl.dataset.kind = kind;
  if (kind) showControls(5000);
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

function showInputError(err) {
  setStatus(`Input error: ${err.message}`, 'error');
}

function showControls(ms = 2400) {
  stage.classList.add('controls-visible');
  clearTimeout(controlsTimer);
  if (ms > 0 && textPanel.hidden) {
    controlsTimer = setTimeout(() => stage.classList.remove('controls-visible'), ms);
  }
}

function focusStage() {
  try { stage.focus({ preventScroll: true }); } catch (_) { stage.focus(); }
}

function scheduleImeHide(delay = 100) {
  clearTimeout(imeHideTimer);
  imeHideTimer = setTimeout(() => {
    post('/ime-hide').catch(() => {});
    imeHideTimer = setTimeout(() => post('/ime-hide').catch(() => {}), 250);
  }, delay);
}

function xy(target, e) {
  const r = target.getBoundingClientRect();
  return [
    Math.max(0, Math.min(inputWidth - 1, Math.round((e.clientX - r.left) * inputWidth / r.width))),
    Math.max(0, Math.min(inputHeight - 1, Math.round((e.clientY - r.top) * inputHeight / r.height))),
  ];
}

function touchPost(action, point) {
  return post('/touch', { action, x: point[0], y: point[1] });
}

async function pumpMoves() {
  if (movePumpRunning) return;
  movePumpRunning = true;
  try {
    if (touchStartPromise) await touchStartPromise;
    while (latestMove && gesture) {
      const point = latestMove;
      latestMove = null;
      await touchPost('move', point);
    }
  } catch (err) {
    showInputError(err);
  } finally {
    movePumpRunning = false;
    if (latestMove && gesture) queueMicrotask(pumpMoves);
  }
}

function installPointerControls(target) {
  target.addEventListener('pointerdown', (e) => {
    if (e.button !== undefined && e.button !== 0) return;
    e.preventDefault();
    focusStage();
    showControls();
    const point = xy(target, e);
    gesture = { pointerId: e.pointerId, start: point, last: point };
    latestMove = null;
    touchStartPromise = touchPost('down', point).catch((err) => {
      showInputError(err);
      gesture = null;
    });
    target.setPointerCapture(e.pointerId);
  });

  target.addEventListener('pointermove', (e) => {
    showControls();
    if (!gesture || gesture.pointerId !== e.pointerId) return;
    e.preventDefault();
    const point = xy(target, e);
    gesture.last = point;
    latestMove = point;
    pumpMoves();
  });

  target.addEventListener('pointerup', async (e) => {
    if (!gesture || gesture.pointerId !== e.pointerId) return;
    e.preventDefault();
    const point = xy(target, e);
    gesture.last = point;
    latestMove = point;
    try {
      if (touchStartPromise) await touchStartPromise;
      await pumpMoves();
      while (movePumpRunning) await new Promise((resolve) => setTimeout(resolve, 1));
      await touchPost('up', point);
      scheduleImeHide(120);
    } catch (err) {
      showInputError(err);
    } finally {
      gesture = null;
      latestMove = null;
      touchStartPromise = null;
    }
  });

  target.addEventListener('pointercancel', async (e) => {
    if (!gesture || gesture.pointerId !== e.pointerId) return;
    const point = gesture.last;
    try {
      if (touchStartPromise) await touchStartPromise;
      await touchPost('cancel', point);
    } catch (_) {}
    gesture = null;
    latestMove = null;
    touchStartPromise = null;
  });
}

installPointerControls(canvas);
installPointerControls(fallback);

for (const button of document.querySelectorAll('[data-key]')) {
  button.addEventListener('click', () => {
    showControls();
    post('/key', { key: Number(button.dataset.key) }).catch(showInputError);
    focusStage();
  });
}

document.getElementById('launch').addEventListener('click', () => post('/launch').catch(showInputError));
document.getElementById('settings').addEventListener('click', () => post('/settings').catch(showInputError));
document.getElementById('restart').addEventListener('click', () => restartStream('manual restart'));

function openTextPanel() {
  textPanel.hidden = false;
  textPanel.classList.add('pinned');
  showControls(0);
  textInput.focus();
}

function closeTextPanel() {
  textPanel.hidden = true;
  textPanel.classList.remove('pinned');
  textInput.value = '';
  focusStage();
  showControls();
  scheduleImeHide();
}

document.getElementById('keyboard').addEventListener('click', openTextPanel);
document.getElementById('close-text').addEventListener('click', closeTextPanel);
document.getElementById('send-text').addEventListener('click', async () => {
  const text = textInput.value;
  if (!text) return;
  try {
    await post('/text', { text });
    textInput.value = '';
    scheduleImeHide();
  } catch (err) {
    showInputError(err);
  }
});
textInput.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    e.preventDefault();
    document.getElementById('send-text').click();
  } else if (e.key === 'Escape') {
    e.preventDefault();
    closeTextPanel();
  }
});

const keyMap = new Map([
  ['Enter', 66],
  ['Backspace', 67],
  ['Delete', 112],
  ['Escape', 4],
  ['ArrowUp', 19],
  ['ArrowDown', 20],
  ['ArrowLeft', 21],
  ['ArrowRight', 22],
  ['Tab', 61],
  ['PageUp', 92],
  ['PageDown', 93],
]);

function flushTextBuffer() {
  clearTimeout(textTimer);
  textTimer = null;
  if (!textBuffer) return;
  const text = textBuffer;
  textBuffer = '';
  post('/text', { text }).catch(showInputError);
}

function queueText(text) {
  textBuffer += text;
  if (textBuffer.length >= 24) return flushTextBuffer();
  clearTimeout(textTimer);
  textTimer = setTimeout(flushTextBuffer, 25);
}

stage.addEventListener('keydown', (e) => {
  if (document.activeElement === textInput || document.activeElement?.tagName === 'BUTTON') return;
  const code = keyMap.get(e.key);
  if (code !== undefined) {
    e.preventDefault();
    flushTextBuffer();
    post('/key', { key: code }).catch(showInputError);
    scheduleImeHide();
    return;
  }
  if (e.ctrlKey || e.metaKey || e.altKey) return;
  if (e.key.length === 1) {
    e.preventDefault();
    queueText(e.key);
    scheduleImeHide();
  }
});

stage.addEventListener('paste', (e) => {
  if (document.activeElement === textInput) return;
  const text = e.clipboardData?.getData('text') || '';
  if (!text) return;
  e.preventDefault();
  flushTextBuffer();
  post('/text', { text: text.slice(0, 256) }).catch(showInputError);
  scheduleImeHide();
});

stage.addEventListener('pointermove', () => showControls());
stage.addEventListener('pointerdown', () => showControls());
stage.addEventListener('contextmenu', (e) => e.preventDefault());

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
    setStatus('Decoder fell behind; resyncing…', 'warn');
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
    focusStage();
    showControls();
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
    `queue ${queue}`,
    `reconnects ${reconnects}`,
  ];
  if (server) parts.push(server.adb ? 'ADB up' : 'ADB down');
  statsEl.textContent = parts.join(' · ');
}

setInterval(refreshStats, 1000);
document.addEventListener('visibilitychange', () => {
  if (document.hidden) stopStream('paused while tab hidden');
  else connectStream();
});
window.addEventListener('beforeunload', () => {
  flushTextBuffer();
  stopStream('closing');
});
showControls();
connectStream();
