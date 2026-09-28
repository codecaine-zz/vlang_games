#!/usr/bin/env python3
"""Generate studio-grade 512x512 RGBA sprite sheet for Yahtzee Deluxe:
Grid: 64x64 cells (8x8 grid in 512x512 sheet)

Row 0 (Y=0..63):    Ivory Casino Dice (Face 1, Face 2, Face 3, Face 4, Face 5, Face 6, Die Rolling Blur 1, Die Rolling Blur 2)
Row 1 (Y=64..127):  Gold Luxury Dice (Face 1, Face 2, Face 3, Face 4, Face 5, Face 6, Held Lock Glow, Selection Outline)
Row 2 (Y=128..191): Scorecard Category Badges (Aces, Twos, Threes, Fours, Fives, Sixes, 3-Kind, 4-Kind)
Row 3 (Y=192..255): Special Badges (Full House, Small Straight, Large Straight, YAHTZEE Crown, Chance, Trophy, Shaker Cup 1, Shaker Cup 2)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size 64x64


def draw_die(draw: ImageDraw.ImageDraw, ox: int, oy: int, value: int, style: str = "ivory") -> None:
    # 3D Soft Shadow
    draw.rounded_rectangle((ox + 6, oy + 8, ox + 58, oy + 60), radius=10, fill=(10, 20, 15, 110))

    # Base Die Body
    if style == "ivory":
        base_col = (250, 250, 246, 255)
        border_col = (203, 213, 225, 255)
        pip_col = (220, 38, 38, 255) if value in (1, 4) else (15, 23, 42, 255)
    else: # Gold luxury
        base_col = (251, 191, 36, 255)
        border_col = (180, 83, 9, 255)
        pip_col = (120, 53, 15, 255)

    draw.rounded_rectangle((ox + 4, oy + 4, ox + 56, oy + 56), radius=10, fill=base_col, outline=border_col, width=2)
    # Specular gloss bevel
    draw.line([(ox + 10, oy + 6), (ox + 50, oy + 6)], fill=(255, 255, 255, 200), width=2)
    draw.line([(ox + 6, oy + 10), (ox + 6, oy + 50)], fill=(255, 255, 255, 200), width=2)

    # Render Pips
    cx = ox + 30
    cy = oy + 30
    offset = 13
    r = 4

    pips = []
    if value == 1:
        pips = [(cx, cy)]
        r = 6  # Centered large ace pip
    elif value == 2:
        pips = [(cx - offset, cy - offset), (cx + offset, cy + offset)]
    elif value == 3:
        pips = [(cx - offset, cy - offset), (cx, cy), (cx + offset, cy + offset)]
    elif value == 4:
        pips = [(cx - offset, cy - offset), (cx + offset, cy - offset), (cx - offset, cy + offset), (cx + offset, cy + offset)]
    elif value == 5:
        pips = [(cx - offset, cy - offset), (cx + offset, cy - offset), (cx, cy), (cx - offset, cy + offset), (cx + offset, cy + offset)]
    elif value == 6:
        pips = [(cx - offset, cy - offset), (cx + offset, cy - offset), (cx - offset, cy), (cx + offset, cy), (cx - offset, cy + offset), (cx + offset, cy + offset)]

    for px, py in pips:
        draw.ellipse((px - r, py - r, px + r, py + r), fill=pip_col)
        # Specular pip dot
        draw.ellipse((px - r + 1, py - r + 1, px - r + 3, py - r + 3), fill=(255, 255, 255, 220))


def draw_cup(draw: ImageDraw.ImageDraw, ox: int, oy: int, tilt: int = 0) -> None:
    # Leather Casino Shaker Cup
    draw.ellipse((ox + 10, oy + 48, ox + 54, oy + 60), fill=(10, 20, 15, 110))
    # Cup body
    draw.polygon([(ox + 16, oy + 12), (ox + 48, oy + 12), (ox + 42, oy + 52), (ox + 22, oy + 52)], fill=(120, 53, 15, 255), outline=(69, 26, 3, 255), width=2)
    # Leather rim
    draw.ellipse((ox + 14, oy + 8, ox + 50, oy + 18), fill=(180, 83, 9, 255), outline=(69, 26, 3, 255), width=2)
    draw.ellipse((ox + 18, oy + 10, ox + 46, oy + 16), fill=(69, 26, 3, 255))


def draw_yahtzee_crown(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 5-Star Yahtzee Crown Badge
    draw.ellipse((ox + 6, oy + 6, ox + 58, oy + 58), fill=(220, 38, 38, 255), outline=(245, 158, 11, 255), width=3)
    draw.polygon([(ox + 16, oy + 42), (ox + 16, oy + 26), (ox + 24, oy + 32), (ox + 32, oy + 18), (ox + 40, oy + 32), (ox + 48, oy + 26), (ox + 48, oy + 42)], fill=(251, 191, 36, 255), outline=(180, 83, 9, 255), width=2)
    # Jewels
    for jx in [16, 32, 48]:
        draw.ellipse((ox + jx - 2, oy + 20, ox + jx + 2, oy + 24), fill=(239, 68, 68, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0: Ivory Casino Dice (1..6)
    # -------------------------------------------------------------
    for v in range(1, 7):
        draw_die(draw, (v - 1) * C, 0, value=v, style="ivory")

    # -------------------------------------------------------------
    # Row 1: Gold Luxury Dice (1..6)
    # -------------------------------------------------------------
    for v in range(1, 7):
        draw_die(draw, (v - 1) * C, 1 * C, value=v, style="gold")

    # -------------------------------------------------------------
    # Row 3: Cup and YAHTZEE Badge
    # -------------------------------------------------------------
    draw_cup(draw, 0 * C, 3 * C, tilt=0)
    draw_yahtzee_crown(draw, 1 * C, 3 * C)

    out_path = root / "assets" / "sprites" / "yahtzee.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "yahtzee" / "assets" / "sprites" / "yahtzee.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
