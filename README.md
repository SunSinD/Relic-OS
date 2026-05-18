<p align="center">
  <kbd>
    <img src="https://i.imgur.com/Pf7trgl.jpeg" width="300" alt="Relic OS cyan sword artwork">
  </kbd>
</p>

<h1 align="center">Relic OS</h1>

<p align="center">
  A modern fork of TempleOS - built as a tribute to Terry A. Davis.<br>
  Focused on turning the original system into a cleaner, usable desktop operating system.
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

Relic OS is a fork of TempleOS dedicated to the memory of Terry A. Davis,
the sole creator of TempleOS. It aims to build a refined, usable desktop
experience on top of the foundation he created - while never forgetting
who made it all possible.

## Current State

Relic OS features a working dark-themed desktop environment with:

- **Custom dark palette** - 16-color scheme replacing TempleOS defaults
- **Dock launcher** - macOS-style dock with hover effects and tooltips
- **Inline apps** - Files, Editor, Shell, Mount, Tasks, Memory, System Info
- **Terry Davis tribute** - dedicated Help page honoring the creator
- **Custom wallpaper** - raw bitmap wallpaper with top bar overlay
- **Live clock** - date and time display in the top bar

## Running Relic OS

Relic OS runs in a VMware virtual machine using a VHD disk image:

1. Clone this repository
2. Place a TempleOS V5.03 ISO in your VM
3. Copy the `src/relic/` files to the VM's drive
4. Run `#include "E:/RelicBoot.HC";` to launch the desktop

See [Getting Started](docs/getting-started.md) for detailed instructions.

## Repository Layout

```
|-- docs/       Project notes and explanations
|-- research/   TempleOS source notes and inventory
|-- roadmap/    Project roadmap and phase tracking
|-- specs/      Technical specs
|-- src/
|   |-- relic/      Relic OS source (RelicDesktop, RelicTheme, etc.)
|   `-- templeos/   Original TempleOS V5.03 source (read-only baseline)
|-- tests/      Tests and emulator checks
|-- tools/      Build and developer scripts
`-- README.md
```

## Key Files

| File | Purpose |
|------|---------|
| `src/relic/RelicBoot.HC` | Boot orchestrator - chains theme, wallpaper, desktop |
| `src/relic/RelicTheme.HC` | Custom 16-color dark palette |
| `src/relic/RelicWallpaper.HC` | Raw bitmap wallpaper loader |
| `src/relic/RelicDesktop.HC` | Desktop environment with dock and apps |

## Contributing

Contributions should move Relic OS toward a cleaner, usable system. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License. TempleOS source code is in the public domain.

---

<p align="center">
  <em>In memory of Terry A. Davis (1969-2018) - his work lives on.</em>
</p>
