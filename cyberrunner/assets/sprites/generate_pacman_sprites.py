#!/usr/bin/env python3
"""Generate high-definition pixel-art sprite sheet for Pac-Man with full 4-directional chomp animations."""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

TILE_SIZE = 32
COLS = 8
ROWS = 8
WIDTH = COLS * TILE_SIZE
HEIGHT = ROWS * TILE_SIZE


def draw_pacman(draw: ImageDraw.ImageDraw, x: int, y: int, dir_name: str, mouth_open: float) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    r = 13

    # Angles for 4 directions
    rotations = {"right": 0.0, "down": 90.0, "left": 180.0, "up": 270.0}
    rot = rotations.get(dir_name, 0.0)

    if mouth_open <= 0.05:
        # Fully closed circle
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 230, 20), outline=(210, 160, 0), width=2)
    else:
        half_mouth = mouth_open * 42.0
        st_ang = (rot + half_mouth) % 360.0
        end_ang = (rot + 360.0 - half_mouth) % 360.0
        draw.pieslice((cx - r, cy - r, cx + r, cy + r), start=st_ang, end=end_ang, fill=(255, 230, 20), outline=(210, 160, 0), width=2)

    # Specular Glint on top
    draw.ellipse((cx - 7, cy - 8, cx - 3, cy - 4), fill=(255, 255, 200))


def draw_ghost(draw: ImageDraw.ImageDraw, x: int, y: int, body_col: tuple[int, int, int], eye_dir: str) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    r = 12

    # Ghost Head dome
    draw.pieslice((cx - r, cy - r - 1, cx + r, cy + r - 5), start=180, end=360, fill=body_col)
    # Ghost Torso
    draw.rectangle((cx - r, cy - 2, cx + r, cy + 8), fill=body_col)

    # Wavy bottom skirt tentacles (3 peaks)
    skirt_y = cy + 8
    draw.polygon([
        (cx - r, skirt_y), (cx - r + 4, skirt_y + 4), (cx - r + 8, skirt_y),
        (cx - r + 12, skirt_y + 4), (cx - r + 16, skirt_y),
        (cx - r + 20, skirt_y + 4), (cx + r, skirt_y),
        (cx + r, skirt_y - 2), (cx - r, skirt_y - 2)
    ], fill=body_col)

    # Eyes
    eye_offsets = {"right": (2, 0), "left": (-2, 0), "up": (0, -2), "down": (0, 2)}
    edx, edy = eye_offsets.get(eye_dir, (0, 0))

    # Eye Whites
    draw.ellipse((cx - 8 + edx, cy - 5 + edy, cx - 1 + edx, cy + 3 + edy), fill=(255, 255, 255))
    draw.ellipse((cx + 1 + edx, cy - 5 + edy, cx + 8 + edx, cy + 3 + edy), fill=(255, 255, 255))

    # Blue Pupils
    draw.ellipse((cx - 6 + edx * 2, cy - 2 + edy * 2, cx - 2 + edx * 2, cy + 2 + edy * 2), fill=(30, 60, 200))
    draw.ellipse((cx + 3 + edx * 2, cy - 2 + edy * 2, cx + 7 + edx * 2, cy + 2 + edy * 2), fill=(30, 60, 200))


def draw_frightened_ghost(draw: ImageDraw.ImageDraw, x: int, y: int, is_flashing: bool = False) -> None:
    body_col = (240, 240, 255) if is_flashing else (35, 60, 220)
    face_col = (220, 40, 40) if is_flashing else (255, 190, 180)

    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    r = 12

    # Body
    draw.pieslice((cx - r, cy - r - 1, cx + r, cy + r - 5), start=180, end=360, fill=body_col)
    draw.rectangle((cx - r, cy - 2, cx + r, cy + 8), fill=body_col)
    # Skirt
    draw.polygon([
        (cx - r, cy + 8), (cx - r + 4, cy + 12), (cx - r + 8, cy + 8),
        (cx - r + 12, cy + 12), (cx - r + 16, cy + 8),
        (cx - r + 20, cy + 12), (cx + r, cy + 8),
        (cx + r, cy + 6), (cx - r, cy + 6)
    ], fill=body_col)

    # Scared small eyes & squiggly mouth
    draw.rectangle((cx - 6, cy - 2, cx - 3, cy + 1), fill=face_col)
    draw.rectangle((cx + 3, cy - 2, cx + 6, cy + 1), fill=face_col)
    # Wavy mouth line
    draw.line([(cx - 7, cy + 5), (cx - 4, cy + 3), (cx - 1, cy + 5), (cx + 2, cy + 3), (cx + 5, cy + 5), (cx + 7, cy + 3)], fill=face_col, width=2)


def draw_cherry(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2

    # Twin Cherries
    draw.ellipse((cx - 10, cy + 1, cx - 1, cy + 10), fill=(240, 30, 40), outline=(150, 10, 20), width=1)
    draw.ellipse((cx + 1, cy + 3, cx + 10, cy + 12), fill=(240, 30, 40), outline=(150, 10, 20), width=1)
    draw.point([(cx - 7, cy + 3), (cx + 4, cy + 5)], fill=(255, 200, 210))

    # Brown/Green Stems joined at top
    draw.arc((cx - 6, cy - 10, cx + 10, cy + 4), start=180, end=300, fill=(160, 210, 60), width=2)
    draw.arc((cx - 12, cy - 10, cx + 2, cy + 4), start=240, end=360, fill=(160, 210, 60), width=2)


def draw_strawberry(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2

    # Strawberry Body
    draw.polygon([(cx - 8, cy - 4), (cx + 8, cy - 4), (cx + 5, cy + 8), (cx, cy + 12), (cx - 5, cy + 8)], fill=(245, 40, 60), outline=(170, 15, 30))
    # Green Leaves Top
    draw.polygon([(cx - 9, cy - 6), (cx - 3, cy - 4), (cx, cy - 8), (cx + 3, cy - 4), (cx + 9, cy - 6), (cx, cy - 3)], fill=(50, 210, 60))
    # Seeds
    for sx, sy in [(cx - 4, cy - 1), (cx + 4, cy - 1), (cx, cy + 2), (cx - 3, cy + 6), (cx + 3, cy + 6)]:
        draw.point([(sx, sy)], fill=(255, 255, 180))


def draw_power_pellet(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    draw.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=(255, 184, 174), outline=(255, 230, 220), width=2)
    draw.ellipse((cx - 4, cy - 4, cx, cy), fill=(255, 255, 255))


def main() -> None:
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Row 0: Pac-Man Right (Closed [0.0], Half [0.5], Wide [1.0])
    draw_pacman(draw, 0 * TILE_SIZE, 0 * TILE_SIZE, "right", 0.0)
    draw_pacman(draw, 1 * TILE_SIZE, 0 * TILE_SIZE, "right", 0.5)
    draw_pacman(draw, 2 * TILE_SIZE, 0 * TILE_SIZE, "right", 1.0)

    # Row 1: Pac-Man Down (Closed [0.0], Half [0.5], Wide [1.0])
    draw_pacman(draw, 0 * TILE_SIZE, 1 * TILE_SIZE, "down", 0.0)
    draw_pacman(draw, 1 * TILE_SIZE, 1 * TILE_SIZE, "down", 0.5)
    draw_pacman(draw, 2 * TILE_SIZE, 1 * TILE_SIZE, "down", 1.0)

    # Row 2: Pac-Man Left (Closed [0.0], Half [0.5], Wide [1.0])
    draw_pacman(draw, 0 * TILE_SIZE, 2 * TILE_SIZE, "left", 0.0)
    draw_pacman(draw, 1 * TILE_SIZE, 2 * TILE_SIZE, "left", 0.5)
    draw_pacman(draw, 2 * TILE_SIZE, 2 * TILE_SIZE, "left", 1.0)

    # Row 3: Pac-Man Up (Closed [0.0], Half [0.5], Wide [1.0])
    draw_pacman(draw, 0 * TILE_SIZE, 3 * TILE_SIZE, "up", 0.0)
    draw_pacman(draw, 1 * TILE_SIZE, 3 * TILE_SIZE, "up", 0.5)
    draw_pacman(draw, 2 * TILE_SIZE, 3 * TILE_SIZE, "up", 1.0)

    # Row 4: Blinky (Red: Right, Left, Up, Down) & Pinky (Pink: Right, Left, Up, Down)
    draw_ghost(draw, 0 * TILE_SIZE, 4 * TILE_SIZE, (255, 0, 0), "right")
    draw_ghost(draw, 1 * TILE_SIZE, 4 * TILE_SIZE, (255, 0, 0), "left")
    draw_ghost(draw, 2 * TILE_SIZE, 4 * TILE_SIZE, (255, 0, 0), "up")
    draw_ghost(draw, 3 * TILE_SIZE, 4 * TILE_SIZE, (255, 0, 0), "down")
    draw_ghost(draw, 4 * TILE_SIZE, 4 * TILE_SIZE, (255, 184, 255), "right")
    draw_ghost(draw, 5 * TILE_SIZE, 4 * TILE_SIZE, (255, 184, 255), "left")
    draw_ghost(draw, 6 * TILE_SIZE, 4 * TILE_SIZE, (255, 184, 255), "up")
    draw_ghost(draw, 7 * TILE_SIZE, 4 * TILE_SIZE, (255, 184, 255), "down")

    # Row 5: Inky (Cyan: Right, Left, Up, Down) & Clyde (Orange: Right, Left, Up, Down)
    draw_ghost(draw, 0 * TILE_SIZE, 5 * TILE_SIZE, (0, 255, 255), "right")
    draw_ghost(draw, 1 * TILE_SIZE, 5 * TILE_SIZE, (0, 255, 255), "left")
    draw_ghost(draw, 2 * TILE_SIZE, 5 * TILE_SIZE, (0, 255, 255), "up")
    draw_ghost(draw, 3 * TILE_SIZE, 5 * TILE_SIZE, (0, 255, 255), "down")
    draw_ghost(draw, 4 * TILE_SIZE, 5 * TILE_SIZE, (255, 184, 82), "right")
    draw_ghost(draw, 5 * TILE_SIZE, 5 * TILE_SIZE, (255, 184, 82), "left")
    draw_ghost(draw, 6 * TILE_SIZE, 5 * TILE_SIZE, (255, 184, 82), "up")
    draw_ghost(draw, 7 * TILE_SIZE, 5 * TILE_SIZE, (255, 184, 82), "down")

    # Row 6: Frightened Ghosts (Scared Blue, Flashing White)
    draw_frightened_ghost(draw, 0 * TILE_SIZE, 6 * TILE_SIZE, False)
    draw_frightened_ghost(draw, 1 * TILE_SIZE, 6 * TILE_SIZE, True)

    # Row 7: Collectibles & Items (Cherry, Strawberry, Power Pellet)
    draw_cherry(draw, 0 * TILE_SIZE, 7 * TILE_SIZE)
    draw_strawberry(draw, 1 * TILE_SIZE, 7 * TILE_SIZE)
    draw_power_pellet(draw, 2 * TILE_SIZE, 7 * TILE_SIZE)

    out_path = Path(__file__).resolve().parent / "pacman.png"
    img.save(out_path, "PNG")
    print(f"Generated {out_path} ({WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    main()
