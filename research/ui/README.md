# Desktop refinement references

Consulted 2026-10-30 for the desktop refinement, alongside the actual upstream
HolyC/ZealC rendering and input code.

- [Windows layout](https://learn.microsoft.com/en-us/windows/apps/design/layout/layouts-with-xaml):
  alignment, margins and padding give controls predictable relationships.
  Apply consistent gutters and keep controls within the content bounds.
- [GNOME header bars](https://developer.gnome.org/hig/patterns/containers/header-bars.html):
  keep a small set of relevant controls, group related actions, and leave empty
  space. Apply dedicated toolbars instead of scattered instruction strings.
- [Apple motion](https://developer.apple.com/design/human-interface-guidelines/motion):
  use motion purposefully, make it optional, and retain other forms of feedback.
  Preserve reduced-motion settings and immediate input feedback.

These principles inform the layout; they do not imply that RelicOS uses any
of these systems' UI libraries. The original TempleOS bitmap font is retained.
The recovery compositor remains 640x480. Genuine 1920x1080 is requested by the
separate ZealC platform kernel, with the existing VBE fallback when unavailable.
