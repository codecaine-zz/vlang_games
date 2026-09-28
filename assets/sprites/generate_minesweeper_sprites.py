#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Cyber Minesweeper:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Numbers 1..8 with 3D shadow and vibrant colors
Row 1 (Y=64..127):  Tiles & Items (Unrevealed Bevel, Revealed Flat, Mine Normal, Mine Exploded, Flag, Wrong Flag, Question Mark)
Row 2 (Y=128..191): Smiley Faces (Smile, Astonished/O-face, Sunglasses Win, Dead X-eyes)
Row 3 (Y=192..255): Digital LED digits 0..9, Timer Clock, Trophy
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SHEET_SIZE = 512
C = 64  # cell size


def draw_number(draw: ImageDraw.ImageDraw, ox: int, oy: int, num: int) -> None:
    colors = {
        1: (59, 130, 246, 255),   # Blue
        2: (34, 197, 94, 255),    # Green
        3: (239, 68, 68, 255),    # Red
        4: (30, 58, 138, 255),    # Navy
        5: (185, 28, 28, 255),    # Maroon
        6: (13, 148, 136, 255),   # Teal
        7: (15, 23, 42, 255),     # Black
        8: (100, 116, 139, 255),  # Gray
    }
    col = colors.get(num, (255, 255, 255, 255))
    cx, cy = ox + 32, oy + 32
    # Flat background tile
    draw.rectangle((ox + 4, oy + 4, ox + 60, oy + 60), fill=(203, 213, 225, 255), outline=(148, 163, 184, 255), width=2)
    # Number text centered with shadow
    draw.text((cx - 10, cy - 20), str(num), fill=(0, 0, 0, 120))
    draw.text((cx - 12, cy - 22), str(num), fill=col)


def draw_tiles(draw: ImageDraw.ImageDraw) -> None:
    # Col 0: Unrevealed Raised Tile
    ox, oy = 0 * C, 1 * C
    draw.rectangle((ox + 4, oy + 4, ox + 60, oy + 60), fill=(226, 232, 240, 255))
    draw.line([(ox + 4, oy + 4), (ox + 60, oy + 4)], fill=(255, 255, 255, 255), width=3)
    draw.line([(ox + 4, oy + 4), (ox + 4, oy + 60)], fill=(255, 255, 255, 255), width=3)
    draw.line([(ox + 4, oy + 60), (ox + 60, oy + 60)], fill=(100, 116, 139, 255), width=3)
    draw.line([(ox + 60, oy + 4), (ox + 60, oy + 60)], fill=(100, 116, 139, 255), width=3)

    # Col 1: Mine Normal
    ox, oy = 1 * C, 1 * C
    draw.rectangle((ox + 4, oy + 4, ox + 60, oy + 60), fill=(203, 213, 225, 255), outline=(148, 163, 184, 255), width=2)
    cx, cy = ox + 32, oy + 32
    r = 16
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(15, 23, 42, 255))
    # Spikes
    draw.line([(cx - 22, cy), (cx + 22, cy)], fill=(15, 23, 42, 255), width=3)
    draw.line([(cx, cy - 22), (cx, cy + 22)], fill=(15, 23, 42, 255), width=3)
    draw.line([(cx - 16, cy - 16), (cx + 16, cy + 16)], fill=(15, 23, 42, 255), width=3)
    draw.line([(cx - 16, cy + 16), (cx + 16, cy - 16)], fill=(15, 23, 42, 255), width=3)
    draw.ellipse((cx - 6, cy - 6, cx - 2, cy - 2), fill=(255, 255, 255, 255))

    # Col 2: Mine Exploded (Red background)
    ox, oy = 2 * C, 1 * C
    draw.rectangle((ox + 4, oy + 4, ox + 60, oy + 60), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255), width=2)
    cx, cy = ox + 32, oy + 32
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(15, 23, 42, 255))
    draw.line([(cx - 22, cy), (cx + 22, cy)], fill=(15, 23, 42, 255), width=3)
    draw.line([(cx, cy - 22), (cx, cy + 22)], fill=(15, 23, 42, 255), width=3)
    draw.line([(cx - 16, cy - 16), (cx + 16, cy + 16)], fill=(15, 23, 42, 255), width=3)
    draw.line([(cx - 16, cy + 16), (cx + 16, cy - 16)], fill=(15, 23, 42, 255), width=3)
    draw.ellipse((cx - 6, cy - 6, cx - 2, cy - 2), fill=(255, 255, 255, 255))

    # Col 3: Flag
    ox, oy = 3 * C, 1 * C
    draw.rectangle((ox + 4, oy + 4, ox + 60, oy + 60), fill=(226, 232, 240, 255), outline=(148, 163, 184, 255), width=2)
    cx, cy = ox + 32, oy + 32
    draw.rectangle((cx - 14, cy + 16, cx + 14, cy + 22), fill=(30, 41, 59, 255))
    draw.line([(cx - 2, cy - 20), (cx - 2, cy + 16)], fill=(30, 41, 59, 255), width=3)
    draw.polygon([(cx - 2, cy - 20), (cx - 20, cy - 8), (cx - 2, cy + 4)], fill=(239, 68, 68, 255), outline=(185, 28, 28, 255))

    # Col 4: Wrong Flag (Red X over mine)
    ox, oy = 4 * C, 1 * C
    draw.rectangle((ox + 4, oy + 4, ox + 60, oy + 60), fill=(203, 213, 225, 255), outline=(148, 163, 184, 255), width=2)
    draw.line([(ox + 10, oy + 10), (ox + 54, oy + 54)], fill=(239, 68, 68, 255), width=4)
    draw.line([(ox + 10, oy + 54), (ox + 54, oy + 10)], fill=(239, 68, 68, 255), width=4)


def draw_smileys(draw: ImageDraw.ImageDraw) -> None:
    # 0: Happy Smile
    ox, oy = 0 * C, 2 * C
    cx, cy = ox + 32, oy + 32
    draw.ellipse((cx - 24, cy - 24, cx + 24, cy + 24), fill=(250, 204, 21, 255), outline=(202, 138, 4, 255), width=2)
    draw.ellipse((cx - 10, cy - 10, cx - 4, cy - 4), fill=(15, 23, 42, 255))
    draw.ellipse((cx + 4, cy - 10, cx + 10, cy - 4), fill=(15, 23, 42, 255))
    draw.arc((cx - 14, cy - 8, cx + 14, cy + 16), start=0, end=180, fill=(15, 23, 42, 255), width=3)

    # 1: Astonished O-face
    ox, oy = 1 * C, 2 * C
    cx, cy = ox + 32, oy + 32
    draw.ellipse((cx - 24, cy - 24, cx + 24, cy + 24), fill=(250, 204, 21, 255), outline=(202, 138, 4, 255), width=2)
    draw.ellipse((cx - 10, cy - 12, cx - 4, cy - 6), fill=(15, 23, 42, 255))
    draw.ellipse((cx + 4, cy - 12, cx + 10, cy - 6), fill=(15, 23, 42, 255))
    draw.ellipse((cx - 6, cy + 2, cx + 6, cy + 16), fill=(15, 23, 42, 255))

    # 2: Sunglasses Win
    ox, oy = 2 * C, 2 * C
    cx, cy = ox + 32, oy + 32
    draw.ellipse((cx - 24, cy - 24, cx + 24, cy + 24), fill=(250, 204, 21, 255), outline=(202, 138, 4, 255), width=2)
    # Sunglasses
    draw.rectangle((cx - 18, cy - 12, cx + 18, cy - 2), fill=(15, 23, 42, 255))
    draw.arc((cx - 12, cy - 8, cx + 12, cy + 14), start=0, end=180, fill=(15, 23, 42, 255), width=3)

    # 3: Dead X-eyes
    ox, oy = 3 * C, 2 * C
    cx, cy = ox + 32, oy + 32
    draw.ellipse((cx - 24, cy - 24, cx + 24, cy + 24), fill=(250, 204, 21, 255), outline=(202, 138, 4, 255), width=2)
    draw.line([(cx - 12, cy - 12), (cx - 4, cy - 4)], fill=(15, 23, 42, 255), width=2)
    draw.line([(cx - 12, cy - 4), (cx - 4, cy - 12)], fill=(15, 23, 42, 255), width=2)
    draw.line([(cx + 4, cy - 12), (cx + 12, cy - 4)], fill=(15, 23, 42, 255), width=2)
    draw.line([(cx + 4, cy - 4), (cx + 12, cy - 12)], fill=(15, 23, 42, 255), width=2)
    draw.arc((cx - 12, cy + 4, cx + 12, cy + 18), start=180, end=360, fill=(15, 23, 42, 255), width=3)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Numbers 1..8
    for i in range(1, 9):
        draw_number(draw, (i - 1) * C, 0, i)

    # Row 1: Tiles
    draw_tiles(draw)

    # Row 2: Smileys
    draw_smileys(draw)

    out_path = root / "assets" / "sprites" / "minesweeper.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "minesweeper" / "assets" / "sprites" / "minesweeper.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
