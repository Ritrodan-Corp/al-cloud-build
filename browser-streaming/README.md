# AL Cloud browser streaming prototype

This component adds a low-overhead live browser display while preserving the existing ADB input API. It is intentionally separate from the qualified controller service until live integration is complete.

## Architecture

The server binds to `127.0.0.1:8766` by default and is intended to be reached through the same SSH/IAP local-forward model as the current controller. It never exposes ADB or the browser service publicly.

Video is a single-encode, no-remux path:

`Android screenrecord (Annex-B H.264) -> adb exec-out -> chunked HTTP -> browser fetch ReadableStream -> WebCodecs VideoDecoder -> canvas`

The exact ReDroid Android 14 `screenrecord` binary was verified to accept the hidden `--output-format=h264` option and produce Annex-B H.264 on stdout. The qualified 854x480 probe began with SPS/PPS/IDR, used codec `avc1.42c029`, and then emitted one VCL NAL per coded picture. No host `ffmpeg` dependency is required.

Existing controller endpoints are retained: `/tap`, `/swipe`, `/key`, `/text`, `/settings`, `/appinfo`, `/density`, and `/screen.png`. `/launch`, `/api/status`, and `/stream.h264` are added.

Only one live H.264 client is allowed at once. Closing, refreshing, or hiding the browser tab aborts the HTTP stream so the host-side adb/screenrecord process can terminate. A second concurrent stream receives HTTP 409 rather than starting a second encoder.

If WebCodecs is unavailable, the page falls back to the existing PNG screenshot path. Live H.264 requires a secure context; loopback `http://localhost` / `http://127.0.0.1` reached through a local tunnel qualifies in modern browsers.

## Development tests

No third-party Python or Node packages are required.

```sh
python3 -m unittest discover -s browser-streaming/tests -p 'test_server.py'
node --test browser-streaming/tests/test_player.mjs
python3 -m py_compile browser-streaming/azl_stream_server.py
```

## Prototype deployment

For the first live integration, leave `azl-control-exp157.service` untouched on port 8765. Copy this directory to `/opt/al-cloud/browser-streaming`, install `systemd/azl-stream-prototype.service`, and expose only port 8766 through an SSH/IAP local forward. After browser latency, reconnect behavior, process cleanup, and input-to-visible-response are qualified, the streaming implementation can replace or be merged into the 8765 controller service.

The persistent Android display configuration should remain at its verified default until an explicit performance experiment changes it. The 854x480 value here controls only the encoder output size; it does not change Android's logical display size.

## Configuration

Environment variables:

- `AZL_BIND` default `127.0.0.1`
- `AZL_PORT` default `8766`
- `AZL_SERIAL` default `127.0.0.1:5555`
- `AZL_ADB` default `adb`
- `AZL_INPUT_WIDTH` / `AZL_INPUT_HEIGHT` defaults `1280` / `720`
- `AZL_VIDEO_SIZE` default `854x480`
- `AZL_VIDEO_BITRATE` default `2000000`
- `AZL_STREAM_TIME_LIMIT` default `0` (unlimited)
- `AZL_STREAM_READ_SIZE` default `65536`
- `AZL_WEB_ROOT` defaults to the sibling `web` directory
