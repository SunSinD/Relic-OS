# Relic OS — Session Continuation Prompt

Copy everything in the **"Paste into Cursor"** section below into a new chat to resume work without losing context.

---

## Paste into Cursor

```
I'm continuing work on Relic OS (TempleOS fork): https://github.com/SunSinD/Relic-OS

## Goal
Ship a stable dark desktop (wallpaper + dock), working Shell/Games/TOOM, system status bar with time/date, and a repeatable VMware build loop.

## My environment
- **Host:** Windows 10/11, VMware Workstation
- **Repo:** `C:\Users\SunSD\Relic-OS`
- **Transfer VHD:** `C:\RelicTransfer\transfer.vhd` (sync via `C:\RelicTransfer\MakeVHD.ps1` — copies `src\relic\` → VHD as `C:/`)
- **VM:** `C:\Users\SunSD\Documents\Virtual Machines\TempleOS\TempleOS.vmx`
  - **IDE 0:0** → transfer VHD (Build.HC / source)
  - **IDE 0:1** → `TempleOS.vmdk` (installed system)
  - CD disconnected after install; boot from vmdk
- **ISO export (host):** `C:\RelicTransfer\ExtractISO.ps1` → `RelicOS_v1.0.0.iso`

## Current blockers (fix these first)
1. **Shell dock button (>_) still freezes the desktop** (cursor moves, wallpaper/dock stop updating). Latest fix in repo may not be on the VM yet — I could not open Shell to run `CopyTree`.
2. **Verify system top bar** shows `RelicOS V1.0.0` + day + date + time + FPS via `RelicChrome.HC` / `gr.fp_wall_paper` — NOT drawn on wallpaper. No "Desktop" text on wallpaper.
3. **Deploy latest sources to VM** without Shell if needed (see below).

## Deploy sources without Shell
**Option A — Host sync + reboot:**
1. On Windows (admin): `powershell -ExecutionPolicy Bypass -File C:\RelicTransfer\MakeVHD.ps1`
2. Boot VM with transfer disk attached as IDE 0:0
3. In TempleOS installer/desktop (any working prompt): `Drv('D'); CopyTree("C:/","::/Home/RelicOS/");`
4. Reboot from `TempleOS.vmdk`

**Option B — Full rebuild inside VM:**
```holyc
Drv('D');
Cd("/Home");
#include "C:/Build.HC";
```

## Architecture (desktop)
| Component | File | Role |
|-----------|------|------|
| Boot chain | `RelicBoot.HC` | Theme → Chrome → Wallpaper → `RelicDesktop` loop |
| Status strip | `RelicChrome.HC` | `gr.fp_wall_paper` — `RelicOS V1.0.0` + clock + FPS |
| Wallpaper | `RelicWallpaper.HC` | `wallpaper.raw` 640×480 |
| Desktop | `RelicDesktop.HC` | `draw_it` = dock + wallpaper (below TOPBAR_H), no OS text on wallpaper |
| Games | `GamesLauncher.HC` | Numeric menu; TOOM via `ExePrint("RunTOOM;")` |
| DOOM | `RunTOOM.HC` + `TOOM/` | Child task; needs `freedoom1.wad` in `::/Home/RelicOS/TOOM/` |
| Build | `Build.HC` | Installs to `::/Home/RelicOS`, ISO export, HomeSys patches |

**Shell (intended design):** `RelicShellTaskMain` spawned as independent task (NOT child of desktop `Fs`). Desktop loop must NOT use `DeathWait` or `while (ms.lb)`. Esc → `RelicChildKill` + `RelicDesktopRestore` (no `MsSet` — do not move mouse).

**Wallpaper draw:** `GrBlot(dc, 0, TOPBAR_H, relic_wp_dc)` then `gr.fp_wall_paper(task)` so status strip is never covered.

## HolyC constraints (do not break)
| Avoid | Use instead |
|-------|-------------|
| `continue;` | Restructure loop / `return` |
| `goto` in Relic shell/desktop | `return` / if-else |
| Multi-statement `switch` cases | One statement per case or if/else |
| `RunTOOM()` / `if (!Func())` | `ExePrint("RunTOOM;");` |
| `'\n'` in `StrFirstOcc` | `"\n"` |
| Assignment inside `if (x = ...)` | Separate lines |
| `{ }` inside `switch` cases | Extract `U0` functions |
| `RelicDriveAttrsDark` in `RelicTheme.HC` at boot | Drive colors only in `RelicDesktop.HC` |
| Forward refs like `RelicGamesLauncher;` in desktop | `ExePrint("...");` after `ExeFile` |

Functions must be **defined before use** in boot compile order.

## Resolved in recent commits (verify on VM)
- White terminal borders → `Fs->border_src = 0`, `RelicTermDark`
- Boot crashes → no `continue`/bad switch, no StartOS injection
- Games compile error line 23 → `ExePrint("RunTOOM;")` not `RunTOOM;`
- TOOM in desktop task → child task via `RunTOOM.HC`
- Editable text on wallpaper → `RelicAppStart` / `draw_it = NULL` for text apps
- `freedoom1.wad` added under `src/relic/TOOM/` (~27 MB)

## Next tasks (priority)
1. Confirm Shell opens in separate window; desktop stays responsive; `exit` or Esc closes shell.
2. Confirm status bar always visible with `RelicOS V1.0.0` + live clock.
3. Test all dock buttons: Fi, Ed, >_, Gm, Tk, Mm, Si, ?
4. Test Games → 1 → TOOM → Quit returns to launcher cleanly.
5. If Shell still freezes: debug `GetMsg` vs child focus, remove any remaining blocking waits, consider inline `UserCmdLine` only in child task.
6. Roadmap: Files browser navigation, Editor file picker, Shell history, Settings panel.

## Key files to read first
- `src/relic/RelicDesktop.HC`
- `src/relic/RelicChrome.HC`
- `src/relic/GamesLauncher.HC`
- `src/relic/Build.HC`
- `docs/CONTINUATION.md` (this file)
- `roadmap/README.md`

Please read those files, help me deploy to the VM, fix Shell freeze if still broken, and continue desktop polish.
```

---

## Last session summary (2026-05-23)

- Iterated dock hover, Esc handling, async child tasks for Shell/Games.
- Removed custom "Desktop" text from `DrawDesktop`; restored version string on system strip only.
- Fixed wallpaper covering status bar (blit below `TOPBAR_H`).
- Added `RelicShellTaskMain`, removed `while (ms.lb)` hang, spawn without parent `Fs`.
- User could not test latest build — Shell unusable for `CopyTree`.

---

## Agent transcript (prior chat)

Cursor transcript ID: `7d95b6e6-987a-4d11-8303-4d9f8995c914` (full tool history if needed).
