<p align="center">
  <kbd>
    <img src="https://i.imgur.com/Pf7trgl.jpeg" width="300" alt="Relic OS cyan sword artwork">
  </kbd>
</p>

<h1 align="center">Relic OS</h1>

<p align="center">
  A TempleOS fork focused on turning the original system into a cleaner,
  usable operating system.
</p>

<p align="center">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-2487d8?style=for-the-badge&labelColor=222222">
  <img alt="Language: HolyC" src="https://img.shields.io/badge/language-HolyC-00d8d8?style=for-the-badge&labelColor=222222">
  <img alt="Base: TempleOS" src="https://img.shields.io/badge/base-TempleOS-6f8fe8?style=for-the-badge&labelColor=222222">
  <img alt="Goal: Usable OS" src="https://img.shields.io/badge/goal-usable_OS-20c997?style=for-the-badge&labelColor=222222">
</p>

<p align="center">
  <a href="docs/README.md">Documentation</a> |
  <a href="roadmap/README.md">Roadmap</a> |
  <a href="CONTRIBUTING.md">Contributing</a> |
  <a href="SECURITY.md">Security</a>
</p>

---

## What This Is

Relic OS is a work-in-progress fork of TempleOS. Its goal is to become a usable
operating system while keeping the identity and spirit of the original project.

This repository currently holds the project structure, notes, and planning
material needed to build that foundation. Source code will be added around a
clear upstream baseline, build path, and first boot target.

## Goals

- Build Relic OS into a usable TempleOS fork.
- Modify the parts that define TempleOS.
- Improve organization, tooling, and maintainability.
- Create a bootable and testable system.

## Repository Layout

```
|-- docs/       Project notes and explanations
|-- research/   TempleOS source notes and inventory
|-- roadmap/    Short project plan
|-- specs/      Technical specs when behavior needs to be precise
|-- src/        OS source code
|-- tests/      Tests and emulator checks
|-- tools/      Build and developer scripts
`-- README.md
```

## Main Docs

- [Overview](docs/overview.md)
- [Getting Started](docs/getting-started.md)
- [Architecture](docs/architecture.md)
- [Subsystems](docs/subsystems.md)
- [TempleOS Notes](docs/templeos-notes.md)
- [Roadmap](roadmap/README.md)

## Contributing

Contributions should move Relic OS toward a cleaner, usable system. See
[CONTRIBUTING.md](CONTRIBUTING.md).
