#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Tower Defense:
Layout:
Row 0 (Y=0..63):    Turrets (Laser 40x40, Cannon 40x40, Frost 40x40, Mega Turret 40x40)
Row 1 (Y=64..127):  Creeps (Normal Bot 32x32, Scout Drone 32x32, Armored Tank 36x36, Boss Mech 48x48)
Row 2 (Y=128..191): Base Core / Energy Shield & Projectiles
Row 3 (Y=192..255): Tiles (Grass, Dirt Path, Build Pad)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_laser_turret(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 20, oy + 20
    # Base Platform
    draw.rectangle((cx - 16, cy - 16, cx + 16, cy + 16), fill=(51, 65, 85, 255), outline=(15, 23, 42, 255), width=2)
    # Turret Swivel
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255), width=2)
    # Dual Laser Barrels
    draw.rectangle((cx - 4, cy - 18, cx - 1, cy - 8), fill=(248, 113, 113, 255))
    draw.rectangle((cx + 1, cy - 18, cx + 4, cy - 8), fill=(248, 113, 113, 255))
    # Glowing Lens
    draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(254, 240, 138, 255))


def draw_cannon_turret(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 20, oy + 20
    # Heavy Octagon Base
    draw.rectangle((cx - 16, cy - 16, cx + 16, cy + 16), fill=(71, 85, 105, 255), outline=(15, 23, 42, 255), width=2)
    draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=(245, 158, 11, 255), outline=(180, 83, 9, 255), width=2)
    # Heavy Artillery Barrel
    draw.rectangle((cx - 5, cy - 19, cx + 5, cy - 6), fill=(30, 41, 59, 255), outline=(217, 119, 6, 255), width=1)
    draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(254, 215, 170, 255))


def draw_frost_turret(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 20, oy + 20
    draw.rectangle((cx - 16, cy - 16, cx + 16, cy + 16), fill=(30, 58, 138, 255), outline=(15, 23, 42, 255), width=2)
    # Cryo Crystal Emitter
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(6, 182, 212, 255), outline=(165, 243, 252, 255), width=2)
    # 4 Crystal Spikes
    for angle in [0, 90, 180, 270]:
        rad = math.radians(angle)
        ex = cx + int(14 * math.cos(rad))
        ey = cy + int(14 * math.sin(rad))
        draw.line([(cx, cy), (ex, ey)], fill=(224, 242, 254, 255), width=3)
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 255, 255, 255))


def draw_creep_normal(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 16, oy + 16
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=2)
    draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(239, 68, 68, 255))


def draw_creep_scout(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 16, oy + 16
    # Fast Hover Drone
    draw.polygon([(cx, cy - 12), (cx + 10, cy + 10), (cx - 10, cy + 10)], fill=(6, 182, 212, 255), outline=(8, 145, 178, 255), width=2)
    draw.ellipse((cx - 3, cy - 2, cx + 3, cy + 4), fill=(255, 255, 255, 255))


def draw_creep_tank(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 18, oy + 18
    # Heavy Mech Armor
    draw.rectangle((cx - 14, cy - 14, cx + 14, cy + 14), fill=(225, 29, 72, 255), outline=(136, 19, 55, 255), width=2)
    draw.rectangle((cx - 8, cy - 8, cx + 8, cy + 8), fill=(71, 85, 105, 255))
    draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(255, 255, 255, 255))


def draw_creep_boss(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 24, oy + 24
    # Giant Cyber Boss Mech
    draw.rectangle((cx - 20, cy - 20, cx + 20, cy + 20), fill=(147, 51, 234, 255), outline=(88, 28, 135, 255), width=3)
    draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=(239, 68, 68, 255), outline=(254, 202, 202, 255), width=2)
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 255, 255, 255))


def draw_base_core(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 20, oy + 20
    draw.rectangle((cx - 16, cy - 16, cx + 16, cy + 16), fill=(15, 23, 42, 255), outline=(16, 185, 129, 255), width=2)
    draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=(16, 185, 129, 255), outline=(167, 243, 208, 255), width=2)
    draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(255, 255, 255, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Turrets (Laser, Cannon, Frost)
    draw_laser_turret(draw, 0 * 48, 0)
    draw_cannon_turret(draw, 1 * 48, 0)
    draw_frost_turret(draw, 2 * 48, 0)

    # Row 1: Creeps (Normal, Scout, Tank, Boss)
    draw_creep_normal(draw, 0 * 48, 64)
    draw_creep_scout(draw, 1 * 48, 64)
    draw_creep_tank(draw, 2 * 48, 64)
    draw_creep_boss(draw, 3 * 48, 64)

    # Row 2: Base Core
    draw_base_core(draw, 0 * 48, 128)

    out_path = root / "assets" / "sprites" / "towerdefense.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "towerdefense" / "assets" / "sprites" / "towerdefense.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
