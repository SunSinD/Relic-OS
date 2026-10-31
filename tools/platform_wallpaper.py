"""Make the 1080p platform wallpaper from the RelicOS Reaper artwork.

The 640x480 pixel art is scaled to 1440x1080 with whole-pixel sampling (no
blur) and centred on black, which matches the artwork's own background.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "src/platform/DE/RelicReaper.PNG"
# Palette indices used by wallpaper.raw: CYAN artwork, DKGRAY texture.
COLOURS = {0: (0, 0, 0), 3: (0, 146, 186), 8: (56, 56, 56)}


def main():
    data = (ROOT / "src/relic/wallpaper.raw").read_bytes()
    art = Image.frombytes("P", (640, 480), data)
    palette = [0] * 768
    for index, rgb in COLOURS.items():
        palette[index * 3:index * 3 + 3] = rgb
    art.putpalette(palette)
    art = art.convert("RGB").resize((1440, 1080), Image.Resampling.NEAREST)
    result = Image.new("RGB", (1920, 1080))
    result.paste(art, (240, 0))
    result.save(OUT, optimize=True)
    print(OUT)


if __name__ == "__main__":
    main()
