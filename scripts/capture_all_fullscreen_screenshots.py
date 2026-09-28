#!/usr/bin/env python3
import os
import sys
import time
import subprocess
from PIL import Image

WORKSPACE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCREENSHOTS_DIR = os.path.join(WORKSPACE_ROOT, 'screenshots')

def get_game_dirs():
    dirs = []
    for d in sorted(os.listdir(WORKSPACE_ROOT)):
        full = os.path.join(WORKSPACE_ROOT, d)
        if os.path.isdir(full) and os.path.exists(os.path.join(full, 'main.v')):
            dirs.append(d)
    return dirs

def capture_game(game, target_path, recompile=False):
    game_dir = os.path.join(WORKSPACE_ROOT, game)
    bin_path = os.path.join(game_dir, 'game_bin')
    
    if recompile or not os.path.exists(bin_path):
        print(f"[{game}] compiling fresh game_bin...")
        res = subprocess.run(['v', '-o', f'{game}/game_bin', game], cwd=WORKSPACE_ROOT, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"[{game}] Compilation error: {res.stderr[:200]}")
            return False

    tmp_raw = f"/tmp/raw_ss_{game}.png"
    if os.path.exists(tmp_raw):
        try:
            os.remove(tmp_raw)
        except OSError:
            pass

    proc = subprocess.Popen(['./game_bin'], cwd=game_dir)
    try:
        # Give window time to initialize
        time.sleep(0.9)
        
        # Bring process to front
        subprocess.run(['osascript', '-e', f'tell application "System Events" to set frontmost of first process whose unix id is {proc.pid} to true'], capture_output=True)
        time.sleep(0.2)
        
        # Press grave accent (key code 50) to toggle fullscreen
        subprocess.run(['osascript', '-e', 'tell application "System Events" to key code 50'], capture_output=True)
        time.sleep(1.4)
        
        # Capture fullscreen
        subprocess.run(['screencapture', '-x', tmp_raw], capture_output=True)
        
        # Toggle back out of fullscreen
        subprocess.run(['osascript', '-e', 'tell application "System Events" to key code 50'], capture_output=True)
        time.sleep(0.3)
    finally:
        try:
            proc.terminate()
            proc.wait(timeout=1.5)
        except Exception:
            try:
                proc.kill()
            except Exception:
                pass

    if not os.path.exists(tmp_raw) or os.path.getsize(tmp_raw) < 1000:
        print(f"[{game}] Failed to capture raw screenshot")
        return False

    # Process and optimize image
    try:
        with Image.open(tmp_raw) as im:
            orig_w, orig_h = im.size
            target_w = 1280
            target_h = int(orig_h * (target_w / orig_w))
            resized = im.resize((target_w, target_h), Image.Resampling.LANCZOS)
            # Convert to RGB if no alpha needed or keep RGBA
            resized.save(target_path, 'PNG', optimize=True)
        
        os.remove(tmp_raw)
        file_size = os.path.getsize(target_path)
        print(f"[{game}] OK -> {target_path} ({target_w}x{target_h}, {file_size // 1024} KB)")
        return True
    except Exception as e:
        print(f"[{game}] Image processing failed: {e}")
        return False

def main():
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
    all_games = get_game_dirs()
    
    force = '--force' in sys.argv
    args = [a for a in sys.argv[1:] if a != '--force']
    target_games = args if args else all_games
    print(f"Targeting {len(target_games)} games (force={force})...")
    
    success = []
    skipped = []
    failed = []
    
    for idx, game in enumerate(target_games, 1):
        target_path = os.path.join(SCREENSHOTS_DIR, f"{game}.png")
        if not force and os.path.exists(target_path) and os.path.getsize(target_path) > 10000:
            print(f"[{idx}/{len(target_games)}] {game} already captured, skipping.")
            skipped.append(game)
            continue

        print(f"[{idx}/{len(target_games)}] Capturing {game}...")
        ok = capture_game(game, target_path, recompile=force)
        if ok:
            success.append(game)
        else:
            failed.append(game)
        time.sleep(0.2)
        
    print("\n" + "=" * 50)
    print(f"Completed: {len(success)} captured, {len(skipped)} skipped, {len(failed)} failed.")
    if failed:
        print(f"Failed games: {failed}")
    print("=" * 50)

if __name__ == '__main__':
    main()
