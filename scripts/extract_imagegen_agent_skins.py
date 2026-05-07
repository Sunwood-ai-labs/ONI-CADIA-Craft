from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
REFERENCE_DIR = ROOT / "containers/minetest/oni_cadia_game/mods/oni_cadia_core/textures/generated_reference"
SHEET_SOURCE = REFERENCE_DIR / "imagegen_agent_skin_sheet.png"
INDIVIDUAL_SOURCE_DIR = REFERENCE_DIR / "imagegen_individual"
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


def content_bbox(img: Image.Image) -> tuple[int, int, int, int]:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    min_x, min_y = rgba.width, rgba.height
    max_x, max_y = 0, 0
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _a = pixels[x, y]
            if r > 226 and g > 226 and b > 226 and max(r, g, b) - min(r, g, b) < 14:
                continue
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x + 1)
            max_y = max(max_y, y + 1)
    if min_x >= max_x or min_y >= max_y:
        return (0, 0, img.width, img.height)
    pad_x = max(2, (max_x - min_x) // 80)
    pad_y = max(2, (max_y - min_y) // 80)
    return (
        max(0, min_x - pad_x),
        max(0, min_y - pad_y),
        min(img.width, max_x + pad_x),
        min(img.height, max_y + pad_y),
    )


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    if INDIVIDUAL_SOURCE_DIR.exists():
        for name in NAMES:
            source = INDIVIDUAL_SOURCE_DIR / f"{name}.png"
            cell = Image.open(source).convert("RGB")
            cell = cell.crop(content_bbox(cell))
            skin = cell.resize((64, 32), Image.Resampling.LANCZOS)
            clean_alpha(skin).save(OUT_DIR / f"oni_cadia_skin_{name}.png")
        return

    sheet = Image.open(SHEET_SOURCE).convert("RGB")
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
        cell = cell.crop(content_bbox(cell))
        skin = cell.resize((64, 32), Image.Resampling.LANCZOS)
        clean_alpha(skin).save(OUT_DIR / f"oni_cadia_skin_{name}.png")


if __name__ == "__main__":
    main()
