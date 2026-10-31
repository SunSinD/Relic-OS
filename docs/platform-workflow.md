# Platform development disk

Run commands from `D:\Files\Files\Others\T3Code\RelicOS\Relic-OS`.
The existing working disk is `build/platform/RelicOS.raw`. Keep the baseline
VMware disk separate. These commands do not create an ISO.

Needs Windows, Python 3, QEMU and mtools (the tool can use mtools in WSL Ubuntu).
The tested QEMU path is `C:/Users/SunSD/scoop/apps/qemu/current/`.

## Existing disk

```powershell
python tools/platform.py start
python tools/vnc.py --port 5902 shot build/shots/platform.png
python tools/platform.py stop
python tools/platform.py sync
python tools/platform.py start
```

`sync` copies source onto the stopped development disk, restores Home startup
files and retains saved preferences/user documents. It overwrites matching
platform source files, so keep source edits in the repository.
VNC is bound to localhost port 5902; QEMU monitor port 4445. USB tablet input is
enabled. The first terminal stays minimized; click the bottom-left launcher and search Terminal.

## Kernel/compiler changes

```powershell
python tools/platform.py stop
python tools/platform.py rebuild
```

The guest compiles compiler/kernel, installs the kernel on its partition and
exits. Inspect `C:/Tmp/RelicCompile.DD` before treating the build as successful.
Then run `sync` to remove the temporary rebuild callback, followed by `start`.
A guest exit alone does not establish build success: BootHDIns catches errors.

The tool generates `build/platform/Kernel-dev.PRJ` from the imported project.
It fixes this managed VM's boot drive to C: and enables automatic AHCI discovery,
avoiding the interactive drive/configuration prompts. The repository's upstream
project remains unchanged. This configuration is specific to the development VM.

## New disk bootstrap

`python tools/platform.py bootstrap` downloads and hash-checks the pinned YDE
bootstrap image, creates a blank disk and boots the existing upstream installer.
Install that base to C:, stop QEMU, run `stage`, then `start`. After the initial
kernel build exits, inspect its compile report, run `sync`, then `start`.
The initial disk was bootstrapped successfully during this work; the latest
complete fresh-disk automation still needs another end-to-end clean-room run.

The tool replaces the upstream distribution callback with a readiness marker;
it does not run the later ISO generation stage. Never run AutoFullDistro5 or
upstream ISO scripts while the user's no-ISO instruction remains in effect.

## Guest checks

From a new Terminal:

```c
ExeFile("::/Home/RelicTests");
ExeFile("::/Home/RelicPaintTests");
```

Launch Web Browser once to compile its stack, then use a Terminal:

```c
CryptoSelfTest;
JsTestRun;
```

Reports from the Relic tests are under `C:/Tmp/`. Browser tests print in the
terminal. To test host HTTP through QEMU SLIRP, run
`python tests/http_fixture.py --port 8767`, then browse
`http://10.0.2.2:8767/ok` in the guest.

`python tools/platform_audit.py` checks every source/asset against the import
manifest. `tools/platform_font.py` needs fontTools; `tools/platform_skin.py`
needs Pillow. Generated UI glyphs preserve the original TempleOS bitmap shape.

## Optional VMware platform disk

`build/platform-vmware/RelicOS.vmx` is a separate development VM using the
flat VMDK copy of the platform disk, not the HolyC recovery VM. It uses SATA
AHCI, PCNet NAT (`ethernet0.virtualDev = "vlance"`) and VNC on localhost:5903. Keyboard and absolute pointer input work over VNC through the adapted
TinkerOS VMware driver.

Stop both source and destination VMs before making or replacing this copy:

```powershell
qemu-img convert -f raw -O vmdk -o subformat=monolithicFlat build/platform/RelicOS.raw build/platform-vmware/RelicOS.vmdk
```

Do not overwrite a disk containing user documents you intend to retain.
`platform.py sync` updates only the QEMU raw disk; it does not update this
separate VMware copy. When copying individual files with mtools, compare
`mtype` output bytes with the host source before booting. Use `mtype` captured
stdout to extract reports, avoiding interactive host-file overwrite prompts.
The FAT32 partition starts at byte 32256 in these specific development disks.

From a platform Terminal, renderer profiling is available with:

```c
GrProfReset; Sleep(10000); GrProfRep;
```

The composition-cost ceiling is not measured display FPS. Frame-start maximums
and counts over 16.667 ms expose scheduling delays; no result establishes a
universal hardware or workload guarantee.
