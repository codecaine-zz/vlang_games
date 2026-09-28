#!/usr/bin/env python3
"""Generate high-definition pixel-art sprite sheet for Frogger."""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

TILE_SIZE = 32
COLS = 8
ROWS = 6
WIDTH = COLS * TILE_SIZE
HEIGHT = ROWS * TILE_SIZE


def draw_frog(draw: ImageDraw.ImageDraw, x: int, y: int, dir_idx: int, is_leap: bool) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2

    # Frog green body & cream belly
    body_col = (60, 220, 50)
    belly_col = (210, 245, 120)
    dark_green = (25, 130, 20)

    if not is_leap:
        # Crouch pose
        draw.ellipse((cx - 8, cy - 7, cx + 8, cy + 7), fill=body_col, outline=dark_green, width=1)
        draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=belly_col)
        # Big protruding eyes
        draw.ellipse((cx - 8, cy - 10, cx - 2, cy - 4), fill=(255, 255, 255), outline=dark_green)
        draw.ellipse((cx + 2, cy - 10, cx + 8, cy - 4), fill=(255, 255, 255), outline=dark_green)
        draw.ellipse((cx - 6, cy - 8, cx - 3, cy - 5), fill=(20, 20, 30))
        draw.ellipse((cx + 3, cy - 8, cx + 6, cy - 5), fill=(20, 20, 30))
        # Folded legs
        draw.ellipse((cx - 12, cy + 1, cx - 6, cy + 9), fill=body_col, outline=dark_green)
        draw.ellipse((cx + 6, cy + 1, cx + 12, cy + 9), fill=body_col, outline=dark_green)
    else:
        # Extended leap pose
        draw.ellipse((cx - 6, cy - 8, cx + 6, cy + 8), fill=body_col, outline=dark_green, width=1)
        draw.ellipse((cx - 3, cy - 5, cx + 3, cy + 5), fill=belly_col)
        # Eyes
        draw.ellipse((cx - 7, cy - 11, cx - 1, cy - 5), fill=(255, 255, 255))
        draw.ellipse((cx + 1, cy - 11, cx + 7, cy - 5), fill=(255, 255, 255))
        draw.ellipse((cx - 5, cy - 9, cx - 2, cy - 6), fill=(20, 20, 30))
        draw.ellipse((cx + 2, cy - 9, cx + 5, cy - 6), fill=(20, 20, 30))
        # Extended hind legs & front arms
        draw.line([(cx - 6, cy - 4), (cx - 12, cy - 10)], fill=body_col, width=3)
        draw.line([(cx + 6, cy - 4), (cx + 12, cy - 10)], fill=body_col, width=3)
        draw.line([(cx - 5, cy + 6), (cx - 10, cy + 13)], fill=body_col, width=3)
        draw.line([(cx + 5, cy + 6), (cx + 10, cy + 13)], fill=body_col, width=3)


def draw_car(draw: ImageDraw.ImageDraw, x: int, y: int, body_col: tuple[int, int, int]) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    # Car Body
    draw.rounded_rectangle((cx - 14, cy - 6, cx + 14, cy + 7), radius=3, fill=body_col, outline=(30, 30, 40), width=1)
    # Windshield Glass
    draw.rectangle((cx - 6, cy - 4, cx + 5, cy + 5), fill=(160, 220, 255), outline=(50, 80, 120))
    # Headlights & Taillights
    draw.rectangle((cx + 12, cy - 5, cx + 14, cy - 2), fill=(255, 240, 80))
    draw.rectangle((cx + 12, cy + 3, cx + 14, cy + 6), fill=(255, 240, 80))
    draw.rectangle((cx - 14, cy - 5, cx - 12, cy - 2), fill=(255, 40, 50))
    draw.rectangle((cx - 14, cy + 3, cx - 12, cy + 6), fill=(255, 40, 50))


def draw_truck(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    # Long White Cargo Trailer
    draw.rounded_rectangle((cx - 15, cy - 8, cx + 6, cy + 8), radius=2, fill=(240, 245, 255), outline=(90, 100, 120), width=1)
    # Red Cab
    draw.rounded_rectangle((cx + 6, cy - 7, cx + 15, cy + 7), radius=2, fill=(230, 40, 50), outline=(100, 10, 20), width=1)
    draw.rectangle((cx + 9, cy - 5, cx + 13, cy + 5), fill=(160, 220, 255))


def draw_log(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    # Floating Wooden Log with Bark Rings
    draw.rounded_rectangle((cx - 15, cy - 7, cx + 15, cy + 7), radius=4, fill=(150, 95, 45), outline=(90, 50, 20), width=2)
    # Wood Grain lines
    draw.line([(cx - 10, cy - 2), (cx + 8, cy - 2)], fill=(120, 70, 30), width=2)
    draw.line([(cx - 6, cy + 3), (cx + 11, cy + 3)], fill=(120, 70, 30), width=2)


def draw_turtle(draw: ImageDraw.ImageDraw, x: int, y: int, is_diving: bool) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    shell_col = (190, 40, 50) if not is_diving else (50, 120, 200)
    skin_col = (50, 190, 80) if not is_diving else (30, 100, 150)

    # Shell
    draw.ellipse((cx - 8, cy - 7, cx + 8, cy + 7), fill=shell_col, outline=(30, 30, 40), width=1)
    # Shell Pattern
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(shell_col[0] + 30, shell_col[1] + 20, shell_col[2] + 20))
    # Head & Flippers
    draw.ellipse((cx + 7, cy - 3, cx + 12, cy + 3), fill=skin_col)
    draw.ellipse((cx - 9, cy - 9, cx - 4, cy - 5), fill=skin_col)
    draw.ellipse((cx + 3, cy - 9, cx + 8, cy - 5), fill=skin_col)
    draw.ellipse((cx - 9, cy + 5, cx - 4, cy + 9), fill=skin_col)
    draw.ellipse((cx + 3, cy + 5, cx + 8, cy + 9), fill=skin_col)


def draw_fly(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    # Shiny delicious bonus fly
    draw.ellipse((cx - 4, cy - 3, cx + 4, cy + 3), fill=(30, 30, 30))
    draw.ellipse((cx - 6, cy - 6, cx - 1, cy - 1), fill=(200, 240, 255, 180))
    draw.ellipse((cx + 1, cy - 6, cx + 6, cy - 1), fill=(200, 240, 255, 180))


def main() -> None:
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Row 0: Frog Poses (Up Crouch, Up Leap, Down Crouch, Down Leap, Left Crouch, Left Leap, Right Crouch, Right Leap)
    draw_frog(draw, 0 * TILE_SIZE, 0 * TILE_SIZE, 0, False)
    draw_frog(draw, 1 * TILE_SIZE, 0 * TILE_SIZE, 0, True)

    # Row 1: Cars (Yellow Taxi, Blue Sedan, Purple Cruiser, Green Bug)
    draw_car(draw, 0 * TILE_SIZE, 1 * TILE_SIZE, (255, 210, 40))
    draw_car(draw, 1 * TILE_SIZE, 1 * TILE_SIZE, (40, 140, 245))
    draw_car(draw, 2 * TILE_SIZE, 1 * TILE_SIZE, (190, 60, 230))
    draw_car(draw, 3 * TILE_SIZE, 1 * TILE_SIZE, (60, 220, 80))

    # Row 2: Truck & Racer
    draw_truck(draw, 0 * TILE_SIZE, 2 * TILE_SIZE)

    # Row 3: Floating Log & Turtles
    draw_log(draw, 0 * TILE_SIZE, 3 * TILE_SIZE)
    draw_turtle(draw, 1 * TILE_SIZE, 3 * TILE_SIZE, False)
    draw_turtle(draw, 2 * TILE_SIZE, 3 * TILE_SIZE, True)

    # Row 4: Fly Bonus
    draw_fly(draw, 0 * TILE_SIZE, 4 * TILE_SIZE)

    out_path = Path(__file__).resolve().parent / "frogger.png"
    img.save(out_path, "PNG")
    print(f"Generated {out_path} ({WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    main()
