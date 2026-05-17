# VMware Workflow

This repo now contains the extracted TempleOS ISO filesystem under
`src/templeos/`.

## Important Detail

TempleOS stores many source files compressed with its own `.Z` format. Files
ending in `.HC.Z`, `.HH.Z`, `.DD.Z`, and similar names are original TempleOS
files from the ISO. Keep them intact unless you are intentionally replacing or
rebuilding them.

## Basic Development Loop

1. Make changes in the repo.
2. Commit and push the change to GitHub.
3. Bring the changed file into a TempleOS VM.
4. Rebuild a distro ISO from inside TempleOS.
5. Boot the new ISO in VMware Workstation.

## VMware Setup

Create a new virtual machine:

- Guest OS: Other 64-bit
- Firmware: BIOS
- CPU: 1 or 2 cores to start
- RAM: 2 GB
- Disk: IDE or SATA virtual disk
- CD/DVD: attach `TempleOS.ISO`
- Network: disabled unless you are testing your own future network work

Boot the VM from the ISO and install TempleOS to the virtual disk first. The
distro builder expects a writable drive.

## Building A Test ISO In TempleOS

TempleOS includes a distro script at:

```text
C:/Misc/DoDistro.HC.Z
```

From inside TempleOS, include it:

```c
#include "C:/Misc/DoDistro.HC.Z";
```

That script builds:

```text
C:/Tmp/MyDistro.ISO.C
```

Attach that generated ISO file to VMware Workstation as the CD/DVD image and
boot from it.

## Moving Files In And Out

The clean long-term goal is to add repo tooling that can rebuild RedSea ISO
images directly from `src/templeos/`. Until then, the practical options are:

- Edit small files directly inside TempleOS, then mirror the change back into
  the repo.
- Use a supplemental ISO or virtual disk to move changed files into the VM.
- Use TempleOS's own distro script to generate a bootable test ISO.

## Next Tooling Target

Add host-side tools for:

- Decompressing TempleOS `.Z` files.
- Repacking `src/templeos/` into a RedSea ISO.
- Launching a test VM with the generated image.
