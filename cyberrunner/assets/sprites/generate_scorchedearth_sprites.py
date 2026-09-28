#!/usr/bin/env python3
"""Generate high-fidelity 1024x1024 RGBA sprite sheet for Scorched Earth:
- Tanks: Player 1 Green Tank, Cyborg Bot Red Tank, Destroyed Wreckage, Long Cannon Barrel, Energy Shield Dome
- Projectiles: Standard Shell, Baby Nuke, MIRV Warhead & Submunition, Mountain Mover, Napalm Canister & Fire Droplet, Digger Drill
- Explosions: 4-frame Standard Blast, 4-frame Thermonuclear Nuke Mushroom
- UI Badges & Icons: 6 Weapon Badges (Standard, Nuke, MIRV, Dirt, Napalm, Digger), Cash Icon, Audio Icon, Wind Pointer
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_W = 1024
SHEET_H = 1024


def draw_tank(draw: ImageDraw.ImageDraw, ox: int, oy: int, col_primary: tuple[int, int, int, int], col_trim: tuple[int, int, int, int], is_wreck: bool = False) -> None:
    if is_wreck:
        # Destroyed Wreckage
        draw.ellipse([ox + 4, oy + 24, ox + 44, oy + 30], fill=(15, 15, 20, 140))
        draw.rectangle([ox + 6, oy + 16, ox + 42, oy + 26], fill=(45, 45, 50, 255), outline=(25, 25, 30, 255))
        draw.rectangle([ox + 12, oy + 10, ox + 32, oy + 18], fill=(60, 50, 45, 255), outline=(20, 20, 20, 255))
        # Burnt cracks & smoke holes
        draw.line([(ox + 16, oy + 12), (ox + 22, oy + 16)], fill=(255, 100, 30, 255), width=2)
        draw.line([(ox + 28, oy + 14), (ox + 34, oy + 18)], fill=(255, 180, 50, 255), width=2)
        return

    # Shadow under treads
    draw.ellipse([ox + 2, oy + 24, ox + 46, oy + 31], fill=(10, 15, 25, 120))

    # Heavy Steel Treads & Road Wheels
    draw.rounded_rectangle([ox + 4, oy + 18, ox + 44, oy + 28], radius=4, fill=(35, 40, 48, 255), outline=(15, 20, 25, 255), width=2)
    for wx in range(ox + 8, ox + 42, 7):
        draw.ellipse([wx, oy + 20, wx + 5, oy + 25], fill=(70, 75, 85, 255), outline=(25, 30, 35, 255))
        draw.ellipse([wx + 2, oy + 22, wx + 3, oy + 23], fill=(180, 190, 205, 255))

    # Main Armored Chassis Hull
    draw.polygon([
        (ox + 8, oy + 18),
        (ox + 40, oy + 18),
        (ox + 44, oy + 12),
        (ox + 4, oy + 12)
    ], fill=col_primary, outline=(20, 25, 30, 255))

    # Armor Trim Highlight Line
    draw.line([(ox + 6, oy + 13), (ox + 42, oy + 13)], fill=col_trim, width=1)

    # Turret Dome / Cupola
    draw.ellipse([ox + 14, oy + 4, ox + 34, oy + 16], fill=col_primary, outline=(20, 25, 30, 255))
    draw.ellipse([ox + 18, oy + 6, ox + 30, oy + 12], fill=col_trim)
    # Commander Hatch
    draw.ellipse([ox + 21, oy + 6, ox + 27, oy + 10], fill=(45, 50, 60, 255))


def draw_barrel(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Long Cannon Barrel (horizontal facing right, 24x8)
    draw.rectangle([ox, oy + 2, ox + 22, oy + 6], fill=(90, 95, 105, 255), outline=(30, 35, 42, 255))
    draw.line([(ox, oy + 3), (ox + 22, oy + 3)], fill=(160, 170, 185, 255))
    # Muzzle Brake
    draw.rectangle([ox + 20, oy + 1, ox + 24, oy + 7], fill=(55, 60, 70, 255), outline=(25, 30, 35, 255))


def draw_shield(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Energy Shield Dome (48x48)
    draw.ellipse([ox + 2, oy + 2, ox + 46, oy + 46], fill=(40, 220, 255, 60), outline=(100, 240, 255, 220), width=2)
    draw.arc([ox + 6, oy + 6, ox + 42, oy + 42], start=200, end=340, fill=(255, 255, 255, 220), width=2)


def draw_projectiles(draw: ImageDraw.ImageDraw) -> None:
    # Row 1 (Y = 64..127)
    # Standard Shell (0, 64, 32x32)
    draw.polygon([(26, 80), (8, 74), (8, 86)], fill=(225, 175, 45, 255), outline=(130, 90, 15, 255))
    draw.polygon([(26, 80), (18, 75), (18, 85)], fill=(255, 80, 30, 255))
    draw.rectangle([4, 76, 8, 84], fill=(180, 190, 205, 255))

    # Baby Nuke (48, 64, 32x32)
    draw.rounded_rectangle([52, 74, 76, 86], radius=4, fill=(50, 55, 65, 255), outline=(20, 25, 30, 255))
    draw.polygon([(76, 80), (68, 74), (68, 86)], fill=(255, 215, 40, 255), outline=(140, 100, 10, 255))
    # Radiation Trefoil
    draw.ellipse([58, 77, 64, 83], fill=(255, 220, 40, 255))
    draw.ellipse([60, 79, 62, 81], fill=(20, 20, 20, 255))
    # Fins
    draw.polygon([(52, 74), (46, 70), (52, 77)], fill=(240, 60, 50, 255))
    draw.polygon([(52, 86), (46, 90), (52, 83)], fill=(240, 60, 50, 255))

    # MIRV Warhead (96, 64, 32x32)
    draw.rounded_rectangle([100, 74, 124, 86], radius=3, fill=(180, 40, 45, 255), outline=(90, 15, 20, 255))
    draw.polygon([(124, 80), (116, 73), (116, 87)], fill=(255, 230, 80, 255))
    draw.line([(108, 74), (108, 86)], fill=(255, 255, 255, 255), width=2)
    draw.line([(114, 74), (114, 86)], fill=(255, 255, 255, 255), width=2)

    # MIRV Bomblet (144, 64, 32x32)
    draw.ellipse([152, 74, 168, 86], fill=(240, 60, 50, 255), outline=(255, 220, 80, 255), width=2)
    draw.ellipse([157, 77, 163, 83], fill=(255, 255, 255, 255))

    # Mountain Mover (192, 64, 32x32)
    draw.rounded_rectangle([196, 73, 220, 87], radius=4, fill=(140, 85, 45, 255), outline=(75, 45, 20, 255), width=2)
    draw.ellipse([210, 76, 218, 84], fill=(215, 165, 95, 255))
    draw.line([(200, 74), (200, 86)], fill=(225, 185, 110, 255), width=2)

    # Napalm Roller (240, 64, 32x32)
    draw.rounded_rectangle([244, 73, 268, 87], radius=5, fill=(230, 45, 30, 255), outline=(130, 15, 10, 255), width=2)
    draw.ellipse([250, 76, 262, 84], fill=(255, 160, 30, 255))
    draw.ellipse([253, 78, 259, 82], fill=(255, 240, 80, 255))

    # Napalm Fire Droplet (288, 64, 32x32)
    draw.ellipse([296, 72, 312, 88], fill=(255, 80, 20, 240), outline=(255, 220, 60, 255), width=2)
    draw.ellipse([300, 76, 308, 84], fill=(255, 255, 150, 255))

    # Digger Drill (336, 64, 32x32)
    draw.polygon([(364, 80), (350, 72), (350, 88)], fill=(195, 205, 220, 255), outline=(90, 95, 110, 255))
    draw.line([(364, 80), (350, 75)], fill=(90, 95, 110, 255), width=2)
    draw.line([(360, 80), (350, 85)], fill=(90, 95, 110, 255), width=2)
    draw.rectangle([340, 74, 350, 86], fill=(50, 90, 160, 255), outline=(20, 45, 90, 255))


def draw_explosions(draw: ImageDraw.ImageDraw) -> None:
    # Standard Explosion 4 Frames (Y = 128)
    # Frame 1 (0, 128, 48x48)
    draw.ellipse([14, 142, 34, 162], fill=(255, 240, 180, 255), outline=(255, 180, 40, 255), width=3)
    draw.ellipse([18, 146, 30, 158], fill=(255, 255, 255, 255))

    # Frame 2 (56, 128, 48x48)
    draw.ellipse([64, 136, 96, 168], fill=(255, 140, 30, 255), outline=(255, 220, 70, 255), width=3)
    draw.ellipse([72, 144, 88, 160], fill=(255, 255, 200, 255))

    # Frame 3 (112, 128, 48x48)
    draw.ellipse([116, 132, 156, 172], fill=(230, 50, 30, 255), outline=(255, 160, 40, 255), width=3)
    draw.ellipse([124, 140, 148, 164], fill=(255, 210, 60, 255))
    draw.ellipse([132, 148, 140, 156], fill=(255, 255, 255, 255))

    # Frame 4 (168, 128, 48x48)
    draw.ellipse([172, 132, 212, 172], fill=(60, 40, 35, 200), outline=(200, 80, 40, 220), width=2)
    draw.ellipse([180, 140, 204, 164], fill=(240, 90, 30, 220))

    # Thermonuclear Nuke Explosion 4 Frames (Y = 192, 64x64)
    # Frame 1 (0, 192, 64x64)
    draw.ellipse([16, 208, 48, 240], fill=(255, 255, 255, 255), outline=(255, 225, 80, 255), width=4)

    # Frame 2 (72, 192, 64x64)
    draw.ellipse([80, 196, 128, 230], fill=(255, 170, 30, 255), outline=(255, 240, 90, 255), width=3)
    draw.rectangle([98, 224, 110, 252], fill=(240, 90, 30, 255)) # mushroom stem
    draw.ellipse([92, 206, 116, 224], fill=(255, 255, 220, 255))

    # Frame 3 (144, 192, 64x64)
    draw.ellipse([148, 194, 204, 234], fill=(240, 60, 30, 255), outline=(255, 210, 50, 255), width=4)
    draw.rectangle([170, 222, 182, 254], fill=(210, 60, 25, 255))
    draw.ellipse([160, 204, 192, 226], fill=(255, 240, 120, 255))

    # Frame 4 (216, 192, 64x64)
    draw.ellipse([220, 194, 276, 236], fill=(50, 45, 55, 220), outline=(240, 110, 40, 220), width=3)
    draw.rectangle([242, 224, 254, 254], fill=(60, 50, 50, 200))
    draw.ellipse([232, 206, 264, 226], fill=(220, 90, 30, 220))


def draw_badges(draw: ImageDraw.ImageDraw) -> None:
    # Row 3 (Y = 256..319, 48x48)
    badges = [
        ("STANDARD", (70, 80, 95, 255), (140, 155, 180, 255)),
        ("NUKE", (200, 140, 20, 255), (255, 220, 60, 255)),
        ("MIRV", (180, 35, 45, 255), (255, 100, 110, 255)),
        ("DIRT", (120, 75, 40, 255), (200, 150, 95, 255)),
        ("NAPALM", (210, 50, 20, 255), (255, 140, 40, 255)),
        ("DIGGER", (45, 95, 170, 255), (100, 180, 255, 255)),
    ]

    for idx, (label, col_bg, col_border) in enumerate(badges):
        ox = idx * 56
        oy = 256
        draw.rounded_rectangle([ox + 2, oy + 2, ox + 46, oy + 46], radius=6, fill=col_bg, outline=col_border, width=2)
        # Inner emblem
        if label == "STANDARD":
            draw.polygon([(ox + 34, oy + 24), (ox + 16, oy + 18), (ox + 16, oy + 30)], fill=(255, 200, 60, 255))
        elif label == "NUKE":
            draw.ellipse([ox + 18, oy + 18, ox + 30, oy + 30], fill=(255, 255, 255, 255), outline=(20, 20, 20, 255), width=2)
        elif label == "MIRV":
            draw.polygon([(ox + 32, oy + 24), (ox + 20, oy + 16), (ox + 20, oy + 32)], fill=(255, 255, 255, 255))
            draw.ellipse([ox + 12, oy + 14, ox + 18, oy + 20], fill=(255, 220, 60, 255))
            draw.ellipse([ox + 12, oy + 28, ox + 18, oy + 34], fill=(255, 220, 60, 255))
        elif label == "DIRT":
            draw.polygon([(ox + 24, oy + 14), (ox + 12, oy + 34), (ox + 36, oy + 34)], fill=(215, 165, 95, 255))
        elif label == "NAPALM":
            draw.ellipse([ox + 16, oy + 16, ox + 32, oy + 32], fill=(255, 140, 30, 255), outline=(255, 240, 80, 255), width=2)
        elif label == "DIGGER":
            draw.polygon([(ox + 34, oy + 24), (ox + 18, oy + 16), (ox + 18, oy + 32)], fill=(195, 205, 220, 255))

    # Cash Dollar Icon (336, 256, 32x32)
    draw.ellipse([338, 258, 366, 286], fill=(40, 160, 75, 255), outline=(140, 255, 160, 255), width=2)
    draw.line([(352, 262), (352, 282)], fill=(255, 255, 255, 255), width=2)

    # Audio Speaker Icon (376, 256, 32x32)
    draw.polygon([(380, 268), (388, 268), (396, 262), (396, 282), (388, 276), (380, 276)], fill=(200, 210, 230, 255), outline=(100, 110, 130, 255))

    # Wind Pointer Arrow (416, 256, 32x32)
    draw.polygon([(444, 272), (426, 264), (430, 272), (426, 280)], fill=(80, 200, 255, 255), outline=(200, 240, 255, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sprites_dir = root / "assets" / "sprites"
    sprites_dir.mkdir(parents=True, exist_ok=True)
    out_path = sprites_dir / "scorchedearth.png"

    sheet = Image.new("RGBA", (SHEET_W, SHEET_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # 1. Tanks (Row 0)
    # Player 1 Green Tank (0, 0)
    draw_tank(draw, 0, 0, col_primary=(40, 185, 80, 255), col_trim=(120, 245, 150, 255))
    # Cyborg Bot Red Tank (64, 0)
    draw_tank(draw, 64, 0, col_primary=(215, 45, 50, 255), col_trim=(255, 140, 140, 255))
    # Destroyed Wreckage (128, 0)
    draw_tank(draw, 128, 0, col_primary=(0, 0, 0, 0), col_trim=(0, 0, 0, 0), is_wreck=True)
    # Long Cannon Barrel (192, 0)
    draw_barrel(draw, 192, 0)
    # Shield Dome (224, 0)
    draw_shield(draw, 224, 0)

    # 2. Projectiles (Row 1)
    draw_projectiles(draw)

    # 3. Explosions (Row 2)
    draw_explosions(draw)

    # 4. Badges (Row 3)
    draw_badges(draw)

    sheet.save(out_path, format="PNG")
    print(f"Generated Scorched Earth sprite sheet at {out_path} ({SHEET_W}x{SHEET_H})")


if __name__ == "__main__":
    main()
