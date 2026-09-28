#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Cyber Breakout / Arkanoid:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Paddles & Balls (Normal Paddle, Laser Paddle, Silver Ball, Fireball Ball)
Row 1 (Y=64..127):  Jewel Bricks (Ruby Red, Sapphire Blue, Emerald Green, Topaz Yellow)
Row 2 (Y=128..191): Special Bricks (Amethyst Purple, Armored Silver, Gold Steel, Explosive TNT)
Row 3 (Y=192..255): Power-Up Capsules (Laser L, Expand E, Catch C, Multi-Ball M)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_paddle(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_laser: bool = False) -> None:
    # 3D Cyber Vaus Paddle (fills 64x20 rectangle from oy to oy+20)
    # Body
    draw.rectangle((ox + 6, oy + 2, ox + 58, oy + 18), fill=(226, 232, 240, 255), outline=(100, 116, 139, 255), width=2)
    # Red/Cyan Endcaps
    draw.ellipse((ox + 2, oy + 2, ox + 12, oy + 18), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255))
    draw.ellipse((ox + 52, oy + 2, ox + 62, oy + 18), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255))
    # Center Specular Ridge
    draw.line([(ox + 10, oy + 5), (ox + 54, oy + 5)], fill=(255, 255, 255, 255), width=2)

    if is_laser:
        # Dual Laser Cannons
        draw.rectangle((ox + 8, oy, ox + 12, oy + 6), fill=(239, 68, 68, 255))
        draw.rectangle((ox + 52, oy, ox + 56, oy + 6), fill=(239, 68, 68, 255))


def draw_ball(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_fire: bool = False) -> None:
    # 32x32 tight circle inside ox, oy
    cx, cy = ox + 16, oy + 16
    r = 15
    if is_fire:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(239, 68, 68, 255), outline=(249, 115, 22, 255), width=2)
        draw.ellipse((cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3), fill=(254, 240, 138, 255))
        draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(255, 255, 255, 255))
    else:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(203, 213, 225, 255), outline=(100, 116, 139, 255), width=2)
        draw.ellipse((cx - 8, cy - 8, cx - 2, cy - 2), fill=(255, 255, 255, 255))


def draw_brick(draw: ImageDraw.ImageDraw, ox: int, oy: int, color_name: str) -> None:
    colors = {
        "red": ((239, 68, 68, 255), (254, 202, 202, 255), (185, 28, 28, 255)),
        "blue": ((59, 130, 246, 255), (191, 219, 254, 255), (29, 78, 216, 255)),
        "green": ((34, 197, 94, 255), (187, 247, 208, 255), (21, 128, 61, 255)),
        "yellow": ((234, 179, 8, 255), (254, 240, 138, 255), (161, 98, 7, 255)),
        "purple": ((168, 85, 247, 255), (243, 232, 255, 255), (126, 34, 206, 255)),
        "silver": ((203, 213, 225, 255), (255, 255, 255, 255), (100, 116, 139, 255)),
        "gold": ((245, 158, 11, 255), (254, 243, 199, 255), (180, 83, 9, 255)),
        "tnt": ((220, 38, 38, 255), (254, 240, 138, 255), (30, 41, 59, 255)),
    }
    main_c, high_c, shad_c = colors.get(color_name, colors["red"])

    # 3D Chamfered Brick Body (58x26)
    draw.rectangle((ox + 3, oy + 19, ox + 61, oy + 45), fill=main_c, outline=shad_c, width=2)
    # Bevel Highlights
    draw.line([(ox + 4, oy + 20), (ox + 60, oy + 20)], fill=high_c, width=2)
    draw.line([(ox + 4, oy + 20), (ox + 4, oy + 44)], fill=high_c, width=2)
    # Gem facet glint
    draw.rectangle((ox + 26, oy + 28, ox + 38, oy + 36), fill=high_c)


def draw_capsule(draw: ImageDraw.ImageDraw, ox: int, oy: int, label: str = "L", color_type: str = "red") -> None:
    # Pill Capsule Shape
    colors = {
        "red": (239, 68, 68, 255),
        "blue": (59, 130, 246, 255),
        "green": (34, 197, 94, 255),
        "cyan": (6, 182, 212, 255),
    }
    col = colors.get(color_type, (239, 68, 68, 255))
    cx, cy = ox + 32, oy + 32
    draw.rectangle((cx - 16, cy - 10, cx + 16, cy + 10), fill=col, outline=(255, 255, 255, 255), width=2)
    draw.ellipse((cx - 24, cy - 10, cx - 8, cy + 10), fill=col, outline=(255, 255, 255, 255), width=2)
    draw.ellipse((cx + 8, cy - 10, cx + 24, cy + 10), fill=col, outline=(255, 255, 255, 255), width=2)
    draw.text((cx - 4, cy - 8), label, fill=(255, 255, 255, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Paddles & Balls
    draw_paddle(draw, 0 * C, 0, is_laser=False)
    draw_paddle(draw, 1 * C, 0, is_laser=True)
    draw_ball(draw, 2 * C, 0, is_fire=False)
    draw_ball(draw, 3 * C, 0, is_fire=True)

    # Row 1: Jewel Bricks
    draw_brick(draw, 0 * C, 1 * C, "red")
    draw_brick(draw, 1 * C, 1 * C, "blue")
    draw_brick(draw, 2 * C, 1 * C, "green")
    draw_brick(draw, 3 * C, 1 * C, "yellow")

    # Row 2: Special Bricks
    draw_brick(draw, 0 * C, 2 * C, "purple")
    draw_brick(draw, 1 * C, 2 * C, "silver")
    draw_brick(draw, 2 * C, 2 * C, "gold")
    draw_brick(draw, 3 * C, 2 * C, "tnt")

    # Row 3: Capsules
    draw_capsule(draw, 0 * C, 3 * C, label="L", color_type="red")
    draw_capsule(draw, 1 * C, 3 * C, label="E", color_type="blue")
    draw_capsule(draw, 2 * C, 3 * C, label="C", color_type="green")
    draw_capsule(draw, 3 * C, 3 * C, label="M", color_type="cyan")

    out_path = root / "assets" / "sprites" / "breakout.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "breakout" / "assets" / "sprites" / "breakout.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
