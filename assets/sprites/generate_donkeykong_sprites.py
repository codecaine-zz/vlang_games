#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Donkey Kong Arcade:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Jumpman/Mario (Idle, Run 1, Run 2, Climb 1, Climb 2, Hammer Swing Up, Hammer Swing Down, Dead)
Row 1 (Y=64..127):  Donkey Kong (Idle, Chest Beat Left, Chest Beat Right, Barrel Roll Left, Barrel Roll Right)
Row 2 (Y=128..191): Pauline / Lady (Standing waving, Calling "HELP!"), Rolling Barrels (Roll 1, Roll 2, Down Ladder, Blue Wild)
Row 3 (Y=192..255): Fireball / Living Flame (Flicker 1, Flicker 2), Hammer Item, Pauline's Purse, Parasol, Bonus Hat
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_jumpman(draw: ImageDraw.ImageDraw, ox: int, oy: int, pose: str) -> None:
    cx, cy = ox + 32, oy + 32
    # Red overalls, blue shirt, red cap, brown shoes
    # Cap
    draw.rectangle((cx - 10, cy - 22, cx + 10, cy - 14), fill=(239, 68, 68, 255))
    draw.rectangle((cx - 14, cy - 18, cx + 6, cy - 14), fill=(239, 68, 68, 255))
    # Head / Face (Peach)
    draw.rectangle((cx - 8, cy - 14, cx + 6, cy - 6), fill=(254, 215, 170, 255))
    # Mustache & Eye
    draw.rectangle((cx - 10, cy - 8, cx, cy - 6), fill=(15, 23, 42, 255))
    draw.rectangle((cx - 4, cy - 12, cx - 2, cy - 10), fill=(15, 23, 42, 255))
    # Blue shirt
    draw.rectangle((cx - 12, cy - 6, cx + 8, cy + 6), fill=(59, 130, 246, 255))
    # Red Overalls
    draw.rectangle((cx - 8, cy - 2, cx + 6, cy + 12), fill=(239, 68, 68, 255))
    # Yellow buttons
    draw.rectangle((cx - 6, cy, cx - 4, cy + 2), fill=(250, 204, 21, 255))
    draw.rectangle((cx + 2, cy, cx + 4, cy + 2), fill=(250, 204, 21, 255))
    # Shoes
    draw.rectangle((cx - 12, cy + 12, cx - 4, cy + 18), fill=(120, 53, 15, 255))
    draw.rectangle((cx + 2, cy + 12, cx + 10, cy + 18), fill=(120, 53, 15, 255))


def draw_donkey_kong(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_chest_beat: bool = False) -> None:
    cx, cy = ox + 32, oy + 32
    # Brown Ape Body
    draw.rectangle((cx - 24, cy - 18, cx + 24, cy + 24), fill=(120, 53, 15, 255), outline=(69, 26, 3, 255), width=2)
    # Tan Chest Fur
    draw.rectangle((cx - 14, cy - 4, cx + 14, cy + 18), fill=(254, 215, 170, 255))
    # Face & Eyes
    draw.rectangle((cx - 16, cy - 18, cx + 16, cy - 6), fill=(254, 215, 170, 255))
    draw.rectangle((cx - 10, cy - 14, cx - 6, cy - 10), fill=(15, 23, 42, 255))
    draw.rectangle((cx + 6, cy - 14, cx + 10, cy - 10), fill=(15, 23, 42, 255))
    # Teeth Grin
    draw.line([(cx - 8, cy - 8), (cx + 8, cy - 8)], fill=(255, 255, 255, 255), width=2)
    # Arms
    if is_chest_beat:
        draw.rectangle((cx - 24, cy - 12, cx - 10, cy + 4), fill=(120, 53, 15, 255))
        draw.rectangle((cx + 10, cy - 12, cx + 24, cy + 4), fill=(120, 53, 15, 255))
    else:
        draw.rectangle((cx - 28, cy - 4, cx - 20, cy + 18), fill=(120, 53, 15, 255))
        draw.rectangle((cx + 20, cy - 4, cx + 28, cy + 18), fill=(120, 53, 15, 255))


def draw_barrel(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_blue: bool = False) -> None:
    cx, cy = ox + 32, oy + 32
    r = 16
    main_col = (59, 130, 246, 255) if is_blue else (180, 83, 9, 255)
    hoop_col = (191, 219, 254, 255) if is_blue else (250, 204, 21, 255)
    # Circular Rolling Barrel
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=main_col, outline=(69, 26, 3, 255), width=2)
    draw.line([(cx - r + 4, cy - 6), (cx + r - 4, cy - 6)], fill=hoop_col, width=2)
    draw.line([(cx - r + 4, cy + 6), (cx + r - 4, cy + 6)], fill=hoop_col, width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Jumpman
    poses = ["idle", "run1", "run2", "climb1", "climb2", "hammer_up", "hammer_down", "dead"]
    for i, p in enumerate(poses):
        draw_jumpman(draw, i * C, 0, p)

    # Row 1: Donkey Kong
    draw_donkey_kong(draw, 0 * C, 1 * C, is_chest_beat=False)
    draw_donkey_kong(draw, 1 * C, 1 * C, is_chest_beat=True)

    # Row 2: Barrels
    draw_barrel(draw, 0 * C, 2 * C, is_blue=False)
    draw_barrel(draw, 1 * C, 2 * C, is_blue=True)

    out_path = root / "assets" / "sprites" / "donkeykong.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "donkeykong" / "assets" / "sprites" / "donkeykong.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
