#!/usr/bin/env python3
"""Upgrade all 89 games for independent BGM and SFX management with background music."""
from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

BGM_MAP = {
    "blackjack": "casino_bgm.wav",
    "texas": "casino_bgm.wav",
    "slots": "slots_bgm.wav",
    "tetris": "tetris_bgm.wav",
    "vampiresurvivors": "vampiresurvivors_rondo.wav",
    "drmario": "drmario_chill.wav",
    "duke": "duke_theme.wav",
    "scorchedearth": "scorched_theme.wav",
    "bejeweled": "bejeweled_bgm.wav",
}

def get_bgm_file(game_name: str) -> str:
    return BGM_MAP.get(game_name, f"{game_name}_bgm.wav")

def patch_sound_v(game_dir: str) -> None:
    sv_path = Path(game_dir) / "sound.v"
    if not sv_path.exists():
        return
    content = sv_path.read_text()

    # 1. ActiveVoice: ensure is_bgm bool exists
    if "is_bgm bool" not in content and "is_bgm: bool" not in content:
        content = re.sub(
            r"(struct\s+ActiveVoice\s*\{[\s\S]*?looping\s+bool)",
            r"\1\n\tis_bgm  bool",
            content
        )

    # 2. SoundManager struct: add sfx_enabled and bgm_enabled if missing
    struct_match = re.search(r"((?:pub\s+)?struct\s+SoundManager\s*\{[\s\S]*?\n\})", content)
    if struct_match:
        struct_block = struct_match.group(1)
        new_struct_block = struct_block
        if "sfx_enabled" not in struct_block:
            new_struct_block = re.sub(
                r"(sound_enabled\s+bool\s*=\s*(?:true|false))",
                r"\1\n\tsfx_enabled   bool = true",
                new_struct_block,
                count=1
            )
        if "bgm_enabled" not in struct_block:
            new_struct_block = re.sub(
                r"(sfx_enabled\s+bool\s*=\s*(?:true|false))",
                r"\1\n\tbgm_enabled   bool = true",
                new_struct_block,
                count=1
            )
        if new_struct_block != struct_block:
            content = content.replace(struct_block, new_struct_block)

    # 3. Ensure BGM is loaded in load_all_clips
    bgm_file = get_bgm_file(game_dir)
    # Check if bgm is already loaded under any name
    load_all_match = re.search(r"(fn\s+\(mut\s+sm\s+SoundManager\)\s+load_all_clips\(\)\s*\{[\s\S]*?\n\})", content)
    if load_all_match:
        load_block = load_all_match.group(1)
        if "load_clip('bgm'" not in load_block and 'load_clip("bgm"' not in load_block and "load_clip('bgm_" not in load_block:
            new_load_block = re.sub(
                r"(\n\})",
                f"\n\tsm.load_clip('bgm', '{bgm_file}')\\1",
                load_block
            )
            content = content.replace(load_block, new_load_block)

    # 4. Check receiver type (& or mut)
    is_ref_receiver = bool(re.search(r'fn\s+\(sm\s+&SoundManager\)\s+toggle_sound', content))

    # 5. Add toggle_music, toggle_bgm, toggle_sfx if missing
    if "toggle_music" not in content:
        if is_ref_receiver:
            toggle_funcs = """pub fn (sm &SoundManager) toggle_music() bool {
	unsafe {
		mut msm := &SoundManager(sm)
		msm.bgm_enabled = !msm.bgm_enabled
		if !msm.bgm_enabled {
			msm.voices = msm.voices.filter(!it.is_bgm)
			msm.bgm_active = false
		} else {
			msm.update_bgm(true)
		}
		return msm.bgm_enabled
	}
}

pub fn (sm &SoundManager) toggle_bgm() bool {
	return sm.toggle_music()
}

pub fn (sm &SoundManager) toggle_sfx() bool {
	unsafe {
		mut msm := &SoundManager(sm)
		msm.sfx_enabled = !msm.sfx_enabled
		if !msm.sfx_enabled {
			msm.voices = msm.voices.filter(it.is_bgm)
		}
		return msm.sfx_enabled
	}
}
"""
        else:
            toggle_funcs = """pub fn (mut sm SoundManager) toggle_music() bool {
	sm.bgm_enabled = !sm.bgm_enabled
	if !sm.bgm_enabled {
		sm.voices = sm.voices.filter(!it.is_bgm)
		sm.bgm_active = false
	} else {
		sm.update_bgm(true)
	}
	return sm.bgm_enabled
}

pub fn (mut sm SoundManager) toggle_bgm() bool {
	return sm.toggle_music()
}

pub fn (mut sm SoundManager) toggle_sfx() bool {
	sm.sfx_enabled = !sm.sfx_enabled
	if !sm.sfx_enabled {
		sm.voices = sm.voices.filter(it.is_bgm)
	}
	return sm.sfx_enabled
}
"""
        content = re.sub(
            r"((?:pub\s+)?fn\s+\((?:mut\s+)?(?:sm\s+&?SoundManager)\)\s+toggle_sound)",
            toggle_funcs + "\n" + r"\1",
            content,
            count=1
        )

    # 6. Update toggle_sound to delegate to toggle_sfx
    if is_ref_receiver:
        content = re.sub(
            r"(pub\s+)?fn\s+\(sm\s+&SoundManager\)\s+toggle_sound\(\)\s+bool\s*\{[\s\S]*?return\s+msm\.sound_enabled\s*\n\t\}?\s*\}",
            r"pub fn (sm &SoundManager) toggle_sound() bool {\n\treturn sm.toggle_sfx()\n}",
            content
        )
    else:
        content = re.sub(
            r"(pub\s+)?fn\s+\(mut\s+sm\s+SoundManager\)\s+toggle_sound\(\)\s+bool\s*\{[\s\S]*?return\s+sm\.sound_enabled\s*\n\}",
            r"pub fn (mut sm SoundManager) toggle_sound() bool {\n\treturn sm.toggle_sfx()\n}",
            content
        )

    # 7. Update update_bgm check to honor bgm_enabled
    # Keep special cases untouched if already handled
    if game_dir not in ("puzzlefighter", "tetris", "vampiresurvivors", "drmario", "duke", "scorchedearth", "bejeweled"):
        if is_ref_receiver:
            new_ubgm = """pub fn (sm &SoundManager) update_bgm(is_active bool) {
	unsafe {
		mut msm := &SoundManager(sm)
		if !msm.sound_enabled || !msm.bgm_enabled || !is_active {
			if msm.bgm_active {
				msm.voices = msm.voices.filter(!it.is_bgm)
				msm.bgm_active = false
			}
			return
		}
		if !msm.bgm_active {
			if clip := msm.clips['bgm'] {
				if clip.len > 0 {
					msm.voices = msm.voices.filter(!it.is_bgm)
					msm.voices << ActiveVoice{
						samples: clip
						pos:     0
						volume:  0.38
						looping: true
						is_bgm:  true
					}
					msm.bgm_active = true
				}
			}
		}
	}
}"""
            content = re.sub(
                r"(pub\s+)?fn\s+\(sm\s+&SoundManager\)\s+update_bgm\s*\(is_active\s+bool\)\s*\{[\s\S]*?\n\}",
                new_ubgm,
                content
            )
        else:
            new_ubgm = """pub fn (mut sm SoundManager) update_bgm(is_active bool) {
	if !sm.sound_enabled || !sm.bgm_enabled || !is_active {
		if sm.bgm_active {
			sm.voices = sm.voices.filter(!it.is_bgm)
			sm.bgm_active = false
		}
		return
	}
	if !sm.bgm_active {
		if clip := sm.clips['bgm'] {
			if clip.len > 0 {
				sm.voices = sm.voices.filter(!it.is_bgm)
				sm.voices << ActiveVoice{
					samples: clip
					pos:     0
					volume:  0.38
					looping: true
					is_bgm:  true
				}
				sm.bgm_active = true
			}
		}
	}
}"""
            content = re.sub(
                r"(pub\s+)?fn\s+\(mut\s+sm\s+SoundManager\)\s+update_bgm\s*\(is_active\s+bool\)\s*\{[\s\S]*?\n\}",
                new_ubgm,
                content
            )
    elif game_dir in ("drmario", "duke", "scorchedearth", "bejeweled"):
        # Ensure is_bgm: true for bgm voices
        content = re.sub(r"(looping:\s*true\s*)(\n\t*\}\s*\n\t*msm\.bgm_active)", r"\1\n\t\t\t\t\t\t\tis_bgm:  true\2", content)
        content = re.sub(r"(if\s+!msm\.sound_enabled)(\s*\{)", r"\1 || !msm.bgm_enabled\2", content)

    # 8. Check sfx_enabled in play_clip, play_pcm, play_sfx_pcm
    content = re.sub(r"if\s+!sm\.sound_enabled\s*\{", "if !sm.sound_enabled || !sm.sfx_enabled {", content)
    content = re.sub(r"if\s+!sm\.sound_enabled\s*\|\|\s*pcm\.len\s*==\s*0\s*\{", "if !sm.sound_enabled || !sm.sfx_enabled || pcm.len == 0 {", content)

    # 9. Update update() method
    if "v.is_bgm && (!sm.bgm_enabled" not in content:
        # Add auto-bgm start in fn (mut sm SoundManager) update()
        if "sm.bgm_enabled && sm.sound_enabled && !sm.bgm_active" not in content:
            if game_dir == "puzzlefighter":
                auto_bgm_code = "\n\tif sm.bgm_enabled && sm.sound_enabled && !sm.bgm_active {\n\t\tsm.update_bgm(0.016, true)\n\t}"
            else:
                auto_bgm_code = "\n\tif sm.bgm_enabled && sm.sound_enabled && !sm.bgm_active {\n\t\tsm.update_bgm(true)\n\t}"
            content = re.sub(
                r"(fn\s+\(mut\s+sm\s+SoundManager\)\s+update\(\)\s*\{[\s\S]*?if\s+!audio\.is_valid\(\)\s*\{\s*return\s*\})",
                r"\1" + auto_bgm_code,
                content
            )
        # Inside the mixing loop: skip disabled voices
        content = re.sub(
            r"(for\s+mut\s+v\s+in\s+sm\.voices\s*\{)",
            r"""\1
			if v.is_bgm && (!sm.bgm_enabled || !sm.sound_enabled) {
				continue
			}
			if !v.is_bgm && (!sm.sfx_enabled || !sm.sound_enabled) {
				continue
			}""",
            content
        )

    sv_path.write_text(content)

def patch_main_v(game_dir: str) -> None:
    mv_path = Path(game_dir) / "main.v"
    if not mv_path.exists():
        return
    content = mv_path.read_text()

    # Determine sound manager reference
    if game_dir == "cyberrunner":
        mgr_ref = "app.sound"
    elif game_dir in ("bomberman", "digdug", "donkeykong", "drmario", "frogger", "galaga", "shinobi", "towerdefense", "vampiresurvivors"):
        mgr_ref = "app.game.sound_mgr"
    else:
        mgr_ref = "app.sound_mgr"

    # 1. Ensure update() is called in the frame function
    if f"{mgr_ref}.update()" not in content:
        if game_dir == "cyberrunner":
            content = re.sub(
                r"(render_frame\(mut\s+app\))",
                r"app.sound.update()\n\t\1",
                content
            )
        else:
            # Insert before prod_fx_render or draw/render call in on_frame
            content = re.sub(
                r"(\tprod_fx_render\(app\.ctx\))",
                f"\t{mgr_ref}.update()\n\\1",
                content
            )

    # 2. Keybindings in on_event / key_down
    # If .m is already bound to toggle_sound or sound toggle:
    if f"{mgr_ref}.toggle_sound()" in content:
        # Check if .m calls toggle_sound
        content = re.sub(
            rf"(\.m\s*\{{\s*){re.escape(mgr_ref)}\.toggle_sound\(\)",
            rf"\1{mgr_ref}.toggle_music()",
            content
        )

    # Ensure .m (or .b in pong/lolo) toggles music
    if game_dir == "pong":
        if ".b {" not in content:
            content = re.sub(
                r"(\.m\s*\{[\s\S]*?\n\t\t\t\t\})",
                r"""\1
				.b {
					app.sound_mgr.toggle_music()
				}""",
                content
            )
    elif game_dir == "lolo":
        if ".b {" not in content:
            content = re.sub(
                r"(\.m\s*\{[\s\S]*?\n\t\t\t\t\})",
                r"""\1
				.b {
					app.sound_mgr.toggle_music()
				}""",
                content
            )
    else:
        if ".m {" not in content and ".m," not in content and ", .m" not in content:
            # Add .m to key_down
            content = re.sub(
                r"(match\s+e\.key_code\s*\{)",
                rf"""\1
				.m {{
					{mgr_ref}.toggle_music()
				}}""",
                content
            )

    # Ensure .n toggles SFX
    if ".n {" not in content and ".n," not in content and ", .n" not in content:
        content = re.sub(
            r"(match\s+e\.key_code\s*\{)",
            rf"""\1
				.n {{
					{mgr_ref}.toggle_sfx()
				}}""",
            content
        )

    mv_path.write_text(content)

def check_game(game_dir: str) -> bool:
    res = subprocess.run(["v", "-check", game_dir], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"  ❌ {game_dir} compiler error:\n{res.stderr.strip()[:300]}")
        return False
    return True

def main() -> None:
    root = Path(__file__).resolve().parent.parent
    dirs = sorted([
        d for d in os.listdir(str(root))
        if os.path.isdir(d)
        and not d.startswith(".")
        and d not in ("assets", "engine", "scripts", "air_hockey")
        and os.path.exists(os.path.join(d, "main.v"))
    ])

    print(f"Starting audio upgrade for {len(dirs)} games...")
    successes = 0
    failures = []

    for d in dirs:
        patch_sound_v(d)
        patch_main_v(d)
        if check_game(d):
            successes += 1
            print(f"  ✓ {d}")
        else:
            failures.append(d)

    print(f"\nCompleted: {successes}/{len(dirs)} games compiled successfully!")
    if failures:
        print(f"Failed games ({len(failures)}): {failures}")

if __name__ == "__main__":
    main()
