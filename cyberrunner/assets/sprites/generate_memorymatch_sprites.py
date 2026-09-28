#!/usr/bin/env python3
"""Generate high-fidelity 512x512 RGBA sprite sheet for Memory Match:
Contains 18 beautifully crafted 64x64 card icons + decorative card textures:
- Row 0 (Y=0..63):   Gem, Crown, Star, Key, Potion, Fire, Lightning, Heart
- Row 1 (Y=64..127):  Crescent, Atom, Rocket, Shield, Diamond, Coin, Music, Clover
- Row 2 (Y=128..191): Bell, Skull, Card Back Royal, Card Back Emerald, Card Front, Star Gold, Sparkle
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
CELL = 64


def draw_gem(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Faceted Cyan / Aquamarine Gem
    pts_outer = [
        (cx - 18, cy - 8),
        (cx - 8, cy - 20),
        (cx + 8, cy - 20),
        (cx + 18, cy - 8),
        (cx, cy + 20),
    ]
    draw.polygon(pts_outer, fill=(6, 182, 212, 255), outline=(165, 243, 252, 255), width=2)
    # Inner facets
    draw.polygon([(cx - 8, cy - 20), (cx + 8, cy - 20), (cx + 10, cy - 8), (cx - 10, cy - 8)], fill=(103, 232, 249, 255))
    draw.polygon([(cx - 18, cy - 8), (cx - 10, cy - 8), (cx, cy + 20)], fill=(8, 145, 178, 255))
    draw.polygon([(cx + 18, cy - 8), (cx + 10, cy - 8), (cx, cy + 20)], fill=(14, 116, 144, 255))
    draw.polygon([(cx - 10, cy - 8), (cx + 10, cy - 8), (cx, cy + 20)], fill=(34, 211, 238, 255))
    # Sparkle glint
    draw.ellipse((cx - 6, cy - 16, cx - 2, cy - 12), fill=(255, 255, 255, 240))


def draw_crown(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Regal Gold Crown
    pts = [
        (cx - 20, cy + 14),
        (cx + 20, cy + 14),
        (cx + 20, cy - 10),
        (cx + 10, cy + 2),
        (cx, cy - 18),
        (cx - 10, cy + 2),
        (cx - 20, cy - 10),
    ]
    draw.polygon(pts, fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=2)
    # Headband
    draw.rectangle((cx - 20, cy + 8, cx + 20, cy + 14), fill=(217, 119, 6, 255), outline=(254, 240, 138, 255))
    # Jewels
    draw.ellipse((cx - 22, cy - 12, cx - 18, cy - 8), fill=(239, 68, 68, 255))
    draw.ellipse((cx - 2, cy - 20, cx + 2, cy - 16), fill=(59, 130, 246, 255))
    draw.ellipse((cx + 18, cy - 12, cx + 22, cy - 8), fill=(239, 68, 68, 255))
    draw.ellipse((cx - 10, cy + 9, cx - 6, cy + 13), fill=(16, 185, 129, 255))
    draw.ellipse((cx - 2, cy + 9, cx + 2, cy + 13), fill=(239, 68, 68, 255))
    draw.ellipse((cx + 6, cy + 9, cx + 10, cy + 13), fill=(59, 130, 246, 255))


def draw_star(draw: ImageDraw.ImageDraw, ox: int, oy: int, col=(250, 204, 21), outline_col=(254, 240, 138)) -> None:
    cx, cy = ox + 32, oy + 32
    pts = []
    for i in range(10):
        ang = i * math.pi / 5 - math.pi / 2
        r = 20 if i % 2 == 0 else 9
        pts.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
    draw.polygon(pts, fill=(*col, 255), outline=(*outline_col, 255), width=2)
    # Center highlight
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 255, 255, 180))


def draw_key(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Antique Gold Skeleton Key
    draw.ellipse((cx - 18, cy - 18, cx - 2, cy - 2), fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=2)
    draw.ellipse((cx - 14, cy - 14, cx - 6, cy - 6), fill=(0, 0, 0, 0), outline=(254, 240, 138, 255), width=2)
    # Shaft
    draw.line([(cx - 4, cy - 4), (cx + 18, cy + 18)], fill=(245, 158, 11, 255), width=4)
    draw.line([(cx - 4, cy - 4), (cx + 18, cy + 18)], fill=(254, 240, 138, 255), width=2)
    # Teeth
    draw.line([(cx + 10, cy + 10), (cx + 16, cy + 4)], fill=(245, 158, 11, 255), width=3)
    draw.line([(cx + 16, cy + 16), (cx + 22, cy + 10)], fill=(245, 158, 11, 255), width=3)


def draw_potion(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Flask Neck & Cork
    draw.rectangle((cx - 4, cy - 20, cx + 4, cy - 14), fill=(180, 83, 9, 255))
    draw.rectangle((cx - 6, cy - 14, cx + 6, cy - 6), fill=(203, 213, 225, 200), outline=(255, 255, 255, 255))
    # Round Flask Body
    draw.ellipse((cx - 18, cy - 8, cx + 18, cy + 20), fill=(225, 29, 72, 255), outline=(255, 255, 255, 255), width=2)
    # Bubbles
    draw.ellipse((cx - 8, cy + 2, cx - 4, cy + 6), fill=(255, 255, 255, 200))
    draw.ellipse((cx + 4, cy + 8, cx + 8, cy + 12), fill=(255, 255, 255, 200))
    draw.ellipse((cx - 2, cy + 10, cx + 2, cy + 14), fill=(255, 255, 255, 200))


def draw_fire(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Outer Flame (Crimson Orange)
    flame_outer = [
        (cx, cy - 22),
        (cx + 8, cy - 10),
        (cx + 18, cy - 4),
        (cx + 18, cy + 12),
        (cx + 10, cy + 20),
        (cx - 10, cy + 20),
        (cx - 18, cy + 12),
        (cx - 18, cy - 2),
        (cx - 8, cy - 12),
    ]
    draw.polygon(flame_outer, fill=(234, 88, 12, 255), outline=(251, 146, 60, 255), width=2)
    # Inner Flame (Gold)
    flame_inner = [
        (cx, cy - 10),
        (cx + 6, cy - 2),
        (cx + 10, cy + 12),
        (cx - 10, cy + 12),
        (cx - 6, cy - 2),
    ]
    draw.polygon(flame_inner, fill=(250, 204, 21, 255))
    # Core (White)
    draw.ellipse((cx - 4, cy + 2, cx + 4, cy + 10), fill=(255, 255, 255, 240))


def draw_lightning(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    pts = [
        (cx + 4, cy - 22),
        (cx - 14, cy - 2),
        (cx - 2, cy - 2),
        (cx - 6, cy + 22),
        (cx + 14, cy + 2),
        (cx + 2, cy + 2),
    ]
    draw.polygon(pts, fill=(250, 204, 21, 255), outline=(254, 240, 138, 255), width=2)
    draw.line([(cx + 2, cy - 18), (cx - 8, cy - 2)], fill=(255, 255, 255, 220), width=2)


def draw_heart(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Left lobe & Right lobe
    draw.ellipse((cx - 18, cy - 16, cx + 2, cy + 4), fill=(225, 29, 72, 255))
    draw.ellipse((cx - 2, cy - 16, cx + 18, cy + 4), fill=(225, 29, 72, 255))
    # Bottom wedge
    draw.polygon([(cx - 18, cy - 4), (cx + 18, cy - 4), (cx, cy + 20)], fill=(225, 29, 72, 255))
    # Highlight
    draw.ellipse((cx - 14, cy - 12, cx - 6, cy - 4), fill=(251, 113, 133, 255))
    draw.ellipse((cx - 12, cy - 10, cx - 8, cy - 6), fill=(255, 255, 255, 220))


def draw_crescent(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    draw.ellipse((cx - 18, cy - 18, cx + 18, cy + 18), fill=(168, 85, 247, 255), outline=(216, 180, 254, 255), width=2)
    # Mask out cutout to create crescent
    draw.ellipse((cx - 10, cy - 22, cx + 22, cy + 14), fill=(0, 0, 0, 0))


def draw_atom(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Orbit rings
    draw.ellipse((cx - 20, cy - 10, cx + 20, cy + 10), outline=(34, 211, 238, 220), width=2)
    draw.ellipse((cx - 10, cy - 20, cx + 10, cy + 20), outline=(168, 85, 247, 220), width=2)
    # Nucleus core
    draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=2)
    # Electrons
    draw.ellipse((cx + 16, cy - 2, cx + 20, cy + 2), fill=(34, 211, 238, 255))
    draw.ellipse((cx - 2, cy + 16, cx + 2, cy + 20), fill=(168, 85, 247, 255))


def draw_rocket(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Rocket Fuselage
    draw.ellipse((cx - 8, cy - 20, cx + 8, cy + 10), fill=(241, 245, 249, 255), outline=(225, 29, 72, 255), width=2)
    # Fins
    draw.polygon([(cx - 8, cy + 2), (cx - 16, cy + 14), (cx - 8, cy + 10)], fill=(225, 29, 72, 255))
    draw.polygon([(cx + 8, cy + 2), (cx + 16, cy + 14), (cx + 8, cy + 10)], fill=(225, 29, 72, 255))
    # Porthole
    draw.ellipse((cx - 4, cy - 8, cx + 4, cy), fill=(34, 211, 238, 255), outline=(100, 116, 139, 255))
    # Booster Flame
    draw.polygon([(cx - 5, cy + 10), (cx, cy + 22), (cx + 5, cy + 10)], fill=(245, 158, 11, 255))


def draw_shield(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    pts = [
        (cx - 18, cy - 16),
        (cx + 18, cy - 16),
        (cx + 18, cy + 2),
        (cx, cy + 20),
        (cx - 18, cy + 2),
    ]
    draw.polygon(pts, fill=(30, 58, 138, 255), outline=(250, 204, 21, 255), width=2)
    # Gold Cross
    draw.rectangle((cx - 3, cy - 12, cx + 3, cy + 12), fill=(250, 204, 21, 255))
    draw.rectangle((cx - 12, cy - 6, cx + 12, cy), fill=(250, 204, 21, 255))


def draw_diamond(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    pts = [(cx, cy - 20), (cx + 18, cy), (cx, cy + 20), (cx - 18, cy)]
    draw.polygon(pts, fill=(168, 85, 247, 255), outline=(243, 232, 255, 255), width=2)
    draw.polygon([(cx, cy - 10), (cx + 9, cy), (cx, cy + 10), (cx - 9, cy)], fill=(192, 132, 252, 255))
    draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(255, 255, 255, 230))


def draw_coin(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    draw.ellipse((cx - 18, cy - 18, cx + 18, cy + 18), fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=2)
    draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(217, 119, 6, 255), outline=(254, 240, 138, 255), width=1)
    # Center Star
    draw_star(draw, ox + 6, oy + 6, col=(254, 240, 138), outline_col=(255, 255, 255))


def draw_music(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Double Eighth Note
    draw.ellipse((cx - 14, cy + 6, cx - 4, cy + 16), fill=(236, 72, 153, 255))
    draw.ellipse((cx + 4, cy + 2, cx + 14, cy + 12), fill=(236, 72, 153, 255))
    draw.line([(cx - 4, cy + 10), (cx - 4, cy - 12)], fill=(236, 72, 153, 255), width=3)
    draw.line([(cx + 14, cy + 6), (cx + 14, cy - 16)], fill=(236, 72, 153, 255), width=3)
    draw.line([(cx - 5, cy - 12), (cx + 15, cy - 16)], fill=(236, 72, 153, 255), width=5)


def draw_clover(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # 4 Leaves
    draw.ellipse((cx - 14, cy - 14, cx, cy), fill=(16, 185, 129, 255), outline=(110, 231, 183, 255))
    draw.ellipse((cx, cy - 14, cx + 14, cy), fill=(16, 185, 129, 255), outline=(110, 231, 183, 255))
    draw.ellipse((cx - 14, cy, cx, cy + 14), fill=(16, 185, 129, 255), outline=(110, 231, 183, 255))
    draw.ellipse((cx, cy, cx + 14, cy + 14), fill=(16, 185, 129, 255), outline=(110, 231, 183, 255))
    # Stem
    draw.arc((cx - 4, cy + 4, cx + 8, cy + 22), start=90, end=270, fill=(5, 150, 105, 255), width=3)


def draw_bell(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Bell Body
    pts = [
        (cx - 6, cy - 16),
        (cx + 6, cy - 16),
        (cx + 10, cy + 2),
        (cx + 18, cy + 10),
        (cx - 18, cy + 10),
        (cx - 10, cy + 2),
    ]
    draw.polygon(pts, fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=2)
    draw.ellipse((cx - 4, cy - 20, cx + 4, cy - 14), fill=(217, 119, 6, 255))
    draw.ellipse((cx - 4, cy + 8, cx + 4, cy + 16), fill=(180, 83, 9, 255))


def draw_skull(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Skull Head
    draw.ellipse((cx - 16, cy - 18, cx + 16, cy + 6), fill=(226, 232, 240, 255), outline=(71, 85, 105, 255), width=2)
    # Jaw
    draw.rectangle((cx - 8, cy + 4, cx + 8, cy + 16), fill=(226, 232, 240, 255), outline=(71, 85, 105, 255), width=2)
    # Eye sockets
    draw.ellipse((cx - 10, cy - 6, cx - 2, cy + 2), fill=(15, 23, 42, 255))
    draw.ellipse((cx + 2, cy - 6, cx + 10, cy + 2), fill=(15, 23, 42, 255))
    # Nose
    draw.polygon([(cx, cy + 2), (cx - 2, cy + 6), (cx + 2, cy + 6)], fill=(15, 23, 42, 255))


def draw_card_back(draw: ImageDraw.ImageDraw, ox: int, oy: int, primary=(20, 32, 58), border=(215, 175, 45)) -> None:
    draw.rectangle((ox + 4, oy + 4, ox + 60, oy + 60), fill=(*primary, 255), outline=(*border, 255), width=2)
    draw.rectangle((ox + 8, oy + 8, ox + 56, oy + 56), fill=(*primary, 255), outline=(*border, 160), width=1)
    # Filigree Mandala
    cx, cy = ox + 32, oy + 32
    draw.ellipse((cx - 16, cy - 16, cx + 16, cy + 16), outline=(*border, 180), width=1)
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(*border, 200), outline=(255, 255, 255, 220), width=1)
    draw.polygon([(cx, cy - 6), (cx + 6, cy), (cx, cy + 6), (cx - 6, cy)], fill=(255, 255, 255, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: 8 icons
    draw_gem(draw, 0 * CELL, 0)
    draw_crown(draw, 1 * CELL, 0)
    draw_star(draw, 2 * CELL, 0)
    draw_key(draw, 3 * CELL, 0)
    draw_potion(draw, 4 * CELL, 0)
    draw_fire(draw, 5 * CELL, 0)
    draw_lightning(draw, 6 * CELL, 0)
    draw_heart(draw, 7 * CELL, 0)

    # Row 1: 8 icons
    draw_crescent(draw, 0 * CELL, CELL)
    draw_atom(draw, 1 * CELL, CELL)
    draw_rocket(draw, 2 * CELL, CELL)
    draw_shield(draw, 3 * CELL, CELL)
    draw_diamond(draw, 4 * CELL, CELL)
    draw_coin(draw, 5 * CELL, CELL)
    draw_music(draw, 6 * CELL, CELL)
    draw_clover(draw, 7 * CELL, CELL)

    # Row 2: 2 remaining icons + card backs
    draw_bell(draw, 0 * CELL, 2 * CELL)
    draw_skull(draw, 1 * CELL, 2 * CELL)
    draw_card_back(draw, 2 * CELL, 2 * CELL, primary=(20, 32, 58), border=(215, 175, 45))     # Royal Sapphire
    draw_card_back(draw, 3 * CELL, 2 * CELL, primary=(6, 78, 59), border=(110, 231, 183))     # Mystic Emerald

    out_path = root / "assets" / "sprites" / "memorymatch.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "memorymatch" / "assets" / "sprites" / "memorymatch.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
