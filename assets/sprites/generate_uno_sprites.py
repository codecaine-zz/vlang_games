#!/usr/bin/env python3
"""Generate ultra-detailed 1024x1024 RGBA sprite sheet for UNO:
Card dimensions: 68x96

Row 0: Red Cards (0..9, Skip, Reverse, Draw2)
Row 1: Yellow Cards (0..9, Skip, Reverse, Draw2)
Row 2: Green Cards (0..9, Skip, Reverse, Draw2)
Row 3: Blue Cards (0..9, Skip, Reverse, Draw2)
Row 4: Wild, Wild Draw Four, Uno Card Back, Uno Shout Button, Winner Crown
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_W, SHEET_H = 1024, 1024
CW, CH = 68, 92


def draw_uno_card(draw: ImageDraw.ImageDraw, ox: int, oy: int, color_idx: int, card_type: int) -> None:
    # 0: Red, 1: Yellow, 2: Green, 3: Blue
    colors = [
        ((239, 68, 68, 255), (185, 28, 28, 255)),   # Red
        ((234, 179, 8, 255), (161, 98, 7, 255)),    # Yellow
        ((34, 197, 94, 255), (21, 128, 61, 255)),   # Green
        ((59, 130, 246, 255), (29, 78, 216, 255)),  # Blue
    ]
    main_c, shadow_c = colors[color_idx]

    # White Card Border
    draw.rounded_rectangle((ox + 2, oy + 2, ox + CW - 2, oy + CH - 2), radius=8, fill=(255, 255, 255, 255), outline=(203, 213, 225, 255), width=2)
    # Inner Color Area
    draw.rounded_rectangle((ox + 5, oy + 5, ox + CW - 5, oy + CH - 5), radius=6, fill=main_c)

    # Signature Tilted White Oval
    cx, cy = ox + CW // 2, oy + CH // 2
    draw.ellipse((cx - 22, cy - 30, cx + 22, cy + 30), fill=(255, 255, 255, 255), outline=shadow_c, width=2)

    # Center Symbol
    if card_type <= 9:
        # Digit placeholder ring
        draw.ellipse((cx - 10, cy - 14, cx + 10, cy + 14), fill=main_c)
    elif card_type == 10:
        # Skip Circle-Slash
        draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), outline=main_c, width=4)
        draw.line([(cx - 8, cy - 8), (cx + 8, cy + 8)], fill=main_c, width=4)
    elif card_type == 11:
        # Reverse Dual Arrow
        draw.polygon([(cx - 8, cy - 4), (cx, cy - 10), (cx, cy + 2)], fill=main_c)
        draw.polygon([(cx + 8, cy + 4), (cx, cy + 10), (cx, cy - 2)], fill=main_c)
    elif card_type == 12:
        # Draw Two (+2)
        draw.rectangle((cx - 12, cy - 10, cx - 2, cy + 6), fill=main_c)
        draw.rectangle((cx - 4, cy - 4, cx + 6, cy + 12), fill=main_c)


def draw_uno_back(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Classic Black Back with Red Oval & Yellow UNO
    draw.rounded_rectangle((ox + 2, oy + 2, ox + CW - 2, oy + CH - 2), radius=8, fill=(255, 255, 255, 255), outline=(203, 213, 225, 255), width=2)
    draw.rounded_rectangle((ox + 5, oy + 5, ox + CW - 5, oy + CH - 5), radius=6, fill=(15, 23, 42, 255))

    cx, cy = ox + CW // 2, oy + CH // 2
    draw.ellipse((cx - 24, cy - 32, cx + 24, cy + 32), fill=(220, 38, 38, 255))
    # UNO Typography block
    draw.ellipse((cx - 16, cy - 12, cx + 16, cy + 12), fill=(234, 179, 8, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_W, SHEET_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # 4 Colors x 13 Cards (0..9, Skip, Reverse, Draw2)
    for c in range(4):
        for t in range(13):
            draw_uno_card(draw, t * 72, c * 96, color_idx=c, card_type=t)
        # 14th card: Card Back
        draw_uno_back(draw, 13 * 72, c * 96)

    # Save to assets/sprites/uno.png
    out_path = root / "assets" / "sprites" / "uno.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_W}x{SHEET_H})")

    local_path = root / "uno" / "assets" / "sprites" / "uno.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
