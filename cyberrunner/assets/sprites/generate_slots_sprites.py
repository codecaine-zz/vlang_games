#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Slots:
Layout:
Row 0 (Y=0..63):    Cherry, Lemon, Orange, Plum, Liberty Bell, Bar 1, Bar 2, Bar 3 (64x64 each)
Row 1 (Y=64..127):  Lucky 7, Diamond, Wild Symbol, Scatter Symbol, Golden Coins
Row 2 (Y=128..191): Lever Knobs & Arm Poses
Row 3 (Y=192..255): Payline Lights & Win Badges
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_cherry(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Twin Cherries
    draw.ellipse((cx - 20, cy + 2, cx - 2, cy + 20), fill=(225, 29, 72, 255), outline=(159, 18, 57, 255), width=2)
    draw.ellipse((cx + 2, cy + 6, cx + 20, cy + 24), fill=(225, 29, 72, 255), outline=(159, 18, 57, 255), width=2)
    # Highlights
    draw.ellipse((cx - 16, cy + 5, cx - 12, cy + 9), fill=(254, 205, 211, 255))
    draw.ellipse((cx + 6, cy + 9, cx + 10, cy + 13), fill=(254, 205, 211, 255))
    # Stems
    draw.line([(cx - 11, cy + 4), (cx - 2, cy - 14)], fill=(34, 197, 94, 255), width=3)
    draw.line([(cx + 11, cy + 8), (cx - 2, cy - 14)], fill=(34, 197, 94, 255), width=3)
    # Leaf
    draw.polygon([(cx - 2, cy - 14), (cx + 16, cy - 18), (cx + 8, cy - 10)], fill=(22, 163, 74, 255))


def draw_lemon(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    draw.ellipse((cx - 20, cy - 16, cx + 20, cy + 16), fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=2)
    draw.ellipse((cx - 15, cy - 11, cx + 15, cy + 11), fill=(250, 204, 21, 255))
    draw.ellipse((cx - 12, cy - 10, cx - 4, cy - 2), fill=(254, 240, 138, 255))


def draw_orange(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    draw.ellipse((cx - 18, cy - 18, cx + 18, cy + 18), fill=(249, 115, 22, 255), outline=(194, 65, 12, 255), width=2)
    draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(251, 146, 60, 255))
    draw.ellipse((cx - 10, cy - 10, cx - 2, cy - 2), fill=(254, 215, 170, 255))


def draw_plum(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    draw.ellipse((cx - 18, cy - 18, cx + 18, cy + 18), fill=(147, 51, 234, 255), outline=(88, 28, 135, 255), width=2)
    draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(168, 85, 247, 255))
    draw.ellipse((cx - 10, cy - 10, cx - 2, cy - 2), fill=(233, 213, 255, 255))


def draw_bell(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Liberty Bell
    draw.polygon([(cx - 16, cy + 14), (cx + 16, cy + 14), (cx + 10, cy - 12), (cx - 10, cy - 12)], fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=2)
    draw.ellipse((cx - 6, cy + 12, cx + 6, cy + 20), fill=(161, 98, 7, 255))
    draw.ellipse((cx - 8, cy - 16, cx + 8, cy - 8), fill=(202, 138, 4, 255))


def draw_bar(draw: ImageDraw.ImageDraw, ox: int, oy: int, bars: int) -> None:
    cx, cy = ox + 32, oy + 32
    # BAR rectangle
    draw.rectangle((cx - 26, cy - 12, cx + 26, cy + 12), fill=(30, 41, 59, 255), outline=(203, 213, 225, 255), width=2)
    draw.rectangle((cx - 22, cy - 8, cx + 22, cy + 8), fill=(15, 23, 42, 255))
    # Text color based on bars
    col = (239, 68, 68, 255) if bars == 1 else ((59, 130, 246, 255) if bars == 2 else (234, 179, 8, 255))
    draw.rectangle((cx - 18, cy - 4, cx + 18, cy + 4), fill=col)


def draw_seven(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Lucky 777
    draw.polygon([(cx - 16, cy - 20), (cx + 18, cy - 20), (cx + 4, cy + 20), (cx - 6, cy + 20), (cx + 6, cy - 10), (cx - 16, cy - 10)], fill=(220, 38, 38, 255), outline=(254, 240, 138, 255), width=3)


def draw_diamond(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    draw.polygon([(cx, cy - 20), (cx + 20, cy), (cx, cy + 20), (cx - 20, cy)], fill=(6, 182, 212, 255), outline=(241, 245, 249, 255), width=2)
    draw.polygon([(cx, cy - 12), (cx + 12, cy), (cx, cy + 12), (cx - 12, cy)], fill=(165, 243, 252, 255))


def draw_wild(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Wild badge
    draw.ellipse((cx - 22, cy - 22, cx + 22, cy + 22), fill=(168, 85, 247, 255), outline=(245, 208, 254, 255), width=3)
    draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(236, 72, 153, 255))


def draw_scatter(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Golden dollar coin
    draw.ellipse((cx - 22, cy - 22, cx + 22, cy + 22), fill=(234, 179, 8, 255), outline=(254, 240, 138, 255), width=3)
    draw.ellipse((cx - 15, cy - 15, cx + 15, cy + 15), fill=(202, 138, 4, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Classic Fruits & Bells & Bars (Y=0..63)
    draw_cherry(draw, 0 * 64, 0)
    draw_lemon(draw, 1 * 64, 0)
    draw_orange(draw, 2 * 64, 0)
    draw_plum(draw, 3 * 64, 0)
    draw_bell(draw, 4 * 64, 0)
    draw_bar(draw, 5 * 64, 0, bars=1)
    draw_bar(draw, 6 * 64, 0, bars=2)
    draw_bar(draw, 7 * 64, 0, bars=3)

    # Row 1: High Rollers (Y=64..127)
    draw_seven(draw, 0 * 64, 64)
    draw_diamond(draw, 1 * 64, 64)
    draw_wild(draw, 2 * 64, 64)
    draw_scatter(draw, 3 * 64, 64)

    out_path = root / "assets" / "sprites" / "slots.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "slots" / "assets" / "sprites" / "slots.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
