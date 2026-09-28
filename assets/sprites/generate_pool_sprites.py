#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for 8-Ball / 9-Ball Pool:
Layout:
Row 0-1 (Y=0..127): 16 Billiard Balls (0: Cue ball, 1-7: Solids, 8: 8-ball, 9-15: Stripes) - 32x32 each
Row 2 (Y=128..191): Cue Sticks, Chalk Cube, Pocket Plates
Row 3 (Y=192..255): Table Badges & Power Meter Indicators
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512

BALL_COLORS = [
    (250, 248, 242),  # 0: Cue (Ivory)
    (250, 215, 35),   # 1: Yellow
    (30, 85, 220),    # 2: Blue
    (225, 45, 45),    # 3: Red
    (125, 40, 170),   # 4: Purple
    (245, 120, 25),   # 5: Orange
    (28, 140, 65),    # 6: Green
    (140, 30, 30),    # 7: Maroon / Brown
    (18, 18, 20),     # 8: Black 8-Ball
    (250, 215, 35),   # 9: Yellow Stripe
    (30, 85, 220),    # 10: Blue Stripe
    (225, 45, 45),    # 11: Red Stripe
    (125, 40, 170),   # 12: Purple Stripe
    (245, 120, 25),   # 13: Orange Stripe
    (28, 140, 65),    # 14: Green Stripe
    (140, 30, 30),    # 15: Maroon Stripe
]


def draw_ball(draw: ImageDraw.ImageDraw, ox: int, oy: int, num: int) -> None:
    cx, cy = ox + 16, oy + 16
    r = 14
    color = BALL_COLORS[num]
    is_stripe = (num >= 9)

    # 1. Radial Spherical Shading
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r:
                # Shading light from top-left (-5, -5)
                lx, ly = dx + 4, dy + 4
                light_dist = math.sqrt(lx * lx + ly * ly)
                norm_light = max(0.0, 1.0 - (light_dist / (r * 2.2)))
                factor = 0.35 + norm_light * 0.9

                pix_col = color
                if is_stripe:
                    # White polar caps
                    if dy < -4 or dy > 4:
                        pix_col = (245, 242, 235)

                pr = int(min(255, pix_col[0] * factor))
                pg = int(min(255, pix_col[1] * factor))
                pb = int(min(255, pix_col[2] * factor))

                # Specular gloss point
                if lx * lx + ly * ly <= 4:
                    pr, pg, pb = 255, 255, 255

                draw.point((cx + dx, cy + dy), fill=(pr, pg, pb, 255))

    # 2. Number Badge Circle
    if num > 0:
        draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(252, 250, 245, 255), outline=(30, 41, 59, 180), width=1)
    else:
        # Red dot on cue ball
        draw.point((cx + 1, cy), fill=(220, 40, 40, 255))


def draw_chalk(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 16, oy + 16
    draw.rectangle((cx - 10, cy - 10, cx + 10, cy + 10), fill=(30, 58, 138, 255), outline=(15, 23, 42, 255), width=1)
    draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(59, 130, 246, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Balls 0..7 (32x32 each)
    for i in range(8):
        draw_ball(draw, i * 32, 0, i)

    # Row 1: Balls 8..15 (32x32 each)
    for i in range(8):
        draw_ball(draw, i * 32, 32, i + 8)

    # Row 2: Chalk & Accessories
    draw_chalk(draw, 0 * 32, 64)

    out_path = root / "assets" / "sprites" / "pool.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "pool" / "assets" / "sprites" / "pool.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
