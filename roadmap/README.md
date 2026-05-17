# Roadmap

## Done

- [x] Import TempleOS V5.03 ISO filesystem into `src/templeos/`
- [x] Record source baseline in `CHANGELOG.md`
- [x] Add `docs/relic-os-identity.md` — formal Relic OS identity declaration
- [x] Add `src/relic/HelloRelicOS.HC` — first Relic OS HolyC source file
- [x] Add tool stubs: `build-iso.ps1`, `run-vmware.ps1`, `extract-redsea.ps1`
- [x] Set up project structure (docs, research, roadmap, specs, src, tests, tools)

## Now

- [ ] Run `HelloRelicOS.HC` inside the TempleOS VM to confirm it works
- [ ] Take a VMware snapshot named `clean-templeos-baseline`
- [ ] Build a source inventory for `src/templeos/` (list key files)
- [ ] Document the TempleOS boot sequence in `research/`

## Next

- [ ] Port or build a host-side `.Z` decompressor (see `tools/extract-redsea.ps1`)
- [ ] Decompress `StartOS.HC.Z` for review
- [ ] Create a repeatable VM build command (`tools/build-iso.ps1`)
- [ ] Boot the first self-built image in VMware

## Later

- [ ] Change the TempleOS startup message to "Relic OS" branding
- [ ] Improve shell behavior and menus
- [ ] Add basic smoke test scripts in `tests/`
- [ ] Modernize one subsystem at a time
- [ ] Publish the first usable Relic OS image
