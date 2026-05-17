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
  Do not edit files here directly on Windows. The `.HC.Z` files are
  TempleOS-compressed and must be edited inside the VM or with a proper
  decompressor.
- `src/relic/` holds plain HolyC files written for Relic OS. These are
  readable and editable on Windows. They should be copied into the VM
  for testing.

## First Relic OS File

`src/relic/HelloRelicOS.HC` — a greeting script that prints the Relic OS
identity when run inside the VM. This is the first file that makes Relic OS
visibly different from TempleOS.
