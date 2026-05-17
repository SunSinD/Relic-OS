# Changelog

All notable changes to Relic OS are recorded here.
Each entry marks a point where Relic OS diverges from the TempleOS baseline.

---

## [Unreleased]

### Added
- `src/relic/HelloRelicOS.HC` — First Relic OS HolyC source file. Prints a
  Relic OS greeting to confirm the fork is running.
- `docs/relic-os-identity.md` — Formal declaration of Relic OS as an
  independent project.
- `tools/build-iso.ps1` — Stub: future script to repack source into a
  bootable RedSea ISO.
- `tools/run-vmware.ps1` — Stub: future script to launch VMware with the
  built ISO.
- `tools/extract-redsea.ps1` — Stub: future script to unpack a RedSea ISO
  into `src/templeos`.
- `CHANGELOG.md` — This file. Tracks every divergence from TempleOS.

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
