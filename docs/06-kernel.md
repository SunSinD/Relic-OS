# Kernel

The kernel document tracks core services and ownership boundaries.

## Kernel Responsibilities

- CPU setup after boot handoff.
- Interrupts and exception handling.
- Memory management.
- Task scheduling.
- Timing and sleep.
- Filesystem and device access.
- Graphics and input coordination if retained in-kernel.
- System diagnostics and panic behavior.

## Design Questions

- Which services remain inside the kernel?
- Which services can move to userland later?
- What ABI or API should programs depend on?
- How much single-address-space behavior is preserved?
- What debugging hooks are required from the start?

## Documentation Rule

Every kernel subsystem should document invariants: what must always be true
before and after a function, interrupt, or state transition.
