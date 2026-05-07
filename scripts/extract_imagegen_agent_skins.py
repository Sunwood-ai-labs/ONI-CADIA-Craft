from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "containers/minetest/oni_cadia_game/mods/oni_cadia_core/textures/generated_reference/imagegen_agent_skin_sheet.png"
OUT_DIR = ROOT / "containers/minetest/oni_cadia_game/mods/oni_cadia_core/textures"

NAMES = [
    "iori",
    "tsumugi",
    "saku",
    "ruri",
    "hibiki",
    "kanae",
    "kimi",
    "qwen",
    "minimax",
]


def clean_alpha(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if r > 226 and g > 226 and b > 226 and max(r, g, b) - min(r, g, b) < 14:
                pixels[x, y] = (r, g, b, 0)
    return rgba


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(SOURCE).convert("RGB")
    cell_w = sheet.width // 3
    cell_h = sheet.height // 3
    for index, name in enumerate(NAMES):
        col = index % 3
        row = index // 3
        left = col * cell_w
        upper = row * cell_h
        right = sheet.width if col == 2 else (col + 1) * cell_w
        lower = sheet.height if row == 2 else (row + 1) * cell_h
        cell = sheet.crop((left, upper, right, lower))
        skin = cell.resize((64, 32), Image.Resampling.LANCZOS)
        clean_alpha(skin).save(OUT_DIR / f"oni_cadia_skin_{name}.png")


if __name__ == "__main__":
    main()
