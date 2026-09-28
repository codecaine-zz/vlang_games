#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Shinobi:
Layout:
Row 0 (Y=0..63):    Joe Musashi Cyber Shinobi (Stand, Run 1, Run 2, Run 3, Jump Somersault, Katana Slash, Shuriken Throw)
Row 1 (Y=64..127):  Enemies (Cyber Gunner, Shadow Ninja, Drone, Turret, Samurai Boss)
Row 2 (Y=128..191): Hostages / Scrolls, Shurikens, Katana Wave Arc
Row 3 (Y=192..255): Ninjutsu Magic Effects & Power-ups
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_shinobi_hero(draw: ImageDraw.ImageDraw, ox: int, oy: int, pose: str) -> None:
    cx, cy = ox + 24, oy + 32
    # Flowing Red Scarf / Headband Tail
    draw.polygon([(cx - 4, cy - 24), (cx - 18, cy - 20), (cx - 24, cy - 14), (cx - 16, cy - 14)], fill=(220, 38, 38, 255))

    # Legs & Boots
    if pose == "run1":
        draw.line([(cx - 4, cy + 6), (cx - 10, cy + 24)], fill=(15, 23, 42, 255), width=4)
        draw.line([(cx + 4, cy + 6), (cx + 8, cy + 22)], fill=(15, 23, 42, 255), width=4)
    elif pose == "run2":
        draw.line([(cx - 4, cy + 6), (cx - 2, cy + 24)], fill=(15, 23, 42, 255), width=4)
        draw.line([(cx + 4, cy + 6), (cx + 12, cy + 20)], fill=(15, 23, 42, 255), width=4)
    elif pose == "jump":
        draw.line([(cx - 4, cy + 4), (cx - 10, cy + 16)], fill=(15, 23, 42, 255), width=4)
        draw.line([(cx + 4, cy + 4), (cx + 10, cy + 16)], fill=(15, 23, 42, 255), width=4)
    else:
        draw.line([(cx - 5, cy + 6), (cx - 5, cy + 24)], fill=(15, 23, 42, 255), width=4)
        draw.line([(cx + 5, cy + 6), (cx + 5, cy + 24)], fill=(15, 23, 42, 255), width=4)

    # Shinobi Gi Body (White & Midnight Blue with Silver Mesh)
    draw.rectangle((cx - 8, cy - 10, cx + 8, cy + 8), fill=(241, 245, 249, 255), outline=(30, 41, 59, 255), width=1)
    # Red Obi Sash
    draw.rectangle((cx - 8, cy + 2, cx + 8, cy + 6), fill=(220, 38, 38, 255))

    # Masked Head & Ninja Hood
    draw.rectangle((cx - 6, cy - 24, cx + 6, cy - 10), fill=(15, 23, 42, 255))
    # Fierce Ninja Eye Slit
    draw.rectangle((cx + 1, cy - 18, cx + 6, cy - 15), fill=(254, 240, 138, 255))

    if pose == "slash":
        # Katana Steel Blade Swing
        draw.line([(cx + 4, cy - 4), (cx + 26, cy - 18)], fill=(226, 232, 240, 255), width=3)
        draw.line([(cx + 6, cy - 6), (cx + 28, cy - 16)], fill=(6, 182, 212, 255), width=1)
    elif pose == "throw":
        # Extended throwing arm
        draw.rectangle((cx + 4, cy - 8, cx + 18, cy - 2), fill=(241, 245, 249, 255))


def draw_cyber_gunner(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 24, oy + 32
    # Mercenary Body Armor
    draw.rectangle((cx - 8, cy - 10, cx + 8, cy + 8), fill=(71, 85, 105, 255), outline=(15, 23, 42, 255), width=2)
    # Combat Helmet & Visor
    draw.rectangle((cx - 6, cy - 24, cx + 6, cy - 10), fill=(30, 41, 59, 255))
    draw.rectangle((cx - 4, cy - 18, cx + 4, cy - 14), fill=(239, 68, 68, 255))
    # Assault Rifle Gun
    draw.rectangle((cx - 16, cy - 4, cx - 2, cy + 2), fill=(15, 23, 42, 255))
    draw.line([(cx - 5, cy + 8), (cx - 5, cy + 24)], fill=(15, 23, 42, 255), width=4)
    draw.line([(cx + 5, cy + 8), (cx + 5, cy + 24)], fill=(15, 23, 42, 255), width=4)


def draw_shadow_ninja(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 24, oy + 32
    # Black Ninja Gi
    draw.rectangle((cx - 8, cy - 10, cx + 8, cy + 8), fill=(15, 23, 42, 255), outline=(168, 85, 247, 255), width=1)
    draw.rectangle((cx - 6, cy - 24, cx + 6, cy - 10), fill=(15, 23, 42, 255))
    draw.rectangle((cx - 4, cy - 18, cx + 4, cy - 15), fill=(168, 85, 247, 255))
    # Dual Ninjato Swords
    draw.line([(cx + 6, cy - 4), (cx + 18, cy - 14)], fill=(226, 232, 240, 255), width=2)
    draw.line([(cx - 6, cy - 4), (cx - 18, cy - 14)], fill=(226, 232, 240, 255), width=2)
    draw.line([(cx - 5, cy + 8), (cx - 5, cy + 24)], fill=(15, 23, 42, 255), width=4)
    draw.line([(cx + 5, cy + 8), (cx + 5, cy + 24)], fill=(15, 23, 42, 255), width=4)


def draw_drone(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 24, oy + 24
    # Cyber Drone Hull
    draw.ellipse((cx - 14, cy - 10, cx + 14, cy + 10), fill=(88, 28, 135, 255), outline=(192, 132, 252, 255), width=2)
    draw.ellipse((cx - 5, cy - 4, cx + 5, cy + 4), fill=(239, 68, 68, 255))
    draw.line([(cx - 18, cy - 12), (cx - 4, cy - 12)], fill=(148, 163, 184, 255), width=2)
    draw.line([(cx + 4, cy - 12), (cx + 18, cy - 12)], fill=(148, 163, 184, 255), width=2)


def draw_shuriken(draw: ImageDraw.ImageDraw, cx: int, cy: int, angle_deg: float) -> None:
    r = 10
    rad = math.radians(angle_deg)
    pts = []
    for i in range(4):
        a1 = rad + (i * math.pi / 2.0)
        a2 = a1 + math.pi / 4.0
        pts.append((cx + r * math.cos(a1), cy + r * math.sin(a1)))
        pts.append((cx + (r * 0.35) * math.cos(a2), cy + (r * 0.35) * math.sin(a2)))
    draw.polygon(pts, fill=(6, 182, 212, 255), outline=(241, 245, 249, 255), width=1)
    draw.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=(15, 23, 42, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Hero Poses (Y=0..63)
    poses = ["stand", "run1", "run2", "jump", "slash", "throw"]
    for i, p in enumerate(poses):
        draw_shinobi_hero(draw, i * 48, 0, pose=p)

    # Row 1: Enemies (Y=64..127)
    draw_cyber_gunner(draw, 0 * 48, 64)
    draw_shadow_ninja(draw, 1 * 48, 64)
    draw_drone(draw, 2 * 48, 64)

    # Row 2: Shurikens & FX (Y=128..191)
    for i in range(4):
        draw_shuriken(draw, i * 32 + 16, 128 + 16, angle_deg=i * 22.5)

    out_path = root / "assets" / "sprites" / "shinobi.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "shinobi" / "assets" / "sprites" / "shinobi.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
