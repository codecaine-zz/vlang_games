#!/usr/bin/env python3
"""Generate high-definition pixel-art sprite sheet for Snake."""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

TILE_SIZE = 32
COLS = 8
ROWS = 6
WIDTH = COLS * TILE_SIZE
HEIGHT = ROWS * TILE_SIZE


def draw_snake_head(draw: ImageDraw.ImageDraw, x: int, y: int, dir_idx: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2

    head_col = (80, 220, 90)
    dark_green = (30, 130, 40)
    belly_col = (210, 255, 140)

    # Rounded head
    draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=head_col, outline=dark_green, width=2)
    draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=belly_col)

    # Eyes & Tongue depending on direction (0: Up, 1: Right, 2: Down, 3: Left)
    if dir_idx == 0:  # Up
        draw.ellipse((cx - 9, cy - 10, cx - 3, cy - 4), fill=(255, 255, 255), outline=(20, 20, 20))
        draw.ellipse((cx + 3, cy - 10, cx + 9, cy - 4), fill=(255, 255, 255), outline=(20, 20, 20))
        draw.ellipse((cx - 7, cy - 9, cx - 4, cy - 6), fill=(10, 10, 10))
        draw.ellipse((cx + 4, cy - 9, cx + 7, cy - 6), fill=(10, 10, 10))
        draw.line([(cx, cy - 12), (cx, cy - 16)], fill=(255, 50, 60), width=2)
    elif dir_idx == 1:  # Right
        draw.ellipse((cx + 4, cy - 9, cx + 10, cy - 3), fill=(255, 255, 255), outline=(20, 20, 20))
        draw.ellipse((cx + 4, cy + 3, cx + 10, cy + 9), fill=(255, 255, 255), outline=(20, 20, 20))
        draw.ellipse((cx + 6, cy - 7, cx + 9, cy - 4), fill=(10, 10, 10))
        draw.ellipse((cx + 6, cy + 4, cx + 9, cy + 7), fill=(10, 10, 10))
        draw.line([(cx + 12, cy), (cx + 16, cy)], fill=(255, 50, 60), width=2)
    elif dir_idx == 2:  # Down
        draw.ellipse((cx - 9, cy + 4, cx - 3, cy + 10), fill=(255, 255, 255), outline=(20, 20, 20))
        draw.ellipse((cx + 3, cy + 4, cx + 9, cy + 10), fill=(255, 255, 255), outline=(20, 20, 20))
        draw.ellipse((cx - 7, cy + 6, cx - 4, cy + 9), fill=(10, 10, 10))
        draw.ellipse((cx + 4, cy + 6, cx + 7, cy + 9), fill=(10, 10, 10))
        draw.line([(cx, cy + 12), (cx, cy + 16)], fill=(255, 50, 60), width=2)
    else:  # Left
        draw.ellipse((cx - 10, cy - 9, cx - 4, cy - 3), fill=(255, 255, 255), outline=(20, 20, 20))
        draw.ellipse((cx - 10, cy + 3, cx - 4, cy + 9), fill=(255, 255, 255), outline=(20, 20, 20))
        draw.ellipse((cx - 9, cy - 7, cx - 6, cy - 4), fill=(10, 10, 10))
        draw.ellipse((cx - 9, cy + 4, cx - 6, cy + 7), fill=(10, 10, 10))
        draw.line([(cx - 12, cy), (cx - 16, cy)], fill=(255, 50, 60), width=2)


def draw_snake_body(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    draw.rounded_rectangle((cx - 11, cy - 11, cx + 11, cy + 11), radius=6, fill=(70, 205, 80), outline=(25, 120, 35), width=2)
    draw.rounded_rectangle((cx - 6, cy - 6, cx + 6, cy + 6), radius=3, fill=(130, 240, 140))


def draw_apple(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    # Juicy red apple
    draw.ellipse((cx - 10, cy - 9, cx + 10, cy + 11), fill=(240, 45, 50), outline=(130, 15, 20), width=2)
    # Highlight
    draw.ellipse((cx - 6, cy - 6, cx - 2, cy - 2), fill=(255, 170, 175))
    # Stem & Leaf
    draw.line([(cx, cy - 9), (cx + 2, cy - 14)], fill=(110, 60, 20), width=2)
    draw.ellipse((cx + 1, cy - 14, cx + 7, cy - 10), fill=(80, 210, 60))


def draw_golden_apple(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    # Sparkling Golden Apple
    draw.ellipse((cx - 10, cy - 9, cx + 10, cy + 11), fill=(255, 215, 30), outline=(160, 110, 10), width=2)
    draw.ellipse((cx - 6, cy - 6, cx - 2, cy - 2), fill=(255, 255, 200))
    draw.line([(cx, cy - 9), (cx + 2, cy - 14)], fill=(120, 70, 20), width=2)
    draw.ellipse((cx + 1, cy - 14, cx + 7, cy - 10), fill=(240, 255, 120))


def main() -> None:
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Row 0: Snake Heads (Up, Right, Down, Left)
    draw_snake_head(draw, 0 * TILE_SIZE, 0 * TILE_SIZE, 0)
    draw_snake_head(draw, 1 * TILE_SIZE, 0 * TILE_SIZE, 1)
    draw_snake_head(draw, 2 * TILE_SIZE, 0 * TILE_SIZE, 2)
    draw_snake_head(draw, 3 * TILE_SIZE, 0 * TILE_SIZE, 3)

    # Row 1: Body Segment & Tail
    draw_snake_body(draw, 0 * TILE_SIZE, 1 * TILE_SIZE)

    # Row 2: Foods (Red Apple, Golden Apple)
    draw_apple(draw, 0 * TILE_SIZE, 2 * TILE_SIZE)
    draw_golden_apple(draw, 1 * TILE_SIZE, 2 * TILE_SIZE)

    out_path = Path(__file__).resolve().parent / "snake.png"
    img.save(out_path, "PNG")
    print(f"Generated {out_path} ({WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    main()
