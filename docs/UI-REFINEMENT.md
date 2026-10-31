# Desktop and application refinement

Work requested from the recovery desktop screenshots on 2026-10-30. No ISO
was created. The original TempleOS bitmap glyphs remain in both targets.

## Platform

- Kernel requests 1920x1080; retains upstream VBE fallback when unavailable.
  The rebuilt kernel compiled with zero errors and 31 warnings, and QEMU
  reported an actual 1920x1080 framebuffer.
- The blue Reaper artwork is the default wallpaper, made at 1080p with
  `python tools/platform_wallpaper.py` (whole-pixel scaling, centred on black).
- Bottom taskbar has a grid launcher, only Files and Browser pinned, and right-aligned date, FPS and clock.
  Date format is month/day/year.
- Calculator has larger, evenly spaced buttons and a contained display/footer.
  Division by zero also clears the pending-operation label.
- Games opens a clickable library for Quake, QuakePlus, Half-Life, Diablo and
  OpenEmpire. Distinct upstream vector symbols identify the engines. Launches
  check for game data and explain what is missing. Game data is not bundled;
  engine source availability does not establish gameplay compatibility.
- `help;` prints common terminal commands. `Help;` opens the complete system
  help index.

## Recovery target

The stock TempleOS compositor remains 640x480 with its original font and
palette. It cannot become a native 1080p desktop by enlarging a framebuffer
copy. The ZealC platform is the development target for genuine high resolution.
Recovery game ports and platform game engines use different APIs.

DOOM mouse turning is reduced from 0.35 to 0.25 degrees per mouse pixel.
The desktop cursor sensitivity is unchanged. The recovery shell accepts
`help` and shows common commands; `Help;` retains the complete stock help.

## Evidence and limits

Host unittest suite: five passed. Platform import hashes were checked after
the edits. Kernel transcript: `validation/platform-1080-kernel-build.txt`.
Six platform UI checks passed in the guest; see `validation/RelicUITests-1080.txt`.
Recovery passed 21 core/network checks and six calculator/help checks; see
`validation/SELFTEST.TXT` and `validation/UITEST.TXT`.

The 75 Hz platform profile sampled 756 intervals: average 13.220 ms, maximum
14.719 ms, none over 16.667 ms. This meets the frame budget in that desktop
sample, not a guaranteed minimum across browsers, games or host presentation.
Recovery averaged 75.032 guest updates per second.

References: [layout and motion notes](../research/ui/README.md).

## Latest interaction and media checks

- Recovery has a full-width bottom taskbar with only Files and Browser pinned;
  other apps remain in Start. Folder/globe glyphs are larger and clearer.
- Recovery Files create-folder, create-file, rename, copy, delete-cancel and
  double-click folder opening were exercised through VNC. Fixed immediate
  mouse mode suppressing stock double-click messages by detecting repeat row
  clicks locally. Editor opens directly without the stock file picker.
- Paint unsaved close shows Save / Don't save / Cancel. Cancel retains the
  canvas; Don't save returns to desktop. Full save-error paths need more work.
- Recovery VMware pointer uses TinkerOS's backdoor protocol with TempleOS
  types/APIs. Installation runs after the stock startup mouse reset; clicks
  work after reboot. Physical machines retain the stock driver via CPUID guard.
- Platform Image Viewer decodes the 1080p PNG, fits it and offers gallery,
  original size and fullscreen. Added clickable toolbar controls. Gallery and Fullscreen were clicked in the
  guest; the final filename/toolbar spacing was verified after reboot.
- Platform Video Player opens MP4; all 48 H.264 baseline test frames decoded
  with increasing timestamps, final PTS 3.917 s, then seek-to-start passed.
  Playback, pause, restart and seek were exercised. Minimum window width is
  640 px so transport labels fit. AVI is rejected. AV1 remains keyframe-only;
  H.264 8x8 transform and broader codec compatibility remain unsupported.
- Media programs are in Start as Image Viewer and Video Player, not pinned.
  Recovery does not have these full media decoders.
- VMware platform must use PCNet (`ethernet0.virtualDev = "vlance"`), since
  the imported E1000 driver is unfinished and fails network compilation.
  Browser pin opened Zinc after changing the development VM adapter. Public
  HTTP page rendering was not confirmed in this pass; TLS authentication
  remains missing upstream.
- Boot completion now uses explicit callback setup and removes redundant
  extern declarations that shadowed the readiness flag. Splash clears and
  Ctrl+Alt+T opens a full-height terminal after boot.

No ISO, commits, pushes or PRs were created. Legacy platform windows and the
stock file manager still need visual refinement; importing source does not
mean every application or game has been validated for daily use.
