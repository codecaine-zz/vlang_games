#!/usr/bin/env python3
"""Generate high-fidelity 512x512 RGBA sprite sheet for Dr. Mario:
- 3D Glossy Pill Capsules (Red, Yellow, Blue in Left, Right, Top, Bottom, Single)
- Animated Cell Viruses (Red Fever, Yellow Chill, Blue Weird)
- Large Petri Dish Dancing Mascot Viruses
- Dr. Mario Character Mascot (Lab Coat, Head Mirror, Stethoscope, Tossing)
- FX Sparkle Bursts
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

SHEET_SIZE = 512
SCALE = 2  # 2x supersampling


def draw_capsule_half(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    size: float,
    color_base: tuple[int, int, int],
    color_hi: tuple[int, int, int],
    color_sd: tuple[int, int, int],
    half_type: str,
) -> None:
    r = size * 0.42
    x1, y1 = cx - r, cy - r
    x2, y2 = cx + r, cy + r

    # Shadow / Outline
    draw.rounded_rectangle((x1 - 1, y1 - 1, x2 + 1, y2 + 1), radius=int(r * 0.6), fill=(10, 15, 25, 220))

    if half_type == "single":
        draw.rounded_rectangle((x1, y1, x2, y2), radius=int(r * 0.7), fill=color_base)
        # 3D Gloss Highlight strip
        draw.rounded_rectangle((x1 + r * 0.3, y1 + r * 0.2, x2 - r * 0.3, y1 + r * 0.55), radius=int(r * 0.25), fill=(*color_hi, 230))
        # Drop shadow bottom
        draw.rounded_rectangle((x1 + r * 0.3, y2 - r * 0.5, x2 - r * 0.3, y2 - r * 0.2), radius=int(r * 0.2), fill=(*color_sd, 210))
        # Center shine dot
        draw.ellipse((cx - r * 0.2, cy - r * 0.1, cx + r * 0.2, cy + r * 0.2), fill=(255, 255, 255, 240))
        return

    if half_type == "left":
        # Round left, flat right with seam
        draw.polygon([(cx - r * 0.3, y1), (x2, y1), (x2, y2), (cx - r * 0.3, y2)], fill=color_base)
        draw.pieslice((x1, y1, cx + r * 0.4, y2), 90, 270, fill=color_base)
        # Highlight top
        draw.line([(cx - r * 0.6, y1 + r * 0.3), (x2 - 1, y1 + r * 0.3)], fill=(*color_hi, 230), width=int(size * 0.12))
        # Shadow bottom
        draw.line([(cx - r * 0.6, y2 - r * 0.3), (x2 - 1, y2 - r * 0.3)], fill=(*color_sd, 210), width=int(size * 0.10))
        # Joint seam line on right
        draw.line([(x2 - 1, y1 + 1), (x2 - 1, y2 - 1)], fill=(20, 25, 35, 240), width=int(size * 0.08))

    elif half_type == "right":
        # Flat left with seam, round right
        draw.polygon([(x1, y1), (cx + r * 0.3, y1), (cx + r * 0.3, y2), (x1, y2)], fill=color_base)
        draw.pieslice((cx - r * 0.4, y1, x2, y2), 270, 90, fill=color_base)
        # Highlight top
        draw.line([(x1 + 1, y1 + r * 0.3), (cx + r * 0.6, y1 + r * 0.3)], fill=(*color_hi, 230), width=int(size * 0.12))
        # Shadow bottom
        draw.line([(x1 + 1, y2 - r * 0.3), (cx + r * 0.6, y2 - r * 0.3)], fill=(*color_sd, 210), width=int(size * 0.10))
        # Joint seam on left
        draw.line([(x1 + 1, y1 + 1), (x1 + 1, y2 - 1)], fill=(20, 25, 35, 240), width=int(size * 0.08))

    elif half_type == "top":
        # Round top, flat bottom
        draw.polygon([(x1, cy - r * 0.3), (x2, cy - r * 0.3), (x2, y2), (x1, y2)], fill=color_base)
        draw.pieslice((x1, y1, x2, cy + r * 0.4), 180, 360, fill=color_base)
        # Highlight
        draw.line([(x1 + r * 0.35, cy - r * 0.5), (x2 - r * 0.35, cy - r * 0.5)], fill=(*color_hi, 230), width=int(size * 0.12))
        # Seam on bottom
        draw.line([(x1 + 1, y2 - 1), (x2 - 1, y2 - 1)], fill=(20, 25, 35, 240), width=int(size * 0.08))

    elif half_type == "bottom":
        # Flat top, round bottom
        draw.polygon([(x1, y1), (x2, y1), (x2, cy + r * 0.3), (x1, cy + r * 0.3)], fill=color_base)
        draw.pieslice((x1, cy - r * 0.4, x2, y2), 0, 180, fill=color_base)
        # Shadow
        draw.line([(x1 + r * 0.35, cy + r * 0.5), (x2 - r * 0.35, cy + r * 0.5)], fill=(*color_sd, 210), width=int(size * 0.10))
        # Seam on top
        draw.line([(x1 + 1, y1 + 1), (x2 - 1, y1 + 1)], fill=(20, 25, 35, 240), width=int(size * 0.08))


def draw_virus_cell_sprite(
    draw: ImageDraw.ImageDraw, cx: float, cy: float, size: float, v_type: str, frame: int
) -> None:
    r = size * 0.38
    wiggle = (1 if frame == 1 else -1) * (size * 0.06)

    if v_type == "red":
        # Fever Red Virus (Angry spiky ball)
        col_body = (240, 45, 45)
        col_spike = (180, 20, 20)
        # Spikes
        for ang_deg in [0, 45, 90, 135, 180, 225, 270, 315]:
            ang = math.radians(ang_deg + (5 if frame == 1 else -5))
            sx = cx + (r * 1.25) * math.cos(ang)
            sy = cy + (r * 1.25) * math.sin(ang)
            draw.line([(cx, cy), (sx, sy)], fill=(*col_spike, 255), width=int(size * 0.14))

        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(*col_body, 255), outline=(120, 10, 10, 255), width=int(size * 0.06))

        # Angry slanted eyes
        eye_y = cy - r * 0.2
        draw.ellipse((cx - r * 0.65, eye_y - r * 0.3, cx - r * 0.15, eye_y + r * 0.3), fill=(255, 255, 255, 255))
        draw.ellipse((cx + r * 0.15, eye_y - r * 0.3, cx + r * 0.65, eye_y + r * 0.3), fill=(255, 255, 255, 255))
        pupil_off = (r * 0.1) if frame == 1 else (-r * 0.1)
        draw.ellipse((cx - r * 0.45 + pupil_off, eye_y - r * 0.15, cx - r * 0.25 + pupil_off, eye_y + r * 0.15), fill=(20, 5, 5, 255))
        draw.ellipse((cx + r * 0.25 + pupil_off, eye_y - r * 0.15, cx + r * 0.45 + pupil_off, eye_y + r * 0.15), fill=(20, 5, 5, 255))

        # Sharp toothy grimace
        draw.polygon([(cx - r * 0.4, cy + r * 0.3), (cx, cy + r * 0.5 + wiggle), (cx + r * 0.4, cy + r * 0.3), (cx, cy + r * 0.2)], fill=(20, 5, 5, 255))

    elif v_type == "yellow":
        # Chill Yellow Virus (Grinning horn virus)
        col_body = (250, 220, 30)
        draw.rounded_rectangle((cx - r * 1.05, cy - r * 0.85, cx + r * 1.05, cy + r * 0.85), radius=int(r * 0.5), fill=(*col_body, 255), outline=(160, 120, 10, 255), width=int(size * 0.06))

        # Mischievous little horns
        h_y = cy - r * 1.1 + wiggle
        draw.polygon([(cx - r * 0.7, cy - r * 0.6), (cx - r * 0.9, h_y), (cx - r * 0.4, cy - r * 0.7)], fill=(220, 180, 15, 255))
        draw.polygon([(cx + r * 0.4, cy - r * 0.7), (cx + r * 0.9, h_y), (cx + r * 0.7, cy - r * 0.6)], fill=(220, 180, 15, 255))

        # Grinning eyes
        draw.ellipse((cx - r * 0.65, cy - r * 0.35, cx - r * 0.15, cy + r * 0.15), fill=(255, 255, 255, 255))
        draw.ellipse((cx + r * 0.15, cy - r * 0.35, cx + r * 0.65, cy + r * 0.15), fill=(255, 255, 255, 255))
        draw.ellipse((cx - r * 0.45, cy - r * 0.2, cx - r * 0.25, cy + r * 0.05), fill=(20, 20, 5, 255))
        draw.ellipse((cx + r * 0.25, cy - r * 0.2, cx + r * 0.45, cy + r * 0.05), fill=(20, 20, 5, 255))

        # Wide smirk
        draw.arc((cx - r * 0.6, cy - r * 0.1, cx + r * 0.6, cy + r * 0.6), 0, 180, fill=(30, 20, 5, 255), width=int(size * 0.08))

    elif v_type == "blue":
        # Weird Blue Virus (Goofy wide-eyed round virus)
        col_body = (45, 145, 250)
        draw.ellipse((cx - r * 0.95, cy - r * 0.95, cx + r * 0.95, cy + r * 0.95), fill=(*col_body, 255), outline=(15, 60, 140, 255), width=int(size * 0.06))

        # Round wide eyes
        draw.ellipse((cx - r * 0.75, cy - r * 0.45, cx - r * 0.15, cy + r * 0.25), fill=(255, 255, 255, 255))
        draw.ellipse((cx + r * 0.15, cy - r * 0.45, cx + r * 0.75, cy + r * 0.25), fill=(255, 255, 255, 255))
        p_off = (r * 0.1) if frame == 1 else (-r * 0.1)
        draw.ellipse((cx - r * 0.5 + p_off, cy - r * 0.2, cx - r * 0.3 + p_off, cy + r * 0.1), fill=(5, 15, 30, 255))
        draw.ellipse((cx + r * 0.3 + p_off, cy - r * 0.2, cx + r * 0.5 + p_off, cy + r * 0.1), fill=(5, 15, 30, 255))

        # O-shaped open mouth
        draw.ellipse((cx - r * 0.25, cy + r * 0.25 + wiggle * 0.5, cx + r * 0.25, cy + r * 0.65 + wiggle * 0.5), fill=(10, 20, 45, 255))


def draw_dr_mario_mascot(draw: ImageDraw.ImageDraw, cx: float, cy: float, frame: int) -> None:
    # Dr. Mario in Lab Coat (64x96)
    # Head Mirror
    draw.ellipse((cx - 16, cy - 42, cx - 2, cy - 28), fill=(225, 240, 255, 255), outline=(140, 160, 180, 255), width=2)
    draw.line([(cx - 12, cy - 36), (cx + 14, cy - 36)], fill=(50, 50, 60, 255), width=2)

    # Face & Nose
    draw.ellipse((cx - 14, cy - 34, cx + 18, cy - 6), fill=(255, 200, 150, 255))
    draw.ellipse((cx + 8, cy - 24, cx + 22, cy - 12), fill=(255, 180, 130, 255))  # Mario big nose
    # Mustache
    draw.rounded_rectangle((cx + 2, cy - 14, cx + 24, cy - 6), radius=3, fill=(90, 45, 15, 255))
    # Hair
    draw.rounded_rectangle((cx - 18, cy - 40, cx - 4, cy - 16), radius=4, fill=(90, 45, 15, 255))
    # Eye
    draw.ellipse((cx + 6, cy - 26, cx + 12, cy - 18), fill=(20, 20, 30, 255))

    # Doctor Lab Coat Body
    draw.rounded_rectangle((cx - 16, cy - 6, cx + 22, cy + 38), radius=6, fill=(245, 245, 250, 255), outline=(180, 185, 195, 255), width=2)

    # Stethoscope
    draw.arc((cx - 8, cy - 4, cx + 14, cy + 18), 0, 180, fill=(50, 50, 60, 255), width=3)
    draw.ellipse((cx + 6, cy + 14, cx + 14, cy + 22), fill=(210, 225, 240, 255))

    # Tossing Arm
    if frame == 1:
        # Arm raised throwing
        draw.rounded_rectangle((cx - 28, cy - 20, cx - 12, cy + 8), radius=4, fill=(245, 245, 250, 255))
        draw.ellipse((cx - 30, cy - 26, cx - 18, cy - 14), fill=(255, 200, 150, 255))
    else:
        # Arm holding ready
        draw.rounded_rectangle((cx - 26, cy + 2, cx - 10, cy + 18), radius=4, fill=(245, 245, 250, 255))
        draw.ellipse((cx - 32, cy + 4, cx - 20, cy + 16), fill=(255, 200, 150, 255))


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Pill Colors
    pill_palettes = {
        "red": ((235, 45, 45), (255, 160, 160), (145, 18, 18)),
        "yellow": ((245, 215, 30), (255, 250, 160), (165, 125, 12)),
        "blue": ((45, 135, 245), (165, 215, 255), (20, 65, 155)),
    }

    # 1. Pills (32x32 tiles, Y=0, 32, 64)
    # Shapes: Left=0, Right=32, Top=64, Bottom=96, Single=128
    half_types = ["left", "right", "top", "bottom", "single"]
    for row_idx, (color_name, pal) in enumerate(pill_palettes.items()):
        y_center = row_idx * 32 + 16
        for col_idx, h_type in enumerate(half_types):
            x_center = col_idx * 32 + 16
            draw_capsule_half(draw, x_center, y_center, 28, pal[0], pal[1], pal[2], h_type)

    # 2. Small Cell Viruses (32x32 tiles, Y=96)
    virus_types = ["red", "yellow", "blue"]
    for v_idx, v_type in enumerate(virus_types):
        for frame in (0, 1):
            x_center = (v_idx * 2 + frame) * 32 + 16
            y_center = 96 + 16
            draw_virus_cell_sprite(draw, x_center, y_center, 26, v_type, frame)

    # 3. Large Petri Dish Mascot Viruses (64x64 tiles, Y=128)
    for v_idx, v_type in enumerate(virus_types):
        for frame in (0, 1):
            x_center = (v_idx * 2 + frame) * 64 + 32
            y_center = 128 + 32
            draw_virus_cell_sprite(draw, x_center, y_center, 56, v_type, frame)

    # 4. Dr. Mario Mascot (64x96, Y=224)
    for frame in (0, 1):
        x_center = frame * 64 + 32
        y_center = 224 + 48
        draw_dr_mario_mascot(draw, x_center, y_center, frame)

    # 5. Particle FX Starbursts (Y=336)
    for s_idx in range(4):
        cx = s_idx * 32 + 16
        cy = 336 + 16
        r = 10 + s_idx * 2
        col = [(255, 240, 80), (255, 100, 100), (80, 200, 255), (255, 255, 255)][s_idx]
        draw.line([(cx - r, cy), (cx + r, cy)], fill=(*col, 240), width=2)
        draw.line([(cx, cy - r), (cx, cy + r)], fill=(*col, 240), width=2)
        draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(255, 255, 255, 255))

    out_path = root / "assets" / "sprites" / "drmario.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")


if __name__ == "__main__":
    main()
