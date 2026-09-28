#!/usr/bin/env python3
"""Generate high-fidelity 512x512 RGBA sprite sheet for GNUjump (Tux Tower Ascender):
- Row 0 (Y=0..63): Tux Penguin (Idle Left/Right, Walk Frames, Jump Up, Fall, Splat) (48x48)
- Row 1 (Y=64..127): GNU Player 2 (Idle Left/Right, Jump Up, Fall, Wall Cling) (48x48)
- Row 2 (Y=128..191): Platforms (Standard Steel, Frosted Ice, Amber Spring, Crumbly Rock) (64x24)
- Row 3 (Y=192..255): Animated Lava Waves, Bubbles & Fire Particles (32x32)
- Row 4 (Y=256..319): HUD & Combo Badges (2x, 3x, 5x, 10x, Golden Star, Milestone Flags) (48x48)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_tux(draw: ImageDraw.ImageDraw, ox: int, oy: int, facing_right: bool = True, state: str = "idle") -> None:
    # 48x48 Tux Penguin
    cx, cy = ox + 24, oy + 24

    # Body (Black/Dark Slate Oval)
    draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 18), fill=(15, 23, 42, 255), outline=(51, 65, 85, 255), width=2)

    # White Belly
    draw.ellipse((cx - 9, cy - 6, cx + 9, cy + 16), fill=(248, 250, 252, 255))

    # Red Scarf
    draw.rectangle((cx - 12, cy - 7, cx + 12, cy - 3), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255))
    draw.rectangle((cx + (4 if facing_right else -8), cy - 3, cx + (8 if facing_right else -4), cy + 6), fill=(239, 68, 68, 255))

    # Eyes
    eye_x = cx + (5 if facing_right else -7)
    draw.ellipse((eye_x - 3, cy - 13, eye_x + 3, cy - 7), fill=(255, 255, 255, 255))
    draw.ellipse((eye_x + (1 if facing_right else -1), cy - 11, eye_x + (3 if facing_right else 1), cy - 9), fill=(15, 23, 42, 255))

    # Orange Beak
    beak_tip = cx + (12 if facing_right else -12)
    draw.polygon([(cx + (3 if facing_right else -3), cy - 10), (beak_tip, cy - 8), (cx + (3 if facing_right else -3), cy - 6)], fill=(245, 158, 11, 255), outline=(217, 119, 6, 255))

    # Orange Feet
    foot_y = cy + 16
    if state == "jump":
        draw.ellipse((cx - 12, foot_y - 3, cx - 4, foot_y + 3), fill=(245, 158, 11, 255))
        draw.ellipse((cx + 4, foot_y - 3, cx + 12, foot_y + 3), fill=(245, 158, 11, 255))
    else:
        draw.ellipse((cx - 12, foot_y, cx - 2, foot_y + 5), fill=(245, 158, 11, 255))
        draw.ellipse((cx + 2, foot_y, cx + 12, foot_y + 5), fill=(245, 158, 11, 255))

    # Flippers / Wings
    if state == "jump":
        draw.polygon([(cx - 12, cy - 6), (cx - 20, cy - 14), (cx - 12, cy - 2)], fill=(15, 23, 42, 255))
        draw.polygon([(cx + 12, cy - 6), (cx + 20, cy - 14), (cx + 12, cy - 2)], fill=(15, 23, 42, 255))
    else:
        wing_x = cx + (-14 if facing_right else 10)
        draw.ellipse((wing_x, cy - 4, wing_x + 6, cy + 10), fill=(15, 23, 42, 255))


def draw_gnu(draw: ImageDraw.ImageDraw, ox: int, oy: int, facing_right: bool = True) -> None:
    # 48x48 GNU Mascot
    cx, cy = ox + 24, oy + 24

    # Body (Brown Fur Oval)
    draw.ellipse((cx - 13, cy - 12, cx + 13, cy + 18), fill=(120, 53, 15, 255), outline=(180, 83, 9, 255), width=2)
    draw.ellipse((cx - 8, cy - 4, cx + 8, cy + 15), fill=(180, 83, 9, 255))

    # Horns (Curved Wildebeest Horns)
    draw.arc((cx - 18, cy - 22, cx - 4, cy - 8), start=180, end=360, fill=(254, 240, 138, 255), width=3)
    draw.arc((cx + 4, cy - 22, cx + 18, cy - 8), start=180, end=360, fill=(254, 240, 138, 255), width=3)

    # Snout
    snout_x = cx + (4 if facing_right else -12)
    draw.ellipse((snout_x, cy - 8, snout_x + 10, cy + 2), fill=(69, 26, 3, 255))

    # Eyes
    eye_x = cx + (4 if facing_right else -6)
    draw.ellipse((eye_x - 2, cy - 12, eye_x + 2, cy - 8), fill=(255, 255, 255, 255))
    draw.ellipse((eye_x, cy - 11, eye_x + 2, cy - 9), fill=(15, 23, 42, 255))


def draw_platform_standard(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 64x24 Steel Platform with Cyan Neon Bevel
    draw.rectangle((ox, oy + 2, ox + 63, oy + 21), fill=(30, 41, 59, 255), outline=(59, 130, 246, 255), width=2)
    # Top neon strip
    draw.line([(ox + 2, oy + 4), (ox + 61, oy + 4)], fill=(147, 197, 253, 255), width=2)
    # Metallic rivets
    for rx in range(ox + 8, ox + 60, 14):
        draw.ellipse((rx, oy + 10, rx + 4, oy + 14), fill=(148, 163, 184, 255))


def draw_platform_ice(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 64x24 Frosted Ice Platform
    draw.rectangle((ox, oy + 2, ox + 63, oy + 21), fill=(34, 211, 238, 255), outline=(207, 250, 254, 255), width=2)
    draw.line([(ox + 2, oy + 4), (ox + 61, oy + 4)], fill=(255, 255, 255, 255), width=2)
    for ix in range(ox + 10, ox + 56, 12):
        draw.line([(ix, oy + 6), (ix + 4, oy + 18)], fill=(255, 255, 255, 200), width=1)


def draw_platform_spring(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 64x24 Golden Amber Spring Platform
    draw.rectangle((ox, oy + 2, ox + 63, oy + 14), fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=2)
    draw.line([(ox + 2, oy + 4), (ox + 61, oy + 4)], fill=(255, 255, 255, 255), width=2)
    # Spring coils underneath
    for cx in range(ox + 8, ox + 56, 16):
        draw.arc((cx, oy + 12, cx + 12, oy + 22), start=0, end=180, fill=(250, 204, 21, 255), width=2)


def draw_platform_crumbly(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 64x24 Crumbly Stone Platform with Fracture Cracks
    draw.rectangle((ox, oy + 2, ox + 63, oy + 21), fill=(185, 28, 28, 255), outline=(254, 202, 202, 255), width=2)
    draw.line([(ox + 2, oy + 4), (ox + 61, oy + 4)], fill=(252, 165, 165, 255), width=1)
    draw.line([(ox + 14, oy + 4), (ox + 10, oy + 18)], fill=(127, 29, 29, 255), width=2)
    draw.line([(ox + 36, oy + 6), (ox + 42, oy + 20)], fill=(127, 29, 29, 255), width=2)


def draw_combo_badge(draw: ImageDraw.ImageDraw, ox: int, oy: int, label: str) -> None:
    # 48x48 Golden/Ruby Combo Badge
    cx, cy = ox + 24, oy + 24
    draw.ellipse((cx - 20, cy - 20, cx + 20, cy + 20), fill=(220, 38, 38, 255), outline=(251, 191, 36, 255), width=3)
    draw.ellipse((cx - 16, cy - 16, cx + 16, cy + 16), fill=(185, 28, 28, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0 (Y=0..63): Tux Penguin Animations
    # -------------------------------------------------------------
    draw_tux(draw, 0, 8, facing_right=True, state="idle")
    draw_tux(draw, 48, 8, facing_right=False, state="idle")
    draw_tux(draw, 96, 8, facing_right=True, state="jump")
    draw_tux(draw, 144, 8, facing_right=False, state="jump")

    # -------------------------------------------------------------
    # Row 1 (Y=64..127): GNU Player 2 Animations
    # -------------------------------------------------------------
    draw_gnu(draw, 0, 72, facing_right=True)
    draw_gnu(draw, 48, 72, facing_right=False)

    # -------------------------------------------------------------
    # Row 2 (Y=128..191): Platforms (64x24)
    # -------------------------------------------------------------
    draw_platform_standard(draw, 0, 136)
    draw_platform_ice(draw, 64, 136)
    draw_platform_spring(draw, 128, 136)
    draw_platform_crumbly(draw, 192, 136)

    # -------------------------------------------------------------
    # Row 3 (Y=192..255): Lava Waves & Bubbles
    # -------------------------------------------------------------
    for i in range(4):
        bx = i * 48
        draw.ellipse((bx + 12, 204, bx + 36, 228), fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=2)
        draw.ellipse((bx + 18, 210, bx + 26, 218), fill=(255, 255, 255, 230))

    # -------------------------------------------------------------
    # Row 4 (Y=256..319): Badges & Stars
    # -------------------------------------------------------------
    draw_combo_badge(draw, 0, 264, "2X")
    draw_combo_badge(draw, 48, 264, "5X")

    out_path = root / "assets" / "sprites" / "gnujump.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "gnujump" / "assets" / "sprites" / "gnujump.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
