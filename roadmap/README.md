# Relic OS - Roadmap

## Phase 1: Foundation (Complete)

- [x] Import TempleOS V5.03 ISO filesystem into `src/templeos/`
- [x] Record source baseline in `CHANGELOG.md`
- [x] Add `docs/relic-os-identity.md` - formal Relic OS identity declaration
- [x] Set up project structure (docs, research, roadmap, specs, src, tests, tools)
- [x] Add tool stubs: `build-iso.ps1`, `run-vmware.ps1`, `extract-redsea.ps1`

## Phase 2: Desktop Environment (Complete)

- [x] Create VHD build pipeline (`C:\RelicTransfer\MakeVHD.ps1`) for VMware testing
- [x] Implement custom dark 16-color palette (`RelicTheme.HC`)
- [x] Create raw wallpaper loader (`RelicWallpaper.HC`)
- [x] Build dock-based desktop launcher (`RelicDesktop.HC`)
- [x] Implement dock apps (Files, Editor, Shell, Games, Tasks, Memory, SysInfo, Help)
- [x] Add Terry Davis tribute page in Help
- [x] Suppress TempleOS menu chrome; dark terminal theme
- [x] Create boot orchestrator (`RelicBoot.HC`)
- [x] System status strip via `RelicChrome.HC` (`RelicOS V1.0.0` + clock + FPS)

## Phase 3: Polish & Refinement (In Progress)

### Shipped (0.3.0)
- [x] Port TOOM to RelicOS and integrate Games Launcher (`GamesLauncher.HC`, `RunTOOM.HC`)
- [x] Package TOOM source tree into `src/relic/TOOM/`; bundle `freedoom1.wad` for testing
- [x] TOOM in isolated child task; quit returns to launcher without killing desktop
- [x] Boot-safe theme (`RelicTheme.HC`); no early-boot drive symbol references
- [x] Fix white terminal borders (`border_src = 0`, `RelicTermDark`)
- [x] Wallpaper below status strip; no OS branding text on wallpaper graphics
- [x] HolyC-safe Games launcher (`ExePrint` for runtime calls)
- [x] Automated ISO build (`Build.HC`) + host `ExtractISO.ps1`
- [x] Session handoff doc (`docs/CONTINUATION.md`)

### Active — fix before new features
- [ ] **Shell dock button:** verify `RelicShellTaskMain` opens terminal without freezing desktop (blocked on VM deploy as of 2026-05-23)
- [ ] **Deploy loop:** document and verify `MakeVHD.ps1` → `CopyTree` / `Build.HC` → reboot test checklist
- [ ] **Esc behavior:** close child Shell/Games without moving mouse; desktop redraw stays smooth

### Next up
- [ ] Improve Files browser: navigate directories, open files
- [ ] Make Editor open user-selected files instead of fixed `B:/RelicNote.DD`
- [ ] Shell: command history, reliable focus when child task is open
- [ ] Settings / Preferences panel (palette, wallpaper path)
- [ ] Visual feedback for dock clicks (optional sounds or flash)

## Phase 4: System Integration

- [ ] Integrate `RelicBoot.HC` into installed boot path for auto-desktop (without breaking StartOS repair)
- [ ] Custom boot splash screen
- [ ] User profile system (username, preferences)
- [ ] Persistent settings across reboots
- [ ] Custom file associations

## Phase 5: Distribution

- [x] Create automated ISO build pipeline (`Build.HC`)
- [ ] Add basic smoke test scripts in `tests/`
- [ ] Write user documentation (install VMware/QEMU, first boot, Games/TOOM)
- [ ] Publish first downloadable Relic OS image (GitHub Releases)
- [ ] CI workflow for `MakeVHD.ps1` + lint/docs checks (host-side)

## Development references

| Topic | Location |
|-------|----------|
| Resume next session | `docs/CONTINUATION.md` |
| VMware disks & build | `docs/vmware-workflow.md` |
| Recent changes | `CHANGELOG.md` [0.3.0] |
| Desktop source | `src/relic/RelicDesktop.HC` |
