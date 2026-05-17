# Architecture Overview

This document describes the intended shape of Relic OS. It is a planning map,
not a claim that all pieces exist today.

## System Layers

```text
Applications and demos
Shell and developer tools
User libraries and runtime
Graphics, input, and UI services
Filesystem and storage services
Kernel services
Architecture-specific CPU support
Bootloader and firmware interface
Hardware or emulator
```

## Core Questions

Before heavy implementation work, answer these questions:

- What source snapshot is the compatibility baseline?
- What CPU architecture is supported first?
- What boot path is supported first?
- What parts of HolyC remain required?
- What graphics and input model should be preserved?
- What compatibility promises can be tested automatically?
- What safety boundaries should exist in a modernized version?

## Modernization Strategy

Modernization should happen in layers:

1. Preserve and document existing behavior.
2. Build tests that describe the behavior.
3. Replace internals behind a stable interface.
4. Remove or change compatibility only with an ADR.
