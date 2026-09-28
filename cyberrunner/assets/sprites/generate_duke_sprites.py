#!/usr/bin/env python3
"""Generate high-fidelity 1024x1024 RGBA sprite sheet for Duke Nukem 2D Retro Platformer:
- Duke Nukem Player Sprites (Idle, Walk 1 & 2, Somersault Jump 1 & 2, Crouch, Aim Up, Climb 1 & 2, Pipe Hang 1 & 2, Victory)
- Tiles (Sector 1 City Steel, Sector 2 Subterranean Rust, Sector 3 Orbital Alloy, Ladder, Pipe, Red/Blue/Green Doors, Acid, Exit, Elevator)
- Props (Surveillance Camera, Toxic Waste Barrel, Supply Crate)
- Items (Soda Can, Turkey, Red/Blue/Green Keys, Floppy Disk, Circuit Board, Dual Laser, Flamethrower, Missile)
- Enemies (Robodroid, Turret, Mutant Slime)
- Boss Mech (Goliath Heavy Mech Walker)
- Projectiles (Blaster, Dual Laser, Flamethrower, Missile, Enemy Laser)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_W = 1024
SHEET_H = 1024


def draw_duke(draw: ImageDraw.ImageDraw, ox: int, oy: int, state: str = "idle") -> None:
    # Shadow
    draw.ellipse([ox + 4, oy + 32, ox + 28, oy + 38], fill=(10, 10, 15, 120))

    if state == "tumble1":
        # Somersault ball frame 1
        draw.ellipse([ox + 4, oy + 6, ox + 28, oy + 30], fill=(220, 35, 40, 255), outline=(120, 15, 20, 255))
        draw.rectangle([ox + 8, oy + 18, ox + 24, oy + 28], fill=(35, 80, 190, 255))
        draw.rectangle([ox + 10, oy + 4, ox + 22, oy + 10], fill=(250, 220, 60, 255))
        draw.rectangle([ox + 12, oy + 10, ox + 20, oy + 14], fill=(20, 20, 25, 255)) # sunglasses
        return

    if state == "tumble2":
        # Somersault ball frame 2 (inverted spin)
        draw.ellipse([ox + 4, oy + 6, ox + 28, oy + 30], fill=(35, 80, 190, 255), outline=(15, 40, 110, 255))
        draw.rectangle([ox + 8, oy + 8, ox + 24, oy + 18], fill=(220, 35, 40, 255))
        draw.rectangle([ox + 10, oy + 22, ox + 22, oy + 28], fill=(250, 220, 60, 255))
        return

    if state == "climb1" or state == "climb2":
        # Back facing ladder climb
        leg_y = -3 if state == "climb1" else 3
        # Boots & Jeans
        draw.rectangle([ox + 6, oy + 24 + leg_y, ox + 12, oy + 34 + leg_y], fill=(35, 80, 190, 255), outline=(15, 40, 110, 255))
        draw.rectangle([ox + 18, oy + 24 - leg_y, ox + 24, oy + 34 - leg_y], fill=(35, 80, 190, 255), outline=(15, 40, 110, 255))
        draw.rectangle([ox + 5, oy + 30 + leg_y, ox + 13, oy + 35 + leg_y], fill=(100, 60, 25, 255))
        draw.rectangle([ox + 17, oy + 30 - leg_y, ox + 25, oy + 35 - leg_y], fill=(100, 60, 25, 255))
        # Red Tank Top Back
        draw.rectangle([ox + 7, oy + 12, ox + 23, oy + 24], fill=(220, 35, 40, 255), outline=(120, 15, 20, 255))
        # Muscular arms holding ladder
        draw.rectangle([ox + 2, oy + 8 + leg_y, ox + 7, oy + 18 + leg_y], fill=(245, 185, 140, 255), outline=(160, 100, 60, 255))
        draw.rectangle([ox + 23, oy + 8 - leg_y, ox + 28, oy + 18 - leg_y], fill=(245, 185, 140, 255), outline=(160, 100, 60, 255))
        # Blonde Hair Back
        draw.rectangle([ox + 8, oy + 3, ox + 22, oy + 12], fill=(250, 220, 60, 255), outline=(180, 140, 30, 255))
        return

    if state == "hang1" or state == "hang2":
        # Overhead pipe hanging
        leg_sw = 3 if state == "hang1" else -3
        # Red tank top
        draw.rectangle([ox + 8, oy + 10, ox + 22, oy + 22], fill=(220, 35, 40, 255), outline=(120, 15, 20, 255))
        # Arms raised holding pipe
        draw.rectangle([ox + 4, oy + 2, ox + 9, oy + 12], fill=(245, 185, 140, 255))
        draw.rectangle([ox + 21, oy + 2, ox + 26, oy + 12], fill=(245, 185, 140, 255))
        # Head & Sunglasses
        draw.rectangle([ox + 9, oy + 4, ox + 21, oy + 11], fill=(250, 220, 60, 255))
        draw.rectangle([ox + 10, oy + 9, ox + 20, oy + 14], fill=(245, 185, 140, 255))
        draw.rectangle([ox + 12, oy + 10, ox + 20, oy + 13], fill=(15, 15, 20, 255))
        # Dangling legs
        draw.rectangle([ox + 9 + leg_sw, oy + 22, ox + 15 + leg_sw, oy + 32], fill=(35, 80, 190, 255))
        draw.rectangle([ox + 16 - leg_sw, oy + 22, ox + 22 - leg_sw, oy + 32], fill=(35, 80, 190, 255))
        draw.rectangle([ox + 8 + leg_sw, oy + 29, ox + 15 + leg_sw, oy + 33], fill=(100, 60, 25, 255))
        draw.rectangle([ox + 15 - leg_sw, oy + 29, ox + 22 - leg_sw, oy + 33], fill=(100, 60, 25, 255))
        return

    # Normal Stand, Walk, Crouch, Aim Up, Victory
    walk_leg = 0
    if state == "walk1":
        walk_leg = 4
    elif state == "walk2":
        walk_leg = -4

    is_crouch = state == "crouch"
    body_y = 17 if is_crouch else 13
    body_h = 8 if is_crouch else 12

    # 1. Legs & Jeans
    if not is_crouch:
        draw.rectangle([ox + 7 + walk_leg, oy + 24, ox + 13 + walk_leg, oy + 32], fill=(35, 80, 190, 255), outline=(15, 40, 110, 255))
        draw.rectangle([ox + 16 - walk_leg, oy + 24, ox + 22 - walk_leg, oy + 32], fill=(35, 80, 190, 255), outline=(15, 40, 110, 255))
        # Combat Boots
        draw.rectangle([ox + 6 + walk_leg, oy + 29, ox + 14 + walk_leg, oy + 34], fill=(100, 60, 25, 255), outline=(50, 30, 10, 255))
        draw.rectangle([ox + 15 - walk_leg, oy + 29, ox + 23 - walk_leg, oy + 34], fill=(100, 60, 25, 255), outline=(50, 30, 10, 255))
    else:
        # Crouch legs
        draw.rectangle([ox + 6, oy + 24, ox + 22, oy + 32], fill=(35, 80, 190, 255), outline=(15, 40, 110, 255))
        draw.rectangle([ox + 5, oy + 28, ox + 23, oy + 33], fill=(100, 60, 25, 255))

    # 2. Red Tank Top Body
    draw.rectangle([ox + 6, oy + body_y, ox + 22, oy + body_y + body_h], fill=(220, 35, 40, 255), outline=(120, 15, 20, 255))
    # Belt & Buckle
    draw.rectangle([ox + 6, oy + body_y + body_h - 3, ox + 22, oy + body_y + body_h], fill=(30, 30, 35, 255))
    draw.rectangle([ox + 12, oy + body_y + body_h - 3, ox + 16, oy + body_y + body_h], fill=(255, 215, 60, 255))

    # Muscular Arms
    draw.rectangle([ox + 3, oy + body_y + 1, ox + 7, oy + body_y + 8], fill=(245, 185, 140, 255), outline=(170, 110, 70, 255))
    draw.rectangle([ox + 21, oy + body_y + 1, ox + 25, oy + body_y + 8], fill=(245, 185, 140, 255), outline=(170, 110, 70, 255))

    # 3. Head, Flattop Hair & Sunglasses
    head_y = body_y - 10
    draw.rectangle([ox + 7, oy + head_y, ox + 21, oy + head_y + 6], fill=(250, 220, 60, 255), outline=(180, 140, 30, 255))
    draw.rectangle([ox + 8, oy + head_y + 5, ox + 20, oy + head_y + 11], fill=(245, 185, 140, 255))
    # Dark Sunglasses with cyan specular glint
    draw.rectangle([ox + 12, oy + head_y + 6, ox + 21, oy + head_y + 9], fill=(15, 15, 20, 255))
    draw.rectangle([ox + 14, oy + head_y + 6, ox + 16, oy + head_y + 8], fill=(180, 240, 255, 255))

    # 4. Weapon in Hand
    if state == "aim_up":
        # Plasma rifle held vertical
        draw.rectangle([ox + 18, oy + head_y - 8, ox + 22, oy + head_y + 6], fill=(180, 185, 195, 255), outline=(80, 85, 95, 255))
        draw.rectangle([ox + 18, oy + head_y - 10, ox + 22, oy + head_y - 8], fill=(255, 60, 60, 255))
    elif state == "victory":
        # Thumb up & pistol holstered
        draw.rectangle([ox + 22, oy + body_y - 2, ox + 26, oy + body_y + 6], fill=(245, 185, 140, 255))
        draw.rectangle([ox + 24, oy + body_y - 6, ox + 26, oy + body_y - 2], fill=(245, 185, 140, 255))
    else:
        # Standard forward plasma pistol
        gun_x = ox + 18
        gun_y = oy + body_y + 3
        draw.rectangle([gun_x, gun_y, gun_x + 10, gun_y + 5], fill=(180, 185, 195, 255), outline=(80, 85, 95, 255))
        draw.rectangle([gun_x + 8, gun_y + 1, gun_x + 10, gun_y + 4], fill=(255, 60, 60, 255))


def draw_tiles(draw: ImageDraw.ImageDraw) -> None:
    # Row 1 (Y = 64..127)
    # Sector 1 City Steel Panel (0, 64, 32x32)
    draw.rectangle([0, 64, 31, 95], fill=(70, 75, 90, 255), outline=(110, 120, 140, 255))
    draw.line([(0, 64), (31, 64)], fill=(140, 150, 175, 255))
    draw.line([(0, 95), (31, 95)], fill=(35, 40, 50, 255))
    draw.rectangle([3, 67, 5, 69], fill=(180, 190, 210, 255))
    draw.rectangle([26, 67, 28, 69], fill=(180, 190, 210, 255))
    draw.rectangle([3, 90, 5, 92], fill=(180, 190, 210, 255))
    draw.rectangle([26, 90, 28, 92], fill=(180, 190, 210, 255))

    # Sector 2 Subterranean Rust Wall (40, 64, 32x32)
    draw.rectangle([40, 64, 71, 95], fill=(95, 55, 40, 255), outline=(150, 95, 70, 255))
    draw.line([(40, 64), (71, 64)], fill=(180, 120, 90, 255))
    draw.line([(40, 95), (71, 95)], fill=(45, 25, 15, 255))
    draw.rectangle([44, 72, 67, 78], fill=(50, 30, 20, 255)) # vent grate
    draw.line([(48, 72), (48, 78)], fill=(150, 95, 70, 255))
    draw.line([(56, 72), (56, 78)], fill=(150, 95, 70, 255))
    draw.line([(64, 72), (64, 78)], fill=(150, 95, 70, 255))

    # Sector 3 Orbital Purple Alloy (80, 64, 32x32)
    draw.rectangle([80, 64, 111, 95], fill=(45, 30, 70, 255), outline=(75, 185, 245, 255))
    draw.line([(80, 64), (111, 64)], fill=(120, 220, 255, 255))
    draw.line([(80, 95), (111, 95)], fill=(20, 12, 35, 255))
    draw.rectangle([86, 70, 105, 89], fill=(30, 20, 50, 255), outline=(60, 40, 90, 255))

    # Ladder (120, 64, 32x32)
    draw.line([(126, 64), (126, 95)], fill=(225, 175, 45, 255), width=3)
    draw.line([(146, 64), (146, 95)], fill=(225, 175, 45, 255), width=3)
    for ly in range(70, 95, 8):
        draw.line([(126, ly), (146, ly)], fill=(225, 175, 45, 255), width=2)

    # Overhead Pipe (160, 64, 32x32)
    draw.rectangle([160, 70, 191, 80], fill=(145, 155, 170, 255), outline=(85, 95, 110, 255))
    draw.line([(160, 71), (191, 71)], fill=(220, 230, 245, 255))
    draw.rectangle([164, 68, 168, 82], fill=(85, 95, 110, 255))
    draw.rectangle([183, 68, 187, 82], fill=(85, 95, 110, 255))

    # Red Door (200, 64, 32x32)
    draw.rectangle([200, 64, 231, 95], fill=(215, 40, 45, 255), outline=(130, 20, 25, 255))
    draw.rectangle([208, 72, 224, 86], fill=(50, 10, 15, 255), outline=(255, 100, 100, 255))
    draw.ellipse([214, 76, 218, 80], fill=(255, 220, 80, 255))

    # Blue Door (240, 64, 32x32)
    draw.rectangle([240, 64, 271, 95], fill=(40, 95, 225, 255), outline=(20, 50, 135, 255))
    draw.rectangle([248, 72, 264, 86], fill=(10, 20, 55, 255), outline=(100, 160, 255, 255))
    draw.ellipse([254, 76, 258, 80], fill=(255, 220, 80, 255))

    # Green Door (280, 64, 32x32)
    draw.rectangle([280, 64, 311, 95], fill=(40, 195, 75, 255), outline=(15, 105, 35, 255))
    draw.rectangle([288, 72, 304, 86], fill=(10, 50, 20, 255), outline=(100, 255, 140, 255))
    draw.ellipse([294, 76, 298, 80], fill=(255, 220, 80, 255))

    # Toxic Acid Vat (320, 64, 32x32)
    draw.rectangle([320, 68, 351, 95], fill=(45, 235, 60, 255), outline=(20, 140, 30, 255))
    draw.ellipse([324, 66, 332, 74], fill=(180, 255, 100, 255))
    draw.ellipse([338, 65, 348, 75], fill=(180, 255, 100, 255))

    # Exit Extraction Pad (360, 64, 32x32)
    draw.rectangle([360, 64, 391, 95], fill=(30, 45, 75, 255), outline=(50, 200, 255, 255))
    draw.ellipse([364, 68, 388, 92], fill=(40, 160, 240, 180), outline=(200, 245, 255, 255))
    draw.ellipse([370, 74, 382, 86], fill=(255, 255, 255, 255))

    # Elevator Platform (400, 64, 48x16)
    draw.rectangle([400, 72, 447, 87], fill=(240, 190, 30, 255), outline=(120, 90, 10, 255))
    for dx in range(0, 48, 12):
        draw.line([(400 + dx, 72), (400 + dx + 6, 87)], fill=(20, 20, 20, 255), width=2)


def draw_props(draw: ImageDraw.ImageDraw) -> None:
    # Row 2 (Y = 128..191)
    # Surveillance Camera (0, 128, 32x32)
    draw.rectangle([6, 134, 26, 148], fill=(155, 165, 180, 255), outline=(85, 95, 110, 255))
    draw.rectangle([18, 138, 24, 144], fill=(255, 30, 40, 255)) # flashing red lens
    draw.ellipse([19, 139, 21, 141], fill=(255, 255, 255, 255))
    draw.line([(2, 134), (8, 138)], fill=(85, 95, 110, 255), width=2) # mount arm

    # Toxic Waste Barrel (40, 128, 32x32)
    draw.rounded_rectangle([44, 130, 68, 158], radius=4, fill=(40, 190, 55, 255), outline=(20, 110, 30, 255), width=2)
    draw.rectangle([44, 136, 68, 138], fill=(20, 110, 30, 255))
    draw.rectangle([44, 150, 68, 152], fill=(20, 110, 30, 255))
    # Biohazard Emblem
    draw.ellipse([52, 140, 60, 148], fill=(250, 220, 30, 255))
    draw.ellipse([54, 142, 58, 146], fill=(20, 20, 20, 255))

    # Supply Crate (80, 128, 32x32)
    draw.rectangle([82, 130, 109, 157], fill=(150, 100, 50, 255), outline=(80, 50, 20, 255), width=2)
    draw.line([(82, 130), (109, 157)], fill=(80, 50, 20, 255), width=2)
    draw.line([(82, 157), (109, 130)], fill=(80, 50, 20, 255), width=2)
    draw.rectangle([82, 130, 86, 134], fill=(190, 195, 205, 255))
    draw.rectangle([105, 130, 109, 134], fill=(190, 195, 205, 255))
    draw.rectangle([82, 153, 86, 157], fill=(190, 195, 205, 255))
    draw.rectangle([105, 153, 109, 157], fill=(190, 195, 205, 255))


def draw_items(draw: ImageDraw.ImageDraw) -> None:
    # Row 3 (Y = 192..255)
    # Soda Can (0, 192, 32x32)
    draw.rounded_rectangle([10, 198, 22, 218], radius=2, fill=(225, 30, 45, 255), outline=(130, 15, 25, 255))
    draw.rectangle([11, 198, 21, 200], fill=(220, 225, 235, 255))
    draw.line([(10, 207), (22, 207)], fill=(255, 255, 255, 255), width=2)

    # Roast Turkey (40, 192, 32x32)
    draw.ellipse([46, 200, 66, 216], fill=(200, 120, 45, 255), outline=(120, 65, 20, 255))
    draw.rectangle([64, 205, 72, 211], fill=(245, 240, 230, 255))

    # Red Keycard (80, 192, 32x32)
    draw.rounded_rectangle([86, 200, 106, 216], radius=2, fill=(240, 40, 45, 255), outline=(255, 200, 200, 255), width=2)
    draw.rectangle([90, 204, 96, 212], fill=(255, 215, 60, 255))

    # Blue Keycard (120, 192, 32x32)
    draw.rounded_rectangle([126, 200, 146, 216], radius=2, fill=(40, 110, 250, 255), outline=(200, 230, 255, 255), width=2)
    draw.rectangle([130, 204, 136, 212], fill=(255, 215, 60, 255))

    # Green Keycard (160, 192, 32x32)
    draw.rounded_rectangle([166, 200, 186, 216], radius=2, fill=(40, 220, 65, 255), outline=(200, 255, 210, 255), width=2)
    draw.rectangle([170, 204, 176, 212], fill=(255, 215, 60, 255))

    # Floppy Disk (200, 192, 32x32)
    draw.rounded_rectangle([204, 198, 228, 222], radius=2, fill=(35, 40, 60, 255), outline=(180, 190, 210, 255))
    draw.rectangle([208, 198, 222, 206], fill=(190, 195, 205, 255))
    draw.rectangle([209, 212, 223, 222], fill=(245, 245, 255, 255))

    # Circuit Board (240, 192, 32x32)
    draw.rounded_rectangle([244, 198, 268, 222], radius=2, fill=(25, 125, 55, 255), outline=(180, 240, 190, 255))
    draw.rectangle([250, 204, 262, 216], fill=(20, 20, 30, 255))
    draw.line([(244, 210), (250, 210)], fill=(255, 215, 60, 255), width=2)
    draw.line([(262, 210), (268, 210)], fill=(255, 215, 60, 255), width=2)

    # Dual Laser Weapon Pickup (280, 192, 32x32)
    draw.rounded_rectangle([284, 198, 308, 220], radius=4, fill=(255, 215, 0, 255), outline=(130, 95, 10, 255), width=2)
    draw.line([(288, 206), (304, 206)], fill=(40, 220, 255, 255), width=2)
    draw.line([(288, 212), (304, 212)], fill=(40, 220, 255, 255), width=2)

    # Flamethrower Weapon Pickup (320, 192, 32x32)
    draw.rounded_rectangle([324, 198, 348, 220], radius=4, fill=(255, 215, 0, 255), outline=(130, 95, 10, 255), width=2)
    draw.ellipse([330, 204, 342, 216], fill=(255, 100, 25, 255), outline=(255, 220, 60, 255))

    # Micro Missile Weapon Pickup (360, 192, 32x32)
    draw.rounded_rectangle([364, 198, 388, 220], radius=4, fill=(255, 215, 0, 255), outline=(130, 95, 10, 255), width=2)
    draw.polygon([(382, 209), (370, 204), (370, 214)], fill=(225, 230, 240, 255))


def draw_enemies(draw: ImageDraw.ImageDraw) -> None:
    # Row 4 (Y = 256..335)
    # Robodroid Frame 1 (0, 256, 32x32)
    draw.ellipse([4, 260, 28, 284], fill=(140, 50, 185, 255), outline=(200, 120, 245, 255), width=2)
    draw.rectangle([8, 268, 24, 274], fill=(255, 40, 50, 255)) # red scan visor
    draw.line([(8, 284), (4, 288)], fill=(180, 190, 205, 255), width=2)
    draw.line([(24, 284), (28, 288)], fill=(180, 190, 205, 255), width=2)

    # Robodroid Frame 2 (48, 256, 32x32)
    draw.ellipse([52, 262, 76, 286], fill=(140, 50, 185, 255), outline=(200, 120, 245, 255), width=2)
    draw.rectangle([56, 270, 72, 276], fill=(255, 200, 60, 255))
    draw.line([(56, 286), (52, 292)], fill=(180, 190, 205, 255), width=2)
    draw.line([(72, 286), (76, 292)], fill=(180, 190, 205, 255), width=2)

    # Turret Facing Left (96, 256, 32x32)
    draw.rectangle([102, 270, 122, 286], fill=(85, 90, 105, 255), outline=(130, 140, 160, 255))
    draw.rectangle([96, 274, 104, 280], fill=(200, 205, 220, 255)) # gun barrel
    draw.ellipse([110, 272, 116, 278], fill=(255, 40, 40, 255)) # laser sensor

    # Turret Facing Right (144, 256, 32x32)
    draw.rectangle([148, 270, 168, 286], fill=(85, 90, 105, 255), outline=(130, 140, 160, 255))
    draw.rectangle([166, 274, 174, 280], fill=(200, 205, 220, 255))
    draw.ellipse([154, 272, 160, 278], fill=(255, 40, 40, 255))

    # Mutant Slime Frame 1 (192, 256, 32x32)
    draw.ellipse([196, 268, 220, 286], fill=(55, 240, 85, 255), outline=(20, 140, 40, 255), width=2)
    draw.ellipse([202, 272, 206, 276], fill=(255, 225, 40, 255))
    draw.ellipse([210, 272, 214, 276], fill=(255, 225, 40, 255))

    # Mutant Slime Frame 2 (240, 256, 32x32)
    draw.ellipse([242, 266, 270, 288], fill=(55, 240, 85, 255), outline=(20, 140, 40, 255), width=2)
    draw.ellipse([250, 274, 254, 278], fill=(255, 225, 40, 255))
    draw.ellipse([258, 274, 262, 278], fill=(255, 225, 40, 255))


def draw_boss(draw: ImageDraw.ImageDraw) -> None:
    # Row 5: Goliath Boss Mech (0, 336, 80x80)
    ox = 0
    oy = 336
    # Main Heavy Chassis
    draw.rounded_rectangle([ox + 8, oy + 8, ox + 72, oy + 64], radius=8, fill=(120, 30, 165, 255), outline=(195, 80, 245, 255), width=3)
    # Armor Plating & Vents
    draw.rectangle([ox + 16, oy + 42, ox + 64, oy + 58], fill=(65, 15, 90, 255), outline=(130, 45, 175, 255))
    # Glowing Crimson Cockpit Visor
    draw.rectangle([ox + 20, oy + 20, ox + 60, oy + 32], fill=(255, 30, 40, 255), outline=(255, 200, 200, 255), width=2)
    draw.rectangle([ox + 34, oy + 23, ox + 46, oy + 29], fill=(255, 240, 240, 255))

    # Twin Heavy Plasma Gatling Cannons
    draw.rectangle([ox - 4, oy + 26, ox + 10, oy + 36], fill=(190, 195, 210, 255), outline=(90, 95, 110, 255))
    draw.rectangle([ox - 4, oy + 46, ox + 10, oy + 56], fill=(190, 195, 210, 255), outline=(90, 95, 110, 255))

    # Heavy Hydraulic Legs
    draw.rectangle([ox + 16, oy + 64, ox + 28, oy + 76], fill=(60, 65, 80, 255))
    draw.rectangle([ox + 52, oy + 64, ox + 64, oy + 76], fill=(60, 65, 80, 255))
    draw.rectangle([ox + 12, oy + 74, ox + 32, oy + 79], fill=(190, 195, 210, 255))
    draw.rectangle([ox + 48, oy + 74, ox + 68, oy + 79], fill=(190, 195, 210, 255))


def draw_projectiles(draw: ImageDraw.ImageDraw) -> None:
    # Row 6 (Y = 440..511)
    # Blaster Plasma Bolt (0, 440, 32x32)
    draw.ellipse([8, 448, 24, 464], fill=(255, 220, 50, 255), outline=(255, 255, 255, 255), width=2)

    # Dual Laser Beam (40, 440, 32x32)
    draw.rectangle([44, 450, 68, 454], fill=(40, 220, 255, 255))
    draw.rectangle([44, 458, 68, 462], fill=(40, 220, 255, 255))

    # Flamethrower Fireball (80, 440, 32x32)
    draw.ellipse([84, 444, 108, 468], fill=(255, 110, 25, 255), outline=(255, 225, 60, 255), width=2)
    draw.ellipse([90, 450, 102, 462], fill=(255, 240, 120, 255))

    # Micro Missile (120, 440, 32x32)
    draw.polygon([(144, 456), (128, 450), (128, 462)], fill=(225, 230, 245, 255), outline=(120, 130, 150, 255))
    draw.ellipse([122, 453, 128, 459], fill=(255, 120, 30, 255))

    # Enemy Plasma Bolt (160, 440, 32x32)
    draw.ellipse([168, 448, 184, 464], fill=(255, 40, 50, 255), outline=(255, 200, 200, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sprites_dir = root / "assets" / "sprites"
    sprites_dir.mkdir(parents=True, exist_ok=True)
    out_path = sprites_dir / "duke.png"

    sheet = Image.new("RGBA", (SHEET_W, SHEET_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # 1. Duke Animations (Row 0)
    states = [
        "idle", "walk1", "walk2", "tumble1", "tumble2",
        "crouch", "aim_up", "climb1", "climb2", "hang1", "hang2", "victory"
    ]
    for i, st in enumerate(states):
        draw_duke(draw, i * 48, 0, state=st)

    # 2. Tiles (Row 1)
    draw_tiles(draw)

    # 3. Props (Row 2)
    draw_props(draw)

    # 4. Items (Row 3)
    draw_items(draw)

    # 5. Enemies (Row 4)
    draw_enemies(draw)

    # 6. Boss Mech (Row 5)
    draw_boss(draw)

    # 7. Projectiles (Row 6)
    draw_projectiles(draw)

    sheet.save(out_path, format="PNG")
    print(f"Generated Duke Nukem sprite sheet successfully at {out_path} ({SHEET_W}x{SHEET_H})")


if __name__ == "__main__":
    main()
