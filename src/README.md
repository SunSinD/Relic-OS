# Relic OS Source

This directory holds all OS source code.

## Layout

```
src/
|-- templeos/    Raw TempleOS V5.03 import. Treat as read-only baseline.
|-- relic/       Relic OS original source files.
```

## Rules

- `src/templeos/` is a raw import of the TempleOS V5.03 ISO filesystem.
  Do not edit files here. The `.HC.Z` files are TempleOS-compressed; read
  one on the host with `python tools/tosz.py FILE.HC.Z out.HC`.
- `src/relic/` holds plain HolyC files written for Relic OS. These are
  readable and editable on Windows. `tools\relic.ps1 dev` copies them into
  the VM and boots it.

## Where things start

`src/relic/HomeSys.HC` runs at boot, then `RelicStartUp.HC`, `RelicBoot.HC`
and `RelicDesktop.HC` (the desktop). `Build.HC` makes the ISO.
