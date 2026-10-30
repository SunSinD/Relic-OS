# VMware Workflow

Everything runs through one script, `tools\relic.ps1`, from the repo root in
PowerShell. Python 3 and VMware Workstation must be installed.

## The dev loop

```powershell
powershell -ExecutionPolicy Bypass -File tools\relic.ps1 dev
```

That one command:

1. Powers the VM off if it is running.
2. Writes `src\relic\` onto the transfer disk (`build\vm\RelicOS\transfer-flat.vmdk`,
   a FAT32 image made by `tools\fat32img.py`, about 3 seconds) with a
   `RelicDev.TXT` marker.
3. Boots the VM and picks "1. Drive C" in the boot loader.
4. In the guest, `HomeSys.HC` mounts the transfer disk (IDE 0:0 only), finds the marker, copies the new `*.HC` files to
   `::/Home/RelicOS` (and `TOOM/*.HC` to `::/Home/TOOM`), then starts the desktop.

About 30 seconds after you run it, the desktop shows your latest code.

Edit, run `dev`, look at the VM window, repeat.

Changes to `HomeSys.HC` itself apply one boot later (the old one is already
running when the new one is copied). Everything else, including
`RelicStartUp.HC`, applies on the next boot.

## Other commands

| Command | What it does |
|---------|--------------|
| `dev` | Sync sources and boot (default). |
| `prepare` | Only write the transfer disk. |
| `start` / `stop` | Boot or hard power-off the VM. |
| `shot` | Save a screenshot of the VMware window to `build\shots\latest.png` (keep the window open, not minimized). |
| `log` | Show `::/Home/Boot.LOG` from the VM disk (powers the VM off first). |
| `iso` | Sync, let the guest run `Build.HC` on its own, wait, power off and assemble `build\RelicOS-v0.4.0.iso` (several minutes). |
| `extract` | Assemble the ISO from chunks already on the transfer disk. |
| `newvm` | Create the VM folder (empty disk) if you are starting from scratch. |

## The VM (`build\vm\RelicOS`, not in git)

| Slot | File | Role |
|------|------|------|
| IDE 1:1 | `RelicOS-HD.vmdk` | Installed RelicOS, boots from here |
| IDE 0:0 | `transfer.vmdk` | FAT32 copy of `src\relic` (`E:` after a dev boot, `G:` with the setup command) |
| IDE 1:0 | `build\RelicOS-v0.4.0.iso` | Live CD, only used to reinstall |

The VMX turns on VNC at `127.0.0.1:5901` so `tools\vnc.py` can take
screenshots and type keys (`python tools\vnc.py type "Dir;" --enter`).
VNC screenshots are only reliable for still screens: VMware's VNC server misreports
frames that change quickly (use `relic.ps1 shot`). Mouse clicks do not work over VNC (TempleOS uses a PS/2 mouse); use the
keyboard shortcuts on the desktop instead: F, E, S, G, T, M, I, H.

The VMX sets `mks.gamingMouse.policy = "gaming"` (same as Edit > Preferences >
Input > Optimize mouse for games: Always) so VMware sends raw mouse motion,
which DOOM uses to turn the view. Click inside the VM to grab the
mouse, Ctrl+Alt to release it.

## Starting from scratch

1. `tools\relic.ps1 newvm` creates an empty disk and the VMX. The transfer
   disk stays disconnected during installation so the installer selects the system disk.
2. Boot it with the ISO attached, press `I` at the RelicOS setup screen, answer
   `Y` to "virtual machine?", press a key at the pause, and wait for installation.
   Answer `Y` to reboot.
3. Turn on the dev loop once: run `tools\relic.ps1 dev`, press S in the VM for
   the Relic Shell and type `ATAMount('G',BDT_ATA,0x1F0,0x3F4,0);` (Enter), then
   `#include "G:/DevSetup.HC";` (Enter). Two separate lines: `#include` runs at
   compile time, before the mount call on the same line.
   (G: is the transfer disk). From then on, `tools\relic.ps1 dev`.

The dev sync only runs on installs that have `::/Home/RelicDev.TXT` (made by
`DevSetup.HC`). A normal install never probes the disks at boot.

## Boot the ISO on any VMware VM

1. File > New Virtual Machine > Typical, ISO = `build\RelicOS-v0.4.0.iso`.
2. Guest OS: Other 64-bit, BIOS firmware, 2 GB RAM, 4 CPUs (DOOM renders on all of them).
3. Hard disk: IDE (not SATA/SCSI/NVMe), 2 GB or more.
4. Remove USB and network.
5. Power on. The setup screen offers `I` (install) or `C` (live desktop).

## Display

TempleOS draws 640x480 in 16 colours through planar VGA. VMware emulates that by
trapping every video-memory write (270 ms per full screen), so `RelicDisplay.HC`
switches to a linear framebuffer at boot: VMware SVGA II (VMware, VirtualBox
VBoxSVGA, QEMU `-vga vmware`) or Bochs VBE (QEMU `-vga std`, VirtualBox
VBoxVGA). Real hardware keeps plain VGA. Ctrl+Alt+V switches back to VGA at
any time, also inside the kernel debugger (that is how you see a crash
screen). `::/Home/RelicNoSVGA.TXT` keeps VGA from boot.

## HolyC rules learned the hard way

| Do not | Why |
|--------|-----|
| Re-declare a defined function with `extern` | It replaces the real symbol, calls throw "Undefined Extern" (this broke the whole desktop). |
| `ToI64(x) - some_U8` | Mixed signed/unsigned math is done unsigned, so `0 - 10` is huge (this was the pink DOOM bug). Use `ToF64` on both sides. |
| `continue` | HolyC has no `continue`. |
| Forward references | Define functions before they are used in include order. |
| Shell lines over 1023 chars | The Relic Shell truncates them. |
| `MountIDEAuto` at boot | It hung / panicked on a fresh install with an empty CD drive. Mount one known port with `ATAMount` instead. |
| Rewrite `::/Kernel.BIN.C` or `::/0000Boot/*` on the running system | The boot sectors find them by disk position; a rewrite can move them and the disk stops booting. Patch the copies in `/Distro` only. |
| A `catch` without `Fs->catch_except = TRUE;` | The exception keeps unwinding after your handler runs. |
| `reg` as a variable or parameter name | It is a HolyC keyword (register variables). |
| `#include` after a statement on the same line | `#include` runs at compile time, before the statement. Use two lines. |
| Drop `SrvStartUp` from HomeSys | Popups (`PopUpOk`, file pickers) become invisible and callers hang. |
