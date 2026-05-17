# Learning Path

This is the recommended order for learning enough to work on Relic OS without
getting lost.

## Phase 0: Project Setup

- Learn the repository layout.
- Read the project charter and roadmap.
- Set up a notes file under `research/`.
- Learn how ADRs are written.

## Phase 1: Operating System Basics

- CPU modes, interrupts, exceptions, and timers.
- Physical memory, virtual memory, paging, and allocators.
- Filesystems, block devices, and boot media.
- Scheduling, tasks, synchronization, and preemption.
- Basic display, keyboard, and storage drivers.

## Phase 2: TempleOS Study

- Identify the exact upstream source snapshot.
- Build a source inventory by subsystem.
- Document the boot path.
- Document the HolyC language/toolchain assumptions.
- Document filesystem formats and user interaction model.
- Record inherited constraints and unusual design choices.

## Phase 3: Relic OS Direction

- Decide the first supported hardware target.
- Decide the first emulator target.
- Decide the build host and compiler path.
- Decide compatibility rules for programs, filesystem images, and APIs.
- Decide which inherited behavior is required, optional, or intentionally removed.

## Phase 4: First Implementation Loop

- Create the smallest repeatable boot target.
- Add CI checks that run without special hardware.
- Add one compatibility test at a time.
- Keep documentation next to each subsystem change.
