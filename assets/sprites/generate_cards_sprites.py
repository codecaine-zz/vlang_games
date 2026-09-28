#!/usr/bin/env python3
"""Generate ultra-detailed 1024x1024 RGBA sprite sheet for Playing Cards & Casino Games (War, Texas Hold'em, Blackjack):

Card Cell Size: 72x96 (W x H)
Grid:
Row 0: Hearts (A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K, BackRed)
Row 1: Diamonds (A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K, BackBlue)
Row 2: Clubs (A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K, Joker)
Row 3: Spades (A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K, GoldCrown)
Row 4 (Y=400..): Casino Chips (White $1, Red $5, Green $25, Black $100, Purple $500, Dealer Button, War Swords)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SHEET_W, SHEET_H = 1024, 1024
CW, CH = 68, 92  # Card dimensions


def draw_suit_icon(draw: ImageDraw.ImageDraw, cx: int, cy: int, suit: int, r: int = 8) -> None:
    # 0: Hearts, 1: Diamonds, 2: Clubs, 3: Spades
    if suit == 0:
        # Heart
        draw.polygon([(cx, cy + r), (cx - r, cy - r // 4), (cx - r // 2, cy - r), (cx, cy - r // 2), (cx + r // 2, cy - r), (cx + r, cy - r // 4)], fill=(220, 38, 38, 255))
    elif suit == 1:
        # Diamond
        draw.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=(220, 38, 38, 255))
    elif suit == 2:
        # Club
        draw.ellipse((cx - r // 2, cy - r, cx + r // 2, cy), fill=(15, 23, 42, 255))
        draw.ellipse((cx - r, cy - r // 2, cx, cy + r // 2), fill=(15, 23, 42, 255))
        draw.ellipse((cx, cy - r // 2, cx + r, cy + r // 2), fill=(15, 23, 42, 255))
        draw.polygon([(cx, cy), (cx - r // 4, cy + r), (cx + r // 4, cy + r)], fill=(15, 23, 42, 255))
    else:
        # Spade
        draw.polygon([(cx, cy - r), (cx - r, cy + r // 4), (cx - r // 2, cy + r // 2), (cx, cy + r // 4), (cx + r // 2, cy + r // 2), (cx + r, cy + r // 4)], fill=(15, 23, 42, 255))
        draw.polygon([(cx, cy), (cx - r // 4, cy + r), (cx + r // 4, cy + r)], fill=(15, 23, 42, 255))


def draw_card(draw: ImageDraw.ImageDraw, ox: int, oy: int, suit: int, rank_idx: int) -> None:
    # Card Background (Ivory white with subtle border)
    draw.rounded_rectangle((ox + 2, oy + 2, ox + CW - 2, oy + CH - 2), radius=6, fill=(255, 255, 255, 255), outline=(203, 213, 225, 255), width=2)

    rank_str = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"][rank_idx]
    is_red = suit in (0, 1)
    text_col = (220, 38, 38, 255) if is_red else (15, 23, 42, 255)

    # Top-Left Rank & Small Suit
    draw_suit_icon(draw, ox + 14, oy + 24, suit, r=5)
    # Center Big Suit or Court Graphic
    draw_suit_icon(draw, ox + CW // 2, oy + CH // 2, suit, r=14)
    # Bottom-Right Inverted Small Suit
    draw_suit_icon(draw, ox + CW - 14, oy + CH - 24, suit, r=5)


def draw_card_back(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_red: bool = True) -> None:
    bg_col = (185, 28, 28, 255) if is_red else (29, 78, 216, 255)
    inner_col = (153, 27, 27, 255) if is_red else (30, 58, 138, 255)

    draw.rounded_rectangle((ox + 2, oy + 2, ox + CW - 2, oy + CH - 2), radius=6, fill=(255, 255, 255, 255), outline=(203, 213, 225, 255), width=2)
    draw.rounded_rectangle((ox + 5, oy + 5, ox + CW - 5, oy + CH - 5), radius=4, fill=bg_col)

    # Lattice Diamond pattern
    for y in range(oy + 10, oy + CH - 10, 8):
        for x in range(ox + 10, ox + CW - 10, 8):
            draw.polygon([(x + 4, y), (x + 8, y + 4), (x + 4, y + 8), (x, y + 4)], fill=inner_col)


def draw_chip(draw: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int, int], label: str) -> None:
    r = 28
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color, outline=(255, 255, 255, 255), width=3)
    # Dashed perimeter rim
    for a in range(0, 360, 45):
        rad = math.radians(a)
        x1 = cx + math.cos(rad) * (r - 2)
        y1 = cy + math.sin(rad) * (r - 2)
        x2 = cx + math.cos(rad) * (r - 8)
        y2 = cy + math.sin(rad) * (r - 8)
        draw.line([(x1, y1), (x2, y2)], fill=(255, 255, 255, 255), width=3)
    # Center Inset
    draw.ellipse((cx - 16, cy - 16, cx + 16, cy + 16), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_W, SHEET_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # 4 Suits x 13 Ranks
    for s in range(4):
        for r in range(13):
            draw_card(draw, r * 72, s * 96, suit=s, rank_idx=r)
        # 14th card: Card Back
        draw_card_back(draw, 13 * 72, s * 96, is_red=(s % 2 == 0))

    # Row 4: Casino Chips (White $1, Red $5, Green $25, Black $100, Purple $500, Dealer Button)
    chips = [
        ((226, 232, 240, 255), "1"),
        ((220, 38, 38, 255), "5"),
        ((22, 163, 74, 255), "25"),
        ((30, 41, 59, 255), "100"),
        ((147, 51, 234, 255), "500"),
        ((245, 158, 11, 255), "D"),
    ]
    for i, (col, lbl) in enumerate(chips):
        draw_chip(draw, 40 + i * 80, 440, col, lbl)

    # Save to shared and game directories
    out_path = root / "assets" / "sprites" / "cards.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_W}x{SHEET_H})")

    for g in ["war", "texas", "blackjack"]:
        g_path = root / g / "assets" / "sprites" / "cards.png"
        g_path.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(g_path, format="PNG")


if __name__ == "__main__":
    main()
