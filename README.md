<p align="center">
  <img src="docs/assets/relic-os-mark.svg" width="180" alt="Relic OS mark">
</p>

<h1 align="center">Relic OS</h1>

<p align="center">
  A documentation-first TempleOS fork focused on becoming understandable,
  buildable, and eventually usable as a modern experimental operating system.
</p>

<p align="center">
  <a href="docs/README.md">Documentation</a> |
  <a href="roadmap/README.md">Roadmap</a> |
  <a href="CONTRIBUTING.md">Contributing</a> |
  <a href="SECURITY.md">Security</a>
</p>

---

## Project Status

Relic OS is in the foundation phase. The goal right now is not to rewrite
TempleOS immediately. The goal is to understand it, preserve what makes it
interesting, document the current system carefully, and then make deliberate
engineering decisions before large code changes land.

Current priorities:

1. Document the original TempleOS architecture and constraints.
2. Define what Relic OS should keep, replace, modernize, or remove.
3. Establish a clean repository layout before importing or rewriting source code.
4. Build repeatable tooling for formatting, building, testing, and releases.
5. Track decisions with Architecture Decision Records instead of scattered notes.

## Start Here

If you are new to the project, read these first:

- [Project Charter](docs/00-project-charter.md): mission, scope, non-goals, and principles.
- [Learning Path](docs/01-learning-path.md): the order to study OS concepts and the TempleOS codebase.
- [Repository Map](docs/02-repository-map.md): where files belong as the project grows.
- [Architecture Overview](docs/04-architecture-overview.md): the planned system map for Relic OS.
- [TempleOS Compatibility](docs/14-compatibility-templeos.md): what compatibility means and how to measure it.
- [Roadmap](roadmap/README.md): milestones from documentation to a bootable fork.

## Project Principles

- Documentation is part of the system, not a side task.
- Every major change should explain the problem, tradeoff, and migration path.
- Build and test steps must become reproducible on a clean machine.
- Compatibility should be intentional, measured, and documented.
- New code should prefer simple interfaces, clear ownership, and isolated subsystems.
- Experimental ideas are welcome, but they should not make the base system harder to understand.

## Planned System Areas

| Area | Purpose | Documentation |
| --- | --- | --- |
| Boot | Firmware entry, loader flow, early CPU setup | [Boot Process](docs/05-boot-process.md) |
| Kernel | Core execution environment and system services | [Kernel](docs/06-kernel.md) |
| Memory | Physical and virtual memory management | [Memory Management](docs/07-memory-management.md) |
| Scheduling | Tasks, interrupts, timing, and concurrency | [Scheduler](docs/08-scheduler.md) |
| Storage | Disk layout, filesystems, and persistence | [Filesystems](docs/09-filesystems.md) |
| Drivers | Hardware interfaces and device model | [Drivers](docs/10-drivers.md) |
| Userland | Shell, tools, libraries, and applications | [Userland](docs/11-userland.md) |
| Graphics | Display stack, UI model, drawing APIs | [Graphics and UI](docs/12-graphics-and-ui.md) |
| Security | Threat model, permissions, isolation, supply chain | [Security Model](docs/13-security-model.md) |
| Quality | Tests, emulation, CI, debugging, releases | [Testing and Quality](docs/15-testing-and-quality.md) |

## Repository Layout

```text
.
|-- .github/              GitHub templates, ownership, and CI workflows
|-- docs/                 Project documentation and subsystem notes
|   |-- adr/              Architecture Decision Records
|   `-- assets/           Images, diagrams, and project branding
|-- research/             Notes from studying TempleOS and OS design
|-- roadmap/              Milestones and project planning
|-- specs/                Formal subsystem contracts and proposals
|-- src/                  Source code when implementation work begins
|-- tests/                Emulation, integration, and regression tests
|-- tools/                Build, analysis, migration, and developer scripts
`-- README.md             Project entry point
```

## First Milestones

1. Build a source inventory of the upstream TempleOS codebase.
2. Write a bootable-system map from firmware entry to user interaction.
3. Decide the first supported architecture, emulator, compiler path, and build host.
4. Import or mirror upstream source only after licensing and preservation notes are clear.
5. Make the smallest reproducible boot target, then protect it with CI.

## Legal And Preservation Note

TempleOS has unusual history, tooling, and licensing expectations. Before
importing upstream source, the project should document the exact source
snapshot, license text, provenance, and any files that need special handling.
Until then, this repository is a planning and documentation foundation.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. For
large changes, start with an ADR in [docs/adr](docs/adr) so the reasoning is
reviewable before code becomes expensive to change.
