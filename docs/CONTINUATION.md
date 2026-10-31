# Continuing RelicOS

User constraints: original TempleOS font, matte black/grey/white, automatic
home/desktop startup, broad apps and games, smooth motion and minimum 60 FPS.
No new ISO until the user asks. No commits, pushes or PRs were requested.

Read README.md, docs/VALIDATION.md, docs/UPSTREAM-INTEGRATION.md and
 docs/platform-workflow.md before continuing. `src/relic/` is the working
HolyC recovery baseline; `src/platform/` is the imported ZealC platform.
Do not mix their binaries, kernel APIs or source dialects.

Use actual guest compilation and runtime checks. Static source inspection is
not a substitute. Preserve raw DolDoc/binary bytes in the platform import.
Update the import manifest when changing imported files. Check
`python tools/platform_audit.py` and the host unittest suite.

Known limits: the 60 FPS minimum remains unmet; TLS has no certificate-chain
validation and uses a non-hardened random source; many imported apps/drivers
need runtime coverage. Baseline TinkerOS games need ZealC ports to join the
platform. Retail game data is separate. UT99 is incomplete upstream.

ZealC reads types/functions in one pass. Define them before use. Avoid relying
on declaration initializers to install callbacks. HolyC local fixed-array
string initialization required explicit StrCpy in baseline tests. FileWrite
returns a disk location, not the number of bytes; verify saves by reading back.

Do not modify a running VM's disk from mtools. Stop the relevant VM and verify
it is off first. Keep the recovery VMware disk and platform QEMU disk separate.
No automatic commits, pushes, ISO generation or publication on continuation.

Latest retained platform checks: eight platform checks and five Paint checks
pass under VMware; docs/validation/RelicProfile.txt records actual frame-start
intervals (maximum 18.607 ms, so the requested minimum remains unmet). The new
TinkerOS-derived VMware absolute-pointer driver fixes VNC movement/clicks and
Paint dragging; QEMU still uses USB tablet input. Normal Once files are restored
on both development disks. Read the validation record before claiming results.

Latest UI pass: read docs/UI-REFINEMENT.md. Real platform framebuffer1920x1080;
75Hz desktop sample max14.719ms, no intervals above16.667ms, but no guarantee
under load. Recovery27 checks pass, platform UI6 pass, MP4 media2 pass.
Only Files and Browser pinned. Native media apps remain in platform Start.
Recovery pointer driver must install after stock startup mouse reset; verified
post-reboot. Platform VMware NIC must be PCNet/vlance, not unfinished E1000.
Image viewer now has clickable controls. Legacy platform file manager still
uses DolDoc; broader visual redesign and game/media coverage remain open.

Latest sources synced to both platform disks; both VMware guests stopped after
validation. Import audit:1322 files passed. No ISO produced. Final actual guest
screenshots:build/shots/platform-image-viewer-final.png,
platform-video-player-final.png, recovery-games-final.png.
