#!/usr/bin/env python3
"""Generate high-definition kawaii jelly pixel-art sprite sheet for Puyo Puyo."""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

TILE_SIZE = 48
COLS = 6
ROWS = 4
WIDTH = COLS * TILE_SIZE
HEIGHT = ROWS * TILE_SIZE

# Palette definition: (Base, Highlight, Shadow, Deep Shadow)
PUYO_PALETTES = {
    "red": ((245, 55, 75), (255, 170, 185), (180, 20, 40), (120, 10, 25)),
    "green": ((45, 210, 75), (160, 255, 180), (20, 140, 45), (10, 85, 25)),
    "blue": ((35, 145, 250), (165, 220, 255), (15, 80, 180), (10, 45, 120)),
    "yellow": ((255, 215, 30), (255, 250, 160), (205, 150, 10), (140, 95, 5)),
    "purple": ((195, 65, 245), (235, 170, 255), (135, 25, 175), (85, 10, 115)),
    "garbage": ((200, 210, 225), (255, 255, 255), (140, 150, 170), (90, 100, 120)),
}


def draw_kawaii_puyo(draw: ImageDraw.ImageDraw, x: int, y: int, pal_key: str, expression: str = "normal") -> None:
    base, high, shad, deep_shad = PUYO_PALETTES[pal_key]
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    r = 18

    # 1. Soft Drop Shadow
    draw.ellipse((cx - r + 1, cy - r + 3, cx + r + 1, cy + r + 3), fill=(10, 15, 25, 90))

    # 2. Main Jelly Spherical Body
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=base, outline=deep_shad, width=2)

    # 3. Bottom & Side Crescent Shading
    draw.arc((cx - r + 2, cy - r + 2, cx + r - 2, cy + r - 2), start=30, end=150, fill=shad, width=4)

    # 4. Top-Left Gloss Specular Highlight
    draw.ellipse((cx - 12, cy - 13, cx - 4, cy - 7), fill=high)
    draw.ellipse((cx - 14, cy - 7, cx - 11, cy - 4), fill=high)

    # 5. Kawaii Expressive Eyes
    if expression == "normal":
        # Left Eye (Big glossy anime eye)
        draw.ellipse((cx - 9, cy - 3, cx - 3, cy + 6), fill=(255, 255, 255), outline=deep_shad, width=1)
        draw.ellipse((cx - 7, cy - 1, cx - 4, cy + 4), fill=(20, 20, 30))
        draw.point([(cx - 7, cy), (cx - 6, cy - 1)], fill=(255, 255, 255))

        # Right Eye
        draw.ellipse((cx + 3, cy - 3, cx + 9, cy + 6), fill=(255, 255, 255), outline=deep_shad, width=1)
        draw.ellipse((cx + 4, cy - 1, cx + 7, cy + 4), fill=(20, 20, 30))
        draw.point([(cx + 4, cy), (cx + 5, cy - 1)], fill=(255, 255, 255))

        # Rosy Cheeks
        draw.ellipse((cx - 13, cy + 4, cx - 9, cy + 7), fill=high)
        draw.ellipse((cx + 9, cy + 4, cx + 13, cy + 7), fill=high)

    elif expression == "blink":
        # Cute sleeping / blinking arc eyes
        draw.arc((cx - 9, cy + 1, cx - 3, cy + 5), start=180, end=360, fill=deep_shad, width=2)
        draw.arc((cx + 3, cy + 1, cx + 9, cy + 5), start=180, end=360, fill=deep_shad, width=2)
        draw.ellipse((cx - 13, cy + 4, cx - 9, cy + 7), fill=high)
        draw.ellipse((cx + 9, cy + 4, cx + 13, cy + 7), fill=high)

    elif expression == "shock":
        # Shocked / Popping Wide Eyes
        draw.ellipse((cx - 10, cy - 5, cx - 2, cy + 5), fill=(255, 255, 255), outline=deep_shad, width=1)
        draw.ellipse((cx + 2, cy - 5, cx + 10, cy + 5), fill=(255, 255, 255), outline=deep_shad, width=1)
        draw.ellipse((cx - 7, cy - 2, cx - 5, cy + 2), fill=(200, 20, 30))
        draw.ellipse((cx + 5, cy - 2, cx + 7, cy + 2), fill=(200, 20, 30))
        # Open Mouth
        draw.ellipse((cx - 2, cy + 6, cx + 2, cy + 10), fill=deep_shad)


def draw_connecting_blob(draw: ImageDraw.ImageDraw, x: int, y: int, pal_key: str, dir_str: str) -> None:
    base, high, shad, deep_shad = PUYO_PALETTES[pal_key]
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2

    draw_kawaii_puyo(draw, x, y, pal_key, "normal")

    # Connective slime bridges
    if "down" in dir_str:
        draw.rectangle((cx - 12, cy + 8, cx + 12, y + TILE_SIZE), fill=base)
        draw.line([(cx - 12, cy + 8), (cx - 12, y + TILE_SIZE)], fill=deep_shad, width=2)
        draw.line([(cx + 12, cy + 8), (cx + 12, y + TILE_SIZE)], fill=shad, width=2)
    if "right" in dir_str:
        draw.rectangle((cx + 8, cy - 12, x + TILE_SIZE, cy + 12), fill=base)
        draw.line([(cx + 8, cy - 12), (x + TILE_SIZE, cy - 12)], fill=high, width=2)
        draw.line([(cx + 8, cy + 12), (x + TILE_SIZE, cy + 12)], fill=deep_shad, width=2)


def main() -> None:
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    pal_keys = ["red", "green", "blue", "yellow", "purple", "garbage"]

    # Row 0: Normal expressive Puyos (Red, Green, Blue, Yellow, Purple, Garbage)
    for col, pal in enumerate(pal_keys):
        draw_kawaii_puyo(draw, col * TILE_SIZE, 0 * TILE_SIZE, pal, "normal")

    # Row 1: Blinking / Happy Puyos
    for col, pal in enumerate(pal_keys):
        draw_kawaii_puyo(draw, col * TILE_SIZE, 1 * TILE_SIZE, pal, "blink")

    # Row 2: Shocked / Combo Popping Puyos
    for col, pal in enumerate(pal_keys):
        draw_kawaii_puyo(draw, col * TILE_SIZE, 2 * TILE_SIZE, pal, "shock")

    # Row 3: Connected Blob Links
    for col, pal in enumerate(pal_keys):
        draw_connecting_blob(draw, col * TILE_SIZE, 3 * TILE_SIZE, pal, "down_right")

    out_path = Path(__file__).resolve().parent / "puyopuyo.png"
    img.save(out_path, "PNG")
    print(f"Generated {out_path} ({WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    main()
