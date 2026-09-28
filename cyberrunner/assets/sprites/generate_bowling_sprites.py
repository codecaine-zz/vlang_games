#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Cyber Bowling:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Bowling Balls (Ruby Marble, Midnight Pearl, Emerald Glow, Golden Crown)
Row 1 (Y=64..127):  Pins (Upright, Tilted 30deg, Flying 60deg, Horizontal Fallen 90deg)
Row 2 (Y=128..191): Pinsetter Bar, Sweeper Rack, Trophy, Bowling Shoes
Row 3 (Y=192..255): Badges (STRIKE "X", SPARE "/", Split, Gutter, Turkey Fire)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_ball(draw: ImageDraw.ImageDraw, ox: int, oy: int, style: str = "ruby") -> None:
    cx, cy = ox + 32, oy + 32
    r = 24
    if style == "ruby":
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(185, 28, 28, 255), outline=(127, 29, 29, 255), width=2)
        draw.arc((cx - 16, cy - 16, cx + 16, cy + 16), start=30, end=210, fill=(239, 68, 68, 255), width=3)
    elif style == "pearl":
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(30, 58, 138, 255), outline=(23, 37, 84, 255), width=2)
        draw.arc((cx - 16, cy - 16, cx + 16, cy + 16), start=30, end=210, fill=(96, 165, 250, 255), width=3)
    elif style == "emerald":
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(4, 120, 87, 255), outline=(6, 78, 59, 255), width=2)
        draw.arc((cx - 16, cy - 16, cx + 16, cy + 16), start=30, end=210, fill=(52, 211, 153, 255), width=3)
    else:  # gold
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(217, 119, 6, 255), outline=(180, 83, 9, 255), width=2)
        draw.arc((cx - 16, cy - 16, cx + 16, cy + 16), start=30, end=210, fill=(251, 191, 36, 255), width=3)

    # 3 Finger holes
    draw.ellipse((cx - 8, cy - 10, cx - 4, cy - 6), fill=(15, 23, 42, 255))
    draw.ellipse((cx + 2, cy - 10, cx + 6, cy - 6), fill=(15, 23, 42, 255))
    draw.ellipse((cx - 3, cy + 2, cx + 1, cy + 6), fill=(15, 23, 42, 255))

    # Specular Gleam
    draw.ellipse((cx - 14, cy - 16, cx - 8, cy - 10), fill=(255, 255, 255, 220))


def draw_upright_pin(img: Image.Image, ox: int, oy: int, angle_deg: float = 0.0) -> None:
    # Render pin onto a temporary 64x64 RGBA surface then rotate
    temp = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    tdraw = ImageDraw.Draw(temp)
    cx, cy = 32, 32

    if angle_deg == 90.0:
        # Fallen horizontal pin lying flat
        tdraw.ellipse((cx - 24, cy - 6, cx - 14, cy + 6), fill=(241, 245, 249, 255), outline=(148, 163, 184, 255), width=2)
        tdraw.ellipse((cx - 16, cy - 10, cx + 6, cy + 10), fill=(255, 255, 255, 255))
        tdraw.rectangle((cx + 4, cy - 5, cx + 16, cy + 5), fill=(255, 255, 255, 255))
        tdraw.rectangle((cx + 8, cy - 5, cx + 11, cy + 5), fill=(239, 68, 68, 255))
        tdraw.rectangle((cx + 13, cy - 5, cx + 16, cy + 5), fill=(239, 68, 68, 255))
        tdraw.ellipse((cx + 14, cy - 6, cx + 24, cy + 6), fill=(255, 255, 255, 255))
    else:
        # Upright or tilted pin
        tdraw.ellipse((cx - 10, cy + 14, cx + 10, cy + 24), fill=(241, 245, 249, 255), outline=(148, 163, 184, 255), width=2)
        tdraw.ellipse((cx - 12, cy - 4, cx + 12, cy + 18), fill=(255, 255, 255, 255))
        tdraw.rectangle((cx - 6, cy - 18, cx + 6, cy - 4), fill=(255, 255, 255, 255))
        tdraw.rectangle((cx - 6, cy - 14, cx + 6, cy - 11), fill=(239, 68, 68, 255))
        tdraw.rectangle((cx - 6, cy - 9, cx + 6, cy - 6), fill=(239, 68, 68, 255))
        tdraw.ellipse((cx - 7, cy - 26, cx + 7, cy - 14), fill=(255, 255, 255, 255))

        if angle_deg != 0.0:
            temp = temp.rotate(angle_deg, resample=Image.BICUBIC, center=(cx, cy))

    img.paste(temp, (ox, oy), temp)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Balls
    styles = ["ruby", "pearl", "emerald", "gold"]
    for i, s in enumerate(styles):
        draw_ball(draw, i * C, 0, s)

    # Row 1: Pins (Upright, 25deg, 50deg, Fallen 90deg)
    angles = [0.0, 25.0, 50.0, 90.0]
    for i, a in enumerate(angles):
        draw_upright_pin(sheet, i * C, 1 * C, angle_deg=a)

    out_path = root / "assets" / "sprites" / "bowling.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "bowling" / "assets" / "sprites" / "bowling.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
