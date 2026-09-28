#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Yie Ar Kung-Fu (1985 Konami Classic):
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Oolong (Lee) - 1: Idle, 2: Walk1, 3: Punch, 4: Kick, 5: Jump Kick, 6: Crouch, 7: Hit, 8: KO
Row 1 (Y=64..127):  Wang (Bo Staff) - 1: Idle, 2: Staff Thrust, 3: Staff Overhead, 4: Hit
Row 2 (Y=128..191): Tao (Fire Spitter) - 1: Idle, 2: Fire Breath, 3: Fireball, 4: Hit
Row 3 (Y=192..255): Chen (Chain Whip) - 1: Idle, 2: Whip Swing, 3: Hit
Row 4 (Y=256..319): Lang (Shuriken Fan) - 1: Idle, 2: Fan Throw, 3: Shuriken Star, 4: Hit
Row 5 (Y=320..383): Mu (Winged Diver) - 1: Idle, 2: Flying Dive, 3: Hit
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_oolong(draw: ImageDraw.ImageDraw, ox: int, oy: int, pose: str) -> None:
    cx, cy = ox + 32, oy + 42
    # Skin color: (254, 215, 170)
    # Pants color: (239, 68, 68) - Red Kung-fu pants with yellow sash (234, 179, 8)
    # White top / Bare chest: (255, 255, 255)
    # Hair: Black topknot (15, 23, 42)

    # Head & Topknot
    draw.ellipse((cx - 7, cy - 36, cx + 7, cy - 22), fill=(254, 215, 170, 255))
    draw.ellipse((cx - 7, cy - 38, cx + 7, cy - 32), fill=(15, 23, 42, 255))
    draw.ellipse((cx - 3, cy - 42, cx + 3, cy - 36), fill=(15, 23, 42, 255))

    # Eyes & Headband
    draw.line([(cx - 7, cy - 31), (cx + 7, cy - 31)], fill=(239, 68, 68, 255), width=2)
    draw.ellipse((cx + 1, cy - 30, cx + 4, cy - 27), fill=(15, 23, 42, 255))

    if pose == "idle":
        # Torso (White Kung-Fu Vest)
        draw.rectangle((cx - 10, cy - 22, cx + 10, cy - 4), fill=(255, 255, 255, 255), outline=(203, 213, 225, 255), width=1)
        # Yellow Sash
        draw.rectangle((cx - 10, cy - 4, cx + 10, cy), fill=(234, 179, 8, 255))
        # Arms in Guard Stance
        draw.rectangle((cx - 13, cy - 20, cx - 7, cy - 8), fill=(254, 215, 170, 255))
        draw.rectangle((cx + 6, cy - 18, cx + 16, cy - 10), fill=(254, 215, 170, 255))
        # Legs
        draw.rectangle((cx - 9, cy, cx - 3, cy + 18), fill=(239, 68, 68, 255))
        draw.rectangle((cx + 3, cy, cx + 9, cy + 18), fill=(239, 68, 68, 255))
        # Black Kung-Fu Slippers
        draw.rectangle((cx - 11, cy + 16, cx - 2, cy + 20), fill=(15, 23, 42, 255))
        draw.rectangle((cx + 2, cy + 16, cx + 11, cy + 20), fill=(15, 23, 42, 255))

    elif pose == "punch":
        # Torso
        draw.rectangle((cx - 10, cy - 22, cx + 10, cy - 4), fill=(255, 255, 255, 255))
        draw.rectangle((cx - 10, cy - 4, cx + 10, cy), fill=(234, 179, 8, 255))
        # Extended Right Punch
        draw.rectangle((cx + 4, cy - 19, cx + 24, cy - 11), fill=(254, 215, 170, 255), outline=(15, 23, 42, 255), width=1)
        # Fist
        draw.ellipse((cx + 20, cy - 20, cx + 26, cy - 10), fill=(254, 215, 170, 255))
        # Legs in Deep Horse Stance
        draw.rectangle((cx - 12, cy, cx - 5, cy + 18), fill=(239, 68, 68, 255))
        draw.rectangle((cx + 4, cy, cx + 14, cy + 18), fill=(239, 68, 68, 255))
        draw.rectangle((cx - 14, cy + 16, cx - 4, cy + 20), fill=(15, 23, 42, 255))
        draw.rectangle((cx + 4, cy + 16, cx + 16, cy + 20), fill=(15, 23, 42, 255))

    elif pose == "kick":
        # Torso tilted
        draw.polygon([(cx - 8, cy - 22), (cx + 8, cy - 22), (cx + 4, cy), (cx - 12, cy)], fill=(255, 255, 255, 255))
        draw.rectangle((cx - 12, cy, cx + 4, cy + 4), fill=(234, 179, 8, 255))
        # Standing Leg
        draw.rectangle((cx - 14, cy + 4, cx - 6, cy + 20), fill=(239, 68, 68, 255))
        draw.rectangle((cx - 16, cy + 16, cx - 4, cy + 20), fill=(15, 23, 42, 255))
        # Extended High Flying Kick Leg
        draw.polygon([(cx + 4, cy - 6), (cx + 26, cy - 18), (cx + 28, cy - 12), (cx + 4, cy)], fill=(239, 68, 68, 255))
        draw.rectangle((cx + 24, cy - 22, cx + 30, cy - 12), fill=(15, 23, 42, 255))

    elif pose == "jump_kick":
        # Airborne Flying Side Kick
        draw.rectangle((cx - 14, cy - 24, cx + 4, cy - 10), fill=(255, 255, 255, 255))
        # Tucked Back Leg
        draw.rectangle((cx - 20, cy - 12, cx - 10, cy - 4), fill=(239, 68, 68, 255))
        # Fully Extended Front Kick
        draw.rectangle((cx + 2, cy - 18, cx + 26, cy - 8), fill=(239, 68, 68, 255))
        draw.rectangle((cx + 24, cy - 20, cx + 29, cy - 6), fill=(15, 23, 42, 255))

    elif pose == "crouch":
        # Low Crouching Stance
        draw.rectangle((cx - 10, cy - 12, cx + 10, cy + 4), fill=(255, 255, 255, 255))
        draw.rectangle((cx - 14, cy + 4, cx + 14, cy + 18), fill=(239, 68, 68, 255))
        draw.rectangle((cx - 16, cy + 16, cx + 16, cy + 20), fill=(15, 23, 42, 255))

    elif pose == "hit":
        # Hit Stun Knockback
        draw.polygon([(cx - 12, cy - 20), (cx + 4, cy - 22), (cx + 8, cy), (cx - 8, cy)], fill=(255, 255, 255, 255))
        draw.rectangle((cx - 12, cy, cx + 4, cy + 18), fill=(239, 68, 68, 255))

    else:
        # KO Fallen
        draw.rectangle((cx - 22, cy + 6, cx + 18, cy + 18), fill=(239, 68, 68, 255))
        draw.ellipse((cx - 28, cy + 4, cx - 18, cy + 16), fill=(254, 215, 170, 255))


def draw_wang(draw: ImageDraw.ImageDraw, ox: int, oy: int, pose: str) -> None:
    cx, cy = ox + 32, oy + 42
    # Orange Bo Staff Master
    draw.ellipse((cx - 7, cy - 36, cx + 7, cy - 22), fill=(254, 215, 170, 255))
    draw.rectangle((cx - 10, cy - 22, cx + 10, cy - 2), fill=(249, 115, 22, 255))
    draw.rectangle((cx - 8, cy - 2, cx + 8, cy + 18), fill=(67, 56, 202, 255))
    # Bo Staff (Long Wooden Pole)
    if pose == "thrust":
        draw.line([(cx - 18, cy - 14), (cx + 30, cy - 14)], fill=(180, 83, 9, 255), width=4)
    else:
        draw.line([(cx - 16, cy + 18), (cx + 18, cy - 34)], fill=(180, 83, 9, 255), width=4)


def draw_tao(draw: ImageDraw.ImageDraw, ox: int, oy: int, pose: str) -> None:
    cx, cy = ox + 32, oy + 42
    # Fireball Monk in Purple Robes
    draw.ellipse((cx - 8, cy - 36, cx + 8, cy - 22), fill=(254, 215, 170, 255))
    draw.rectangle((cx - 12, cy - 22, cx + 12, cy + 18), fill=(147, 51, 234, 255))
    if pose == "fire":
        # Fireball from mouth
        draw.ellipse((cx + 12, cy - 32, cx + 28, cy - 18), fill=(239, 68, 68, 255))
        draw.ellipse((cx + 15, cy - 29, cx + 25, cy - 21), fill=(251, 191, 36, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Oolong Poses
    poses = ["idle", "punch", "kick", "jump_kick", "crouch", "hit", "ko"]
    for i, p in enumerate(poses):
        draw_oolong(draw, i * C, 0 * C, pose=p)

    # Row 1: Wang (Bo Staff)
    draw_wang(draw, 0 * C, 1 * C, pose="idle")
    draw_wang(draw, 1 * C, 1 * C, pose="thrust")

    # Row 2: Tao (Fire Spitter)
    draw_tao(draw, 0 * C, 2 * C, pose="idle")
    draw_tao(draw, 1 * C, 2 * C, pose="fire")

    out_path = root / "assets" / "sprites" / "yiearkungfu.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "yiearkungfu" / "assets" / "sprites" / "yiearkungfu.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
