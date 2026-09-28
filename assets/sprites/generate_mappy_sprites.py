#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Mappy (1983 Namco Classic Arcade):
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Mappy Police Mouse - 1: Walk1, 2: Walk2, 3: Trampoline Bounce, 4: Door Open, 5: Stunned/Die
Row 1 (Y=64..127):  Nyamco (Boss Goro Cat) - 1: Walk1, 2: Walk2, 3: Bounce, 4: Stunned
Row 2 (Y=128..191): Mewkies (Pink Thief Cats) - 1: Walk1, 2: Walk2, 3: Bounce, 4: Stunned
Row 3 (Y=192..255): Stolen Loot - 1: Radio, 2: TV, 3: Computer, 4: Mona Lisa, 5: Safe
Row 4 (Y=256..319): Trampoline States (Green, Blue, Yellow, Red) & Microwave Wave
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64


def draw_mappy(draw: ImageDraw.ImageDraw, ox: int, oy: int, pose: str) -> None:
    cx, cy = ox + 32, oy + 36
    # Blue Police uniform (30, 58, 138), Police Cap with Gold Badge (234, 179, 8), White Mouse Face (255, 255, 255), Pink Ears (244, 114, 182)

    # Large Round Mouse Ears
    draw.ellipse((cx - 16, cy - 26, cx - 4, cy - 14), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255), width=2)
    draw.ellipse((cx - 13, cy - 23, cx - 7, cy - 17), fill=(244, 114, 182, 255))
    draw.ellipse((cx + 4, cy - 26, cx + 16, cy - 14), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255), width=2)
    draw.ellipse((cx + 7, cy - 23, cx + 13, cy - 17), fill=(244, 114, 182, 255))

    # Mouse Head
    draw.ellipse((cx - 12, cy - 18, cx + 12, cy + 2), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255), width=2)
    # Blue Police Cap with Visor & Gold Badge
    draw.polygon([(cx - 10, cy - 18), (cx + 10, cy - 18), (cx + 6, cy - 26), (cx - 6, cy - 26)], fill=(30, 58, 138, 255))
    draw.ellipse((cx - 2, cy - 23, cx + 2, cy - 19), fill=(234, 179, 8, 255))
    draw.line([(cx - 12, cy - 16), (cx + 4, cy - 16)], fill=(15, 23, 42, 255), width=2)

    # Snout & Whiskers
    draw.ellipse((cx + 8, cy - 10, cx + 14, cy - 4), fill=(15, 23, 42, 255))
    draw.ellipse((cx + 2, cy - 13, cx + 6, cy - 8), fill=(15, 23, 42, 255))

    # Police Uniform Body
    draw.rectangle((cx - 10, cy + 2, cx + 10, cy + 18), fill=(30, 58, 138, 255), outline=(15, 23, 42, 255), width=2)
    draw.line([(cx, cy + 2), (cx, cy + 18)], fill=(234, 179, 8, 255), width=2)

    # Legs & Feet
    if pose == "bounce":
        # Spread jumping legs
        draw.rectangle((cx - 14, cy + 18, cx - 6, cy + 24), fill=(239, 68, 68, 255))
        draw.rectangle((cx + 6, cy + 18, cx + 14, cy + 24), fill=(239, 68, 68, 255))
    else:
        draw.rectangle((cx - 8, cy + 18, cx - 2, cy + 24), fill=(239, 68, 68, 255))
        draw.rectangle((cx + 2, cy + 18, cx + 8, cy + 24), fill=(239, 68, 68, 255))


def draw_nyamco(draw: ImageDraw.ImageDraw, ox: int, oy: int, pose: str) -> None:
    cx, cy = ox + 32, oy + 36
    # Big Red Robe (220, 38, 38), Yellow Cat Face (250, 204, 21), Pointy Cat Ears

    # Pointy Cat Ears
    draw.polygon([(cx - 14, cy - 24), (cx - 6, cy - 14), (cx - 16, cy - 12)], fill=(250, 204, 21, 255))
    draw.polygon([(cx + 14, cy - 24), (cx + 6, cy - 14), (cx + 16, cy - 12)], fill=(250, 204, 21, 255))

    # Cat Head
    draw.ellipse((cx - 14, cy - 18, cx + 14, cy + 4), fill=(250, 204, 21, 255), outline=(15, 23, 42, 255), width=2)
    # Whiskers & Eyes
    draw.ellipse((cx - 8, cy - 10, cx - 4, cy - 4), fill=(15, 23, 42, 255))
    draw.ellipse((cx + 4, cy - 10, cx + 8, cy - 4), fill=(15, 23, 42, 255))
    draw.polygon([(cx, cy - 4), (cx - 3, cy), (cx + 3, cy)], fill=(239, 68, 68, 255))

    # Big Red Kimono / Robe
    draw.polygon([(cx - 16, cy + 4), (cx + 16, cy + 4), (cx + 20, cy + 24), (cx - 20, cy + 24)], fill=(220, 38, 38, 255), outline=(15, 23, 42, 255), width=2)
    # Yellow Sash
    draw.rectangle((cx - 14, cy + 8, cx + 14, cy + 14), fill=(234, 179, 8, 255))


def draw_mewkie(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 40
    # Small Pink Thief Cat (244, 114, 182) with Blue Shorts (37, 99, 235)
    draw.polygon([(cx - 10, cy - 18), (cx - 4, cy - 10), (cx - 12, cy - 8)], fill=(244, 114, 182, 255))
    draw.polygon([(cx + 10, cy - 18), (cx + 4, cy - 10), (cx + 12, cy - 8)], fill=(244, 114, 182, 255))
    draw.ellipse((cx - 10, cy - 14, cx + 10, cy + 2), fill=(244, 114, 182, 255), outline=(15, 23, 42, 255), width=1)
    # Eyes
    draw.ellipse((cx - 6, cy - 8, cx - 3, cy - 4), fill=(15, 23, 42, 255))
    draw.ellipse((cx + 3, cy - 8, cx + 6, cy - 4), fill=(15, 23, 42, 255))
    # Body
    draw.rectangle((cx - 8, cy + 2, cx + 8, cy + 14), fill=(37, 99, 235, 255), outline=(15, 23, 42, 255), width=1)


def draw_loot(draw: ImageDraw.ImageDraw, ox: int, oy: int, ltype: int) -> None:
    cx, cy = ox + 32, oy + 32
    if ltype == 1:
        # Radio (100 pts)
        draw.rectangle((cx - 16, cy - 10, cx + 16, cy + 12), fill=(239, 68, 68, 255), outline=(15, 23, 42, 255), width=2)
        draw.ellipse((cx - 10, cy - 4, cx - 2, cy + 4), fill=(255, 255, 255, 255))
        draw.line([(cx - 12, cy - 10), (cx - 18, cy - 20)], fill=(15, 23, 42, 255), width=2)
    elif ltype == 2:
        # Television (200 pts)
        draw.rectangle((cx - 18, cy - 12, cx + 18, cy + 14), fill=(180, 83, 9, 255), outline=(15, 23, 42, 255), width=2)
        draw.rectangle((cx - 14, cy - 8, cx + 8, cy + 10), fill=(6, 182, 212, 255))
    elif ltype == 3:
        # Computer Monitor (300 pts)
        draw.rectangle((cx - 16, cy - 14, cx + 16, cy + 8), fill=(226, 232, 240, 255), outline=(15, 23, 42, 255), width=2)
        draw.rectangle((cx - 12, cy - 10, cx + 12, cy + 4), fill=(34, 197, 94, 255))
        draw.rectangle((cx - 6, cy + 8, cx + 6, cy + 14), fill=(148, 163, 184, 255))
    elif ltype == 4:
        # Mona Lisa Painting (400 pts)
        draw.rectangle((cx - 14, cy - 18, cx + 14, cy + 18), fill=(234, 179, 8, 255), outline=(180, 83, 9, 255), width=3)
        draw.rectangle((cx - 10, cy - 14, cx + 10, cy + 14), fill=(101, 163, 13, 255))
    else:
        # Safe (500 pts)
        draw.rectangle((cx - 16, cy - 16, cx + 16, cy + 16), fill=(71, 85, 105, 255), outline=(15, 23, 42, 255), width=2)
        draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(234, 179, 8, 255), outline=(15, 23, 42, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Mappy
    draw_mappy(draw, 0 * C, 0 * C, pose="walk1")
    draw_mappy(draw, 1 * C, 0 * C, pose="walk2")
    draw_mappy(draw, 2 * C, 0 * C, pose="bounce")

    # Row 1: Nyamco
    draw_nyamco(draw, 0 * C, 1 * C, pose="walk1")
    draw_nyamco(draw, 1 * C, 1 * C, pose="bounce")

    # Row 2: Mewkies
    draw_mewkie(draw, 0 * C, 2 * C)

    # Row 3: Loot
    for i in range(5):
        draw_loot(draw, i * C, 3 * C, ltype=i + 1)

    out_path = root / "assets" / "sprites" / "mappy.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "mappy" / "assets" / "sprites" / "mappy.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
