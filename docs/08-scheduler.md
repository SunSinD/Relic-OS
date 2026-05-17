# Scheduler

This document tracks task, interrupt, timer, and concurrency behavior.

## Topics

- Task structure.
- Task creation and termination.
- Scheduling policy.
- Timer interrupt source.
- Sleep and wake behavior.
- Synchronization primitives.
- Critical sections.
- Interaction with graphics, shell, and filesystem work.

## Test Ideas

- Create many tasks and verify scheduling fairness.
- Verify sleep timing under emulator.
- Verify interrupt handlers do not corrupt task state.
- Verify panic behavior when scheduler invariants fail.
