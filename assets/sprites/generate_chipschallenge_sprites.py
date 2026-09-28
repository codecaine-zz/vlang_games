#!/usr/bin/env python3
"""Generate high-fidelity 512x512 RGBA sprite sheet for Chip's Challenge Deluxe:
Tiles & Sprites (32x32 each):
- Row 0 (Y=0..31): Chip (Player) in 4 directions: Down, Up, Left, Right (Walk 1 & Walk 2)
- Row 1 (Y=32..63): Chip Equipment variants: Swimming Flippers, Fire Boots, Ice Skates, Drowning/Dead
- Row 2 (Y=64..95): Basic Tiles: Floor, Mosaic Wall, Dirt Block, Dirt Floor, Ice Floor
- Row 3 (Y=96..127): Hazards: Water (4 animation frames), Fire (4 animation frames)
- Row 4 (Y=128..159): Keys & Doors: Red Key, Blue Key, Yellow Key, Green Key, Red Door, Blue Door, Yellow Door, Green Door
- Row 5 (Y=160..191): Collectibles & Items: Microchip (4 gleam frames), Chip Socket, Exit Portal (4 vortex frames), Hint Pad
- Row 6 (Y=192..223): Power Boots: Flippers, Fire Boots, Ice Skates, Suction Boots
- Row 7 (Y=224..255): Monsters & Traps: Bug/Ant, Fireball, Glider, Tank, Trap Tile, Button
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512
CELL = 32


def draw_chip_character(draw: ImageDraw.ImageDraw, ox: int, oy: int, facing: str = "down", step: int = 0, variant: str = "normal") -> None:
    # variant: normal, flippers, fire_boots, skates, dead
    if variant == "dead":
        # Scorched / dizzy skull chip
        draw.ellipse((ox + 6, oy + 6, ox + 26, oy + 26), fill=(100, 100, 100, 255), outline=(239, 68, 68, 255), width=2)
        # X eyes
        draw.line([(ox + 10, oy + 12), (ox + 14, oy + 16)], fill=(239, 68, 68, 255), width=2)
        draw.line([(ox + 14, oy + 12), (ox + 10, oy + 16)], fill=(239, 68, 68, 255), width=2)
        draw.line([(ox + 18, oy + 12), (ox + 22, oy + 16)], fill=(239, 68, 68, 255), width=2)
        draw.line([(ox + 22, oy + 12), (ox + 18, oy + 16)], fill=(239, 68, 68, 255), width=2)
        return

    # 1. Shoes / Boots
    boot_col = (30, 41, 59, 255)
    if variant == "flippers":
        boot_col = (34, 211, 238, 255)
    elif variant == "fire_boots":
        boot_col = (239, 68, 68, 255)
    elif variant == "skates":
        boot_col = (226, 232, 240, 255)

    leg_l_y = oy + 24 + (2 if step == 1 else 0)
    leg_r_y = oy + 24 + (2 if step == 2 else 0)
    draw.rectangle((ox + 8, leg_l_y, ox + 14, oy + 29), fill=boot_col)
    draw.rectangle((ox + 18, leg_r_y, ox + 24, oy + 29), fill=boot_col)

    # 2. Blue Jeans Pants
    draw.rectangle((ox + 8, oy + 18, ox + 24, oy + 25), fill=(30, 64, 175, 255), outline=(30, 58, 138, 255))

    # 3. Yellow Shirt / Torso
    draw.rectangle((ox + 7, oy + 11, ox + 25, oy + 19), fill=(245, 158, 11, 255), outline=(217, 119, 6, 255))
    # Shirt collar
    draw.polygon([(ox + 13, oy + 11), (ox + 16, oy + 15), (ox + 19, oy + 11)], fill=(255, 255, 255, 255))

    # 4. Hands / Arms
    if facing in ("left", "down", "right"):
        draw.rectangle((ox + 4, oy + 13 + (1 if step == 1 else 0), ox + 7, oy + 18), fill=(254, 215, 170, 255))
        draw.rectangle((ox + 25, oy + 13 + (1 if step == 2 else 0), ox + 28, oy + 18), fill=(254, 215, 170, 255))

    # 5. Head (Skin tone)
    draw.rectangle((ox + 9, oy + 4, ox + 23, oy + 13), fill=(254, 215, 170, 255))

    # 6. Red Baseball Cap (Backwards / visor)
    draw.rectangle((ox + 8, oy + 2, ox + 24, oy + 7), fill=(220, 38, 38, 255))
    if facing == "down":
        # Front visor or cap button
        draw.ellipse((ox + 14, oy + 1, ox + 18, oy + 4), fill=(185, 28, 28, 255))
        # Eyes looking down
        draw.rectangle((ox + 11, oy + 8, ox + 14, oy + 11), fill=(15, 23, 42, 255))
        draw.rectangle((ox + 18, oy + 8, ox + 21, oy + 11), fill=(15, 23, 42, 255))
        draw.rectangle((ox + 12, oy + 8, ox + 13, oy + 9), fill=(255, 255, 255, 255))
        draw.rectangle((ox + 19, oy + 8, ox + 20, oy + 9), fill=(255, 255, 255, 255))
    elif facing == "up":
        # Back of cap with strap
        draw.rectangle((ox + 13, oy + 5, ox + 19, oy + 7), fill=(185, 28, 28, 255))
    elif facing == "left":
        # Visor facing left
        draw.polygon([(ox + 6, oy + 5), (ox + 9, oy + 3), (ox + 9, oy + 7)], fill=(185, 28, 28, 255))
        draw.rectangle((ox + 10, oy + 8, ox + 13, oy + 11), fill=(15, 23, 42, 255))
    elif facing == "right":
        # Visor facing right
        draw.polygon([(ox + 26, oy + 5), (ox + 23, oy + 3), (ox + 23, oy + 7)], fill=(185, 28, 28, 255))
        draw.rectangle((ox + 19, oy + 8, ox + 22, oy + 11), fill=(15, 23, 42, 255))


def draw_wall(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Classic Windows 95 blue mosaic brick
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(30, 58, 138, 255), outline=(59, 130, 246, 255))
    # Bevel highlight & shadow
    draw.line([(ox, oy), (ox + 31, oy)], fill=(96, 165, 250, 255), width=2)
    draw.line([(ox, oy), (ox, oy + 31)], fill=(96, 165, 250, 255), width=2)
    draw.line([(ox + 31, oy), (ox + 31, oy + 31)], fill=(15, 23, 42, 255), width=2)
    draw.line([(ox, oy + 31), (ox + 31, oy + 31)], fill=(15, 23, 42, 255), width=2)

    # Brick pattern grooves
    draw.line([(ox + 2, oy + 10), (ox + 30, oy + 10)], fill=(30, 64, 175, 255), width=1)
    draw.line([(ox + 2, oy + 20), (ox + 30, oy + 20)], fill=(30, 64, 175, 255), width=1)
    draw.line([(ox + 16, oy + 2), (ox + 16, oy + 10)], fill=(30, 64, 175, 255), width=1)
    draw.line([(ox + 8, oy + 10), (ox + 8, oy + 20)], fill=(30, 64, 175, 255), width=1)
    draw.line([(ox + 24, oy + 10), (ox + 24, oy + 20)], fill=(30, 64, 175, 255), width=1)
    draw.line([(ox + 16, oy + 20), (ox + 16, oy + 30)], fill=(30, 64, 175, 255), width=1)


def draw_floor(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Smooth light gray stone floor
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(212, 212, 216, 255), outline=(161, 161, 170, 255))
    draw.line([(ox + 1, oy + 1), (ox + 30, oy + 1)], fill=(244, 244, 245, 255), width=1)
    draw.line([(ox + 1, oy + 1), (ox + 1, oy + 30)], fill=(244, 244, 245, 255), width=1)


def draw_dirt_block(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # 3D Pushable dirt/stone boulder
    draw.rectangle((ox + 2, oy + 2, ox + 29, oy + 29), fill=(180, 83, 9, 255), outline=(120, 53, 15, 255), width=2)
    # Bevel highlight
    draw.line([(ox + 3, oy + 3), (ox + 28, oy + 3)], fill=(245, 158, 11, 255), width=2)
    draw.line([(ox + 3, oy + 3), (ox + 3, oy + 28)], fill=(245, 158, 11, 255), width=2)
    # Soil speckles
    draw.rectangle((ox + 8, oy + 8, ox + 12, oy + 12), fill=(146, 64, 14, 255))
    draw.rectangle((ox + 18, oy + 16, ox + 22, oy + 20), fill=(146, 64, 14, 255))
    draw.rectangle((ox + 10, oy + 20, ox + 13, oy + 23), fill=(217, 119, 6, 255))


def draw_dirt_floor(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Filled water / compacted dirt
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(161, 98, 7, 255), outline=(113, 63, 18, 255))
    for sx, sy in [(6, 6), (20, 8), (12, 18), (22, 22), (6, 24)]:
        draw.ellipse((ox + sx, oy + sy, ox + sx + 3, oy + sy + 3), fill=(113, 63, 18, 255))


def draw_ice_floor(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Glistening slippery cyan ice
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(186, 230, 253, 255), outline=(56, 189, 248, 255))
    # Ice cracks & shine
    draw.line([(ox + 4, oy + 8), (ox + 14, oy + 16)], fill=(255, 255, 255, 240), width=1)
    draw.line([(ox + 14, oy + 16), (ox + 22, oy + 12)], fill=(255, 255, 255, 240), width=1)
    draw.line([(ox + 10, oy + 24), (ox + 26, oy + 22)], fill=(255, 255, 255, 240), width=1)


def draw_water_frame(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int) -> None:
    # Animated deep blue water with ripple waves
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(2, 132, 199, 255), outline=(3, 105, 161, 255))
    shift = frame * 6
    for y_wave in [8, 16, 24]:
        w_pts = []
        for x_i in range(0, 32, 4):
            y_off = int(math.sin((x_i + shift) * 0.4) * 2.5)
            w_pts.append((ox + x_i, oy + y_wave + y_off))
        for p_i in range(len(w_pts) - 1):
            draw.line([w_pts[p_i], w_pts[p_i + 1]], fill=(186, 230, 253, 220), width=2)


def draw_fire_frame(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int) -> None:
    # Animated roaring fire pit
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(127, 29, 29, 255), outline=(239, 68, 68, 255))
    # Base coals
    draw.ellipse((ox + 4, oy + 18, ox + 27, oy + 29), fill=(220, 38, 38, 255))
    # Animated flame tongues
    f_shift = (frame * 3) % 4
    draw.polygon([(ox + 8, oy + 24), (ox + 12 + f_shift, oy + 4), (ox + 16, oy + 24)], fill=(245, 158, 11, 255))
    draw.polygon([(ox + 14, oy + 24), (ox + 19 - f_shift, oy + 2), (ox + 24, oy + 24)], fill=(251, 191, 36, 255))
    draw.polygon([(ox + 12, oy + 24), (ox + 16, oy + 8), (ox + 20, oy + 24)], fill=(255, 255, 255, 240))


def draw_key(draw: ImageDraw.ImageDraw, ox: int, oy: int, color: tuple[int, int, int]) -> None:
    # Antique ornate key with gem handle
    draw_floor(draw, ox, oy)
    # Head ring
    draw.ellipse((ox + 6, oy + 10, ox + 16, oy + 22), fill=(*color, 255), outline=(255, 255, 255, 240), width=2)
    draw.ellipse((ox + 9, oy + 13, ox + 13, oy + 19), fill=(212, 212, 216, 255))
    # Shaft
    draw.rectangle((ox + 14, oy + 14, ox + 26, oy + 18), fill=(*color, 255), outline=(255, 255, 255, 200), width=1)
    # Teeth
    draw.rectangle((ox + 22, oy + 18, ox + 25, oy + 23), fill=(*color, 255))
    draw.rectangle((ox + 18, oy + 18, ox + 20, oy + 22), fill=(*color, 255))


def draw_door(draw: ImageDraw.ImageDraw, ox: int, oy: int, color: tuple[int, int, int]) -> None:
    # Heavy reinforced security door with keyhole
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(*color, 255), outline=(255, 255, 255, 240), width=2)
    # Door frame bevel
    draw.rectangle((ox + 4, oy + 4, ox + 27, oy + 27), fill=(*color, 255), outline=(15, 23, 42, 200), width=2)
    # Keyhole
    draw.ellipse((ox + 13, oy + 11, ox + 18, oy + 16), fill=(15, 23, 42, 255))
    draw.polygon([(ox + 14, oy + 14), (ox + 17, oy + 14), (ox + 19, oy + 22), (ox + 12, oy + 22)], fill=(15, 23, 42, 255))


def draw_microchip(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int) -> None:
    draw_floor(draw, ox, oy)
    # IC Black ceramic package
    draw.rectangle((ox + 7, oy + 7, ox + 24, oy + 24), fill=(24, 24, 27, 255), outline=(113, 113, 122, 255), width=1)
    # Gold pins
    for pin_i in [10, 14, 18, 21]:
        draw.line([(ox + 3, oy + pin_i), (ox + 7, oy + pin_i)], fill=(234, 179, 8, 255), width=2)
        draw.line([(ox + 24, oy + pin_i), (ox + 28, oy + pin_i)], fill=(234, 179, 8, 255), width=2)
    # Core crystal / gleam
    gleam_col = [(34, 211, 238), (250, 204, 21), (255, 255, 255), (34, 197, 94)][frame % 4]
    draw.rectangle((ox + 11, oy + 11, ox + 20, oy + 20), fill=(*gleam_col, 240), outline=(255, 255, 255, 255))
    # IC Notch
    draw.ellipse((ox + 14, oy + 6, ox + 17, oy + 9), fill=(113, 113, 122, 255))


def draw_socket(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    # Chip socket barrier with red hazard stripes
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(185, 28, 28, 255), outline=(239, 68, 68, 255), width=2)
    # Diagonal yellow stripes
    for d_off in range(-20, 50, 10):
        draw.line([(ox + d_off, oy), (ox + d_off + 32, oy + 32)], fill=(250, 204, 21, 255), width=3)
    # Center lock receptacle
    draw.rectangle((ox + 9, oy + 9, ox + 22, oy + 22), fill=(15, 23, 42, 255), outline=(255, 255, 255, 255))
    draw.rectangle((ox + 12, oy + 12, ox + 19, oy + 19), fill=(239, 68, 68, 255))


def draw_exit_portal(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int) -> None:
    # Swirling vortex portal
    draw.rectangle((ox, oy, ox + 31, oy + 31), fill=(15, 23, 42, 255), outline=(34, 211, 238, 255), width=1)
    angles = [(0, 180), (45, 225), (90, 270), (135, 315)][frame % 4]
    draw.ellipse((ox + 3, oy + 3, ox + 28, oy + 28), outline=(6, 182, 212, 255), width=2)
    draw.ellipse((ox + 7, oy + 7, ox + 24, oy + 24), fill=(14, 165, 233, 200), outline=(255, 255, 255, 255), width=2)
    draw.ellipse((ox + 12, oy + 12, ox + 19, oy + 19), fill=(255, 255, 255, 255))


def draw_hint_tile(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    draw_floor(draw, ox, oy)
    # Question mark tile
    draw.ellipse((ox + 4, oy + 4, ox + 27, oy + 27), fill=(254, 240, 138, 255), outline=(234, 179, 8, 255), width=2)
    # '?'
    draw.arc((ox + 10, oy + 8, ox + 21, oy + 18), start=180, end=0, fill=(15, 23, 42, 255), width=3)
    draw.line([(ox + 21, oy + 13), (ox + 16, oy + 18)], fill=(15, 23, 42, 255), width=3)
    draw.line([(ox + 16, oy + 18), (ox + 16, oy + 21)], fill=(15, 23, 42, 255), width=3)
    draw.ellipse((ox + 14, oy + 23, ox + 17, oy + 26), fill=(15, 23, 42, 255))


def draw_boots_item(draw: ImageDraw.ImageDraw, ox: int, oy: int, kind: str) -> None:
    draw_floor(draw, ox, oy)
    if kind == "flippers":
        # Aqua diving flippers
        draw.polygon([(ox + 6, oy + 18), (ox + 12, oy + 6), (ox + 16, oy + 18)], fill=(6, 182, 212, 255), outline=(255, 255, 255, 240))
        draw.polygon([(ox + 16, oy + 18), (ox + 22, oy + 6), (ox + 26, oy + 18)], fill=(6, 182, 212, 255), outline=(255, 255, 255, 240))
        draw.rectangle((ox + 8, oy + 18, ox + 24, oy + 26), fill=(14, 116, 144, 255))
    elif kind == "fire_boots":
        # Red fire insulated boots
        draw.rectangle((ox + 6, oy + 10, ox + 14, oy + 24), fill=(239, 68, 68, 255), outline=(245, 158, 11, 255), width=2)
        draw.rectangle((ox + 17, oy + 10, ox + 25, oy + 24), fill=(239, 68, 68, 255), outline=(245, 158, 11, 255), width=2)
        draw.polygon([(ox + 6, oy + 20), (ox + 2, oy + 26), (ox + 14, oy + 26)], fill=(245, 158, 11, 255))
        draw.polygon([(ox + 17, oy + 20), (ox + 13, oy + 26), (ox + 25, oy + 26)], fill=(245, 158, 11, 255))
    elif kind == "ice_skates":
        # Silver ice skates
        draw.rectangle((ox + 7, oy + 10, ox + 14, oy + 22), fill=(226, 232, 240, 255), outline=(100, 116, 139, 255))
        draw.rectangle((ox + 17, oy + 10, ox + 24, oy + 22), fill=(226, 232, 240, 255), outline=(100, 116, 139, 255))
        # Blades
        draw.line([(ox + 4, oy + 26), (ox + 16, oy + 26)], fill=(56, 189, 248, 255), width=2)
        draw.line([(ox + 15, oy + 26), (ox + 27, oy + 26)], fill=(56, 189, 248, 255), width=2)
    elif kind == "suction_boots":
        # Green magnetic suction boots
        draw.rectangle((ox + 6, oy + 10, ox + 14, oy + 22), fill=(34, 197, 94, 255), outline=(255, 255, 255, 255))
        draw.rectangle((ox + 17, oy + 10, ox + 25, oy + 22), fill=(34, 197, 94, 255), outline=(255, 255, 255, 255))
        # Suction cups
        draw.ellipse((ox + 4, oy + 22, ox + 15, oy + 27), fill=(22, 101, 52, 255))
        draw.ellipse((ox + 16, oy + 22, ox + 27, oy + 27), fill=(22, 101, 52, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0 (Y=0..31): Chip Walking (Down, Up, Left, Right)
    # -------------------------------------------------------------
    draw_chip_character(draw, 0 * CELL, 0, facing="down", step=0)
    draw_chip_character(draw, 1 * CELL, 0, facing="down", step=1)
    draw_chip_character(draw, 2 * CELL, 0, facing="up", step=0)
    draw_chip_character(draw, 3 * CELL, 0, facing="up", step=1)
    draw_chip_character(draw, 4 * CELL, 0, facing="left", step=0)
    draw_chip_character(draw, 5 * CELL, 0, facing="left", step=1)
    draw_chip_character(draw, 6 * CELL, 0, facing="right", step=0)
    draw_chip_character(draw, 7 * CELL, 0, facing="right", step=1)

    # -------------------------------------------------------------
    # Row 1 (Y=32..63): Chip Equipment variants (Flippers, Fire Boots, Skates, Dead)
    # -------------------------------------------------------------
    draw_chip_character(draw, 0 * CELL, 1 * CELL, facing="down", step=0, variant="flippers")
    draw_chip_character(draw, 1 * CELL, 1 * CELL, facing="down", step=1, variant="flippers")
    draw_chip_character(draw, 2 * CELL, 1 * CELL, facing="down", step=0, variant="fire_boots")
    draw_chip_character(draw, 3 * CELL, 1 * CELL, facing="down", step=1, variant="fire_boots")
    draw_chip_character(draw, 4 * CELL, 1 * CELL, facing="down", step=0, variant="skates")
    draw_chip_character(draw, 5 * CELL, 1 * CELL, facing="down", step=1, variant="skates")
    draw_chip_character(draw, 6 * CELL, 1 * CELL, facing="down", step=0, variant="dead")

    # -------------------------------------------------------------
    # Row 2 (Y=64..95): Basic Tiles (Floor, Wall, Dirt Block, Dirt Floor, Ice Floor)
    # -------------------------------------------------------------
    draw_floor(draw, 0 * CELL, 2 * CELL)
    draw_wall(draw, 1 * CELL, 2 * CELL)
    draw_dirt_block(draw, 2 * CELL, 2 * CELL)
    draw_dirt_floor(draw, 3 * CELL, 2 * CELL)
    draw_ice_floor(draw, 4 * CELL, 2 * CELL)

    # -------------------------------------------------------------
    # Row 3 (Y=96..127): Hazards: Water (4 frames), Fire (4 frames)
    # -------------------------------------------------------------
    for f in range(4):
        draw_water_frame(draw, f * CELL, 3 * CELL, f)
        draw_fire_frame(draw, (4 + f) * CELL, 3 * CELL, f)

    # -------------------------------------------------------------
    # Row 4 (Y=128..159): Keys & Doors (Red, Blue, Yellow, Green)
    # -------------------------------------------------------------
    draw_key(draw, 0 * CELL, 4 * CELL, (220, 38, 38))
    draw_key(draw, 1 * CELL, 4 * CELL, (37, 99, 235))
    draw_key(draw, 2 * CELL, 4 * CELL, (234, 179, 8))
    draw_key(draw, 3 * CELL, 4 * CELL, (22, 163, 74))

    draw_door(draw, 4 * CELL, 4 * CELL, (185, 28, 28))
    draw_door(draw, 5 * CELL, 4 * CELL, (29, 78, 216))
    draw_door(draw, 6 * CELL, 4 * CELL, (202, 138, 4))
    draw_door(draw, 7 * CELL, 4 * CELL, (21, 128, 61))

    # -------------------------------------------------------------
    # Row 5 (Y=160..191): Collectibles (Microchip 4 frames, Socket, Portal 4 frames, Hint)
    # -------------------------------------------------------------
    for f in range(4):
        draw_microchip(draw, f * CELL, 5 * CELL, f)
    draw_socket(draw, 4 * CELL, 5 * CELL)
    for f in range(4):
        draw_exit_portal(draw, (5 + f) * CELL, 5 * CELL, f)
    draw_hint_tile(draw, 9 * CELL, 5 * CELL)

    # -------------------------------------------------------------
    # Row 6 (Y=192..223): Power Boots Items
    # -------------------------------------------------------------
    draw_boots_item(draw, 0 * CELL, 6 * CELL, "flippers")
    draw_boots_item(draw, 1 * CELL, 6 * CELL, "fire_boots")
    draw_boots_item(draw, 2 * CELL, 6 * CELL, "ice_skates")
    draw_boots_item(draw, 3 * CELL, 6 * CELL, "suction_boots")

    out_path = root / "assets" / "sprites" / "chipschallenge.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    # Local symlink/dir
    local_path = root / "chipschallenge" / "assets" / "sprites" / "chipschallenge.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
