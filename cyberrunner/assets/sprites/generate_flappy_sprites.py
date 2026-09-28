#!/usr/bin/env python3
"""Generate high-definition pixel-art sprite sheet for Flappy Bird."""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

TILE_SIZE = 32
COLS = 8
ROWS = 6
WIDTH = COLS * TILE_SIZE
HEIGHT = ROWS * TILE_SIZE


def draw_bird(draw: ImageDraw.ImageDraw, x: int, y: int, wing_pose: int) -> None:
    # 34x24 bird centered in 48x32
    cx = x + 16
    cy = y + 16

    body_col = (248, 184, 0)
    belly_col = (230, 90, 30)
    beak_col = (248, 56, 0)
    eye_white = (255, 255, 255)
    pupil_col = (10, 10, 10)
    outline_col = (40, 20, 10)
    wing_col = (255, 255, 255)

    # Body
    draw.ellipse((cx - 14, cy - 10, cx + 10, cy + 10), fill=body_col, outline=outline_col, width=2)
    # Belly accent
    draw.arc((cx - 10, cy - 6, cx + 6, cy + 8), 0, 180, fill=belly_col, width=3)

    # Eye
    draw.ellipse((cx + 1, cy - 10, cx + 11, cy + 2), fill=eye_white, outline=outline_col, width=1)
    draw.ellipse((cx + 6, cy - 8, cx + 10, cy - 2), fill=pupil_col)

    # Beak / Lips
    draw.polygon([(cx + 8, cy - 2), (cx + 18, cy + 2), (cx + 8, cy + 5)], fill=beak_col, outline=outline_col)
    draw.polygon([(cx + 8, cy + 3), (cx + 16, cy + 6), (cx + 8, cy + 8)], fill=(220, 40, 0), outline=outline_col)

    # Wing (0: middle, 1: up, 2: down)
    if wing_pose == 0:
        draw.ellipse((cx - 13, cy - 4, cx - 1, cy + 4), fill=wing_col, outline=outline_col, width=1)
    elif wing_pose == 1:
        draw.ellipse((cx - 11, cy - 12, cx + 1, cy - 2), fill=wing_col, outline=outline_col, width=1)
    else:
        draw.ellipse((cx - 13, cy + 2, cx - 1, cy + 10), fill=wing_col, outline=outline_col, width=1)


def draw_pipe(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Pipe Cap & Pipe Body
    cap_rect = (x + 2, y + 2, x + TILE_SIZE - 2, y + 14)
    draw.rounded_rectangle(cap_rect, radius=2, fill=(115, 190, 45), outline=(35, 80, 15), width=2)
    draw.rectangle((x + 6, y + 4, x + 10, y + 12), fill=(175, 235, 75))  # Highlight

    body_rect = (x + 5, y + 14, x + TILE_SIZE - 5, y + TILE_SIZE - 2)
    draw.rectangle(body_rect, fill=(115, 190, 45), outline=(35, 80, 15), width=2)
    draw.rectangle((x + 8, y + 14, x + 11, y + TILE_SIZE - 2), fill=(175, 235, 75))  # Highlight


def draw_medal(draw: ImageDraw.ImageDraw, x: int, y: int, color: tuple[int, int, int]) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=color, outline=(40, 30, 20), width=2)
    draw.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=(color[0] + 25, color[1] + 25, color[2] + 25))
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=color)


def main() -> None:
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Row 0: Bird Frames (0: Mid, 1: Up, 2: Down)
    draw_bird(draw, 0 * TILE_SIZE, 0 * TILE_SIZE, 0)
    draw_bird(draw, 1 * TILE_SIZE, 0 * TILE_SIZE, 1)
    draw_bird(draw, 2 * TILE_SIZE, 0 * TILE_SIZE, 2)

    # Row 1: Green Pipe Cap & Body
    draw_pipe(draw, 0 * TILE_SIZE, 1 * TILE_SIZE)

    # Row 2: Medals (Bronze, Silver, Gold, Platinum)
    draw_medal(draw, 0 * TILE_SIZE, 2 * TILE_SIZE, (180, 100, 45))   # Bronze
    draw_medal(draw, 1 * TILE_SIZE, 2 * TILE_SIZE, (195, 205, 215))  # Silver
    draw_medal(draw, 2 * TILE_SIZE, 2 * TILE_SIZE, (250, 210, 30))   # Gold
    draw_medal(draw, 3 * TILE_SIZE, 2 * TILE_SIZE, (160, 240, 255))  # Platinum

    out_path = Path(__file__).resolve().parent / "flappy.png"
    img.save(out_path, "PNG")
    print(f"Generated {out_path} ({WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    main()
