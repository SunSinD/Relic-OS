import sys
import tempfile
import tracemalloc
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from fat32img import Fat32Image, _parse_existing


class Fat32ReaderTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        src = root / "source"
        (src / "Home").mkdir(parents=True)
        self.payload = bytes(range(256)) * 20
        (src / "Home" / "Boot.LOG").write_bytes(self.payload)
        (src / "other.txt").write_bytes(b"unrelated")
        self.image = root / "disk.img"
        Fat32Image(self.image, 64).create_and_fill(src, {"RelicDev.TXT": b"dev\n"})

    def test_filter_finds_nested_files_and_preserves_bytes(self):
        self.assertEqual(list(_parse_existing(self.image, "boot.log")),
                         [("Home/Boot.LOG", self.payload)])
        self.assertEqual(list(_parse_existing(self.image, "RelicDev.TXT")),
                         [("RelicDev.TXT", b"dev\n")])
        self.assertEqual(list(_parse_existing(self.image, "missing")), [])

    def test_reader_uses_bounded_memory_and_releases_image(self):
        tracemalloc.start()
        try:
            rows = _parse_existing(self.image, "Boot.LOG")
            self.assertEqual(next(rows), ("Home/Boot.LOG", self.payload))
            rows.close()
            self.assertLess(tracemalloc.get_traced_memory()[1], 8 * 1024 * 1024)
        finally:
            tracemalloc.stop()
        self.image.unlink()


if __name__ == "__main__":
    unittest.main()
