# Relic OS - Roadmap

## Phase 1: Foundation (Complete)

- [x] Import TempleOS V5.03 ISO filesystem into `src/templeos/`
- [x] Record source baseline in `CHANGELOG.md`
- [x] Add `docs/relic-os-identity.md` - formal Relic OS identity declaration
- [x] Set up project structure (docs, research, roadmap, specs, src, tests, tools)

## Phase 2: Desktop Environment (Complete)

- [x] Custom dark 16-color palette (`RelicTheme.HC`)
- [x] Raw wallpaper loader (`RelicWallpaper.HC`)
- [x] Dock-based desktop launcher (`RelicDesktop.HC`)
- [x] Dock apps: Files, Editor, Shell, Games, Tasks, Memory, SysInfo, Help
- [x] Terry Davis tribute page in Help
- [x] Suppress TempleOS menu chrome; dark terminal theme
- [x] Boot orchestrator (`RelicBoot.HC`)
- [x] System status strip (`RelicChrome.HC`: `RelicOS V0.4.0` + date/time + FPS)

## Phase 3: Polish & Refinement (In Progress)

### Shipped (0.4.0, released 2026-10-30)
- [x] Desktop boots again (removed `extern` re-declarations that broke every call)
- [x] Shell opens, runs HolyC, `exit`/Esc returns to the desktop without freezing
- [x] DOOM: real colors instead of the pink screen (unsigned math bug in `DitherPalette`)
- [x] DOOM: New Game plays E1M1, Esc menu, Quit Game returns to the Games menu
- [x] TempleOS demo games: popups visible again (`SrvStartUp` restored); Flap Bat tested
- [x] SysInfo drive list fully dark
- [x] DOOM in colour (2-colour dithering restored, saturation boost) and 30 fps while moving
- [x] Fast display driver (`RelicDisplay.HC`, VMware SVGA II + Bochs/QEMU VBE): the whole OS draws far faster in VMs; Ctrl+Alt+V back to VGA
- [x] DOOM controls: mouse look, arrows turn, Ctrl or click fires, no more auto-fire
- [x] Titanium no longer crashes (corrupt sprite in stock TempleOS repaired at launch)
- [x] Display path picked by measurement at boot (VMware: VGA 273 ms vs framebuffer 12 ms per full screen)
- [x] Broken start-up code falls back to a terminal instead of the kernel debugger
- [x] Tested in VMware (install + live) and QEMU (`-vga std` and `-vga vmware`)
- [x] One-command dev loop: `tools\relic.ps1 dev` (sync + boot in ~25 s)
- [x] Fresh ISO install boots from its hard disk with the CD disconnected
- [x] Dev-only sync flag is excluded from release installs
- [x] FAT32 extraction regression checks (nested files, memory, file handles)
- [x] Hands-free ISO build: `tools\relic.ps1 iso`
- [x] VNC screenshots and keystrokes from the host (`tools\vnc.py`)

### Known issues
- [ ] Long reports (Memory, Tasks) scroll over the status strip on row 0
- [ ] Popups (`PopUpOk`) and the Editor still use light TempleOS colors and borders
- [ ] Games menu: blank lines between sections do not render
- [ ] Relic Shell: after a line of exactly 80 characters the text stays scrolled one column left
- [ ] DOOM music: TOOM never had it (its song task is an empty stub) and TempleOS only has the PC speaker; needs a sound-card driver (AC97/HDA)
- [ ] Tan DOOM walls (e.g. STARTAN2) come out grey-ish: true tan is not reachable with 2-colour mixes of the 16-colour palette
- [ ] Demo games open in their stock small window, not full screen

### Next up
- [ ] Files browser: navigate directories, open files
- [ ] Editor file picker instead of fixed `B:/RelicNote.DD`
- [ ] Shell: command history (Up/Down)
- [ ] Settings panel (palette, wallpaper path)
- [ ] Visual feedback for dock clicks
- [ ] Hotkeys overview and subsections in Help (God / hotkey docs)
- [ ] Nod to LoseThos / SparrowOS (Terry's earlier OS names) in Help or the boot splash
- [ ] Try JetBrains Mono-style 8x8 font for the terminal
- [ ] Add TempleCraft to the Games menu

## Phase 4: System Integration

- [x] Installed boot path auto-starts the desktop (`HomeSys.HC` -> `RelicStartUp.HC` -> `RelicBoot.HC`)
- [x] Live CD install prompt (`RelicInstall.HC`: I = install, C = live desktop)
- [ ] Custom boot splash screen
- [ ] User profile system (username, preferences)
- [ ] Persistent settings across reboots
- [ ] Custom file associations

## Phase 5: Distribution

- [x] Automated ISO build pipeline (`Build.HC` + `tools\relic.ps1 iso`)
- [ ] Smoke test script in `tests/` (boot, screenshot, compare)
- [x] User documentation (README: download, VM settings, keys)
- [x] Publish first downloadable Relic OS image ([v0.4.0](https://github.com/SunSinD/Relic-OS/releases/tag/v0.4.0))

## Development references

| Topic | Location |
|-------|----------|
| Resume next session | `docs/CONTINUATION.md` |
| Dev loop, VM layout, HolyC gotchas | `docs/vmware-workflow.md` |
| Recent changes | `CHANGELOG.md` |
| Desktop source | `src/relic/RelicDesktop.HC` |
