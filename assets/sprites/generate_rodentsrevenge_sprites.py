#!/usr/bin/env python3
"""Generate high-definition pixel-art sprite sheet for Rodent's Revenge."""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

TILE_SIZE = 32
COLS = 8
ROWS = 6
WIDTH = COLS * TILE_SIZE
HEIGHT = ROWS * TILE_SIZE


def draw_mouse_up(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Body grey
    draw.ellipse((x + 10, y + 8, x + 22, y + 26), fill=(140, 145, 155), outline=(90, 95, 105))
    # Head
    draw.polygon([(x + 16, y + 3), (x + 10, y + 12), (x + 22, y + 12)], fill=(155, 160, 170), outline=(90, 95, 105))
    # Pink Ears
    draw.ellipse((x + 7, y + 8, x + 13, y + 14), fill=(245, 160, 180), outline=(180, 100, 120))
    draw.ellipse((x + 19, y + 8, x + 25, y + 14), fill=(245, 160, 180), outline=(180, 100, 120))
    # Nose
    draw.ellipse((x + 14, y + 2, x + 18, y + 6), fill=(240, 90, 120))
    # Tail
    draw.line([(x + 16, y + 25), (x + 14, y + 30), (x + 18, y + 31)], fill=(230, 140, 160), width=2)


def draw_mouse_down(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Tail pointing up
    draw.line([(x + 16, y + 5), (x + 14, y + 1), (x + 18, y + 0)], fill=(230, 140, 160), width=2)
    # Body grey
    draw.ellipse((x + 10, y + 6, x + 22, y + 24), fill=(140, 145, 155), outline=(90, 95, 105))
    # Head pointing down
    draw.polygon([(x + 16, y + 29), (x + 10, y + 20), (x + 22, y + 20)], fill=(155, 160, 170), outline=(90, 95, 105))
    # Pink Ears
    draw.ellipse((x + 7, y + 18, x + 13, y + 24), fill=(245, 160, 180), outline=(180, 100, 120))
    draw.ellipse((x + 19, y + 18, x + 25, y + 14 + 10), fill=(245, 160, 180), outline=(180, 100, 120))
    # Nose
    draw.ellipse((x + 14, y + 26, x + 18, y + 30), fill=(240, 90, 120))
    # Eyes
    draw.point([(x + 13, y + 22), (x + 19, y + 22)], fill=(20, 20, 30))


def draw_mouse_left(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Tail right
    draw.line([(x + 23, y + 17), (x + 28, y + 14), (x + 30, y + 19)], fill=(230, 140, 160), width=2)
    # Body grey
    draw.ellipse((x + 8, y + 10, x + 24, y + 22), fill=(140, 145, 155), outline=(90, 95, 105))
    # Snout pointing left
    draw.polygon([(x + 2, y + 16), (x + 12, y + 10), (x + 12, y + 22)], fill=(155, 160, 170), outline=(90, 95, 105))
    # Ears
    draw.ellipse((x + 12, y + 5, x + 18, y + 12), fill=(245, 160, 180), outline=(180, 100, 120))
    # Eye
    draw.point([(x + 8, y + 14)], fill=(20, 20, 30))
    # Nose
    draw.ellipse((x + 2, y + 14, x + 5, y + 18), fill=(240, 90, 120))


def draw_mouse_right(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Tail left
    draw.line([(x + 8, y + 17), (x + 3, y + 14), (x + 1, y + 19)], fill=(230, 140, 160), width=2)
    # Body grey
    draw.ellipse((x + 8, y + 10, x + 24, y + 22), fill=(140, 145, 155), outline=(90, 95, 105))
    # Snout pointing right
    draw.polygon([(x + 29, y + 16), (x + 19, y + 10), (x + 19, y + 22)], fill=(155, 160, 170), outline=(90, 95, 105))
    # Ears
    draw.ellipse((x + 13, y + 5, x + 19, y + 12), fill=(245, 160, 180), outline=(180, 100, 120))
    # Eye
    draw.point([(x + 23, y + 14)], fill=(20, 20, 30))
    # Nose
    draw.ellipse((x + 26, y + 14, x + 29, y + 18), fill=(240, 90, 120))


def draw_cat_normal(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Orange Tabby Cat
    # Body
    draw.rounded_rectangle((x + 6, y + 10, x + 26, y + 27), radius=5, fill=(230, 120, 30), outline=(150, 60, 10), width=2)
    # Stripes
    draw.line([(x + 10, y + 12), (x + 10, y + 16)], fill=(160, 70, 15), width=2)
    draw.line([(x + 16, y + 12), (x + 16, y + 17)], fill=(160, 70, 15), width=2)
    draw.line([(x + 22, y + 12), (x + 22, y + 16)], fill=(160, 70, 15), width=2)
    # Head
    draw.ellipse((x + 8, y + 4, x + 24, y + 18), fill=(245, 140, 40), outline=(150, 60, 10), width=2)
    # Pointy Ears
    draw.polygon([(x + 7, y + 7), (x + 10, y + 1), (x + 13, y + 6)], fill=(245, 140, 40), outline=(150, 60, 10))
    draw.polygon([(x + 19, y + 6), (x + 22, y + 1), (x + 25, y + 7)], fill=(245, 140, 40), outline=(150, 60, 10))
    # Green Eyes
    draw.ellipse((x + 11, y + 8, x + 14, y + 12), fill=(100, 230, 80))
    draw.ellipse((x + 18, y + 8, x + 21, y + 12), fill=(100, 230, 80))
    draw.point([(x + 12, y + 10), (x + 19, y + 10)], fill=(0, 0, 0))
    # Nose & Whiskers
    draw.polygon([(x + 15, y + 12), (x + 17, y + 12), (x + 16, y + 14)], fill=(240, 130, 150))
    draw.line([(x + 6, y + 13), (x + 12, y + 13)], fill=(255, 255, 255))
    draw.line([(x + 20, y + 13), (x + 26, y + 13)], fill=(255, 255, 255))
    # Paws
    draw.ellipse((x + 7, y + 24, x + 13, y + 29), fill=(255, 255, 255), outline=(150, 60, 10))
    draw.ellipse((x + 19, y + 24, x + 25, y + 29), fill=(255, 255, 255), outline=(150, 60, 10))


def draw_cat_sleeping(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Curled up sleeping cat
    draw.ellipse((x + 5, y + 8, x + 27, y + 26), fill=(230, 120, 30), outline=(150, 60, 10), width=2)
    # Closed eyes (arcs / lines)
    draw.line([(x + 10, y + 16), (x + 14, y + 16)], fill=(20, 20, 20), width=2)
    draw.line([(x + 18, y + 16), (x + 22, y + 16)], fill=(20, 20, 20), width=2)
    # Zzz letters
    draw.text((x + 21, y + 1), "Z", fill=(120, 180, 255))


def draw_cat_trapped(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Shocked / Trapped Cat (Wide eyes and mouth)
    draw_cat_normal(draw, x, y)
    # Big round white eyes
    draw.ellipse((x + 10, y + 7, x + 15, y + 13), fill=(255, 255, 255), outline=(0, 0, 0))
    draw.ellipse((x + 17, y + 7, x + 22, y + 13), fill=(255, 255, 255), outline=(0, 0, 0))
    draw.ellipse((x + 12, y + 9, x + 14, y + 11), fill=(0, 0, 0))
    draw.ellipse((x + 19, y + 9, x + 21, y + 11), fill=(0, 0, 0))
    # Open 'O' Mouth
    draw.ellipse((x + 14, y + 14, x + 18, y + 17), fill=(200, 30, 30))


def draw_block(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Pushable Wooden Warehouse Crate with 3D Bevel & Cross Bracing
    draw.rounded_rectangle((x + 1, y + 1, x + 30, y + 30), radius=3, fill=(205, 155, 95), outline=(110, 70, 30), width=2)
    # Planks & Cross
    draw.rectangle((x + 4, y + 4, x + 27, y + 27), fill=(225, 175, 115), outline=(160, 110, 50), width=1)
    draw.line([(x + 4, y + 4), (x + 27, y + 27)], fill=(125, 80, 35), width=2)
    draw.line([(x + 4, y + 27), (x + 27, y + 4)], fill=(125, 80, 35), width=2)
    # Corner metal rivets
    for px, py in [(x + 5, y + 5), (x + 26, y + 5), (x + 5, y + 26), (x + 26, y + 26)]:
        draw.ellipse((px - 1, py - 1, px + 1, py + 1), fill=(240, 240, 245), outline=(80, 80, 90))


def draw_wall(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Heavy Blue/Grey Steel Warehouse Wall with Rivets and Grid
    draw.rectangle((x, y, x + 31, y + 31), fill=(95, 110, 130), outline=(45, 55, 70), width=2)
    # 3D Highlight top-left, Shadow bottom-right
    draw.line([(x + 1, y + 1), (x + 30, y + 1)], fill=(160, 180, 205))
    draw.line([(x + 1, y + 1), (x + 1, y + 30)], fill=(160, 180, 205))
    draw.line([(x + 1, y + 30), (x + 30, y + 30)], fill=(40, 48, 60))
    draw.line([(x + 30, y + 1), (x + 30, y + 30)], fill=(40, 48, 60))
    # Mortar / pattern lines
    draw.line([(x + 1, y + 15), (x + 30, y + 15)], fill=(55, 65, 80), width=1)
    draw.line([(x + 15, y + 1), (x + 15, y + 15)], fill=(55, 65, 80), width=1)
    draw.line([(x + 8, y + 16), (x + 8, y + 30)], fill=(55, 65, 80), width=1)
    draw.line([(x + 23, y + 16), (x + 23, y + 30)], fill=(55, 65, 80), width=1)


def draw_cheese(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Delicious Golden Swiss Cheese Wedge
    # Shadow
    draw.polygon([(x + 4, y + 25), (x + 28, y + 25), (x + 24, y + 9)], fill=(190, 130, 0))
    # Main Wedge Face
    draw.polygon([(x + 3, y + 23), (x + 27, y + 23), (x + 23, y + 7)], fill=(255, 215, 25), outline=(200, 145, 0), width=2)
    # Side Perspective Cut
    draw.polygon([(x + 3, y + 23), (x + 7, y + 14), (x + 23, y + 7)], fill=(255, 235, 80))
    # Holes
    draw.ellipse((x + 12, y + 14, x + 16, y + 18), fill=(210, 155, 10))
    draw.ellipse((x + 18, y + 17, x + 23, y + 21), fill=(210, 155, 10))
    draw.ellipse((x + 7, y + 17, x + 10, y + 20), fill=(210, 155, 10))
    # Sparkle glint
    draw.line([(x + 23, y + 4), (x + 23, y + 8)], fill=(255, 255, 255), width=1)
    draw.line([(x + 21, y + 6), (x + 25, y + 6)], fill=(255, 255, 255), width=1)


def draw_mousetrap(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    # Wood Base
    draw.rectangle((x + 3, y + 8, x + 28, y + 24), fill=(185, 135, 80), outline=(100, 65, 30), width=2)
    # Copper Spring / Trigger Wire
    draw.ellipse((x + 13, y + 12, x + 18, y + 18), fill=(220, 160, 40), outline=(130, 90, 20))
    # Steel Snap Bar
    draw.line([(x + 5, y + 14), (x + 26, y + 14)], fill=(220, 50, 50), width=2)
    # Cheese bait bit
    draw.polygon([(x + 14, y + 12), (x + 18, y + 12), (x + 16, y + 9)], fill=(255, 215, 0))


def main() -> None:
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Row 0: Mouse directions & animations
    draw_mouse_up(draw, 0 * TILE_SIZE, 0 * TILE_SIZE)
    draw_mouse_down(draw, 1 * TILE_SIZE, 0 * TILE_SIZE)
    draw_mouse_left(draw, 2 * TILE_SIZE, 0 * TILE_SIZE)
    draw_mouse_right(draw, 3 * TILE_SIZE, 0 * TILE_SIZE)

    # Row 1: Cats
    draw_cat_normal(draw, 0 * TILE_SIZE, 1 * TILE_SIZE)
    draw_cat_sleeping(draw, 1 * TILE_SIZE, 1 * TILE_SIZE)
    draw_cat_trapped(draw, 2 * TILE_SIZE, 1 * TILE_SIZE)

    # Row 2: Pushable Blocks & Obstacles
    draw_block(draw, 0 * TILE_SIZE, 2 * TILE_SIZE)
    draw_wall(draw, 1 * TILE_SIZE, 2 * TILE_SIZE)

    # Row 3: Items & Treats
    draw_cheese(draw, 0 * TILE_SIZE, 3 * TILE_SIZE)
    draw_mousetrap(draw, 1 * TILE_SIZE, 3 * TILE_SIZE)

    out_path = Path(__file__).resolve().parent / "rodentsrevenge.png"
    img.save(out_path, "PNG")
    print(f"Generated {out_path} ({WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    main()
