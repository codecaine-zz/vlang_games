#!/usr/bin/env python3
import os
import re

DST = '/Users/codecaine/vlang_games'
SRC = '/tmp/vlang_sdl2_games'

def migrate_complex_game(game):
    src_p = os.path.join(SRC, game, 'main.v')
    with open(src_p) as f:
        src = f.read()

    # Common replacements
    text = src
    text = re.sub(r'import\s+sdl(\.image)?', '', text)
    text = re.sub(r'&sdl\.Window', 'voidptr', text)
    text = re.sub(r'&sdl\.Renderer', '&Renderer', text)
    text = re.sub(r'sdl\.Rect\b', 'Rect', text)
    text = re.sub(r'sdl\.Color\b', 'Color', text)
    text = re.sub(r'sdl\.Point\b', 'Point', text)
    text = re.sub(r'sdl\.set_render_draw_color\s*\(', 'set_render_draw_color(', text)
    text = re.sub(r'sdl\.render_fill_rect\s*\(', 'render_fill_rect(', text)
    text = re.sub(r'sdl\.render_draw_rect\s*\(', 'render_draw_rect(', text)
    text = re.sub(r'sdl\.render_draw_line\s*\(', 'render_draw_line(', text)
    text = re.sub(r'sdl\.render_draw_point\s*\(', 'render_draw_point(', text)
    text = re.sub(r'sdl\.render_clear\s*\(', 'render_clear(', text)
    text = re.sub(r'sdl\.render_copy_ex\s*\(', 'render_copy_ex(', text)
    text = re.sub(r'sdl\.render_copy\s*\(', 'render_copy(', text)
    text = re.sub(r'sdl\.render_present\s*\(.*?\)', '', text)
    text = re.sub(r'sdl\.get_ticks\s*\(\)', 'u32(time.ticks())', text)
    text = re.sub(r'sdl\.delay\s*\(.*?\)', '', text)
    text = re.sub(r'sdl\.render_set_logical_size\s*\(.*?\)', '', text)
    text = re.sub(r'sdl\.set_render_draw_blend_mode\s*\(.*?\)', '', text)

    return text

print("Script template ready")
