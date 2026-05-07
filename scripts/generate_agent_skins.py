from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "containers/minetest/oni_cadia_game/mods/oni_cadia_core/textures"


AGENTS = [
    ("iori", "#1f8ed6", "#8fd3ff", "#26384c"),
    ("tsumugi", "#d89b18", "#ffd479", "#4d3b21"),
    ("saku", "#4fba45", "#b7ff9a", "#24482a"),
    ("ruri", "#6850d9", "#b5a4ff", "#2d284c"),
    ("hibiki", "#dc3e37", "#ff9a9a", "#4c2524"),
    ("kanae", "#1fae8a", "#9affdf", "#20483f"),
    ("kimi", "#c84ed9", "#f4a7ff", "#48264c"),
    ("qwen", "#507bd8", "#a7c7ff", "#25344c"),
    ("minimax", "#d8c33b", "#fff4a7", "#494522"),
]


def rgb(hex_color: str) -> tuple[int, int, int, int]:
    value = hex_color.removeprefix("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), 255)


def shade(color: tuple[int, int, int, int], factor: float) -> tuple[int, int, int, int]:
    return (
        max(0, min(255, int(color[0] * factor))),
        max(0, min(255, int(color[1] * factor))),
        max(0, min(255, int(color[2] * factor))),
        255,
    )


def rect(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], color: tuple[int, int, int, int]) -> None:
    draw.rectangle(xy, fill=color)


def skin(name: str, base_hex: str, accent_hex: str, dark_hex: str) -> Image.Image:
    base = rgb(base_hex)
    accent = rgb(accent_hex)
    dark = rgb(dark_hex)
    skin_tone = rgb("#d9a578")
    hair = shade(dark, 0.72)
    boot = shade(dark, 0.5)

    img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Head: top/bottom/side/front/back for the classic 64x32 Minetest character map.
    rect(d, (8, 0, 15, 7), hair)
    rect(d, (16, 0, 23, 7), shade(skin_tone, 0.78))
    rect(d, (0, 8, 7, 15), shade(skin_tone, 0.9))
    rect(d, (8, 8, 15, 15), skin_tone)
    rect(d, (16, 8, 23, 15), skin_tone)
    rect(d, (24, 8, 31, 15), shade(skin_tone, 0.84))
    rect(d, (8, 8, 23, 10), hair)
    rect(d, (10, 12, 11, 12), dark)
    rect(d, (20, 12, 21, 12), dark)
    rect(d, (14, 14, 17, 14), shade(skin_tone, 0.72))

    # Torso.
    rect(d, (20, 16, 27, 19), shade(base, 1.15))
    rect(d, (28, 16, 35, 19), shade(base, 0.72))
    rect(d, (16, 20, 19, 31), shade(base, 0.88))
    rect(d, (20, 20, 27, 31), base)
    rect(d, (28, 20, 35, 31), shade(base, 0.78))
    rect(d, (36, 20, 39, 31), shade(base, 0.64))
    rect(d, (21, 21, 26, 22), accent)
    rect(d, (23, 20, 24, 31), shade(accent, 0.82))

    # Right arm.
    rect(d, (44, 16, 47, 19), shade(base, 1.08))
    rect(d, (48, 16, 51, 19), shade(base, 0.66))
    rect(d, (40, 20, 43, 31), shade(base, 0.86))
    rect(d, (44, 20, 47, 31), base)
    rect(d, (48, 20, 51, 31), shade(base, 0.75))
    rect(d, (52, 20, 55, 31), shade(base, 0.62))
    rect(d, (44, 28, 47, 31), skin_tone)

    # Left arm.
    rect(d, (36, 48 - 32, 39, 51 - 32), shade(base, 1.08))
    rect(d, (40, 48 - 32, 43, 51 - 32), shade(base, 0.66))
    rect(d, (32, 52 - 32, 35, 63 - 32), shade(base, 0.86))
    rect(d, (36, 52 - 32, 39, 63 - 32), base)
    rect(d, (40, 52 - 32, 43, 63 - 32), shade(base, 0.75))
    rect(d, (44, 52 - 32, 47, 63 - 32), shade(base, 0.62))
    rect(d, (36, 60 - 32, 39, 63 - 32), skin_tone)

    # Legs.
    rect(d, (4, 16, 7, 19), shade(dark, 1.15))
    rect(d, (8, 16, 11, 19), shade(dark, 0.72))
    rect(d, (0, 20, 3, 31), shade(dark, 0.88))
    rect(d, (4, 20, 7, 31), dark)
    rect(d, (8, 20, 11, 31), shade(dark, 0.78))
    rect(d, (12, 20, 15, 31), shade(dark, 0.64))
    rect(d, (4, 29, 7, 31), boot)
    rect(d, (8, 29, 11, 31), boot)

    # Small per-agent glyphs on the torso so close colors are still distinguishable.
    glyph = sum(ord(ch) for ch in name) % 5
    if glyph == 0:
        d.line((21, 24, 26, 29), fill=accent, width=1)
        d.line((26, 24, 21, 29), fill=accent, width=1)
    elif glyph == 1:
        rect(d, (22, 24, 25, 27), accent)
    elif glyph == 2:
        d.line((23, 23, 21, 27, 24, 30, 27, 25), fill=accent, width=1)
    elif glyph == 3:
        d.ellipse((22, 24, 26, 28), outline=accent)
    else:
        d.polygon([(24, 23), (27, 29), (21, 29)], fill=accent)

    return img


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, base, accent, dark in AGENTS:
        skin(name, base, accent, dark).save(OUT_DIR / f"oni_cadia_skin_{name}.png")


if __name__ == "__main__":
    main()
