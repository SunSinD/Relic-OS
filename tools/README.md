# Tools

| File | Purpose |
|------|---------|
| `relic.ps1` | Main entry point: `dev`, `prepare`, `start`, `stop`, `shot`, `log`, `iso`, `extract`, `newvm`. See `docs/vmware-workflow.md`. |
| `fat32img.py` | Creates the FAT32 transfer disk from `src/relic/` and pulls `ISO.P*` chunks back out. |
| `tosz.py` | Expands a TempleOS `.Z` file so stock sources can be read on the host: `python tools/tosz.py src/templeos/Apps/Titanium/Titanium.HC.Z out.HC`. |
| `vnc.py` | Talks to the VM over VNC: `shot out.png`, `type "Dir;" --enter`, `key Escape`, `key Ctrl+Alt+t`. `shot` needs Pillow (`pip install pillow`). |
