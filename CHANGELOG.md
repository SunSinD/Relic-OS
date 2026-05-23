# Changelog

All notable changes to Relic OS are recorded here.
Each entry marks a point where Relic OS diverges from the TempleOS baseline.

---

## [0.3.0] - 2026-05-23

### Added
- `RelicShellTaskMain` — Shell runs in an independent task with dark terminal chrome.
- `RelicDesktopRefresh` — lightweight redraw after spawning Shell/Games without full doc reset.
- `freedoom1.wad` in `src/relic/TOOM/` for TOOM testing (Freedoom IWAD).
- `docs/CONTINUATION.md` — handoff prompt and VM workflow for resuming development.

### Changed
- **Desktop top strip:** System status line (`RelicOS V1.0.0` + date/time + FPS) via `RelicChrome.HC` / `fp_wall_paper`; no version or "Desktop" text on wallpaper graphics.
- **Wallpaper:** Blitted below `TOPBAR_H` so the status strip is never covered; `DrawDesktop` calls `fp_wall_paper` after paint.
- **Shell / Games:** Spawned as sibling tasks (not `DeathWait` on desktop); removed `while (ms.lb)` click-wait that could freeze the UI.
- **Esc:** Closes child Shell/Games via `RelicChildKill`; restore no longer moves the mouse (`MsSet` removed).
- **GamesLauncher:** HolyC-safe dispatch; TOOM launched with `ExePrint("RunTOOM;")`.
- **RunTOOM.HC:** TOOM runs in a dedicated child task with WAD check and dark palette restore.
- **Build.HC:** Child-task startup branches, IWAD copy, boot-safe theme loading.
- **RelicTheme.HC:** Boot-safe palette only (no kernel drive symbol references at early boot).

### Fixed
- White terminal borders when drive-colored borders were active.
- Boot-time compile crashes (`continue`, switch braces, forward refs, `StrFirstOcc` char literals).
- Games button undefined identifier at compile time.
- DOOM black screen / VM instability from running TOOM in the desktop task.
- Dock hover stuck after Esc (redraw on restore + mouse move).
- `RelicChrome` text attribute operator precedence (`<< 4 |`).

---

## [0.2.0] - 2025-05-18

### Added
- `src/relic/RelicDesktop.HC` - Full desktop environment with dark dock launcher,
  inline app execution, and custom wallpaper rendering.
- `src/relic/RelicTheme.HC` - Custom 16-color dark palette replacing TempleOS defaults.
- `src/relic/RelicWallpaper.HC` - Raw bitmap wallpaper loader (640x480, 16-color).
- `src/relic/RelicBoot.HC` - Boot orchestrator that chains theme, wallpaper, and desktop.
- Desktop dock with 8 buttons: Files, Editor, Shell, Games, Tasks, Memory,
  SysInfo, Help (Terry Davis tribute).
- System info panel showing OS version, CPU, and disk reports.
- Terry Davis tribute/autobiography in the Help section.

### Changed
- Desktop uses `draw_it` callback for continuous wallpaper and dock rendering.
- Suppressed TempleOS menu chrome while preserving terminal borders.

### Technical
- `SettingsPush`/`SettingsPop` for clean environment management.
- `GrPaletteSet()` for global 16-color palette customization.
- `GrBlot()` for raw wallpaper blitting from pre-loaded CDC.

---

## [0.1.0] - Initial Setup

### Added
- `src/relic/HelloRelicOS.HC` - First Relic OS HolyC source file.
- `docs/relic-os-identity.md` - Formal declaration of Relic OS as an independent project.
- Tool stubs under `tools/`.
- `CHANGELOG.md` - This file.

### Notes
- TempleOS source baseline imported under `src/templeos/`. Treated as read-only.
- `.HC.Z` files remain in original compressed form.

---

## Baseline

TempleOS V5.03 source imported from the original ISO.
Original author: Terry A. Davis.
Relic OS is an independent fork. TempleOS code is in the public domain.
