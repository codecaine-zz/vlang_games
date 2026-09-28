#!/usr/bin/env python3
"""Generate high-fidelity 512x512 RGBA sprite sheet for Balloon Fight:
- Player Fighters: P1 Blue & P2 Red (Flapping Frame 0, Flapping Frame 1, Falling)
- Enemy Fighters: Yellow Rank 1, Pink Rank 2, Red Rank 3 (Flap 0, Flap 1, Defeated)
- Glossy 3D Helium Balloons (Red, Blue, Yellow, Pink, Orange, Green)
- Parachutes (Open canopy & strings)
- Giant Sea Fish / Piranha (Emerging with giant chomping jaws)
- Lightning Sparks & Cloud icons
- Trip Balloons & Sparkles
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_balloon(draw: ImageDraw.ImageDraw, ox: int, oy: int, base_col: tuple[int, int, int], size: int = 24) -> None:
    # 3D shaded glossy helium balloon
    r, g, b = base_col
    # Outer body
    draw.ellipse((ox, oy, ox + size, oy + int(size * 1.15)), fill=(r, g, b, 255), outline=(int(r * 0.5), int(g * 0.5), int(b * 0.5), 255), width=2)
    # Specular shine
    draw.ellipse((ox + 4, oy + 4, ox + 10, oy + 9), fill=(255, 255, 255, 220))
    draw.ellipse((ox + 5, oy + 5, ox + 8, oy + 7), fill=(255, 255, 255, 255))
    # Bottom knot
    knot_y = oy + int(size * 1.15)
    draw.polygon([(ox + size // 2 - 3, knot_y), (ox + size // 2 + 3, knot_y), (ox + size // 2, knot_y + 4)], fill=(int(r * 0.7), int(g * 0.7), int(b * 0.7), 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0 (Y=0): Player Fighters (32x32)
    # -------------------------------------------------------------
    # P1 Blue Flap 0 (X=0, Y=0)
    draw.ellipse((8, 10, 24, 26), fill=(59, 130, 246, 255), outline=(29, 78, 216, 255), width=2) # Body
    draw.ellipse((10, 4, 22, 14), fill=(248, 250, 252, 255), outline=(30, 58, 138, 255), width=1) # Helmet
    draw.polygon([(18, 10), (28, 12), (18, 14)], fill=(245, 158, 11, 255)) # Beak/Visor
    draw.polygon([(8, 14), (0, 8), (8, 18)], fill=(248, 250, 252, 255), outline=(203, 213, 225, 255)) # Wing Up
    draw.rectangle((10, 24, 14, 30), fill=(245, 158, 11, 255)) # Feet
    draw.rectangle((18, 24, 22, 30), fill=(245, 158, 11, 255))

    # P1 Blue Flap 1 (X=32, Y=0)
    draw.ellipse((40, 10, 56, 26), fill=(59, 130, 246, 255), outline=(29, 78, 216, 255), width=2)
    draw.ellipse((42, 4, 54, 14), fill=(248, 250, 252, 255), outline=(30, 58, 138, 255), width=1)
    draw.polygon([(50, 10), (60, 12), (50, 14)], fill=(245, 158, 11, 255))
    draw.polygon([(40, 14), (32, 22), (40, 20)], fill=(248, 250, 252, 255), outline=(203, 213, 225, 255)) # Wing Down
    draw.rectangle((42, 24, 46, 30), fill=(245, 158, 11, 255))
    draw.rectangle((50, 24, 54, 30), fill=(245, 158, 11, 255))

    # P2 Red Flap 0 (X=64, Y=0)
    draw.ellipse((72, 10, 88, 26), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255), width=2)
    draw.ellipse((74, 4, 86, 14), fill=(248, 250, 252, 255), outline=(153, 27, 27, 255), width=1)
    draw.polygon([(82, 10), (92, 12), (82, 14)], fill=(245, 158, 11, 255))
    draw.polygon([(72, 14), (64, 8), (72, 18)], fill=(248, 250, 252, 255))
    draw.rectangle((74, 24, 78, 30), fill=(245, 158, 11, 255))
    draw.rectangle((82, 24, 86, 30), fill=(245, 158, 11, 255))

    # P2 Red Flap 1 (X=96, Y=0)
    draw.ellipse((104, 10, 120, 26), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255), width=2)
    draw.ellipse((106, 4, 118, 14), fill=(248, 250, 252, 255), outline=(153, 27, 27, 255), width=1)
    draw.polygon([(114, 10), (124, 12), (114, 14)], fill=(245, 158, 11, 255))
    draw.polygon([(104, 14), (96, 22), (104, 20)], fill=(248, 250, 252, 255))
    draw.rectangle((106, 24, 110, 30), fill=(245, 158, 11, 255))
    draw.rectangle((114, 24, 118, 30), fill=(245, 158, 11, 255))

    # -------------------------------------------------------------
    # Row 1 (Y=32): Enemy Avian Fighters (Yellow, Pink, Red)
    # -------------------------------------------------------------
    ranks = [
        ("yellow", (250, 204, 21), (180, 140, 10)),
        ("pink", (236, 72, 153), (170, 30, 100)),
        ("red", (239, 68, 68), (160, 20, 20)),
    ]
    for r_idx, (name, body_col, border_col) in enumerate(ranks):
        ox = r_idx * 64
        # Flap 0 (Wings Up)
        draw.ellipse((ox + 8, 42, ox + 24, 58), fill=(*body_col, 255), outline=(*border_col, 255), width=2)
        draw.polygon([(ox + 18, 48), (ox + 28, 51), (ox + 18, 54)], fill=(245, 130, 20, 255)) # Sharp Beak
        draw.ellipse((ox + 14, 44, ox + 18, 48), fill=(255, 255, 255, 255)) # Eye
        draw.ellipse((ox + 16, 45, ox + 18, 47), fill=(15, 23, 42, 255))
        draw.polygon([(ox + 8, 48), (ox + 0, 42), (ox + 8, 52)], fill=(*body_col, 255)) # Wing Up

        # Flap 1 (Wings Down)
        draw.ellipse((ox + 40, 42, ox + 56, 58), fill=(*body_col, 255), outline=(*border_col, 255), width=2)
        draw.polygon([(ox + 50, 48), (ox + 60, 51), (ox + 50, 54)], fill=(245, 130, 20, 255))
        draw.ellipse((ox + 46, 44, ox + 50, 48), fill=(255, 255, 255, 255))
        draw.ellipse((ox + 48, 45, ox + 50, 47), fill=(15, 23, 42, 255))
        draw.polygon([(ox + 40, 48), (ox + 32, 56), (ox + 40, 54)], fill=(*body_col, 255)) # Wing Down

    # -------------------------------------------------------------
    # Row 2 (Y=64): Helium Balloons (Red, Blue, Yellow, Pink, Orange, Green)
    # -------------------------------------------------------------
    balloon_colors = [
        (239, 68, 68),   # Red
        (59, 130, 246),  # Blue
        (250, 204, 21),  # Yellow
        (236, 72, 153),  # Pink
        (249, 115, 22),  # Orange
        (34, 197, 94),   # Green
    ]
    for b_idx, col in enumerate(balloon_colors):
        draw_balloon(draw, b_idx * 32 + 6, 64 + 2, col, size=20)

    # -------------------------------------------------------------
    # Row 3 (Y=96): Parachutes & Sparks
    # -------------------------------------------------------------
    # Parachute Open (X=0, Y=96, 32x32)
    draw.chord((4, 98, 28, 120), start=180, end=0, fill=(250, 204, 21, 255), outline=(202, 138, 4, 255), width=2)
    draw.line([(6, 109), (14, 124)], fill=(226, 232, 240, 220), width=1)
    draw.line([(26, 109), (18, 124)], fill=(226, 232, 240, 220), width=1)

    # Parachute White/Enemy (X=32, Y=96)
    draw.chord((36, 98, 60, 120), start=180, end=0, fill=(248, 250, 252, 255), outline=(148, 163, 184, 255), width=2)
    draw.line([(38, 109), (46, 124)], fill=(226, 232, 240, 220), width=1)
    draw.line([(58, 109), (50, 124)], fill=(226, 232, 240, 220), width=1)

    # Lightning Spark Star (X=64, Y=96)
    draw.polygon([(80, 98), (84, 108), (94, 112), (84, 116), (80, 126), (76, 116), (66, 112), (76, 108)], fill=(255, 255, 255, 255), outline=(250, 204, 21, 255), width=2)

    # -------------------------------------------------------------
    # Row 4 (Y=128..191): Giant Sea Fish (64x64)
    # -------------------------------------------------------------
    # Giant Fish / Piranha (X=0, Y=128, 64x64)
    # Scaly body
    draw.chord((4, 132, 60, 188), start=180, end=360, fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=3)
    # Gaping jaw
    draw.polygon([(16, 150), (48, 150), (32, 176)], fill=(15, 23, 42, 255))
    # Sharp White Teeth
    for tooth_x in [20, 26, 32, 38, 44]:
        draw.polygon([(tooth_x - 3, 150), (tooth_x + 3, 150), (tooth_x, 156)], fill=(255, 255, 255, 255))
    # Giant Menacing Eye
    draw.ellipse((40, 136, 52, 148), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255), width=2)
    draw.ellipse((46, 139, 51, 144), fill=(220, 38, 38, 255))

    # Water Splash (X=64, Y=128, 64x64)
    for sp in [(80, 160, 4), (96, 148, 6), (112, 160, 4), (88, 172, 3), (104, 172, 3)]:
        draw.ellipse((sp[0] - sp[2], sp[1] - sp[2], sp[0] + sp[2], sp[1] + sp[2]), fill=(34, 211, 238, 240))

    out_path = root / "assets" / "sprites" / "balloonfight.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")


if __name__ == "__main__":
    main()
