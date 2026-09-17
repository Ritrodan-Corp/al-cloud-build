#!/usr/bin/env python3
"""Low-overhead localhost browser streamer/controller for AL Cloud Android.

The video path is deliberately remux-free:
  Android screenrecord --output-format=h264 -> adb exec-out -> HTTP chunked stream
The browser decodes the Annex-B H.264 stream with WebCodecs.

The service binds to loopback by default and is intended to be reached through
an SSH/IAP local port forward. Existing controller endpoints are preserved.
"""

from __future__ import annotations

import json
import os
import select
import socket
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


def env_int(name: str, default: int) -> int:
    value = os.environ.get(name)
    if value is None:
        return default
    return int(value)


def parse_size(value: str) -> tuple[int, int]:
    try:
        w_s, h_s = value.lower().split("x", 1)
        w, h = int(w_s), int(h_s)
    except (ValueError, AttributeError) as exc:
        raise ValueError(f"invalid size {value!r}; expected WIDTHxHEIGHT") from exc
    if w <= 0 or h <= 0:
        raise ValueError("video dimensions must be positive")
    return w, h


SERIAL = os.environ.get("AZL_SERIAL", "127.0.0.1:5555")
ADB_BIN = os.environ.get("AZL_ADB", "adb")
ADB = [ADB_BIN, "-s", SERIAL]
BIND = os.environ.get("AZL_BIND", "127.0.0.1")
PORT = env_int("AZL_PORT", 8766)
INPUT_W = env_int("AZL_INPUT_WIDTH", 1280)
INPUT_H = env_int("AZL_INPUT_HEIGHT", 720)
VIDEO_SIZE_TEXT = os.environ.get("AZL_VIDEO_SIZE", "854x480")
VIDEO_W, VIDEO_H = parse_size(VIDEO_SIZE_TEXT)
VIDEO_BITRATE = env_int("AZL_VIDEO_BITRATE", 2_000_000)
STREAM_TIME_LIMIT = env_int("AZL_STREAM_TIME_LIMIT", 0)
STREAM_READ_SIZE = env_int("AZL_STREAM_READ_SIZE", 64 * 1024)
STREAM_STALL_TIMEOUT = env_int("AZL_STREAM_STALL_TIMEOUT_MS", 3000) / 1000.0
WEB_ROOT = Path(os.environ.get("AZL_WEB_ROOT", Path(__file__).with_name("web"))).resolve()
GAME_PACKAGE = "com.YoStarEN.AzurLane"
GAME_ACTIVITY = "com.manjuu.azurlane.MainActivity"

adb_lock = threading.Lock()
input_lock = threading.Lock()
stream_lock = threading.Lock()
stream_state_lock = threading.Lock()
stream_state = {
    "active": False,
    "started_at": None,
    "bytes_sent": 0,
    "clients_rejected": 0,
    "last_error": None,
}

STATIC = {
    "/": ("index.html", "text/html; charset=utf-8"),
    "/assets/app.js": ("app.js", "text/javascript; charset=utf-8"),
    "/assets/player.js": ("player.js", "text/javascript; charset=utf-8"),
    "/assets/style.css": ("style.css", "text/css; charset=utf-8"),
}


def ensure_adb() -> None:
    with adb_lock:
        check = subprocess.run(
            [ADB_BIN, "devices"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=5,
            check=False,
        )
        if f"{SERIAL}\tdevice" not in check.stdout:
            subprocess.run(
                [ADB_BIN, "connect", SERIAL],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=5,
                check=False,
            )
            check = subprocess.run(
                [ADB_BIN, "devices"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=5,
                check=False,
            )
            if f"{SERIAL}\tdevice" not in check.stdout:
                raise RuntimeError(f"ADB device {SERIAL} is unavailable")


def run_adb(args: list[str], *, timeout: int = 10, capture: bool = False) -> subprocess.CompletedProcess:
    ensure_adb()
    return subprocess.run(
        ADB + args,
        stdout=subprocess.PIPE if capture else subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        timeout=timeout,
        check=True,
    )


def clamp(value: int, low: int, high: int) -> int:
    return max(low, min(high, value))


def screenrecord_command() -> list[str]:
    return ADB + [
        "exec-out",
        "screenrecord",
        "--output-format=h264",
        "--size",
        VIDEO_SIZE_TEXT,
        "--bit-rate",
        str(VIDEO_BITRATE),
        "--time-limit",
        str(STREAM_TIME_LIMIT),
        "-",
    ]


def set_stream_state(**changes) -> None:
    with stream_state_lock:
        stream_state.update(changes)


def snapshot_stream_state() -> dict:
    with stream_state_lock:
        return dict(stream_state)


def adb_available() -> bool:
    try:
        ensure_adb()
        return True
    except Exception:
        return False


def cleanup_stale_screenrecord() -> None:
    subprocess.run(
        ADB + ["shell", "pkill", "-f", "^screenrecord --output-format=h264 "],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=2,
        check=False,
    )
    time.sleep(0.2)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "ALCloudStream/0.1"

    def log_message(self, fmt: str, *args) -> None:
        return

    def send_bytes(self, code: int, data: bytes, content_type: str, *, extra_headers: dict | None = None) -> None:
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        if extra_headers:
            for key, value in extra_headers.items():
                self.send_header(key, value)
        self.end_headers()
        self.wfile.write(data)

    def send_text(self, code: int, text: str, content_type: str = "text/plain; charset=utf-8") -> None:
        self.send_bytes(code, text.encode("utf-8"), content_type)

    def send_json(self, code: int, payload: dict) -> None:
        self.send_bytes(
            code,
            json.dumps(payload, separators=(",", ":")).encode("utf-8"),
            "application/json; charset=utf-8",
        )

    def read_json(self) -> dict:
        size = int(self.headers.get("Content-Length", "0"))
        if size > 64 * 1024:
            raise ValueError("request body too large")
        raw = self.rfile.read(size) if size else b"{}"
        value = json.loads(raw)
        if not isinstance(value, dict):
            raise ValueError("JSON object required")
        return value

    def serve_static(self, path: str) -> bool:
        entry = STATIC.get(path)
        if not entry:
            return False
        filename, content_type = entry
        target = (WEB_ROOT / filename).resolve()
        if target.parent != WEB_ROOT:
            self.send_text(403, "forbidden")
            return True
        try:
            data = target.read_bytes()
        except FileNotFoundError:
            self.send_text(500, f"missing web asset: {filename}")
            return True
        self.send_bytes(200, data, content_type)
        return True

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if self.serve_static(path):
            return
        if path == "/screen.png":
            try:
                png = run_adb(["exec-out", "screencap", "-p"], capture=True).stdout
                return self.send_bytes(200, png, "image/png")
            except Exception as exc:
                return self.send_text(500, f"ERROR: {exc}")
        if path == "/api/status":
            state = snapshot_stream_state()
            state.update(
                {
                    "adb": adb_available(),
                    "serial": SERIAL,
                    "input": {"width": INPUT_W, "height": INPUT_H},
                    "video": {
                        "width": VIDEO_W,
                        "height": VIDEO_H,
                        "bitrate": VIDEO_BITRATE,
                        "format": "h264-annexb",
                    },
                }
            )
            return self.send_json(200, state)
        if path == "/stream.h264":
            return self.stream_h264()
        return self.send_text(404, "not found")

    def stream_h264(self) -> None:
        if not stream_lock.acquire(blocking=False):
            with stream_state_lock:
                stream_state["clients_rejected"] += 1
            return self.send_text(409, "stream already active")

        proc: subprocess.Popen | None = None
        clean_end = False
        try:
            ensure_adb()
            cleanup_stale_screenrecord()
            set_stream_state(active=True, started_at=time.time(), bytes_sent=0, last_error=None)
            proc = subprocess.Popen(
                screenrecord_command(),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                bufsize=0,
            )
            self.send_response(200)
            self.send_header("Content-Type", "video/h264")
            self.send_header("Cache-Control", "no-store, no-transform")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("X-Azl-Stream-Format", "h264-annexb")
            self.send_header("X-Azl-Video-Size", VIDEO_SIZE_TEXT)
            self.send_header("Transfer-Encoding", "chunked")
            self.send_header("Connection", "close")
            self.end_headers()
            assert proc.stdout is not None

            sent = 0
            client_closed = False
            stdout_fd = proc.stdout.fileno()
            last_output_at = time.monotonic()
            while True:
                readable, _, _ = select.select([stdout_fd, self.connection], [], [], 0.5)

                if self.connection in readable:
                    try:
                        if self.connection.recv(1, socket.MSG_PEEK) == b"":
                            client_closed = True
                            break
                    except (BlockingIOError, InterruptedError):
                        pass
                    except OSError:
                        client_closed = True
                        break

                if stdout_fd not in readable:
                    if proc.poll() is not None:
                        clean_end = proc.returncode == 0
                        break
                    if time.monotonic() - last_output_at >= STREAM_STALL_TIMEOUT:
                        set_stream_state(last_error=f"screenrecord stalled for {STREAM_STALL_TIMEOUT:.1f}s")
                        break
                    continue

                chunk = os.read(stdout_fd, STREAM_READ_SIZE)
                if not chunk:
                    clean_end = proc.poll() == 0
                    break
                self.wfile.write(f"{len(chunk):X}\r\n".encode("ascii"))
                self.wfile.write(chunk)
                self.wfile.write(b"\r\n")
                self.wfile.flush()
                sent += len(chunk)
                last_output_at = time.monotonic()
                set_stream_state(bytes_sent=sent)

            if not client_closed:
                self.wfile.write(b"0\r\n\r\n")
                self.wfile.flush()
            if not clean_end and proc.poll() is not None:
                stderr = b""
                if proc.stderr is not None:
                    stderr = proc.stderr.read(2048)
                if stderr:
                    set_stream_state(last_error=stderr.decode("utf-8", "replace").strip())
        except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
            pass
        except Exception as exc:
            set_stream_state(last_error=str(exc))
            if not self.wfile.closed:
                try:
                    self.wfile.flush()
                except Exception:
                    pass
        finally:
            if proc is not None and proc.poll() is None:
                proc.terminate()
                try:
                    proc.wait(timeout=1.5)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    try:
                        proc.wait(timeout=1)
                    except subprocess.TimeoutExpired:
                        pass
            if proc is not None:
                subprocess.run(
                    ADB + ["shell", "pkill", "-f", "^screenrecord --output-format=h264 "],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=2,
                    check=False,
                )
            set_stream_state(active=False, started_at=None)
            stream_lock.release()
            self.close_connection = True

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        try:
            data = self.read_json()
            if path == "/tap":
                x = clamp(int(data["x"]), 0, INPUT_W - 1)
                y = clamp(int(data["y"]), 0, INPUT_H - 1)
                run_adb(["shell", "input", "tap", str(x), str(y)])
            elif path == "/touch":
                action = str(data.get("action", "")).lower()
                if action not in ("down", "move", "up", "cancel"):
                    raise ValueError("unsupported touch action")
                x = clamp(int(data["x"]), 0, INPUT_W - 1)
                y = clamp(int(data["y"]), 0, INPUT_H - 1)
                with input_lock:
                    run_adb(["shell", "input", "motionevent", action.upper(), str(x), str(y)], timeout=4)
            elif path == "/ime-hide":
                state = run_adb(["shell", "dumpsys", "input_method"], timeout=5, capture=True).stdout
                if b"mInputShown=true" in state:
                    run_adb(["shell", "input", "keyevent", "4"], timeout=4)
            elif path == "/swipe":
                x1 = clamp(int(data["x1"]), 0, INPUT_W - 1)
                y1 = clamp(int(data["y1"]), 0, INPUT_H - 1)
                x2 = clamp(int(data["x2"]), 0, INPUT_W - 1)
                y2 = clamp(int(data["y2"]), 0, INPUT_H - 1)
                ms = clamp(int(data.get("ms", 350)), 50, 3000)
                run_adb(["shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(ms)])
            elif path == "/key":
                run_adb(["shell", "input", "keyevent", str(int(data["key"]))])
            elif path == "/text":
                text = str(data.get("text", ""))[:256]
                if any(ord(c) < 32 for c in text):
                    raise ValueError("control characters not allowed")
                run_adb(["shell", "input", "text", text.replace(" ", "%s")])
            elif path == "/settings":
                run_adb(["shell", "am", "start", "-a", "android.settings.SETTINGS"])
            elif path == "/appinfo":
                run_adb(
                    [
                        "shell",
                        "am",
                        "start",
                        "-a",
                        "android.settings.APPLICATION_DETAILS_SETTINGS",
                        "-d",
                        f"package:{GAME_PACKAGE}",
                    ]
                )
            elif path == "/launch":
                run_adb(["shell", "am", "start", "-n", f"{GAME_PACKAGE}/{GAME_ACTIVITY}"])
            elif path == "/density":
                density = int(data.get("density", 320))
                if density not in (240, 280, 320):
                    raise ValueError("unsupported density")
                run_adb(["shell", "wm", "density", str(density)])
            else:
                return self.send_text(404, "not found")
            return self.send_text(200, "OK")
        except Exception as exc:
            return self.send_text(400, f"ERROR: {exc}")


def main() -> None:
    if not WEB_ROOT.is_dir():
        raise SystemExit(f"web root does not exist: {WEB_ROOT}")
    server = ThreadingHTTPServer((BIND, PORT), Handler)
    print(
        f"AL Cloud browser streamer listening on http://{BIND}:{PORT} "
        f"video={VIDEO_SIZE_TEXT}@{VIDEO_BITRATE}bps adb={SERIAL}",
        flush=True,
    )
    try:
        server.serve_forever(poll_interval=0.25)
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
