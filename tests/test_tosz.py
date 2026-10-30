import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from tosz import expand


class ToszTests(unittest.TestCase):
    def test_expands_stock_file(self):
        data = (ROOT / "src/templeos/Apps/Titanium/Run.HC.Z").read_bytes()
        out = expand(data)
        self.assertEqual(len(out), struct.unpack_from("<Q", data, 8)[0])
        self.assertIn(b'#include "Load"', out)

    def test_large_file_size_matches_header(self):
        data = (ROOT / "src/templeos/Apps/Titanium/Titanium.HC.Z").read_bytes()
        out = expand(data)
        self.assertEqual(len(out), struct.unpack_from("<Q", data, 8)[0])
        self.assertIn(b"U0 Titanium()", out)

    def test_rejects_non_z_data(self):
        with self.assertRaises(ValueError):
            expand(b"\x00" * 16 + b"\x09" + b"junk")


if __name__ == "__main__":
    unittest.main()
