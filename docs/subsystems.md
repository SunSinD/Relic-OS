# Subsystems

Use this page as the quick map for the OS.

| Area | Purpose |
| --- | --- |
| Boot | Gets from firmware or emulator startup into the kernel. |
| Kernel | Owns core system behavior such as tasks, interrupts, and memory. |
| Memory | Tracks physical memory, paging, heaps, and stacks. |
| Scheduler | Runs tasks and handles timing. |
| Filesystem | Reads and writes files and disk images. |
| Drivers | Talks to devices such as display, keyboard, timer, and disk. |
| Graphics | Handles drawing, text, windows, and visual interaction. |
| Userland | Contains shell tools, demos, apps, and libraries. |
| Tests | Keeps booting, compatibility, and tools from regressing. |

Each subsystem should eventually have:

- A short explanation.
- The important source files.
- How to build or test it.
- Known limitations.
