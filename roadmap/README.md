# Relic OS - Roadmap

## Phase 1: Foundation (Complete)

- [x] Import TempleOS V5.03 ISO filesystem into `src/templeos/`
- [x] Record source baseline in `CHANGELOG.md`
- [x] Add `docs/relic-os-identity.md` - formal Relic OS identity declaration
- [x] Set up project structure (docs, research, roadmap, specs, src, tests, tools)
- [x] Add tool stubs: `build-iso.ps1`, `run-vmware.ps1`, `extract-redsea.ps1`

## Phase 2: Desktop Environment (Complete)

- [x] Create VHD build pipeline (`MakeVHD.ps1`) for VMware testing
- [x] Implement custom dark 16-color palette (`RelicTheme.HC`)
- [x] Create raw wallpaper loader (`RelicWallpaper.HC`)
- [x] Build dock-based desktop launcher (`RelicDesktop.HC`)
- [x] Implement inline app execution (Files, Editor, Shell, Mount, Tasks, Memory, SysInfo)
- [x] Add Terry Davis tribute page in Help
- [x] Suppress TempleOS menu chrome while preserving terminal borders
- [x] Create boot orchestrator (`RelicBoot.HC`)

## Phase 3: Polish & Refinement (In Progress)

- [x] Style kernel system line via palette as a sleek light-mode menu bar
- [x] Fix input buffer bleeding (mouse dragging / keyboard presses leaking into apps)
- [x] Inject dynamic dark mode formatting into standard documents (e.g. Editor)
- [x] Fix raw wallpaper inversion bug
- [x] Port TOOM to RelicOS and integrate custom Games Launcher
- [x] Enforce system-wide black/grey terminal theme across all tasks
- [x] Implement robust build auto-repair script for kernel files (`Build.HC`)
- [x] Replace unstable graphical Games launcher with numeric game selection menu
- [x] Package TOOM source tree into `src/relic/TOOM/` for release builds
- [x] Stabilize TOOM wrapper/runtime path: clean launch palette, throttled renderer-adjacent task, Quit Game cleanup
- [x] Suppress TempleOS menu chrome in Relic desktop, numeric Games launcher, and TOOM runtime contexts
- [x] Avoid TempleOS FAT32 transfer-drive cleanup during ISO export
- [x] Restore clean Adam wallpaper source during build instead of patching it in-place
- [x] Guard TOOM task shutdown so Quit Game cannot kill the active launcher task
- [x] Tune TOOM movement and palette setup for steadier VMware play
- [x] Make ISO boot helper loading idempotent across repeated `Build.HC` runs
- [x] Route TOOM Quit Game through wrapper-level cleanup and palette restore
- [x] Validate TOOM quit cleanup, single-owner renderer stability, and dark boot handoff (completely eliminated early boot white flashes and resolved compilation failures)
- [x] Fix early-boot white flashes by prepending inline dark palette setting to StartOS.HC.Z
- [ ] Improve Files browser: navigate directories, open files
- [ ] Make Editor open user-selected files instead of fixed path
- [ ] Add proper Shell with command history
- [ ] Create a Settings/Preferences panel
- [ ] Add system sounds or visual feedback for dock clicks

## Phase 4: System Integration

- [ ] Integrate `RelicBoot.HC` into `StartOS.HC.Z` for auto-boot
- [ ] Custom boot splash screen
- [ ] User profile system (username, preferences)
- [ ] Persistent settings across reboots
- [ ] Custom file associations

## Phase 5: Distribution

- [x] Create automated ISO build pipeline (`Build.HC`)
- [ ] Add basic smoke test scripts in `tests/`
- [ ] Write user documentation
- [ ] Publish the first downloadable Relic OS image
- [ ] Create installation guide for VMware/QEMU
