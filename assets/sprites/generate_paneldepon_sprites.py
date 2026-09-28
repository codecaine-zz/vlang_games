#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Panel de Pon / Puzzle League:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Panels (Red Heart, Yellow Star, Cyan Diamond, Green Triangle, Purple Moon, Dark Blue Drop, Exclamation, Flash)
Row 1 (Y=64..127):  Cursor & Mascots (Cursor Left, Cursor Right, Fairy Wand, Mascot Furil, Chain Badge, Star Burst)
Row 2 (Y=128..191): Garbage Blocks (Metal Block Single, Metal Eye Left, Metal Eye Right, Metal Star, Garland Brick)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_panel(draw: ImageDraw.ImageDraw, ox: int, oy: int, ptype: int) -> None:
    cx, cy = ox + 32, oy + 32
    r = 26

    colors = {
        1: ((239, 68, 68, 255), (254, 202, 202, 255), (153, 27, 27, 255)),   # Red Heart
        2: ((234, 179, 8, 255), (254, 240, 138, 255), (161, 98, 7, 255)),    # Yellow Star
        3: ((6, 182, 212, 255), (207, 250, 254, 255), (14, 116, 144, 255)),  # Cyan Diamond
        4: ((34, 197, 94, 255), (187, 247, 208, 255), (21, 128, 61, 255)),   # Green Triangle
        5: ((168, 85, 247, 255), (243, 232, 255, 255), (107, 33, 168, 255)), # Purple Moon
        6: ((59, 130, 246, 255), (191, 219, 254, 255), (29, 78, 216, 255)),  # Blue Drop
        7: ((249, 115, 22, 255), (254, 215, 170, 255), (194, 65, 12, 255)),  # Orange Exclamation
        8: ((255, 255, 255, 255), (255, 255, 255, 255), (226, 232, 240, 255)), # Starburst Flash
    }

    base, high, shadow = colors.get(ptype, colors[1])

    # 3D Beveled Rounded Block
    draw.rounded_rectangle((cx - r, cy - r, cx + r, cy + r), radius=8, fill=base, outline=(15, 23, 42, 255), width=2)
    # Highlight Bevel
    draw.line([(cx - r + 4, cy - r + 3), (cx + r - 4, cy - r + 3)], fill=high, width=3)
    draw.line([(cx - r + 3, cy - r + 4), (cx - r + 3, cy + r - 4)], fill=high, width=3)
    # Shadow Bevel
    draw.line([(cx - r + 4, cy + r - 3), (cx + r - 4, cy + r - 3)], fill=shadow, width=3)
    draw.line([(cx + r - 3, cy - r + 4), (cx + r - 3, cy + r - 4)], fill=shadow, width=3)

    # Center Embossed Icon
    if ptype == 1:
        # Red Heart
        draw.polygon([(cx, cy + 12), (cx - 12, cy - 2), (cx - 6, cy - 12), (cx, cy - 6), (cx + 6, cy - 12), (cx + 12, cy - 2)], fill=(255, 255, 255, 255))
    elif ptype == 2:
        # Yellow Star
        draw.polygon([(cx, cy - 14), (cx + 4, cy - 4), (cx + 14, cy - 2), (cx + 6, cy + 5), (cx + 9, cy + 14), (cx, cy + 8), (cx - 9, cy + 14), (cx - 6, cy + 5), (cx - 14, cy - 2), (cx - 4, cy - 4)], fill=(255, 255, 255, 255))
    elif ptype == 3:
        # Cyan Diamond
        draw.polygon([(cx, cy - 14), (cx + 12, cy), (cx, cy + 14), (cx - 12, cy)], fill=(255, 255, 255, 255))
    elif ptype == 4:
        # Green Triangle
        draw.polygon([(cx, cy - 14), (cx + 13, cy + 12), (cx - 13, cy + 12)], fill=(255, 255, 255, 255))
    elif ptype == 5:
        # Purple Moon
        draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=(255, 255, 255, 255))
        draw.ellipse((cx - 6, cy - 14, cx + 14, cy + 6), fill=base)
    elif ptype == 6:
        # Blue Drop
        draw.polygon([(cx, cy - 14), (cx + 11, cy + 4), (cx, cy + 14), (cx - 11, cy + 4)], fill=(255, 255, 255, 255))
    elif ptype == 7:
        # Exclamation
        draw.rectangle((cx - 4, cy - 14, cx + 4, cy + 4), fill=(255, 255, 255, 255))
        draw.ellipse((cx - 4, cy + 8, cx + 4, cy + 16), fill=(255, 255, 255, 255))
    else:
        # Flash
        draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(251, 191, 36, 255))


def draw_cursor(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_left: bool = True) -> None:
    cx, cy = ox + 32, oy + 32
    r = 28
    col = (255, 255, 255, 255)
    shadow = (15, 23, 42, 255)
    if is_left:
        # Left Bracket [
        draw.line([(cx + 20, cy - r), (cx - r, cy - r)], fill=shadow, width=6)
        draw.line([(cx - r, cy - r), (cx - r, cy + r)], fill=shadow, width=6)
        draw.line([(cx - r, cy + r), (cx + 20, cy + r)], fill=shadow, width=6)
        draw.line([(cx + 20, cy - r), (cx - r, cy - r)], fill=col, width=4)
        draw.line([(cx - r, cy - r), (cx - r, cy + r)], fill=col, width=4)
        draw.line([(cx - r, cy + r), (cx + 20, cy + r)], fill=col, width=4)
    else:
        # Right Bracket ]
        draw.line([(cx - 20, cy - r), (cx + r, cy - r)], fill=shadow, width=6)
        draw.line([(cx + r, cy - r), (cx + r, cy + r)], fill=shadow, width=6)
        draw.line([(cx + r, cy + r), (cx - 20, cy + r)], fill=shadow, width=6)
        draw.line([(cx - 20, cy - r), (cx + r, cy - r)], fill=col, width=4)
        draw.line([(cx + r, cy - r), (cx + r, cy + r)], fill=col, width=4)
        draw.line([(cx + r, cy + r), (cx - 20, cy + r)], fill=col, width=4)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Panels 1..8
    for i in range(8):
        draw_panel(draw, i * C, 0 * C, ptype=i + 1)

    # Row 1: Cursor Left & Right
    draw_cursor(draw, 0 * C, 1 * C, is_left=True)
    draw_cursor(draw, 1 * C, 1 * C, is_left=False)

    out_path = root / "assets" / "sprites" / "paneldepon.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "paneldepon" / "assets" / "sprites" / "paneldepon.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
