#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Cyber Bomberman:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Bomberman P1 White/Blue (Idle, Walk 1, Walk 2, Drop Pose, Defeat, Victory)
Row 1 (Y=64..127):  Bomberman P2 Black/Red (Idle, Walk 1, Walk 2, Defeat)
Row 2 (Y=128..191): Bombs & Flames (Bomb Black, Bomb Red Pulse, Center Blast, Horizontal Flame, Vertical Flame)
Row 3 (Y=192..255): Blocks & Power-Ups (Hard Steel Pillar, Soft Brick Block, Flame Up, Bomb Up, Speed Skate)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_bomberman(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_p2: bool = False, anim: str = "idle") -> None:
    # 3D Soft Shadow
    draw.ellipse((ox + 16, oy + 50, ox + 48, oy + 60), fill=(10, 15, 25, 100))

    body_color = (239, 68, 68, 255) if is_p2 else (37, 99, 235, 255)
    head_color = (30, 41, 59, 255) if is_p2 else (248, 250, 252, 255)
    visor_color = (255, 255, 255, 255) if is_p2 else (15, 23, 42, 255)

    # 1. Jumpsuit Body
    draw.rectangle((ox + 20, oy + 28, ox + 44, oy + 48), fill=body_color, outline=(29, 78, 216, 255) if not is_p2 else (185, 28, 28, 255), width=2)
    # White Belt
    draw.rectangle((ox + 20, oy + 38, ox + 44, oy + 42), fill=(241, 245, 249, 255))
    draw.rectangle((ox + 30, oy + 38, ox + 34, oy + 42), fill=(234, 179, 8, 255))

    # 2. Large Spherical Helmet
    draw.ellipse((ox + 16, oy + 10, ox + 48, oy + 32), fill=head_color, outline=(148, 163, 184, 255), width=2)
    # Highlight
    draw.ellipse((ox + 22, oy + 12, ox + 34, oy + 18), fill=(255, 255, 255, 200))

    # Pink Antenna Sphere on top
    draw.ellipse((ox + 28, oy + 4, ox + 36, oy + 12), fill=(244, 63, 94, 255), outline=(225, 29, 72, 255))

    # Visor Oval Eyes
    draw.ellipse((ox + 24, oy + 18, ox + 28, oy + 26), fill=visor_color)
    draw.ellipse((ox + 36, oy + 18, ox + 40, oy + 26), fill=visor_color)

    # Pink Boxing Gloves
    draw.ellipse((ox + 12, oy + 32, ox + 20, oy + 40), fill=(244, 63, 94, 255))
    draw.ellipse((ox + 44, oy + 32, ox + 52, oy + 40), fill=(244, 63, 94, 255))

    # Pink Boots
    boot_off = 2 if anim == "walk2" else 0
    draw.ellipse((ox + 18, oy + 46 - boot_off, ox + 28, oy + 54 - boot_off), fill=(244, 63, 94, 255))
    draw.ellipse((ox + 36, oy + 46 + boot_off, ox + 46, oy + 54 + boot_off), fill=(244, 63, 94, 255))


def draw_bomb(draw: ImageDraw.ImageDraw, ox: int, oy: int, pulse: bool = False) -> None:
    draw.ellipse((ox + 14, oy + 48, ox + 50, oy + 58), fill=(10, 15, 25, 100))
    color = (220, 38, 38, 255) if pulse else (30, 41, 59, 255)
    outline = (185, 28, 28, 255) if pulse else (15, 23, 42, 255)

    # Sphere Body
    draw.ellipse((ox + 16, oy + 18, ox + 48, oy + 50), fill=color, outline=outline, width=2)
    # Specular White Reflection
    draw.ellipse((ox + 22, oy + 22, ox + 32, oy + 28), fill=(255, 255, 255, 220))

    # Fuse stem & Spark
    draw.rectangle((ox + 30, oy + 12, ox + 34, oy + 18), fill=(203, 213, 225, 255))
    draw.ellipse((ox + 28, oy + 6, ox + 36, oy + 14), fill=(234, 179, 8, 255), outline=(239, 68, 68, 255))
    draw.ellipse((ox + 30, oy + 8, ox + 34, oy + 12), fill=(255, 255, 255, 255))


def draw_flame(draw: ImageDraw.ImageDraw, ox: int, oy: int, flame_type: str = "center") -> None:
    cx, cy = ox + 32, oy + 32
    if flame_type == "center":
        # Plasma Fireball Nova
        draw.ellipse((cx - 24, cy - 24, cx + 24, cy + 24), fill=(239, 68, 68, 255), outline=(249, 115, 22, 255), width=2)
        draw.ellipse((cx - 16, cy - 16, cx + 16, cy + 16), fill=(249, 115, 22, 255))
        draw.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill=(254, 240, 138, 255))
        draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 255, 255, 255))
    elif flame_type == "h_stream":
        # Horizontal Flame Jet
        draw.rectangle((ox + 4, cy - 16, ox + 60, cy + 16), fill=(239, 68, 68, 255))
        draw.rectangle((ox + 4, cy - 8, ox + 60, cy + 8), fill=(249, 115, 22, 255))
        draw.rectangle((ox + 4, cy - 3, ox + 60, cy + 3), fill=(254, 240, 138, 255))
    elif flame_type == "v_stream":
        # Vertical Flame Jet
        draw.rectangle((cx - 16, oy + 4, cx + 16, oy + 60), fill=(239, 68, 68, 255))
        draw.rectangle((cx - 8, oy + 4, cx + 8, oy + 60), fill=(249, 115, 22, 255))
        draw.rectangle((cx - 3, oy + 4, cx + 3, oy + 60), fill=(254, 240, 138, 255))


def draw_powerup(draw: ImageDraw.ImageDraw, ox: int, oy: int, p_type: str = "flame") -> None:
    # Golden Badge Foundation
    draw.rectangle((ox + 10, oy + 10, ox + 54, oy + 54), fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=2)
    draw.rectangle((ox + 14, oy + 14, ox + 50, oy + 50), fill=(15, 23, 42, 255))

    cx, cy = ox + 32, oy + 32
    if p_type == "flame":
        draw.polygon([(cx, cy - 14), (cx + 12, cy + 10), (cx - 12, cy + 10)], fill=(239, 68, 68, 255))
        draw.polygon([(cx, cy - 6), (cx + 6, cy + 8), (cx - 6, cy + 8)], fill=(254, 240, 138, 255))
    elif p_type == "bomb":
        draw.ellipse((cx - 10, cy - 6, cx + 10, cy + 12), fill=(59, 130, 246, 255))
        draw.rectangle((cx - 2, cy - 10, cx + 2, cy - 6), fill=(255, 255, 255, 255))
    elif p_type == "speed":
        # Roller Skate
        draw.rectangle((cx - 10, cy - 4, cx + 10, cy + 6), fill=(34, 197, 94, 255))
        draw.ellipse((cx - 10, cy + 6, cx - 4, cy + 12), fill=(234, 179, 8, 255))
        draw.ellipse((cx + 4, cy + 6, cx + 10, cy + 12), fill=(234, 179, 8, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: P1 Bomberman
    draw_bomberman(draw, 0 * C, 0, is_p2=False, anim="idle")
    draw_bomberman(draw, 1 * C, 0, is_p2=False, anim="walk1")
    draw_bomberman(draw, 2 * C, 0, is_p2=False, anim="walk2")
    draw_bomberman(draw, 3 * C, 0, is_p2=False, anim="drop")

    # Row 1: P2 Bomberman
    draw_bomberman(draw, 0 * C, 1 * C, is_p2=True, anim="idle")
    draw_bomberman(draw, 1 * C, 1 * C, is_p2=True, anim="walk1")
    draw_bomberman(draw, 2 * C, 1 * C, is_p2=True, anim="walk2")

    # Row 2: Bombs & Flames
    draw_bomb(draw, 0 * C, 2 * C, pulse=False)
    draw_bomb(draw, 1 * C, 2 * C, pulse=True)
    draw_flame(draw, 2 * C, 2 * C, flame_type="center")
    draw_flame(draw, 3 * C, 2 * C, flame_type="h_stream")
    draw_flame(draw, 4 * C, 2 * C, flame_type="v_stream")

    # Row 3: Blocks & Powerups
    # Hard Wall
    draw.rectangle((0 * C + 4, 3 * C + 4, 0 * C + 60, 3 * C + 60), fill=(71, 85, 105, 255), outline=(30, 41, 59, 255), width=2)
    draw.line([(0 * C + 6, 3 * C + 6), (0 * C + 58, 3 * C + 6)], fill=(148, 163, 184, 255), width=2)

    # Soft Brick Block
    draw.rectangle((1 * C + 4, 3 * C + 4, 1 * C + 60, 3 * C + 60), fill=(194, 65, 12, 255), outline=(124, 45, 18, 255), width=2)
    draw.line([(1 * C + 6, 3 * C + 32), (1 * C + 58, 3 * C + 32)], fill=(254, 215, 170, 255), width=2)

    # Powerups
    draw_powerup(draw, 2 * C, 3 * C, p_type="flame")
    draw_powerup(draw, 3 * C, 3 * C, p_type="bomb")
    draw_powerup(draw, 4 * C, 3 * C, p_type="speed")

    out_path = root / "assets" / "sprites" / "bomberman.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "bomberman" / "assets" / "sprites" / "bomberman.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
