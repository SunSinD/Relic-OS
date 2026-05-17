<p align="center">
  <img src="https://i.imgur.com/Pf7trgl.jpeg" width="520" alt="Relic OS cyan sword artwork">
</p>

<h1 align="center">Relic OS</h1>

<p align="center">
  A TempleOS fork focused on learning from the original system and shaping it
  into a cleaner, more usable experimental operating system.
</p>

<p align="center">
  <a href="docs/README.md">Documentation</a> |
  <a href="roadmap/README.md">Roadmap</a> |
  <a href="CONTRIBUTING.md">Contributing</a> |
  <a href="SECURITY.md">Security</a>
</p>

---

## What This Is

Relic OS is a work-in-progress fork of TempleOS. The first step is to understand
the original system clearly, then make careful changes that improve usability,
portability, maintainability, and developer experience.

This repository currently holds the project structure, notes, and planning
material. Source code will be added once the upstream baseline, build path, and
first technical goals are clear.

## Goals

- Make TempleOS easier to study, build, and modify.
- Keep the parts that make the original system interesting.
- Improve organization, tooling, and long-term maintainability.
- Work toward a bootable, testable experimental OS.
- Keep the repository simple enough to navigate without a map.

## Repository Layout

The repo is intentionally small:

```text
.
|-- docs/       Project notes and explanations
|-- research/   TempleOS study notes and source inventory
|-- roadmap/    Short project plan
|-- specs/      Technical specs when behavior needs to be precise
|-- src/        OS source code
|-- tests/      Tests and emulator checks
|-- tools/      Build and developer scripts
`-- README.md
```

## Current Focus

1. Pick the exact TempleOS version to use as the starting point.
2. Write a source inventory so each major piece is easy to find.
3. Document how the original boot, kernel, filesystem, UI, and language work.
4. Decide the first build and emulator target.
5. Add the smallest bootable baseline.

## Main Docs

- [Overview](docs/overview.md)
- [Getting Started](docs/getting-started.md)
- [Architecture](docs/architecture.md)
- [Subsystems](docs/subsystems.md)
- [TempleOS Notes](docs/templeos-notes.md)
- [Roadmap](roadmap/README.md)

## Contributing

Contributions should keep the repo easier to understand than it was before.
See [CONTRIBUTING.md](CONTRIBUTING.md).
