#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Hyper Air Hockey:
Layout:
Row 0 (Y=0..63):    Strikers / Mallets (P1 Crimson Red, P2 Cobalt Blue, AI Golden Amber, Neon Emerald)
Row 1 (Y=64..127):  Pucks (Classic Black/Gold, Neon Red Laser, Plasma Cyan, Trophy Gold)
Row 2 (Y=128..191): Goal Net Fixtures & LED Goal Lights
Row 3 (Y=192..255): Spark Particles, Winner Trophy & Star Badges
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_mallet(draw: ImageDraw.ImageDraw, ox: int, oy: int, primary_col: tuple[int, int, int], inner_col: tuple[int, int, int]) -> None:
    cx, cy = ox + 32, oy + 32
    r = 28

    # Multi-layer radial striker base
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=primary_col + (255,), outline=(255, 255, 255, 220), width=2)
    draw.ellipse((cx - r + 5, cy - r + 5, cx + r - 5, cy + r - 5), fill=inner_col + (255,))

    # Center grip handle knob
    draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=(245, 245, 250, 255), outline=(30, 41, 59, 255), width=2)
    draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=primary_col + (255,))

    # Glossy specular crescent
    draw.arc((cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3), start=200, end=320, fill=(255, 255, 255, 255), width=3)


def draw_puck(draw: ImageDraw.ImageDraw, ox: int, oy: int, base_col: tuple[int, int, int], rim_col: tuple[int, int, int]) -> None:
    cx, cy = ox + 32, oy + 32
    r = 20

    # Puck body
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=base_col + (255,), outline=rim_col + (255,), width=3)
    draw.ellipse((cx - r + 6, cy - r + 6, cx + r - 6, cy + r - 6), fill=base_col + (255,), outline=(255, 255, 255, 140), width=1)
    draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=rim_col + (255,))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Strikers / Mallets (64x64 each)
    draw_mallet(draw, 0 * 64, 0, (225, 29, 72), (159, 18, 57))      # P1 Red
    draw_mallet(draw, 1 * 64, 0, (37, 99, 235), (29, 78, 216))      # P2 Blue
    draw_mallet(draw, 2 * 64, 0, (217, 119, 6), (180, 83, 9))       # AI Gold
    draw_mallet(draw, 3 * 64, 0, (16, 185, 129), (5, 150, 105))     # Green

    # Row 1: Pucks (64x64 each)
    draw_puck(draw, 0 * 64, 64, (24, 24, 27), (234, 179, 8))        # Classic Black/Gold
    draw_puck(draw, 1 * 64, 64, (225, 29, 72), (254, 205, 211))     # Neon Red Laser
    draw_puck(draw, 2 * 64, 64, (6, 182, 212), (224, 242, 254))     # Plasma Cyan
    draw_puck(draw, 3 * 64, 64, (234, 179, 8), (254, 240, 138))     # Golden Puck

    out_path = root / "assets" / "sprites" / "airhockey.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "airhockey" / "assets" / "sprites" / "airhockey.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
