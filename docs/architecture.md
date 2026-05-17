# Architecture

This is the intended high-level shape. It will become more specific as the
project studies and imports the original system.

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

## Early Design Questions

- What CPU architecture is supported first?
- What emulator is the first target?
- What build system should be used?
- How much TempleOS compatibility is required?
- What parts of HolyC remain central to the system?
- What should the first bootable milestone include?
