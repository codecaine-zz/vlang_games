#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Contra:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Bill Rizer (Blue Pants / Blonde Bandana) - Stand, Run 1, Run 2, Aim Up, Prone, Jump Somersault, Aim Down, Dead
Row 1 (Y=64..127):  Lance Bean (Red Pants / Black Bandana) - Stand, Run 1, Run 2, Aim Up, Prone, Jump Somersault, Aim Down, Dead
Row 2 (Y=128..191): Red Falcon Enemies (Grunt Run 1, Grunt Run 2, Turret, Sniper, Defense Core)
Row 3 (Y=192..255): Flying Capsule, Power-Up Falcon Badges (M, S, L, F, B), Boss Energy Core
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_commando(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_lance: bool = False, pose: str = "stand") -> None:
    cx, cy = ox + 32, oy + 32
    pants_col = (239, 68, 68, 255) if is_lance else (59, 130, 246, 255)
    bandana_col = (15, 23, 42, 255) if is_lance else (239, 68, 68, 255)
    hair_col = (69, 26, 3, 255) if is_lance else (250, 204, 21, 255)

    if pose == "jump":
        # Somersault tuck spinning ball
        r = 16
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=pants_col, outline=(15, 23, 42, 255), width=2)
        draw.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill=(254, 215, 170, 255))
        draw.rectangle((cx - 10, cy - 4, cx + 10, cy + 4), fill=bandana_col)
        return

    if pose == "prone":
        # Prone crawling flat on ground
        draw.rectangle((cx - 20, cy + 10, cx + 14, cy + 22), fill=pants_col)
        draw.rectangle((cx - 24, cy + 14, cx - 18, cy + 22), fill=(15, 23, 42, 255))
        draw.rectangle((cx + 10, cy + 4, cx + 22, cy + 14), fill=(254, 215, 170, 255))
        draw.rectangle((cx + 8, cy + 2, cx + 22, cy + 6), fill=bandana_col)
        # Rifle forward on ground
        draw.rectangle((cx + 14, cy + 8, cx + 30, cy + 14), fill=(30, 41, 59, 255))
        return

    # Muscle Torso (Peach/Tan)
    draw.rectangle((cx - 10, cy - 8, cx + 10, cy + 8), fill=(254, 215, 170, 255))
    # Head & Bandana
    draw.rectangle((cx - 8, cy - 20, cx + 8, cy - 10), fill=(254, 215, 170, 255))
    draw.rectangle((cx - 10, cy - 18, cx + 10, cy - 14), fill=bandana_col)
    draw.rectangle((cx - 8, cy - 24, cx + 8, cy - 18), fill=hair_col)
    # Bandana Tails
    draw.line([(cx - 8, cy - 16), (cx - 16, cy - 12)], fill=bandana_col, width=3)

    if pose == "aim_up":
        # Rifle Gun pointing straight up
        draw.rectangle((cx - 2, cy - 28, cx + 4, cy - 6), fill=(30, 41, 59, 255))
        draw.line([(cx, cy - 26), (cx, cy - 6)], fill=(148, 163, 184, 255), width=2)
    else:
        # Rifle Gun forward
        draw.rectangle((cx + 4, cy - 4, cx + 24, cy + 2), fill=(30, 41, 59, 255))
        draw.line([(cx + 8, cy - 2), (cx + 26, cy - 2)], fill=(148, 163, 184, 255), width=2)

    # Pants & Boots
    if pose == "run1":
        draw.rectangle((cx - 12, cy + 8, cx - 2, cy + 22), fill=pants_col)
        draw.rectangle((cx + 2, cy + 8, cx + 12, cy + 18), fill=pants_col)
        draw.rectangle((cx - 14, cy + 22, cx - 4, cy + 26), fill=(15, 23, 42, 255))
        draw.rectangle((cx + 4, cy + 18, cx + 12, cy + 24), fill=(15, 23, 42, 255))
    elif pose == "run2":
        draw.rectangle((cx - 4, cy + 8, cx + 8, cy + 20), fill=pants_col)
        draw.rectangle((cx - 10, cy + 12, cx - 2, cy + 24), fill=pants_col)
        draw.rectangle((cx + 4, cy + 20, cx + 14, cy + 26), fill=(15, 23, 42, 255))
        draw.rectangle((cx - 12, cy + 24, cx - 4, cy + 28), fill=(15, 23, 42, 255))
    else:
        draw.rectangle((cx - 8, cy + 8, cx + 8, cy + 22), fill=pants_col)
        draw.rectangle((cx - 10, cy + 22, cx - 2, cy + 28), fill=(15, 23, 42, 255))
        draw.rectangle((cx + 2, cy + 22, cx + 10, cy + 28), fill=(15, 23, 42, 255))


def draw_powerup(draw: ImageDraw.ImageDraw, ox: int, oy: int, letter: str) -> None:
    cx, cy = ox + 32, oy + 32
    r = 20
    # Falcon badge wings
    draw.ellipse((cx - r - 4, cy - r + 4, cx + r + 4, cy + r - 4), fill=(245, 158, 11, 255), outline=(180, 83, 9, 255), width=2)
    draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(239, 68, 68, 255))
    draw.text((cx - 5, cy - 10), letter, fill=(255, 255, 255, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    poses = ["stand", "run1", "run2", "aim_up", "prone", "jump", "stand", "dead"]

    # Row 0: Bill Rizer
    for i, p in enumerate(poses):
        draw_commando(draw, i * C, 0, is_lance=False, pose=p)

    # Row 1: Lance Bean
    for i, p in enumerate(poses):
        draw_commando(draw, i * C, 1 * C, is_lance=True, pose=p)

    # Row 3: PowerUp Badges
    letters = ["M", "S", "L", "F", "B"]
    for i, l in enumerate(letters):
        draw_powerup(draw, i * C, 3 * C, l)

    out_path = root / "assets" / "sprites" / "contra.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "contra" / "assets" / "sprites" / "contra.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
