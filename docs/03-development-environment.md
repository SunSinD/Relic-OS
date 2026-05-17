# Development Environment

The development environment is intentionally not locked yet. The first task is
to document the minimum viable toolchain before source code is imported.

## Expected Host Tools

Track exact versions once they are chosen:

- Git
- Make, Ninja, or another build runner
- A C/C++ compiler if native components are introduced
- Assembler and linker tooling
- QEMU or another emulator
- Script runtime for repository tools
- Markdown formatter or linter

## First Emulator Target

The first target should be emulator-first so changes can be tested without
special hardware. Record:

- Emulator name and version.
- CPU architecture.
- Firmware mode.
- Disk image format.
- Boot media format.
- Minimum RAM and display requirements.
- Exact command used to start the system.

## Reproducibility Rule

A fresh contributor should eventually be able to run one documented command to
build an image and one documented command to boot it in an emulator.
