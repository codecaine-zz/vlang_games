#!/usr/bin/env python3
"""Generate ultra-polished 512x512 RGBA sprite sheet for WorldRunner (3D WorldRunner / Space Runner):
Grid: 64x64 cells (8x8 grid in 512x512 sheet)

Row 0 (Y=0..63):    Player Commando (Run 0, Run 1, Run 2, Run 3, Jump/Air, Jetpack Boost, Laser Firing, Death/Crash)
Row 1 (Y=64..127):  Obstacles & Hazards (Cosmic Pillar, Crystal Spikes, Plasma Barrier, Alien Spire, Void Pit Marker, Electric Gate)
Row 2 (Y=128..191): Collectibles & Items (Super Missile, Invincibility Star, Shield Orb, Laser Powerup, Cyber Key, Gold Medallion, Speed Fuel)
Row 3 (Y=192..255): Segmented Dragon Boss (Boss Head Roar, Boss Head Normal, Boss Body Segment, Boss Tail, Fireball Orb, Reticle Target)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size 64x64


def draw_commando(draw: ImageDraw.ImageDraw, ox: int, oy: int, anim: str = "run0") -> None:
    # 3D Sci-Fi Space Commando with sleek cyber visor and jet thrusters
    # Shadow
    draw.ellipse((ox + 12, oy + 50, ox + 52, oy + 62), fill=(10, 15, 25, 110))

    # Jetpack / Backpack
    draw.rectangle((ox + 20, oy + 18, ox + 44, oy + 38), fill=(51, 65, 85, 255), outline=(15, 23, 42, 255), width=2)
    # Thruster nozzles
    draw.rectangle((ox + 22, oy + 38, ox + 28, oy + 44), fill=(100, 116, 139, 255))
    draw.rectangle((ox + 36, oy + 38, ox + 42, oy + 44), fill=(100, 116, 139, 255))

    # Jet flame if boosting / jumping
    if anim in ("jump", "boost"):
        draw.polygon([(ox + 22, oy + 44), (ox + 25, oy + 58), (ox + 28, oy + 44)], fill=(249, 115, 22, 255))
        draw.polygon([(ox + 36, oy + 44), (ox + 39, oy + 58), (ox + 42, oy + 44)], fill=(249, 115, 22, 255))
        draw.polygon([(ox + 23, oy + 44), (ox + 25, oy + 52), (ox + 27, oy + 44)], fill=(254, 240, 138, 255))
        draw.polygon([(ox + 37, oy + 44), (ox + 39, oy + 52), (ox + 41, oy + 44)], fill=(254, 240, 138, 255))

    # Legs & Boots
    leg_y_l = oy + 36
    leg_y_r = oy + 36
    if anim == "run0":
        leg_y_l += 2
        leg_y_r -= 2
    elif anim == "run1":
        leg_y_l -= 4
        leg_y_r += 4
    elif anim == "run2":
        leg_y_l += 4
        leg_y_r -= 4
    elif anim == "jump":
        leg_y_l += 2
        leg_y_r += 2

    # Armored Boots
    draw.rectangle((ox + 18, leg_y_l, ox + 28, leg_y_l + 16), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255), width=2)
    draw.rectangle((ox + 36, leg_y_r, ox + 46, leg_y_r + 16), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255), width=2)
    draw.rectangle((ox + 16, leg_y_l + 12, ox + 28, leg_y_l + 18), fill=(15, 23, 42, 255)) # Boot sole
    draw.rectangle((ox + 36, leg_y_r + 12, ox + 48, leg_y_r + 18), fill=(15, 23, 42, 255))

    # Torso Armor (Cyber Suit)
    draw.rectangle((ox + 22, oy + 18, ox + 42, oy + 36), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255), width=2)
    draw.rectangle((ox + 26, oy + 22, ox + 38, oy + 32), fill=(255, 255, 255, 255), outline=(203, 213, 225, 255)) # Chest logo plate

    # Helmet
    draw.ellipse((ox + 20, oy + 4, ox + 44, oy + 22), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255), width=2)
    # Glowing Cyan Visor
    draw.rectangle((ox + 24, oy + 10, ox + 40, oy + 16), fill=(6, 182, 212, 255), outline=(207, 250, 254, 255))
    draw.line([(ox + 26, oy + 11), (ox + 34, oy + 11)], fill=(255, 255, 255, 255), width=1) # Visor shine

    # Laser Cannon / Arms
    if anim == "laser":
        draw.rectangle((ox + 42, oy + 20, ox + 58, oy + 28), fill=(100, 116, 139, 255), outline=(30, 41, 59, 255), width=2)
        # Laser muzzle flash
        draw.ellipse((ox + 54, oy + 18, ox + 62, oy + 30), fill=(250, 204, 21, 255))
        draw.ellipse((ox + 56, oy + 20, ox + 60, oy + 28), fill=(255, 255, 255, 255))
    else:
        draw.rectangle((ox + 16, oy + 22, ox + 22, oy + 34), fill=(185, 28, 28, 255), outline=(153, 27, 27, 255))
        draw.rectangle((ox + 42, oy + 22, ox + 48, oy + 34), fill=(185, 28, 28, 255), outline=(153, 27, 27, 255))


def draw_pillar(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 3D Cosmic Monolith Pillar
    draw.ellipse((ox + 8, oy + 48, ox + 56, oy + 60), fill=(10, 15, 25, 120))
    # Column
    draw.polygon([(ox + 16, oy + 10), (ox + 48, oy + 10), (ox + 52, oy + 54), (ox + 12, oy + 54)], fill=(14, 165, 233, 255), outline=(3, 105, 161, 255), width=2)
    # Bevel highlight
    draw.polygon([(ox + 18, oy + 12), (ox + 30, oy + 12), (ox + 28, oy + 52), (ox + 14, oy + 52)], fill=(125, 211, 252, 255))
    # Glowing power runes
    for y in [20, 32, 44]:
        draw.rectangle((ox + 32, oy + y, ox + 44, oy + y + 4), fill=(255, 255, 255, 255))


def draw_crystal_spikes(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    draw.ellipse((ox + 8, oy + 48, ox + 56, oy + 60), fill=(10, 15, 25, 120))
    # 3 Crystalline Spikes
    draw.polygon([(ox + 32, oy + 6), (ox + 44, oy + 52), (ox + 20, oy + 52)], fill=(236, 72, 153, 255), outline=(157, 23, 77, 255), width=2)
    draw.polygon([(ox + 32, oy + 8), (ox + 38, oy + 50), (ox + 22, oy + 50)], fill=(249, 168, 212, 255))

    draw.polygon([(ox + 14, oy + 20), (ox + 26, oy + 52), (ox + 8, oy + 52)], fill=(219, 39, 119, 255), outline=(157, 23, 77, 255), width=2)
    draw.polygon([(ox + 50, oy + 20), (ox + 56, oy + 52), (ox + 38, oy + 52)], fill=(219, 39, 119, 255), outline=(157, 23, 77, 255), width=2)


def draw_barrier(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # High-Tech Laser Plasma Gate
    draw.rectangle((ox + 6, oy + 12, ox + 16, oy + 54), fill=(71, 85, 105, 255), outline=(15, 23, 42, 255), width=2)
    draw.rectangle((ox + 48, oy + 12, ox + 58, oy + 54), fill=(71, 85, 105, 255), outline=(15, 23, 42, 255), width=2)
    # Energy Field
    draw.rectangle((ox + 16, oy + 18, ox + 48, oy + 48), fill=(239, 68, 68, 160))
    for y in [24, 32, 40]:
        draw.line([(ox + 16, oy + y), (ox + 48, oy + y)], fill=(254, 240, 138, 255), width=2)


def draw_powerup(draw: ImageDraw.ImageDraw, ox: int, oy: int, kind: str = "star") -> None:
    # Floating Sci-Fi Orb
    draw.ellipse((ox + 12, oy + 50, ox + 52, oy + 60), fill=(10, 15, 25, 90))
    draw.ellipse((ox + 10, oy + 10, ox + 54, oy + 54), fill=(30, 41, 59, 255), outline=(148, 163, 184, 255), width=2)

    if kind == "star":
        # Invincibility Star
        draw.polygon([
            (ox + 32, oy + 14), (ox + 37, oy + 26), (ox + 50, oy + 26),
            (ox + 39, oy + 34), (ox + 43, oy + 46), (ox + 32, oy + 38),
            (ox + 21, oy + 46), (ox + 25, oy + 34), (ox + 14, oy + 26),
            (ox + 27, oy + 26)
        ], fill=(250, 204, 21, 255), outline=(180, 83, 9, 255), width=2)
    elif kind == "missile":
        # Heavy Missile Warhead
        draw.polygon([(ox + 32, oy + 14), (ox + 40, oy + 30), (ox + 24, oy + 30)], fill=(239, 68, 68, 255), outline=(153, 27, 27, 255))
        draw.rectangle((ox + 26, oy + 30, ox + 38, oy + 46), fill=(226, 232, 240, 255), outline=(100, 116, 139, 255), width=2)
    elif kind == "shield":
        # Energy Shield Barrier
        draw.ellipse((ox + 16, oy + 16, ox + 48, oy + 48), fill=(6, 182, 212, 255), outline=(255, 255, 255, 255), width=2)
        draw.ellipse((ox + 22, oy + 22, ox + 42, oy + 42), fill=(165, 243, 252, 255))
    elif kind == "laser":
        # Twin Laser Bolt
        draw.line([(ox + 26, oy + 16), (ox + 26, oy + 48)], fill=(34, 211, 238, 255), width=4)
        draw.line([(ox + 38, oy + 16), (ox + 38, oy + 48)], fill=(34, 211, 238, 255), width=4)
        draw.line([(ox + 26, oy + 18), (ox + 26, oy + 46)], fill=(255, 255, 255, 255), width=2)
        draw.line([(ox + 38, oy + 18), (ox + 38, oy + 46)], fill=(255, 255, 255, 255), width=2)


def draw_boss(draw: ImageDraw.ImageDraw, ox: int, oy: int, part: str = "head") -> None:
    # 3D Cyber-Dragon Serpent Boss
    if part == "head":
        draw.ellipse((ox + 6, oy + 6, ox + 58, oy + 58), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255), width=3)
        # Horns
        draw.polygon([(ox + 12, oy + 12), (ox + 4, oy + 2), (ox + 20, oy + 6)], fill=(245, 158, 11, 255), outline=(180, 83, 9, 255))
        draw.polygon([(ox + 52, oy + 12), (ox + 60, oy + 2), (ox + 44, oy + 6)], fill=(245, 158, 11, 255), outline=(180, 83, 9, 255))
        # Glowing Fierce Eyes
        draw.ellipse((ox + 16, oy + 20, ox + 26, oy + 32), fill=(250, 204, 21, 255), outline=(15, 23, 42, 255))
        draw.ellipse((ox + 38, oy + 20, ox + 48, oy + 32), fill=(250, 204, 21, 255), outline=(15, 23, 42, 255))
        draw.ellipse((ox + 19, oy + 24, ox + 23, oy + 28), fill=(239, 68, 68, 255))
        draw.ellipse((ox + 41, oy + 24, ox + 45, oy + 28), fill=(239, 68, 68, 255))
        # Fanged Jaw
        draw.polygon([(ox + 22, oy + 42), (ox + 26, oy + 36), (ox + 30, oy + 42), (ox + 34, oy + 36), (ox + 38, oy + 42), (ox + 42, oy + 36)], fill=(255, 255, 255, 255))
    elif part == "body":
        draw.ellipse((ox + 10, oy + 10, ox + 54, oy + 54), fill=(185, 28, 28, 255), outline=(127, 29, 29, 255), width=3)
        draw.ellipse((ox + 18, oy + 18, ox + 46, oy + 46), fill=(245, 158, 11, 255), outline=(180, 83, 9, 255), width=2)
        draw.ellipse((ox + 24, oy + 24, ox + 40, oy + 40), fill=(254, 240, 138, 255))
    elif part == "tail":
        draw.ellipse((ox + 16, oy + 16, ox + 48, oy + 48), fill=(153, 27, 27, 255), outline=(127, 29, 29, 255), width=2)
        # Tail stinger blade
        draw.polygon([(ox + 32, oy + 2), (ox + 40, oy + 20), (ox + 24, oy + 20)], fill=(245, 158, 11, 255), outline=(180, 83, 9, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0: Player Commando Animations
    # -------------------------------------------------------------
    draw_commando(draw, 0 * C, 0, anim="run0")
    draw_commando(draw, 1 * C, 0, anim="run1")
    draw_commando(draw, 2 * C, 0, anim="run2")
    draw_commando(draw, 3 * C, 0, anim="jump")
    draw_commando(draw, 4 * C, 0, anim="boost")
    draw_commando(draw, 5 * C, 0, anim="laser")

    # -------------------------------------------------------------
    # Row 1: Obstacles & Hazards
    # -------------------------------------------------------------
    draw_pillar(draw, 0 * C, 1 * C)
    draw_crystal_spikes(draw, 1 * C, 1 * C)
    draw_barrier(draw, 2 * C, 1 * C)

    # -------------------------------------------------------------
    # Row 2: Collectibles & Items
    # -------------------------------------------------------------
    draw_powerup(draw, 0 * C, 2 * C, kind="star")
    draw_powerup(draw, 1 * C, 2 * C, kind="missile")
    draw_powerup(draw, 2 * C, 2 * C, kind="shield")
    draw_powerup(draw, 3 * C, 2 * C, kind="laser")

    # -------------------------------------------------------------
    # Row 3: Segmented Dragon Boss
    # -------------------------------------------------------------
    draw_boss(draw, 0 * C, 3 * C, part="head")
    draw_boss(draw, 1 * C, 3 * C, part="body")
    draw_boss(draw, 2 * C, 3 * C, part="tail")

    out_path = root / "assets" / "sprites" / "worldrunner.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "worldrunner" / "assets" / "sprites" / "worldrunner.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
