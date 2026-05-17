# Overview

Relic OS is a TempleOS fork with a practical goal: understand the original
system, keep its interesting ideas, and gradually turn it into a cleaner
experimental OS.

## What Matters

- Clear source layout.
- Repeatable builds.
- Emulator-friendly testing.
- Simple documentation.
- Careful compatibility decisions.
- A usable developer workflow.

## What Comes First

Before large code changes, the project needs a clear baseline:

1. Which TempleOS version is the starting point.
2. How the original system boots.
3. How the kernel, filesystem, shell, graphics, and HolyC environment fit together.
4. What should be preserved exactly and what can change.
