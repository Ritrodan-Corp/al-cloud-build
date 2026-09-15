export function startCodeLength(nal) {
  if (nal.length >= 4 && nal[0] === 0 && nal[1] === 0 && nal[2] === 0 && nal[3] === 1) return 4;
  if (nal.length >= 3 && nal[0] === 0 && nal[1] === 0 && nal[2] === 1) return 3;
  return 0;
}

export function nalType(nal) {
  const n = startCodeLength(nal);
  if (!n || nal.length <= n) return -1;
  return nal[n] & 0x1f;
}

export function codecFromSps(nal) {
  const n = startCodeLength(nal);
  if (!n || nal.length < n + 4 || (nal[n] & 0x1f) !== 7) return null;
  const h = (v) => v.toString(16).padStart(2, '0');
  return `avc1.${h(nal[n + 1])}${h(nal[n + 2])}${h(nal[n + 3])}`;
}

function findStartCode(data, from = 0) {
  for (let i = from; i + 2 < data.length; i++) {
    if (data[i] !== 0 || data[i + 1] !== 0) continue;
    if (data[i + 2] === 1) return { index: i, length: 3 };
    if (i + 3 < data.length && data[i + 2] === 0 && data[i + 3] === 1) {
      return { index: i, length: 4 };
    }
  }
  return null;
}

export class AnnexBParser {
  constructor() {
    this.buffer = new Uint8Array(0);
  }

  feed(chunk) {
    if (!(chunk instanceof Uint8Array)) chunk = new Uint8Array(chunk);
    const merged = new Uint8Array(this.buffer.length + chunk.length);
    merged.set(this.buffer, 0);
    merged.set(chunk, this.buffer.length);
    this.buffer = merged;

    const out = [];
    let first = findStartCode(this.buffer, 0);
    if (!first) {
      if (this.buffer.length > 1024 * 1024) this.buffer = this.buffer.slice(-4);
      return out;
    }
    if (first.index > 0) this.buffer = this.buffer.slice(first.index);

    let current = { index: 0, length: first.length };
    while (true) {
      const next = findStartCode(this.buffer, current.index + current.length);
      if (!next) break;
      if (next.index > current.index + current.length) {
        out.push(this.buffer.slice(current.index, next.index));
      }
      current = next;
    }
    this.buffer = this.buffer.slice(current.index);
    return out;
  }

  flush() {
    if (!this.buffer.length) return [];
    const start = findStartCode(this.buffer, 0);
    if (!start || start.index !== 0) {
      this.buffer = new Uint8Array(0);
      return [];
    }
    const last = this.buffer;
    this.buffer = new Uint8Array(0);
    return last.length > start.length ? [last] : [];
  }
}

function concatArrays(arrays) {
  const size = arrays.reduce((sum, a) => sum + a.length, 0);
  const out = new Uint8Array(size);
  let offset = 0;
  for (const a of arrays) {
    out.set(a, offset);
    offset += a.length;
  }
  return out;
}

export class AccessUnitAssembler {
  constructor() {
    this.sps = null;
    this.pps = null;
  }

  push(nal) {
    const type = nalType(nal);
    if (type === 7) {
      this.sps = nal.slice();
      return null;
    }
    if (type === 8) {
      this.pps = nal.slice();
      return null;
    }
    if (type === 5) {
      const pieces = [];
      if (this.sps) pieces.push(this.sps);
      if (this.pps) pieces.push(this.pps);
      pieces.push(nal);
      return { type: 'key', data: concatArrays(pieces) };
    }
    if (type === 1) {
      return { type: 'delta', data: nal };
    }
    return null;
  }
}
