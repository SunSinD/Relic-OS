# Tests

Run host regression checks from the repo root:

```powershell
python -W error::ResourceWarning -m unittest discover -s tests -p "test_*.py"
```

The FAT32 reader checks cover nested file extraction, data integrity, memory use and releasing the disk image. The `tosz.py` checks expand stock TempleOS `.Z` files. GitHub Actions runs these on every push.

Planned test categories:

- Host-side tool tests.
- Emulator boot smoke tests.
- Filesystem image tests.
- Compatibility tests.
- Regression tests for fixed issues.
