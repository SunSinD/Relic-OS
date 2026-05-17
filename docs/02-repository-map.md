# Repository Map

Relic OS uses a layout that separates documentation, source, tests, tools, and
research. This keeps early design work organized and leaves room for real OS
code later.

## Top-Level Directories

| Path | Purpose |
| --- | --- |
| `.github/` | Issue templates, pull request templates, ownership, and CI |
| `docs/` | Human-readable documentation and subsystem notes |
| `docs/adr/` | Architecture Decision Records |
| `docs/assets/` | Diagrams, logos, and documentation assets |
| `research/` | Study notes and source inventory work |
| `roadmap/` | Milestones, release planning, and project sequencing |
| `specs/` | Design contracts that are more formal than normal docs |
| `src/` | Operating system source code |
| `tests/` | Emulator, integration, regression, and compatibility tests |
| `tools/` | Build, migration, formatting, and analysis scripts |

## Source Layout Proposal

When code is imported or written, prefer this shape unless an ADR changes it:

```text
src/
|-- boot/
|-- kernel/
|-- arch/
|   `-- x86_64/
|-- drivers/
|-- fs/
|-- graphics/
|-- libc/
|-- shell/
`-- apps/
```

## Documentation Rule

If a directory contains real implementation work, it should eventually contain
either a `README.md` or a link to the relevant document under `docs/`.
