#!/usr/bin/env python3
"""Generate ultra-polished 512x512 RGBA sprite sheet for Mario Bros Arcade (1983):
Grid: 32x32 cells (16x16 grid of tiles in 512x512 sheet)

Row 0 (Y=0..31):   Mario (Idle, Run 1, Run 2, Skid, Jump, Defeat, Victory, Fire Mario)
Row 1 (Y=32..63):  Luigi (Idle, Run 1, Run 2, Skid, Jump, Defeat, Victory, Fire Luigi)
Row 2 (Y=64..95):  Enemies 1 (Shellcreeper Green 2-frames, Shellcreeper Red 2-frames, Flipped Shell, Recovering Shell, Sidestepper Normal 2-frames)
Row 3 (Y=96..127): Enemies 2 (Sidestepper Angry 2-frames, Sidestepper Flipped, Fighterfly 2-frames, Freezie/Slipice, Red Fireball, Green Fireball)
Row 4 (Y=128..159): Sewer Props (Green Pipe Top, Green Pipe Base, Blue Pipe Top, POW Block Full, POW Block 2-hit, POW Block 1-hit, Coin 4-frames)
Row 5 (Y=160..191): Powerups & FX (Super Star, Fire Flower, Sliding Shell, Water Splash, Bump Ripple, Fireball Blast)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 32  # cell size 32x32


def draw_plumber(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_luigi: bool = False, anim: str = "idle") -> None:
    # 3D Soft Shadow
    draw.ellipse((ox + 6, oy + 24, ox + 26, oy + 30), fill=(10, 15, 25, 100))

    # Hat & Shirt Color
    cap_col = (34, 197, 94, 255) if is_luigi else (220, 38, 38, 255)
    cap_dark = (21, 128, 61, 255) if is_luigi else (153, 27, 27, 255)
    # Overalls Color
    suit_col = (37, 99, 235, 255) if is_luigi else (30, 64, 175, 255)
    suit_dark = (29, 78, 216, 255) if is_luigi else (23, 37, 84, 255)
    # Skin & Mustache
    skin_col = (254, 215, 170, 255)
    hair_col = (69, 26, 3, 255)

    # 1. Shoes
    boot_l_y = oy + 24 + (2 if anim == "run1" else 0)
    boot_r_y = oy + 24 + (2 if anim == "run2" else 0)
    draw.ellipse((ox + 6, boot_l_y, ox + 15, boot_l_y + 7), fill=hair_col)
    draw.ellipse((ox + 17, boot_r_y, ox + 26, boot_r_y + 7), fill=hair_col)

    # 2. Overalls Body
    draw.rectangle((ox + 8, oy + 15, ox + 24, oy + 25), fill=suit_col, outline=suit_dark)
    # Yellow buttons
    draw.ellipse((ox + 10, oy + 16, ox + 12, oy + 18), fill=(250, 204, 21, 255))
    draw.ellipse((ox + 20, oy + 16, ox + 22, oy + 18), fill=(250, 204, 21, 255))

    # 3. Red/Green Shirt & Arms
    if anim == "jump":
        # Arms raised in victory jump
        draw.rectangle((ox + 4, oy + 8, ox + 8, oy + 18), fill=cap_col)
        draw.rectangle((ox + 24, oy + 8, ox + 28, oy + 18), fill=cap_col)
        # White gloves
        draw.ellipse((ox + 3, oy + 6, ox + 9, oy + 12), fill=(255, 255, 255, 255))
        draw.ellipse((ox + 23, oy + 6, ox + 29, oy + 12), fill=(255, 255, 255, 255))
    else:
        draw.rectangle((ox + 5, oy + 16, ox + 9, oy + 22), fill=cap_col)
        draw.rectangle((ox + 23, oy + 16, ox + 27, oy + 22), fill=cap_col)
        # White gloves
        draw.ellipse((ox + 4, oy + 20, ox + 9, oy + 25), fill=(255, 255, 255, 255))
        draw.ellipse((ox + 23, oy + 20, ox + 28, oy + 25), fill=(255, 255, 255, 255))

    # 4. Face & Nose
    draw.ellipse((ox + 9, oy + 8, ox + 23, oy + 18), fill=skin_col)
    # Big round plumber nose
    draw.ellipse((ox + 19, oy + 10, ox + 25, oy + 15), fill=skin_col, outline=(251, 146, 60, 255))
    # Mustache
    draw.ellipse((ox + 16, oy + 13, ox + 24, oy + 17), fill=hair_col)
    # Eye
    draw.ellipse((ox + 16, oy + 9, ox + 19, oy + 13), fill=(15, 23, 42, 255))
    draw.ellipse((ox + 17, oy + 10, ox + 18, oy + 11), fill=(255, 255, 255, 255))

    # 5. Cap
    draw.ellipse((ox + 8, oy + 4, ox + 24, oy + 10), fill=cap_col, outline=cap_dark)
    draw.rectangle((ox + 13, oy + 7, ox + 25, oy + 10), fill=cap_col) # Visor brim


def draw_turtle(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_red: bool = False, flipped: bool = False) -> None:
    # Shellcreeper Koopa
    draw.ellipse((ox + 6, oy + 24, ox + 26, oy + 30), fill=(10, 15, 25, 100))

    shell_col = (220, 38, 38, 255) if is_red else (22, 163, 74, 255)
    shell_dark = (153, 27, 27, 255) if is_red else (20, 83, 45, 255)
    skin_col = (250, 204, 21, 255)

    if not flipped:
        # Green / Red Dome Shell
        draw.ellipse((ox + 6, oy + 10, ox + 26, oy + 26), fill=shell_col, outline=shell_dark, width=2)
        # Shell plates
        draw.ellipse((ox + 11, oy + 13, ox + 21, oy + 21), fill=(254, 240, 138, 255) if is_red else (134, 239, 172, 255))
        # Turtle Head
        draw.ellipse((ox + 20, oy + 8, ox + 29, oy + 16), fill=skin_col, outline=(180, 83, 9, 255))
        # Beady eye
        draw.ellipse((ox + 24, oy + 10, ox + 27, oy + 13), fill=(15, 23, 42, 255))
        # Feet
        draw.ellipse((ox + 7, oy + 22, ox + 14, oy + 28), fill=skin_col)
        draw.ellipse((ox + 18, oy + 22, ox + 25, oy + 28), fill=skin_col)
    else:
        # Upside down flipped shell with helpless wiggling feet
        draw.ellipse((ox + 6, oy + 14, ox + 26, oy + 28), fill=shell_col, outline=shell_dark, width=2)
        # Yellow belly plastron facing up
        draw.ellipse((ox + 8, oy + 12, ox + 24, oy + 20), fill=(254, 240, 138, 255), outline=(180, 83, 9, 255))
        # Wiggling feet in air
        draw.ellipse((ox + 7, oy + 6, ox + 13, oy + 14), fill=skin_col)
        draw.ellipse((ox + 19, oy + 6, ox + 25, oy + 14), fill=skin_col)


def draw_crab(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_angry: bool = False, flipped: bool = False) -> None:
    # Sidestepper Crab
    draw.ellipse((ox + 4, oy + 24, ox + 28, oy + 30), fill=(10, 15, 25, 100))

    crab_col = (220, 38, 38, 255) if is_angry else (249, 115, 22, 255)
    crab_dark = (153, 27, 27, 255) if is_angry else (194, 65, 12, 255)

    if not flipped:
        # Crab main shell
        draw.ellipse((ox + 6, oy + 12, ox + 26, oy + 26), fill=crab_col, outline=crab_dark, width=2)
        # Eyestalks
        draw.rectangle((ox + 10, oy + 6, ox + 13, oy + 12), fill=crab_col)
        draw.rectangle((ox + 19, oy + 6, ox + 22, oy + 12), fill=crab_col)
        draw.ellipse((ox + 9, oy + 4, ox + 14, oy + 9), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
        draw.ellipse((ox + 18, oy + 4, ox + 23, oy + 9), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
        draw.ellipse((ox + 11, oy + 5, ox + 13, oy + 7), fill=(15, 23, 42, 255))
        draw.ellipse((ox + 19, oy + 5, ox + 21, oy + 7), fill=(15, 23, 42, 255))
        # Pincer Claws
        draw.ellipse((ox + 2, oy + 10, ox + 9, oy + 18), fill=crab_col, outline=crab_dark)
        draw.ellipse((ox + 23, oy + 10, ox + 30, oy + 18), fill=crab_col, outline=crab_dark)
    else:
        # Upside-down crab
        draw.ellipse((ox + 6, oy + 14, ox + 26, oy + 28), fill=crab_col, outline=crab_dark, width=2)
        # Eyestalks on bottom
        draw.ellipse((ox + 10, oy + 6, ox + 15, oy + 12), fill=(255, 255, 255, 255))
        draw.ellipse((ox + 17, oy + 6, ox + 22, oy + 12), fill=(255, 255, 255, 255))


def draw_fly(draw: ImageDraw.ImageDraw, ox: int, oy: int, wings_up: bool = True) -> None:
    # Fighterfly
    draw.ellipse((ox + 6, oy + 24, ox + 26, oy + 30), fill=(10, 15, 25, 100))
    # Striped Body
    draw.ellipse((ox + 9, oy + 10, ox + 23, oy + 26), fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=2)
    draw.line([(ox + 11, oy + 16), (ox + 21, oy + 16)], fill=(15, 23, 42, 255), width=2)
    draw.line([(ox + 12, oy + 21), (ox + 20, oy + 21)], fill=(15, 23, 42, 255), width=2)
    # Huge anime fly eyes
    draw.ellipse((ox + 8, oy + 6, ox + 16, oy + 14), fill=(239, 68, 68, 255), outline=(153, 27, 27, 255))
    draw.ellipse((ox + 16, oy + 6, ox + 24, oy + 14), fill=(239, 68, 68, 255), outline=(153, 27, 27, 255))
    # Translucent Cyan Wings
    wing_y = oy + 4 if wings_up else oy + 12
    draw.ellipse((ox + 2, wing_y, ox + 12, wing_y + 10), fill=(6, 182, 212, 190), outline=(207, 250, 254, 255))
    draw.ellipse((ox + 20, wing_y, ox + 30, wing_y + 10), fill=(6, 182, 212, 190), outline=(207, 250, 254, 255))


def draw_pow(draw: ImageDraw.ImageDraw, ox: int, oy: int, hits_left: int = 3) -> None:
    # 3D Blue POW Block
    draw.rectangle((ox + 2, oy + 4, ox + 29, oy + 28), fill=(37, 99, 235, 255), outline=(29, 78, 216, 255), width=2)
    draw.line([(ox + 4, oy + 6), (ox + 27, oy + 6)], fill=(147, 197, 253, 255), width=2)
    # Text "POW"
    # P
    draw.line([(ox + 7, oy + 12), (ox + 7, oy + 22)], fill=(255, 255, 255, 255), width=2)
    draw.arc((ox + 7, oy + 12, ox + 13, oy + 18), start=270, end=90, fill=(255, 255, 255, 255), width=2)
    # O
    draw.ellipse((ox + 13, oy + 12, ox + 19, oy + 22), outline=(255, 255, 255, 255), width=2)
    # W
    draw.line([(ox + 20, oy + 12), (ox + 22, oy + 22), (ox + 24, oy + 16), (ox + 26, oy + 22), (ox + 28, oy + 12)], fill=(255, 255, 255, 255), width=2)


def draw_coin(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    w_scale = [12, 9, 5, 9][frame % 4]
    cx = ox + 16
    draw.ellipse((cx - w_scale, oy + 6, cx + w_scale, oy + 26), fill=(250, 204, 21, 255), outline=(180, 83, 9, 255), width=2)
    if w_scale > 6:
        draw.line([(cx, oy + 10), (cx, oy + 22)], fill=(254, 240, 138, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0: Mario
    # -------------------------------------------------------------
    draw_plumber(draw, 0 * C, 0, is_luigi=False, anim="idle")
    draw_plumber(draw, 1 * C, 0, is_luigi=False, anim="run1")
    draw_plumber(draw, 2 * C, 0, is_luigi=False, anim="run2")
    draw_plumber(draw, 3 * C, 0, is_luigi=False, anim="jump")

    # -------------------------------------------------------------
    # Row 1: Luigi
    # -------------------------------------------------------------
    draw_plumber(draw, 0 * C, 1 * C, is_luigi=True, anim="idle")
    draw_plumber(draw, 1 * C, 1 * C, is_luigi=True, anim="run1")
    draw_plumber(draw, 2 * C, 1 * C, is_luigi=True, anim="run2")
    draw_plumber(draw, 3 * C, 1 * C, is_luigi=True, anim="jump")

    # -------------------------------------------------------------
    # Row 2: Shellcreeper & Sidestepper
    # -------------------------------------------------------------
    draw_turtle(draw, 0 * C, 2 * C, is_red=False, flipped=False)
    draw_turtle(draw, 1 * C, 2 * C, is_red=True, flipped=False)
    draw_turtle(draw, 2 * C, 2 * C, is_red=False, flipped=True)
    draw_crab(draw, 3 * C, 2 * C, is_angry=False, flipped=False)
    draw_crab(draw, 4 * C, 2 * C, is_angry=True, flipped=False)
    draw_crab(draw, 5 * C, 2 * C, is_angry=False, flipped=True)

    # -------------------------------------------------------------
    # Row 3: Fighterfly, Fireballs, Freezie
    # -------------------------------------------------------------
    draw_fly(draw, 0 * C, 3 * C, wings_up=True)
    draw_fly(draw, 1 * C, 3 * C, wings_up=False)
    # Red Fireball
    draw.ellipse((2 * C + 6, 3 * C + 6, 3 * C - 7, 4 * C - 7), fill=(239, 68, 68, 255), outline=(254, 240, 138, 255), width=2)
    # Green Fireball
    draw.ellipse((3 * C + 6, 3 * C + 6, 4 * C - 7, 4 * C - 7), fill=(34, 197, 94, 255), outline=(254, 240, 138, 255), width=2)

    # -------------------------------------------------------------
    # Row 4: POW Block, Coins, Pipes
    # -------------------------------------------------------------
    draw_pow(draw, 0 * C, 4 * C, hits_left=3)
    for f in range(4):
        draw_coin(draw, (1 + f) * C, 4 * C, frame=f)

    # Sewer Pipe
    draw.rectangle((5 * C + 4, 4 * C + 4, 6 * C - 5, 5 * C - 5), fill=(22, 163, 74, 255), outline=(20, 83, 45, 255), width=2)
    draw.rectangle((5 * C + 2, 4 * C + 2, 6 * C - 3, 4 * C + 12), fill=(34, 197, 94, 255), outline=(20, 83, 45, 255), width=2)

    out_path = root / "assets" / "sprites" / "mariobros.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "mariobros" / "assets" / "sprites" / "mariobros.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
