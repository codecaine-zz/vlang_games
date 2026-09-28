#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Connect 4:
Cell dimensions: 96x96

Row 0 (Y=0..95):   1: Red Disc, 2: Yellow Disc, 3: Empty Cell Hole, 4: Grid Frame Segment
Row 1 (Y=96..191): 1: Red Disc Highlighted (Win Ring), 2: Yellow Disc Highlighted (Win Ring), 3: Golden Crown, 4: AI Robot Icon
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 96


def draw_red_disc(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_win: bool = False) -> None:
    cx, cy = ox + C // 2, oy + C // 2
    r = 42

    # Drop Shadow
    draw.ellipse((cx - r + 3, cy - r + 5, cx + r + 3, cy + r + 5), fill=(10, 15, 30, 160))

    # Outer Rim (Dark Burgundy)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(153, 27, 27, 255), outline=(127, 29, 29, 255), width=3)
    # Inner Bevel (Vibrant Crimson)
    draw.ellipse((cx - r + 4, cy - r + 4, cx + r - 4, cy + r - 4), fill=(220, 38, 38, 255))
    # Concentric Grooves
    draw.ellipse((cx - r + 12, cy - r + 12, cx + r - 12, cy + r - 12), outline=(185, 28, 28, 255), width=3)
    draw.ellipse((cx - r + 22, cy - r + 22, cx + r - 22, cy + r - 22), fill=(239, 68, 68, 255), outline=(153, 27, 27, 255), width=2)
    # Specular Glass Highlight
    draw.ellipse((cx - r + 10, cy - r + 8, cx - r + 28, cy - r + 22), fill=(254, 202, 202, 220))
    draw.ellipse((cx - r + 14, cy - r + 10, cx - r + 22, cy - r + 16), fill=(255, 255, 255, 255))

    if is_win:
        # Pulsing Gold Aura Ring
        draw.ellipse((cx - r - 3, cy - r - 3, cx + r + 3, cy + r + 3), outline=(250, 204, 21, 255), width=5)


def draw_yellow_disc(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_win: bool = False) -> None:
    cx, cy = ox + C // 2, oy + C // 2
    r = 42

    # Drop Shadow
    draw.ellipse((cx - r + 3, cy - r + 5, cx + r + 3, cy + r + 5), fill=(10, 15, 30, 160))

    # Outer Rim (Dark Amber)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(180, 83, 9, 255), outline=(146, 64, 14, 255), width=3)
    # Inner Bevel (Golden Yellow)
    draw.ellipse((cx - r + 4, cy - r + 4, cx + r - 4, cy + r - 4), fill=(234, 179, 8, 255))
    # Concentric Grooves
    draw.ellipse((cx - r + 12, cy - r + 12, cx + r - 12, cy + r - 12), outline=(202, 138, 4, 255), width=3)
    draw.ellipse((cx - r + 22, cy - r + 22, cx + r - 22, cy + r - 22), fill=(250, 204, 21, 255), outline=(180, 83, 9, 255), width=2)
    # Specular Glass Highlight
    draw.ellipse((cx - r + 10, cy - r + 8, cx - r + 28, cy - r + 22), fill=(254, 240, 138, 220))
    draw.ellipse((cx - r + 14, cy - r + 10, cx - r + 22, cy - r + 16), fill=(255, 255, 255, 255))

    if is_win:
        draw.ellipse((cx - r - 3, cy - r - 3, cx + r + 3, cy + r + 3), outline=(255, 255, 255, 255), width=5)


def draw_grid_slot(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Royal Blue Connect 4 Cabinet Mesh Slot with circular cutout
    draw.rectangle((ox, oy, ox + C, oy + C), fill=(29, 78, 216, 255), outline=(30, 58, 138, 255), width=3)
    # Beveled Inner Ring Cutout
    cx, cy = ox + C // 2, oy + C // 2
    r = 42
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(15, 23, 42, 255), outline=(37, 99, 235, 255), width=4)


def draw_crown(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + C // 2, oy + C // 2
    # Golden Victory Crown
    draw.polygon([(cx - 24, cy + 14), (cx + 24, cy + 14), (cx + 28, cy - 14), (cx + 12, cy - 2), (cx, cy - 18), (cx - 12, cy - 2), (cx - 28, cy - 14)], fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=3)
    # Jewels
    draw.ellipse((cx - 30, cy - 18, cx - 24, cy - 12), fill=(239, 68, 68, 255))
    draw.ellipse((cx - 3, cy - 22, cx + 3, cy - 16), fill=(6, 182, 212, 255))
    draw.ellipse((cx + 24, cy - 18, cx + 30, cy - 12), fill=(239, 68, 68, 255))


def draw_robot(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + C // 2, oy + C // 2
    # AI Opponent Cyber Robot Avatar
    draw.rectangle((cx - 20, cy - 16, cx + 20, cy + 16), fill=(71, 85, 105, 255), outline=(148, 163, 184, 255), width=3)
    # Antenna
    draw.line([(cx, cy - 16), (cx, cy - 26)], fill=(148, 163, 184, 255), width=3)
    draw.ellipse((cx - 4, cy - 32, cx + 4, cy - 24), fill=(239, 68, 68, 255))
    # Glowing Cyan Visor
    draw.rectangle((cx - 14, cy - 8, cx + 14, cy + 2), fill=(6, 182, 212, 255))
    # Speaker mouth
    draw.rectangle((cx - 10, cy + 8, cx + 10, cy + 12), fill=(15, 23, 42, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Basic Discs & Grid Slot
    draw_red_disc(draw, 0 * C, 0 * C, is_win=False)
    draw_yellow_disc(draw, 1 * C, 0 * C, is_win=False)
    draw_grid_slot(draw, 2 * C, 0 * C)

    # Row 1: Win Glowing Discs & Icons
    draw_red_disc(draw, 0 * C, 1 * C, is_win=True)
    draw_yellow_disc(draw, 1 * C, 1 * C, is_win=True)
    draw_crown(draw, 2 * C, 1 * C)
    draw_robot(draw, 3 * C, 1 * C)

    out_path = root / "assets" / "sprites" / "connect4.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "connect4" / "assets" / "sprites" / "connect4.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
