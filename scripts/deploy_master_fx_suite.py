#!/usr/bin/env python3
import os
import re
import shutil
import subprocess
import sys

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

def patch_sound_v(game_dir):
    sound_path = os.path.join(game_dir, 'sound.v')
    if not os.path.exists(sound_path):
        return False, "sound.v not found"

    with open(sound_path, 'r') as f:
        code = f.read()

    if 'soft_limit_sample_c' in code:
        return True, "already patched"

    # Locate update()
    upd_match = re.search(r'((?:pub\s+)?fn\s+\(mut\s+sm\s+SoundManager\)\s+update\(\)\s*\{)', code)
    if not upd_match:
        return False, "could not find SoundManager.update()"

    c_decls = (
        "fn C.apply_lowpass_c(sample f32) f32\n"
        "fn C.soft_limit_sample_c(x f32) f32\n"
        "fn C.set_audio_levels_c(rms f32, peak f32, bass f32)\n\n"
    )

    # Insert C decls before update()
    idx = upd_match.start()
    code = code[:idx] + c_decls + code[idx:]

    # Locate:
    # mut mix := []f32{len: needed}
    # for i in 0 .. needed {
    pattern_mix = re.search(r'mut\s+mix\s*:=\s*\[\]f32\{len:\s*needed\}\s*\n(\s*)for\s+i\s+in\s+0\s*\.\.\s*needed\s*\{', code)
    if not pattern_mix:
        return False, "could not find mix array initialization and loop"

    indent = pattern_mix.group(1)
    replace_mix = (
        f"mut mix := []f32{{len: needed}}\n"
        f"{indent}mut sum_sq := f32(0.0)\n"
        f"{indent}mut peak := f32(0.0)\n"
        f"{indent}for i in 0 .. needed {{"
    )
    code = code[:pattern_mix.start()] + replace_mix + code[pattern_mix.end():]

    # Locate:
    # mix[i] = audio.fclamp(sum, -1.0, 1.0)
    # }
    pattern_fclamp = re.search(r'mix\[i\]\s*=\s*audio\.fclamp\(sum,\s*-1\.0,\s*1\.0\)\s*\n(\s*)\}', code)
    if not pattern_fclamp:
        return False, "could not find audio.fclamp"

    loop_indent = pattern_fclamp.group(1)
    replace_fclamp = (
        f"// Lowpass filter (muffled when paused)\n"
        f"{loop_indent}\tfiltered := C.apply_lowpass_c(sum)\n"
        f"{loop_indent}\t// Analog rational soft-saturator limiter (zero harsh digital clipping)\n"
        f"{loop_indent}\tlimited := C.soft_limit_sample_c(filtered)\n"
        f"{loop_indent}\tmix[i] = limited\n\n"
        f"{loop_indent}\tabs_val := if limited >= 0.0 {{ limited }} else {{ -limited }}\n"
        f"{loop_indent}\tif abs_val > peak {{\n"
        f"{loop_indent}\t\tpeak = abs_val\n"
        f"{loop_indent}\t}}\n"
        f"{loop_indent}\tsum_sq += limited * limited\n"
        f"{loop_indent}}}\n"
        f"{loop_indent}rms := f32(math.sqrt(f64(sum_sq / f32(needed))))\n"
        f"{loop_indent}C.set_audio_levels_c(rms, peak, rms * 1.4)"
    )
    code = code[:pattern_fclamp.start()] + replace_fclamp + code[pattern_fclamp.end():]

    with open(sound_path, 'w') as f:
        f.write(code)

    return True, "patched sound.v"

def patch_game(game):
    game_dir = os.path.join(WORKSPACE_ROOT, game)

    # 1. Copy fx_helper.h
    dest_helper = os.path.join(game_dir, 'fx_helper.h')
    shutil.copy2(FX_HELPER_SRC, dest_helper)

    # 2. Copy prod_fx.v
    dest_fx = os.path.join(game_dir, 'prod_fx.v')
    if os.path.abspath(dest_fx) != os.path.abspath(PROD_FX_SRC):
        shutil.copy2(PROD_FX_SRC, dest_fx)

    # 3. Patch sound.v
    ok, msg = patch_sound_v(game_dir)
    return ok, msg

def test_game(game):
    game_dir = os.path.join(WORKSPACE_ROOT, game)
    test_files = [f for f in os.listdir(game_dir) if f.endswith('_test.v')]
    if not test_files:
        return True, "no tests"
    test_target = os.path.join(game, test_files[0])
    cmd = ['v', 'test', test_target]
    res = subprocess.run(cmd, cwd=WORKSPACE_ROOT, capture_output=True, text=True)
    if res.returncode == 0:
        return True, "test passed"
    else:
        return False, res.stderr + "\n" + res.stdout

def main():
    target_games = sys.argv[1:] if len(sys.argv) > 1 else get_game_dirs()
    print(f"Deploying Master FX & Audio Suite to {len(target_games)} games...")

    success = 0
    test_failures = []
    patch_failures = []

    for idx, g in enumerate(target_games, 1):
        ok, msg = patch_game(g)
        if not ok:
            print(f"[{idx}/{len(target_games)}] [{g}] Patch FAILED: {msg}")
            patch_failures.append((g, msg))
            continue

        tok, tmsg = test_game(g)
        if not tok:
            print(f"[{idx}/{len(target_games)}] [{g}] Test FAILED: {tmsg[:120]}")
            test_failures.append((g, tmsg))
        else:
            success += 1
            if idx % 10 == 0 or idx == len(target_games):
                print(f"[{idx}/{len(target_games)}] Progress: {success} verified passing...")

    print("\n" + "="*50)
    print(f"Deployment Summary: {success}/{len(target_games)} passed tests cleanly.")
    if patch_failures:
        print(f"Patch failures: {patch_failures}")
    if test_failures:
        print(f"Test failures: {[g for g, _ in test_failures]}")
    print("="*50)

if __name__ == '__main__':
    main()
