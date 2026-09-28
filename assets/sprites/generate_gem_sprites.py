#!/usr/bin/env python3
"""Generate a high-fidelity 1024x1024 RGBA sprite sheet for Bejeweled gems,
special gem variants (Flame, Star, Hypercube, Supernova, Time Bonus), and FX.
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

TILE_SIZE = 128
SCALE = 2  # 2x supersampling for ultra-crisp antialiasing
DRAW_SIZE = TILE_SIZE * SCALE  # 256x256
SHEET_COLS = 8
SHEET_ROWS = 8

# Primary & Accent colors for 7 gem types
GEM_PALETTES = [
    # 1: Ruby (Red) - Octagon
    {
        "name": "Ruby",
        "primary": (235, 35, 55),
        "dark": (140, 10, 25),
        "deep": (70, 5, 12),
        "highlight": (255, 160, 175),
        "glow": (255, 60, 80),
        "shape": "octagon",
    },
    # 2: Sapphire (Royal Blue) - Hexagon / Teardrop
    {
        "name": "Sapphire",
        "primary": (40, 120, 255),
        "dark": (15, 50, 160),
        "deep": (8, 22, 90),
        "highlight": (160, 210, 255),
        "glow": (70, 150, 255),
        "shape": "hexagon",
    },
    # 3: Emerald (Green) - Step-Cut Square
    {
        "name": "Emerald",
        "primary": (40, 215, 95),
        "dark": (15, 120, 45),
        "deep": (8, 60, 22),
        "highlight": (175, 255, 200),
        "glow": (60, 245, 120),
        "shape": "square",
    },
    # 4: Topaz (Golden Yellow) - Triangle / Pyramid
    {
        "name": "Topaz",
        "primary": (255, 205, 30),
        "dark": (180, 120, 10),
        "deep": (100, 60, 5),
        "highlight": (255, 250, 170),
        "glow": (255, 225, 60),
        "shape": "triangle",
    },
    # 5: Amethyst (Purple) - Radiant Circle
    {
        "name": "Amethyst",
        "primary": (175, 60, 245),
        "dark": (100, 20, 160),
        "deep": (55, 10, 95),
        "highlight": (230, 175, 255),
        "glow": (200, 90, 255),
        "shape": "circle",
    },
    # 6: Diamond (Ice White / Silver) - Rhombus Kite
    {
        "name": "Diamond",
        "primary": (230, 242, 255),
        "dark": (150, 175, 210),
        "deep": (90, 110, 145),
        "highlight": (255, 255, 255),
        "glow": (210, 235, 255),
        "shape": "rhombus",
    },
    # 7: Amber (Mandarin Orange) - Pentagon / Shield
    {
        "name": "Amber",
        "primary": (255, 135, 25),
        "dark": (175, 65, 8),
        "deep": (95, 30, 4),
        "highlight": (255, 215, 155),
        "glow": (255, 160, 45),
        "shape": "pentagon",
    },
]


def blend_color(c1: tuple[int, int, int], c2: tuple[int, int, int], factor: float) -> tuple[int, int, int]:
    f = max(0.0, min(1.0, factor))
    return (
        int(c1[0] * (1.0 - f) + c2[0] * f),
        int(c1[1] * (1.0 - f) + c2[1] * f),
        int(c1[2] * (1.0 - f) + c2[2] * f),
    )


def draw_specular_glint(draw: ImageDraw.ImageDraw, cx: float, cy: float, radius: float, alpha: int = 240) -> None:
    # 4-point cross shine star
    r = radius
    col = (255, 255, 255, alpha)
    draw.polygon([(cx, cy - r), (cx + r * 0.25, cy), (cx, cy + r), (cx - r * 0.25, cy)], fill=col)
    draw.polygon([(cx - r, cy), (cx, cy + r * 0.25), (cx + r, cy), (cx, cy - r * 0.25)], fill=col)
    draw.ellipse((cx - r * 0.35, cy - r * 0.35, cx + r * 0.35, cy + r * 0.35), fill=(255, 255, 255, 255))


def render_ruby(size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    r = size * 0.40
    cut = r * 0.38

    outer_pts = [
        (cx - r + cut, cy - r),
        (cx + r - cut, cy - r),
        (cx + r, cy - r + cut),
        (cx + r, cy + r - cut),
        (cx + r - cut, cy + r),
        (cx - r + cut, cy + r),
        (cx - r, cy + r - cut),
        (cx - r, cy - r + cut),
    ]

    # Drop shadow
    shadow_pts = [(x + size * 0.03, y + size * 0.04) for x, y in outer_pts]
    draw.polygon(shadow_pts, fill=(10, 2, 5, 120))

    # Base gem body
    draw.polygon(outer_pts, fill=(210, 25, 45, 255), outline=(120, 10, 25, 255), width=int(size * 0.02))

    # Facets (8 outer trapezoid bevels)
    inner_r = r * 0.55
    inner_cut = inner_r * 0.38
    inner_pts = [
        (cx - inner_r + inner_cut, cy - inner_r),
        (cx + inner_r - inner_cut, cy - inner_r),
        (cx + inner_r, cy - inner_r + inner_cut),
        (cx + inner_r, cy + inner_r - inner_cut),
        (cx + inner_r - inner_cut, cy + inner_r),
        (cx - inner_r + inner_cut, cy + inner_r),
        (cx - inner_r, cy + inner_r - inner_cut),
        (cx - inner_r, cy - inner_r + inner_cut),
    ]

    facet_colors = [
        (255, 140, 155, 240),  # Top
        (255, 100, 120, 230),  # Top-right
        (190, 20, 40, 230),    # Right
        (130, 10, 25, 230),    # Bottom-right
        (100, 8, 18, 240),     # Bottom
        (140, 12, 28, 230),    # Bottom-left
        (210, 40, 60, 230),    # Left
        (255, 160, 175, 240),  # Top-left
    ]

    for i in range(8):
        next_i = (i + 1) % 8
        poly = [outer_pts[i], outer_pts[next_i], inner_pts[next_i], inner_pts[i]]
        draw.polygon(poly, fill=facet_colors[i], outline=(255, 190, 205, 90), width=1)

    # Raised center table facet
    draw.polygon(inner_pts, fill=(245, 45, 70, 255), outline=(255, 180, 195, 200), width=int(size * 0.015))

    # Specular shine
    draw_specular_glint(draw, cx - inner_r * 0.4, cy - inner_r * 0.4, size * 0.12)
    return im


def render_sapphire(size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    r = size * 0.42

    outer_pts = []
    for i in range(6):
        ang = math.pi / 6.0 + i * math.pi / 3.0
        outer_pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))

    # Shadow
    shadow_pts = [(x + size * 0.03, y + size * 0.04) for x, y in outer_pts]
    draw.polygon(shadow_pts, fill=(5, 10, 30, 120))

    # Base body
    draw.polygon(outer_pts, fill=(25, 90, 230, 255), outline=(10, 35, 120, 255), width=int(size * 0.02))

    # Hexagonal outer bevels
    inner_r = r * 0.58
    inner_pts = []
    for i in range(6):
        ang = math.pi / 6.0 + i * math.pi / 3.0
        inner_pts.append((cx + inner_r * math.cos(ang), cy + inner_r * math.sin(ang)))

    facet_colors = [
        (130, 190, 255, 230),  # Top right
        (40, 110, 240, 220),   # Right
        (18, 55, 150, 240),    # Bottom right
        (10, 35, 110, 240),    # Bottom left
        (35, 95, 220, 220),    # Left
        (180, 225, 255, 240),  # Top left
    ]

    for i in range(6):
        next_i = (i + 1) % 6
        poly = [outer_pts[i], outer_pts[next_i], inner_pts[next_i], inner_pts[i]]
        draw.polygon(poly, fill=facet_colors[i], outline=(180, 220, 255, 80), width=1)

    # Center star facets
    for i in range(6):
        next_i = (i + 1) % 6
        star_color = (60, 140, 255, 240) if i % 2 == 0 else (30, 100, 240, 240)
        draw.polygon([(cx, cy), inner_pts[i], inner_pts[next_i]], fill=star_color, outline=(200, 230, 255, 120))

    # Specular shine
    draw_specular_glint(draw, cx - inner_r * 0.35, cy - inner_r * 0.45, size * 0.13)
    return im


def render_emerald(size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    r = size * 0.39
    chamfer = r * 0.28

    outer_pts = [
        (cx - r + chamfer, cy - r),
        (cx + r - chamfer, cy - r),
        (cx + r, cy - r + chamfer),
        (cx + r, cy + r - chamfer),
        (cx + r - chamfer, cy + r),
        (cx - r + chamfer, cy + r),
        (cx - r, cy + r - chamfer),
        (cx - r, cy - r + chamfer),
    ]

    # Shadow
    shadow_pts = [(x + size * 0.03, y + size * 0.04) for x, y in outer_pts]
    draw.polygon(shadow_pts, fill=(5, 20, 10, 120))

    # Base emerald body
    draw.polygon(outer_pts, fill=(25, 175, 75, 255), outline=(10, 80, 30, 255), width=int(size * 0.02))

    # Stepped concentric facets
    prev_step_pts = outer_pts
    step_r = r * 0.48
    for step_idx, step_scale in enumerate([0.72, 0.48]):
        step_r = r * step_scale
        step_cham = step_r * 0.28
        step_pts = [
            (cx - step_r + step_cham, cy - step_r),
            (cx + step_r - step_cham, cy - step_r),
            (cx + step_r, cy - step_r + step_cham),
            (cx + step_r, cy + step_r - step_cham),
            (cx + step_r - step_cham, cy + step_r),
            (cx - step_r + step_cham, cy + step_r),
            (cx - step_r, cy + step_r - step_cham),
            (cx - step_r, cy - step_r + step_cham),
        ]

        for i in range(8):
            next_i = (i + 1) % 8
            if i in (0, 7):
                fcol = (140, 245, 175, 230)
            elif i in (1, 2):
                fcol = (60, 205, 110, 220)
            elif i in (3, 4):
                fcol = (12, 90, 35, 240)
            else:
                fcol = (30, 150, 65, 220)
            draw.polygon([prev_step_pts[i], prev_step_pts[next_i], step_pts[next_i], step_pts[i]], fill=fcol, outline=(180, 255, 210, 80))

        prev_step_pts = step_pts

    # Emerald table
    draw.polygon(step_pts, fill=(45, 225, 105, 255), outline=(200, 255, 220, 220), width=int(size * 0.015))

    # Specular shine
    draw_specular_glint(draw, cx - step_r * 0.45, cy - step_r * 0.45, size * 0.12)
    return im


def render_topaz(size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    r = size * 0.42

    # Triangle points with tip at top
    p_top = (cx, cy - r * 1.05)
    p_right = (cx + r * 1.02, cy + r * 0.75)
    p_left = (cx - r * 1.02, cy + r * 0.75)
    outer_pts = [p_top, p_right, p_left]

    # Shadow
    shadow_pts = [(x + size * 0.03, y + size * 0.04) for x, y in outer_pts]
    draw.polygon(shadow_pts, fill=(35, 25, 5, 120))

    # Base body
    draw.polygon(outer_pts, fill=(245, 185, 20, 255), outline=(140, 95, 8, 255), width=int(size * 0.02))

    # Facet centroid apex
    apex = (cx, cy + r * 0.08)

    # 3 Main pyramid facets
    draw.polygon([p_top, p_right, apex], fill=(255, 235, 110, 240), outline=(255, 245, 180, 140))
    draw.polygon([p_right, p_left, apex], fill=(160, 100, 10, 240), outline=(255, 210, 120, 100))
    draw.polygon([p_left, p_top, apex], fill=(255, 210, 60, 240), outline=(255, 245, 180, 140))

    # Inner brilliant subdiv facets
    mid_top_l = ((p_left[0] + p_top[0]) / 2, (p_left[1] + p_top[1]) / 2)
    mid_bot = ((p_right[0] + p_left[0]) / 2, (p_right[1] + p_left[1]) / 2)

    draw.polygon([apex, mid_top_l, p_top], fill=(255, 250, 160, 230))
    draw.polygon([apex, mid_bot, p_left], fill=(210, 140, 20, 220))

    # Specular shine
    draw_specular_glint(draw, cx - r * 0.22, cy - r * 0.35, size * 0.12)
    return im


def render_amethyst(size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    r = size * 0.40

    # Shadow
    draw.ellipse((cx - r + size * 0.03, cy - r + size * 0.04, cx + r + size * 0.03, cy + r + size * 0.04), fill=(20, 5, 30, 120))

    # Base circle
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(145, 40, 215, 255), outline=(75, 12, 115, 255), width=int(size * 0.02))

    # Radial faceted ring (12 brilliant facets)
    num_facets = 12
    inner_r = r * 0.52
    for i in range(num_facets):
        a1 = i * 2.0 * math.pi / num_facets
        a2 = (i + 1) * 2.0 * math.pi / num_facets
        p1 = (cx + r * math.cos(a1), cy + r * math.sin(a1))
        p2 = (cx + r * math.cos(a2), cy + r * math.sin(a2))
        ip1 = (cx + inner_r * math.cos(a1), cy + inner_r * math.sin(a1))
        ip2 = (cx + inner_r * math.cos(a2), cy + inner_r * math.sin(a2))

        cos_ang = -math.sin((a1 + a2) / 2.0 + math.pi / 4.0)
        f = (cos_ang + 1.0) / 2.0
        fcol = blend_color((65, 12, 105), (235, 175, 255), f)
        draw.polygon([p1, p2, ip2, ip1], fill=(*fcol, 230), outline=(230, 180, 255, 70))

    # Center radiant table
    draw.ellipse((cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r), fill=(185, 65, 250, 255), outline=(240, 195, 255, 200), width=int(size * 0.015))

    # Internal star cut
    for i in range(6):
        ang = i * math.pi / 3.0
        draw.line([cx, cy, cx + inner_r * 0.85 * math.cos(ang), cy + inner_r * 0.85 * math.sin(ang)], fill=(245, 210, 255, 170), width=int(size * 0.01))

    # Specular shine
    draw_specular_glint(draw, cx - inner_r * 0.35, cy - inner_r * 0.4, size * 0.12)
    return im


def render_diamond(size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    r_x = size * 0.36
    r_y = size * 0.44

    outer_pts = [
        (cx, cy - r_y),
        (cx + r_x, cy),
        (cx, cy + r_y),
        (cx - r_x, cy),
    ]

    # Shadow
    shadow_pts = [(x + size * 0.03, y + size * 0.04) for x, y in outer_pts]
    draw.polygon(shadow_pts, fill=(15, 20, 35, 120))

    # Base crystal body
    draw.polygon(outer_pts, fill=(225, 238, 252, 255), outline=(120, 145, 185, 255), width=int(size * 0.02))

    # Kite facets
    inner_rx = r_x * 0.48
    inner_ry = r_y * 0.48
    inner_pts = [
        (cx, cy - inner_ry),
        (cx + inner_rx, cy),
        (cx, cy + inner_ry),
        (cx - inner_rx, cy),
    ]

    facet_colors = [
        (255, 255, 255, 240),  # Top Right (Pure White Brilliance)
        (170, 200, 235, 230),  # Bottom Right (Ice Blue)
        (110, 140, 180, 240),  # Bottom Left (Deep Steel Shadow)
        (235, 248, 255, 240),  # Top Left (Bright Ice)
    ]

    for i in range(4):
        next_i = (i + 1) % 4
        poly = [outer_pts[i], outer_pts[next_i], inner_pts[next_i], inner_pts[i]]
        draw.polygon(poly, fill=facet_colors[i], outline=(255, 255, 255, 120))

    # Raised center kite
    draw.polygon(inner_pts, fill=(245, 252, 255, 255), outline=(255, 255, 255, 240), width=int(size * 0.015))

    # Prismatic refraction cross lines
    draw.line([outer_pts[0], outer_pts[2]], fill=(255, 255, 255, 180), width=int(size * 0.01))
    draw.line([outer_pts[1], outer_pts[3]], fill=(200, 230, 255, 180), width=int(size * 0.01))

    # Specular shine
    draw_specular_glint(draw, cx - inner_rx * 0.25, cy - inner_ry * 0.35, size * 0.14)
    return im


def render_amber(size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    r = size * 0.41

    outer_pts = []
    # Pentagon cut
    for i in range(5):
        ang = -math.pi / 2.0 + i * 2.0 * math.pi / 5.0
        outer_pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))

    # Shadow
    shadow_pts = [(x + size * 0.03, y + size * 0.04) for x, y in outer_pts]
    draw.polygon(shadow_pts, fill=(30, 12, 2, 120))

    # Base body
    draw.polygon(outer_pts, fill=(250, 125, 15, 255), outline=(130, 50, 5, 255), width=int(size * 0.02))

    inner_r = r * 0.54
    inner_pts = []
    for i in range(5):
        ang = -math.pi / 2.0 + i * 2.0 * math.pi / 5.0
        inner_pts.append((cx + inner_r * math.cos(ang), cy + inner_r * math.sin(ang)))

    facet_colors = [
        (255, 210, 130, 240),  # Top Right
        (210, 95, 12, 230),    # Bottom Right
        (115, 40, 5, 240),     # Bottom Left
        (225, 115, 20, 230),   # Top Left
        (255, 185, 80, 240),   # Top Apex
    ]

    for i in range(5):
        next_i = (i + 1) % 5
        poly = [outer_pts[i], outer_pts[next_i], inner_pts[next_i], inner_pts[i]]
        draw.polygon(poly, fill=facet_colors[i], outline=(255, 215, 140, 90))

    # Center shield facet
    draw.polygon(inner_pts, fill=(255, 155, 35, 255), outline=(255, 225, 160, 220), width=int(size * 0.015))

    # Specular shine
    draw_specular_glint(draw, cx - inner_r * 0.35, cy - inner_r * 0.35, size * 0.12)
    return im


def render_hypercube(size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    r = size * 0.38

    # Multi-layered rotating chromatic cube
    cube_colors = [
        (255, 50, 80),    # Crimson Red
        (255, 175, 30),   # Orange Gold
        (50, 230, 120),   # Emerald Green
        (40, 190, 255),   # Cyan Blue
        (200, 70, 255),   # Purple Violet
    ]

    # Outer ambient glow aura
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse((cx - r * 1.15, cy - r * 1.15, cx + r * 1.15, cy + r * 1.15), fill=(180, 100, 255, 110))
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.06))
    im = Image.alpha_composite(im, glow)
    draw = ImageDraw.Draw(im)

    # Concentric beveled rainbow squares
    for idx, col in enumerate(cube_colors):
        s_r = r * (1.0 - idx * 0.15)
        rect = (cx - s_r, cy - s_r, cx + s_r, cy + s_r)
        draw.rounded_rectangle(rect, radius=int(size * 0.04), fill=(*col, 210), outline=(255, 255, 255, 230), width=int(size * 0.018))

    # Core luminous diamond star
    core_r = r * 0.32
    draw.polygon([(cx, cy - core_r), (cx + core_r, cy), (cx, cy + core_r), (cx - core_r, cy)], fill=(255, 255, 255, 255))
    draw_specular_glint(draw, cx, cy, size * 0.22, alpha=255)
    return im


def render_supernova(size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    r = size * 0.40

    # Blazing solar corona rays
    num_rays = 16
    for i in range(num_rays):
        ang = i * 2.0 * math.pi / num_rays
        ray_len = r * (1.18 if i % 2 == 0 else 0.95)
        rx = cx + ray_len * math.cos(ang)
        ry = cy + ray_len * math.sin(ang)
        col = (255, 210, 40, 210) if i % 2 == 0 else (255, 100, 20, 180)
        draw.line([cx, cy, rx, ry], fill=col, width=int(size * 0.035))

    # Concentric fiery solar rings
    draw.ellipse((cx - r * 0.85, cy - r * 0.85, cx + r * 0.85, cy + r * 0.85), fill=(255, 90, 15, 240), outline=(255, 220, 60, 255), width=int(size * 0.02))
    draw.ellipse((cx - r * 0.60, cy - r * 0.60, cx + r * 0.60, cy + r * 0.60), fill=(255, 185, 30, 255), outline=(255, 255, 180, 255), width=int(size * 0.02))
    draw.ellipse((cx - r * 0.35, cy - r * 0.35, cx + r * 0.35, cy + r * 0.35), fill=(255, 255, 255, 255))

    draw_specular_glint(draw, cx, cy, size * 0.25, alpha=255)
    return im


def render_flame_gem(base_gem: Image.Image, size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0

    # Fiery flame corona background
    flame_pts = [
        (cx - size * 0.35, cy + size * 0.30),
        (cx - size * 0.42, cy),
        (cx - size * 0.25, cy - size * 0.28),
        (cx - size * 0.15, cy - size * 0.18),
        (cx, cy - size * 0.46),
        (cx + size * 0.15, cy - size * 0.18),
        (cx + size * 0.25, cy - size * 0.28),
        (cx + size * 0.42, cy),
        (cx + size * 0.35, cy + size * 0.30),
        (cx, cy + size * 0.42),
    ]

    # Outer fire
    draw.polygon(flame_pts, fill=(255, 75, 15, 180), outline=(255, 200, 30, 240), width=int(size * 0.02))

    # Composite base gem
    im = Image.alpha_composite(im, base_gem)
    draw = ImageDraw.Draw(im)

    # Inner flame crown overlay
    inner_flame = [
        (cx - size * 0.22, cy + size * 0.15),
        (cx - size * 0.12, cy - size * 0.12),
        (cx, cy - size * 0.32),
        (cx + size * 0.12, cy - size * 0.12),
        (cx + size * 0.22, cy + size * 0.15),
    ]
    draw.polygon(inner_flame, fill=(255, 235, 70, 160), outline=(255, 255, 200, 220), width=int(size * 0.015))

    # Floating ember sparks
    draw.ellipse((cx - size * 0.32, cy - size * 0.25, cx - size * 0.28, cy - size * 0.21), fill=(255, 240, 90, 240))
    draw.ellipse((cx + size * 0.28, cy - size * 0.28, cx + size * 0.32, cy - size * 0.24), fill=(255, 240, 90, 240))
    return im


def render_star_gem(base_gem: Image.Image, size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0

    # Cross electric laser flares
    flare_len = size * 0.48
    col_electric = (70, 230, 255, 220)
    col_core = (255, 255, 255, 255)

    # Wide cyan beam
    draw.line([cx - flare_len, cy, cx + flare_len, cy], fill=col_electric, width=int(size * 0.05))
    draw.line([cx, cy - flare_len, cx, cy + flare_len], fill=col_electric, width=int(size * 0.05))
    # Diagonal flares
    diag_len = flare_len * 0.72
    draw.line([cx - diag_len, cy - diag_len, cx + diag_len, cy + diag_len], fill=(120, 240, 255, 180), width=int(size * 0.03))
    draw.line([cx - diag_len, cy + diag_len, cx + diag_len, cy - diag_len], fill=(120, 240, 255, 180), width=int(size * 0.03))

    # Core white laser
    draw.line([cx - flare_len, cy, cx + flare_len, cy], fill=col_core, width=int(size * 0.02))
    draw.line([cx, cy - flare_len, cx, cy + flare_len], fill=col_core, width=int(size * 0.02))

    # Composite gem
    im = Image.alpha_composite(im, base_gem)
    draw = ImageDraw.Draw(im)

    # Center shining star
    draw_specular_glint(draw, cx, cy, size * 0.20, alpha=255)
    return im


def render_time_gem(size: int = DRAW_SIZE) -> Image.Image:
    # Hourglass Time Bonus Gem
    im = render_amethyst(size)
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    r = size * 0.22

    # Hourglass gold emblem
    top_poly = [(cx - r, cy - r), (cx + r, cy - r), (cx, cy)]
    bot_poly = [(cx, cy), (cx + r, cy + r), (cx - r, cy + r)]
    draw.polygon(top_poly, fill=(255, 230, 80, 220), outline=(255, 255, 255, 255), width=int(size * 0.02))
    draw.polygon(bot_poly, fill=(255, 190, 40, 220), outline=(255, 255, 255, 255), width=int(size * 0.02))
    draw.ellipse((cx - size * 0.04, cy - size * 0.04, cx + size * 0.04, cy + size * 0.04), fill=(255, 255, 255, 255))
    return im


def render_cell_socket(size: int = DRAW_SIZE) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    pad = int(size * 0.08)
    draw.rounded_rectangle((pad, pad, size - pad, size - pad), radius=int(size * 0.12), fill=(18, 22, 36, 230), outline=(48, 60, 95, 255), width=int(size * 0.025))
    inner = pad + int(size * 0.05)
    draw.rounded_rectangle((inner, inner, size - inner, size - inner), radius=int(size * 0.08), fill=(10, 14, 24, 255), outline=(32, 40, 68, 255), width=int(size * 0.015))
    return im


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet_w = TILE_SIZE * SHEET_COLS  # 1024
    sheet_h = TILE_SIZE * SHEET_ROWS  # 1024
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))

    # 1. Render 7 standard gem bases
    gem_renders = [
        render_ruby(DRAW_SIZE),
        render_sapphire(DRAW_SIZE),
        render_emerald(DRAW_SIZE),
        render_topaz(DRAW_SIZE),
        render_amethyst(DRAW_SIZE),
        render_diamond(DRAW_SIZE),
        render_amber(DRAW_SIZE),
    ]

    # Row 0: Standard Gems 1..7 + Hypercube
    for idx, gem_im in enumerate(gem_renders):
        downscaled = gem_im.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
        sheet.paste(downscaled, (idx * TILE_SIZE, 0 * TILE_SIZE), downscaled)

    hypercube = render_hypercube(DRAW_SIZE).resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
    sheet.paste(hypercube, (7 * TILE_SIZE, 0 * TILE_SIZE), hypercube)

    # Row 1: Flame Gems 1..7 + Supernova
    for idx, gem_im in enumerate(gem_renders):
        flame_im = render_flame_gem(gem_im, DRAW_SIZE).resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
        sheet.paste(flame_im, (idx * TILE_SIZE, 1 * TILE_SIZE), flame_im)

    supernova = render_supernova(DRAW_SIZE).resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
    sheet.paste(supernova, (7 * TILE_SIZE, 1 * TILE_SIZE), supernova)

    # Row 2: Star Gems 1..7 + Time Bonus Gem
    for idx, gem_im in enumerate(gem_renders):
        star_im = render_star_gem(gem_im, DRAW_SIZE).resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
        sheet.paste(star_im, (idx * TILE_SIZE, 2 * TILE_SIZE), star_im)

    time_gem = render_time_gem(DRAW_SIZE).resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
    sheet.paste(time_gem, (7 * TILE_SIZE, 2 * TILE_SIZE), time_gem)

    # Row 3: Sockets, FX & Sparkles
    socket_im = render_cell_socket(DRAW_SIZE).resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
    sheet.paste(socket_im, (0 * TILE_SIZE, 3 * TILE_SIZE), socket_im)

    # Save output to assets/sprites/gems.png
    out_dir = root / "assets" / "sprites"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "gems.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({sheet_w}x{sheet_h})")


if __name__ == "__main__":
    main()
