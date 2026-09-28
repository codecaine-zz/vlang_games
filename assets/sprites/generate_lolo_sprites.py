#!/usr/bin/env python3
"""Generate ultra-polished, modern, studio-grade 512x512 RGBA sprite sheet for Adventures of Lolo (Cyber Lolo):
Grid: 32x32 cells (16x16 grid of tiles in 512x512 sheet)

Row 0 (Y=0..31):   Lolo Player (Down Idle, Down Walk, Up Idle, Up Walk, Left Idle, Left Walk, Right Idle, Right Walk)
Row 1 (Y=32..63):  Lolo Skins (Cyber Magenta, Obsidian Gold, Toxic Lime, Dark Matter, Boosted Aura, Dead/Fainted) & Princess Lala (2 frames)
Row 2 (Y=64..95):  Environment Tiles (Grass Castle, Cobble Floor, Cyber Grid Floor, Magma Floor, Crystal Floor, Dungeon Floor, Wall Castle, Wall Cyber)
Row 3 (Y=96..127): Obstacles (Tree/Foliage, Rock/Boulder, Water 4-frames animated, Lava 4-frames animated, Ice Floor, Bridge H, Bridge V)
Row 4 (Y=128..159): Arrows & Mechanics (Arrow Up, Arrow Down, Arrow Left, Arrow Right, Warp A, Warp B, Pressure Plate, Laser Prism)
Row 5 (Y=160..191): Collectibles & Items (Heart Frame Full, Heart Frame Empty, Emerald Frame, Chest Closed, Chest Open, Door Closed, Door Open, Hammer, Key, Boots)
Row 6 (Y=192..223): Enemies 1 (Snakey 2-frames, Alma 2-frames, Gol Asleep, Gol Awake Fire, Skull Asleep, Skull Awake, Medusa Normal, Medusa Gaze)
Row 7 (Y=224..255): Enemies 2 & Magic (Don Medusa H, Don Medusa V, Leeper Awake, Leeper Asleep, King Egger, Magic Egg Normal, Egg Cracked, Egg Water Raft, Plasma Shot)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
C = 32  # cell size


def draw_lolo(draw: ImageDraw.ImageDraw, ox: int, oy: int, dir: str = "down", step: int = 0, skin_color: tuple[int, int, int] = (37, 99, 235)) -> None:
    # 1. Drop Shadow
    draw.ellipse((ox + 4, oy + 23, ox + 28, oy + 30), fill=(10, 15, 25, 110))

    # 2. Modern 3D Red Shoes
    foot_y = oy + 22 + (2 if step == 1 else (-1 if step == 2 else 0))
    # Left foot
    draw.ellipse((ox + 4, foot_y, ox + 14, foot_y + 8), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255))
    draw.ellipse((ox + 6, foot_y + 1, ox + 11, foot_y + 4), fill=(248, 113, 113, 255))
    # Right foot
    draw.ellipse((ox + 18, foot_y, ox + 28, foot_y + 8), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255))
    draw.ellipse((ox + 20, foot_y + 1, ox + 25, foot_y + 4), fill=(248, 113, 113, 255))

    # 3. Main Spherical Body with 3D Radial Shading
    r_body, g_body, b_body = skin_color
    dark_body = (max(0, r_body - 40), max(0, g_body - 40), max(0, b_body - 40))
    light_body = (min(255, r_body + 50), min(255, g_body + 50), min(255, b_body + 50))

    # Base sphere
    draw.ellipse((ox + 3, oy + 3, ox + 29, oy + 27), fill=dark_body, outline=(15, 23, 42, 255), width=2)
    draw.ellipse((ox + 4, oy + 4, ox + 28, oy + 26), fill=skin_color)
    draw.ellipse((ox + 5, oy + 5, ox + 24, oy + 20), fill=light_body)
    # Specular gloss highlight
    draw.ellipse((ox + 7, oy + 6, ox + 14, oy + 12), fill=(255, 255, 255, 220))
    draw.ellipse((ox + 8, oy + 7, ox + 11, oy + 9), fill=(255, 255, 255, 255))

    # 4. Cute Aerodynamic Wing Fins
    if dir in ("down", "left", "right"):
        draw.ellipse((ox + 1, oy + 12, ox + 6, oy + 21), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255))
        draw.ellipse((ox + 26, oy + 12, ox + 31, oy + 21), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255))

    # 5. Soft Blushing Cheeks
    draw.ellipse((ox + 5, oy + 16, ox + 10, oy + 20), fill=(251, 113, 133, 180))
    draw.ellipse((ox + 22, oy + 16, ox + 27, oy + 20), fill=(251, 113, 133, 180))

    # 6. Modern Glossy Expressive Eyes
    if dir == "down":
        # White Sclera
        draw.ellipse((ox + 8, oy + 8, ox + 15, oy + 18), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
        draw.ellipse((ox + 17, oy + 8, ox + 24, oy + 18), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
        # Deep Blue-Black Pupils
        draw.ellipse((ox + 10, oy + 10, ox + 15, oy + 17), fill=(15, 23, 42, 255))
        draw.ellipse((ox + 17, oy + 10, ox + 22, oy + 17), fill=(15, 23, 42, 255))
        # Primary Catchlight
        draw.ellipse((ox + 11, oy + 11, ox + 14, oy + 14), fill=(255, 255, 255, 255))
        draw.ellipse((ox + 18, oy + 11, ox + 21, oy + 14), fill=(255, 255, 255, 255))
        # Secondary small sparkle
        draw.ellipse((ox + 13, oy + 15, ox + 14, oy + 16), fill=(255, 255, 255, 255))
        draw.ellipse((ox + 20, oy + 15, ox + 21, oy + 16), fill=(255, 255, 255, 255))
        # Joyful mouth
        draw.arc((ox + 13, oy + 17, ox + 19, oy + 22), start=0, end=180, fill=(15, 23, 42, 255), width=2)
    elif dir == "up":
        # Rear crown crest
        draw.ellipse((ox + 12, oy + 4, ox + 20, oy + 10), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255))
        draw.ellipse((ox + 14, oy + 6, ox + 18, oy + 8), fill=(248, 113, 113, 255))
    elif dir == "left":
        draw.ellipse((ox + 6, oy + 8, ox + 14, oy + 18), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
        draw.ellipse((ox + 7, oy + 10, ox + 12, oy + 17), fill=(15, 23, 42, 255))
        draw.ellipse((ox + 8, oy + 11, ox + 11, oy + 14), fill=(255, 255, 255, 255))
    elif dir == "right":
        draw.ellipse((ox + 18, oy + 8, ox + 26, oy + 18), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
        draw.ellipse((ox + 20, oy + 10, ox + 25, oy + 17), fill=(15, 23, 42, 255))
        draw.ellipse((ox + 21, oy + 11, ox + 24, oy + 14), fill=(255, 255, 255, 255))


def draw_lala(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    draw.ellipse((ox + 4, oy + 23, ox + 28, oy + 30), fill=(10, 15, 25, 110))
    # Red shoes
    draw.ellipse((ox + 5, oy + 22, ox + 14, oy + 29), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255))
    draw.ellipse((ox + 18, oy + 22, ox + 27, oy + 29), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255))
    # Pink body with soft gradient
    draw.ellipse((ox + 3, oy + 3, ox + 29, oy + 27), fill=(219, 39, 119, 255), outline=(157, 23, 77, 255), width=2)
    draw.ellipse((ox + 4, oy + 4, ox + 28, oy + 26), fill=(244, 114, 182, 255))
    draw.ellipse((ox + 5, oy + 5, ox + 23, oy + 18), fill=(251, 207, 232, 255))
    draw.ellipse((ox + 7, oy + 6, ox + 13, oy + 11), fill=(255, 255, 255, 230))
    # Golden Tiara
    draw.polygon([(ox + 9, oy + 5), (ox + 12, oy + 1), (ox + 16, oy + 4), (ox + 20, oy + 1), (ox + 23, oy + 5)], fill=(245, 158, 11, 255), outline=(180, 83, 9, 255))
    draw.ellipse((ox + 15, oy + 2, ox + 17, oy + 4), fill=(239, 68, 68, 255)) # Ruby jewel
    # Red Hair Ribbon Bow
    draw.polygon([(ox + 11, oy + 6), (ox + 16, oy + 8), (ox + 21, oy + 6)], fill=(239, 68, 68, 255))
    # Eyes
    draw.ellipse((ox + 8, oy + 8, ox + 15, oy + 18), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
    draw.ellipse((ox + 17, oy + 8, ox + 24, oy + 18), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
    draw.ellipse((ox + 10, oy + 10, ox + 15, oy + 17), fill=(15, 23, 42, 255))
    draw.ellipse((ox + 17, oy + 10, ox + 22, oy + 17), fill=(15, 23, 42, 255))
    draw.ellipse((ox + 11, oy + 11, ox + 14, oy + 14), fill=(255, 255, 255, 255))
    draw.ellipse((ox + 18, oy + 11, ox + 21, oy + 14), fill=(255, 255, 255, 255))
    # Cheeks
    draw.ellipse((ox + 5, oy + 16, ox + 10, oy + 20), fill=(251, 113, 133, 200))
    draw.ellipse((ox + 22, oy + 16, ox + 27, oy + 20), fill=(251, 113, 133, 200))


def draw_grass_tile(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(34, 197, 94, 255), outline=(22, 163, 74, 255))
    # Stylized tufts
    draw.line([(ox + 6, oy + 8), (ox + 10, oy + 4), (ox + 14, oy + 8)], fill=(134, 239, 172, 255), width=2)
    draw.line([(ox + 18, oy + 20), (ox + 22, oy + 16), (ox + 26, oy + 20)], fill=(134, 239, 172, 255), width=2)


def draw_wall_tile(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # High-tech brick castle wall with stone bevels
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(51, 65, 85, 255), outline=(15, 23, 42, 255), width=2)
    # Brick lines
    draw.line([(ox, oy + 15), (ox + 31, oy + 15)], fill=(30, 41, 59, 255), width=2)
    draw.line([(ox + 15, oy), (ox + 15, oy + 15)], fill=(30, 41, 59, 255), width=2)
    draw.line([(ox + 8, oy + 15), (ox + 8, oy + 31)], fill=(30, 41, 59, 255), width=2)
    draw.line([(ox + 24, oy + 15), (ox + 24, oy + 31)], fill=(30, 41, 59, 255), width=2)
    # Highlights
    draw.line([(ox + 2, oy + 2), (ox + 30, oy + 2)], fill=(148, 163, 184, 255), width=1)
    draw.line([(ox + 2, oy + 17), (ox + 30, oy + 17)], fill=(148, 163, 184, 255), width=1)


def draw_rock_tile(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 3D Chiseled Boulder
    draw.ellipse((ox + 3, oy + 22, ox + 29, oy + 30), fill=(10, 15, 25, 120))
    draw.polygon([(ox + 6, oy + 8), (ox + 18, oy + 3), (ox + 28, oy + 10), (ox + 29, oy + 24), (ox + 16, oy + 28), (ox + 4, oy + 22)], fill=(100, 116, 139, 255), outline=(30, 41, 59, 255), width=2)
    draw.polygon([(ox + 8, oy + 9), (ox + 18, oy + 5), (ox + 24, oy + 12), (ox + 16, oy + 18)], fill=(148, 163, 184, 255))
    draw.line([(ox + 10, oy + 18), (ox + 16, oy + 24)], fill=(51, 65, 85, 255), width=2)


def draw_tree_tile(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Lush stylized pine tree
    draw.ellipse((ox + 4, oy + 24, ox + 28, oy + 30), fill=(10, 15, 25, 120))
    # Trunk
    draw.rectangle((ox + 12, oy + 20, ox + 20, oy + 28), fill=(120, 53, 15, 255), outline=(69, 26, 3, 255))
    # Foliage layers
    draw.polygon([(ox + 4, oy + 22), (ox + 16, oy + 12), (ox + 28, oy + 22)], fill=(21, 128, 61, 255), outline=(20, 83, 45, 255))
    draw.polygon([(ox + 6, oy + 15), (ox + 16, oy + 7), (ox + 26, oy + 15)], fill=(22, 163, 74, 255), outline=(20, 83, 45, 255))
    draw.polygon([(ox + 9, oy + 9), (ox + 16, oy + 2), (ox + 23, oy + 9)], fill=(34, 197, 94, 255), outline=(20, 83, 45, 255))


def draw_water_tile(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(14, 116, 144, 255), outline=(8, 51, 68, 255))
    # Ripples
    y_off = (frame * 6) % 24
    draw.arc((ox + 2, oy + 4 + y_off, ox + 18, oy + 12 + y_off), start=0, end=180, fill=(56, 189, 248, 255), width=2)
    draw.arc((ox + 14, oy + 14 - y_off, ox + 30, oy + 22 - y_off), start=0, end=180, fill=(186, 230, 253, 255), width=2)


def draw_lava_tile(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(185, 28, 28, 255), outline=(127, 29, 29, 255))
    draw.ellipse((ox + 6, oy + 8, ox + 16, oy + 18), fill=(245, 158, 11, 255))
    draw.ellipse((ox + 18, oy + 16, ox + 26, oy + 24), fill=(251, 191, 36, 255))
    draw.ellipse((ox + 8, oy + 10, ox + 12, oy + 14), fill=(254, 240, 138, 255))


def draw_ice_tile(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(34, 211, 238, 255), outline=(207, 250, 254, 255))
    draw.line([(ox + 4, oy + 4), (ox + 10, oy + 28)], fill=(255, 255, 255, 220), width=1)
    draw.line([(ox + 18, oy + 6), (ox + 26, oy + 22)], fill=(255, 255, 255, 220), width=1)


def draw_heart_frame(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_full: bool = True) -> None:
    # 3D Gold Box with Ruby Heart
    draw.rectangle((ox + 2, oy + 2, ox + 29, oy + 29), fill=(245, 158, 11, 255), outline=(180, 83, 9, 255), width=2)
    draw.rectangle((ox + 5, oy + 5, ox + 26, oy + 26), fill=(30, 41, 59, 255))
    if is_full:
        # Glossy Ruby Heart
        draw.polygon([(ox + 16, oy + 24), (ox + 8, oy + 14), (ox + 11, oy + 9), (ox + 16, oy + 12), (ox + 21, oy + 9), (ox + 24, oy + 14)], fill=(220, 38, 38, 255), outline=(254, 202, 202, 255))
        draw.ellipse((ox + 10, oy + 10, ox + 14, oy + 14), fill=(248, 113, 113, 255))
        draw.ellipse((ox + 11, oy + 11, ox + 13, oy + 13), fill=(255, 255, 255, 255))


def draw_emerald_frame(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    draw.rectangle((ox + 2, oy + 2, ox + 29, oy + 29), fill=(16, 185, 129, 255), outline=(4, 120, 87, 255), width=2)
    draw.polygon([(ox + 16, oy + 6), (ox + 25, oy + 15), (ox + 16, oy + 25), (ox + 7, oy + 15)], fill=(52, 211, 153, 255), outline=(255, 255, 255, 200))
    draw.polygon([(ox + 16, oy + 10), (ox + 21, oy + 15), (ox + 16, oy + 21), (ox + 11, oy + 15)], fill=(167, 243, 208, 255))


def draw_chest(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_open: bool = False) -> None:
    # 3D Gold Treasure Chest
    draw.ellipse((ox + 3, oy + 22, ox + 29, oy + 30), fill=(10, 15, 25, 120))
    if not is_open:
        draw.rectangle((ox + 4, oy + 10, ox + 27, oy + 26), fill=(217, 119, 6, 255), outline=(146, 64, 14, 255), width=2)
        draw.rectangle((ox + 4, oy + 8, ox + 27, oy + 15), fill=(245, 158, 11, 255), outline=(180, 83, 9, 255))
        draw.ellipse((ox + 13, oy + 16, ox + 18, oy + 21), fill=(15, 23, 42, 255)) # Keyhole
    else:
        draw.rectangle((ox + 4, oy + 14, ox + 27, oy + 26), fill=(217, 119, 6, 255), outline=(146, 64, 14, 255), width=2)
        # Open lid tilted up
        draw.polygon([(ox + 4, oy + 14), (ox + 8, oy + 4), (ox + 27, oy + 4), (ox + 27, oy + 14)], fill=(245, 158, 11, 255), outline=(180, 83, 9, 255))
        # Sparkling cyan diamond inside
        draw.polygon([(ox + 16, oy + 6), (ox + 21, oy + 12), (ox + 16, oy + 18), (ox + 11, oy + 12)], fill=(34, 211, 238, 255), outline=(255, 255, 255, 255))


def draw_door(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_open: bool = False) -> None:
    # Castle Gate / Dimensional Portal
    draw.rectangle((ox + 2, oy + 2, ox + 29, oy + 29), fill=(30, 41, 59, 255), outline=(71, 85, 105, 255), width=2)
    if is_open:
        # Glowing Cyan Portal Arch
        draw.rectangle((ox + 6, oy + 6, ox + 25, oy + 29), fill=(6, 182, 212, 255))
        draw.rectangle((ox + 10, oy + 10, ox + 21, oy + 29), fill=(207, 250, 254, 255))
    else:
        # Heavy Reinforced Iron Grate
        draw.rectangle((ox + 6, oy + 6, ox + 25, oy + 29), fill=(15, 23, 42, 255), outline=(100, 116, 139, 255))
        draw.line([(ox + 11, oy + 6), (ox + 11, oy + 29)], fill=(148, 163, 184, 255), width=2)
        draw.line([(ox + 20, oy + 6), (ox + 20, oy + 29)], fill=(148, 163, 184, 255), width=2)


def draw_snakey(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Friendly green serpent coil
    draw.ellipse((ox + 4, oy + 22, ox + 28, oy + 30), fill=(10, 15, 25, 110))
    # Coiled base
    draw.ellipse((ox + 4, oy + 14, ox + 28, oy + 28), fill=(22, 163, 74, 255), outline=(20, 83, 45, 255), width=2)
    draw.ellipse((ox + 8, oy + 16, ox + 24, oy + 26), fill=(250, 204, 21, 255)) # Yellow belly scales
    # Head
    draw.ellipse((ox + 7, oy + 4, ox + 25, oy + 18), fill=(34, 197, 94, 255), outline=(20, 83, 45, 255), width=2)
    # Big anime snake eyes
    eye_off = (1 if frame == 1 else 0)
    draw.ellipse((ox + 9, oy + 7, ox + 15, oy + 15), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
    draw.ellipse((ox + 17, oy + 7, ox + 23, oy + 15), fill=(255, 255, 255, 255), outline=(15, 23, 42, 255))
    draw.ellipse((ox + 11 + eye_off, oy + 9, ox + 14 + eye_off, oy + 14), fill=(15, 23, 42, 255))
    draw.ellipse((ox + 18 + eye_off, oy + 9, ox + 21 + eye_off, oy + 14), fill=(15, 23, 42, 255))
    # Pink forked tongue
    if frame == 1:
        draw.line([(ox + 16, oy + 17), (ox + 16, oy + 21)], fill=(244, 114, 182, 255), width=2)


def draw_alma(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Armored red rolling beast
    draw.ellipse((ox + 4, oy + 22, ox + 28, oy + 30), fill=(10, 15, 25, 110))
    draw.ellipse((ox + 3, oy + 3, ox + 29, oy + 27), fill=(220, 38, 38, 255), outline=(153, 27, 27, 255), width=2)
    # Armor segments
    draw.arc((ox + 6, oy + 6, ox + 26, oy + 24), start=30, end=150, fill=(248, 113, 113, 255), width=2)
    # Glowing fierce yellow eyes
    draw.ellipse((ox + 8, oy + 10, ox + 14, oy + 17), fill=(250, 204, 21, 255), outline=(15, 23, 42, 255))
    draw.ellipse((ox + 18, oy + 10, ox + 24, oy + 17), fill=(250, 204, 21, 255), outline=(15, 23, 42, 255))
    draw.ellipse((ox + 10, oy + 12, ox + 13, oy + 15), fill=(153, 27, 27, 255))
    draw.ellipse((ox + 19, oy + 12, ox + 22, oy + 15), fill=(153, 27, 27, 255))


def draw_gol(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_awake: bool = False) -> None:
    # Dragon beast with fire breath
    draw.ellipse((ox + 4, oy + 22, ox + 28, oy + 30), fill=(10, 15, 25, 110))
    draw.ellipse((ox + 3, oy + 5, ox + 29, oy + 27), fill=(37, 99, 235, 255), outline=(29, 78, 216, 255), width=2)
    # Belly
    draw.ellipse((ox + 8, oy + 12, ox + 24, oy + 26), fill=(251, 191, 36, 255))
    if not is_awake:
        # Sleeping closed eyes
        draw.arc((ox + 8, oy + 9, ox + 14, oy + 15), start=0, end=180, fill=(15, 23, 42, 255), width=2)
        draw.arc((ox + 18, oy + 9, ox + 24, oy + 15), start=0, end=180, fill=(15, 23, 42, 255), width=2)
    else:
        # Awake fiery eyes
        draw.ellipse((ox + 8, oy + 8, ox + 14, oy + 16), fill=(239, 68, 68, 255), outline=(255, 255, 255, 255))
        draw.ellipse((ox + 18, oy + 8, ox + 24, oy + 16), fill=(239, 68, 68, 255), outline=(255, 255, 255, 255))
        # Fire plume
        draw.polygon([(ox + 16, oy + 18), (ox + 20, oy + 28), (ox + 12, oy + 28)], fill=(245, 158, 11, 255))


def draw_skull(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_awake: bool = False) -> None:
    draw.ellipse((ox + 4, oy + 22, ox + 28, oy + 30), fill=(10, 15, 25, 110))
    # Bone skull
    draw.ellipse((ox + 5, oy + 4, ox + 27, oy + 22), fill=(241, 245, 249, 255), outline=(148, 163, 184, 255), width=2)
    draw.rectangle((ox + 10, oy + 18, ox + 22, oy + 26), fill=(241, 245, 249, 255), outline=(148, 163, 184, 255))
    # Eye sockets
    eye_col = (239, 68, 68, 255) if is_awake else (15, 23, 42, 255)
    draw.ellipse((ox + 8, oy + 10, ox + 14, oy + 17), fill=eye_col)
    draw.ellipse((ox + 18, oy + 10, ox + 24, oy + 17), fill=eye_col)


def draw_medusa(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_gazing: bool = False) -> None:
    # Deadly Gorgon Head
    draw.ellipse((ox + 4, oy + 22, ox + 28, oy + 30), fill=(10, 15, 25, 110))
    draw.ellipse((ox + 4, oy + 4, ox + 28, oy + 26), fill=(107, 114, 128, 255), outline=(55, 65, 81, 255), width=2)
    # Snake hair loops
    for sx in [4, 12, 20]:
        draw.arc((ox + sx, oy + 1, ox + sx + 8, oy + 9), start=180, end=360, fill=(22, 163, 74, 255), width=2)
    # Eye beams
    if is_gazing:
        draw.ellipse((ox + 8, oy + 10, ox + 14, oy + 17), fill=(239, 68, 68, 255), outline=(255, 255, 255, 255))
        draw.ellipse((ox + 18, oy + 10, ox + 24, oy + 17), fill=(239, 68, 68, 255), outline=(255, 255, 255, 255))
    else:
        draw.ellipse((ox + 8, oy + 10, ox + 14, oy + 17), fill=(15, 23, 42, 255))
        draw.ellipse((ox + 18, oy + 10, ox + 24, oy + 17), fill=(15, 23, 42, 255))


def draw_don_medusa(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Armored roaming Don Medusa with silver spikes
    draw.ellipse((ox + 4, oy + 22, ox + 28, oy + 30), fill=(10, 15, 25, 110))
    draw.rectangle((ox + 4, oy + 6, ox + 27, oy + 26), fill=(79, 70, 229, 255), outline=(49, 46, 129, 255), width=2)
    # Spikes
    draw.polygon([(ox + 16, oy + 1), (ox + 12, oy + 6), (ox + 20, oy + 6)], fill=(226, 232, 240, 255))
    draw.polygon([(ox + 1, oy + 16), (ox + 6, oy + 12), (ox + 6, oy + 20)], fill=(226, 232, 240, 255))
    draw.polygon([(ox + 31, oy + 16), (ox + 26, oy + 12), (ox + 26, oy + 20)], fill=(226, 232, 240, 255))
    # Glowing Cyber Vision Eye
    draw.ellipse((ox + 10, oy + 11, ox + 22, oy + 21), fill=(239, 68, 68, 255), outline=(254, 240, 138, 255))


def draw_egg(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_cracked: bool = False) -> None:
    # 3D Magic Egg
    draw.ellipse((ox + 4, oy + 22, ox + 28, oy + 30), fill=(10, 15, 25, 110))
    draw.ellipse((ox + 5, oy + 4, ox + 27, oy + 27), fill=(254, 240, 138, 255), outline=(217, 119, 6, 255), width=2)
    draw.ellipse((ox + 8, oy + 7, ox + 16, oy + 16), fill=(255, 255, 255, 220))
    if is_cracked:
        # Zig-zag fracture
        draw.line([(ox + 12, oy + 8), (ox + 18, oy + 14), (ox + 14, oy + 18), (ox + 20, oy + 24)], fill=(180, 83, 9, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0 (Y=0..31): Lolo Player (Down, Up, Left, Right + Walk)
    # -------------------------------------------------------------
    draw_lolo(draw, 0 * C, 0, "down", 0)
    draw_lolo(draw, 1 * C, 0, "down", 1)
    draw_lolo(draw, 2 * C, 0, "up", 0)
    draw_lolo(draw, 3 * C, 0, "up", 1)
    draw_lolo(draw, 4 * C, 0, "left", 0)
    draw_lolo(draw, 5 * C, 0, "left", 1)
    draw_lolo(draw, 6 * C, 0, "right", 0)
    draw_lolo(draw, 7 * C, 0, "right", 1)

    # -------------------------------------------------------------
    # Row 1 (Y=32..63): Lolo Skins & Princess Lala
    # -------------------------------------------------------------
    draw_lolo(draw, 0 * C, C, "down", 0, skin_color=(236, 72, 153)) # Magenta
    draw_lolo(draw, 1 * C, C, "down", 0, skin_color=(245, 158, 11)) # Gold
    draw_lolo(draw, 2 * C, C, "down", 0, skin_color=(34, 197, 94))  # Toxic Lime
    draw_lolo(draw, 3 * C, C, "down", 0, skin_color=(147, 51, 234)) # Dark Matter
    draw_lolo(draw, 4 * C, C, "down", 0, skin_color=(6, 182, 212))  # Cyan Boosted
    draw_lolo(draw, 5 * C, C, "down", 0, skin_color=(100, 116, 139)) # Dead/Fainted
    draw_lala(draw, 6 * C, C, frame=0)
    draw_lala(draw, 7 * C, C, frame=1)

    # -------------------------------------------------------------
    # Row 2 (Y=64..95): Environment Floor Tiles
    # -------------------------------------------------------------
    draw_grass_tile(draw, 0 * C, 2 * C)
    draw_wall_tile(draw, 6 * C, 2 * C)
    draw_wall_tile(draw, 7 * C, 2 * C)

    # -------------------------------------------------------------
    # Row 3 (Y=96..127): Obstacles (Tree, Rock, Water, Lava, Ice)
    # -------------------------------------------------------------
    draw_tree_tile(draw, 0 * C, 3 * C)
    draw_rock_tile(draw, 1 * C, 3 * C)
    for f in range(4):
        draw_water_tile(draw, (2 + f) * C, 3 * C, frame=f)
    draw_lava_tile(draw, 6 * C, 3 * C, frame=0)
    draw_ice_tile(draw, 7 * C, 3 * C)

    # -------------------------------------------------------------
    # Row 4 (Y=128..159): Arrows & Mechanics
    # -------------------------------------------------------------
    for i, arrow_char in enumerate(["^", "v", "<", ">"]):
        draw.rectangle((i * C, 4 * C, (i + 1) * C - 1, 5 * C - 1), fill=(30, 41, 59, 255), outline=(59, 130, 246, 255))
        # Arrow chevron
        cx = i * C + 16
        cy = 4 * C + 16
        if arrow_char == "^":
            draw.polygon([(cx, cy - 8), (cx + 8, cy + 4), (cx - 8, cy + 4)], fill=(34, 211, 238, 255))
        elif arrow_char == "v":
            draw.polygon([(cx, cy + 8), (cx + 8, cy - 4), (cx - 8, cy - 4)], fill=(34, 211, 238, 255))
        elif arrow_char == "<":
            draw.polygon([(cx - 8, cy), (cx + 4, cy - 8), (cx + 4, cy + 8)], fill=(34, 211, 238, 255))
        else:
            draw.polygon([(cx + 8, cy), (cx - 4, cy - 8), (cx - 4, cy + 8)], fill=(34, 211, 238, 255))

    # Warp A & B
    draw.rectangle((4 * C, 4 * C, 5 * C - 1, 5 * C - 1), fill=(15, 23, 42, 255), outline=(147, 51, 234, 255), width=2)
    draw.ellipse((4 * C + 6, 4 * C + 6, 5 * C - 7, 5 * C - 7), fill=(168, 85, 247, 255), outline=(243, 232, 255, 255))
    draw.rectangle((5 * C, 4 * C, 6 * C - 1, 5 * C - 1), fill=(15, 23, 42, 255), outline=(236, 72, 153, 255), width=2)
    draw.ellipse((5 * C + 6, 4 * C + 6, 6 * C - 7, 5 * C - 7), fill=(244, 114, 182, 255), outline=(253, 242, 248, 255))

    # Pressure Plate
    draw.rectangle((6 * C, 4 * C, 7 * C - 1, 5 * C - 1), fill=(51, 65, 85, 255))
    draw.rectangle((6 * C + 4, 4 * C + 4, 7 * C - 5, 5 * C - 5), fill=(239, 68, 68, 255), outline=(254, 202, 202, 255))

    # Laser Prism
    draw.rectangle((7 * C, 4 * C, 8 * C - 1, 5 * C - 1), fill=(30, 41, 59, 255))
    draw.polygon([(7 * C + 4, 5 * C - 4), (8 * C - 4, 5 * C - 4), (8 * C - 4, 4 * C + 4)], fill=(6, 182, 212, 255), outline=(255, 255, 255, 255))

    # -------------------------------------------------------------
    # Row 5 (Y=160..191): Collectibles & Items
    # -------------------------------------------------------------
    draw_heart_frame(draw, 0 * C, 5 * C, is_full=True)
    draw_heart_frame(draw, 1 * C, 5 * C, is_full=False)
    draw_emerald_frame(draw, 2 * C, 5 * C)
    draw_chest(draw, 3 * C, 5 * C, is_open=False)
    draw_chest(draw, 4 * C, 5 * C, is_open=True)
    draw_door(draw, 5 * C, 5 * C, is_open=False)
    draw_door(draw, 6 * C, 5 * C, is_open=True)
    # Hammer
    draw.rectangle((7 * C + 14, 5 * C + 12, 7 * C + 18, 5 * C + 28), fill=(120, 53, 15, 255))
    draw.rectangle((7 * C + 8, 5 * C + 4, 7 * C + 24, 5 * C + 14), fill=(148, 163, 184, 255), outline=(71, 85, 105, 255))

    # -------------------------------------------------------------
    # Row 6 (Y=192..223): Enemies 1
    # -------------------------------------------------------------
    draw_snakey(draw, 0 * C, 6 * C, frame=0)
    draw_snakey(draw, 1 * C, 6 * C, frame=1)
    draw_alma(draw, 2 * C, 6 * C, frame=0)
    draw_alma(draw, 3 * C, 6 * C, frame=1)
    draw_gol(draw, 4 * C, 6 * C, is_awake=False)
    draw_gol(draw, 5 * C, 6 * C, is_awake=True)
    draw_skull(draw, 6 * C, 6 * C, is_awake=False)
    draw_skull(draw, 7 * C, 6 * C, is_awake=True)

    # -------------------------------------------------------------
    # Row 7 (Y=224..255): Enemies 2 & Magic
    # -------------------------------------------------------------
    draw_medusa(draw, 0 * C, 7 * C, is_gazing=False)
    draw_medusa(draw, 1 * C, 7 * C, is_gazing=True)
    draw_don_medusa(draw, 2 * C, 7 * C)
    # Leeper
    draw.ellipse((3 * C + 4, 7 * C + 4, 4 * C - 5, 8 * C - 5), fill=(234, 179, 8, 255), outline=(161, 98, 7, 255), width=2)
    # King Egger
    draw.ellipse((4 * C + 3, 7 * C + 3, 5 * C - 4, 8 * C - 4), fill=(168, 85, 247, 255), outline=(107, 33, 168, 255), width=2)
    draw.polygon([(4 * C + 8, 7 * C + 4), (4 * C + 12, 7 * C), (4 * C + 16, 7 * C + 3), (4 * C + 20, 7 * C), (4 * C + 24, 7 * C + 4)], fill=(245, 158, 11, 255))
    # Magic Egg
    draw_egg(draw, 4 * C, 7 * C, is_cracked=False)
    draw_egg(draw, 5 * C, 7 * C, is_cracked=True)
    # Plasma Shot Orb
    draw.ellipse((6 * C + 8, 7 * C + 8, 7 * C - 9, 8 * C - 9), fill=(34, 211, 238, 255), outline=(255, 255, 255, 255), width=2)
    # Keycard
    draw.rectangle((7 * C + 6, 7 * C + 8, 8 * C - 7, 8 * C - 8), fill=(245, 158, 11, 255), outline=(180, 83, 9, 255))
    draw.ellipse((7 * C + 10, 7 * C + 12, 7 * C + 16, 7 * C + 18), fill=(15, 23, 42, 255))

    out_path = root / "assets" / "sprites" / "lolo.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "lolo" / "assets" / "sprites" / "lolo.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
