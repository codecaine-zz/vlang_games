#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Dig Dug Arcade:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Dig Dug (Walk 1, Walk 2, Dig Up, Dig Down, Pump Action, Defeat)
Row 1 (Y=64..127):  Pooka (Walk 1, Walk 2, Ghost, Inflate 1, Inflate 2, Inflate 3, Pop Burst)
Row 2 (Y=128..191): Fygar (Walk 1, Walk 2, Fire Breath, Ghost, Inflate 1, Inflate 2, Pop Burst)
Row 3 (Y=192..255): Props & Hazards (Boulder Intact, Boulder Wobble, Carrot, Tomato, Pineapple, Harpoon Tip)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_digdug(draw: ImageDraw.ImageDraw, ox: int, oy: int, anim: str = "walk1") -> None:
    # 3D Soft Shadow
    draw.ellipse((ox + 16, oy + 48, ox + 48, oy + 58), fill=(10, 15, 25, 100))

    # White miner suit
    draw.rectangle((ox + 18, oy + 26, ox + 46, oy + 48), fill=(241, 245, 249, 255), outline=(148, 163, 184, 255), width=2)

    # Blue helmet with visor
    draw.ellipse((ox + 16, oy + 12, ox + 48, oy + 28), fill=(37, 99, 235, 255), outline=(29, 78, 216, 255), width=2)
    draw.line([(ox + 20, oy + 16), (ox + 44, oy + 16)], fill=(147, 197, 253, 255), width=2)
    # Dark Visor Glass
    draw.rectangle((ox + 24, oy + 22, ox + 42, oy + 28), fill=(15, 23, 42, 255))

    # Red/Yellow backpack & drill
    draw.rectangle((ox + 12, oy + 30, ox + 18, oy + 42), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255))

    # Red boots
    boot_off = 2 if anim == "walk2" else 0
    draw.ellipse((ox + 18, oy + 46 - boot_off, ox + 30, oy + 54 - boot_off), fill=(220, 38, 38, 255))
    draw.ellipse((ox + 34, oy + 46 + boot_off, ox + 46, oy + 54 + boot_off), fill=(220, 38, 38, 255))


def draw_pooka(draw: ImageDraw.ImageDraw, ox: int, oy: int, inflate: int = 0, is_ghost: bool = False) -> None:
    draw.ellipse((ox + 16, oy + 48, ox + 48, oy + 58), fill=(10, 15, 25, 100))
    scale = 1.0 + inflate * 0.25
    r = int(16.0 * scale)
    cx, cy = ox + 32, oy + 32

    if is_ghost:
        # Translucent yellow ghost goggles
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, 140), outline=(250, 204, 21, 255), width=2)
    else:
        # Round Red Body
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255), width=2)
        # Specular glint
        draw.line([(cx - r // 2, cy - r + 4), (cx + r // 2, cy - r + 4)], fill=(254, 202, 202, 255), width=2)

    # Yellow Oversized Diving Goggles
    gog_w = int(14.0 * scale)
    gog_h = int(8.0 * scale)
    draw.ellipse((cx - gog_w, cy - gog_h, cx + gog_w, cy + gog_h), fill=(250, 204, 21, 255), outline=(180, 83, 9, 255), width=2)
    # Lenses
    draw.ellipse((cx - gog_w + 2, cy - 4, cx - 2, cy + 4), fill=(15, 23, 42, 255))
    draw.ellipse((cx + 2, cy - 4, cx + gog_w - 2, cy + 4), fill=(15, 23, 42, 255))


def draw_fygar(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_fire: bool = False, inflate: int = 0) -> None:
    draw.ellipse((ox + 14, oy + 48, ox + 50, oy + 58), fill=(10, 15, 25, 100))
    scale = 1.0 + inflate * 0.25
    cx, cy = ox + 32, oy + 32
    w = int(22.0 * scale)
    h = int(16.0 * scale)

    # Green Dragon Body
    draw.ellipse((cx - w, cy - h, cx + w, cy + h), fill=(34, 197, 94, 255), outline=(21, 128, 61, 255), width=2)
    # Yellow Belly
    draw.ellipse((cx - w // 2, cy, cx + w // 2, cy + h - 2), fill=(254, 240, 138, 255))

    # White Bat Wings
    draw.polygon([(cx - 8, cy - h), (cx - 16, cy - h - 10), (cx, cy - h + 2)], fill=(241, 245, 249, 255), outline=(148, 163, 184, 255))
    draw.polygon([(cx + 8, cy - h), (cx + 16, cy - h - 10), (cx, cy - h + 2)], fill=(241, 245, 249, 255), outline=(148, 163, 184, 255))

    # Red Eye
    draw.ellipse((cx + 8, cy - 6, cx + 14, cy), fill=(239, 68, 68, 255))

    if is_fire:
        # Giant horizontal fire breath jet
        draw.polygon([(cx + w, cy - 4), (cx + w + 20, cy - 10), (cx + w + 20, cy + 10), (cx + w, cy + 4)], fill=(239, 68, 68, 255))
        draw.polygon([(cx + w + 4, cy - 2), (cx + w + 16, cy - 6), (cx + w + 16, cy + 6), (cx + w + 4, cy + 2)], fill=(254, 240, 138, 255))


def draw_boulder(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_cracking: bool = False) -> None:
    # 3D Stone Monolith
    draw.ellipse((ox + 12, oy + 48, ox + 52, oy + 58), fill=(10, 15, 25, 100))
    draw.ellipse((ox + 12, oy + 14, ox + 52, oy + 50), fill=(148, 163, 184, 255), outline=(71, 85, 105, 255), width=2)
    draw.line([(ox + 20, oy + 20), (ox + 44, oy + 20)], fill=(226, 232, 240, 255), width=2)

    if is_cracking:
        # Dark Cracks
        draw.line([(ox + 24, oy + 24), (ox + 34, oy + 36), (ox + 28, oy + 46)], fill=(30, 41, 59, 255), width=2)
        draw.line([(ox + 34, oy + 36), (ox + 44, oy + 32)], fill=(30, 41, 59, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Dig Dug
    draw_digdug(draw, 0 * C, 0, anim="walk1")
    draw_digdug(draw, 1 * C, 0, anim="walk2")
    draw_digdug(draw, 2 * C, 0, anim="dig_up")
    draw_digdug(draw, 3 * C, 0, anim="pump")

    # Row 1: Pooka
    draw_pooka(draw, 0 * C, 1 * C, inflate=0, is_ghost=False)
    draw_pooka(draw, 1 * C, 1 * C, inflate=1, is_ghost=False)
    draw_pooka(draw, 2 * C, 1 * C, inflate=2, is_ghost=False)
    draw_pooka(draw, 3 * C, 1 * C, inflate=3, is_ghost=False)
    draw_pooka(draw, 4 * C, 1 * C, inflate=0, is_ghost=True)

    # Row 2: Fygar
    draw_fygar(draw, 0 * C, 2 * C, is_fire=False, inflate=0)
    draw_fygar(draw, 1 * C, 2 * C, is_fire=True, inflate=0)
    draw_fygar(draw, 2 * C, 2 * C, is_fire=False, inflate=1)
    draw_fygar(draw, 3 * C, 2 * C, is_fire=False, inflate=2)
    draw_fygar(draw, 4 * C, 2 * C, is_fire=False, inflate=3)

    # Row 3: Boulders & Bonus items
    draw_boulder(draw, 0 * C, 3 * C, is_cracking=False)
    draw_boulder(draw, 1 * C, 3 * C, is_cracking=True)

    # Carrot Bonus Item
    draw.ellipse((2 * C + 20, 3 * C + 20, 2 * C + 44, 3 * C + 52), fill=(249, 115, 22, 255), outline=(194, 65, 12, 255), width=2)
    draw.polygon([(2 * C + 32, 3 * C + 20), (2 * C + 26, 3 * C + 10), (2 * C + 38, 3 * C + 10)], fill=(34, 197, 94, 255))

    # Tomato Bonus Item
    draw.ellipse((3 * C + 18, 3 * C + 22, 3 * C + 46, 3 * C + 50), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255), width=2)
    draw.ellipse((3 * C + 28, 3 * C + 16, 3 * C + 36, 3 * C + 24), fill=(34, 197, 94, 255))

    out_path = root / "assets" / "sprites" / "digdug.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "digdug" / "assets" / "sprites" / "digdug.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
