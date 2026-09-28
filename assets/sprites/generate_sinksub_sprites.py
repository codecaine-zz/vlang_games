#!/usr/bin/env python3
"""Generate high-fidelity 512x512 RGBA sprite sheet for SinkSub Naval Destroyer & Submarine Warfare:
- Player Surface Warship (Destroyer: Hull, Superstructure, Radar, Cannon, Shield Variant, Damaged Variant)
- Submarines: Standard (Gray), Fast (Cyan), Heavy (Amber), Boss Leviathan (Magenta)
- Projectiles: Depth Charges, Torpedoes with fins, Spiked Sea Mines with diodes
- Supply Crates: Shield (Cyan), Triple (Indigo), Hyper (Amber), Tactical Nuke (Red)
- Naval FX: Bubbles, Splash, Water Ring
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_destroyer(draw: ImageDraw.ImageDraw, ox: int, oy: int, w: int = 88, h: int = 28, is_damaged: bool = False) -> None:
    # Main Warship Hull (Steel Slate Gray)
    hull_col = (40, 50, 70) if not is_damaged else (60, 45, 45)
    hull_pts = [
        (ox + 4, oy + 12),
        (ox + w - 8, oy + 12),
        (ox + w, oy + 18),
        (ox + w - 10, oy + h),
        (ox + 8, oy + h),
        (ox, oy + 20),
    ]
    draw.polygon(hull_pts, fill=(*hull_col, 255), outline=(148, 163, 184, 255))

    # Bevel Top deck
    draw.line([(ox + 6, oy + 13), (ox + w - 8, oy + 13)], fill=(203, 213, 225, 255), width=2)

    # Navy Yellow / Blue Identification Stripe
    stripe_col = (245, 158, 11) if not is_damaged else (239, 68, 68)
    draw.rectangle((ox + w // 2 - 6, oy + 14, ox + w // 2 + 6, oy + h - 2), fill=(*stripe_col, 255), outline=(30, 58, 138, 255))

    # Superstructure Cabin / Bridge
    draw.rectangle((ox + w // 4, oy + 2, ox + w // 2 + 10, oy + 12), fill=(30, 41, 59, 255), outline=(100, 116, 139, 255))
    # Bridge Windows (Cyan glow)
    for win_i in range(3):
        wx = ox + w // 4 + 4 + win_i * 8
        draw.rectangle((wx, oy + 5, wx + 5, oy + 8), fill=(34, 211, 238, 240))

    # Radar Mast & Antenna Dish
    draw.line([(ox + w // 3 + 4, oy), (ox + w // 3 + 4, oy + 4)], fill=(34, 211, 238, 255), width=2)
    draw.ellipse((ox + w // 3 + 1, oy - 4, ox + w // 3 + 7, oy + 2), fill=(34, 211, 238, 255))

    # Bow Heavy Cannon Turret
    draw.rectangle((ox + w - 22, oy + 8, ox + w - 12, oy + 12), fill=(15, 23, 42, 255), outline=(100, 116, 139, 255))
    draw.line([(ox + w - 12, oy + 9), (ox + w - 3, oy + 7)], fill=(15, 23, 42, 255), width=3)

    # Depth Charge Stern Launch Rack
    draw.rectangle((ox + 4, oy + 8, ox + 14, oy + 12), fill=(220, 38, 38, 255), outline=(185, 28, 28, 255))
    draw.rectangle((ox + 6, oy + 6, ox + 10, oy + 8), fill=(245, 158, 11, 255))


def draw_sub(draw: ImageDraw.ImageDraw, ox: int, oy: int, w: int, h: int, main_col: tuple[int, int, int], trim_col: tuple[int, int, int], is_boss: bool = False) -> None:
    # Streamlined Submarine Hull Capsule
    draw.ellipse((ox + 4, oy + 4, ox + w - 4, oy + h - 4), fill=(*main_col, 255), outline=(*trim_col, 255), width=2)

    # Conning Tower / Sail
    tower_w = max(12, w // 5)
    tower_h = 8 if not is_boss else 12
    draw.rectangle((ox + w // 2 - tower_w // 2, oy - (tower_h - 6), ox + w // 2 + tower_w // 2, oy + 6), fill=(*main_col, 255), outline=(*trim_col, 255), width=2)

    # Periscope Mast
    draw.line([(ox + w // 2 + 2, oy - tower_h), (ox + w // 2 + 2, oy)], fill=(203, 213, 225, 255), width=2)
    draw.line([(ox + w // 2 + 2, oy - tower_h), (ox + w // 2 + 6, oy - tower_h)], fill=(203, 213, 225, 255), width=2)

    # Lit Portholes / Observation Nodes
    num_ports = max(3, w // 18)
    for p in range(num_ports):
        px = ox + 16 + p * (w - 32) // (num_ports - 1 if num_ports > 1 else 1)
        port_col = (250, 204, 21) if not is_boss else (244, 114, 182)
        draw.ellipse((px - 2, oy + h // 2 - 2, px + 2, oy + h // 2 + 2), fill=(*port_col, 255))

    # Bow Active Sonar Array Dome
    dome_col = (34, 211, 238) if not is_boss else (239, 68, 68)
    draw.chord((ox + w - 14, oy + 6, ox + w - 2, oy + h - 6), start=270, end=90, fill=(*dome_col, 220), outline=(255, 255, 255, 200))

    # Stern Propulsion Fins & Screws
    draw.polygon([(ox + 10, oy + 2), (ox + 2, oy + h // 2), (ox + 10, oy + h - 2)], fill=(*trim_col, 255))
    draw.rectangle((ox, oy + h // 2 - 4, ox + 4, oy + h // 2 + 4), fill=(148, 163, 184, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0 (Y=0..63): Surface Warships (Normal, Shielded, Damaged)
    # -------------------------------------------------------------
    # Player Destroyer Normal (X=4, Y=16, 88x28)
    draw_destroyer(draw, 4, 16, w=88, h=28, is_damaged=False)

    # Player Destroyer Shielded (X=110, Y=16, 96x32 with aura)
    draw.ellipse((100, 2, 216, 58), fill=(34, 211, 238, 45), outline=(34, 211, 238, 210), width=2)
    draw.ellipse((104, 6, 212, 54), fill=(34, 211, 238, 25), outline=(100, 240, 255, 180), width=1)
    draw_destroyer(draw, 114, 16, w=88, h=28, is_damaged=False)

    # Player Destroyer Damaged (X=230, Y=16, 88x28)
    draw_destroyer(draw, 230, 16, w=88, h=28, is_damaged=True)

    # -------------------------------------------------------------
    # Row 1 (Y=64..127): Submarines (Standard, Fast, Heavy, Boss)
    # -------------------------------------------------------------
    # Standard U-Boat (X=4, Y=76, 68x22) - Slate Gray
    draw_sub(draw, 4, 76, w=68, h=22, main_col=(100, 116, 139), trim_col=(148, 163, 184))

    # Fast Torpedo Sub (X=84, Y=78, 60x18) - Cyan Hunter
    draw_sub(draw, 84, 78, w=60, h=18, main_col=(6, 182, 212), trim_col=(34, 211, 238))

    # Heavy Armored Sub (X=164, Y=72, 84x26) - Amber Gold
    draw_sub(draw, 164, 72, w=84, h=26, main_col=(217, 119, 6), trim_col=(251, 191, 36))

    # Boss Leviathan Dreadnought (X=264, Y=66, 108x34) - Magenta Dreadnought
    draw_sub(draw, 264, 66, w=108, h=34, main_col=(162, 28, 175), trim_col=(244, 114, 182), is_boss=True)

    # -------------------------------------------------------------
    # Row 2 (Y=128..159): Projectiles & Mines (32x32 cells)
    # -------------------------------------------------------------
    # Depth Charge (X=0, Y=128, 32x32)
    draw.rectangle((8, 134, 24, 154), fill=(71, 85, 105, 255), outline=(220, 38, 38, 255), width=2)
    draw.line([(10, 144), (22, 144)], fill=(245, 158, 11, 255), width=2)
    draw.ellipse((13, 136, 19, 140), fill=(239, 68, 68, 255)) # Fuse diode

    # Torpedo (X=32, Y=128, 32x32)
    draw.ellipse((36, 140, 60, 148), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255), width=1)
    draw.polygon([(36, 138), (40, 144), (36, 150)], fill=(245, 158, 11, 255)) # Stern Fins
    draw.ellipse((55, 142, 60, 146), fill=(255, 255, 255, 240)) # Warhead nose

    # Naval Contact Mine (X=64, Y=128, 32x32)
    draw.ellipse((68, 132, 92, 156), fill=(30, 41, 59, 255), outline=(100, 116, 139, 255), width=2)
    for angle_deg in [0, 45, 90, 135, 180, 225, 270, 315]:
        rad = math.radians(angle_deg)
        cx, cy = 80, 144
        x1 = cx + int(math.cos(rad) * 11)
        y1 = cy + int(math.sin(rad) * 11)
        x2 = cx + int(math.cos(rad) * 16)
        y2 = cy + int(math.sin(rad) * 16)
        draw.line([(x1, y1), (x2, y2)], fill=(239, 68, 68, 255), width=2)
    draw.ellipse((77, 141, 83, 147), fill=(239, 68, 68, 255))

    # Water Explosion Blast Frame (X=96, Y=128, 32x32)
    draw.ellipse((98, 130, 126, 158), fill=(255, 200, 50, 200), outline=(255, 80, 20, 255), width=2)
    draw.ellipse((104, 136, 120, 152), fill=(255, 255, 255, 240))

    # -------------------------------------------------------------
    # Row 3 (Y=160..191): Supply Crates (32x32 cells)
    # -------------------------------------------------------------
    crates = [
        ("shield", (34, 211, 238), "S"),
        ("triple", (99, 102, 241), "3"),
        ("hyper", (245, 158, 11), "H"),
        ("nuke", (239, 68, 68), "N"),
    ]
    for c_idx, (c_name, c_col, c_char) in enumerate(crates):
        ox = c_idx * 32
        oy = 160
        draw.rectangle((ox + 4, oy + 4, ox + 28, oy + 28), fill=(*c_col, 255), outline=(255, 255, 255, 220), width=2)
        draw.line([(ox + 6, oy + 6), (ox + 26, oy + 26)], fill=(255, 255, 255, 120), width=1)
        draw.line([(ox + 26, oy + 6), (ox + 6, oy + 26)], fill=(255, 255, 255, 120), width=1)

    # -------------------------------------------------------------
    # Row 4 (Y=192..223): Underwater Bubbles & Sonar Rings
    # -------------------------------------------------------------
    # Bubbles (X=0, Y=192, 32x32)
    for bx, by, br in [(8, 204, 4), (18, 198, 6), (24, 212, 3), (12, 216, 5)]:
        draw.ellipse((bx - br, by - br, bx + br, by + br), fill=(200, 240, 255, 120), outline=(255, 255, 255, 220), width=1)

    # Sonar Ping Wave (X=32, Y=192, 32x32)
    draw.ellipse((36, 196, 60, 220), outline=(34, 211, 238, 200), width=2)
    draw.ellipse((42, 202, 54, 214), outline=(34, 211, 238, 140), width=1)

    out_path = root / "assets" / "sprites" / "sinksub.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    # Also sync to sinksub local assets if needed
    local_path = root / "sinksub" / "assets" / "sprites" / "sinksub.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
