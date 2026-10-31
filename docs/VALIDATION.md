# Validation record

Development checks on Windows 11, 2026-10-30. No new ISO was generated.
A successful compile or imported source file does not establish daily-driver
readiness. Results below distinguish actual guest checks from untested imports.

## Host checks

`python -W error::ResourceWarning -m unittest discover -s tests -p "test_*.py"`:
5 passed. Covers compressed TempleOS source and FAT32 image creation/extraction.
Python development tools also passed `py_compile`.
`python tools/platform_audit.py` passed for all 1,317 platform files, including
unchanged upstream blob hashes. A stopped-disk byte audit checked 1,315 runtime
source/assets on each development disk; both matched the repository with zero
mismatches. The two excluded paths were Git metadata `.gitattributes` and the
intentional disk-only AutoFullDistro4 readiness callback that prevents ISO creation.
Both VMs were stopped after validation. The screenshot below is from the actual
VMware guest, showing Paint and Calculator:

[Guest screenshot](validation/platform-desktop.png)

## ZealC platform

Environment: QEMU TCG, q35, 2 GB RAM, four virtual cores, AHCI disk, RTL8139
with SLIRP networking, AC97 and USB tablet, 1280x720 truecolour framebuffer.

| Check | Observed result |
|---|---|
| Kernel/compiler build and disk boot | Rebuilt compiler (zero errors/warnings) and kernel (zero errors, 31 warnings); installed and booted the new kernel |
| Desktop/start menu | Matte desktop and taskbar shown; search opens apps |
| Zinc full stack compilation | Successful after correcting CTLS declaration order |
| Crypto known-answer vectors | Seven pass: SHA256, HMAC, HKDF, ChaCha20, Poly1305, AEAD, X25519 |
| JavaScript fixtures | 40 pass, zero fail; captured [report](validation/platform-browser.txt) |
| Real guest HTTP | Browser renders `http://10.0.2.2:8767/ok` served by host fixture |
| Calculator | Keyboard input `12+30=` displays 42 |
| Paint | Compiles, opens, brush strokes appear in canvas and navigator |
| UI/browser font | Original glyph shape visible, including enlarged browser text and menu labels |
| Multiwindow rendering | 204 updates / 9.974 guest seconds = 20.454 FPS with several apps open |

The FPS result is a QEMU software-emulation measurement, not a guaranteed
hardware bound or a strict frame-time test. A 60 Hz timer is not proof of 60 FPS.
Results for the HolyC recovery baseline are separate from platform results.

The rebuild transcript is retained in [platform-kernel-build.txt](validation/platform-kernel-build.txt).
It includes DolDoc parser diagnostics from malformed `FG24/BG24` comment text,
separate from the compiler error counts. Those source comments have been fixed.

A separate copy of the platform disk also booted in VMware Workstation:
2 GB RAM, four cores, SATA AHCI and E1000 NAT, 1280x720. Reports retained:

- [Eight platform checks](validation/RelicPlatformTests.txt): original A glyph,
  settings key boundaries/defaults/string limits, zero-size output, saved
  preferences, PNG skin decoding and disk write/readback. All passed.
- [Five Paint checks](validation/RelicPaintTests.txt): layered round trip,
  truncated input preserves the open document, negative length rejection,
  saved document reopening and TGA export. All passed.
- The latest platform check run reports 60.012 FPS on average, with 596 updates
  over about 9.93 guest seconds. Earlier VMware runs measured 59.921 and
  60.022 FPS. These are guest-time averages; none establishes a minimum or actual presentation FPS.
- Music opens with the original matte skin, generates the test tone and closes
  with Escape. This VM has no sound device, so audible playback is unverified.
- Calendar opens; Right changes October to November 2026.
- Settings opens with its footer visible at 720p. A visual check caught the
  saver/system panel overlap; the source now uses separate panel rectangles.
- The retained [renderer profile](validation/RelicProfile.txt) samples 595
  frames: 3.824 ms average composition, 16.760 ms average frame-start interval,
  18.607 ms maximum, and 329 intervals over the 16.667 ms budget. QEMU was off.
  The maximum corresponds to about 53.7 FPS for that interval, so the minimum
  requirement remains unmet. These TSC-based intervals are distinct from guest
  PIT-clock averages and are not display-synchronization measurements.
  A concurrent QEMU TCG boot caused much longer VMware stalls; it is not the
  retained isolated profile. The profiler now snapshots counters before printing
  and supplies floating-point values to floating-point formats.

The VMware VNC pointer was initially frozen while keyboard input worked.
The adapted TinkerOS VMware absolute-pointer driver compiled at boot and fixed
VNC movement/clicks. Actual clicks opened the launcher, launched Settings,
toggled Reduced motion and closed Settings. Paint brush dragging also works.
Stopped-disk inspection confirmed
`motion 0` persisted; the VMware guest rebooted with that preference.
QEMU USB tablet input remains functional with the VMware vendor guard.
Both targets boot directly to the desktop again with normal startup callbacks.
Quake without PAK0.PAK shows the expected data-install message. Full Quake
runtime and raw mouse capture in games remain untested.

## TempleOS/HolyC baseline

VMware Workstation, 2 GB RAM, four cores, PCNet NAT, existing linear framebuffer.
15 core checks passed: BMP save/read, truncated image rejection, HTML/link/script
handling, bounded long pages, default settings and relative URL cases. Six
network parsing/decoder checks then passed after fixing local array setup in
the test harness, for 21 checks with zero failures. A fresh run is retained in
[SELFTEST.TXT](validation/SELFTEST.TXT), averaging 60.024 FPS over 9.929 seconds.

Core refresh samples averaged 60.022 to 60.026 FPS over about ten guest seconds.
Instantaneous FPS varied below 60, so this does not meet the requested minimum.
Autoboot selected the installed disk without a key. The latest recovery-menu
Escape timing still needs a clean retest; an early key hit VMware's BIOS menu.

Browser fetched 3,961 bytes from NeverSSL over public HTTP. Local HTTP fixture
connections through VMware were blocked before reaching the host server.
An older extracted SELFTEST.TXT therefore shows three HTTP fixture failures;
the negative cases in that run also do not count as parser passes because the
fixture was unreachable. The harness now preflights reachability before running.
A scoped Windows firewall rule could not be added (access denied).

Tetris launched with movement/rotation/hard drop; Scorch launched and fired.
Sudoku and Chess opened. Full game progression, save/reload and AI coverage
remain incomplete. Files/Notes/Paint/settings were exercised during development;
not every action and disk failure path has a regression test.

## Not established

- Minimum 60 FPS, frame-time consistency, display synchronization or smooth
  animations under all supported workloads.
- Authenticated HTTPS or safe private-account browsing. Certificate validation
  and a hardened random source are missing upstream.
- Full browser conformance or modern website compatibility.
- Runtime correctness of every imported mail/chat/SSH/git/media app and game engine.
- Real-hardware AHCI/NVMe/USB/Wi-Fi/audio compatibility, install/upgrade/recovery
  reliability, suspend/resume, isolation or crash containment.
- Complete integration of the baseline games into the ZealC platform.

## Latest UI pass (supersedes older resolution/refresh observations)

Actual 1920x1080 boot verified under QEMU and VMware after kernel rebuild
(zero errors, 31 warnings). Original TempleOS glyphs and the Reaper wallpaper
retained. Both desktops have only Browser and Files pinned beside Start.

- Platform: eight existing checks and six new UI checks passed at 1080p.
- Recovery: 21 core/network checks and six UI checks passed. Retained reports
  SELFTEST.TXT / UITEST.TXT average 75.032 guest updates per second.
- 75 Hz platform profile: 756 intervals, mean 13.220 ms, maximum 14.719 ms,
  zero above 16.667 ms, mean composition 8.423 ms. Retained in
  Relic75Profile-1080.txt. All-workload minimum 60 FPS is still unestablished.
- Platform native media: PNG 1920x1080 rendered; MP4 H.264 baseline 48/48
  frames decoded/presented, final PTS 3.917 s, seek-to-start passed.
  RelicMediaTests-1080.txt is the guest decoder transcript. Silent generated
  fixture does not verify audio. AVI unsupported, AV1 inter frames unsupported.
- Recovery mouse clicks work after reboot with the new absolute-pointer
  driver installed after stock mouse initialization. Files double-click,
  create, rename, copy and delete-cancel checked with VNC.
- Browser pin opened native Zinc with PCNet VMware adapter. E1000 is WIP and
  does not implement the generic packet API required by Ethernet.ZC.
  Public HTTP rendering from Zinc was not confirmed in this pass.

See UI-REFINEMENT.md for exact scope and remaining visual limitations.
