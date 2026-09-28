#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for The Legend of Kage:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Kage & Princess Kiri (Stand/Run, Soaring Jump, Katana Slash, Shuriken Throw, Tree Perch, Gold Jutsu, Shadow Clone, Princess Kiri)
Row 1 (Y=64..127):  Enemies (Blue Ninja Run, Blue Ninja Jump, Red Ninja Shuriken, Water Ninja, Fire Monk, Samurai Warlord Boss, Kidnapper, Defeated)
Row 2 (Y=128..191): Scrolls & Items (Lightning Scroll, Fire Scroll, Clone Scroll, Speed Scroll, 1UP Orb, Magatama, Shuriken Star, Fireball)
Row 3 (Y=192..255): Effects (Autumn Leaf, Blade Clash Spark, Jutsu Kanji Circle, Water Splash, Smoke Puff)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_kage(draw: ImageDraw.ImageDraw, ox: int, oy: int, pose: str = "run", is_gold: bool = False, is_clone: bool = False) -> None:
    cx, cy = ox + 32, oy + 32
    if is_clone:
        robe_col = (250, 204, 21, 160)
        scarf_col = (254, 240, 138, 180)
        skin_col = (254, 215, 170, 180)
    elif is_gold:
        robe_col = (234, 179, 8, 255)
        scarf_col = (254, 240, 138, 255)
        skin_col = (254, 215, 170, 255)
    else:
        robe_col = (220, 38, 38, 255)
        scarf_col = (255, 255, 255, 255)
        skin_col = (254, 215, 170, 255)

    # Scarf Tails Fluttering behind
    draw.polygon([(cx - 8, cy - 14), (cx - 24, cy - 10), (cx - 22, cy - 6), (cx - 8, cy - 10)], fill=scarf_col)
    draw.polygon([(cx - 8, cy - 12), (cx - 20, cy - 2), (cx - 18, cy + 2), (cx - 8, cy - 8)], fill=scarf_col)

    # Head & Mask
    draw.rectangle((cx - 8, cy - 22, cx + 8, cy - 10), fill=robe_col)
    draw.rectangle((cx - 6, cy - 18, cx + 6, cy - 14), fill=skin_col)
    # Forehead metal plate (Hitai-ate)
    draw.rectangle((cx - 7, cy - 22, cx + 7, cy - 19), fill=(148, 163, 184, 255))

    # Robe Torso
    draw.rectangle((cx - 10, cy - 10, cx + 10, cy + 8), fill=robe_col)
    # Black Obi Sash
    draw.rectangle((cx - 10, cy + 2, cx + 10, cy + 6), fill=(15, 23, 42, 255))

    if pose == "jump":
        # Soaring leap legs curled / trailing
        draw.rectangle((cx - 12, cy + 8, cx - 2, cy + 18), fill=robe_col)
        draw.rectangle((cx + 2, cy + 4, cx + 14, cy + 12), fill=robe_col)
        # Katana held ready
        draw.line([(cx + 4, cy - 6), (cx + 22, cy - 16)], fill=(241, 245, 249, 255), width=3)
    elif pose == "slash":
        # Katana slashing wide arc
        draw.rectangle((cx - 8, cy + 8, cx + 8, cy + 22), fill=robe_col)
        # Metallic blade glow arc
        draw.arc((cx - 20, cy - 26, cx + 28, cy + 22), start=-45, end=90, fill=(56, 189, 248, 255), width=4)
        draw.line([(cx + 6, cy - 4), (cx + 24, cy - 2)], fill=(255, 255, 255, 255), width=3)
    elif pose == "shuriken":
        # Throwing arm extended forward
        draw.rectangle((cx - 8, cy + 8, cx + 8, cy + 22), fill=robe_col)
        draw.rectangle((cx + 6, cy - 8, cx + 18, cy - 2), fill=skin_col)
        draw.polygon([(cx + 18, cy - 8), (cx + 26, cy - 5), (cx + 18, cy - 2)], fill=(148, 163, 184, 255))
    else:  # run
        draw.rectangle((cx - 10, cy + 8, cx - 2, cy + 22), fill=robe_col)
        draw.rectangle((cx + 2, cy + 8, cx + 10, cy + 20), fill=robe_col)
        # Sheathed Kodachi on back
        draw.line([(cx - 12, cy + 4), (cx - 2, cy - 12)], fill=(148, 163, 184, 255), width=3)


def draw_princess_kiri(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Pink Silk Kimono
    draw.polygon([(cx, cy - 10), (cx - 14, cy + 24), (cx + 14, cy + 24)], fill=(244, 114, 182, 255))
    # Red Obi Sash
    draw.rectangle((cx - 8, cy + 2, cx + 8, cy + 8), fill=(225, 29, 72, 255))
    # Head & Long Black Hair
    draw.rectangle((cx - 10, cy - 24, cx + 10, cy - 6), fill=(15, 23, 42, 255))
    draw.rectangle((cx - 6, cy - 20, cx + 6, cy - 10), fill=(254, 215, 170, 255))
    # Flower Hairpin
    draw.ellipse((cx + 4, cy - 24, cx + 10, cy - 18), fill=(251, 191, 36, 255))


def draw_enemy(draw: ImageDraw.ImageDraw, ox: int, oy: int, enemy_type: str = "blue_ninja") -> None:
    cx, cy = ox + 32, oy + 32
    if enemy_type == "blue_ninja":
        robe_col = (37, 99, 235, 255)
        # Head & Mask
        draw.rectangle((cx - 8, cy - 20, cx + 8, cy - 10), fill=robe_col)
        draw.rectangle((cx - 6, cy - 16, cx + 6, cy - 12), fill=(254, 215, 170, 255))
        draw.rectangle((cx - 10, cy - 10, cx + 10, cy + 8), fill=robe_col)
        draw.rectangle((cx - 8, cy + 8, cx + 8, cy + 22), fill=robe_col)
        # Katana
        draw.line([(cx + 4, cy - 4), (cx + 20, cy - 12)], fill=(203, 213, 225, 255), width=2)
    elif enemy_type == "red_ninja":
        robe_col = (185, 28, 28, 255)
        draw.rectangle((cx - 8, cy - 20, cx + 8, cy - 10), fill=robe_col)
        draw.rectangle((cx - 6, cy - 16, cx + 6, cy - 12), fill=(254, 215, 170, 255))
        draw.rectangle((cx - 10, cy - 10, cx + 10, cy + 8), fill=robe_col)
        draw.rectangle((cx - 8, cy + 8, cx + 8, cy + 22), fill=robe_col)
        # Shuriken ready
        draw.ellipse((cx + 10, cy - 4, cx + 18, cy + 4), fill=(148, 163, 184, 255))
    elif enemy_type == "fire_monk":
        # Yellow Kasaya Robe
        draw.rectangle((cx - 12, cy - 10, cx + 12, cy + 22), fill=(234, 179, 8, 255))
        # Bald Head
        draw.ellipse((cx - 9, cy - 24, cx + 9, cy - 8), fill=(254, 215, 170, 255))
        # Fire Stream from Mouth
        draw.polygon([(cx + 6, cy - 12), (cx + 26, cy - 18), (cx + 28, cy - 6)], fill=(239, 68, 68, 255))
        draw.polygon([(cx + 8, cy - 12), (cx + 22, cy - 16), (cx + 24, cy - 8)], fill=(251, 191, 36, 255))
    elif enemy_type == "boss_warlord":
        # Samurai Kabuto & Armor
        draw.rectangle((cx - 14, cy - 8, cx + 14, cy + 22), fill=(153, 27, 27, 255))
        # Gold Kabuto Helmet Crest
        draw.polygon([(cx - 10, cy - 16), (cx, cy - 26), (cx + 10, cy - 16)], fill=(245, 158, 11, 255))
        draw.rectangle((cx - 8, cy - 18, cx + 8, cy - 8), fill=(15, 23, 42, 255))
        # Dual Katanas
        draw.line([(cx - 18, cy - 12), (cx + 18, cy + 8)], fill=(241, 245, 249, 255), width=3)
        draw.line([(cx - 18, cy + 8), (cx + 18, cy - 12)], fill=(241, 245, 249, 255), width=3)


def draw_scroll(draw: ImageDraw.ImageDraw, ox: int, oy: int, style: str = "lightning") -> None:
    cx, cy = ox + 32, oy + 32
    # Parchment Scroll
    draw.rectangle((cx - 14, cy - 12, cx + 14, cy + 12), fill=(254, 243, 199, 255), outline=(180, 83, 9, 255), width=2)
    # Gold Roller Rods
    draw.rectangle((cx - 18, cy - 10, cx - 14, cy + 10), fill=(245, 158, 11, 255))
    draw.rectangle((cx + 14, cy - 10, cx + 18, cy + 10), fill=(245, 158, 11, 255))
    # Kanji / Symbol
    if style == "lightning":
        draw.polygon([(cx, cy - 8), (cx - 6, cy), (cx + 2, cy), (cx - 2, cy + 8), (cx + 6, cy - 1), (cx - 1, cy - 1)], fill=(234, 179, 8, 255))
    elif style == "fire":
        draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(239, 68, 68, 255))
    elif style == "clone":
        draw.ellipse((cx - 7, cy - 5, cx, cy + 5), fill=(59, 130, 246, 255))
        draw.ellipse((cx, cy - 5, cx + 7, cy + 5), fill=(239, 68, 68, 255))
    else:  # speed
        draw.polygon([(cx - 6, cy - 6), (cx + 6, cy), (cx - 6, cy + 6)], fill=(16, 185, 129, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Kage poses & Princess Kiri
    draw_kage(draw, 0 * C, 0 * C, pose="run")
    draw_kage(draw, 1 * C, 0 * C, pose="jump")
    draw_kage(draw, 2 * C, 0 * C, pose="slash")
    draw_kage(draw, 3 * C, 0 * C, pose="shuriken")
    draw_kage(draw, 4 * C, 0 * C, pose="jump")
    draw_kage(draw, 5 * C, 0 * C, pose="run", is_gold=True)
    draw_kage(draw, 6 * C, 0 * C, pose="run", is_clone=True)
    draw_princess_kiri(draw, 7 * C, 0 * C)

    # Row 1: Enemies
    draw_enemy(draw, 0 * C, 1 * C, "blue_ninja")
    draw_enemy(draw, 1 * C, 1 * C, "blue_ninja")
    draw_enemy(draw, 2 * C, 1 * C, "red_ninja")
    draw_enemy(draw, 3 * C, 1 * C, "blue_ninja")
    draw_enemy(draw, 4 * C, 1 * C, "fire_monk")
    draw_enemy(draw, 5 * C, 1 * C, "boss_warlord")
    draw_enemy(draw, 6 * C, 1 * C, "blue_ninja")
    draw_enemy(draw, 7 * C, 1 * C, "red_ninja")

    # Row 2: Scrolls & Items
    draw_scroll(draw, 0 * C, 2 * C, "lightning")
    draw_scroll(draw, 1 * C, 2 * C, "fire")
    draw_scroll(draw, 2 * C, 2 * C, "clone")
    draw_scroll(draw, 3 * C, 2 * C, "speed")

    # Shuriken Projectile
    cx, cy = 6 * C + 32, 2 * C + 32
    draw.polygon([(cx, cy - 10), (cx + 3, cy - 3), (cx + 10, cy), (cx + 3, cy + 3), (cx, cy + 10), (cx - 3, cy + 3), (cx - 10, cy), (cx - 3, cy - 3)], fill=(241, 245, 249, 255))

    # Fireball Projectile
    cx, cy = 7 * C + 32, 2 * C + 32
    draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=(239, 68, 68, 255))
    draw.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=(251, 191, 36, 255))

    out_path = root / "assets" / "sprites" / "legendofkage.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "legendofkage" / "assets" / "sprites" / "legendofkage.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
