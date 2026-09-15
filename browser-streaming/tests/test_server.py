import importlib.util
import os
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "azl_stream_server.py"


def load_module(**env):
    old = os.environ.copy()
    try:
        os.environ.update(env)
        spec = importlib.util.spec_from_file_location("azl_stream_server_test", MODULE_PATH)
        module = importlib.util.module_from_spec(spec)
        assert spec.loader
        spec.loader.exec_module(module)
        return module
    finally:
        os.environ.clear()
        os.environ.update(old)


class ServerConfigTests(unittest.TestCase):
    def test_parse_size(self):
        m = load_module()
        self.assertEqual(m.parse_size("854x480"), (854, 480))
        with self.assertRaises(ValueError):
            m.parse_size("bad")
        with self.assertRaises(ValueError):
            m.parse_size("0x480")

    def test_clamp(self):
        m = load_module()
        self.assertEqual(m.clamp(-1, 0, 1279), 0)
        self.assertEqual(m.clamp(500, 0, 1279), 500)
        self.assertEqual(m.clamp(1300, 0, 1279), 1279)

    def test_screenrecord_command_is_raw_annexb_stdout(self):
        m = load_module(
            AZL_ADB="adb-test",
            AZL_SERIAL="127.0.0.1:5555",
            AZL_VIDEO_SIZE="854x480",
            AZL_VIDEO_BITRATE="2000000",
            AZL_STREAM_TIME_LIMIT="0",
        )
        self.assertEqual(
            m.screenrecord_command(),
            [
                "adb-test", "-s", "127.0.0.1:5555", "exec-out", "screenrecord",
                "--output-format=h264", "--size", "854x480", "--bit-rate", "2000000",
                "--time-limit", "0", "-",
            ],
        )

    def test_defaults_are_loopback_only(self):
        m = load_module()
        self.assertEqual(m.BIND, "127.0.0.1")
        self.assertEqual(m.SERIAL, "127.0.0.1:5555")
        self.assertEqual((m.INPUT_W, m.INPUT_H), (1280, 720))


if __name__ == "__main__":
    unittest.main()
