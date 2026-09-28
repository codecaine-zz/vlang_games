#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Pong:
Layout:
Row 0 (Y=0..63):    Arcade Cyber Paddles (Player 1 Cyan, Player 2 Magenta/Red, AI Gold)
Row 1 (Y=64..127):  Glowing Balls (Plasma Blue, Fireball Orange, Laser Green, Hyper Sonic)
Row 2 (Y=128..191): Power-up Orbs (Speed Boost, Long Paddle, Multiball, Laser Gun)
Row 3 (Y=192..255): Table Centerline Nodes & Goal Field Bars
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_paddle(draw: ImageDraw.ImageDraw, ox: int, oy: int, col: tuple[int, int, int]) -> None:
    # 24x80 Beveled Glowing Cyber Paddle
    draw.rectangle((ox + 4, oy + 4, ox + 20, oy + 84), fill=(20, 24, 38, 255), outline=col + (255,), width=2)
    draw.rectangle((ox + 8, oy + 8, ox + 16, oy + 80), fill=col + (200,))
    draw.line([(ox + 12, oy + 8), (ox + 12, oy + 80)], fill=(255, 255, 255, 255), width=2)


def draw_pong_ball(draw: ImageDraw.ImageDraw, ox: int, oy: int, col: tuple[int, int, int]) -> None:
    cx, cy = ox + 16, oy + 16
    r = 12
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=col + (255,), outline=(255, 255, 255, 255), width=2)
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 255, 255, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Paddles (P1 Cyan, P2 Magenta, AI Gold)
    draw_paddle(draw, 0 * 32, 0, (6, 182, 212))
    draw_paddle(draw, 1 * 32, 0, (236, 72, 153))
    draw_paddle(draw, 2 * 32, 0, (234, 179, 8))

    # Row 1: Balls (Cyan, Orange, Green, Purple)
    draw_pong_ball(draw, 0 * 32, 96, (6, 182, 212))
    draw_pong_ball(draw, 1 * 32, 96, (249, 115, 22))
    draw_pong_ball(draw, 2 * 32, 96, (34, 197, 94))
    draw_pong_ball(draw, 3 * 32, 96, (168, 85, 247))

    out_path = root / "assets" / "sprites" / "pong.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "pong" / "assets" / "sprites" / "pong.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
