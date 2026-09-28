#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Lunar Lander:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Apollo Lunar Module LEM (LEM Idle, LEM Main Thrust Plume, LEM RCS Left, LEM RCS Right)
Row 1 (Y=64..127):  Landing Pads (Green Pad 2X, Cyan Pad 3X, Gold Pad 5X, Touchdown Beacon Light)
Row 2 (Y=128..191): Astronaut & Flag (Astronaut Walking, Planting Flag, American Flag Waving 2-frames)
Row 3 (Y=192..255): Crash & Shrapnel (Debris Chunk 1, Debris Chunk 2, Sparks Nova, Impact Crater)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_lem(draw: ImageDraw.ImageDraw, ox: int, oy: int, thrust: str = "none") -> None:
    # 1. Lower Descent Stage (Gold Mylar Foil Octagon with Brass Bevels)
    draw.polygon([(ox + 20, oy + 32), (ox + 44, oy + 32), (ox + 48, oy + 44), (ox + 16, oy + 44)], fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=2)
    # Mylar foil pattern
    draw.line([(ox + 28, oy + 32), (ox + 28, oy + 44)], fill=(254, 240, 138, 255))
    draw.line([(ox + 36, oy + 32), (ox + 36, oy + 44)], fill=(254, 240, 138, 255))

    # 2. Upper Ascent Stage (White/Grey Pressurized Cockpit)
    draw.polygon([(ox + 24, oy + 18), (ox + 40, oy + 18), (ox + 46, oy + 30), (ox + 18, oy + 30)], fill=(226, 232, 240, 255), outline=(100, 116, 139, 255), width=2)
    # Cockpit Triangular Triangular Windows
    draw.polygon([(ox + 26, oy + 22), (ox + 30, oy + 22), (ox + 28, oy + 26)], fill=(6, 182, 212, 255))
    draw.polygon([(ox + 34, oy + 22), (ox + 38, oy + 22), (ox + 36, oy + 26)], fill=(6, 182, 212, 255))
    # Top VHF Antenna & Docking Hatch
    draw.rectangle((ox + 30, oy + 14, ox + 34, oy + 18), fill=(148, 163, 184, 255))
    draw.line([(ox + 32, oy + 10), (ox + 32, oy + 14)], fill=(239, 68, 68, 255), width=2)

    # 3. Landing Gear Struts & Footpads
    draw.line([(ox + 20, oy + 44), (ox + 10, oy + 56)], fill=(148, 163, 184, 255), width=2)
    draw.line([(ox + 44, oy + 44), (ox + 54, oy + 56)], fill=(148, 163, 184, 255), width=2)
    # Dish footpads
    draw.ellipse((ox + 6, oy + 54, ox + 14, oy + 58), fill=(203, 213, 225, 255))
    draw.ellipse((ox + 50, oy + 54, ox + 58, oy + 58), fill=(203, 213, 225, 255))

    # 4. Engine Nozzle & Thruster Plume
    draw.polygon([(ox + 28, oy + 44), (ox + 36, oy + 44), (ox + 38, oy + 48), (ox + 26, oy + 48)], fill=(71, 85, 105, 255))

    if thrust == "main":
        # Fiery Exhaust Plume Cone
        draw.polygon([(ox + 28, oy + 48), (ox + 36, oy + 48), (ox + 32, oy + 62)], fill=(249, 115, 22, 255))
        draw.polygon([(ox + 30, oy + 48), (ox + 34, oy + 48), (ox + 32, oy + 56)], fill=(254, 240, 138, 255))
    elif thrust == "rcs_left":
        # RCS jet firing right
        draw.line([(ox + 46, oy + 24), (ox + 56, oy + 24)], fill=(6, 182, 212, 255), width=2)
    elif thrust == "rcs_right":
        # RCS jet firing left
        draw.line([(ox + 18, oy + 24), (ox + 8, oy + 24)], fill=(6, 182, 212, 255), width=2)


def draw_pad(draw: ImageDraw.ImageDraw, ox: int, oy: int, multiplier: str = "2X") -> None:
    color = (34, 197, 94, 255) if multiplier == "2X" else ((6, 182, 212, 255) if multiplier == "3X" else (234, 179, 8, 255))
    # Glowing Landing Pad Foundation
    draw.rectangle((ox + 4, oy + 36, ox + 60, oy + 48), fill=color, outline=(255, 255, 255, 255), width=2)
    # Strobe beacon towers
    draw.ellipse((ox + 6, oy + 30, ox + 12, oy + 36), fill=(255, 255, 255, 255))
    draw.ellipse((ox + 52, oy + 30, ox + 58, oy + 36), fill=(255, 255, 255, 255))


def draw_astronaut(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Mini Apollo Astronaut with Gold Visor
    draw.ellipse((ox + 26, oy + 22, ox + 38, oy + 34), fill=(255, 255, 255, 255)) # Helmet
    draw.ellipse((ox + 28, oy + 25, ox + 36, oy + 31), fill=(234, 179, 8, 255)) # Gold Visor
    draw.rectangle((ox + 24, oy + 34, ox + 40, oy + 48), fill=(241, 245, 249, 255)) # Suit
    # PLSS Backpack
    draw.rectangle((ox + 20, oy + 32, ox + 24, oy + 44), fill=(203, 213, 225, 255))
    # Boots
    draw.ellipse((ox + 24, oy + 48, ox + 31, oy + 54), fill=(100, 116, 139, 255))
    draw.ellipse((ox + 33, oy + 48, ox + 40, oy + 54), fill=(100, 116, 139, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: LEM Lander
    draw_lem(draw, 0 * C, 0, thrust="none")
    draw_lem(draw, 1 * C, 0, thrust="main")
    draw_lem(draw, 2 * C, 0, thrust="rcs_left")
    draw_lem(draw, 3 * C, 0, thrust="rcs_right")

    # Row 1: Landing Pads
    draw_pad(draw, 0 * C, 1 * C, multiplier="2X")
    draw_pad(draw, 1 * C, 1 * C, multiplier="3X")
    draw_pad(draw, 2 * C, 1 * C, multiplier="5X")

    # Row 2: Astronaut & Flag
    draw_astronaut(draw, 0 * C, 2 * C)

    # American Flag on lunar surface
    draw.line([(1 * C + 20, 2 * C + 16), (1 * C + 20, 2 * C + 54)], fill=(203, 213, 225, 255), width=2)
    draw.rectangle((1 * C + 22, 2 * C + 18, 1 * C + 46, 2 * C + 34), fill=(239, 68, 68, 255))
    draw.rectangle((1 * C + 22, 2 * C + 18, 1 * C + 32, 2 * C + 26), fill=(30, 58, 138, 255))

    out_path = root / "assets" / "sprites" / "lunarlander.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "lunarlander" / "assets" / "sprites" / "lunarlander.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
