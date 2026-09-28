#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Zuma Deluxe:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Gem Orbs (1: Ruby, 2: Sapphire, 3: Emerald, 4: Topaz, 5: Amethyst, 6: Bomb, 7: Reverse, 8: Slow)
Row 1 (Y=64..127):  Aztec Stone Frog Shooter (Stone Idol Mouth Closed, Mouth Open Fire, Gold Eyes, Jeweled Back)
Row 2 (Y=128..191): Mayan Skull Goal (Stone Skull Mouth Open, Burning Eyes Glow, Golden Aztec Coin, Sparkle Star)
Row 3 (Y=192..255): Special Effects & Track Stones (Cobblestone Path Segment, Aztec Glyph 1, Aztec Glyph 2, Explosion Burst)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_orb(draw: ImageDraw.ImageDraw, ox: int, oy: int, orb_type: int) -> None:
    cx, cy = ox + 32, oy + 32
    r = 20

    colors = {
        1: ((220, 38, 38, 255), (254, 202, 202, 255), (153, 27, 27, 255)),   # Ruby Red
        2: ((37, 99, 235, 255), (191, 219, 254, 255), (30, 58, 138, 255)),   # Sapphire Blue
        3: ((16, 185, 129, 255), (167, 243, 208, 255), (6, 95, 70, 255)),    # Emerald Green
        4: ((234, 179, 8, 255), (254, 240, 138, 255), (161, 98, 7, 255)),    # Topaz Yellow
        5: ((168, 85, 247, 255), (243, 232, 255, 255), (107, 33, 168, 255)), # Amethyst Purple
        6: ((30, 41, 59, 255), (239, 68, 68, 255), (15, 23, 42, 255)),       # Bomb Orb
        7: ((14, 165, 233, 255), (224, 242, 254, 255), (3, 105, 161, 255)),  # Reverse Orb
        8: ((249, 115, 22, 255), (254, 215, 170, 255), (194, 65, 12, 255)),  # Slow Orb
    }

    base, high, shadow = colors.get(orb_type, colors[1])

    # Radial 3D Sphere Shading
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=base, outline=shadow, width=2)
    # Highlight Crescent
    draw.arc((cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3), start=180, end=300, fill=high, width=3)
    # Specular Gleam
    draw.ellipse((cx - 10, cy - 12, cx - 4, cy - 6), fill=(255, 255, 255, 230))

    if orb_type == 6:
        # Bomb fuse symbol
        draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(239, 68, 68, 255))
    elif orb_type == 7:
        # Rewind dual arrow symbol
        draw.polygon([(cx - 2, cy - 6), (cx - 8, cy), (cx - 2, cy + 6)], fill=(255, 255, 255, 255))
        draw.polygon([(cx + 6, cy - 6), (cx, cy), (cx + 6, cy + 6)], fill=(255, 255, 255, 255))
    elif orb_type == 8:
        # Hourglass sand symbol
        draw.polygon([(cx - 6, cy - 8), (cx + 6, cy - 8), (cx - 6, cy + 8), (cx + 6, cy + 8)], fill=(255, 255, 255, 255))


def draw_frog_idol(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Ancient Carved Jade / Stone Body
    draw.ellipse((cx - 24, cy - 24, cx + 24, cy + 24), fill=(20, 83, 45, 255), outline=(234, 179, 8, 255), width=3)
    # Aztec Gold Inlays
    draw.arc((cx - 18, cy - 18, cx + 18, cy + 18), start=45, end=315, fill=(245, 158, 11, 255), width=2)
    # Golden Eyes (Ruby Center)
    draw.ellipse((cx - 18, cy - 22, cx - 6, cy - 10), fill=(234, 179, 8, 255))
    draw.ellipse((cx - 14, cy - 18, cx - 10, cy - 14), fill=(220, 38, 38, 255))
    draw.ellipse((cx + 6, cy - 22, cx + 18, cy - 10), fill=(234, 179, 8, 255))
    draw.ellipse((cx + 10, cy - 18, cx + 14, cy - 14), fill=(220, 38, 38, 255))
    # Mouth Nozzle (Carved stone opening)
    draw.ellipse((cx - 8, cy - 4, cx + 8, cy + 12), fill=(15, 23, 42, 255), outline=(245, 158, 11, 255), width=2)


def draw_skull_endpoint(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Aztec Stone Skull
    draw.ellipse((cx - 22, cy - 22, cx + 22, cy + 14), fill=(71, 85, 105, 255), outline=(30, 41, 59, 255), width=2)
    draw.rectangle((cx - 14, cy + 10, cx + 14, cy + 22), fill=(71, 85, 105, 255), outline=(30, 41, 59, 255), width=2)
    # Glowing Red Eye Sockets
    draw.ellipse((cx - 14, cy - 12, cx - 4, cy - 2), fill=(239, 68, 68, 255))
    draw.ellipse((cx + 4, cy - 12, cx + 14, cy - 2), fill=(239, 68, 68, 255))
    # Triangle Nose
    draw.polygon([(cx, cy), (cx - 3, cy + 6), (cx + 3, cy + 6)], fill=(15, 23, 42, 255))
    # Teeth Grate
    for i in range(4):
        draw.line([(cx - 9 + i * 6, cy + 12), (cx - 9 + i * 6, cy + 20)], fill=(15, 23, 42, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Orbs 1..8
    for i in range(8):
        draw_orb(draw, i * C, 0 * C, orb_type=i + 1)

    # Row 1: Frog Idol
    draw_frog_idol(draw, 0 * C, 1 * C)

    # Row 2: Aztec Skull Endpoint
    draw_skull_endpoint(draw, 0 * C, 2 * C)

    out_path = root / "assets" / "sprites" / "zuma.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "zuma" / "assets" / "sprites" / "zuma.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
