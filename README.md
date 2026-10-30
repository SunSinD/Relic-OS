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

## Download and Run

1. Download `RelicOS-v0.4.0.iso` from the [latest release](https://github.com/SunSinD/Relic-OS/releases/latest).
2. Make a new virtual machine:

| Setting | Value |
|---------|-------|
| Guest OS | Other 64-bit, BIOS (not UEFI) |
| Memory | 2 GB |
| CPUs | 1 to 4 (DOOM draws on all of them) |
| Hard disk | IDE, 2 GB or more (not SATA, SCSI or NVMe) |
| CD | the RelicOS ISO |

3. Boot it. Press `C` to try the live desktop, or `I` to install to the disk
   (answer `Y` to "virtual machine?", then `Y` to reboot).

Tested in VMware Workstation and QEMU. QEMU one-liner (live CD only):

```sh
qemu-system-x86_64 -m 2G -smp 4 -cdrom RelicOS-v0.4.0.iso -boot d
```

VMware tip: click inside the VM to capture the mouse, Ctrl+Alt to release it.
For DOOM mouse look, set Edit > Preferences > Input > "Optimize mouse for games"
to Always.

## Using It

| Key | Desktop |
|-----|---------|
| F E S G T M I H | Files, Editor, Shell, Games, Tasks, Memory, SysInfo, Help |
| Esc | Back to the desktop |
| Ctrl+Alt+V | Switch to plain VGA (shows a crash screen if something breaks) |

| Key | DOOM |
|-----|------|
| W/S or Up/Down | Move |
| Mouse or Left/Right | Turn |
| A/D | Strafe |
| Ctrl or left click | Fire |
| Space | Open doors, press switches |
| Shift | Run |
| 1-7, mouse wheel | Weapons |
| Tab | Map |
| Esc | Menu |

## What Works

- Dark desktop with wallpaper, dock and a live status bar (version, date, time, FPS)
- Dock apps: Files, Editor, Shell, Games, Tasks, Memory, SysInfo, Help
- Games menu with DOOM (TOOM port, 30 fps in a VM) and the TempleOS demo games
- Fast display driver for virtual machines (VMware SVGA II and Bochs VBE), plain VGA elsewhere
- Live CD with an install prompt

## Building From Source

Needs Windows, Python 3 and VMware Workstation. From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File tools\relic.ps1 dev   # sync src\relic and boot the dev VM
powershell -ExecutionPolicy Bypass -File tools\relic.ps1 iso   # build build\RelicOS-v0.4.0.iso
```

First-time setup and VM layout: [docs/vmware-workflow.md](docs/vmware-workflow.md).

## Contributing

Contributions should move Relic OS toward a cleaner, usable system. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

Relic OS code: MIT License. TempleOS is public domain. DOOM data and the TOOM
engine have their own terms (not for sale), see [NOTICE.md](NOTICE.md).

---

<p align="center">
  <em>In memory of Terry A. Davis (1969-2018) - his work lives on.</em>
</p>
