# YDE platform import

`src/platform/` imports the YDE `src/` tree at
`ab4bc69e1e7f2a74563a4960fd1020b5c55dae4d`. YDE builds on ZealOS, itself a
TempleOS fork. This is a separate ZealC platform alongside the stock HolyC
recovery baseline under `src/relic/`.

The platform kernel has compiled and booted from a development disk. The desktop,
start menu, calculator, Paint and Zinc browser have been exercised. All 40
upstream JS fixture comparisons and seven crypto known-answer tests passed.
This is not a claim that all imported apps or hardware drivers work.
No ISO was generated. See [validation](VALIDATION.md).

## Inventory and provenance

The pinned YDE tree has 1,341 blobs under `src/`. Of those, 1,301 were imported;
238 missing assets were fetched at that exact commit. Every original blob was
verified against Git's blob SHA-1 before adaptation. The manifest records
original hashes, current adapted hashes, added files and exclusions:
`research/upstream/platform-import.json`.

`python tools/platform_audit.py` verifies every current platform file, checks
unchanged files against upstream blob hashes, and rejects unrecorded additions.
Raw binary and DolDoc bytes are preserved; the nested `.gitattributes` prevents
Git's root newline rule from rewriting the platform tree.

Imported areas include kernel/compiler, compositor, desktop/widgets, Zinc,
image/video decoders, yPainter/yViewer/yVideo/yTracker, audio/mixer/drivers,
network protocols and clients, game engines, docs and stock apps.

## RelicOS adaptations

- Matte black/grey desktop, taskbar, widgets and chrome; no default photo wallpaper.
- Automatic desktop startup with the first terminal minimized, plus a simple
  original-font RELIC loading screen. The small eased indicator becomes static
  under reduced motion and clears after actual boot completion.
- Original TempleOS 8x8 printable glyphs, plus row-doubled original glyphs for
  the optional 8x16 cell. UISANS/UIMONO TTFs contain square outlines generated
  from those same bitmap pixels, rather than a different UI/browser typeface.
- Kernel font slots 2 through 13 remain blank for ZealOS control handling.
  CJK fallback stays separately licensed because TempleOS has no CJK glyphs.
- The scheduler targets exactly 60 Hz. This does not establish a minimum FPS.
- Launcher opening uses a 160 ms cubic ease-out slide, bypassed by Reduced motion.
- Menu callback installation executes explicitly. Browser readiness is only set
  after all modules compile, concurrent launches wait, and failure shows a message.
- TLS's CTLS type is declared before helper functions using it, fixing an actual
  one-pass compilation failure. Browser status identifies unverified TLS identity.
- Browser welcome page and Paint interface use neutral colours; artwork and web
  page colours remain content-controlled.
- Paint decodes layered files before replacing the open drawing, validates
  lengths/version and limits memory; damaged files preserve existing work.
- Music player uses newly generated matte assets and original-font labels;
  partial image loads are cleaned up and text spacing matches the font.
- Kernel/compiler rebuild and source sync tools operate on a development disk.
- TinkerOS's VMware absolute pointer is adapted to ZealC and runtime display
  bounds, with a VMware vendor check before backdoor probing. Movement and
  desktop clicks now work through VMware VNC; QEMU keeps its USB tablet.
- Terminal startup uses the existing palette's dark background and skips stock
  tips/directory output. Settings fits a 720p display without overlapping panels.
- The renderer profiler snapshots counters before printing and records frame
  intervals separately from composition cost.

`tools/platform_font.py` and `tools/platform_skin.py` regenerate the original
RelicOS font outlines and skin. Rebuild the kernel after bitmap font changes.
The manifest's per-file notes are the detailed change ledger.

## Excluded upstream assets

40 upstream blobs are intentionally excluded: 22 unlicensed photo wallpapers,
seven copyrighted classic Winamp skin images, their duplicate PNG demo image,
and ten third-party ANSI examples with no stated license. The seven image paths
now used by the music player hold newly drawn RelicOS assets, not upstream art.
No retail game data or emulator ROMs were present in this imported tree.

## Game ports and licensing

Quake/QuakePlus, Half-Life and Diablo launchers check for separately supplied
game data before running. Quake needs `id1/PAK0.PAK`, Half-Life needs retail
`valve/`, and Diablo needs `DIABDAT.MPQ`. OpenEmpire requires its own game data.
UT99 remains hidden because upstream marks the client incomplete.
The baseline TinkerOS games are not yet ZealC ports.

YDE's root Unlicense is retained as `UPSTREAM-LICENSE.TXT`. Component exceptions
remain: CJK OFL, Devilution's non-commercial Sustainable Use terms, Valve SDK
terms, and individual decoder/source notices. See [NOTICE.md](../NOTICE.md).
A public release needs a component-level distribution review.

## Practical limits

The browser's TLS does not validate certificate chains/signatures and uses
RandU32-derived randomness, not a hardened CSPRNG. Passing primitive vectors
is not evidence of authenticated HTTPS. Modern website compatibility is partial.
Many imported clients, games and hardware drivers remain untested at runtime.
The requested minimum 60 FPS and complete desktop animation system remain open.
See [disk workflow](platform-workflow.md) and [feature ledger](UPSTREAM-INTEGRATION.md).
