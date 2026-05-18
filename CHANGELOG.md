# Changelog

All notable changes to Relic OS are recorded here.
Each entry marks a point where Relic OS diverges from the TempleOS baseline.

---

## [0.2.0] - 2025-05-18

### Added
- `src/relic/RelicDesktop.HC` - Full desktop environment with dark dock launcher,
  inline app execution, and custom wallpaper rendering.
- `src/relic/RelicTheme.HC` - Custom 16-color dark palette replacing TempleOS defaults.
- `src/relic/RelicWallpaper.HC` - Raw bitmap wallpaper loader (640x480, 16-color).
- `src/relic/RelicBoot.HC` - Boot orchestrator that chains theme, wallpaper, and desktop.
- Desktop dock with 9 buttons: Files, Editor, Shell, Mount, Tasks, Memory,
  SysInfo, Help (Terry Davis tribute), and Exit.
- Live date/time display in custom top bar overlay.
- Interactive mini-shell with `exit` command to return to desktop.
- System info panel showing OS version, CPU, and disk reports.
- Terry Davis tribute/autobiography in the Help section.

### Changed
- Desktop uses `draw_it` callback for continuous wallpaper and dock rendering.
- All apps run inline in the desktop task (no Spawn/multi-window issues).
- Top bar paints over kernel status line for a clean look.
- Removed all TempleOS chrome: borders, menus, AutoComplete popups.

### Technical
- `SettingsPush`/`SettingsPop` for clean environment management.
- `WinBorder(OFF)` and `AutoComplete(OFF)` to suppress system UI.
- `GrPaletteSet()` for global 16-color palette customization.
- `GrBlot()` for raw wallpaper blitting from pre-loaded CDC.

---

## [0.1.0] - Initial Setup

### Added
- `src/relic/HelloRelicOS.HC` - First Relic OS HolyC source file. Prints a
  Relic OS greeting to confirm the fork is running.
- `docs/relic-os-identity.md` - Formal declaration of Relic OS as an
  independent project.
- `tools/build-iso.ps1` - Stub: future script to repack source into a
  bootable RedSea ISO.
- `tools/run-vmware.ps1` - Stub: future script to launch VMware with the
  built ISO.
- `tools/extract-redsea.ps1` - Stub: future script to unpack a RedSea ISO
  into `src/templeos`.
- `CHANGELOG.md` - This file. Tracks every divergence from TempleOS.

### Notes
- TempleOS source baseline imported under `src/templeos/`. Treated as a raw,
  read-only import for now. No TempleOS files have been modified.
- `.HC.Z` files remain in original compressed form. A decompression tool is
  a near-term priority (see `tools/`).

---

## Baseline

TempleOS V5.03 source imported from the original ISO.
Original author: Terry A. Davis.
Relic OS is an independent fork. TempleOS code is in the public domain.
