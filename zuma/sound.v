module main

import math
import os
import encoding.binary
import sokol.audio

const audio_sample_rate = 44100

pub enum BgmType {
	fever
	chill
	off
}

pub fn (sm &SoundManager) set_bgm(bgm_type BgmType) {
	unsafe {
		mut msm := &SoundManager(sm)
		msm.bgm_type = bgm_type
	}
}

pub fn (sm &SoundManager) cycle_bgm() BgmType {
	unsafe {
		mut msm := &SoundManager(sm)
		msm.bgm_type = match msm.bgm_type {
			.fever { BgmType.chill }
			.chill { BgmType.off }
			.off { BgmType.fever }
		}
		return msm.bgm_type
	}
}


struct ActiveVoice {
mut:
	samples []f32
	pos     int
	volume  f32
	looping bool
	is_bgm  bool
}

pub struct SoundManager {
pub mut:
	sound_enabled bool = true
	sfx_enabled   bool = true
	enabled       bool = true
	bgm_type      BgmType = .off
	clips         map[string][]f32
	sfx_clips     map[string][]i16
	voices        []ActiveVoice
	bgm_active    bool
	bgm_enabled   bool = true
	roll_timer    f32
	waka_phase    bool
}

fn load_wav(path string) ?[]f32 {
	bytes := os.read_bytes(path) or { return none }
	if bytes.len < 44 {
		return none
	}
	if bytes[0..4].bytestr() != 'RIFF' || bytes[8..12].bytestr() != 'WAVE' {
		return none
	}
	mut pos := 12
	for pos + 8 <= bytes.len {
		chunk_id := bytes[pos..pos + 4].bytestr()
		chunk_size := int(binary.little_endian_u32(bytes[pos + 4..pos + 8]))
		pos += 8
		if chunk_id == 'data' {
			num_samples := chunk_size / 2
			mut samples := []f32{cap: num_samples}
			for i in 0 .. num_samples {
				if pos + i * 2 + 2 <= bytes.len {
					sample_i16 := i16(binary.little_endian_u16(bytes[pos + i * 2..pos + i * 2 + 2]))
					samples << f32(sample_i16) / 32768.0
				}
			}
			return samples
		}
		pos += chunk_size
	}
	return none
}

pub fn new_sound_manager() SoundManager {
	if !audio.is_valid() {
		audio.setup(
			sample_rate:   audio_sample_rate
			num_channels:  1
			buffer_frames: 2048
		)
	}

	mut sm := SoundManager{
		sound_enabled: audio.is_valid()
	}
	sm.load_all_clips()
	return sm
}

pub fn (mut sm SoundManager) init() {
	sm.load_all_clips()
}

fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/sounds/${filename}',
		'assets/music/${filename}',
		'../assets/sounds/${filename}',
		'../assets/music/${filename}',
	]
	for p in paths {
		if os.exists(p) {
			if samples := load_wav(p) {
				sm.clips[name] = samples
				mut i16_samples := []i16{cap: samples.len}
				for s in samples {
					i16_samples << i16(s * 32767.0)
				}
				sm.sfx_clips[name] = i16_samples
				return
			}
		}
	}
}

fn (mut sm SoundManager) load_all_clips() {
	sm.load_clip('bgm', 'zuma_bgm.wav')
	sm.load_clip('shoot', 'zuma_fire.wav')
	sm.load_clip('match', 'zuma_match.wav')
	sm.load_clip('combo', 'zuma_combo.wav')
	sm.load_clip('bomb', 'zuma_bomb.wav')
	sm.load_clip('slow', 'zuma_slow.wav')
	sm.load_clip('reverse', 'zuma_reverse.wav')
	sm.load_clip('skull', 'zuma_skull.wav')
	sm.load_clip('win', 'zuma_win.wav')
}

pub fn (sm &SoundManager) toggle_music() bool {
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

pub fn (sm &SoundManager) toggle_sound() bool {
	return sm.toggle_sfx()
}

pub fn (sm &SoundManager) update_bgm(is_active bool) {
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
}

pub fn (sm &SoundManager) play_clip(name string) bool {
	if !sm.sound_enabled || !sm.sfx_enabled {
		return false
	}
	if clip := sm.clips[name] {
		if clip.len > 0 {
			unsafe {
				mut msm := &SoundManager(sm)
				msm.voices << ActiveVoice{
					samples: clip
					pos:     0
					volume:  0.7
					looping: false
				}
			}
			return true
		}
	}
	return false
}

pub fn (sm &SoundManager) play_pcm(pcm []i16) {
	if !sm.sound_enabled || !sm.sfx_enabled || pcm.len == 0 {
		return
	}
	mut s := []f32{cap: pcm.len}
	for val in pcm {
		s << f32(val) / 32768.0
	}
	unsafe {
		mut msm := &SoundManager(sm)
		msm.voices << ActiveVoice{
			samples: s
			pos:     0
			volume:  0.7
			looping: false
		}
	}
}

pub fn (sm &SoundManager) clear_audio() {
	unsafe {
		mut msm := &SoundManager(sm)
		msm.voices.clear()
	}
}

pub fn (sm &SoundManager) play_samples(samples []i16) {
	sm.play_pcm(samples)
}

pub fn (sm &SoundManager) play_sound_raw(samples []i16) {
	sm.play_pcm(samples)
}

pub fn (sm &SoundManager) play_raw_samples(samples []i16) {
	sm.play_pcm(samples)
}

pub fn (sm &SoundManager) play_sfx_pcm(pcm []i16, vol ...f32) {
	if !sm.sound_enabled || !sm.sfx_enabled || pcm.len == 0 {
		return
	}
	mut v := f32(0.7)
	if vol.len > 0 {
		v = vol[0]
	}
	mut s := []f32{cap: pcm.len}
	for val in pcm {
		s << f32(val) / 32768.0
	}
	unsafe {
		mut msm := &SoundManager(sm)
		msm.voices << ActiveVoice{
			samples: s
			pos:     0
			volume:  v
			looping: false
		}
	}
}

fn C.apply_lowpass_c(sample f32) f32
fn C.soft_limit_sample_c(x f32) f32
fn C.set_audio_levels_c(rms f32, peak f32, bass f32)

pub fn (mut sm SoundManager) update() {
	if !audio.is_valid() {
		return
	}
	if sm.bgm_enabled && sm.sound_enabled && !sm.bgm_active {
		sm.update_bgm(true)
	}
	needed := audio.expect()
	if needed <= 0 {
		return
	}

	mut mix := []f32{len: needed}
	mut sum_sq := f32(0.0)
	mut peak := f32(0.0)
	for i in 0 .. needed {
		mut sum := f32(0.0)
		for mut v in sm.voices {
			if v.is_bgm && (!sm.bgm_enabled || !sm.sound_enabled) {
				continue
			}
			if !v.is_bgm && (!sm.sfx_enabled || !sm.sound_enabled) {
				continue
			}
			if v.pos < v.samples.len {
				sum += v.samples[v.pos] * v.volume
				v.pos++
			} else if v.looping && v.samples.len > 0 {
				v.pos = 0
				sum += v.samples[v.pos] * v.volume
				v.pos++
			}
		}
		// Lowpass filter (muffled when paused)
		filtered := C.apply_lowpass_c(sum)
		// Analog rational soft-saturator limiter (zero harsh digital clipping)
		limited := C.soft_limit_sample_c(filtered)
		mix[i] = limited

		abs_val := if limited >= 0.0 { limited } else { -limited }
		if abs_val > peak {
			peak = abs_val
		}
		sum_sq += limited * limited
	}
	rms := f32(math.sqrt(f64(sum_sq / f32(needed))))
	C.set_audio_levels_c(rms, peak, rms * 1.4)
	sm.voices = sm.voices.filter(it.pos < it.samples.len || it.looping)
	unsafe {
		audio.push(&mix[0], needed)
	}
}

pub fn (mut sm SoundManager) cleanup() {
	sm.voices.clear()
}

pub fn (sm &SoundManager) play_shoot_sound() {
	if 'shoot' in sm.clips {
		sm.play_clip('shoot')
		return
	}
	sample_rate := 44100
	duration_ms := 55
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 680.0 - t * 6500.0
		if freq < 80.0 {
			continue
		}
		env := math.exp(-t * 30.0)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 17000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_insert_sound() {
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 420.0 + (1.0 - t * 25.0) * 200.0
		env := math.exp(-t * 40.0)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 15000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_swap_sound() {
	sm.play_insert_sound()
}

pub fn (sm &SoundManager) play_match_sound(combo int) {
	if combo > 1 && 'combo' in sm.clips {
		sm.play_clip('combo')
		return
	} else if 'match' in sm.clips {
		sm.play_clip('match')
		return
	}

	sample_rate := 44100
	duration_ms := 180 + combo * 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	base_freq := 440.0 * math.pow(1.1892, f64(combo - 1))

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-t * 10.0)
		s1 := math.sin(2.0 * math.pi * base_freq * t)
		s2 := math.sin(2.0 * math.pi * base_freq * 1.5 * t) * 0.6
		sample := (s1 + s2) * env * 15000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_powerup_sound(pt PowerupType) {
	match pt {
		.bomb {
			if 'bomb' in sm.clips {
				sm.play_clip('bomb')
				return
			}
		}
		.slow {
			if 'slow' in sm.clips {
				sm.play_clip('slow')
				return
			}
		}
		.reverse {
			if 'reverse' in sm.clips {
				sm.play_clip('reverse')
				return
			}
		}
		else {}
	}
}

pub fn (sm &SoundManager) play_skull_sound() {
	if 'skull' in sm.clips {
		sm.play_clip('skull')
		return
	}
	sample_rate := 44100
	duration_ms := 550
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 180.0 - t * 240.0
		if freq < 30.0 {
			continue
		}
		env := math.exp(-t * 4.0)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}
