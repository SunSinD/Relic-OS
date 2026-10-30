# Architecture

This is the intended high-level shape. It will become more specific as the
fork is built out.

```text
Applications
Shell and tools
Runtime libraries
Graphics and input
Filesystem and storage
Kernel services
Architecture-specific code
Boot code
Hardware or emulator
```

## Current Answers

- Target: x86-64, BIOS boot, in a VM (VMware first, QEMU tested).
- Build: `tools\relic.ps1 iso` runs `src/relic/Build.HC` inside the VM.
- Relic OS stays TempleOS-compatible: stock apps and games still run.
- Everything is HolyC; only host tools are PowerShell and Python.
