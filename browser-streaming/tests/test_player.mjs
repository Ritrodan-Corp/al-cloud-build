import test from 'node:test';
import assert from 'node:assert/strict';
import { AnnexBParser, AccessUnitAssembler, codecFromSps, nalType } from '../web/player.js';

const sps = Uint8Array.from([0,0,0,1,0x67,0x42,0xc0,0x29,0x8d,0x68]);
const pps = Uint8Array.from([0,0,0,1,0x68,0xce,0x01,0xa8]);
const idr = Uint8Array.from([0,0,0,1,0x65,0x88,0x99]);
const p = Uint8Array.from([0,0,1,0x41,0x11,0x22]);

function join(...arrays) {
  const n = arrays.reduce((s, a) => s + a.length, 0);
  const out = new Uint8Array(n);
  let o = 0;
  for (const a of arrays) { out.set(a, o); o += a.length; }
  return out;
}

test('derives qualified codec string from SPS', () => {
  assert.equal(codecFromSps(sps), 'avc1.42c029');
  assert.equal(nalType(sps), 7);
  assert.equal(nalType(pps), 8);
  assert.equal(nalType(idr), 5);
  assert.equal(nalType(p), 1);
});

test('AnnexB parser handles arbitrary transport chunk boundaries', () => {
  const parser = new AnnexBParser();
  const stream = join(sps, pps, idr, p);
  const out = [];
  let start = 0;
  for (const cut of [2, 7, 13, 21, stream.length]) {
    out.push(...parser.feed(stream.slice(start, cut)));
    start = cut;
  }
  out.push(...parser.flush());
  assert.deepEqual(out.map(nalType), [7, 8, 5, 1]);
});

test('assembler prepends SPS/PPS to IDR and emits deltas directly', () => {
  const a = new AccessUnitAssembler();
  assert.equal(a.push(sps), null);
  assert.equal(a.push(pps), null);
  const key = a.push(idr);
  assert.equal(key.type, 'key');
  assert.deepEqual(Array.from(key.data), Array.from(join(sps, pps, idr)));
  const delta = a.push(p);
  assert.equal(delta.type, 'delta');
  assert.deepEqual(Array.from(delta.data), Array.from(p));
});
