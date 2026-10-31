# Changelog

## [0.5.0] - 2026-10-31

### Added
- Matte-black desktop with the blue Reaper wallpaper, a bottom taskbar (Browser
  and Files pinned) and a searchable Start menu behind the TempleOS logo.
- Sharp pixel icons built from Fluent UI System Icons (`tools/relic_icons.py`).
- New apps: Browser (plain HTTP), Paint, Calculator, Calendar, Notes and Settings.
  Files and Help were redone; Help keeps the full Terry A. Davis tribute.
- Networking (TinkerOS PCNet driver and IPv4 stack) with DHCP, DNS and HTTP.
- Games library with 28 games: DOOM (TOOM), Tetris, Scorch, Sudoku and Chess
  (TinkerOS ports) and the TempleOS games.
- Loading screen and automatic boot to the desktop. Esc during boot opens recovery.
- VMware mouse integration (no capture needed on the desktop).
- `help` in the shell lists common commands.
- Experimental 1080p platform build in `src/platform/` (YDE/ZealOS based, not in the ISO).

### Fixed
- DOOM mouse turning in VMware: the game switches to relative mouse while it runs.
- About 75 FPS desktop refresh instead of 30.
- Missing files in the ISO build list, save checks, bounds checks in the file,
  image, DNS and settings code.

---

## [0.4.0] - 2026-10-30

First public release with a downloadable ISO. Tested in VMware Workstation (install and live CD) and QEMU (fresh install, boot from disk, DOOM).

### Added
- `tools/relic.ps1`: one script for the dev loop (`dev`), VM control, screenshots and hands-free ISO builds (`iso`). Replaces `build-iso.ps1` and `run-vmware.ps1`.
- `tools/vnc.py`: VNC client so the host can screenshot the guest and send keys.
- `tools/tosz.py`: expands TempleOS `.Z` files on the host so the stock sources can be read.
- GitHub Actions also runs the host tool tests.
- `tools/fat32img.py`: writes the FAT32 transfer disk without mounting anything in Windows (`--marker` adds `RelicDev.TXT`).
- `src/relic/HomeSys.HC`: the boot script is now a real file (was a string inside `Build.HC`). It syncs fresh sources from the transfer disk at boot.
- `src/relic/RelicStartUp.HC`: `UserStartUp`, `SrvStartUp` and the boot sequence.
- `src/relic/RelicInstall.HC`: live CD install prompt and `RelicBuild;`.
- `wallpaper.raw` is tracked in git (it was ignored, so a fresh clone could not build).
- `src/relic/RelicDisplay.HC`: fast display for virtual machines. VMs emulate TempleOS's planar VGA by trapping every write (one full-screen update measured 270 ms in VMware), which capped anything moving at 4-10 fps. Frames now go to a linear framebuffer: VMware SVGA II (VMware, VirtualBox VBoxSVGA, QEMU -vga vmware) or Bochs VBE (QEMU -vga std, VirtualBox VBoxVGA). DOOM runs at 30 fps while moving (was ~9). At boot it times one full-screen update both ways and keeps the faster one (logged in Boot.LOG). Plain VGA elsewhere; `::/Home/RelicNoSVGA.TXT` turns it off; Ctrl+Alt+V switches back to VGA (also inside the debugger, to see crash screens).
- DOOM keyboard controls: Left/Right arrows turn, A/D strafe, Ctrl fires (the mouse works too).
- Boot log `::/Home/Boot.LOG`, readable from the host with `tools\relic.ps1 log`.
- `tools\relic.ps1 shot` captures the VMware window itself (VMware's VNC misreports moving frames).
- Dev VM uses 4 vCPUs (TOOM renders on all cores).

### Changed
- Version shown in the OS is V0.4.0 (was V1.0.0; RelicOS is pre-release until 1.0).
- Games menu lists games only (no control hints).
- VM config sets `mks.gamingMouse.policy = "gaming"` so VMware sends raw mouse motion (DOOM mouse look).
- The ISO no longer ships the unused 28 MB `freedoom1.wad` (DOOM uses `doom1.wad`).
- `NOTICE.md` lists the third-party parts (TempleOS, TOOM, DOOM shareware data, Freedoom) and their terms.

### Fixed
- Titanium crashed (General Protection in `SpriteSize`) a few seconds into a game. Stock TempleOS bug: one sprite in `Titanium.HC.Z` (`CIA_neeger_imgs[3]`) has garbage where its end marker should be, so drawing it ran off the end. It only draws when a blinking CIA unit is on screen, which made the crash look random. The Games menu loads Titanium, repairs those bytes, then starts it. No other sprite in the TempleOS tree has this problem (all 262 checked with `tools/tosz.py`).
- DOOM mouse look did nothing: TOOM re-centred the mouse with `MsSet` every frame, but the window manager adds mouse packets just before DOOM reads them, so the re-centre erased every movement (the cursor only moved in the Esc menu, and the view jumped on resume). DOOM now turns by the change in the raw hardware position and keeps the cursor centred through `ms.offset`, which never touches the hardware state.
- DOOM could crash at level start (General Protection in `DCDepthBufRst`): the screen-melt effect wrote up to 3 rows past the bottom of the screen buffer and overwrote whatever came next in memory (here, the camera).
- Text from the stock games (Titanium's intro, scores) was black on black.
- Files listed the last game's folder instead of Home after playing a game.
- If the desktop task was ever killed, the status bar kept calling its freed code every frame. It now hands the stock wallpaper back when the task ends.
- The display driver patches two kernel routines with interrupts off, so a task switch can never run a half-patched instruction.
- `Build.HC`: probing an unmounted drive letter no longer stops the build; a failed build tells the host at once instead of after a 30 minute timeout; leftover dev files are not shipped in the ISO.
- A compile error in the Relic start-up code dropped the machine into the kernel debugger at boot. HomeSys now loads RelicStartUp.HC so that errors are caught (boot-phase compile errors normally go straight to the debugger) and opens a plain terminal instead.
- Relic Shell and the install screen wrap long lines instead of scrolling the text sideways.
- DOOM fired on its own and could not turn: the mouse click VMware passes through when you grab the mouse counted as a held trigger. The mouse button now only counts after it has been seen released.
- DOOM in-game colours were almost all grey: earlier commits had cut TOOM's 2-colour dithering down to 16 flat colours. Restored it and added a saturation/brightness boost so Doom's muted browns and greens survive the 16-colour palette. The light table keeps 2-colour mixes for coloured surfaces and uses 4-pixel grey blocks for grey ones, so ceilings and floors keep their detail in shadow. Its distance limit (I16_MAX) was also too small.
- DOOM frames are shown from a front buffer filled at the end of each frame, so no half-drawn frames; never-drawn edge pixels keep their previous colour like stock TOOM.
- DOOM picture was drawn 8 px low, cutting off the bottom of the HUD.
- Building the ISO no longer rewrites `/Kernel.BIN.C` and `/0000Boot/*` on the build machine (that made the build VM unbootable).
- Every `catch` sets `catch_except`; a typo in the Shell no longer kills it.
- `RelicTermNew` reuses the terminal doc instead of leaking a new one per app launch.
- Boot menu reads "RelicOS Boot Loader" on installed systems; the Shift+F1 help file name is kept.
- `relic.ps1 iso` resets the transfer disk to dev mode afterwards (a later `start` rebuilt the ISO).
- New VMs keep the transfer disk disconnected during installation so the installer selects the system disk.
- Fresh ISO installs no longer inherit the build VM dev-sync flag or boot log.
- Dev sync searches only FAT32 hard disks, avoiding empty CD drives.
- FAT32 extraction reads only matching files, bounds memory use and closes the image.
- Host VM control checks errors before rewriting disks; starting an active VM sends no keys.
- Desktop crashed on every boot with "Undefined Extern": `GamesLauncher.HC` re-declared already-defined functions as `extern`.
- Pink DOOM screen: `ToI64(x) - U8` is unsigned in HolyC, so every colour distance was ~1e19 and almost every DOOM colour mapped to LTRED.
- Invisible popups (demo games looked frozen): `SrvStartUp` was missing from HomeSys.
- SysInfo drive list had bright bars for RAM/CD drives.
- Relic Shell input limit raised from 255 to 1023 characters.

---

## [0.3.0] - 2026-05-23

### Added
- `RelicShellTaskMain`: Shell runs in an independent task with dark terminal chrome.
- `RelicDesktopRefresh`: lightweight redraw after spawning Shell/Games without full doc reset.
- `freedoom1.wad` in `src/relic/TOOM/` for TOOM testing (Freedoom IWAD).
- `docs/CONTINUATION.md`: handoff prompt and VM workflow for resuming development.

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
