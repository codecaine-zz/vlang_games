#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Cyber Simon Arcade Console:
Grid: 64x64 cells (8x8 grid of sprites)

Row 0 (Y=0..63):    Glowing Quadrant Pad Lenses (Green Lit, Red Lit, Yellow Lit, Blue Lit)
Row 1 (Y=64..127):  Console Hardware (Center Gold Badge, Power Switch On, Strict Switch Red, Speed Dial)
Row 2 (Y=128..191): Trophies & Badges (Gold Trophy, Silver Star, Neon Memory Brain, Victory Ribbon)
Row 3 (Y=192..255): 7-Segment LED Numbers (0..7)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 64  # cell size


def draw_neon_lens(draw: ImageDraw.ImageDraw, ox: int, oy: int, color_type: str = "green") -> None:
    cx, cy = ox + 32, oy + 32
    colors = {
        "green": ((34, 197, 94, 255), (187, 247, 208, 255)),
        "red": ((239, 68, 68, 255), (254, 202, 202, 255)),
        "yellow": ((234, 179, 8, 255), (254, 240, 138, 255)),
        "blue": ((59, 130, 246, 255), (191, 219, 254, 255)),
    }
    main_c, high_c = colors.get(color_type, colors["green"])

    # Radial Glowing Lens
    for r in range(26, 6, -4):
        alpha = int(120 + (26 - r) * 6)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(main_c[0], main_c[1], main_c[2], alpha))

    # Bright Hot Glass Core
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=high_c)
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 255, 255, 255))


def draw_console_hardware(draw: ImageDraw.ImageDraw, ox: int, oy: int, hw_type: str = "badge") -> None:
    cx, cy = ox + 32, oy + 32
    if hw_type == "badge":
        # Center Gold Cyber Simon Crest
        draw.ellipse((cx - 24, cy - 24, cx + 24, cy + 24), fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=3)
        draw.ellipse((cx - 18, cy - 18, cx + 18, cy + 18), fill=(30, 41, 59, 255), outline=(254, 240, 138, 255), width=2)
        # Inner 'S' Logo
        draw.text((cx - 6, cy - 12), "S", fill=(250, 204, 21, 255))
    elif hw_type == "switch_on":
        # Rocker Switch (Glowing Blue)
        draw.rectangle((cx - 14, cy - 22, cx + 14, cy + 22), fill=(15, 23, 42, 255), outline=(100, 116, 139, 255), width=2)
        draw.rectangle((cx - 10, cy - 18, cx + 10, cy - 2), fill=(6, 182, 212, 255))
        draw.text((cx - 6, cy - 14), "I", fill=(255, 255, 255, 255))
    elif hw_type == "switch_strict":
        # Strict Mode Switch (Glowing Red)
        draw.rectangle((cx - 14, cy - 22, cx + 14, cy + 22), fill=(15, 23, 42, 255), outline=(100, 116, 139, 255), width=2)
        draw.rectangle((cx - 10, cy - 18, cx + 10, cy - 2), fill=(239, 68, 68, 255))
        draw.text((cx - 8, cy - 14), "!", fill=(255, 255, 255, 255))
    elif hw_type == "dial":
        # Metallic Rotary Potentiometer Knob
        draw.ellipse((cx - 20, cy - 20, cx + 20, cy + 20), fill=(71, 85, 105, 255), outline=(30, 41, 59, 255), width=2)
        draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(148, 163, 184, 255))
        draw.line([(cx, cy), (cx + 10, cy - 10)], fill=(239, 68, 68, 255), width=3)


def draw_trophy(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 32, oy + 32
    # Gold Cup Body
    draw.polygon([(cx - 16, cy - 16), (cx + 16, cy - 16), (cx + 10, cy + 6), (cx - 10, cy + 6)], fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=2)
    # Handles
    draw.line([(cx - 16, cy - 12), (cx - 24, cy - 6), (cx - 14, cy + 2)], fill=(234, 179, 8, 255), width=2)
    draw.line([(cx + 16, cy - 12), (cx + 24, cy - 6), (cx + 14, cy + 2)], fill=(234, 179, 8, 255), width=2)
    # Stem & Base
    draw.rectangle((cx - 4, cy + 6, cx + 4, cy + 16), fill=(161, 98, 7, 255))
    draw.rectangle((cx - 14, cy + 16, cx + 14, cy + 22), fill=(100, 116, 139, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Glowing Quadrant Lenses
    draw_neon_lens(draw, 0 * C, 0, color_type="green")
    draw_neon_lens(draw, 1 * C, 0, color_type="red")
    draw_neon_lens(draw, 2 * C, 0, color_type="yellow")
    draw_neon_lens(draw, 3 * C, 0, color_type="blue")

    # Row 1: Console Hardware
    draw_console_hardware(draw, 0 * C, 1 * C, hw_type="badge")
    draw_console_hardware(draw, 1 * C, 1 * C, hw_type="switch_on")
    draw_console_hardware(draw, 2 * C, 1 * C, hw_type="switch_strict")
    draw_console_hardware(draw, 3 * C, 1 * C, hw_type="dial")

    # Row 2: Trophy
    draw_trophy(draw, 0 * C, 2 * C)

    out_path = root / "assets" / "sprites" / "simon.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "simon" / "assets" / "sprites" / "simon.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
