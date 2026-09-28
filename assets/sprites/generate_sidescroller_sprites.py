#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Cyberpunk Sidescroller:
Layout:
Row 0 (Y=0..63):    Hero Commando (Stand, Run 1, Run 2, Run 3, Jump, Dash)
Row 1 (Y=64..127):  Enemies (Scout Drone, Walker Mech, Turret, Kamikaze, Sniper)
Row 2 (Y=128..191): Boss Behemoth Core & Drone Orbs
Row 3 (Y=192..255): Power-ups (Weapon, Shield, Overdrive, Drone, Repair, EMP, Multiplier)
Row 4 (Y=256..319): Projectiles (Pulse, Spread, Plasma, Missile, Beam)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_hero(draw: ImageDraw.ImageDraw, ox: int, oy: int, pose: str) -> None:
    cx, cy = ox + 24, oy + 32
    # Cybernetic Armor Body (Dark Slate & Neon Cyan)
    # Legs
    if pose in ("run1", "jump"):
        draw.line([(cx - 6, cy + 8), (cx - 10, cy + 24)], fill=(15, 23, 42, 255), width=4)
        draw.line([(cx + 4, cy + 8), (cx + 8, cy + 22)], fill=(15, 23, 42, 255), width=4)
    elif pose == "run2":
        draw.line([(cx - 6, cy + 8), (cx - 4, cy + 24)], fill=(15, 23, 42, 255), width=4)
        draw.line([(cx + 4, cy + 8), (cx + 12, cy + 20)], fill=(15, 23, 42, 255), width=4)
    else:
        draw.line([(cx - 6, cy + 8), (cx - 6, cy + 24)], fill=(15, 23, 42, 255), width=4)
        draw.line([(cx + 6, cy + 8), (cx + 6, cy + 24)], fill=(15, 23, 42, 255), width=4)

    # Torso & Chest Plate
    draw.rectangle((cx - 10, cy - 8, cx + 10, cy + 10), fill=(30, 41, 59, 255), outline=(14, 165, 233, 255), width=2)
    # Glowing Cyan Core
    draw.rectangle((cx - 4, cy - 2, cx + 4, cy + 4), fill=(6, 182, 212, 255))

    # Helmet & Visor
    draw.rectangle((cx - 8, cy - 24, cx + 8, cy - 10), fill=(15, 23, 42, 255), outline=(100, 116, 139, 255), width=2)
    draw.rectangle((cx + 2, cy - 18, cx + 8, cy - 13), fill=(239, 68, 68, 255))

    # Heavy Gun Arm
    draw.rectangle((cx + 2, cy - 4, cx + 22, cy + 2), fill=(100, 116, 139, 255), outline=(15, 23, 42, 255), width=1)
    draw.rectangle((cx + 18, cy - 6, cx + 24, cy + 4), fill=(234, 179, 8, 255))

    if pose == "dash":
        # Plasma Thruster Trail
        draw.polygon([(cx - 10, cy), (cx - 24, cy - 6), (cx - 20, cy), (cx - 24, cy + 6)], fill=(6, 182, 212, 255))


def draw_scout_drone(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 24, oy + 24
    # Circular Drone Hull
    draw.ellipse((cx - 16, cy - 12, cx + 16, cy + 12), fill=(30, 41, 59, 255), outline=(239, 68, 68, 255), width=2)
    # Glowing Red Eye Visor
    draw.ellipse((cx - 6, cy - 4, cx + 6, cy + 4), fill=(239, 68, 68, 255))
    # Propeller Rotors
    draw.line([(cx - 20, cy - 14), (cx - 4, cy - 14)], fill=(148, 163, 184, 255), width=2)
    draw.line([(cx + 4, cy - 14), (cx + 20, cy - 14)], fill=(148, 163, 184, 255), width=2)
    # Underside Laser Barrel
    draw.rectangle((cx - 3, cy + 12, cx + 3, cy + 18), fill=(100, 116, 139, 255))


def draw_walker_mech(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 28, oy + 28
    # Heavy Mech Legs
    draw.line([(cx - 12, cy + 6), (cx - 18, cy + 24)], fill=(51, 65, 85, 255), width=5)
    draw.line([(cx + 12, cy + 6), (cx + 18, cy + 24)], fill=(51, 65, 85, 255), width=5)
    # Main Armored Cockpit
    draw.polygon([(cx - 18, cy - 16), (cx + 18, cy - 16), (cx + 12, cy + 8), (cx - 12, cy + 8)], fill=(185, 28, 28, 255), outline=(79, 70, 229, 255), width=2)
    # Twin Gatling Cannons
    draw.rectangle((cx - 22, cy - 6, cx - 14, cy + 4), fill=(15, 23, 42, 255))
    draw.rectangle((cx + 14, cy - 6, cx + 22, cy + 4), fill=(15, 23, 42, 255))


def draw_turret(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 24, oy + 24
    # Base Mount
    draw.polygon([(cx - 18, cy + 18), (cx + 18, cy + 18), (cx + 10, cy + 6), (cx - 10, cy + 6)], fill=(51, 65, 85, 255))
    # Swivel Cannon
    draw.ellipse((cx - 10, cy - 8, cx + 10, cy + 8), fill=(234, 179, 8, 255), outline=(180, 83, 9, 255), width=2)
    draw.rectangle((cx - 4, cy - 18, cx + 4, cy - 6), fill=(100, 116, 139, 255))


def draw_kamikaze(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 24, oy + 24
    # Delta-wing Suicide Drone
    draw.polygon([(cx + 16, cy), (cx - 14, cy - 12), (cx - 8, cy), (cx - 14, cy + 12)], fill=(220, 38, 38, 255), outline=(254, 240, 138, 255), width=2)
    # Glowing Bomb Core
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(250, 204, 21, 255))


def draw_boss_behemoth(draw: ImageDraw.ImageDraw, ox: int, oy: int) -> None:
    cx, cy = ox + 48, oy + 48
    # Massive Cyber Behemoth Core
    draw.polygon([(cx - 40, cy - 30), (cx + 40, cy - 30), (cx + 30, cy + 35), (cx - 30, cy + 35)], fill=(30, 41, 59, 255), outline=(239, 68, 68, 255), width=3)
    # Main Plasma Core Eye
    draw.ellipse((cx - 18, cy - 12, cx + 18, cy + 18), fill=(239, 68, 68, 255), outline=(254, 240, 138, 255), width=2)
    # Heavy Laser Mounts
    draw.rectangle((cx - 42, cy - 10, cx - 32, cy + 20), fill=(100, 116, 139, 255))
    draw.rectangle((cx + 32, cy - 10, cx + 42, cy + 20), fill=(100, 116, 139, 255))


def draw_powerup(draw: ImageDraw.ImageDraw, cx: int, cy: int, kind: str) -> None:
    r = 14
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(15, 23, 42, 255), outline=(250, 204, 21, 255), width=2)
    if kind == "weapon":
        draw.rectangle((cx - 6, cy - 3, cx + 6, cy + 3), fill=(239, 68, 68, 255))
    elif kind == "shield":
        draw.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), outline=(6, 182, 212, 255), width=2)
    elif kind == "overdrive":
        draw.polygon([(cx, cy - 8), (cx + 7, cy + 6), (cx - 7, cy + 6)], fill=(250, 204, 21, 255))
    elif kind == "drone":
        draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(168, 85, 247, 255))
    elif kind == "repair":
        draw.rectangle((cx - 6, cy - 2, cx + 6, cy + 2), fill=(34, 197, 94, 255))
        draw.rectangle((cx - 2, cy - 6, cx + 2, cy + 6), fill=(34, 197, 94, 255))
    elif kind == "emp":
        draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(59, 130, 246, 255))
    elif kind == "multiplier":
        draw.line([(cx - 5, cy - 5), (cx + 5, cy + 5)], fill=(236, 72, 153, 255), width=2)
        draw.line([(cx - 5, cy + 5), (cx + 5, cy - 5)], fill=(236, 72, 153, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Hero Commando Poses (Y=0..63)
    poses = ["stand", "run1", "run2", "run1", "jump", "dash"]
    for i, p in enumerate(poses):
        draw_hero(draw, i * 48, 0, pose=p)

    # Row 1: Enemies (Y=64..127)
    draw_scout_drone(draw, 0 * 48, 64)
    draw_walker_mech(draw, 1 * 56, 64)
    draw_turret(draw, 3 * 48, 64)
    draw_kamikaze(draw, 4 * 48, 64)

    # Row 2: Boss Behemoth Core (Y=128..224)
    draw_boss_behemoth(draw, 0, 128)

    # Row 3: Power-ups (Y=240..280)
    pu_types = ["weapon", "shield", "overdrive", "drone", "repair", "emp", "multiplier"]
    for i, k in enumerate(pu_types):
        draw_powerup(draw, i * 40 + 20, 240 + 20, kind=k)

    out_path = root / "assets" / "sprites" / "sidescroller.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "sidescroller" / "assets" / "sprites" / "sidescroller.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
