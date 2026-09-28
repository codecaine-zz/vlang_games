#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Boulder Dash (1984 First Star Classic):
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Rockford Miner - 1: Idle/Blink, 2: Walk Left, 3: Walk Right, 4: Digging, 5: Victory
Row 1 (Y=64..127):  Terrain - 1: Steel Wall, 2: Brick Wall, 3: Soil/Dirt, 4: Magic Wall
Row 2 (Y=128..191): Objects - 1: Boulder, 2: Diamond (Frame 1), 3: Diamond (Frame 2 Sparkle), 4: Exit Closed, 5: Exit Open
Row 3 (Y=192..255): Creatures - 1: Firefly (Frame 1), 2: Firefly (Frame 2), 3: Butterfly (Frame 1), 4: Butterfly (Frame 2), 5: Amoeba Slime
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64


def draw_rockford(draw: ImageDraw.ImageDraw, ox: int, oy: int, pose: str) -> None:
    cx, cy = ox + 32, oy + 32
    # Blue Denim Overalls (37, 99, 235), Red Shirt (220, 38, 38), Yellow Mining Helmet (234, 179, 8) with Flashlight

    # Yellow Miner Helmet with Headlamp
    draw.polygon([(cx - 14, cy - 14), (cx + 14, cy - 14), (cx + 10, cy - 24), (cx - 10, cy - 24)], fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=2)
    # Headlamp Lens & Glow
    draw.rectangle((cx - 4, cy - 22, cx + 4, cy - 16), fill=(254, 240, 138, 255), outline=(255, 255, 255, 255))
    draw.polygon([(cx - 2, cy - 24), (cx + 2, cy - 24), (cx + 10, cy - 30), (cx - 10, cy - 30)], fill=(255, 255, 200, 120))

    # Rockford Face & Big Expressive Eyes
    draw.ellipse((cx - 12, cy - 14, cx + 12, cy + 4), fill=(254, 215, 170, 255), outline=(15, 23, 42, 255), width=2)
    # Big Eyes
    draw.ellipse((cx - 8, cy - 10, cx - 2, cy - 2), fill=(255, 255, 255, 255))
    draw.ellipse((cx + 2, cy - 10, cx + 8, cy - 2), fill=(255, 255, 255, 255))
    draw.ellipse((cx - 6, cy - 7, cx - 3, cy - 4), fill=(15, 23, 42, 255))
    draw.ellipse((cx + 4, cy - 7, cx + 7, cy - 4), fill=(15, 23, 42, 255))
    # Red Nose
    draw.ellipse((cx - 3, cy - 4, cx + 3, cy + 1), fill=(239, 68, 68, 255))

    # Red Shirt Body & Denim Overalls
    draw.rectangle((cx - 10, cy + 4, cx + 10, cy + 18), fill=(220, 38, 38, 255))
    draw.polygon([(cx - 8, cy + 8), (cx + 8, cy + 8), (cx + 10, cy + 20), (cx - 10, cy + 20)], fill=(37, 99, 235, 255))
    # Overalls Straps & Yellow Buttons
    draw.rectangle((cx - 7, cy + 6, cx - 4, cy + 14), fill=(29, 78, 216, 255))
    draw.rectangle((cx + 4, cy + 6, cx + 7, cy + 14), fill=(29, 78, 216, 255))
    draw.ellipse((cx - 6, cy + 12, cx - 4, cy + 14), fill=(234, 179, 8, 255))
    draw.ellipse((cx + 4, cy + 12, cx + 6, cy + 14), fill=(234, 179, 8, 255))

    # Boots
    if pose == "walk_r":
        draw.rectangle((cx - 10, cy + 20, cx - 4, cy + 26), fill=(120, 53, 15, 255))
        draw.rectangle((cx + 2, cy + 18, cx + 10, cy + 24), fill=(120, 53, 15, 255))
    elif pose == "walk_l":
        draw.rectangle((cx - 10, cy + 18, cx - 2, cy + 24), fill=(120, 53, 15, 255))
        draw.rectangle((cx + 4, cy + 20, cx + 10, cy + 26), fill=(120, 53, 15, 255))
    else:
        draw.rectangle((cx - 9, cy + 20, cx - 3, cy + 26), fill=(120, 53, 15, 255))
        draw.rectangle((cx + 3, cy + 20, cx + 9, cy + 26), fill=(120, 53, 15, 255))


def draw_steel_wall(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Titanium Outer Boundary Wall with Inset Panels & Rivets
    draw.rectangle((ox + 2, oy + 2, ox + C - 2, oy + C - 2), fill=(100, 116, 139, 255), outline=(51, 65, 85, 255), width=3)
    draw.rectangle((ox + 8, oy + 8, ox + C - 8, oy + C - 8), fill=(71, 85, 105, 255), outline=(148, 163, 184, 255), width=2)
    # Metallic cross hatch
    draw.line([(ox + 8, oy + 8), (ox + C - 8, oy + C - 8)], fill=(51, 65, 85, 255), width=2)
    draw.line([(ox + C - 8, oy + 8), (ox + 8, oy + C - 8)], fill=(51, 65, 85, 255), width=2)
    # Corner rivets
    for rx, ry in [(ox + 5, oy + 5), (ox + C - 7, oy + 5), (ox + 5, oy + C - 7), (ox + C - 7, oy + C - 7)]:
        draw.rectangle((rx, ry, rx + 2, ry + 2), fill=(226, 232, 240, 255))


def draw_brick_wall(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Rounded Terracotta Masonry
    draw.rectangle((ox + 2, oy + 2, ox + C - 2, oy + C - 2), fill=(185, 28, 28, 255), outline=(69, 10, 10, 255), width=2)
    # Brick row lines
    draw.line([(ox + 2, oy + 20), (ox + C - 2, oy + 20)], fill=(69, 10, 10, 255), width=3)
    draw.line([(ox + 2, oy + 42), (ox + C - 2, oy + 42)], fill=(69, 10, 10, 255), width=3)
    # Vertical mortar seams
    draw.line([(ox + 32, oy + 2), (ox + 32, oy + 20)], fill=(69, 10, 10, 255), width=2)
    draw.line([(ox + 16, oy + 20), (ox + 16, oy + 42)], fill=(69, 10, 10, 255), width=2)
    draw.line([(ox + 48, oy + 20), (ox + 48, oy + 42)], fill=(69, 10, 10, 255), width=2)
    draw.line([(ox + 32, oy + 42), (ox + 32, oy + C - 2)], fill=(69, 10, 10, 255), width=2)
    # Highlights
    draw.line([(ox + 4, oy + 4), (ox + 30, oy + 4)], fill=(239, 68, 68, 255), width=2)


def draw_soil(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Organic Subterranean Soil with Granular Earth Pebbles
    draw.rectangle((ox + 2, oy + 2, ox + C - 2, oy + C - 2), fill=(120, 53, 15, 255))
    # Speckled pebble dots & root threads
    pebbles = [
        (ox + 12, oy + 14, (180, 83, 9, 255)),
        (ox + 38, oy + 10, (217, 119, 6, 255)),
        (ox + 24, oy + 28, (146, 64, 14, 255)),
        (ox + 48, oy + 32, (180, 83, 9, 255)),
        (ox + 16, oy + 46, (217, 119, 6, 255)),
        (ox + 42, oy + 50, (146, 64, 14, 255)),
    ]
    for px, py, col in pebbles:
        draw.rectangle((px, py, px + 5, py + 5), fill=col)


def draw_boulder(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    r = 26
    # 3D Granite Shading
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(100, 116, 139, 255), outline=(30, 41, 59, 255), width=3)
    # Highlight Crescent
    draw.ellipse((cx - r + 4, cy - r + 4, cx + r // 2, cy + r // 3), fill=(203, 213, 225, 255))
    # Rock Texture Craters
    draw.ellipse((cx - 8, cy + 6, cx - 2, cy + 12), fill=(51, 65, 85, 255))
    draw.ellipse((cx + 8, cy - 4, cx + 14, cy + 2), fill=(51, 65, 85, 255))


def draw_diamond(draw: ImageDraw.ImageDraw, ox: int, oy: int, sparkle: bool) -> None:
    cx, cy = ox + 32, oy + 32
    r = 24
    # Brilliant Cyan Gem Facets
    # Diamond Polygon
    draw.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=(6, 182, 212, 255), outline=(8, 145, 178, 255), width=2)
    # Inner Cut Facets
    draw.polygon([(cx, cy - r), (cx + r // 2, cy - r // 2), (cx, cy), (cx - r // 2, cy - r // 2)], fill=(165, 243, 252, 255))
    draw.polygon([(cx + r, cy), (cx + r // 2, cy - r // 2), (cx, cy), (cx + r // 2, cy + r // 2)], fill=(34, 211, 238, 255))
    draw.polygon([(cx, cy + r), (cx + r // 2, cy + r // 2), (cx, cy), (cx - r // 2, cy + r // 2)], fill=(8, 145, 178, 255))
    draw.polygon([(cx - r, cy), (cx - r // 2, cy - r // 2), (cx, cy), (cx - r // 2, cy + r // 2)], fill=(14, 116, 144, 255))

    if sparkle:
        # Glint Flare
        draw.line([(cx - 10, cy - r - 4), (cx - 10, cy - r + 8)], fill=(255, 255, 255, 255), width=3)
        draw.line([(cx - 16, cy - r + 2), (cx - 4, cy - r + 2)], fill=(255, 255, 255, 255), width=3)


def draw_exit(draw: ImageDraw.ImageDraw, ox: int, oy: int, open_state: bool) -> None:
    # Exit Hatch / Portal
    draw.rectangle((ox + 4, oy + 4, ox + C - 4, oy + C - 4), fill=(30, 41, 59, 255), outline=(245, 158, 11, 255), width=3)
    if open_state:
        # Glowing Emerald Exit Gateway
        draw.rectangle((ox + 10, oy + 10, ox + C - 10, oy + C - 10), fill=(34, 197, 94, 255), outline=(255, 255, 255, 255), width=2)
        draw.ellipse((ox + 20, oy + 20, ox + C - 20, oy + C - 20), fill=(255, 255, 255, 255))
    else:
        # Padlocked Metal Grid
        draw.line([(ox + 12, oy + 12), (ox + C - 12, oy + C - 12)], fill=(239, 68, 68, 255), width=4)
        draw.line([(ox + C - 12, oy + 12), (ox + 12, oy + C - 12)], fill=(239, 68, 68, 255), width=4)
        draw.rectangle((ox + 24, oy + 24, ox + 40, oy + 40), fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=2)


def draw_firefly(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Glowing Orange Subterranean Firefly
    draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=(245, 158, 11, 255), outline=(180, 83, 9, 255), width=2)
    draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(254, 240, 138, 255))
    # Glowing Wings
    wing_w = 14 if frame == 0 else 8
    draw.ellipse((cx - 18, cy - wing_w, cx - 6, cy + wing_w), fill=(253, 224, 71, 200))
    draw.ellipse((cx + 6, cy - wing_w, cx + 18, cy + wing_w), fill=(253, 224, 71, 200))


def draw_butterfly(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Prismatic Magenta / Cyan Butterfly (explodes into diamonds)
    draw.ellipse((cx - 4, cy - 14, cx + 4, cy + 14), fill=(15, 23, 42, 255))
    wing_span = 18 if frame == 0 else 10
    draw.polygon([(cx - 4, cy), (cx - wing_span - 6, cy - 16), (cx - wing_span - 2, cy + 16)], fill=(236, 72, 153, 255), outline=(244, 114, 182, 255), width=2)
    draw.polygon([(cx + 4, cy), (cx + wing_span + 6, cy - 16), (cx + wing_span + 2, cy + 16)], fill=(6, 182, 212, 255), outline=(165, 243, 252, 255), width=2)


def draw_amoeba(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Bubbling Slime Biomass
    draw.ellipse((cx - 24, cy - 24, cx + 24, cy + 24), fill=(34, 197, 94, 255), outline=(21, 128, 61, 255), width=3)
    draw.ellipse((cx - 14, cy - 14, cx, cy), fill=(134, 239, 172, 255))
    draw.ellipse((cx + 4, cy + 4, cx + 16, cy + 16), fill=(134, 239, 172, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Rockford Poses
    draw_rockford(draw, 0 * C, 0 * C, pose="idle")
    draw_rockford(draw, 1 * C, 0 * C, pose="walk_l")
    draw_rockford(draw, 2 * C, 0 * C, pose="walk_r")

    # Row 1: Terrain
    draw_steel_wall(draw, 0 * C, 1 * C)
    draw_brick_wall(draw, 1 * C, 1 * C)
    draw_soil(draw, 2 * C, 1 * C)

    # Row 2: Objects
    draw_boulder(draw, 0 * C, 2 * C)
    draw_diamond(draw, 1 * C, 2 * C, sparkle=False)
    draw_diamond(draw, 2 * C, 2 * C, sparkle=True)
    draw_exit(draw, 3 * C, 2 * C, open_state=False)
    draw_exit(draw, 4 * C, 2 * C, open_state=True)

    # Row 3: Creatures
    draw_firefly(draw, 0 * C, 3 * C, frame=0)
    draw_firefly(draw, 1 * C, 3 * C, frame=1)
    draw_butterfly(draw, 2 * C, 3 * C, frame=0)
    draw_butterfly(draw, 3 * C, 3 * C, frame=1)
    draw_amoeba(draw, 4 * C, 3 * C)

    out_path = root / "assets" / "sprites" / "boulderdash.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "boulderdash" / "assets" / "sprites" / "boulderdash.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
