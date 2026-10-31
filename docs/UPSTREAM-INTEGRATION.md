# Upstream integration

RelicOS now has two development targets. They use different compilers and kernel
interfaces, so copying a HolyC app into the ZealC platform does not make it work.
No ISO was created for this development work.

| Target | Purpose | Current runtime evidence |
|---|---|---|
| `src/relic/` | Stock TempleOS/HolyC recovery baseline, 640x480 palette display | VMware desktop, apps, network and game smoke tests; 21 guest core/network checks reported passing |
| `src/platform/` | Full YDE/ZealOS source platform, 1280x720 truecolour desktop | Kernel built and booted; start menu, browser, calculator and Paint exercised; 40 JS fixtures and seven crypto vectors pass |

## Pinned research

| Repository | Revision |
|---|---|
| [YDE](https://github.com/y4my4my4m/YDE) | `ab4bc69e1e7f2a74563a4960fd1020b5c55dae4d` |
| [ZealOS](https://github.com/Zeal-Operating-System/ZealOS) | `eee210f4379ba3d00b47507f336a158eefb2c993` |
| [TinkerOS](https://github.com/tinkeros/tinkeros) | `fe68fde1f4c3c49652025656dd8f1dc5095a07ae` |

Recursive inventories, import hashes and the YDE author's game-repository
metadata are under `research/upstream/`. Adjacent `../Reference/` holds the
research source downloads. It is not a runtime dependency.

## Feature ledger

| Area | Platform | TempleOS baseline |
|---|---|---|
| Desktop | Truecolour compositor, multiwindow taskbar, search launcher, settings, original-font UI | Matte desktop, dock, app search, hover and short launcher transition |
| Startup | Automatic desktop, original-font loading screen, first terminal minimized | Installed-disk autoboot with recovery menu and loading splash |
| Browser | Zinc HTML/CSS/images/JS browser; native TCP/TLS stack | HTTP text/HTML viewer, local pages, links/history/scrolling |
| Drawing | yPainter layers, selections, brushes, undo, native layered files and image import/export | Pen/eraser, line/rectangle, undo and BMP save/load |
| Media | PNG/JPG/GIF/WebP/TGA/SVG, yViewer/yVideo, MP3/Ogg/WAV/MOD, yTracker and music player | Existing TempleOS creative tools retained |
| Utilities | File manager/editor, calculator/calendar, task/system tools, IRC/mail/Harmony | Files/editor, Notes, calculator/calendar, shell history, settings and diagnostics |
| Drivers | Imported AHCI/NVMe/USB, USB HID, RTL8139/E1000/PCNet, audio and other upstream drivers | Adapted PCNet and VMware/Bochs display paths |
| Games | Quake/QuakePlus, Half-Life, Diablo, OpenEmpire and incomplete UT99 engine source | TempleOS library, existing TOOM integration, Tetris/Scorch/Sudoku/Chess ports |

The ledger describes source availability and integration. Only checks listed in
[VALIDATION.md](VALIDATION.md) count as runtime evidence. The baseline TinkerOS
games and its modified HTTP stack have not been translated into the platform.
Retail game data and emulator ROMs are not bundled. UT99 remains hidden because
upstream marks it incomplete. No unsupported emulator launcher has been added.

## Remaining work

- Meet and measure the requested minimum 60 FPS under supported workloads. The
  scheduler targets 60 Hz; actual QEMU TCG rendering can be much slower.
- Authenticate TLS servers, provide a hardened random source, and test modern
  websites before treating the browser as suitable for private accounts.
- Exercise each imported app and driver beyond compilation. Source availability
  does not establish compatibility with actual hardware.
- Consolidate the baseline-only games/apps into the new platform with proper ports.
- The launcher now has a 160 ms cubic ease-out slide and the boot indicator uses
  elapsed time. Window open/minimize/close animations remain incomplete.
- Audit crash recovery, installer, storage error handling and network robustness.

## Motion research

- [Microsoft timing and easing](https://learn.microsoft.com/en-us/windows/apps/design/motion/timing-and-easing): standard fast duration is 167 ms; easing decelerates into a stable end state.
- [Apple Motion](https://developer.apple.com/design/human-interface-guidelines/motion): brief, purposeful and optional feedback; interaction should not wait for animations. The documentation JSON was read because the HTML requires JavaScript.
- [GNOME libadwaita animation implementation](https://github.com/GNOME/libadwaita/blob/main/src/adw-animation.c): follows the widget frame clock and skips motion when `gtk-enable-animations` is false.

RelicOS uses a 160 ms, 12-pixel cubic ease-out for the launcher, with immediate
input handling and a Reduced motion bypass. It uses the compositor callback
rather than a separate redraw loop. This is modest motion within the existing
renderer; a nominal FPS constant does not establish smoothness or minimum FPS.
