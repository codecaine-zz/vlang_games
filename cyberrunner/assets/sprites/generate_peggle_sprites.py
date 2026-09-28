#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Peggle:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Glowing Pegs (Blue Peg Normal & Lit, Orange Peg Normal & Lit, Purple Peg, Green Peg)
Row 1 (Y=64..127):  Brick Pegs (Blue Brick, Orange Brick, Purple Brick, Green Brick)
Row 2 (Y=128..191): Launcher Cannon, Silver Metal Ball, Flaming Energy Ball, Super Ball
Row 3 (Y=192..255): Free Ball Bucket (Left Wing, Center Basin, Right Wing), Multiplier Star Badges
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_peg(draw: ImageDraw.ImageDraw, ox: int, oy: int, color_type: str, is_lit: bool = False) -> None:
    colors = {
        "blue": ((59, 130, 246, 255), (191, 219, 254, 255), (29, 78, 216, 255)),
        "orange": ((249, 115, 22, 255), (254, 215, 170, 255), (194, 65, 12, 255)),
        "purple": ((168, 85, 247, 255), (243, 232, 255, 255), (126, 34, 206, 255)),
        "green": ((34, 197, 94, 255), (187, 247, 208, 255), (21, 128, 61, 255)),
    }
    main_c, high_c, shad_c = colors.get(color_type, colors["blue"])
    cx, cy = ox + 32, oy + 32
    r = 20

    if is_lit:
        # Intense glowing outer corona
        draw.ellipse((cx - r - 6, cy - r - 6, cx + r + 6, cy + r + 6), fill=(255, 255, 255, 160))
        draw.ellipse((cx - r - 3, cy - r - 3, cx + r + 3, cy + r + 3), fill=high_c)

    # Core spherical jewel peg
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=main_c, outline=shad_c, width=2)
    # Shading crescent
    draw.arc((cx - r, cy - r, cx + r, cy + r), start=0, end=140, fill=shad_c, width=3)
    # Specular glint
    draw.ellipse((cx - 10, cy - 10, cx - 2, cy - 2), fill=high_c)
    draw.ellipse((cx - 8, cy - 8, cx - 4, cy - 4), fill=(255, 255, 255, 255))


def draw_brick_peg(draw: ImageDraw.ImageDraw, ox: int, oy: int, color_type: str) -> None:
    colors = {
        "blue": ((59, 130, 246, 255), (191, 219, 254, 255), (29, 78, 216, 255)),
        "orange": ((249, 115, 22, 255), (254, 215, 170, 255), (194, 65, 12, 255)),
        "purple": ((168, 85, 247, 255), (243, 232, 255, 255), (126, 34, 206, 255)),
        "green": ((34, 197, 94, 255), (187, 247, 208, 255), (21, 128, 61, 255)),
    }
    main_c, high_c, shad_c = colors.get(color_type, colors["blue"])
    draw.rectangle((ox + 6, oy + 20, ox + 58, oy + 44), fill=main_c, outline=shad_c, width=2)
    draw.line([(ox + 7, oy + 21), (ox + 57, oy + 21)], fill=high_c, width=2)


def draw_peggle_cannon(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Golden Ornate Launcher Barrel
    draw.ellipse((cx - 24, cy - 18, cx + 24, cy + 18), fill=(245, 158, 11, 255), outline=(254, 243, 199, 255), width=2)
    draw.rectangle((cx - 10, cy - 8, cx + 10, cy + 24), fill=(217, 119, 6, 255), outline=(254, 243, 199, 255), width=2)
    draw.ellipse((cx - 10, cy + 20, cx + 10, cy + 28), fill=(245, 158, 11, 255))


def draw_silver_ball(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    r = 16
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(226, 232, 240, 255), outline=(100, 116, 139, 255), width=2)
    draw.ellipse((cx - 8, cy - 8, cx - 2, cy - 2), fill=(255, 255, 255, 255))


def draw_bucket(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Ornate moving catcher bucket
    draw.rectangle((ox + 4, oy + 18, ox + 60, oy + 46), fill=(245, 158, 11, 255), outline=(254, 243, 199, 255), width=2)
    draw.ellipse((ox + 8, oy + 12, ox + 56, oy + 24), fill=(180, 83, 9, 255), outline=(254, 243, 199, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Glowing Pegs
    draw_peg(draw, 0 * C, 0, "blue", is_lit=False)
    draw_peg(draw, 1 * C, 0, "blue", is_lit=True)
    draw_peg(draw, 2 * C, 0, "orange", is_lit=False)
    draw_peg(draw, 3 * C, 0, "orange", is_lit=True)
    draw_peg(draw, 4 * C, 0, "purple", is_lit=False)
    draw_peg(draw, 5 * C, 0, "green", is_lit=False)

    # Row 1: Brick Pegs
    draw_brick_peg(draw, 0 * C, 1 * C, "blue")
    draw_brick_peg(draw, 1 * C, 1 * C, "orange")
    draw_brick_peg(draw, 2 * C, 1 * C, "purple")
    draw_brick_peg(draw, 3 * C, 1 * C, "green")

    # Row 2: Cannon & Silver Ball
    draw_peggle_cannon(draw, 0 * C, 2 * C)
    draw_silver_ball(draw, 1 * C, 2 * C)

    # Row 3: Bucket
    draw_bucket(draw, 0 * C, 3 * C)

    out_path = root / "assets" / "sprites" / "peggle.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "peggle" / "assets" / "sprites" / "peggle.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
