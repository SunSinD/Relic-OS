"""Build src/relic/Icons.BIN from Fluent UI System Icons (MIT) and RelicOS pixel art.

Icons are 1-bit pixel art, like the TempleOS font, so they stay sharp even
when a VM window stretches the 640x480 screen. Fluent icons are rendered from
the source drawn for that exact pixel size (16 or 20), nudged by up to half a
pixel so their lines land on whole pixels (like font hinting), then
thresholded. Round icons whose strokes cannot land on the grid are hand
drawn. The file still stores 4-bit coverage (0 or 15 here), which
RelicIconDraw (RelicChrome.HC) can blend if softer art is ever added.

    python tools/relic_icons.py            build Icons.BIN
    python tools/relic_icons.py --preview  also write build/iconwork/preview.png
"""
import io
import re
import struct
import sys
import urllib.parse
import urllib.request
from pathlib import Path

import resvg_py
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
FLUENT = ROOT / "assets/icons/fluent"
OUT = ROOT / "src/relic/Icons.BIN"
STYLE = "regular"
SIZES = (16, 20)
FLUENT_SIZES = (16, 20, 24)
# Only the Files list draws at 16; it shows folders and documents.
SMALL = (100, 101)

# Ids match RelicAppGlyph: app_tips[] order, then the shared extras.
ICONS = {
    0: "Folder",
    1: "Document Text",
    2: "Window Console",
    3: "Games",
    4: "Apps List",
    5: "Developer Board",
    6: "Desktop",
    7: "pixel:help",
    8: "Globe",
    9: "Paint Brush",
    10: "Calculator",
    11: "Calendar",
    12: "pixel:gear",
    13: "Note",
    -1: "pixel:logo",
    100: "Document",
    101: "Folder",
}

# Start button: the TempleOS logo (sword and scales), redrawn by hand at
# 20 px so every line lands on the pixel grid. '#' marks a lit pixel.
# Source artwork: assets/templeos-logo-source.png.
LOGO = [
    "....................",
    "................#...",
    "...............##...",
    "..............##....",
    "..............##....",
    ".......########.....",
    "...##############...",
    "....#.......##.#....",
    "...#.#.....##.#.#...",
    "...#.#.....##.#.#...",
    "..#...#...##.#...#..",
    "..#####..##..#####..",
    "...###...##...###...",
    "........##..........",
    "......#####.........",
    "........#...........",
    ".......#............",
    ".......#............",
    "......#.............",
    ".....##.............",
]


# Settings gear and Help: outlines traced one pixel wide.
GEAR = [
    "....................",
    "....................",
    "........####........",
    "........#..#........",
    ".....##.#..#.##.....",
    "....#..#....#..#....",
    "....#..........#....",
    ".....#..####..#.....",
    "..###..#....#..###..",
    "..#....#....#....#..",
    "..#....#....#....#..",
    "..###..#....#..###..",
    ".....#..####..#.....",
    "....#..........#....",
    "....#..#....#..#....",
    ".....##.#..#.##.....",
    "........#..#........",
    "........####........",
    "....................",
    "....................",
]

HELP = [
    "....................",
    "....................",
    "......########......",
    ".....#........#.....",
    "....#..........#....",
    "...#............#...",
    "..#......##......#..",
    "..#.....#..#.....#..",
    "..#........#.....#..",
    "..#.......#......#..",
    "..#......#.......#..",
    "..#......#.......#..",
    "..#..............#..",
    "..#......#.......#..",
    "...#............#...",
    "....#..........#....",
    ".....#........#.....",
    "......########......",
    "....................",
    "....................",
]

PIXEL = {"pixel:logo": LOGO, "pixel:gear": GEAR, "pixel:help": HELP}


def fluent_svg(name, size):
    slug = name.lower().replace(" ", "_")
    path = FLUENT / f"{slug}_{size}_{STYLE}.svg"
    if path.exists():
        return path.read_text(encoding="utf-8")
    url = ("https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/"
           f"{urllib.parse.quote(name)}/SVG/ic_fluent_{slug}_{size}_{STYLE}.svg")
    try:
        data = urllib.request.urlopen(url, timeout=30).read().decode("utf-8")
    except Exception:
        return None
    FLUENT.mkdir(parents=True, exist_ok=True)
    path.write_text(data, encoding="utf-8")
    return data


def source_svg(name, size):
    for s in sorted(FLUENT_SIZES, key=lambda s: (abs(s - size), -s)):
        svg = fluent_svg(name, s)
        if svg:
            return svg
    raise SystemExit(f"No Fluent source for {name}")


def render(svg, size, dx, dy):
    svg = svg.replace('fill="#212121"', 'fill="#ffffff"')
    svg = re.sub(r"(<svg[^>]*>)", r"\g<1>" + f'<g transform="translate({dx} {dy})">', svg, count=1)
    svg = svg.replace("</svg>", "</g></svg>")
    png = resvg_py.svg_to_bytes(svg_string=svg, width=size, height=size)
    img = Image.open(io.BytesIO(bytes(png))).convert("RGBA")
    if img.size != (size, size):
        img = img.resize((size, size), Image.Resampling.LANCZOS)
    return [(a * 15 + 127) // 255 for a in img.getchannel("A").tobytes()]


def coverage(svg, size):
    # Pick the quarter-pixel shift that leaves the fewest half-covered pixels.
    shifts = [(x / 4, y / 4) for x in range(-2, 3) for y in range(-2, 3)]
    fuzz = lambda cov: sum(min(a, 15 - a) for a in cov)
    best = min(shifts, key=lambda o: (fuzz(render(svg, size, *o)), abs(o[0]) + abs(o[1])))
    return bytes(15 if a >= 8 else 0 for a in render(svg, size, *best))


def pixel_coverage(rows, size):
    pad = (size - len(rows)) // 2
    out = bytearray(size * size)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            out[(y + pad) * size + x + pad] = 15 if ch == "#" else 0
    return bytes(out)


def build():
    entries = []
    for icon_id, name in ICONS.items():
        for size in SIZES:
            if size == 16 and icon_id not in SMALL:
                continue
            if name in PIXEL:
                entries.append((icon_id, size, pixel_coverage(PIXEL[name], size)))
            else:
                entries.append((icon_id, size, coverage(source_svg(name, size), size)))
    blob = bytearray(b"RICN" + struct.pack("<I", len(entries)))
    for icon_id, size, cov in entries:
        blob += struct.pack("<iI", icon_id, size) + cov
    OUT.write_bytes(bytes(blob))
    print(f"{OUT} {len(entries)} icons, {len(blob)} bytes")
    return entries


def preview(entries):
    ramp = [0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x38, 0x60, 0x88, 0xBB, 0xDD, 0xEE, 0xFF]
    bg = 0x10
    sheet = Image.new("L", (len(entries) * 26 + 6, 32), bg)
    for c, (icon_id, size, cov) in enumerate(entries):
        for i, a in enumerate(cov):
            lum = bg + (0xFF - bg) * a // 15
            lum = min(ramp, key=lambda v: abs(v - lum))
            sheet.putpixel((6 + c * 26 + i % size, 6 + i // size), lum)
    out = ROOT / "build/iconwork/preview.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.resize((sheet.width * 5, sheet.height * 5), Image.Resampling.NEAREST).save(out)
    print(out)


if __name__ == "__main__":
    built = build()
    if "--preview" in sys.argv:
        preview(built)
