#!/usr/bin/env python3
import re
import os

PATH = '/Users/codecaine/vlang_games/scripts/build_batch3_all.py'
with open(PATH) as f:
    content = f.read()

# 1. mappy: new_game() -> new_game_engine()
content = content.replace("game:      new_game()\n\t\tsound_mgr: new_sound_manager()\n\t\tlast_tick: time.ticks()\n\t}\n}\n\nfn on_init(data voidptr) {\n\tmut app := unsafe { &App(data) }\n\tapp.tex_mgr.init(&app.renderer)",
                          "game:      new_game_engine()\n\t\tsound_mgr: new_sound_manager()\n\t\tlast_tick: time.ticks()\n\t}\n}\n\nfn on_init(data voidptr) {\n\tmut app := unsafe { &App(data) }\n\tapp.tex_mgr.init(&app.renderer)")

# 2. marblemadness: new_game() -> new_marble_game()
content = content.replace("def gen_marblemadness():\n    code = '''module main\n\nimport gg\nimport time\n\nconst win_w = 840\nconst win_h = 640\n\nstruct App {\nmut:\n\tctx       &gg.Context = unsafe { nil }\n\trenderer  Renderer\n\tgame      MarbleGame\n\tsound_mgr SoundManager\n\tlast_tick i64\n}\n\nfn new_app() App {\n\treturn App{\n\t\tgame:      new_game()",
                          "def gen_marblemadness():\n    code = '''module main\n\nimport gg\nimport time\n\nconst win_w = 840\nconst win_h = 640\n\nstruct App {\nmut:\n\tctx       &gg.Context = unsafe { nil }\n\trenderer  Renderer\n\tgame      MarbleGame\n\tsound_mgr SoundManager\n\tlast_tick i64\n}\n\nfn new_app() App {\n\treturn App{\n\t\tgame:      new_marble_game()")

# 3. mariobros: new_mariobros_game() -> new_mario_bros_game()
content = content.replace("new_mariobros_game()", "new_mario_bros_game()")

# 4. nuclearthrone: new_nuclearthrone_game() -> new_nuclear_throne_game()
content = content.replace("game:        new_nuclearthrone_game()", "game:        new_nuclear_throne_game()\n\t\ttex_mgr:     new_nuclear_throne_texture_manager()")

with open(PATH, 'w') as f:
    f.write(content)

print("Updated simple replacements in build_batch3_all.py")
