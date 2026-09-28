#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Missile Command:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Silo Batteries & Radar (Active Silo, Camo Bunker, Damaged Silo, Destroyed Rubble)
Row 1 (Y=64..127):  Cities (Metropolis Active 1, Spire City Active 2, Dome City Active 3, Burning City, Ruined Rubble)
Row 2 (Y=128..191): Fireball Blast Shockwaves (Expanding Nova 1, Nova 2, Nova 3, Smoke Plume 4)
Row 3 (Y=192..255): Air Hazards & Crosshairs (Bomber Aircraft, Spy Satellite, Target Reticle 1, Target Reticle 2)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_silo(draw: ImageDraw.ImageDraw, ox: int, oy: int, state: str = "active") -> None:
    # 3D Fortified missile silo battery
    if state == "destroyed":
        draw.ellipse((ox + 8, oy + 42, ox + 56, oy + 58), fill=(71, 85, 105, 255))
        draw.rectangle((ox + 12, oy + 46, ox + 52, oy + 54), fill=(30, 41, 59, 255))
        return

    # Concrete Bunker Foundation
    draw.polygon([(ox + 6, oy + 54), (ox + 58, oy + 54), (ox + 50, oy + 28), (ox + 14, oy + 28)], fill=(51, 65, 85, 255), outline=(30, 41, 59, 255))
    # Bevel highlight
    draw.line([(ox + 14, oy + 28), (ox + 50, oy + 28)], fill=(148, 163, 184, 255), width=2)
    # Armor blast doors / Hatch
    draw.rectangle((ox + 22, oy + 24, ox + 42, oy + 32), fill=(15, 23, 42, 255), outline=(96, 165, 250, 255), width=2)

    if state == "active":
        # Rotating Radar Dish / Missile Tip
        draw.ellipse((ox + 26, oy + 12, ox + 38, oy + 24), fill=(226, 232, 240, 255), outline=(59, 130, 246, 255), width=2)
        draw.line([(ox + 32, oy + 6), (ox + 32, oy + 16)], fill=(239, 68, 68, 255), width=2)
        # Radar Pulse Light
        draw.ellipse((ox + 30, oy + 4, ox + 34, oy + 8), fill=(34, 197, 94, 255))


def draw_city(draw: ImageDraw.ImageDraw, ox: int, oy: int, city_type: int = 1, is_ruined: bool = False) -> None:
    if is_ruined:
        draw.ellipse((ox + 4, oy + 44, ox + 60, oy + 58), fill=(51, 65, 85, 255))
        draw.rectangle((ox + 10, oy + 48, ox + 54, oy + 56), fill=(30, 41, 59, 255))
        # Orange burning embers
        draw.ellipse((ox + 16, oy + 42, ox + 22, oy + 48), fill=(239, 68, 68, 255))
        draw.ellipse((ox + 36, oy + 40, ox + 44, oy + 46), fill=(249, 115, 22, 255))
        return

    # Skyscraper 1
    draw.rectangle((ox + 8, oy + 20, ox + 22, oy + 54), fill=(30, 58, 138, 255), outline=(59, 130, 246, 255), width=1)
    # Skyscraper 2 (Center Spire)
    draw.rectangle((ox + 24, oy + 10, ox + 40, oy + 54), fill=(23, 37, 84, 255), outline=(96, 165, 250, 255), width=1)
    draw.line([(ox + 32, oy + 2), (ox + 32, oy + 10)], fill=(239, 68, 68, 255), width=2)
    # Skyscraper 3
    draw.rectangle((ox + 42, oy + 26, ox + 56, oy + 54), fill=(30, 58, 138, 255), outline=(59, 130, 246, 255), width=1)

    # Lit Amber Windows
    for wy in range(24, 50, 6):
        draw.point((ox + 12, wy), fill=(254, 240, 138, 255))
        draw.point((ox + 18, wy), fill=(254, 240, 138, 255))
        draw.point((ox + 28, wy), fill=(254, 240, 138, 255))
        draw.point((ox + 36, wy), fill=(254, 240, 138, 255))
        draw.point((ox + 46, wy), fill=(254, 240, 138, 255))
        draw.point((ox + 52, wy), fill=(254, 240, 138, 255))


def draw_blast(draw: ImageDraw.ImageDraw, ox: int, oy: int, stage: int = 1) -> None:
    # 3D Plasma explosion shockwave
    cx, cy = ox + 32, oy + 32
    r_outer = 12 + stage * 6
    r_inner = r_outer * 0.65
    r_core = r_inner * 0.5

    # Outer shockwave corona
    draw.ellipse((cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer), fill=(239, 68, 68, 200), outline=(254, 240, 138, 255), width=2)
    # Middle Nova Fireball
    draw.ellipse((cx - r_inner, cy - r_inner, cx + r_inner, cy + r_inner), fill=(249, 115, 22, 255))
    # Hot White/Cyan Core
    draw.ellipse((cx - r_core, cy - r_core, cx + r_core, cy + r_core), fill=(255, 255, 255, 255))


def draw_ufo(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_plane: bool = False) -> None:
    if is_plane:
        # High Altitude Stealth Bomber
        draw.polygon([(ox + 32, oy + 16), (ox + 58, oy + 38), (ox + 32, oy + 34), (ox + 6, oy + 38)], fill=(51, 65, 85, 255), outline=(148, 163, 184, 255), width=2)
        draw.ellipse((ox + 30, oy + 22, ox + 34, oy + 26), fill=(239, 68, 68, 255))
    else:
        # Killer Spy Satellite / UFO
        draw.ellipse((ox + 16, oy + 22, ox + 48, oy + 38), fill=(71, 85, 105, 255), outline=(6, 182, 212, 255), width=2)
        # Dome Cockpit
        draw.ellipse((ox + 24, oy + 14, ox + 40, oy + 28), fill=(6, 182, 212, 230), outline=(207, 250, 254, 255))
        # Solar Panel Wings
        draw.rectangle((ox + 4, oy + 26, ox + 14, oy + 34), fill=(30, 58, 138, 255), outline=(96, 165, 250, 255))
        draw.rectangle((ox + 50, oy + 26, ox + 60, oy + 34), fill=(30, 58, 138, 255), outline=(96, 165, 250, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Silo Batteries
    draw_silo(draw, 0 * C, 0, state="active")
    draw_silo(draw, 1 * C, 0, state="camo")
    draw_silo(draw, 2 * C, 0, state="damaged")
    draw_silo(draw, 3 * C, 0, state="destroyed")

    # Row 1: Cities
    draw_city(draw, 0 * C, 1 * C, city_type=1, is_ruined=False)
    draw_city(draw, 1 * C, 1 * C, city_type=2, is_ruined=False)
    draw_city(draw, 2 * C, 1 * C, city_type=3, is_ruined=False)
    draw_city(draw, 3 * C, 1 * C, city_type=1, is_ruined=True)

    # Row 2: Blast Shockwaves
    for f in range(4):
        draw_blast(draw, f * C, 2 * C, stage=f + 1)

    # Row 3: Hazards & Crosshairs
    draw_ufo(draw, 0 * C, 3 * C, is_plane=False)
    draw_ufo(draw, 1 * C, 3 * C, is_plane=True)

    # Target Crosshairs
    cx, cy = 2 * C + 32, 3 * C + 32
    draw.ellipse((cx - 16, cy - 16, cx + 16, cy + 16), outline=(250, 204, 21, 255), width=2)
    draw.line([(cx - 22, cy), (cx + 22, cy)], fill=(250, 204, 21, 255), width=2)
    draw.line([(cx, cy - 22), (cx, cy + 22)], fill=(250, 204, 21, 255), width=2)

    out_path = root / "assets" / "sprites" / "missilecommand.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "missilecommand" / "assets" / "sprites" / "missilecommand.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
