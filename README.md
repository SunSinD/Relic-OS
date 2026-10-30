<p align="center">
  <img src="docs/images/banner.jpg" width="220" alt="Relic OS artwork">
</p>

<h1 align="center">Relic OS</h1>

<p align="center">
  A TempleOS fork with a dark desktop, a dock, and DOOM.<br>
  Made as a tribute to Terry A. Davis.
</p>

<p align="center">
  <a href="https://github.com/SunSinD/Relic-OS/releases/latest"><b>Download the ISO</b></a> |
  <a href="roadmap/README.md">Roadmap</a> |
  <a href="CHANGELOG.md">Changelog</a>
</p>

<p align="center">
  <img src="docs/images/desktop.png" width="49%" alt="Relic OS desktop">
  <img src="docs/images/doom.png" width="49%" alt="DOOM running in Relic OS">
</p>

## What it is

Relic OS is TempleOS with a desktop on top. It boots into a dark desktop with a
dock, and everything from TempleOS still works: HolyC, the shell, the editor and
the games. It's still early (version 0.4.0).

- Dark desktop with a dock and a status bar (time, FPS)
- Apps: Files, Editor, Shell, Games, Tasks, Memory, SysInfo, Help
- DOOM in colour at 30 fps in a VM, with mouse look
- Fast display driver for virtual machines, so everything draws faster
- Live CD that can install itself to a disk

<p align="center">
  <img src="docs/images/games.png" width="60%" alt="Games menu">
</p>

## Try it

1. Download `RelicOS-v0.4.0.iso` from the [latest release](https://github.com/SunSinD/Relic-OS/releases/latest).
2. Make a virtual machine with these settings:

| Setting | Value |
|---------|-------|
| Guest OS | Other 64-bit, BIOS (not UEFI) |
| Memory | 2 GB |
| CPUs | 1 to 4 |
| Hard disk | IDE, 2 GB or more (not SATA, SCSI or NVMe) |
| CD | the Relic OS ISO |

3. Boot it. Press `C` to try the live desktop, or `I` to install it to the disk.

Tested in VMware Workstation and QEMU. For QEMU (live CD):

```sh
qemu-system-x86_64 -m 2G -smp 4 -cdrom RelicOS-v0.4.0.iso -boot d
```

In VMware, click inside the VM to capture the mouse and press Ctrl+Alt to let
it go. For mouse look in DOOM, set Edit > Preferences > Input > "Optimize mouse
for games" to Always.

## Keys

| Key | On the desktop |
|-----|----------------|
| F E S G T M I H | Files, Editor, Shell, Games, Tasks, Memory, SysInfo, Help |
| Esc | Back to the desktop |
| Ctrl+Alt+V | Plain VGA (shows the crash screen if something breaks) |

| Key | In DOOM |
|-----|---------|
| W/S or Up/Down | Move |
| Mouse or Left/Right | Turn |
| A/D | Strafe |
| Ctrl or left click | Fire |
| Space | Open doors, press switches |
| Shift | Run |
| 1-7, mouse wheel | Weapons |
| Tab | Map |
| Esc | Menu |

## Feedback

I'd like to hear what you think: what works, what breaks, and what you'd want
next. Open an [issue](https://github.com/SunSinD/Relic-OS/issues) or reply in
the TempleOS Discord thread. If something crashes, a photo of the screen after
pressing Ctrl+Alt+V helps a lot.

What's planned is in the [roadmap](roadmap/README.md).

## Building from source

Needs Windows, Python 3 and VMware Workstation. From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File tools\relic.ps1 dev   # sync src\relic and boot the dev VM
powershell -ExecutionPolicy Bypass -File tools\relic.ps1 iso   # build build\RelicOS-v0.4.0.iso
```

First-time setup: [docs/vmware-workflow.md](docs/vmware-workflow.md).
Contributing: [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Relic OS code is MIT. TempleOS is public domain. The DOOM data and the TOOM
engine have their own terms (not for sale), see [NOTICE.md](NOTICE.md).

<p align="center">
  <em>In memory of Terry A. Davis (1969-2018).</em>
</p>
