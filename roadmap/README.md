# Roadmap

This roadmap is intentionally staged. Each phase should leave the repository in
a better state even if later phases change direction.

## Phase 0: Foundation

- [x] Create project documentation structure.
- [x] Add contribution and security policy files.
- [x] Add ADR process.
- [ ] Pick exact upstream TempleOS source snapshot.
- [ ] Record license and provenance details.
- [ ] Build a source inventory.

## Phase 1: Understanding

- [ ] Document boot path.
- [ ] Document kernel services.
- [ ] Document filesystem behavior.
- [ ] Document HolyC and toolchain assumptions.
- [ ] Document graphics and input behavior.

## Phase 2: Reproducible Build

- [ ] Choose build host and toolchain.
- [ ] Add build scripts.
- [ ] Produce a minimal image or imported baseline.
- [ ] Boot in emulator with a documented command.
- [ ] Add CI smoke checks.

## Phase 3: Compatibility Baseline

- [ ] Define compatibility labels.
- [ ] Add first compatibility tests.
- [ ] Preserve one known original program behavior.
- [ ] Track unsupported behavior explicitly.

## Phase 4: Modernization

- [ ] Improve developer workflow.
- [ ] Add safer subsystem boundaries.
- [ ] Improve diagnostics.
- [ ] Expand hardware or emulator support.
- [ ] Publish first experimental release.
