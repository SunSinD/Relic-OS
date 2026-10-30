# Relic OS - Continuation Prompt

Paste the block below into a new chat with any AI coding assistant to pick up
where the last session stopped.

```
You are working on my repo Relic OS, a fork of TempleOS V5.03 written in HolyC:
https://github.com/SunSinD/Relic-OS
Local clone: <path to your clone> (Windows, VMware Workstation, Python 3)
Plain-text TempleOS source for checking APIs: python tools\tosz.py <file>.HC.Z out.HC (expands any src/templeos .Z file)

Dev loop (already set up and working):
- powershell -ExecutionPolicy Bypass -File tools\relic.ps1 dev
  Powers off the VM, writes src\relic\ to a FAT32 transfer disk, boots the VM.
  The guest's HomeSys.HC copies the new files in and starts the desktop (~25 s).
- tools\relic.ps1 shot  -> build\shots\latest.png (screenshot of the VMware window; VNC misreports moving frames)
- tools\relic.ps1 log   -> prints ::/Home/Boot.LOG from the VM disk
- python tools\vnc.py type "Dir;" --enter   /   python tools\vnc.py key Escape
  Keyboard works over VNC, mouse clicks do not. Desktop keys: F E S G T M I H.
- tools\relic.ps1 iso   -> build\RelicOS-v0.4.0.iso (guest runs Build.HC by itself)
- The VM lives in build\vm\RelicOS (git-ignored). Transfer disk is E: after a dev boot (G: when mounted manually for setup).

Boot chain: HomeSys.HC (dev sync) -> RelicStartUp.HC (UserStartUp/SrvStartUp)
-> RelicBoot.HC -> Theme -> Chrome (status bar) -> Wallpaper -> Install prompt
-> RelicDesktop.HC (dock, apps, Shell task) which includes GamesLauncher.HC -> RunTOOM.HC -> TOOM/.

HolyC rules (each one broke the OS before):
- Never re-declare an already defined function with extern (calls become "Undefined Extern").
- ToI64(x) - U8 is unsigned; convert both sides with ToF64 for signed math.
- HomeSys must keep SrvStartUp or every popup is invisible.
- No continue; define functions before use; Relic Shell lines max 1023 chars.
- Changes to HomeSys.HC apply one boot later; everything else on the next boot.
- Dev sync is opt-in with ::/Home/RelicDev.TXT; that flag must never ship in the ISO.
- Dev discovery checks only FAT32 ATA drives, never an empty CD drive.
- Display goes through RelicDisplay.HC (VMware SVGA II or Bochs VBE); planar VGA in VMs costs ~270 ms per full screen.
  Ctrl+Alt+V returns to VGA (shows debugger/crash text); ::/Home/RelicNoSVGA.TXT forces VGA from boot.
- DOOM controls: mouse or arrows turn, A/D strafe, W/S move, Ctrl or left click fires, Shift runs.
- DOOM mouse look reads the ms_hard.pos delta; never MsSet the cursor every frame (it erases the movement).
- Never rewrite ::/Kernel.BIN.C or ::/0000Boot/* on a running system (boot sectors use disk positions).
- reg is a HolyC keyword; #include on the same line as a statement runs before it.

How to work:
1. Read roadmap/README.md and the files you will touch before editing.
2. Make the change, run tools\relic.ps1 dev, take screenshots over VNC and check the result yourself.
   If something breaks, find the cause in the guest (dump buffers to the transfer disk, read them on the host) instead of guessing.
3. Update roadmap/README.md and CHANGELOG.md, commit with a clear message, push to main.
   Do not commit build/, ISOs, VMDKs or screenshots.

Task for this session:
<describe what you want next, e.g. "Files browser that can navigate folders and open files in the Editor">
```

## Status

v0.4.0 is released. What is done, known issues and what is next:
`roadmap/README.md`. Host checks:
`python -W error::ResourceWarning -m unittest discover -s tests -p "test_*.py"`.
