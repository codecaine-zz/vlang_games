#!/usr/bin/env python3
"""Generate ultra-detailed 512x512 RGBA sprite sheet for Asteroids:
Grid layout:
Row 0 (Y=0..63):    Player Spaceship (Hull, Thrusting, Shielded)
Row 1 (Y=64..127):  Asteroid Large (64x64)
Row 2 (Y=128..191): Asteroid Med (48x48), Asteroid Small (32x32), UFO Large (48x32), UFO Small (32x20)
Row 3 (Y=192..255): Power-ups (Shield, Spread, Rapid, EMP, Plasma, Life)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_ship(draw: ImageDraw.ImageDraw, ox: int, oy: int, thrust: bool, shield: bool) -> None:
    cx, cy = ox + 32, oy + 32
    # Sleek High-Tech Starfighter Hull
    hull_pts = [(cx, cy - 24), (cx + 18, cy + 20), (cx + 10, cy + 14), (cx, cy + 18), (cx - 10, cy + 14), (cx - 18, cy + 20)]
    draw.polygon(hull_pts, fill=(203, 213, 225, 255), outline=(100, 116, 139, 255), width=2)

    # Cyan Cockpit Visor
    draw.polygon([(cx, cy - 12), (cx + 4, cy + 2), (cx - 4, cy + 2)], fill=(6, 182, 212, 255), outline=(165, 243, 252, 255), width=1)

    # Wingtip plasma cannons
    draw.rectangle((cx - 18, cy + 10, cx - 15, cy + 18), fill=(239, 68, 68, 255))
    draw.rectangle((cx + 15, cy + 10, cx + 18, cy + 18), fill=(239, 68, 68, 255))

    if thrust:
        # Fiery Plasma Jet Flame
        flame_pts = [(cx - 6, cy + 18), (cx + 6, cy + 18), (cx, cy + 32)]
        draw.polygon(flame_pts, fill=(249, 115, 22, 255))
        draw.polygon([(cx - 3, cy + 18), (cx + 3, cy + 18), (cx, cy + 26)], fill=(254, 240, 138, 255))

    if shield:
        # Energy Forcefield Bubble
        draw.ellipse((cx - 28, cy - 28, cx + 28, cy + 28), outline=(6, 182, 212, 255), width=3)


def draw_asteroid(draw: ImageDraw.ImageDraw, cx: int, cy: int, r: int) -> None:
    # Jagged Polygon Rock
    num_pts = 12
    pts = []
    offsets = [1.0, 0.82, 0.95, 1.05, 0.88, 1.0, 0.78, 1.08, 0.92, 0.85, 1.02, 0.9]
    for i in range(num_pts):
        angle = (i / num_pts) * 2.0 * math.pi
        dist = r * offsets[i % len(offsets)]
        pts.append((cx + dist * math.cos(angle), cy + dist * math.sin(angle)))

    draw.polygon(pts, fill=(100, 116, 139, 255), outline=(51, 65, 85, 255), width=3)

    # Shading Highlights
    draw.ellipse((cx - r // 2, cy - r // 2, cx - r // 4, cy - r // 4), fill=(148, 163, 184, 255))
    # Crater indentations
    draw.ellipse((cx + r // 4, cy - r // 6, cx + r // 2, cy + r // 8), fill=(51, 65, 85, 255), outline=(30, 41, 59, 255))
    draw.ellipse((cx - r // 5, cy + r // 4, cx + r // 8, cy + r // 2), fill=(51, 65, 85, 255), outline=(30, 41, 59, 255))


def draw_ufo(draw: ImageDraw.ImageDraw, cx: int, cy: int, w: int, h: int, is_scout: bool) -> None:
    # Flying Saucer Base
    body_col = (239, 68, 68, 255) if not is_scout else (234, 179, 8, 255)
    rim_col = (185, 28, 28, 255) if not is_scout else (180, 83, 9, 255)
    dome_col = (6, 182, 212, 255)

    # Glass Dome
    draw.ellipse((cx - w // 3, cy - h, cx + w // 3, cy), fill=dome_col, outline=(165, 243, 252, 255), width=2)
    # Saucer Disk
    draw.ellipse((cx - w // 2, cy - h // 3, cx + w // 2, cy + h // 2), fill=body_col, outline=rim_col, width=2)
    # Under-chassis lights
    for i in range(-2, 3):
        lx = cx + i * (w // 6)
        ly = cy + h // 6
        draw.ellipse((lx - 2, ly - 2, lx + 2, ly + 2), fill=(255, 255, 255, 255))


def draw_powerup(draw: ImageDraw.ImageDraw, cx: int, cy: int, kind: str) -> None:
    r = 14
    # Glowing orb container
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(15, 23, 42, 255), outline=(254, 240, 138, 255), width=2)
    if kind == "shield":
        draw.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), outline=(6, 182, 212, 255), width=3)
    elif kind == "spread":
        draw.line([(cx, cy - 8), (cx, cy + 8)], fill=(239, 68, 68, 255), width=2)
        draw.line([(cx - 6, cy - 6), (cx + 6, cy + 6)], fill=(239, 68, 68, 255), width=2)
    elif kind == "rapid":
        draw.line([(cx - 4, cy - 8), (cx - 4, cy + 8)], fill=(234, 179, 8, 255), width=2)
        draw.line([(cx + 4, cy - 8), (cx + 4, cy + 8)], fill=(234, 179, 8, 255), width=2)
    elif kind == "emp":
        draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(168, 85, 247, 255))
    elif kind == "plasma":
        draw.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=(34, 197, 94, 255))
    elif kind == "life":
        draw.polygon([(cx, cy - 6), (cx + 6, cy + 6), (cx - 6, cy + 6)], fill=(236, 72, 153, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Row 0: Ships
    draw_ship(draw, 0 * 64, 0 * 64, thrust=False, shield=False)
    draw_ship(draw, 1 * 64, 0 * 64, thrust=True, shield=False)
    draw_ship(draw, 2 * 64, 0 * 64, thrust=True, shield=True)

    # Row 1: Large Asteroids (64x64)
    draw_asteroid(draw, 32, 64 + 32, r=28)
    draw_asteroid(draw, 64 + 32, 64 + 32, r=28)

    # Row 2: Medium Asteroids (48x48), Small Asteroids (32x32), UFOs
    draw_asteroid(draw, 24, 128 + 24, r=18)
    draw_asteroid(draw, 64 + 16, 128 + 16, r=12)
    draw_ufo(draw, 128 + 32, 128 + 32, w=48, h=24, is_scout=False)
    draw_ufo(draw, 192 + 24, 128 + 24, w=32, h=16, is_scout=True)

    # Row 3: Power-ups
    kinds = ["shield", "spread", "rapid", "emp", "plasma", "life"]
    for i, k in enumerate(kinds):
        draw_powerup(draw, i * 40 + 20, 192 + 20, kind=k)

    out_path = root / "assets" / "sprites" / "asteroids.png"
    sheet.save(out_path, format="PNG")
    print(f"Generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    local_path = root / "asteroids" / "assets" / "sprites" / "asteroids.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
