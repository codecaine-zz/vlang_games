#!/usr/bin/env python3
import os
import sys
import re
import shutil
import subprocess

SRC_REPO = '/tmp/vlang_sdl2_games'
DST_REPO = '/Users/codecaine/vlang_games'

def extract_balanced_block(text, start_idx):
    idx = text.find('{', start_idx)
    if idx == -1:
        return ""
    count = 1
    i = idx + 1
    while i < len(text) and count > 0:
        if text[i] == '{':
            count += 1
        elif text[i] == '}':
            count -= 1
        i += 1
    return text[start_idx:i]

def fix_init_textures(content, game_name):
    m = re.search(r'(?:pub\s+)?fn\s+\(mut\s+([a-zA-Z0-9_]+)\s+([a-zA-Z0-9_]+)\)\s+init_textures\([^\)]*\)\s*\{', content)
    if m:
        rec_var = m.group(1)
        rec_type = m.group(2)
        block = extract_balanced_block(content, m.start())
        new_init = f'''pub fn (mut {rec_var} {rec_type}) init_textures(renderer &Renderer) {{
	paths := [
		'assets/sprites/{game_name}.png',
		'./assets/sprites/{game_name}.png',
		'../assets/sprites/{game_name}.png',
		'{game_name}/assets/sprites/{game_name}.png',
	]
	for p in paths {{
		if os.exists(p) {{
			{rec_var}.sprite_texture = load_texture(renderer.ctx, p)
			if {rec_var}.sprite_texture != unsafe {{ nil }} && {rec_var}.sprite_texture.valid {{
				println('{game_name} Texture Loaded Successfully: ' + p)
				return
			}}
		}}
	}}
}}'''
        content = content[:m.start()] + new_init + content[m.start() + len(block):]
    return content

def migrate_game(game_name):
    print(f"=== Migrating: {game_name} ===")
    src_dir = os.path.join(SRC_REPO, game_name)
    dst_dir = os.path.join(DST_REPO, game_name)
    os.makedirs(dst_dir, exist_ok=True)

    # 1. Assets symlink
    dst_assets = os.path.join(dst_dir, 'assets')
    if not os.path.exists(dst_assets) and not os.path.islink(dst_assets):
        try:
            os.symlink('../assets', dst_assets)
        except Exception:
            pass

    # 2. Copy logic files, test files, save.v
    for f in os.listdir(src_dir):
        src_file = os.path.join(src_dir, f)
        if os.path.isfile(src_file):
            if f.endswith('_test.v') or f == 'save.v' or (
                f.endswith('.v') and f not in ('main.v', 'render.v', 'sound.v', 'font.v', 'prod_fx.v', 'snapshot.v', 'take_snapshots.v')
            ):
                with open(src_file, 'r', errors='ignore') as fp:
                    content = fp.read()
                content = content.replace('&sdl.Texture', '&Texture')
                content = content.replace('&sdl.Renderer', '&Renderer')
                content = content.replace('sdl.Texture', 'Texture')
                content = content.replace('sdl.Renderer', 'Renderer')
                content = re.sub(r'import\s+sdl\.image\b', '', content)
                content = re.sub(r'import\s+sdl\b', '', content)
                content = content.replace('sdl.get_ticks()', 'time.ticks()')
                if 'time.ticks()' in content and 'import time' not in content:
                    content = re.sub(r'^(module\s+[a-zA-Z0-9_]+\n)', r'\1\nimport time\n', content)
                content = re.sub(r'sound_mgr\.update_bgm\([^,]+,\s*([^)]+)\)', r'sound_mgr.update_bgm(\1)', content)
                if 'init_textures' in content:
                    content = fix_init_textures(content, game_name)
                with open(os.path.join(dst_dir, f), 'w') as fp:
                    fp.write(content)

    # 3. v.mod
    with open(os.path.join(dst_dir, 'v.mod'), 'w') as fp:
        fp.write(f'''Module {{
	name: '{game_name}'
	description: '{game_name} built with V gg and sokol'
	version: '1.0.0'
	license: 'MIT'
	dependencies: []
}}
''')

    # 4. prod_fx.v
    with open(os.path.join(dst_dir, 'prod_fx.v'), 'w') as fp:
        fp.write('''module main

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
''')

    # 5. gfx.v
    with open(os.path.join(dst_dir, 'gfx.v'), 'w') as fp:
        fp.write('''module main

import gg

pub struct Rect {
pub mut:
	x int
	y int
	w int
	h int
}

// Point definition is conditional or voidptr

pub struct Texture {
pub mut:
	img   gg.Image
	valid bool
}

pub struct Renderer {
pub mut:
	ctx        &gg.Context = unsafe { nil }
	draw_color gg.Color
	width      int
	height     int
}

pub fn (mut r Renderer) set_draw_color(red u8, green u8, blue u8, alpha u8) {
	r.draw_color = gg.Color{r: red, g: green, b: blue, a: alpha}
}

pub fn set_render_draw_color(renderer &Renderer, r u8, g u8, b u8, a u8) {
	unsafe {
		mut ren := &Renderer(renderer)
		ren.draw_color = gg.Color{r: r, g: g, b: b, a: a}
	}
}

pub fn render_clear(renderer &Renderer) {
	if renderer.ctx != unsafe { nil } {
		renderer.ctx.draw_rect_filled(0, 0, f32(renderer.width), f32(renderer.height), renderer.draw_color)
	}
}

pub fn render_present(renderer &Renderer) {}

pub fn render_fill_rect(renderer &Renderer, rect &Rect) {
	if renderer.ctx != unsafe { nil } && rect != unsafe { nil } {
		renderer.ctx.draw_rect_filled(f32(rect.x), f32(rect.y), f32(rect.w), f32(rect.h), renderer.draw_color)
	}
}

pub fn render_draw_rect(renderer &Renderer, rect &Rect) {
	if renderer.ctx != unsafe { nil } && rect != unsafe { nil } {
		renderer.ctx.draw_rect_empty(f32(rect.x), f32(rect.y), f32(rect.w), f32(rect.h), renderer.draw_color)
	}
}

pub fn render_draw_line(renderer &Renderer, x1 int, y1 int, x2 int, y2 int) {
	if renderer.ctx != unsafe { nil } {
		renderer.ctx.draw_line(f32(x1), f32(y1), f32(x2), f32(y2), renderer.draw_color)
	}
}

pub fn render_draw_point(renderer &Renderer, x int, y int) {
	if renderer.ctx != unsafe { nil } {
		renderer.ctx.draw_rect_filled(f32(x), f32(y), 1, 1, renderer.draw_color)
	}
}

pub fn render_copy(renderer &Renderer, tex &Texture, src &Rect, dst &Rect) {
	if renderer.ctx == unsafe { nil } || tex == unsafe { nil } || !tex.valid || dst == unsafe { nil } {
		return
	}
	mut cfg := gg.DrawImageConfig{
		img:      &tex.img
		img_rect: gg.Rect{
			x:      f32(dst.x)
			y:      f32(dst.y)
			width:  f32(dst.w)
			height: f32(dst.h)
		}
	}
	if src != unsafe { nil } {
		cfg.part_rect = gg.Rect{
			x:      f32(src.x)
			y:      f32(src.y)
			width:  f32(src.w)
			height: f32(src.h)
		}
	}
	renderer.ctx.draw_image_with_config(cfg)
}

pub enum BlendMode {
	none
	blend
	add
	mod
	mul
}

pub enum RendererFlip {
	none       = 0
	horizontal = 1
	vertical   = 2
}

pub fn render_copy_ex(renderer &Renderer, tex &Texture, src &Rect, dst &Rect, angle f64, center voidptr, flip RendererFlip) {
	if renderer.ctx == unsafe { nil } || tex == unsafe { nil } || !tex.valid || dst == unsafe { nil } {
		return
	}
	mut cfg := gg.DrawImageConfig{
		img:      &tex.img
		img_rect: gg.Rect{
			x:      f32(dst.x)
			y:      f32(dst.y)
			width:  f32(dst.w)
			height: f32(dst.h)
		}
		rotation: f32(angle)
	}
	if src != unsafe { nil } {
		cfg.part_rect = gg.Rect{
			x:      f32(src.x)
			y:      f32(src.y)
			width:  f32(src.w)
			height: f32(src.h)
		}
	}
	renderer.ctx.draw_image_with_config(cfg)
}

pub fn set_texture_blend_mode(tex &Texture, mode BlendMode) {}

pub fn set_render_draw_blend_mode(renderer &Renderer, mode BlendMode) {}

pub fn render_set_clip_rect(renderer &Renderer, rect &Rect) {}

pub fn load_texture(ctx &gg.Context, path string) &Texture {
	img := ctx.create_image(path) or { return &Texture{} }
	return &Texture{
		img:   img
		valid: true
	}
}

pub fn load_bmp(path string) &Texture {
	return &Texture{}
}
''')

    # 6. font.v
    src_font = os.path.join(src_dir, 'font.v')
    if os.path.exists(src_font):
        font_c = open(src_font, 'r', errors='ignore').read()
        font_c = font_c.replace('&sdl.Renderer', '&Renderer')
        font_c = font_c.replace('sdl.Renderer', 'Renderer')
        font_c = font_c.replace('sdl.set_render_draw_color', 'set_render_draw_color')
        font_c = font_c.replace('sdl.render_fill_rect', 'render_fill_rect')
        font_c = font_c.replace('sdl.render_draw_rect', 'render_draw_rect')
        font_c = font_c.replace('sdl.render_draw_line', 'render_draw_line')
        font_c = font_c.replace('sdl.render_draw_point', 'render_draw_point')
        font_c = font_c.replace('sdl.Rect', 'Rect')
        font_c = font_c.replace('sdl.Point', 'Point')
        font_c = font_c.replace('sdl.sqrt', 'math.sqrt')
        if 'math.sqrt' in font_c and 'import math' not in font_c:
            font_c = re.sub(r'^(module\s+[a-zA-Z0-9_]+\n)', r'\1import math\n', font_c)
        font_c = font_c.replace('sdl.Color', 'Color')
        font_c = re.sub(r'import\s+sdl\b', '', font_c)
        with open(os.path.join(dst_dir, 'font.v'), 'w') as fp:
            fp.write(font_c)

    # 7. sound.v
    src_sound = os.path.join(src_dir, 'sound.v')
    if os.path.exists(src_sound):
        sound_raw = open(src_sound, 'r', errors='ignore').read()
        clips = re.findall(r"load_clip\(['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\)", sound_raw)
        
        proc_funcs = []
        pos = 0
        while True:
            m = re.search(r'(?:pub\s+)?fn\s+\((?:mut\s+)?sm\s+(?:&)?SoundManager\)\s+([a-zA-Z0-9_]+)\s*(\([^\)]*\)[^\{]*\{)', sound_raw[pos:])
            if not m:
                break
            fn_start = pos + m.start()
            fn_name = m.group(1)
            block = extract_balanced_block(sound_raw, fn_start)
            pos = fn_start + len(block)
            
            if fn_name in ('init', 'toggle_sound', 'update_bgm', 'load_clip', 'play_clip', 'cleanup', 'load_all_clips', 'clear_audio', 'play_samples', 'play_sound_raw', 'play_raw_samples', 'play_sfx_pcm', 'play_pcm', 'update', 'update_audio', 'update_audio_stream', 'update_bgm_stream', 'update_mixer', 'set_bgm', 'cycle_bgm'):
                continue
            
            block = re.sub(r'(?:pub\s+)?fn\s+\((?:mut\s+)?sm\s+(?:&)?SoundManager\)', 'pub fn (sm &SoundManager)', block)
            block = block.replace('mutable_sm.dev == 0', 'false').replace('mutable_sm.dev != 0', 'true')
            block = block.replace('mutable_sm.dev_id == 0', 'false').replace('mutable_sm.dev_id != 0', 'true')
            block = block.replace('sm.dev == 0', 'false').replace('sm.dev != 0', 'true')
            block = block.replace('sm.dev_id == 0', 'false').replace('sm.dev_id != 0', 'true')
            block = block.replace('!sm.sound_enabled || sm.dev == 0', '!sm.sound_enabled')
            block = block.replace('sm.sound_enabled && sm.dev != 0', 'sm.sound_enabled')
            block = block.replace('!sm.enabled || sm.dev_id == 0', '!sm.sound_enabled')
            block = block.replace('sm.enabled && sm.dev_id != 0', 'sm.sound_enabled')
            while 'sdl.queue_audio' in block:
                idx = block.find('sdl.queue_audio')
                open_paren = block.find('(', idx)
                if open_paren == -1:
                    break
                cnt = 1
                j = open_paren + 1
                while j < len(block) and cnt > 0:
                    if block[j] == '(':
                        cnt += 1
                    elif block[j] == ')':
                        cnt -= 1
                    j += 1
                call_text = block[idx:j]
                if 'clip' in call_text:
                    block = block[:idx] + 'sm.play_clip(name)' + block[j:]
                else:
                    block = block[:idx] + 'sm.play_pcm(pcm)' + block[j:]
            block = block.replace('&& !isnil(clip.buf)', '')
            block = block.replace('!isnil(clip.buf)', 'true')
            block = block.replace('sdl.clear_queued_audio(sm.dev)', 'sm.voices.clear()')
            block = block.replace('sdl.clear_queued_audio(sm.dev_id)', 'sm.voices.clear()')
            proc_funcs.append(block)

        # Also extract standalone functions (e.g. fn gen_*() []i16)
        pos = 0
        while True:
            m = re.search(r'(?:pub\s+)?fn\s+([a-zA-Z0-9_]+)\s*(\([^\)]*\)[^\{]*\{)', sound_raw[pos:])
            if not m:
                break
            fn_start = pos + m.start()
            fn_name = m.group(1)
            block = extract_balanced_block(sound_raw, fn_start)
            pos = fn_start + len(block)
            if fn_name in ('init', 'toggle_sound', 'update_bgm', 'load_clip', 'play_clip', 'cleanup', 'load_all_clips', 'clear_audio', 'play_samples', 'play_sound_raw', 'play_raw_samples', 'play_sfx_pcm', 'play_pcm', 'update', 'update_audio', 'update_audio_stream', 'update_bgm_stream', 'update_mixer', 'set_bgm', 'cycle_bgm', 'new_sound_manager', 'init_sound', 'main'):
                continue
            sig_sub = sound_raw[fn_start:fn_start + 50]
            if 'SoundManager' in sig_sub or 'sm ' in sig_sub:
                continue
            proc_funcs.append(block)

        load_clips_code = '\n'.join([f"\tsm.load_clip('{k}', '{v}')" for k, v in clips])
        extra_proc_code = '\n\n'.join(proc_funcs)

        sound_v_code = f'''module main

import math
import rand
import os
import encoding.binary
import sokol.audio

const audio_sample_rate = 44100

pub enum BgmType {{
	fever
	chill
	off
}}

pub fn (sm &SoundManager) set_bgm(bgm_type BgmType) {{
	unsafe {{
		mut msm := &SoundManager(sm)
		msm.bgm_type = bgm_type
	}}
}}

pub fn (sm &SoundManager) cycle_bgm() BgmType {{
	unsafe {{
		mut msm := &SoundManager(sm)
		msm.bgm_type = match msm.bgm_type {{
			.fever {{ BgmType.chill }}
			.chill {{ BgmType.off }}
			.off {{ BgmType.fever }}
		}}
		return msm.bgm_type
	}}
}}


struct ActiveVoice {{
mut:
	samples []f32
	pos     int
	volume  f32
	looping bool
}}

pub struct SoundManager {{
pub mut:
	sound_enabled bool = true
	enabled       bool = true
	bgm_type      BgmType = .off
	clips         map[string][]f32
	sfx_clips     map[string][]i16
	voices        []ActiveVoice
	bgm_active    bool
	bgm_enabled   bool = true
	roll_timer    f32
	waka_phase    bool
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

pub fn new_sound_manager() SoundManager {{
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

pub fn (mut sm SoundManager) init() {{
	sm.load_all_clips()
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
				mut i16_samples := []i16{{cap: samples.len}}
				for s in samples {{
					i16_samples << i16(s * 32767.0)
				}}
				sm.sfx_clips[name] = i16_samples
				return
			}}
		}}
	}}
}}

fn (mut sm SoundManager) load_all_clips() {{
{load_clips_code}
}}

pub fn (sm &SoundManager) toggle_sound() bool {{
	unsafe {{
		mut msm := &SoundManager(sm)
		msm.sound_enabled = !msm.sound_enabled
		if !msm.sound_enabled {{
			msm.voices.clear()
		}}
		return msm.sound_enabled
	}}
}}

pub fn (sm &SoundManager) update_bgm(is_active bool) {{
	if !sm.sound_enabled {{
		unsafe {{
			mut msm := &SoundManager(sm)
			msm.bgm_active = false
		}}
		return
	}}
	if is_active && !sm.bgm_active {{
		if clip := sm.clips['bgm'] {{
			unsafe {{
				mut msm := &SoundManager(sm)
				msm.bgm_active = true
				msm.voices << ActiveVoice{{
					samples: clip
					pos:     0
					volume:  0.4
					looping: true
				}}
			}}
		}}
	}}
}}

pub fn (sm &SoundManager) play_clip(name string) bool {{
	if !sm.sound_enabled {{
		return false
	}}
	if clip := sm.clips[name] {{
		if clip.len > 0 {{
			unsafe {{
				mut msm := &SoundManager(sm)
				msm.voices << ActiveVoice{{
					samples: clip
					pos:     0
					volume:  0.7
					looping: false
				}}
			}}
			return true
		}}
	}}
	return false
}}

pub fn (sm &SoundManager) play_pcm(pcm []i16) {{
	if !sm.sound_enabled || pcm.len == 0 {{
		return
	}}
	mut s := []f32{{cap: pcm.len}}
	for val in pcm {{
		s << f32(val) / 32768.0
	}}
	unsafe {{
		mut msm := &SoundManager(sm)
		msm.voices << ActiveVoice{{
			samples: s
			pos:     0
			volume:  0.7
			looping: false
		}}
	}}
}}

pub fn (sm &SoundManager) clear_audio() {{
	unsafe {{
		mut msm := &SoundManager(sm)
		msm.voices.clear()
	}}
}}

pub fn (sm &SoundManager) play_samples(samples []i16) {{
	sm.play_pcm(samples)
}}

pub fn (sm &SoundManager) play_sound_raw(samples []i16) {{
	sm.play_pcm(samples)
}}

pub fn (sm &SoundManager) play_raw_samples(samples []i16) {{
	sm.play_pcm(samples)
}}

pub fn (sm &SoundManager) play_sfx_pcm(pcm []i16, vol ...f32) {{
	if !sm.sound_enabled || pcm.len == 0 {{
		return
	}}
	mut v := f32(0.7)
	if vol.len > 0 {{
		v = vol[0]
	}}
	mut s := []f32{{cap: pcm.len}}
	for val in pcm {{
		s << f32(val) / 32768.0
	}}
	unsafe {{
		mut msm := &SoundManager(sm)
		msm.voices << ActiveVoice{{
			samples: s
			pos:     0
			volume:  v
			looping: false
		}}
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
        with open(os.path.join(dst_dir, 'sound.v'), 'w') as fp:
            fp.write(sound_v_code)

    # 8. render.v
    src_render = os.path.join(src_dir, 'render.v')
    if os.path.exists(src_render):
        r_content = open(src_render, 'r', errors='ignore').read()
        r_content = r_content.replace('&sdl.Renderer', '&Renderer')
        r_content = r_content.replace('sdl.Renderer', 'Renderer')
        r_content = r_content.replace('&sdl.Texture', '&Texture')
        r_content = r_content.replace('sdl.Texture', 'Texture')
        r_content = r_content.replace('sdl.Rect', 'Rect')
        r_content = r_content.replace('sdl.Point', 'Point')
        r_content = r_content.replace('sdl.Color', 'Color')
        r_content = r_content.replace('sdl.RendererFlip', 'RendererFlip')
        
        for tm_var in ('tm', 'tex_mgr'):
            m = re.search(r'pub\s+fn\s+\(mut\s+' + tm_var + r'\s+([a-zA-Z0-9_]+)\)\s+init\([^\)]*\)\s*\{', r_content)
            if m:
                tm_type = m.group(1)
                block = extract_balanced_block(r_content, m.start())
                new_init = f'''pub fn (mut {tm_var} {tm_type}) init(renderer &Renderer) {{
	candidates := [
		'assets/sprites/{game_name}.png',
		'./assets/sprites/{game_name}.png',
		'../assets/sprites/{game_name}.png',
		'{game_name}/assets/sprites/{game_name}.png',
	]
	for p in candidates {{
		if os.exists(p) {{
			{tm_var}.sprite_texture = load_texture(renderer.ctx, p)
			if {tm_var}.sprite_texture != unsafe {{ nil }} && {tm_var}.sprite_texture.valid {{
				println('{game_name} Texture Loaded Successfully: ' + p)
				return
			}}
		}}
	}}
}}'''
                r_content = r_content[:m.start()] + new_init + r_content[m.start() + len(block):]

        r_content = r_content.replace('sdl.set_render_draw_color', 'set_render_draw_color')
        r_content = r_content.replace('sdl.render_clear', 'render_clear')
        r_content = r_content.replace('sdl.render_present', 'render_present')
        r_content = r_content.replace('sdl.render_fill_rect', 'render_fill_rect')
        r_content = r_content.replace('sdl.render_draw_rect', 'render_draw_rect')
        r_content = r_content.replace('sdl.render_draw_line', 'render_draw_line')
        r_content = r_content.replace('sdl.render_draw_point', 'render_draw_point')
        r_content = r_content.replace('sdl.render_copy_ex', 'render_copy_ex')
        r_content = r_content.replace('sdl.render_copy', 'render_copy')
        r_content = r_content.replace('sdl.set_texture_blend_mode', 'set_texture_blend_mode')
        r_content = r_content.replace('sdl.set_render_draw_blend_mode', 'set_render_draw_blend_mode')
        r_content = r_content.replace('sdl.render_set_clip_rect', 'render_set_clip_rect')
        r_content = r_content.replace('sdl.load_bmp', 'load_bmp')
        r_content = r_content.replace('sdl.get_ticks()', 'u32(time.ticks())')
        r_content = r_content.replace('prod_fx_render(renderer)', 'if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }')
        r_content = r_content.replace('prod_fx_render(app.renderer)', 'prod_fx_render(app.ctx)')
        r_content = r_content.replace('sdl.BlendMode.blend', '.blend')
        r_content = r_content.replace('sdl.BlendMode.none', '.none')
        r_content = r_content.replace('sdl.BlendMode.add', '.add')
        r_content = r_content.replace('sdl.BlendMode.mod', '.mod')
        r_content = r_content.replace('sdl.BlendMode.mul', '.mul')
        r_content = r_content.replace('BlendMode.blend', '.blend')
        r_content = re.sub(r'import\s+sdl\.image\b[^\n]*\n?', '', r_content)
        r_content = re.sub(r'import\s+sdl\b[^\n]*\n?', '', r_content)
        r_content = r_content.replace('_ = image.init(int(image.InitFlags.png))', '')
        r_content = re.sub(r'import\s+time\s*\n?', '', r_content)
        
        m_mod = re.search(r'module\s+([a-zA-Z0-9_]+)', r_content)
        if m_mod:
            mod_line = f"module {m_mod.group(1)}\n"
            r_content = re.sub(r'module\s+[a-zA-Z0-9_]+[^\n]*\n?', '', r_content).lstrip()
            if 'time.ticks()' in r_content:
                r_content = mod_line + "\nimport time\n\n" + r_content
            else:
                r_content = mod_line + "\n" + r_content
        with open(os.path.join(dst_dir, 'render.v'), 'w') as fp:
            fp.write(r_content)

    print(f"Base migration done for {game_name}")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        migrate_game(sys.argv[1])
