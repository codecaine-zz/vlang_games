#!/usr/bin/env python3
import os
import shutil
import subprocess

WORKSPACE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FX_HELPER_SRC = os.path.join(WORKSPACE_ROOT, 'fx_helper.h')
PROD_FX_SRC = os.path.join(WORKSPACE_ROOT, 'pong', 'prod_fx.v')

def get_game_dirs():
    dirs = []
    for d in sorted(os.listdir(WORKSPACE_ROOT)):
        full = os.path.join(WORKSPACE_ROOT, d)
        if os.path.isdir(full) and os.path.exists(os.path.join(full, 'main.v')):
            dirs.append(d)
    return dirs

def patch_game(game):
    game_dir = os.path.join(WORKSPACE_ROOT, game)
    
    # 1. Copy fx_helper.h
    dest_helper = os.path.join(game_dir, 'fx_helper.h')
    shutil.copy2(FX_HELPER_SRC, dest_helper)
    
    # 2. Copy prod_fx.v
    dest_fx = os.path.join(game_dir, 'prod_fx.v')
    if os.path.abspath(dest_fx) != os.path.abspath(PROD_FX_SRC):
        shutil.copy2(PROD_FX_SRC, dest_fx)
    
    # 3. Patch main.v for F10 key binding
    main_v = os.path.join(game_dir, 'main.v')
    with open(main_v, 'r') as f:
        content = f.read()
        
    modified = False
    if '.f10' not in content:
        # Search for .f11, .grave_accent pattern
        target_f11 = '.f11, .grave_accent {'
        if target_f11 in content:
            replacement = '.f11, .grave_accent {\n\t\t\t\t\tgg.toggle_fullscreen()\n\t\t\t\t}\n\t\t\t\t.f10 {\n\t\t\t\t\tprod_fx_cycle_mode()\n\t\t\t\t}'
            # Replace the entire block
            parts = content.split(target_f11, 1)
            # Find the closing bracket of f11 block
            sub = parts[1]
            end_bracket = sub.find('}')
            if end_bracket != -1:
                content = parts[0] + replacement + sub[end_bracket + 1:]
                modified = True
        elif '.f11' in content:
            # Handle single .f11
            target_single = '.f11 {'
            if target_single in content:
                replacement = '.f11, .grave_accent {\n\t\t\t\t\tgg.toggle_fullscreen()\n\t\t\t\t}\n\t\t\t\t.f10 {\n\t\t\t\t\tprod_fx_cycle_mode()\n\t\t\t\t}'
                parts = content.split(target_single, 1)
                sub = parts[1]
                end_bracket = sub.find('}')
                if end_bracket != -1:
                    content = parts[0] + replacement + sub[end_bracket + 1:]
                    modified = True

    if modified:
        with open(main_v, 'w') as f:
            f.write(content)
            
    return True

def main():
    games = get_game_dirs()
    print(f"Deploying FX suite to {len(games)} games...")
    success = 0
    for g in games:
        try:
            patch_game(g)
            success += 1
        except Exception as e:
            print(f"[{g}] Failed: {e}")
            
    print(f"Successfully deployed to {success}/{len(games)} games.")

if __name__ == '__main__':
    main()
