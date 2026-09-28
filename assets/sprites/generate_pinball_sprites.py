#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Cyber Pinball:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Pinballs (Silver Chrome Steel, Gold Ball, Fireball Plasma, High-Energy Glow)
Row 1 (Y=64..127):  Bumpers & Lights (Bumper Inactive, Bumper Hit 100, Bumper Hit 500, Rollover Light)
Row 2 (Y=128..191): Flippers & Targets (Left Flipper, Right Flipper, Drop Targets 10/J/Q/K/A)
Row 3 (Y=192..255): Mario Sub-Stage (Mario, Lady Pauline, Bouncing Platform, Plunger Knob)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_pinball(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_gold: bool = False, is_fire: bool = False) -> None:
    cx, cy = ox + 32, oy + 32
    r = 20
    if is_fire:
        draw.ellipse((cx - r - 4, cy - r - 4, cx + r + 4, cy + r + 4), fill=(239, 68, 68, 200), outline=(249, 115, 22, 255), width=2)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(254, 240, 138, 255))
        draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(255, 255, 255, 255))
    elif is_gold:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(245, 158, 11, 255), outline=(180, 83, 9, 255), width=2)
        draw.ellipse((cx - 10, cy - 10, cx - 2, cy - 2), fill=(254, 243, 199, 255))
    else:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(203, 213, 225, 255), outline=(100, 116, 139, 255), width=2)
        draw.ellipse((cx - 10, cy - 10, cx - 2, cy - 2), fill=(255, 255, 255, 255))


def draw_bumper(draw: ImageDraw.ImageDraw, ox: int, oy: int, hit: bool = False) -> None:
    cx, cy = ox + 32, oy + 32
    r = 24
    if hit:
        draw.ellipse((cx - r - 4, cy - r - 4, cx + r + 4, cy + r + 4), fill=(255, 255, 255, 180))
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(250, 204, 21, 255), outline=(255, 255, 255, 255), width=2)
        draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(239, 68, 68, 255))
    else:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255), width=2)
        draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(30, 41, 59, 255), outline=(255, 255, 255, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Balls
    draw_pinball(draw, 0 * C, 0, is_gold=False, is_fire=False)
    draw_pinball(draw, 1 * C, 0, is_gold=True, is_fire=False)
    draw_pinball(draw, 2 * C, 0, is_gold=False, is_fire=True)

    # Row 1: Bumpers
    draw_bumper(draw, 0 * C, 1 * C, hit=False)
    draw_bumper(draw, 1 * C, 1 * C, hit=True)

    out_path = root / "assets" / "sprites" / "pinball.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "pinball" / "assets" / "sprites" / "pinball.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
