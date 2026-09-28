#!/usr/bin/env python3
"""Generate high-fidelity 512x512 RGBA sprite sheet for Battleship Pro: Tactical Naval Warfare.
Includes:
- Aircraft Carrier (Size 5: 160x32, Normal & Damaged/Burning)
- Battleship (Size 4: 128x32, Normal & Damaged/Burning)
- Cruiser (Size 3: 96x32, Normal & Damaged/Burning)
- Submarine (Size 3: 96x32, Normal & Damaged/Burning)
- Destroyer (Size 2: 64x32, Normal & Damaged/Burning)
- Combat Markers & FX: Ocean Water Tile, Radar Grid Tile, Water Splash, Fire Blast, Sunk Wreckage,
  Sonar Ping, Crosshair, Artillery Shell, Torpedo, Naval Medals.
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

SHEET_SIZE = 512


def draw_aircraft_carrier(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_damaged: bool = False) -> None:
    w, h = 160, 32
    # Flight deck polygon (broad flat deck with tapered bow)
    deck_col = (51, 65, 85) if not is_damaged else (65, 45, 45)
    border_col = (148, 163, 184) if not is_damaged else (185, 28, 28)
    deck_pts = [
        (ox + 4, oy + 4),
        (ox + w - 18, oy + 4),
        (ox + w - 2, oy + 12),
        (ox + w - 2, oy + h - 12),
        (ox + w - 18, oy + h - 4),
        (ox + 4, oy + h - 4),
    ]
    draw.polygon(deck_pts, fill=(*deck_col, 255), outline=(*border_col, 255))

    # Flight deck runway center dashed line
    runway_col = (241, 245, 249, 230) if not is_damaged else (148, 163, 184, 180)
    for seg in range(ox + 10, ox + w - 20, 16):
        draw.line([(seg, oy + 16), (seg + 10, oy + 16)], fill=runway_col, width=2)

    # Deck yellow landing hash marks
    draw.line([(ox + 16, oy + 6), (ox + 16, oy + 26)], fill=(245, 158, 11, 220), width=2)
    draw.line([(ox + 30, oy + 6), (ox + 30, oy + 26)], fill=(245, 158, 11, 220), width=2)

    # Island / Command Tower (Starboard side, around X = 70..100)
    island_col = (30, 41, 59) if not is_damaged else (20, 15, 15)
    draw.rectangle((ox + 70, oy + 4, ox + 96, oy + 11), fill=(*island_col, 255), outline=(100, 116, 139, 255))
    # Island bridge windows
    for i in range(4):
        draw.rectangle((ox + 74 + i * 5, oy + 6, ox + 77 + i * 5, oy + 8), fill=(34, 211, 238, 240))
    # Radar mast & antenna
    draw.line([(ox + 82, oy + 1), (ox + 82, oy + 4)], fill=(34, 211, 238, 255), width=2)
    draw.ellipse((ox + 80, oy - 2, ox + 84, oy + 2), fill=(34, 211, 238, 255))

    # Parked Jet Silhouette (near stern)
    draw.polygon([(ox + 42, oy + 7), (ox + 52, oy + 10), (ox + 42, oy + 13)], fill=(15, 23, 42, 220))
    draw.polygon([(ox + 22, oy + 7), (ox + 32, oy + 10), (ox + 22, oy + 13)], fill=(15, 23, 42, 220))

    if is_damaged:
        # Burning crater
        draw.ellipse((ox + 110, oy + 8, ox + 136, oy + 24), fill=(239, 68, 68, 180), outline=(245, 158, 11, 255), width=2)
        draw.ellipse((ox + 116, oy + 11, ox + 130, oy + 21), fill=(255, 255, 255, 220))


def draw_battleship_ship(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_damaged: bool = False) -> None:
    w, h = 128, 32
    # Heavy armor warship hull
    hull_col = (71, 85, 105) if not is_damaged else (75, 45, 45)
    border_col = (203, 213, 225) if not is_damaged else (185, 28, 28)
    hull_pts = [
        (ox + 4, oy + 6),
        (ox + w - 24, oy + 6),
        (ox + w - 2, oy + 16),
        (ox + w - 24, oy + h - 6),
        (ox + 4, oy + h - 6),
        (ox, oy + 16),
    ]
    draw.polygon(hull_pts, fill=(*hull_col, 255), outline=(*border_col, 255))
    draw.line([(ox + 6, oy + 8), (ox + w - 22, oy + 8)], fill=(148, 163, 184, 255), width=1)

    # Superstructure Bridge in center
    draw.rectangle((ox + 48, oy + 9, ox + 76, oy + 23), fill=(30, 41, 59, 255), outline=(100, 116, 139, 255))
    # Radar & Funnel stack
    draw.rectangle((ox + 58, oy + 12, ox + 68, oy + 20), fill=(15, 23, 42, 255))
    draw.ellipse((ox + 60, oy + 4, ox + 66, oy + 10), fill=(245, 158, 11, 255))

    # Main Gun Turret #1 (Bow forward)
    draw.ellipse((ox + 92, oy + 11, ox + 106, oy + 21), fill=(30, 41, 59, 255), outline=(148, 163, 184, 255))
    draw.line([(ox + 104, oy + 14), (ox + 118, oy + 13)], fill=(15, 23, 42, 255), width=2)
    draw.line([(ox + 104, oy + 18), (ox + 118, oy + 19)], fill=(15, 23, 42, 255), width=2)

    # Main Gun Turret #2 (Bow secondary)
    draw.ellipse((ox + 78, oy + 12, ox + 90, oy + 20), fill=(30, 41, 59, 255), outline=(148, 163, 184, 255))
    draw.line([(ox + 88, oy + 14), (ox + 98, oy + 13)], fill=(15, 23, 42, 255), width=2)
    draw.line([(ox + 88, oy + 18), (ox + 98, oy + 19)], fill=(15, 23, 42, 255), width=2)

    # Aft Gun Turret (Stern)
    draw.ellipse((ox + 22, oy + 11, ox + 36, oy + 21), fill=(30, 41, 59, 255), outline=(148, 163, 184, 255))
    draw.line([(ox + 24, oy + 14), (ox + 10, oy + 13)], fill=(15, 23, 42, 255), width=2)
    draw.line([(ox + 24, oy + 18), (ox + 10, oy + 19)], fill=(15, 23, 42, 255), width=2)

    if is_damaged:
        draw.ellipse((ox + 46, oy + 7, ox + 72, oy + 25), fill=(239, 68, 68, 190), outline=(245, 158, 11, 255), width=2)
        draw.ellipse((ox + 52, oy + 11, ox + 66, oy + 21), fill=(255, 255, 255, 230))


def draw_cruiser_ship(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_damaged: bool = False) -> None:
    w, h = 96, 32
    # Sleek modern missile cruiser hull
    hull_col = (51, 65, 85) if not is_damaged else (70, 45, 45)
    border_col = (148, 163, 184) if not is_damaged else (185, 28, 28)
    hull_pts = [
        (ox + 4, oy + 7),
        (ox + w - 18, oy + 7),
        (ox + w - 2, oy + 16),
        (ox + w - 18, oy + h - 7),
        (ox + 4, oy + h - 7),
        (ox, oy + 16),
    ]
    draw.polygon(hull_pts, fill=(*hull_col, 255), outline=(*border_col, 255))

    # Center Bridge & Radome
    draw.rectangle((ox + 34, oy + 10, ox + 56, oy + 22), fill=(30, 41, 59, 255), outline=(100, 116, 139, 255))
    # Radome dome (Cyan)
    draw.ellipse((ox + 42, oy + 6, ox + 50, oy + 14), fill=(34, 211, 238, 255), outline=(255, 255, 255, 200))

    # Bow Gun Turret
    draw.ellipse((ox + 66, oy + 12, ox + 78, oy + 20), fill=(15, 23, 42, 255), outline=(148, 163, 184, 255))
    draw.line([(ox + 76, oy + 16), (ox + 88, oy + 16)], fill=(15, 23, 42, 255), width=2)

    # Vertical Launch Missile Cell VLS (Aft)
    draw.rectangle((ox + 14, oy + 10, ox + 28, oy + 22), fill=(15, 23, 42, 255), outline=(245, 158, 11, 255))
    for r in range(2):
        for c in range(3):
            draw.rectangle((ox + 16 + c * 4, oy + 12 + r * 5, ox + 18 + c * 4, oy + 15 + r * 5), fill=(239, 68, 68, 255))

    if is_damaged:
        draw.ellipse((ox + 30, oy + 8, ox + 52, oy + 24), fill=(239, 68, 68, 190), outline=(245, 158, 11, 255), width=2)


def draw_submarine_ship(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_damaged: bool = False) -> None:
    w, h = 96, 32
    # Streamlined teardrop submersible hull
    hull_col = (30, 41, 59) if not is_damaged else (55, 30, 30)
    border_col = (100, 116, 139) if not is_damaged else (185, 28, 28)
    draw.ellipse((ox + 4, oy + 8, ox + w - 4, oy + h - 8), fill=(*hull_col, 255), outline=(*border_col, 255), width=2)

    # Conning Tower (Sail)
    tower_col = (15, 23, 42)
    draw.rectangle((ox + 40, oy + 6, ox + 56, oy + 16), fill=(*tower_col, 255), outline=(*border_col, 255))
    # Periscope mast
    draw.line([(ox + 48, oy + 2), (ox + 48, oy + 6)], fill=(203, 213, 225, 255), width=2)
    draw.line([(ox + 48, oy + 2), (ox + 52, oy + 2)], fill=(203, 213, 225, 255), width=2)

    # Sonar Bow Sphere (Cyan)
    draw.chord((ox + w - 16, oy + 10, ox + w - 4, oy + h - 10), start=270, end=90, fill=(34, 211, 238, 220), outline=(255, 255, 255, 200))

    # Portholes
    for p in range(3):
        px = ox + 20 + p * 8
        draw.ellipse((px, oy + 14, px + 4, oy + 18), fill=(245, 158, 11, 255))

    # Stern Propeller Fins
    draw.polygon([(ox + 8, oy + 6), (ox + 2, oy + 16), (ox + 8, oy + 26)], fill=(100, 116, 139, 255))

    if is_damaged:
        draw.ellipse((ox + 36, oy + 7, ox + 58, oy + 25), fill=(239, 68, 68, 190), outline=(245, 158, 11, 255), width=2)


def draw_destroyer_ship(draw: ImageDraw.ImageDraw, ox: int, oy: int, is_damaged: bool = False) -> None:
    w, h = 64, 32
    # Fast nimble escort destroyer hull
    hull_col = (51, 65, 85) if not is_damaged else (70, 45, 45)
    border_col = (148, 163, 184) if not is_damaged else (185, 28, 28)
    hull_pts = [
        (ox + 4, oy + 8),
        (ox + w - 14, oy + 8),
        (ox + w - 2, oy + 16),
        (ox + w - 14, oy + h - 8),
        (ox + 4, oy + h - 8),
        (ox, oy + 16),
    ]
    draw.polygon(hull_pts, fill=(*hull_col, 255), outline=(*border_col, 255))

    # Bridge & Mast
    draw.rectangle((ox + 22, oy + 10, ox + 38, oy + 22), fill=(30, 41, 59, 255), outline=(100, 116, 139, 255))
    draw.line([(ox + 30, oy + 5), (ox + 30, oy + 10)], fill=(34, 211, 238, 255), width=2)

    # Forward Gun Mount
    draw.ellipse((ox + 44, oy + 12, ox + 52, oy + 20), fill=(15, 23, 42, 255))
    draw.line([(ox + 50, oy + 16), (ox + 58, oy + 16)], fill=(15, 23, 42, 255), width=2)

    # Stern Depth Charge Rack
    draw.rectangle((ox + 6, oy + 11, ox + 14, oy + 21), fill=(220, 38, 38, 255), outline=(245, 158, 11, 255))

    if is_damaged:
        draw.ellipse((ox + 18, oy + 8, ox + 38, oy + 24), fill=(239, 68, 68, 190), outline=(245, 158, 11, 255), width=2)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # -------------------------------------------------------------
    # Row 0 (Y=0): Carrier Normal (160x32)
    # Row 1 (Y=32): Carrier Damaged (160x32)
    # -------------------------------------------------------------
    draw_aircraft_carrier(draw, 0, 0, is_damaged=False)
    draw_aircraft_carrier(draw, 0, 32, is_damaged=True)

    # -------------------------------------------------------------
    # Row 2 (Y=64): Battleship Normal (128x32)
    # Row 3 (Y=96): Battleship Damaged (128x32)
    # -------------------------------------------------------------
    draw_battleship_ship(draw, 0, 64, is_damaged=False)
    draw_battleship_ship(draw, 0, 96, is_damaged=True)

    # -------------------------------------------------------------
    # Row 4 (Y=128): Cruiser Normal (96x32)
    # Row 5 (Y=160): Cruiser Damaged (96x32)
    # -------------------------------------------------------------
    draw_cruiser_ship(draw, 0, 128, is_damaged=False)
    draw_cruiser_ship(draw, 0, 160, is_damaged=True)

    # -------------------------------------------------------------
    # Row 6 (Y=192): Submarine Normal (96x32)
    # Row 7 (Y=224): Submarine Damaged (96x32)
    # -------------------------------------------------------------
    draw_submarine_ship(draw, 0, 192, is_damaged=False)
    draw_submarine_ship(draw, 0, 224, is_damaged=True)

    # -------------------------------------------------------------
    # Row 8 (Y=256): Destroyer Normal (64x32)
    # Row 9 (Y=288): Destroyer Damaged (64x32)
    # -------------------------------------------------------------
    draw_destroyer_ship(draw, 0, 256, is_damaged=False)
    draw_destroyer_ship(draw, 0, 288, is_damaged=True)

    # -------------------------------------------------------------
    # Row 10 (Y=320..351): 32x32 Tiles & FX Markers
    # -------------------------------------------------------------
    # 1. Ocean Water Tile (X=0, Y=320)
    draw.rectangle((0, 320, 31, 351), fill=(15, 32, 58, 255), outline=(30, 70, 110, 255))
    draw.line([(4, 328), (14, 328)], fill=(56, 189, 248, 120), width=1)
    draw.line([(18, 334), (28, 334)], fill=(56, 189, 248, 100), width=1)
    draw.line([(8, 342), (20, 342)], fill=(56, 189, 248, 140), width=1)

    # 2. Radar Grid Tile (X=32, Y=320)
    draw.rectangle((32, 320, 63, 351), fill=(8, 28, 22, 255), outline=(20, 70, 45, 255))
    draw.rectangle((36, 324, 59, 347), outline=(34, 197, 94, 60))
    draw.ellipse((46, 334, 49, 337), fill=(34, 197, 94, 200))

    # 3. Water Splash (Miss) (X=64, Y=320)
    draw.ellipse((68, 330, 92, 348), fill=(186, 230, 253, 200), outline=(255, 255, 255, 255), width=2)
    draw.ellipse((72, 334, 88, 344), fill=(255, 255, 255, 230))
    # Water droplets
    for drop_x, drop_y in [(70, 324), (80, 322), (90, 325), (76, 326), (84, 327)]:
        draw.ellipse((drop_x, drop_y, drop_x + 3, drop_y + 4), fill=(224, 242, 254, 240))

    # 4. Fiery Explosion (Hit) (X=96, Y=320)
    draw.ellipse((98, 322, 126, 350), fill=(239, 68, 68, 240), outline=(245, 158, 11, 255), width=2)
    draw.ellipse((104, 328, 120, 344), fill=(251, 191, 36, 255), outline=(255, 255, 255, 240))
    draw.ellipse((108, 332, 116, 340), fill=(255, 255, 255, 255))

    # 5. Sunk Wreckage Marker (X=128, Y=320)
    draw.rectangle((130, 322, 158, 350), fill=(40, 15, 15, 255), outline=(239, 68, 68, 255), width=2)
    draw.line([(134, 326), (154, 346)], fill=(239, 68, 68, 255), width=3)
    draw.line([(154, 326), (134, 346)], fill=(239, 68, 68, 255), width=3)
    draw.ellipse((140, 332, 148, 340), fill=(255, 255, 255, 240))

    # 6. Sonar Scan Ring (X=160, Y=320)
    draw.ellipse((162, 322, 190, 350), outline=(34, 211, 238, 240), width=2)
    draw.ellipse((168, 328, 184, 344), outline=(34, 211, 238, 180), width=1)
    draw.ellipse((174, 334, 178, 338), fill=(34, 211, 238, 255))

    # 7. Crosshair Target Lock (X=192, Y=320)
    draw.ellipse((194, 322, 222, 350), outline=(239, 68, 68, 255), width=2)
    draw.line([(192, 336), (224, 336)], fill=(239, 68, 68, 255), width=2)
    draw.line([(208, 320), (208, 352)], fill=(239, 68, 68, 255), width=2)
    draw.ellipse((206, 334, 210, 338), fill=(255, 255, 255, 255))

    # 8. Recon Golden Star (X=224, Y=320)
    draw.ellipse((226, 322, 254, 350), fill=(245, 158, 11, 220), outline=(255, 255, 255, 240), width=2)
    draw.polygon([
        (240, 326), (243, 333), (250, 334), (245, 339),
        (247, 346), (240, 342), (233, 346), (235, 339),
        (230, 334), (237, 333)
    ], fill=(255, 255, 255, 255))

    # 9. Artillery Heavy Shell (X=256, Y=320)
    draw.ellipse((262, 324, 282, 348), fill=(245, 158, 11, 255), outline=(180, 83, 9, 255), width=1)
    draw.ellipse((268, 328, 276, 336), fill=(255, 255, 255, 240))

    # 10. Torpedo (X=288, Y=320)
    draw.ellipse((290, 330, 318, 342), fill=(239, 68, 68, 255), outline=(185, 28, 28, 255), width=1)
    draw.polygon([(290, 328), (294, 336), (290, 344)], fill=(245, 158, 11, 255))
    draw.ellipse((312, 332, 318, 340), fill=(255, 255, 255, 240))

    # 11. Naval Medal / Fleet Admiral Badge (X=320, Y=320)
    draw.polygon([(324, 322), (348, 322), (348, 332), (336, 342), (324, 332)], fill=(30, 58, 138, 255), outline=(245, 158, 11, 255), width=2)
    draw.ellipse((330, 336, 342, 348), fill=(245, 158, 11, 255), outline=(255, 255, 255, 240), width=2)

    # 12. Green Radar Sweep Reticle (X=352, Y=320)
    draw.ellipse((354, 322, 382, 350), outline=(34, 197, 94, 255), width=2)
    draw.line([(352, 336), (384, 336)], fill=(34, 197, 94, 255), width=1)
    draw.line([(368, 320), (368, 352)], fill=(34, 197, 94, 255), width=1)

    out_path = root / "assets" / "sprites" / "battleship.png"
    sheet.save(out_path, format="PNG")
    print(f"Successfully generated {out_path} ({SHEET_SIZE}x{SHEET_SIZE})")

    # Local symlink/fallback directory
    local_path = root / "battleship" / "assets" / "sprites" / "battleship.png"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(local_path, format="PNG")


if __name__ == "__main__":
    main()
