#!/usr/bin/env python3
"""Patch a single game's sound.v and main.v for independent BGM and SFX control."""
from __future__ import annotations

import os
import re
import sys
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

def patch_sound_v(game_dir: str) -> bool:
    sv_path = Path(game_dir) / "sound.v"
    if not sv_path.exists():
        return False
    content = sv_path.read_text()

    # 1. ActiveVoice: ensure is_bgm bool exists
    if "is_bgm bool" not in content and "is_bgm: bool" not in content:
        content = re.sub(
            r"(struct\s+ActiveVoice\s*\{[\s\S]*?looping\s+bool)",
            r"\1\n\tis_bgm  bool",
            content
        )

    # 2. SoundManager struct: ensure sfx_enabled and bgm_enabled exist
    if "sfx_enabled" not in content:
        content = re.sub(
            r"((?:pub\s+)?struct\s+SoundManager\s*\{[\s\S]*?sound_enabled\s+bool\s*=\s*(?:true|false))",
            r"\1\n\tsfx_enabled   bool = true\n\tbgm_enabled   bool = true",
            content
        )
    elif "bgm_enabled" not in content:
        content = re.sub(
            r"((?:pub\s+)?struct\s+SoundManager\s*\{[\s\S]*?sfx_enabled\s+bool\s*=\s*(?:true|false))",
            r"\1\n\tbgm_enabled   bool = true",
            content
        )

    # 3. Ensure bgm is loaded in load_all_clips
    bgm_file = get_bgm_file(game_dir)
    if "load_clip('bgm'" not in content and 'load_clip("bgm"' not in content:
        # Add sm.load_clip('bgm', bgm_file) at end of load_all_clips
        content = re.sub(
            r"(fn\s+\(mut\s+sm\s+SoundManager\)\s+load_all_clips\(\)\s*\{[\s\S]*?)(\n\})",
            rf"\1\n\tsm.load_clip('bgm', '{bgm_file}')\2",
            content
        )

    # 4. Determine receiver type: & or mut
    is_ref_receiver = bool(re.search(r'fn\s+\(sm\s+&SoundManager\)\s+toggle_sound', content))

    # 5. Replace or add toggle_music, toggle_bgm, toggle_sfx, and update toggle_sound
    # Check if toggle_music already exists
    if "toggle_music" not in content:
        if is_ref_receiver:
            toggle_block = """pub fn (sm &SoundManager) toggle_music() bool {
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
            toggle_block = """pub fn (mut sm SoundManager) toggle_music() bool {
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
        # Insert before toggle_sound
        content = re.sub(
            r"((?:pub\s+)?fn\s+\((?:mut\s+)?(?:sm\s+&?SoundManager)\)\s+toggle_sound)",
            toggle_block + "\n" + r"\1",
            content,
            count=1
        )

    # 6. Update toggle_sound implementation:
    # Instead of turning off all sound, toggle_sound delegates to toggle_sfx (or toggles sfx)
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

    # 7. Update update_bgm check
    # Make sure update_bgm checks sm.bgm_enabled
    # Special handling for puzzlefighter: update_bgm(_dt f64, is_active bool)
    if "puzzlefighter" in game_dir:
        content = re.sub(
            r"pub fn \(sm &SoundManager\) update_bgm\(_dt f64, is_active bool\) \{[\s\S]*?if !sm\.sound_enabled\s*\{[\s\S]*?return\s*\}",
            """pub fn (sm &SoundManager) update_bgm(_dt f64, is_active bool) {
	unsafe {
		mut msm := &SoundManager(sm)
		if !msm.sound_enabled || !msm.bgm_enabled || !is_active {
			if msm.bgm_active {
				msm.voices = msm.voices.filter(!it.is_bgm)
				msm.bgm_active = false
			}
			return
		}
	}""",
            content
        )
    elif "tetris" in game_dir:
        # Tetris custom track update_bgm
        content = re.sub(
            r"pub fn \(sm &SoundManager\) update_bgm\(is_active bool\) \{[\s\S]*?if is_active && !sm\.bgm_active \{[\s\S]*?if clip := sm\.clips\['bgm'\] \{[\s\S]*?\}",
            """pub fn (sm &SoundManager) update_bgm(is_active bool) {
	unsafe {
		mut msm := &SoundManager(sm)
		if !msm.sound_enabled || !msm.bgm_enabled || msm.bgm_type == .off || !is_active {
			if msm.bgm_active {
				msm.voices = msm.voices.filter(!it.is_bgm)
				msm.bgm_active = false
			}
			return
		}
		if !msm.bgm_active {
			track_clip := match msm.bgm_type {
				.type_a { 'bgm_type_a' }
				.type_b { 'bgm_type_b' }
				.type_c { 'bgm_type_c' }
				.off { '' }
			}
			mut clip := msm.clips[track_clip]
			if clip.len == 0 {
				clip = msm.clips['bgm']
			}
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
	}""",
            content
        )
    elif "vampiresurvivors" in game_dir or "drmario" in game_dir or "duke" in game_dir or "bejeweled" in game_dir:
        # These games already check bgm_enabled, but let's ensure bgm voices are tagged with is_bgm: true
        content = re.sub(r"(looping:\s*true\s*\n\t*is_bgm:\s*)(?:false)", r"\1true", content)
        content = re.sub(r"(looping:\s*true\s*)(\n\t*\}\s*\n\t*msm\.bgm_active)", r"\1\n\t\t\t\t\t\t\tis_bgm:  true\2", content)
    else:
        # Standard update_bgm
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

    # 8. Ensure play_clip checks sfx_enabled
    if "!sm.sfx_enabled" not in content and "!msm.sfx_enabled" not in content:
        content = content.replace("if !sm.sound_enabled {", "if !sm.sound_enabled || !sm.sfx_enabled {")
        content = content.replace("if !sm.sound_enabled || pcm.len == 0 {", "if !sm.sound_enabled || !sm.sfx_enabled || pcm.len == 0 {")

    # 9. Update update() method to:
    #   a) auto-start BGM if enabled and not active
    #   b) skip voices that are disabled
    if "v.is_bgm && (!sm.bgm_enabled" not in content:
        # In fn (mut sm SoundManager) update():
        # Add auto-bgm right after audio.is_valid check:
        content = re.sub(
            r"(fn\s+\(mut\s+sm\s+SoundManager\)\s+update\(\)\s*\{[\s\S]*?if\s+!audio\.is_valid\(\)\s*\{\s*return\s*\})",
            r"\1\n\tif sm.bgm_enabled && sm.sound_enabled && !sm.bgm_active {\n\t\tsm.update_bgm(true)\n\t}",
            content
        )
        # Inside the mixing loop:
        # replace "for mut v in sm.voices {"
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
    return True

if __name__ == "__main__":
    game = sys.argv[1] if len(sys.argv) > 1 else "pong"
    print(f"Patching {game}...")
    patch_sound_v(game)
