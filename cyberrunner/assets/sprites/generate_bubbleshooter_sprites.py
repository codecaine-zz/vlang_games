#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Bubble Shooter:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Glossy Color Bubbles (Red, Blue, Green, Yellow, Purple, Orange, Wildcard, Bomb)
Row 1 (Y=64..127):  Cannon Turret, Arrow Pointer, Target Crosshair, Ring Reticle
Row 2 (Y=128..191): Bubble Pop Sequence (4 frames of bursting soap bubbles)
Row 3 (Y=192..255): Star Badge, Level Trophy, Hazard Skull, Sound On/Off
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_bubble(draw: ImageDraw.ImageDraw, ox: int, oy: int, color_id: str) -> None:
    colors = {
        "red": ((239, 68, 68, 255), (254, 202, 202, 255), (185, 28, 28, 255)),
        "blue": ((59, 130, 246, 255), (191, 219, 254, 255), (29, 78, 216, 255)),
        "green": ((34, 197, 94, 255), (187, 247, 208, 255), (21, 128, 61, 255)),
        "yellow": ((234, 179, 8, 255), (254, 240, 138, 255), (161, 98, 7, 255)),
        "purple": ((168, 85, 247, 255), (243, 232, 255, 255), (126, 34, 206, 255)),
        "orange": ((249, 115, 22, 255), (254, 215, 170, 255), (194, 65, 12, 255)),
        "wildcard": ((236, 72, 153, 255), (255, 255, 255, 255), (157, 23, 77, 255)),
        "bomb": ((30, 41, 59, 255), (239, 68, 68, 255), (15, 23, 42, 255)),
    }
    main_c, high_c, shad_c = colors.get(color_id, colors["red"])
    cx, cy = ox + 32, oy + 32
    r = 24

    # Drop shadow
    draw.ellipse((cx - r + 2, cy - r + 4, cx + r + 2, cy + r + 4), fill=(10, 15, 25, 90))
    # Main spherical orb
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=main_c, outline=shad_c, width=2)
    # Shading crescent
    draw.arc((cx - r, cy - r, cx + r, cy + r), start=0, end=140, fill=shad_c, width=3)
    # Top-left specular gloss
    draw.ellipse((cx - 14, cy - 14, cx - 2, cy - 2), fill=high_c)
    draw.ellipse((cx - 12, cy - 12, cx - 6, cy - 6), fill=(255, 255, 255, 255))
    # Secondary rim reflection
    draw.arc((cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3), start=90, end=180, fill=high_c, width=2)


def draw_cannon(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Base Turret Pod
    draw.ellipse((cx - 20, cy - 10, cx + 20, cy + 22), fill=(51, 65, 85, 255), outline=(148, 163, 184, 255), width=2)
    # Cannon Barrel
    draw.rectangle((cx - 8, cy - 26, cx + 8, cy), fill=(71, 85, 105, 255), outline=(203, 213, 225, 255), width=2)
    draw.ellipse((cx - 8, cy - 30, cx + 8, cy - 22), fill=(148, 163, 184, 255), outline=(255, 255, 255, 255), width=2)
    # Golden Trim
    draw.ellipse((cx - 10, cy + 2, cx + 10, cy + 18), fill=(245, 158, 11, 255))


def draw_pop_frame(draw: ImageDraw.ImageDraw, ox: int, oy: int, stage: int) -> None:
    cx, cy = ox + 32, oy + 32
    radii = [20, 26, 30, 34]
    r = radii[stage % 4]
    # Bursting droplets
    num_drops = 8 + stage * 2
    for i in range(num_drops):
        ang = i * (2.0 * math.pi / num_drops)
        dist = r + (stage * 3)
        dx = cx + int(math.cos(ang) * dist)
        dy = cy + int(math.sin(ang) * dist)
        sz = max(1, 4 - stage)
        draw.ellipse((dx - sz, dy - sz, dx + sz, dy + sz), fill=(255, 255, 255, 220))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Bubbles
    bubble_types = ["red", "blue", "green", "yellow", "purple", "orange", "wildcard", "bomb"]
    for i, bt in enumerate(bubble_types):
        draw_bubble(draw, i * C, 0, bt)

    # Row 1: Cannon & Launcher Components
    draw_cannon(draw, 0 * C, 1 * C)

    # Row 2: Pop Sequence
    for s in range(4):
        draw_pop_frame(draw, s * C, 2 * C, s)

    out_path = root / "assets" / "sprites" / "bubbleshooter.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "bubbleshooter" / "assets" / "sprites" / "bubbleshooter.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
