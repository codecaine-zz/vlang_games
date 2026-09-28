#!/usr/bin/env python3
"""Generate high-fidelity 512x512 RGBA sprite sheet for Championship Darts Pro:
- Row 0 (Y=0..63): Steel-tip Darts (Red Flight, Blue Flight, Gold Flight, Green Flight in flight & embedded)
- Row 1 (Y=64..127): Flying Darts Perspective & Angle Variations
- Row 2 (Y=128..191): Aim Reticles & Power Indicators (Normal Crosshair, Locked Reticle, Bullseye Target, Power Bar Pins)
- Row 3 (Y=192..255): Chalkboard & Tournament Badges (Trophy Cup, 180 Banner, Bullseye Medal, Chalk Stick, Beer Mug, Crown)
- Row 4 (Y=256..319): Dartboard Numbers & Brass Brackets (Decorative Accents)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_dart_horizontal(draw: ImageDraw.ImageDraw, ox: int, oy: int, flight_col: tuple[int, int, int] = (220, 38, 38)) -> None:
    # High-end tungsten steel-tip dart (64x24)
    # 1. Steel Point Tip
    draw.polygon([(ox + 4, oy + 12), (ox + 16, oy + 10), (ox + 16, oy + 14)], fill=(226, 232, 240, 255), outline=(148, 163, 184, 255))

    # 2. Tungsten / Brass Barrel with knurled grip rings
    draw.rectangle((ox + 16, oy + 9, ox + 36, oy + 15), fill=(217, 119, 6, 255), outline=(180, 83, 9, 255))
    for gx in range(ox + 18, ox + 36, 4):
        draw.line([(gx, oy + 9), (gx, oy + 15)], fill=(254, 240, 138, 255), width=1)

    # 3. Shaft (Nylon / Titanium)
    draw.rectangle((ox + 36, oy + 11, ox + 48, oy + 13), fill=(15, 23, 42, 255), outline=(100, 116, 139, 255))

    # 4. Flight Fins (Standard 4-wing aerodynamic shape)
    draw.polygon([(ox + 46, oy + 12), (ox + 60, oy + 3), (ox + 62, oy + 6), (ox + 50, oy + 12)], fill=(*flight_col, 255), outline=(255, 255, 255, 220))
    draw.polygon([(ox + 46, oy + 12), (ox + 60, oy + 21), (ox + 62, oy + 18), (ox + 50, oy + 12)], fill=(*flight_col, 255), outline=(255, 255, 255, 220))
    draw.polygon([(ox + 48, oy + 7), (ox + 60, oy + 7), (ox + 56, oy + 17), (ox + 48, oy + 17)], fill=(*flight_col, 200))


def draw_dart_embedded(draw: ImageDraw.ImageDraw, ox: int, oy: int, flight_col: tuple[int, int, int] = (220, 38, 38)) -> None:
    # 3D Angled Dart stuck in board (facing into board at 45 degrees, 32x32)
    # Shadow
    draw.ellipse((ox + 14, oy + 24, ox + 26, oy + 30), fill=(10, 15, 25, 120))
    # Tip entry point
    draw.ellipse((ox + 14, oy + 18, ox + 18, oy + 22), fill=(15, 23, 42, 255))
    # Barrel & Shaft rising up-right
    draw.line([(ox + 16, oy + 20), (ox + 26, oy + 8)], fill=(217, 119, 6, 255), width=3)
    draw.line([(ox + 16, oy + 20), (ox + 26, oy + 8)], fill=(254, 240, 138, 255), width=1)
    # Flight wings at top
    draw.polygon([(ox + 24, oy + 10), (ox + 22, oy + 2), (ox + 30, oy + 6)], fill=(*flight_col, 255), outline=(255, 255, 255, 240))
    draw.polygon([(ox + 24, oy + 10), (ox + 30, oy + 14), (ox + 31, oy + 4)], fill=(*flight_col, 255), outline=(255, 255, 255, 240))


def draw_reticle(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_locked: bool = False) -> None:
    # 48x48 precision aiming crosshair
    col = (239, 68, 68) if is_locked else (34, 211, 238)
    cx, cy = ox + 24, oy + 24
    # Outer circle
    draw.ellipse((cx - 18, cy - 18, cx + 18, cy + 18), outline=(*col, 240), width=2)
    # Inner dot
    draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(*col, 255), outline=(255, 255, 255, 255))
    # Crosshair ticks
    draw.line([(cx - 24, cy), (cx - 10, cy)], fill=(*col, 255), width=2)
    draw.line([(cx + 10, cy), (cx + 24, cy)], fill=(*col, 255), width=2)
    draw.line([(cx, cy - 24), (cx, cy - 10)], fill=(*col, 255), width=2)
    draw.line([(cx, cy + 10), (cx, cy + 24)], fill=(*col, 255), width=2)


def draw_trophy(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 48x48 Golden Championship Cup
    draw.polygon([(ox + 12, oy + 10), (ox + 36, oy + 10), (ox + 32, oy + 26), (ox + 16, oy + 26)], fill=(245, 158, 11, 255), outline=(251, 191, 36, 255), width=2)
    # Handles
    draw.arc((ox + 6, oy + 12, ox + 18, oy + 24), start=90, end=270, fill=(245, 158, 11, 255), width=3)
    draw.arc((ox + 30, oy + 12, ox + 42, oy + 24), start=270, end=90, fill=(245, 158, 11, 255), width=3)
    # Stem & Base
    draw.rectangle((ox + 21, oy + 26, ox + 27, oy + 36), fill=(217, 119, 6, 255), outline=(245, 158, 11, 255))
    draw.rectangle((ox + 14, oy + 36, ox + 34, oy + 42), fill=(120, 53, 15, 255), outline=(251, 191, 36, 255), width=2)
    # Star gleam
    draw.ellipse((ox + 20, oy + 14, ox + 28, oy + 22), fill=(255, 255, 255, 240))


def draw_180_badge(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 64x32 "180" Golden Ribbon Badge
    draw.rectangle((ox + 2, oy + 2, ox + 61, oy + 29), fill=(220, 38, 38, 255), outline=(245, 158, 11, 255), width=2)
    draw.line([(ox + 4, oy + 4), (ox + 59, oy + 4)], fill=(254, 240, 138, 255), width=1)
    # Stars on corners
    draw.ellipse((ox + 6, oy + 12, ox + 10, oy + 16), fill=(251, 191, 36, 255))
    draw.ellipse((ox + 53, oy + 12, ox + 57, oy + 16), fill=(251, 191, 36, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0 (Y=0..63): Horizontal Darts (Red, Blue, Gold, Green) (64x32)
    # -------------------------------------------------------------
    draw_dart_horizontal(draw, 0, 4, (220, 38, 38))
    draw_dart_horizontal(draw, 64, 4, (37, 99, 235))
    draw_dart_horizontal(draw, 128, 4, (234, 179, 8))
    draw_dart_horizontal(draw, 192, 4, (22, 163, 74))

    # -------------------------------------------------------------
    # Row 1 (Y=64..127): Embedded Darts (32x32)
    # -------------------------------------------------------------
    draw_dart_embedded(draw, 0, 64, (220, 38, 38))
    draw_dart_embedded(draw, 32, 64, (37, 99, 235))
    draw_dart_embedded(draw, 64, 64, (234, 179, 8))
    draw_dart_embedded(draw, 96, 64, (22, 163, 74))

    # -------------------------------------------------------------
    # Row 2 (Y=128..191): Aim Reticles (48x48)
    # -------------------------------------------------------------
    draw_reticle(draw, 0, 128, is_locked=False)
    draw_reticle(draw, 64, 128, is_locked=True)

    # -------------------------------------------------------------
    # Row 3 (Y=192..255): Trophy & Badges (48x48 & 64x32)
    # -------------------------------------------------------------
    draw_trophy(draw, 0, 192)
    draw_180_badge(draw, 64, 192)

    out_path = root / "assets" / "sprites" / "darts.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "darts" / "assets" / "sprites" / "darts.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
