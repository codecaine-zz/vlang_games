#!/usr/bin/env python3
"""Generate high-fidelity 512x512 RGBA sprite sheet for Centipede:
- Player Blaster Cannon & Powered variant
- Centipede Head & Body (Animated walking legs & mandibles)
- Mushrooms (Healthy 4-HP, Damaged 3/2/1-HP, Poison Purple, Gold Powerup)
- Pests: Flea, Spider (Animated 8 legs), Scorpion (Stinger & claws)
- Power-up capsules (Rapid Fire, Triple Spread, Plasma Beam, EMP Nuke, Shield, Speed Dash)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_pixel_circle(
    draw: ImageDraw.ImageDraw, cx: int, cy: int, r: int, fill: tuple[int, int, int, int], outline: tuple[int, int, int, int] | None = None
) -> None:
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill, outline=outline)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0 (Y=0): Player Blaster & Centipede Segments
    # -------------------------------------------------------------

    # 1. Player Blaster Cannon (X=0, Y=0)
    # Triangular chassis with dual plasma rails and glowing reactor
    draw.polygon([(4, 28), (28, 28), (20, 14), (12, 14)], fill=(40, 60, 90, 255), outline=(0, 220, 255, 255))
    draw.rectangle((14, 4, 18, 16), fill=(0, 240, 255, 255), outline=(255, 255, 255, 255))
    draw.ellipse((13, 18, 19, 24), fill=(255, 220, 50, 255))

    # 2. Player Shielded Cannon (X=32, Y=0)
    draw.polygon([(36, 28), (60, 28), (52, 14), (44, 14)], fill=(60, 40, 110, 255), outline=(255, 100, 255, 255))
    draw.rectangle((46, 4, 50, 16), fill=(255, 120, 255, 255), outline=(255, 255, 255, 255))
    draw.ellipse((45, 18, 51, 24), fill=(80, 255, 220, 255))
    draw.ellipse((34, 2, 62, 30), outline=(100, 220, 255, 180), width=2)

    # 3. Centipede Head Normal - Frame 0 (X=64, Y=0)
    # Segment body
    draw.ellipse((68, 6, 92, 26), fill=(235, 45, 45, 255), outline=(140, 10, 10, 255), width=2)
    # Mandibles open
    draw.polygon([(70, 6), (64, 0), (74, 4)], fill=(255, 220, 40, 255))
    draw.polygon([(90, 6), (96, 0), (86, 4)], fill=(255, 220, 40, 255))
    # Glowing yellow eyes & angry pupils
    draw.ellipse((72, 10, 78, 16), fill=(255, 240, 40, 255))
    draw.ellipse((82, 10, 88, 16), fill=(255, 240, 40, 255))
    draw.ellipse((74, 12, 77, 15), fill=(20, 20, 20, 255))
    draw.ellipse((84, 12, 87, 15), fill=(20, 20, 20, 255))

    # 4. Centipede Head Normal - Frame 1 Mandibles Closed (X=96, Y=0)
    draw.ellipse((100, 6, 124, 26), fill=(235, 45, 45, 255), outline=(140, 10, 10, 255), width=2)
    draw.polygon([(104, 6), (108, 2), (108, 6)], fill=(255, 220, 40, 255))
    draw.polygon([(116, 6), (112, 2), (112, 6)], fill=(255, 220, 40, 255))
    draw.ellipse((104, 10, 110, 16), fill=(255, 240, 40, 255))
    draw.ellipse((114, 10, 120, 16), fill=(255, 240, 40, 255))
    draw.ellipse((106, 12, 109, 15), fill=(20, 20, 20, 255))
    draw.ellipse((116, 12, 119, 15), fill=(20, 20, 20, 255))

    # 5. Centipede Head Poisoned (X=128, Y=0)
    draw.ellipse((132, 6, 156, 26), fill=(180, 40, 220, 255), outline=(90, 10, 130, 255), width=2)
    draw.polygon([(134, 6), (128, 0), (138, 4)], fill=(40, 255, 140, 255))
    draw.polygon([(154, 6), (160, 0), (150, 4)], fill=(40, 255, 140, 255))
    draw.ellipse((136, 10, 142, 16), fill=(40, 255, 140, 255))
    draw.ellipse((146, 10, 152, 16), fill=(40, 255, 140, 255))

    # 6. Centipede Body Normal - Frame 0 (X=160, Y=0)
    draw.ellipse((166, 6, 186, 26), fill=(40, 200, 80, 255), outline=(10, 110, 30, 255), width=2)
    draw.ellipse((172, 12, 180, 20), fill=(240, 220, 40, 255))
    # Legs angled down
    draw.line([(166, 20), (160, 28)], fill=(240, 220, 40, 255), width=2)
    draw.line([(186, 20), (192, 28)], fill=(240, 220, 40, 255), width=2)

    # 7. Centipede Body Normal - Frame 1 (X=192, Y=0)
    draw.ellipse((198, 6, 218, 26), fill=(40, 200, 80, 255), outline=(10, 110, 30, 255), width=2)
    draw.ellipse((204, 12, 212, 20), fill=(240, 220, 40, 255))
    # Legs angled forward
    draw.line([(198, 16), (192, 10)], fill=(240, 220, 40, 255), width=2)
    draw.line([(218, 16), (224, 10)], fill=(240, 220, 40, 255), width=2)

    # 8. Centipede Body Poisoned (X=224, Y=0)
    draw.ellipse((230, 6, 250, 26), fill=(160, 40, 200, 255), outline=(80, 10, 110, 255), width=2)
    draw.ellipse((236, 12, 244, 20), fill=(40, 255, 140, 255))
    draw.line([(230, 20), (224, 28)], fill=(40, 255, 140, 255), width=2)
    draw.line([(250, 20), (256, 28)], fill=(40, 255, 140, 255), width=2)

    # -------------------------------------------------------------
    # Row 1 (Y=32): Mushrooms
    # -------------------------------------------------------------

    def draw_mush(ox: int, oy: int, cap_color: tuple[int, int, int], spots_color: tuple[int, int, int], damage: int = 0) -> None:
        # Stem
        draw.rectangle((ox + 12, oy + 16, ox + 20, oy + 28), fill=(220, 220, 230, 255), outline=(60, 60, 70, 255))
        # Cap
        draw.chord((ox + 4, oy + 4, ox + 28, oy + 24), start=180, end=0, fill=(*cap_color, 255), outline=(20, 30, 40, 255), width=2)
        # Spots
        if damage < 3:
            draw.ellipse((ox + 8, oy + 8, ox + 12, oy + 12), fill=(*spots_color, 255))
            draw.ellipse((ox + 19, oy + 7, ox + 23, oy + 11), fill=(*spots_color, 255))
        if damage < 2:
            draw.ellipse((ox + 14, oy + 12, ox + 18, oy + 16), fill=(*spots_color, 255))
        # Cracks/damage cuts
        if damage >= 1:
            draw.line([(ox + 10, oy + 6), (ox + 13, oy + 14)], fill=(20, 20, 20, 255), width=2)
        if damage >= 2:
            draw.line([(ox + 22, oy + 8), (ox + 18, oy + 15)], fill=(20, 20, 20, 255), width=2)

    # Mushroom HP=4 (X=0, Y=32)
    draw_mush(0, 32, (60, 220, 100), (240, 255, 200), damage=0)
    # Mushroom HP=3 (X=32, Y=32)
    draw_mush(32, 32, (50, 190, 90), (200, 240, 180), damage=1)
    # Mushroom HP=2 (X=64, Y=32)
    draw_mush(64, 32, (40, 150, 80), (170, 210, 150), damage=2)
    # Mushroom HP=1 (X=96, Y=32)
    draw_mush(96, 32, (30, 110, 60), (140, 170, 120), damage=3)
    # Poison Mushroom (X=128, Y=32)
    draw_mush(128, 32, (220, 50, 220), (40, 255, 180), damage=0)
    # Gold Powerup Mushroom (X=160, Y=32)
    draw_mush(160, 32, (255, 215, 30), (255, 255, 240), damage=0)

    # -------------------------------------------------------------
    # Row 2 (Y=64): Pests (Flea, Spider, Scorpion)
    # -------------------------------------------------------------

    # Flea Frame 0 (X=0, Y=64)
    draw.ellipse((10, 68, 22, 90), fill=(80, 220, 255, 255), outline=(0, 140, 200, 255), width=2)
    draw.line([(10, 74), (4, 82)], fill=(255, 255, 255, 255), width=2)
    draw.line([(22, 74), (28, 82)], fill=(255, 255, 255, 255), width=2)

    # Flea Frame 1 (X=32, Y=64)
    draw.ellipse((42, 68, 54, 90), fill=(80, 220, 255, 255), outline=(0, 140, 200, 255), width=2)
    draw.line([(42, 78), (36, 70)], fill=(255, 255, 255, 255), width=2)
    draw.line([(54, 78), (60, 70)], fill=(255, 255, 255, 255), width=2)

    # Spider Frame 0 (X=64, Y=64)
    # Round furry abdomen & 8 sprawling legs
    draw.ellipse((74, 74, 86, 86), fill=(240, 140, 30, 255), outline=(120, 60, 10, 255), width=2)
    draw.ellipse((77, 76, 80, 79), fill=(255, 255, 255, 255))
    draw.ellipse((80, 76, 83, 79), fill=(255, 255, 255, 255))
    for leg_angle in [-60, -30, 30, 60]:
        rad = math.radians(leg_angle)
        draw.line([(80 + int(math.cos(rad) * 6), 80 + int(math.sin(rad) * 6)),
                   (80 + int(math.cos(rad) * 14), 80 + int(math.sin(rad) * 14))], fill=(240, 140, 30, 255), width=2)
        draw.line([(80 - int(math.cos(rad) * 6), 80 + int(math.sin(rad) * 6)),
                   (80 - int(math.cos(rad) * 14), 80 + int(math.sin(rad) * 14))], fill=(240, 140, 30, 255), width=2)

    # Spider Frame 1 (X=96, Y=64)
    draw.ellipse((106, 74, 118, 86), fill=(240, 140, 30, 255), outline=(120, 60, 10, 255), width=2)
    draw.ellipse((109, 76, 112, 79), fill=(255, 255, 255, 255))
    draw.ellipse((112, 76, 115, 79), fill=(255, 255, 255, 255))
    for leg_angle in [-75, -45, 15, 45]:
        rad = math.radians(leg_angle)
        draw.line([(112 + int(math.cos(rad) * 6), 80 + int(math.sin(rad) * 6)),
                   (112 + int(math.cos(rad) * 14), 80 + int(math.sin(rad) * 14))], fill=(240, 140, 30, 255), width=2)
        draw.line([(112 - int(math.cos(rad) * 6), 80 + int(math.sin(rad) * 6)),
                   (112 - int(math.cos(rad) * 14), 80 + int(math.sin(rad) * 14))], fill=(240, 140, 30, 255), width=2)

    # Scorpion Frame 0 (X=128, Y=64)
    # Long segmented poisonous crawler with raised stinger
    draw.ellipse((136, 78, 152, 88), fill=(220, 40, 80, 255), outline=(110, 10, 30, 255), width=2)
    # Pincers
    draw.line([(136, 82), (130, 78)], fill=(255, 180, 40, 255), width=2)
    draw.line([(136, 86), (130, 90)], fill=(255, 180, 40, 255), width=2)
    # Tail arching up
    draw.line([(152, 83), (157, 76), (155, 70), (149, 72)], fill=(255, 200, 40, 255), width=2)

    # Scorpion Frame 1 (X=160, Y=64)
    draw.ellipse((168, 78, 184, 88), fill=(220, 40, 80, 255), outline=(110, 10, 30, 255), width=2)
    draw.line([(168, 80), (162, 82)], fill=(255, 180, 40, 255), width=2)
    draw.line([(168, 86), (162, 84)], fill=(255, 180, 40, 255), width=2)
    draw.line([(184, 83), (189, 78), (188, 68), (182, 70)], fill=(255, 200, 40, 255), width=2)

    # -------------------------------------------------------------
    # Row 3 (Y=96): Power-up Orbs / Capsules
    # -------------------------------------------------------------

    def draw_orb(ox: int, oy: int, base_col: tuple[int, int, int], symbol: str) -> None:
        draw.ellipse((ox + 4, oy + 4, ox + 28, oy + 28), fill=(*base_col, 220), outline=(255, 255, 255, 255), width=2)
        draw.ellipse((ox + 8, oy + 8, ox + 14, oy + 14), fill=(255, 255, 255, 180))

    draw_orb(0, 96, (235, 50, 50), "R")    # Rapid Fire
    draw_orb(32, 96, (255, 140, 30), "T")  # Triple Spread
    draw_orb(64, 96, (40, 200, 255), "P")  # Plasma Beam
    draw_orb(96, 96, (255, 215, 0), "E")   # EMP Nuke
    draw_orb(128, 96, (60, 120, 255), "S") # Shield
    draw_orb(160, 96, (50, 230, 100), "D") # Speed Dash

    out_path = root / "assets" / "sprites" / "centipede.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")


if __name__ == "__main__":
    main()
