#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Sokoban:
Layout:
Row 0 (Y=0..63):    Worker/Player Poses (Down, Up, Left, Right - 64x64 each)
Row 1 (Y=64..127):  Crates (Standard Wooden Crate, Crate on Goal with Gold Glow)
Row 2 (Y=128..191): Floor & Targets (Clean Floor, Goal Target Tile, Active Target)
Row 3 (Y=192..255): Walls (Brick Wall, Steel Reinforced Wall)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_worker(draw: ImageDraw.ImageDraw, ox: int, oy: int, dir_name: str) -> None:
    cx, cy = ox + 32, oy + 32
    # Shadow
    draw.ellipse((cx - 18, cy + 18, cx + 18, cy + 28), fill=(0, 0, 0, 80))

    # Overalls Body (Denim Blue)
    draw.rectangle((cx - 12, cy - 6, cx + 12, cy + 18), fill=(30, 64, 175, 255), outline=(30, 41, 59, 255), width=2)
    # Red Flannel Shirt Underneath
    draw.rectangle((cx - 10, cy - 14, cx + 10, cy - 6), fill=(220, 38, 38, 255))

    # Yellow Construction Hardhat
    draw.polygon([(cx - 16, cy - 16), (cx + 16, cy - 16), (cx + 12, cy - 28), (cx - 12, cy - 28)], fill=(250, 204, 21, 255), outline=(180, 83, 9, 255), width=2)
    draw.line([(cx - 18, cy - 16), (cx + 18, cy - 16)], fill=(234, 179, 8, 255), width=3)

    # Face details based on direction
    if dir_name == "down":
        draw.rectangle((cx - 8, cy - 16, cx + 8, cy - 8), fill=(254, 215, 170, 255))
        draw.rectangle((cx - 5, cy - 14, cx - 2, cy - 11), fill=(15, 23, 42, 255))
        draw.rectangle((cx + 2, cy - 14, cx + 5, cy - 11), fill=(15, 23, 42, 255))
    elif dir_name == "left":
        draw.rectangle((cx - 10, cy - 16, cx + 4, cy - 8), fill=(254, 215, 170, 255))
        draw.rectangle((cx - 8, cy - 14, cx - 5, cy - 11), fill=(15, 23, 42, 255))
    elif dir_name == "right":
        draw.rectangle((cx - 4, cy - 16, cx + 10, cy - 8), fill=(254, 215, 170, 255))
        draw.rectangle((cx + 5, cy - 14, cx + 8, cy - 11), fill=(15, 23, 42, 255))
    # 'up' just shows hardhat back


def draw_crate(draw: ImageDraw.ImageDraw, ox: int, oy: int, on_goal: bool) -> None:
    pad = 4
    x1, y1 = ox + pad, oy + pad
    x2, y2 = ox + 64 - pad, oy + 64 - pad

    # Wood Base Fill
    wood_col = (217, 119, 6, 255) if not on_goal else (245, 158, 11, 255)
    border_col = (146, 64, 14, 255) if not on_goal else (180, 83, 9, 255)

    draw.rectangle((x1, y1, x2, y2), fill=wood_col, outline=border_col, width=3)

    # Diagonal Wood Cross Bracing
    draw.line([(x1 + 4, y1 + 4), (x2 - 4, y2 - 4)], fill=border_col, width=4)
    draw.line([(x1 + 4, y2 - 4), (x2 - 4, y1 + 4)], fill=border_col, width=4)

    # Steel Corner Rivets
    rivet_col = (226, 232, 240, 255) if not on_goal else (52, 211, 153, 255)
    for cx, cy in [(x1 + 6, y1 + 6), (x2 - 6, y1 + 6), (x1 + 6, y2 - 6), (x2 - 6, y2 - 6)]:
        draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=rivet_col, outline=(30, 41, 59, 255), width=1)

    if on_goal:
        # Glowing Emerald Goal Lock Icon
        draw.ellipse((ox + 22, oy + 22, ox + 42, oy + 42), fill=(16, 185, 129, 255), outline=(209, 250, 229, 255), width=2)
        # Checkmark
        draw.line([(ox + 26, oy + 32), (ox + 31, oy + 37), (ox + 39, oy + 26)], fill=(255, 255, 255, 255), width=3)


def draw_target(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Floor Base
    draw.rectangle((ox + 2, oy + 2, ox + 62, oy + 62), fill=(51, 65, 85, 255), outline=(30, 41, 59, 255), width=1)
    # Circular Concentric Target Rings
    draw.ellipse((cx - 18, cy - 18, cx + 18, cy + 18), fill=(30, 41, 59, 255), outline=(239, 68, 68, 255), width=3)
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(239, 68, 68, 255), outline=(254, 202, 202, 255), width=2)
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 255, 255, 255))


def draw_wall(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 3D Beveled Industrial Wall Block
    draw.rectangle((ox, oy, ox + 64, oy + 64), fill=(71, 85, 105, 255), outline=(30, 41, 59, 255), width=2)
    # Brick pattern
    draw.line([(ox, oy + 21), (ox + 64, oy + 21)], fill=(30, 41, 59, 255), width=2)
    draw.line([(ox, oy + 42), (ox + 64, oy + 42)], fill=(30, 41, 59, 255), width=2)
    draw.line([(ox + 32, oy), (ox + 32, oy + 21)], fill=(30, 41, 59, 255), width=2)
    draw.line([(ox + 16, oy + 21), (ox + 16, oy + 42)], fill=(30, 41, 59, 255), width=2)
    draw.line([(ox + 48, oy + 21), (ox + 48, oy + 42)], fill=(30, 41, 59, 255), width=2)
    draw.line([(ox + 32, oy + 42), (ox + 32, oy + 64)], fill=(30, 41, 59, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Worker Poses (Down, Up, Left, Right)
    dirs = ["down", "up", "left", "right"]
    for i, d in enumerate(dirs):
        draw_worker(draw, i * 64, 0, dir_name=d)

    # Row 1: Crates
    draw_crate(draw, 0 * 64, 64, on_goal=False)
    draw_crate(draw, 1 * 64, 64, on_goal=True)

    # Row 2: Target & Floor
    draw_target(draw, 0 * 64, 128)

    # Row 3: Wall
    draw_wall(draw, 0 * 64, 192)

    out_path = root / "assets" / "sprites" / "sokoban.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "sokoban" / "assets" / "sprites" / "sokoban.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
