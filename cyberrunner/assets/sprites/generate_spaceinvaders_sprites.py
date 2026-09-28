#!/usr/bin/env python3
"""Generate high-definition pixel-art sprite sheet for Space Invaders."""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

TILE_SIZE = 36
COLS = 8
ROWS = 4
WIDTH = COLS * TILE_SIZE
HEIGHT = ROWS * TILE_SIZE


def draw_squid(draw: ImageDraw.ImageDraw, x: int, y: int, frame: int) -> None:
    # 8x8 Squid Invader (White/Cyan)
    pat0 = [
        "   ##   ",
        "  ####  ",
        " ###### ",
        "## ## ##",
        "########",
        "  #  #  ",
        " # ## # ",
        "# #  # #",
    ]
    pat1 = [
        "   ##   ",
        "  ####  ",
        " ###### ",
        "## ## ##",
        "########",
        "  #  #  ",
        " #    # ",
        "  #  #  ",
    ]
    pat = pat0 if frame == 0 else pat1
    scale = 3
    off_x = x + (TILE_SIZE - 8 * scale) // 2
    off_y = y + (TILE_SIZE - 8 * scale) // 2

    for r, row in enumerate(pat):
        for c, ch in enumerate(row):
            if ch == "#":
                px = off_x + c * scale
                py = off_y + r * scale
                draw.rectangle((px, py, px + scale - 1, py + scale - 1), fill=(100, 240, 255), outline=(40, 160, 220))


def draw_crab(draw: ImageDraw.ImageDraw, x: int, y: int, frame: int) -> None:
    # 11x8 Crab Invader (Emerald Green)
    pat0 = [
        "  #     #  ",
        "   #   #   ",
        "  #######  ",
        " ## ### ## ",
        "###########",
        "# ####### #",
        "# #     # #",
        "   ## ##   ",
    ]
    pat1 = [
        "  #     #  ",
        "#  #   #  #",
        "# ####### #",
        "### ### ###",
        "###########",
        " ####### # ",
        "  #     #  ",
        " #       # ",
    ]
    pat = pat0 if frame == 0 else pat1
    scale = 3
    off_x = x + (TILE_SIZE - 11 * scale) // 2
    off_y = y + (TILE_SIZE - 8 * scale) // 2

    for r, row in enumerate(pat):
        for c, ch in enumerate(row):
            if ch == "#":
                px = off_x + c * scale
                py = off_y + r * scale
                draw.rectangle((px, py, px + scale - 1, py + scale - 1), fill=(50, 255, 120), outline=(20, 160, 60))


def draw_octopus(draw: ImageDraw.ImageDraw, x: int, y: int, frame: int) -> None:
    # 12x8 Octopus Invader (Magenta/Pink)
    pat0 = [
        "    ####    ",
        " ########## ",
        "############",
        "###  ##  ###",
        "############",
        "   ##  ##   ",
        "  ## ## ##  ",
        "##        ##",
    ]
    pat1 = [
        "    ####    ",
        " ########## ",
        "############",
        "###  ##  ###",
        "############",
        "  ###  ###  ",
        " ##  ##  ## ",
        "  ##    ##  ",
    ]
    pat = pat0 if frame == 0 else pat1
    scale = 2
    off_x = x + (TILE_SIZE - 12 * scale) // 2
    off_y = y + (TILE_SIZE - 8 * scale) // 2

    for r, row in enumerate(pat):
        for c, ch in enumerate(row):
            if ch == "#":
                px = off_x + c * scale
                py = off_y + r * scale
                draw.rectangle((px, py, px + scale - 1, py + scale - 1), fill=(255, 100, 220), outline=(180, 30, 140))


def draw_ufo(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Mystery Flying Saucer (Crimson & Glowing Gold Dome)
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    draw.ellipse((cx - 15, cy - 6, cx + 15, cy + 6), fill=(255, 40, 60), outline=(180, 10, 20), width=2)
    # Glass Dome
    draw.ellipse((cx - 7, cy - 11, cx + 7, cy - 2), fill=(255, 230, 80), outline=(180, 150, 10))
    # Underside Thrusters
    for tx in [cx - 9, cx, cx + 9]:
        draw.ellipse((tx - 2, cy + 4, tx + 2, cy + 7), fill=(100, 220, 255))


def draw_player_tank(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Green Earth Defense Cannon Tank
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    # Base Treads
    draw.rounded_rectangle((cx - 14, cy + 2, cx + 14, cy + 12), radius=3, fill=(40, 220, 60), outline=(15, 120, 30), width=2)
    # Turret Body
    draw.rectangle((cx - 8, cy - 4, cx + 8, cy + 2), fill=(60, 240, 80), outline=(15, 120, 30))
    # Cannon Barrel
    draw.rectangle((cx - 2, cy - 12, cx + 2, cy - 4), fill=(255, 255, 255), outline=(100, 220, 120))


def draw_explosion(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    draw.line([(cx - 12, cy - 12), (cx + 12, cy + 12)], fill=(255, 220, 50), width=2)
    draw.line([(cx - 12, cy + 12), (cx + 12, cy - 12)], fill=(255, 220, 50), width=2)
    draw.line([(cx - 14, cy), (cx + 14, cy)], fill=(255, 80, 50), width=2)
    draw.line([(cx, cy - 14), (cx, cy + 14)], fill=(255, 80, 50), width=2)


def draw_bunker(draw: ImageDraw.ImageDraw, x: int, y: int, damage_level: int) -> None:
    cx = x + TILE_SIZE // 2
    cy = y + TILE_SIZE // 2
    # Arch bunker
    draw.rounded_rectangle((cx - 14, cy - 10, cx + 14, cy + 12), radius=4, fill=(40, 210, 80), outline=(15, 110, 30), width=2)
    # Tunnel arch cutout
    draw.pieslice((cx - 7, cy + 2, cx + 7, cy + 16), start=180, end=360, fill=(10, 10, 20))
    if damage_level >= 1:
        draw.ellipse((cx - 8, cy - 6, cx - 2, cy), fill=(10, 10, 20))
    if damage_level >= 2:
        draw.ellipse((cx + 3, cy - 4, cx + 9, cy + 2), fill=(10, 10, 20))


def main() -> None:
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Row 0: Aliens Frame 0 & Frame 1
    draw_squid(draw, 0 * TILE_SIZE, 0 * TILE_SIZE, 0)
    draw_squid(draw, 1 * TILE_SIZE, 0 * TILE_SIZE, 1)
    draw_crab(draw, 2 * TILE_SIZE, 0 * TILE_SIZE, 0)
    draw_crab(draw, 3 * TILE_SIZE, 0 * TILE_SIZE, 1)
    draw_octopus(draw, 4 * TILE_SIZE, 0 * TILE_SIZE, 0)
    draw_octopus(draw, 5 * TILE_SIZE, 0 * TILE_SIZE, 1)

    # Row 1: UFO & Cannon Tank & Explosions
    draw_ufo(draw, 0 * TILE_SIZE, 1 * TILE_SIZE)
    draw_player_tank(draw, 1 * TILE_SIZE, 1 * TILE_SIZE)
    draw_explosion(draw, 2 * TILE_SIZE, 1 * TILE_SIZE)

    # Row 2: Defense Bunkers (Full, Damaged 1, Damaged 2)
    draw_bunker(draw, 0 * TILE_SIZE, 2 * TILE_SIZE, 0)
    draw_bunker(draw, 1 * TILE_SIZE, 2 * TILE_SIZE, 1)
    draw_bunker(draw, 2 * TILE_SIZE, 2 * TILE_SIZE, 2)

    out_path = Path(__file__).resolve().parent / "spaceinvaders.png"
    img.save(out_path, "PNG")
    print(f"Generated {out_path} ({WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    main()
