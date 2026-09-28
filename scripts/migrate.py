#!/usr/bin/env python3
import os
import re
import sys
import shutil
import subprocess

SRC_REPO = '/tmp/vlang_sdl2_games'
DST_REPO = '/Users/codecaine/vlang_games'

def get_games():
    games = [
        d for d in os.listdir(SRC_REPO)
        if os.path.isdir(os.path.join(SRC_REPO, d))
        and not d.startswith('.')
        and d not in ('screenshots', 'assets', 'icons')
    ]
    games.sort()
    return games

def migrate_game(game_name):
    print(f'=== Migrating {game_name} ===')
    src_dir = os.path.join(SRC_REPO, game_name)
    dst_dir = os.path.join(DST_REPO, game_name)
    os.makedirs(dst_dir, exist_ok=True)

    # 1. Copy game logic and test files, save.v
    for f in os.listdir(src_dir):
        src_file = os.path.join(src_dir, f)
        if os.path.isfile(src_file) and (f.endswith('_test.v') or f == 'save.v' or (
            f.endswith('.v') and f not in ('main.v', 'render.v', 'sound.v', 'font.v', 'prod_fx.v', 'take_snapshots.v')
        )):
            shutil.copy2(src_file, os.path.join(dst_dir, f))

    # 2. Prod fx
    prod_fx_code = '''module main

import gg
import math
import time

fn prod_fx_render(ctx &gg.Context) {
	ws := ctx.window_size()
	w := ws.width
	h := ws.height
	t := f64(time.ticks()) / 1000.0

	prod_fx_draw_particles(ctx, w, h, t)
	prod_fx_draw_vignette(ctx, w, h)
}

fn prod_fx_draw_particles(ctx &gg.Context, w int, h int, t f64) {
	for i in 0 .. 24 {
		fi := f64(i)
		seed := math.sin(fi * 12.9898) * 43758.5453
		frac := seed - math.floor(seed)
		speed := 0.10 + frac * 0.16
		phase := (frac + t * speed)
		py := f32((phase - math.floor(phase)) * f64(h))
		px := f32((0.5 + 0.5 * math.sin(fi * 2.31 + t * 0.18)) * f64(w))
		glow := u8(60 + int(60.0 * (0.5 + 0.5 * math.sin(t * 1.3 + fi))))
		size := f32(2 + (i % 3))
		ctx.draw_rect_filled(px - size, py - size, size * 2, size * 2, gg.Color{
			r: glow
			g: u8(int(glow) * 3 / 4 + 60)
			b: 255
			a: 90
		})
	}
}

fn prod_fx_draw_vignette(ctx &gg.Context, w int, h int) {
	for i in 0 .. 10 {
		inset := f32(i * 4)
		col := gg.Color{
			r: 0
			g: 0
			b: 0
			a: 6
		}
		ctx.draw_rect_filled(0, inset, f32(w), 3, col)
		ctx.draw_rect_filled(0, f32(h) - inset - 3, f32(w), 3, col)
		ctx.draw_rect_filled(inset, 0, 3, f32(h), col)
		ctx.draw_rect_filled(f32(w) - inset - 3, 0, 3, f32(h), col)
	}
}
'''
    with open(os.path.join(dst_dir, 'prod_fx.v'), 'w') as f:
        f.write(prod_fx_code)

    # 3. Sound manager
    src_sound = os.path.join(src_dir, 'sound.v')
    if os.path.exists(src_sound):
        sound_content = open(src_sound).read()
        
        # Extract load_clip calls in load_all_clips
        clips = re.findall(r"load_clip\(['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\)", sound_content)
        
        # Extract custom procedural sound functions
        # Functions starting after load_all_clips / cleanup
        proc_funcs = []
        for fn_match in re.finditer(r'(pub\s+fn\s+\([^\)]+\)\s+play_[a-zA-Z0-9_]+\s*\([^\)]*\)\s*\{[\s\S]*?\n\})(?=\n(?:pub\s+)?fn|\Z)', sound_content):
            fn_code = fn_match.group(1)
            # Remove sdl references inside fn_code if any
            fn_code = fn_code.replace('sm.dev == 0', 'false').replace('sm.dev != 0', 'true')
            # ensure signature takes (mut sm SoundManager) if it modifies or sm &SoundManager
            proc_funcs.append(fn_code)
            
        load_clips_code = '\n'.join([f"\tsm.load_clip('{k}', '{v}')" for k, v in clips])
        extra_proc_code = '\n\n'.join(proc_funcs)
        
        sound_v_code = f'''module main

import math
import os
import encoding.binary
import sokol.audio

struct ActiveVoice {{
mut:
	samples []f32
	pos     int
	volume  f32
	looping bool
}}

struct SoundManager {{
mut:
	sound_enabled bool = true
	clips         map[string][]f32
	voices        []ActiveVoice
	bgm_active    bool
}}

fn load_wav(path string) ?[]f32 {{
	bytes := os.read_bytes(path) or {{ return none }}
	if bytes.len < 44 {{
		return none
	}}
	if bytes[0..4].bytestr() != 'RIFF' || bytes[8..12].bytestr() != 'WAVE' {{
		return none
	}}
	mut pos := 12
	for pos + 8 <= bytes.len {{
		chunk_id := bytes[pos..pos + 4].bytestr()
		chunk_size := int(binary.little_endian_u32(bytes[pos + 4..pos + 8]))
		pos += 8
		if chunk_id == 'data' {{
			num_samples := chunk_size / 2
			mut samples := []f32{{cap: num_samples}}
			for i in 0 .. num_samples {{
				if pos + i * 2 + 2 <= bytes.len {{
					sample_i16 := i16(binary.little_endian_u16(bytes[pos + i * 2..pos + i * 2 + 2]))
					samples << f32(sample_i16) / 32768.0
				}}
			}}
			return samples
		}}
		pos += chunk_size
	}}
	return none
}}

fn new_sound_manager() SoundManager {{
	if !audio.is_valid() {{
		audio.setup(
			sample_rate:   44100
			num_channels:  1
			buffer_frames: 2048
		)
	}}

	mut sm := SoundManager{{
		sound_enabled: audio.is_valid()
	}}
	sm.load_all_clips()
	return sm
}}

fn (mut sm SoundManager) load_clip(name string, filename string) {{
	paths := [
		'assets/sounds/${{filename}}',
		'assets/music/${{filename}}',
		'../assets/sounds/${{filename}}',
		'../assets/music/${{filename}}',
	]
	for p in paths {{
		if os.exists(p) {{
			if samples := load_wav(p) {{
				sm.clips[name] = samples
				return
			}}
		}}
	}}
}}

fn (mut sm SoundManager) load_all_clips() {{
{load_clips_code}
}}

pub fn (mut sm SoundManager) toggle_sound() bool {{
	sm.sound_enabled = !sm.sound_enabled
	if !sm.sound_enabled {{
		sm.voices.clear()
	}}
	return sm.sound_enabled
}}

pub fn (mut sm SoundManager) update_bgm(is_active bool) {{
	if !sm.sound_enabled {{
		sm.bgm_active = false
		return
	}}
	if is_active && !sm.bgm_active {{
		if clip := sm.clips['bgm'] {{
			sm.bgm_active = true
			sm.voices << ActiveVoice{{
				samples: clip
				pos:     0
				volume:  0.4
				looping: true
			}}
		}}
	}}
}}

pub fn (mut sm SoundManager) play_clip(name string) bool {{
	if !sm.sound_enabled {{
		return false
	}}
	if clip := sm.clips[name] {{
		if clip.len > 0 {{
			sm.voices << ActiveVoice{{
				samples: clip
				pos:     0
				volume:  0.7
				looping: false
			}}
			return true
		}}
	}}
	return false
}}

pub fn (mut sm SoundManager) play_pcm(pcm []i16) {{
	if !sm.sound_enabled || pcm.len == 0 {{
		return
	}}
	mut s := []f32{{cap: pcm.len}}
	for val in pcm {{
		s << f32(val) / 32768.0
	}}
	sm.voices << ActiveVoice{{
		samples: s
		pos:     0
		volume:  0.7
		looping: false
	}}
}}

pub fn (mut sm SoundManager) update() {{
	if !audio.is_valid() {{
		return
	}}
	needed := audio.expect()
	if needed <= 0 {{
		return
	}}

	mut mix := []f32{{len: needed}}
	for i in 0 .. needed {{
		mut sum := f32(0.0)
		for mut v in sm.voices {{
			if v.pos < v.samples.len {{
				sum += v.samples[v.pos] * v.volume
				v.pos++
			}} else if v.looping && v.samples.len > 0 {{
				v.pos = 0
				sum += v.samples[v.pos] * v.volume
				v.pos++
			}}
		}}
		mix[i] = audio.fclamp(sum, -1.0, 1.0)
	}}
	sm.voices = sm.voices.filter(it.pos < it.samples.len || it.looping)
	unsafe {{
		audio.push(&mix[0], needed)
	}}
}}

pub fn (mut sm SoundManager) cleanup() {{
	sm.voices.clear()
}}

{extra_proc_code}
'''
        with open(os.path.join(dst_dir, 'sound.v'), 'w') as f:
            f.write(sound_v_code)

    # 4. v.mod
    v_mod_code = f'''Module {{
	name: '{game_name}'
	description: '{game_name} built with V gg and sokol'
	version: '1.0.0'
	license: 'MIT'
	dependencies: []
}}
'''
    with open(os.path.join(dst_dir, 'v.mod'), 'w') as f:
        f.write(v_mod_code)

print("Migration framework helper written")
