#!/usr/bin/env python3
"""Generate ultra-sweet, polished 512x512 RGBA sprite sheet for Yoshi's Cookie Bakery:
Grid: 64x64 cells (8x8 grid in 512x512 sheet)

Row 0 (Y=0..63):    Bakery Cookies (Donut, Heart, Flower, Checkered Square, Yoshi Star, Chocolate Swirl, Match Glow Frame, Crumb Burst)
Row 1 (Y=64..127):  Chef Yoshi (Happy Idle, Open Mouth Tongue, Cheering Jump, Sleeping / Waiting)
Row 2 (Y=128..191): Chef Mario (Turning Crank, Holding Tray, Thumbs Up Victory, Shocked Alert)
Row 3 (Y=192..255): Bakery Props (Baking Oven Fire, Conveyor Warning Meter, Golden Star Badge, Stage Clear Trophy)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size 64x64


def draw_donut_cookie(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 3D Soft Shadow
    draw.ellipse((ox + 6, oy + 10, ox + 58, oy + 58), fill=(10, 15, 25, 90))
    # Baked crust ring
    draw.ellipse((ox + 4, oy + 4, ox + 56, oy + 56), fill=(217, 119, 6, 255), outline=(146, 64, 14, 255), width=2)
    # Strawberry Icing
    draw.ellipse((ox + 8, oy + 8, ox + 52, oy + 52), fill=(244, 114, 182, 255), outline=(219, 39, 119, 255))
    # Specular gloss arc
    draw.arc((ox + 12, oy + 12, ox + 48, oy + 48), start=200, end=300, fill=(255, 255, 255, 220), width=3)
    # Center Hole
    draw.ellipse((ox + 22, oy + 22, ox + 38, oy + 38), fill=(40, 30, 25, 255), outline=(146, 64, 14, 255), width=2)
    # Rainbow Sprinkles
    draw.rectangle((ox + 16, oy + 18, ox + 22, oy + 21), fill=(250, 204, 21, 255))
    draw.rectangle((ox + 38, oy + 16, ox + 41, oy + 22), fill=(6, 182, 212, 255))
    draw.rectangle((ox + 34, oy + 42, ox + 40, oy + 45), fill=(255, 255, 255, 255))
    draw.rectangle((ox + 16, oy + 40, ox + 21, oy + 43), fill=(168, 85, 247, 255))


def draw_heart_cookie(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    draw.ellipse((ox + 6, oy + 10, ox + 58, oy + 58), fill=(10, 15, 25, 90))
    # Golden crust heart
    draw.polygon([(ox + 30, oy + 54), (ox + 6, oy + 26), (ox + 14, oy + 8), (ox + 30, oy + 18), (ox + 46, oy + 8), (ox + 54, oy + 26)], fill=(217, 119, 6, 255), outline=(146, 64, 14, 255), width=2)
    # Pink strawberry glaze
    draw.polygon([(ox + 30, oy + 48), (ox + 12, oy + 26), (ox + 18, oy + 14), (ox + 30, oy + 22), (ox + 42, oy + 14), (ox + 48, oy + 26)], fill=(251, 113, 133, 255), outline=(225, 29, 72, 255))
    # Sugar shine
    draw.ellipse((ox + 16, oy + 16, ox + 24, oy + 24), fill=(255, 255, 255, 200))


def draw_flower_cookie(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    draw.ellipse((ox + 6, oy + 10, ox + 58, oy + 58), fill=(10, 15, 25, 90))
    # 5 Petals
    cx, cy = ox + 30, oy + 30
    for a in range(0, 360, 72):
        rad = math.radians(a)
        px = cx + int(math.cos(rad) * 14)
        py = cy + int(math.sin(rad) * 14)
        draw.ellipse((px - 10, py - 10, px + 10, py + 10), fill=(245, 158, 11, 255), outline=(180, 83, 9, 255))
    # Honey amber center
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=2)
    draw.ellipse((cx - 5, cy - 5, cx + 1, cy + 1), fill=(255, 255, 255, 200))


def draw_square_cookie(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    draw.ellipse((ox + 6, oy + 10, ox + 58, oy + 58), fill=(10, 15, 25, 90))
    # Checkered butter & cocoa square cookie
    draw.rounded_rectangle((ox + 6, oy + 6, ox + 54, oy + 54), radius=6, fill=(217, 119, 6, 255), outline=(146, 64, 14, 255), width=2)
    # Checkered 4 quadrants
    draw.rectangle((ox + 10, oy + 10, ox + 29, oy + 29), fill=(254, 240, 138, 255)) # Vanilla
    draw.rectangle((ox + 30, oy + 10, ox + 49, oy + 29), fill=(88, 28, 12, 255))   # Dark Cocoa
    draw.rectangle((ox + 10, oy + 30, ox + 29, oy + 49), fill=(88, 28, 12, 255))   # Dark Cocoa
    draw.rectangle((ox + 30, oy + 30, ox + 49, oy + 49), fill=(254, 240, 138, 255)) # Vanilla


def draw_yoshi_cookie(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    draw.ellipse((ox + 6, oy + 10, ox + 58, oy + 58), fill=(10, 15, 25, 90))
    # Golden Star with Yoshi's Eye
    draw.polygon([
        (ox + 30, oy + 4), (ox + 37, oy + 20), (ox + 54, oy + 20),
        (ox + 41, oy + 32), (ox + 46, oy + 48), (ox + 30, oy + 38),
        (ox + 14, oy + 48), (ox + 19, oy + 32), (ox + 6, oy + 20),
        (ox + 23, oy + 20)
    ], fill=(250, 204, 21, 255), outline=(180, 83, 9, 255), width=2)
    # Yoshi Cute Eye in Center
    draw.ellipse((ox + 24, oy + 20, ox + 32, oy + 32), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
    draw.ellipse((ox + 27, oy + 23, ox + 31, oy + 29), fill=(22, 163, 74, 255))


def draw_swirl_cookie(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    draw.ellipse((ox + 6, oy + 10, ox + 58, oy + 58), fill=(10, 15, 25, 90))
    # Round biscuit with chocolate ganache swirl
    draw.ellipse((ox + 6, oy + 6, ox + 54, oy + 54), fill=(254, 240, 138, 255), outline=(180, 83, 9, 255), width=2)
    # Chocolate spiral
    draw.arc((ox + 12, oy + 12, ox + 48, oy + 48), start=0, end=270, fill=(88, 28, 12, 255), width=4)
    draw.arc((ox + 18, oy + 18, ox + 42, oy + 42), start=180, end=360, fill=(88, 28, 12, 255), width=3)


def draw_yoshi_character(draw: ImageDraw.ImageDraw, ox: int, oy: int, anim: str = "idle") -> None:
    # Chef Yoshi with white chef hat
    draw.ellipse((ox + 12, oy + 48, ox + 52, oy + 60), fill=(10, 15, 25, 100))
    # Yoshi green snout & head
    draw.ellipse((ox + 12, oy + 14, ox + 48, oy + 48), fill=(34, 197, 94, 255), outline=(21, 128, 61, 255), width=2)
    # White lower jaw
    draw.ellipse((ox + 18, oy + 28, ox + 46, oy + 46), fill=(255, 255, 255, 255))
    # Yoshi Big Eyes
    draw.ellipse((ox + 14, oy + 8, ox + 26, oy + 26), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
    draw.ellipse((ox + 26, oy + 8, ox + 38, oy + 26), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
    draw.ellipse((ox + 18, oy + 12, ox + 24, oy + 22), fill=(15, 23, 42, 255))
    draw.ellipse((ox + 28, oy + 12, ox + 34, oy + 22), fill=(15, 23, 42, 255))
    draw.ellipse((ox + 20, oy + 14, ox + 22, oy + 17), fill=(255, 255, 255, 255))
    draw.ellipse((ox + 30, oy + 14, ox + 32, oy + 17), fill=(255, 255, 255, 255))
    # Red saddle crest on head
    draw.polygon([(ox + 38, oy + 16), (ox + 46, oy + 20), (ox + 42, oy + 28)], fill=(239, 68, 68, 255))
    # White Chef Hat (Toque)
    draw.ellipse((ox + 20, oy + 2, ox + 34, oy + 10), fill=(255, 255, 255, 255), outline=(203, 213, 225, 255))
    draw.rectangle((ox + 22, oy + 6, ox + 32, oy + 12), fill=(255, 255, 255, 255), outline=(203, 213, 225, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0: 6 Bakery Cookie Varieties
    # -------------------------------------------------------------
    draw_donut_cookie(draw, 0 * C, 0)
    draw_heart_cookie(draw, 1 * C, 0)
    draw_flower_cookie(draw, 2 * C, 0)
    draw_square_cookie(draw, 3 * C, 0)
    draw_yoshi_cookie(draw, 4 * C, 0)
    draw_swirl_cookie(draw, 5 * C, 0)

    # -------------------------------------------------------------
    # Row 1: Chef Yoshi
    # -------------------------------------------------------------
    draw_yoshi_character(draw, 0 * C, 1 * C, anim="idle")

    out_path = root / "assets" / "sprites" / "yoshicookie.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "yoshicookie" / "assets" / "sprites" / "yoshicookie.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
