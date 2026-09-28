#!/usr/bin/env python3
"""Generate high-fidelity 1024x1024 RGBA sprite sheet for Vampire Survivors:
- 4 Player Classes (Antonio, Imelda, Pasqualina, Gennaro) with walk frames & portraits
- 8 Enemy Types (Bat, Skeleton, Zombie, Ghost, Mudman, Werewolf, Red Skull, Reaper Boss) with animations
- All 16 Weapons & Projectiles (Whip, Wand, Knife, Axe, Bible, Garlic, Lightning, Fireball, Nuke, Laser, Evolutions)
- Gems, Floor Pickups & Breakable Props (Exp gems, Chest, Vacuum, Rosary, Freeze Watch, Chicken, Coins, Candelabras, Urns, Tombstones, Cobblestone Tiles)
- UI Badges & Icons for Weapons and Passives
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

SHEET_W = 1024
SHEET_H = 1024


def draw_shading_rect(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], fill: tuple[int, int, int, int], outline: tuple[int, int, int, int] | None = None) -> None:
    x0, y0, x1, y1 = rect
    draw.rectangle([x0, y0, x1, y1], fill=fill, outline=outline)


def draw_antonio(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Shadow
    draw.ellipse([ox + 16, oy + 54, ox + 48, oy + 62], fill=(10, 10, 15, 140))
    walk_y = -2 if frame == 1 else 0
    leg_off = 4 if frame == 1 else 0

    # Red Belmont-style cape
    cape_pts = [
        (ox + 20, oy + 24 + walk_y),
        (ox + 44, oy + 24 + walk_y),
        (ox + 48 + (2 if frame == 1 else 0), oy + 52),
        (ox + 16 - (2 if frame == 1 else 0), oy + 52),
    ]
    draw.polygon(cape_pts, fill=(160, 28, 38, 255), outline=(90, 12, 20, 255))
    draw.line([(ox + 24, oy + 26 + walk_y), (ox + 22, oy + 50)], fill=(200, 45, 55, 255), width=2)

    # Leather Boots / Legs
    draw.rectangle([ox + 22, oy + 42, ox + 28, oy + 56 - leg_off], fill=(60, 40, 25, 255), outline=(30, 20, 12, 255))
    draw.rectangle([ox + 36, oy + 42, ox + 42, oy + 56 + leg_off], fill=(60, 40, 25, 255), outline=(30, 20, 12, 255))
    # Boot gold cuffs
    draw.rectangle([ox + 21, oy + 42, ox + 29, oy + 45], fill=(220, 175, 50, 255))
    draw.rectangle([ox + 35, oy + 42, ox + 43, oy + 45], fill=(220, 175, 50, 255))

    # Royal Blue / Slate Steel Armor Tunic
    draw.rectangle([ox + 22, oy + 24 + walk_y, ox + 42, oy + 42 + walk_y], fill=(45, 80, 155, 255), outline=(20, 40, 85, 255))
    # Golden cross breastplate emblem & belt
    draw.rectangle([ox + 20, oy + 38 + walk_y, ox + 44, oy + 42 + walk_y], fill=(180, 130, 30, 255), outline=(90, 60, 15, 255))
    draw.rectangle([ox + 30, oy + 37 + walk_y, ox + 34, oy + 43 + walk_y], fill=(255, 220, 80, 255))
    # Shoulder pauldrons
    draw.rectangle([ox + 18, oy + 22 + walk_y, ox + 25, oy + 29 + walk_y], fill=(180, 190, 210, 255), outline=(50, 60, 80, 255))
    draw.rectangle([ox + 39, oy + 22 + walk_y, ox + 46, oy + 29 + walk_y], fill=(180, 190, 210, 255), outline=(50, 60, 80, 255))

    # Head & Face
    draw.rectangle([ox + 25, oy + 12 + walk_y, ox + 39, oy + 24 + walk_y], fill=(255, 210, 170, 255), outline=(190, 140, 100, 255))
    # Brown Belmont Hair with headband
    draw.rectangle([ox + 23, oy + 8 + walk_y, ox + 41, oy + 16 + walk_y], fill=(90, 50, 25, 255), outline=(50, 25, 10, 255))
    draw.rectangle([ox + 23, oy + 14 + walk_y, ox + 41, oy + 17 + walk_y], fill=(220, 30, 40, 255)) # red headband
    # Eyes
    draw.rectangle([ox + 32, oy + 18 + walk_y, ox + 35, oy + 20 + walk_y], fill=(30, 40, 60, 255))

    # Whip Handle on belt
    draw.line([(ox + 43, oy + 32 + walk_y), (ox + 48, oy + 46 + walk_y)], fill=(120, 70, 30, 255), width=3)


def draw_imelda(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Shadow
    draw.ellipse([ox + 16, oy + 54, ox + 48, oy + 62], fill=(10, 10, 15, 140))
    walk_y = -2 if frame == 1 else 0

    # Flowing Violet Sorceress Robe
    robe_pts = [
        (ox + 24, oy + 22 + walk_y),
        (ox + 40, oy + 22 + walk_y),
        (ox + 48 + (3 if frame == 1 else 0), oy + 56),
        (ox + 16 - (3 if frame == 1 else 0), oy + 56),
    ]
    draw.polygon(robe_pts, fill=(130, 45, 160, 255), outline=(70, 20, 90, 255))
    # Gold trim and center sash
    draw.line([(ox + 32, oy + 22 + walk_y), (ox + 32, oy + 56)], fill=(255, 215, 60, 255), width=2)
    draw.rectangle([ox + 20, oy + 32 + walk_y, ox + 44, oy + 36 + walk_y], fill=(220, 180, 50, 255), outline=(120, 90, 20, 255))

    # Robe Sleeves
    draw.rectangle([ox + 16, oy + 24 + walk_y, ox + 23, oy + 38 + walk_y], fill=(150, 60, 180, 255), outline=(70, 20, 90, 255))
    draw.rectangle([ox + 41, oy + 24 + walk_y, ox + 48, oy + 38 + walk_y], fill=(150, 60, 180, 255), outline=(70, 20, 90, 255))

    # Face & Blonde Hair
    draw.rectangle([ox + 25, oy + 12 + walk_y, ox + 39, oy + 22 + walk_y], fill=(255, 215, 180, 255))
    draw.rectangle([ox + 22, oy + 10 + walk_y, ox + 42, oy + 28 + walk_y], fill=(245, 220, 120, 255))
    draw.rectangle([ox + 25, oy + 12 + walk_y, ox + 39, oy + 22 + walk_y], fill=(255, 215, 180, 255)) # face in front of back hair
    # Eyes
    draw.rectangle([ox + 32, oy + 16 + walk_y, ox + 35, oy + 18 + walk_y], fill=(40, 120, 180, 255))

    # Pointed Wizard Hat / Tiara
    hat_pts = [
        (ox + 14, oy + 12 + walk_y),
        (ox + 50, oy + 12 + walk_y),
        (ox + 40, oy - 2 + walk_y),
        (ox + 32, oy - 10 + walk_y),
        (ox + 24, oy - 2 + walk_y),
    ]
    draw.polygon(hat_pts, fill=(90, 25, 120, 255), outline=(50, 10, 70, 255))
    draw.rectangle([ox + 20, oy + 10 + walk_y, ox + 44, oy + 13 + walk_y], fill=(255, 215, 60, 255))

    # Magic Wand in Hand
    draw.line([(ox + 46, oy + 18 + walk_y), (ox + 54, oy + 4 + walk_y)], fill=(210, 175, 90, 255), width=2)
    draw.ellipse([ox + 52, oy + 2 + walk_y, ox + 58, oy + 8 + walk_y], fill=(80, 230, 255, 255), outline=(255, 255, 255, 255))


def draw_pasqualina(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Shadow
    draw.ellipse([ox + 16, oy + 54, ox + 48, oy + 62], fill=(10, 10, 15, 140))
    walk_y = -2 if frame == 1 else 0

    # Emerald Green Scholarly Cloak & Robe
    cloak_pts = [
        (ox + 22, oy + 22 + walk_y),
        (ox + 42, oy + 22 + walk_y),
        (ox + 48 + (2 if frame == 1 else 0), oy + 56),
        (ox + 16 - (2 if frame == 1 else 0), oy + 56),
    ]
    draw.polygon(cloak_pts, fill=(35, 130, 85, 255), outline=(15, 65, 40, 255))
    draw.rectangle([ox + 24, oy + 28 + walk_y, ox + 40, oy + 44 + walk_y], fill=(190, 140, 60, 255), outline=(110, 75, 25, 255))

    # Face & Auburn / Copper Hair
    draw.rectangle([ox + 22, oy + 10 + walk_y, ox + 42, oy + 26 + walk_y], fill=(200, 75, 40, 255))
    draw.rectangle([ox + 25, oy + 12 + walk_y, ox + 39, oy + 22 + walk_y], fill=(255, 215, 180, 255))
    draw.rectangle([ox + 32, oy + 16 + walk_y, ox + 35, oy + 18 + walk_y], fill=(30, 80, 50, 255))

    # Scholar Hood
    draw.arc([ox + 20, oy + 6 + walk_y, ox + 44, oy + 22 + walk_y], start=160, end=380, fill=(35, 130, 85, 255), width=4)

    # Holy Book / Grimoire in Arm
    draw.rectangle([ox + 42, oy + 28 + walk_y, ox + 54, oy + 42 + walk_y], fill=(140, 30, 30, 255), outline=(255, 215, 60, 255))
    draw.line([(ox + 48, oy + 31 + walk_y), (ox + 48, oy + 39 + walk_y)], fill=(255, 215, 60, 255), width=2)
    draw.line([(ox + 45, oy + 35 + walk_y), (ox + 51, oy + 35 + walk_y)], fill=(255, 215, 60, 255), width=2)


def draw_gennaro(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Shadow
    draw.ellipse([ox + 16, oy + 54, ox + 48, oy + 62], fill=(10, 10, 15, 140))
    walk_y = -2 if frame == 1 else 0
    leg_off = 4 if frame == 1 else 0

    # Crimson Assassin Leather Tunic & Cloak
    draw.rectangle([ox + 22, oy + 42, ox + 28, oy + 56 - leg_off], fill=(30, 30, 40, 255))
    draw.rectangle([ox + 36, oy + 42, ox + 42, oy + 56 + leg_off], fill=(30, 30, 40, 255))

    draw.rectangle([ox + 22, oy + 24 + walk_y, ox + 42, oy + 42 + walk_y], fill=(145, 35, 40, 255), outline=(75, 15, 20, 255))
    draw.rectangle([ox + 20, oy + 34 + walk_y, ox + 44, oy + 38 + walk_y], fill=(30, 30, 35, 255)) # black leather harness
    draw.line([(ox + 22, oy + 24 + walk_y), (ox + 42, oy + 42 + walk_y)], fill=(30, 30, 35, 255), width=2)

    # Face Mask & Dark Hood
    draw.rectangle([ox + 24, oy + 10 + walk_y, ox + 40, oy + 24 + walk_y], fill=(30, 30, 35, 255))
    draw.rectangle([ox + 26, oy + 14 + walk_y, ox + 38, oy + 19 + walk_y], fill=(255, 205, 170, 255))
    draw.rectangle([ox + 25, oy + 18 + walk_y, ox + 39, oy + 25 + walk_y], fill=(130, 30, 35, 255)) # red cloth rogue mask
    # Eyes
    draw.rectangle([ox + 32, oy + 15 + walk_y, ox + 35, oy + 17 + walk_y], fill=(255, 255, 255, 255))

    # Twin Daggers
    draw.line([(ox + 16, oy + 36 + walk_y), (ox + 12, oy + 48 + walk_y)], fill=(220, 230, 245, 255), width=3)
    draw.line([(ox + 48, oy + 36 + walk_y), (ox + 52, oy + 48 + walk_y)], fill=(220, 230, 245, 255), width=3)


def draw_portrait_badge(draw: ImageDraw.ImageDraw, ox: int, oy: int, char_class: str) -> None:
    # Ornate Gold Frame Badge 64x64
    draw.rounded_rectangle([ox + 2, oy + 2, ox + 61, oy + 61], radius=8, fill=(20, 24, 38, 255), outline=(215, 175, 60, 255), width=3)
    draw.rectangle([ox + 5, oy + 5, ox + 58, oy + 58], outline=(120, 90, 30, 255), width=1)
    if char_class == "antonio":
        draw_antonio(draw, ox, oy - 4, frame=0)
    elif char_class == "imelda":
        draw_imelda(draw, ox, oy - 4, frame=0)
    elif char_class == "pasqualina":
        draw_pasqualina(draw, ox, oy - 4, frame=0)
    elif char_class == "gennaro":
        draw_gennaro(draw, ox, oy - 4, frame=0)


def draw_bat(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Bat (48x48)
    wing_y = -8 if frame == 0 else 8
    # Fur body
    draw.ellipse([ox + 20, oy + 18, ox + 28, oy + 30], fill=(120, 45, 160, 255), outline=(60, 20, 80, 255))
    # Glowing red eyes & fangs
    draw.rectangle([ox + 22, oy + 20, ox + 23, oy + 22], fill=(255, 40, 40, 255))
    draw.rectangle([ox + 25, oy + 20, ox + 26, oy + 22], fill=(255, 40, 40, 255))
    draw.line([(ox + 23, oy + 24), (ox + 23, oy + 26)], fill=(255, 255, 255, 255))
    draw.line([(ox + 25, oy + 24), (ox + 25, oy + 26)], fill=(255, 255, 255, 255))
    # Bat Wings
    left_wing = [(ox + 20, oy + 22), (ox + 4, oy + 14 + wing_y), (ox + 10, oy + 28), (ox + 18, oy + 28)]
    right_wing = [(ox + 28, oy + 22), (ox + 44, oy + 14 + wing_y), (ox + 38, oy + 28), (ox + 30, oy + 28)]
    draw.polygon(left_wing, fill=(85, 30, 120, 255), outline=(160, 70, 210, 255))
    draw.polygon(right_wing, fill=(85, 30, 120, 255), outline=(160, 70, 210, 255))


def draw_skeleton(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Skeleton (48x48)
    walk_y = -2 if frame == 1 else 0
    # Ribs & Spine
    draw.rectangle([ox + 22, oy + 22 + walk_y, ox + 26, oy + 34 + walk_y], fill=(225, 225, 235, 255))
    draw.line([(ox + 18, oy + 24 + walk_y), (ox + 30, oy + 24 + walk_y)], fill=(225, 225, 235, 255), width=2)
    draw.line([(ox + 18, oy + 28 + walk_y), (ox + 30, oy + 28 + walk_y)], fill=(225, 225, 235, 255), width=2)
    draw.line([(ox + 20, oy + 32 + walk_y), (ox + 28, oy + 32 + walk_y)], fill=(225, 225, 235, 255), width=2)
    # Skull
    draw.ellipse([ox + 18, oy + 10 + walk_y, ox + 30, oy + 22 + walk_y], fill=(240, 240, 250, 255), outline=(140, 140, 160, 255))
    draw.rectangle([ox + 20, oy + 14 + walk_y, ox + 22, oy + 17 + walk_y], fill=(20, 20, 30, 255))
    draw.rectangle([ox + 26, oy + 14 + walk_y, ox + 28, oy + 17 + walk_y], fill=(20, 20, 30, 255))
    draw.line([(ox + 21, oy + 20 + walk_y), (ox + 27, oy + 20 + walk_y)], fill=(50, 50, 60, 255))
    # Rusty Sword
    draw.line([(ox + 32, oy + 20 + walk_y), (ox + 42, oy + 36 + walk_y)], fill=(160, 170, 185, 255), width=3)
    draw.line([(ox + 30, oy + 24 + walk_y), (ox + 36, oy + 21 + walk_y)], fill=(180, 120, 40, 255), width=2)


def draw_zombie(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Zombie (48x48)
    walk_y = -2 if frame == 1 else 0
    # Decaying green flesh & tattered garments
    draw.rectangle([ox + 18, oy + 24 + walk_y, ox + 30, oy + 38 + walk_y], fill=(65, 125, 75, 255), outline=(30, 70, 40, 255))
    draw.rectangle([ox + 18, oy + 28 + walk_y, ox + 30, oy + 36 + walk_y], fill=(110, 40, 40, 255)) # torn shirt
    # Rotting Head
    draw.rectangle([ox + 19, oy + 12 + walk_y, ox + 29, oy + 24 + walk_y], fill=(85, 145, 95, 255), outline=(40, 80, 50, 255))
    draw.rectangle([ox + 21, oy + 15 + walk_y, ox + 23, oy + 17 + walk_y], fill=(255, 255, 180, 255))
    draw.rectangle([ox + 26, oy + 16 + walk_y, ox + 28, oy + 18 + walk_y], fill=(180, 30, 30, 255)) # bleeding eye
    # Outstretched reaching arms
    arm_off = 3 if frame == 1 else 0
    draw.rectangle([ox + 28, oy + 22 + walk_y, ox + 42, oy + 26 + walk_y + arm_off], fill=(75, 135, 85, 255), outline=(30, 70, 40, 255))


def draw_ghost(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Ghost (48x48) - ethereal translucent Cyan phantom
    float_y = -3 if frame == 1 else 1
    ghost_pts = [
        (ox + 16, oy + 18 + float_y),
        (ox + 24, oy + 8 + float_y),
        (ox + 32, oy + 18 + float_y),
        (ox + 34, oy + 34 + float_y),
        (ox + 30, oy + 42 + float_y),
        (ox + 24, oy + 36 + float_y),
        (ox + 18, oy + 42 + float_y),
        (ox + 14, oy + 34 + float_y),
    ]
    draw.polygon(ghost_pts, fill=(180, 235, 255, 210), outline=(100, 200, 255, 255))
    # Glowing hollow eyes & mouth
    draw.ellipse([ox + 19, oy + 16 + float_y, ox + 23, oy + 21 + float_y], fill=(20, 40, 80, 255))
    draw.ellipse([ox + 25, oy + 16 + float_y, ox + 29, oy + 21 + float_y], fill=(20, 40, 80, 255))
    draw.ellipse([ox + 22, oy + 24 + float_y, ox + 26, oy + 29 + float_y], fill=(20, 40, 80, 255))


def draw_mudman(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Mudman Golem (64x64)
    walk_y = -3 if frame == 1 else 0
    # Heavy Mud Body
    draw.rounded_rectangle([ox + 14, oy + 20 + walk_y, ox + 50, oy + 54 + walk_y], radius=10, fill=(110, 75, 45, 255), outline=(65, 40, 20, 255), width=2)
    # Mud Stone Crags
    draw.rectangle([ox + 20, oy + 26 + walk_y, ox + 28, oy + 34 + walk_y], fill=(70, 50, 30, 255))
    draw.rectangle([ox + 36, oy + 38 + walk_y, ox + 46, oy + 46 + walk_y], fill=(70, 50, 30, 255))
    # Rocky Head with Amber eyes
    draw.rounded_rectangle([ox + 22, oy + 10 + walk_y, ox + 42, oy + 26 + walk_y], radius=6, fill=(130, 90, 55, 255), outline=(65, 40, 20, 255))
    draw.rectangle([ox + 26, oy + 16 + walk_y, ox + 29, oy + 19 + walk_y], fill=(255, 210, 40, 255))
    draw.rectangle([ox + 35, oy + 16 + walk_y, ox + 38, oy + 19 + walk_y], fill=(255, 210, 40, 255))


def draw_werewolf(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Werewolf (64x64)
    walk_y = -3 if frame == 1 else 0
    # Fur beast body & legs
    draw.rectangle([ox + 20, oy + 24 + walk_y, ox + 44, oy + 50 + walk_y], fill=(130, 50, 40, 255), outline=(70, 20, 15, 255))
    draw.rectangle([ox + 18, oy + 44, ox + 26, oy + 58 - (4 if frame == 1 else 0)], fill=(90, 30, 20, 255))
    draw.rectangle([ox + 38, oy + 44, ox + 46, oy + 58 + (4 if frame == 1 else 0)], fill=(90, 30, 20, 255))
    # Wolf Snout & Head
    draw.polygon([(ox + 18, oy + 12 + walk_y), (ox + 46, oy + 12 + walk_y), (ox + 52, oy + 22 + walk_y), (ox + 20, oy + 26 + walk_y)], fill=(150, 60, 45, 255), outline=(70, 20, 15, 255))
    # Beast Ears
    draw.polygon([(ox + 22, oy + 12 + walk_y), (ox + 26, oy + 4 + walk_y), (ox + 30, oy + 12 + walk_y)], fill=(100, 35, 25, 255))
    draw.polygon([(ox + 36, oy + 12 + walk_y), (ox + 40, oy + 4 + walk_y), (ox + 44, oy + 12 + walk_y)], fill=(100, 35, 25, 255))
    # Glowing yellow eyes & razor fangs
    draw.rectangle([ox + 36, oy + 16 + walk_y, ox + 39, oy + 19 + walk_y], fill=(255, 230, 50, 255))
    draw.line([(ox + 44, oy + 22 + walk_y), (ox + 44, oy + 26 + walk_y)], fill=(255, 255, 255, 255), width=2)
    # Claws
    draw.line([(ox + 46, oy + 32 + walk_y), (ox + 56, oy + 36 + walk_y)], fill=(240, 240, 245, 255), width=3)


def draw_red_skull(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Flaming Demonic Red Skull (64x64)
    float_y = -3 if frame == 1 else 2
    # Hellfire Flame halo
    for r in range(16, 2, -3):
        draw.ellipse([ox + 32 - r - 4, oy + 32 - r + float_y, ox + 32 + r + 4, oy + 32 + r + float_y], fill=(255, 60 + r * 8, 20, 50))
    # Crimson Skull
    draw.rounded_rectangle([ox + 16, oy + 14 + float_y, ox + 48, oy + 48 + float_y], radius=10, fill=(235, 40, 45, 255), outline=(130, 15, 20, 255), width=2)
    # Horns
    draw.polygon([(ox + 18, oy + 18 + float_y), (ox + 10, oy + 6 + float_y), (ox + 24, oy + 14 + float_y)], fill=(50, 15, 20, 255))
    draw.polygon([(ox + 46, oy + 18 + float_y), (ox + 54, oy + 6 + float_y), (ox + 40, oy + 14 + float_y)], fill=(50, 15, 20, 255))
    # Fiery Yellow Sockets
    draw.rectangle([ox + 22, oy + 24 + float_y, ox + 28, oy + 32 + float_y], fill=(255, 220, 50, 255))
    draw.rectangle([ox + 36, oy + 24 + float_y, ox + 42, oy + 32 + float_y], fill=(255, 220, 50, 255))
    # Jagged teeth
    for i in range(4):
        draw.rectangle([ox + 24 + i * 5, oy + 40 + float_y, ox + 26 + i * 5, oy + 46 + float_y], fill=(255, 240, 200, 255))


def draw_reaper_boss(draw: ImageDraw.ImageDraw, ox: int, oy: int, frame: int = 0) -> None:
    # Grim Reaper Boss (96x96)
    float_y = -4 if frame == 1 else 2
    # Dark Cowl / Shredded Robe
    robe_pts = [
        (ox + 32, oy + 20 + float_y),
        (ox + 64, oy + 20 + float_y),
        (ox + 78, oy + 84 + float_y),
        (ox + 56, oy + 76 + float_y),
        (ox + 44, oy + 86 + float_y),
        (ox + 18, oy + 80 + float_y),
    ]
    draw.polygon(robe_pts, fill=(15, 18, 28, 255), outline=(50, 60, 85, 255), width=2)
    # Deep Hood Void
    draw.ellipse([ox + 36, oy + 22 + float_y, ox + 60, oy + 46 + float_y], fill=(5, 5, 10, 255))
    # Piercing Red Pinprick Eyes
    draw.ellipse([ox + 42, oy + 32 + float_y, ox + 45, oy + 35 + float_y], fill=(255, 30, 30, 255))
    draw.ellipse([ox + 51, oy + 32 + float_y, ox + 54, oy + 35 + float_y], fill=(255, 30, 30, 255))

    # Giant Silver Death Scythe
    # Shaft
    draw.line([(ox + 64, oy + 12 + float_y), (ox + 82, oy + 88 + float_y)], fill=(120, 80, 40, 255), width=4)
    # Curved Crescent Blade
    blade_pts = [
        (ox + 64, oy + 12 + float_y),
        (ox + 40, oy - 2 + float_y),
        (ox + 24, oy + 14 + float_y),
        (ox + 34, oy + 18 + float_y),
        (ox + 54, oy + 14 + float_y),
    ]
    draw.polygon(blade_pts, fill=(215, 230, 250, 255), outline=(130, 160, 200, 255))
    draw.line([(ox + 24, oy + 14 + float_y), (ox + 64, oy + 12 + float_y)], fill=(255, 255, 255, 255), width=2)


def draw_weapons_and_projectiles(draw: ImageDraw.ImageDraw) -> None:
    # Y = 256..383
    # Whip Slash (96x48 at 0, 256)
    draw.arc([4, 260, 92, 298], start=200, end=380, fill=(255, 225, 90, 255), width=5)
    draw.arc([8, 262, 88, 296], start=210, end=370, fill=(255, 255, 255, 255), width=2)

    # Bloody Tear Slash (96x48 at 96, 256)
    draw.arc([100, 260, 188, 298], start=200, end=380, fill=(255, 40, 65, 255), width=6)
    draw.arc([104, 262, 184, 296], start=210, end=370, fill=(255, 190, 210, 255), width=3)
    for i in range(5):
        draw.ellipse([110 + i * 16, 280 + (i % 2) * 6, 114 + i * 16, 284 + (i % 2) * 6], fill=(255, 60, 80, 255))

    # Magic Wand Bolt (32x32 at 192, 256)
    draw.ellipse([196, 260, 220, 284], fill=(70, 220, 255, 255), outline=(255, 255, 255, 255), width=2)
    draw.ellipse([202, 266, 214, 278], fill=(255, 255, 255, 255))

    # Holy Wand Star Bolt (32x32 at 224, 256)
    draw.ellipse([228, 260, 252, 284], fill=(255, 220, 70, 255), outline=(255, 255, 255, 255), width=2)
    draw.polygon([(240, 258), (243, 268), (254, 272), (243, 276), (240, 286), (237, 276), (226, 272), (237, 268)], fill=(255, 255, 255, 255))

    # Knife (32x32 at 256, 256)
    knife_pts = [(260, 272), (280, 264), (284, 272), (280, 280)]
    draw.polygon(knife_pts, fill=(225, 235, 245, 255), outline=(130, 150, 180, 255))
    draw.rectangle([258, 270, 264, 274], fill=(120, 75, 35, 255))

    # Thousand Edge (32x32 at 288, 256)
    draw.polygon([(292, 272), (314, 262), (318, 272), (314, 282)], fill=(120, 240, 255, 255), outline=(255, 255, 255, 255))

    # Axe (48x48 at 320, 256)
    draw.line([(326, 298), (362, 262)], fill=(130, 80, 35, 255), width=4)
    # Double crescent blade
    draw.polygon([(342, 264), (356, 258), (364, 272), (352, 278)], fill=(195, 205, 220, 255), outline=(90, 110, 140, 255))
    draw.polygon([(348, 270), (362, 276), (356, 290), (342, 284)], fill=(195, 205, 220, 255), outline=(90, 110, 140, 255))

    # Death Spiral Scythe (48x48 at 368, 256)
    draw.line([(374, 298), (410, 262)], fill=(70, 30, 90, 255), width=4)
    draw.polygon([(386, 260), (412, 258), (414, 284), (398, 276)], fill=(235, 60, 70, 255), outline=(255, 200, 220, 255))

    # Holy Bible (36x44 at 416, 256)
    draw.rounded_rectangle([418, 258, 448, 296], radius=4, fill=(140, 40, 30, 255), outline=(255, 215, 60, 255), width=2)
    draw.line([(433, 264), (433, 290)], fill=(255, 215, 60, 255), width=3)
    draw.line([(425, 272), (441, 272)], fill=(255, 215, 60, 255), width=3)

    # Unholy Vespers (36x44 at 452, 256)
    draw.rounded_rectangle([454, 258, 484, 296], radius=4, fill=(25, 20, 35, 255), outline=(235, 45, 60, 255), width=2)
    draw.ellipse([464, 272, 474, 282], fill=(235, 45, 60, 255))

    # Garlic Aura Glyph (64x64 at 488, 256)
    draw.ellipse([492, 260, 548, 316], fill=(140, 255, 170, 50), outline=(140, 255, 170, 220), width=3)
    draw.ellipse([502, 270, 538, 306], outline=(200, 255, 220, 180), width=2)

    # Soul Eater Aura Glyph (64x64 at 552, 256)
    draw.ellipse([556, 260, 612, 316], fill=(180, 40, 220, 60), outline=(220, 80, 255, 240), width=3)
    draw.ellipse([566, 270, 602, 306], outline=(255, 140, 255, 200), width=2)

    # Lightning Strike (48x80 at 616, 256)
    lightning_pts = [(640, 258), (628, 286), (644, 290), (630, 330), (648, 294), (634, 290), (646, 258)]
    draw.polygon(lightning_pts, fill=(210, 160, 255, 255), outline=(255, 255, 255, 255))

    # Fire Wand Fireball (40x40 at 664, 256)
    draw.ellipse([668, 260, 700, 292], fill=(255, 100, 25, 255), outline=(255, 220, 50, 255), width=2)
    draw.ellipse([674, 266, 694, 286], fill=(255, 235, 90, 255))

    # Cataclysm Nuke Bomb (64x64 at 704, 256)
    draw.ellipse([712, 264, 760, 312], fill=(235, 60, 30, 255), outline=(255, 220, 60, 255), width=3)
    draw.ellipse([722, 274, 750, 302], fill=(255, 200, 50, 255))

    # Prismatic Laser Core (64x64 at 768, 256)
    draw.line([(772, 288), (828, 288)], fill=(80, 230, 255, 255), width=8)
    draw.line([(772, 288), (828, 288)], fill=(255, 255, 255, 255), width=4)

    # Enemy Projectile Fireball (32x32 at 832, 256)
    draw.ellipse([836, 260, 860, 284], fill=(255, 50, 40, 255), outline=(255, 200, 60, 255), width=2)

    # Enemy Shadow Bolt (32x32 at 864, 256)
    draw.ellipse([868, 260, 892, 284], fill=(130, 40, 180, 255), outline=(220, 140, 255, 255), width=2)


def draw_pickups_and_props(draw: ImageDraw.ImageDraw) -> None:
    # Row 3 (Y = 384..511)
    # Blue Exp Gem (32x32 at 0, 384)
    gem_pts = [(16, 388), (28, 398), (16, 412), (4, 398)]
    draw.polygon(gem_pts, fill=(60, 180, 255, 255), outline=(200, 240, 255, 255), width=2)
    draw.line([(16, 388), (16, 412)], fill=(255, 255, 255, 255))

    # Green Exp Gem (32x32 at 32, 384)
    gem_pts = [(48, 388), (60, 398), (48, 412), (36, 398)]
    draw.polygon(gem_pts, fill=(50, 230, 110, 255), outline=(190, 255, 210, 255), width=2)
    draw.line([(48, 388), (48, 412)], fill=(255, 255, 255, 255))

    # Red Exp Gem (32x32 at 64, 384)
    gem_pts = [(80, 388), (92, 398), (80, 412), (68, 398)]
    draw.polygon(gem_pts, fill=(245, 45, 60, 255), outline=(255, 180, 190, 255), width=2)
    draw.line([(80, 388), (80, 412)], fill=(255, 255, 255, 255))

    # Boss Chest Closed (48x40 at 96, 384)
    draw.rounded_rectangle([98, 388, 142, 420], radius=4, fill=(150, 90, 35, 255), outline=(255, 215, 60, 255), width=2)
    draw.line([(98, 400), (142, 400)], fill=(255, 215, 60, 255), width=2)
    draw.rectangle([116, 398, 124, 408], fill=(255, 215, 60, 255), outline=(80, 50, 15, 255))

    # Boss Chest Open (48x40 at 144, 384)
    draw.rounded_rectangle([146, 394, 190, 422], radius=4, fill=(150, 90, 35, 255), outline=(255, 215, 60, 255), width=2)
    draw.polygon([(146, 394), (160, 384), (190, 384), (190, 394)], fill=(120, 70, 25, 255), outline=(255, 215, 60, 255))
    # Golden glow inside
    draw.ellipse([156, 390, 180, 404], fill=(255, 235, 90, 240))

    # Vacuum Magnet Orb (36x36 at 192, 384)
    draw.ellipse([194, 386, 226, 418], fill=(50, 160, 255, 255), outline=(180, 235, 255, 255), width=2)
    draw.ellipse([202, 394, 218, 410], fill=(255, 255, 255, 255))

    # Rosary Crucifix (36x36 at 228, 384)
    draw.rectangle([242, 386, 250, 418], fill=(255, 215, 60, 255), outline=(140, 100, 20, 255))
    draw.rectangle([232, 394, 260, 402], fill=(255, 215, 60, 255), outline=(140, 100, 20, 255))

    # Freeze Watch (36x36 at 264, 384)
    draw.ellipse([266, 386, 298, 418], fill=(220, 240, 255, 255), outline=(50, 120, 190, 255), width=2)
    draw.line([(282, 402), (282, 392)], fill=(30, 70, 130, 255), width=2)
    draw.line([(282, 402), (290, 402)], fill=(30, 70, 130, 255), width=2)

    # Floor Chicken (36x36 at 300, 384)
    draw.ellipse([304, 392, 328, 412], fill=(195, 110, 45, 255), outline=(120, 60, 20, 255), width=2)
    draw.rectangle([324, 398, 334, 404], fill=(245, 240, 230, 255))

    # Coin Bag (36x36 at 336, 384)
    draw.rounded_rectangle([340, 390, 368, 418], radius=6, fill=(215, 165, 45, 255), outline=(120, 85, 20, 255), width=2)
    draw.rectangle([346, 386, 362, 392], fill=(180, 40, 30, 255))

    # Candelabra Lit Frame 1 (36x48 at 372, 384)
    draw.line([(390, 394), (390, 428)], fill=(215, 175, 55, 255), width=3)
    draw.line([(378, 402), (402, 402)], fill=(215, 175, 55, 255), width=3)
    draw.line([(378, 396), (378, 402)], fill=(215, 175, 55, 255), width=2)
    draw.line([(402, 396), (402, 402)], fill=(215, 175, 55, 255), width=2)
    # 3 Flames
    draw.ellipse([375, 388, 381, 396], fill=(255, 140, 30, 255))
    draw.ellipse([387, 386, 393, 394], fill=(255, 140, 30, 255))
    draw.ellipse([399, 388, 405, 396], fill=(255, 140, 30, 255))

    # Candelabra Lit Frame 2 (36x48 at 408, 384)
    draw.line([(426, 394), (426, 428)], fill=(215, 175, 55, 255), width=3)
    draw.line([(414, 402), (438, 402)], fill=(215, 175, 55, 255), width=3)
    draw.line([(414, 396), (414, 402)], fill=(215, 175, 55, 255), width=2)
    draw.line([(438, 396), (438, 402)], fill=(215, 175, 55, 255), width=2)
    draw.ellipse([411, 386, 417, 394], fill=(255, 190, 40, 255))
    draw.ellipse([423, 388, 429, 396], fill=(255, 190, 40, 255))
    draw.ellipse([435, 386, 441, 394], fill=(255, 190, 40, 255))

    # Clay Urn (32x36 at 444, 384)
    draw.rounded_rectangle([448, 390, 472, 418], radius=5, fill=(160, 105, 65, 255), outline=(95, 55, 30, 255), width=2)
    draw.rectangle([452, 386, 468, 390], fill=(130, 80, 45, 255))

    # Tombstone Cross (32x40 at 476, 384)
    draw.rounded_rectangle([480, 386, 504, 422], radius=4, fill=(65, 75, 95, 255), outline=(110, 125, 150, 255), width=2)
    draw.line([(492, 392), (492, 414)], fill=(35, 40, 55, 255), width=2)
    draw.line([(486, 398), (498, 398)], fill=(35, 40, 55, 255), width=2)

    # Cobblestone Tile 1 (64x64 at 512, 384)
    draw.rectangle([512, 384, 575, 447], fill=(24, 28, 40, 255), outline=(36, 42, 58, 255))
    draw.rectangle([516, 388, 540, 410], fill=(28, 34, 48, 255), outline=(42, 50, 70, 255))
    draw.rectangle([544, 388, 570, 414], fill=(22, 26, 38, 255), outline=(42, 50, 70, 255))
    draw.rectangle([520, 416, 550, 442], fill=(26, 30, 44, 255), outline=(42, 50, 70, 255))

    # Cobblestone Tile 2 Mossy (64x64 at 576, 384)
    draw.rectangle([576, 384, 639, 447], fill=(22, 28, 36, 255), outline=(36, 46, 52, 255))
    draw.rectangle([580, 388, 606, 412], fill=(26, 36, 42, 255), outline=(40, 58, 60, 255))
    draw.rectangle([610, 392, 634, 420], fill=(20, 30, 36, 255), outline=(40, 58, 60, 255))
    draw.rectangle([584, 418, 616, 442], fill=(24, 34, 40, 255), outline=(40, 58, 60, 255))
    # Moss speckles
    draw.rectangle([590, 404, 598, 408], fill=(35, 110, 65, 220))
    draw.rectangle([620, 424, 628, 428], fill=(35, 110, 65, 220))

    # Cobblestone Tile 3 Cracked (64x64 at 640, 384)
    draw.rectangle([640, 384, 703, 447], fill=(20, 24, 34, 255), outline=(32, 38, 52, 255))
    draw.line([(646, 390), (664, 414)], fill=(12, 14, 20, 255), width=2)
    draw.line([(664, 414), (658, 438)], fill=(12, 14, 20, 255), width=2)


def draw_ui_icons(draw: ImageDraw.ImageDraw) -> None:
    # Row 4: UI Icons (Y = 512..639, 32x32 icons at step 32)
    # Weapon Icons:
    icons = [
        ("Whip", (255, 215, 60)),
        ("Magic Wand", (80, 220, 255)),
        ("Knife", (220, 230, 245)),
        ("Axe", (180, 195, 215)),
        ("Holy Bible", (255, 215, 60)),
        ("Garlic", (160, 255, 180)),
        ("Lightning", (210, 160, 255)),
        ("Fire Wand", (255, 120, 40)),
        ("Cataclysm Nuke", (255, 70, 40)),
        ("Prismatic Laser", (80, 240, 255)),
        ("Bloody Tear", (255, 45, 65)),
        ("Holy Wand", (255, 235, 90)),
        ("Thousand Edge", (100, 240, 255)),
        ("Death Spiral", (240, 60, 80)),
        ("Unholy Vespers", (240, 50, 70)),
        ("Soul Eater", (220, 80, 255)),
    ]
    for i, (name, col) in enumerate(icons):
        ix = i * 32
        iy = 512
        draw.rounded_rectangle([ix + 2, iy + 2, ix + 30, iy + 30], radius=4, fill=(24, 28, 44, 255), outline=col, width=2)
        draw.rectangle([ix + 8, iy + 8, ix + 24, iy + 24], fill=(*col[:3], 180))

    # Passive Badges: Spinach, Armor, Empty Tome, Wings, Crown, Duplicator
    passives = [
        ("Spinach", (40, 210, 70)),
        ("Armor", (180, 190, 210)),
        ("Empty Tome", (210, 160, 90)),
        ("Wings", (140, 220, 255)),
        ("Crown", (255, 215, 60)),
        ("Duplicator", (230, 90, 240)),
    ]
    for j, (name, col) in enumerate(passives):
        jx = j * 32
        jy = 544
        draw.rounded_rectangle([jx + 2, jy + 2, jx + 30, jy + 30], radius=4, fill=(20, 24, 38, 255), outline=col, width=2)
        draw.ellipse([jx + 7, jy + 7, jx + 25, jy + 25], fill=col)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sprites_dir = root / "assets" / "sprites"
    sprites_dir.mkdir(parents=True, exist_ok=True)
    out_path = sprites_dir / "vampiresurvivors.png"

    sheet = Image.new("RGBA", (SHEET_W, SHEET_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # 1. Characters Walk Frames (0..448, 0..64)
    draw_antonio(draw, 0, 0, frame=0)
    draw_antonio(draw, 64, 0, frame=1)
    draw_imelda(draw, 128, 0, frame=0)
    draw_imelda(draw, 192, 0, frame=1)
    draw_pasqualina(draw, 256, 0, frame=0)
    draw_pasqualina(draw, 320, 0, frame=1)
    draw_gennaro(draw, 384, 0, frame=0)
    draw_gennaro(draw, 448, 0, frame=1)

    # Character Portraits (512..704, 0..64)
    draw_portrait_badge(draw, 512, 0, "antonio")
    draw_portrait_badge(draw, 576, 0, "imelda")
    draw_portrait_badge(draw, 640, 0, "pasqualina")
    draw_portrait_badge(draw, 704, 0, "gennaro")

    # 2. Enemies (Row 1: Y = 128..255)
    draw_bat(draw, 0, 128, frame=0)
    draw_bat(draw, 48, 128, frame=1)
    draw_skeleton(draw, 96, 128, frame=0)
    draw_skeleton(draw, 144, 128, frame=1)
    draw_zombie(draw, 192, 128, frame=0)
    draw_zombie(draw, 240, 128, frame=1)
    draw_ghost(draw, 288, 128, frame=0)
    draw_ghost(draw, 336, 128, frame=1)
    draw_mudman(draw, 384, 128, frame=0)
    draw_mudman(draw, 448, 128, frame=1)
    draw_werewolf(draw, 512, 128, frame=0)
    draw_werewolf(draw, 576, 128, frame=1)
    draw_red_skull(draw, 640, 128, frame=0)
    draw_red_skull(draw, 704, 128, frame=1)
    draw_reaper_boss(draw, 768, 128, frame=0)
    draw_reaper_boss(draw, 864, 128, frame=1)

    # 3. Weapons and Projectiles (Row 2: Y = 256..383)
    draw_weapons_and_projectiles(draw)

    # 4. Pickups & Props (Row 3: Y = 384..511)
    draw_pickups_and_props(draw)

    # 5. UI Icons (Row 4: Y = 512..639)
    draw_ui_icons(draw)

    sheet.save(out_path, format="PNG")
    print(f"Generated Vampire Survivors sprite sheet successfully at {out_path} ({SHEET_W}x{SHEET_H})")


if __name__ == "__main__":
    main()
