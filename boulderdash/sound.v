module main

import math
import rand
import os
import encoding.binary
import sokol.audio

const audio_sample_rate = 44100

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
	bgm_enabled   bool = true
	clips         map[string][]f32
	sfx_clips     map[string][]i16
	voices        []ActiveVoice
	bgm_active    bool
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
	sm.load_clip('bgm', 'boulderdash_bgm.wav')
	sm.load_clip('dig', 'boulderdash_dig.wav')
	sm.load_clip('diamond', 'boulderdash_diamond.wav')
	sm.load_clip('boulder', 'boulderdash_boulder.wav')
	sm.load_clip('explode', 'boulderdash_explode.wav')
	sm.load_clip('door', 'boulderdash_door.wav')
	sm.load_clip('amoeba', 'boulderdash_amoeba.wav')
	sm.load_clip('die', 'boulderdash_die.wav')
	sm.load_clip('win', 'boulderdash_win.wav')
}

pub fn (mut sm SoundManager) toggle_music() bool {
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

pub fn (mut sm SoundManager) toggle_sound() bool {
	return sm.toggle_sfx()
}

pub fn (mut sm SoundManager) update_bgm(is_active bool) {
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
}

pub fn (mut sm SoundManager) play_clip(name string) bool {
	if !sm.sound_enabled || !sm.sfx_enabled {
		return false
	}
	if clip := sm.clips[name] {
		if clip.len > 0 {
			sm.voices << ActiveVoice{
				samples: clip
				pos:     0
				volume:  0.7
				looping: false
			}
			return true
		}
	}
	return false
}

pub fn (mut sm SoundManager) play_pcm(pcm []i16) {
	if !sm.sound_enabled || !sm.sfx_enabled || pcm.len == 0 {
		return
	}
	mut s := []f32{cap: pcm.len}
	for val in pcm {
		s << f32(val) / 32768.0
	}
	sm.voices << ActiveVoice{
		samples: s
		pos:     0
		volume:  0.7
		looping: false
	}
}

pub fn (mut sm SoundManager) clear_audio() {
	sm.voices.clear()
}

pub fn (mut sm SoundManager) play_samples(samples []i16) {
	sm.play_pcm(samples)
}

pub fn (mut sm SoundManager) play_sound_raw(samples []i16) {
	sm.play_pcm(samples)
}

pub fn (mut sm SoundManager) play_raw_samples(samples []i16) {
	sm.play_pcm(samples)
}

pub fn (mut sm SoundManager) play_sfx_pcm(pcm []i16, vol ...f32) {
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
	sm.voices << ActiveVoice{
		samples: s
		pos:     0
		volume:  v
		looping: false
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

pub fn (mut sm SoundManager) play_dig_sound() {
	if 'dig' in sm.clips {
		sm.play_clip('dig')
		return
	}
	if !sm.sound_enabled || false {
		return
	}
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		env := math.exp(-40.0 * t)
		sample := noise * env * 12000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

pub fn (mut sm SoundManager) play_diamond_sound() {
	if 'diamond' in sm.clips {
		sm.play_clip('diamond')
		return
	}
	if !sm.sound_enabled || false {
		return
	}
	sample_rate := 44100
	duration_ms := 100
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := if i < num_samples / 2 { 1760.0 } else { 2349.32 }
		env := math.exp(-25.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 15000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

pub fn (mut sm SoundManager) play_impact_sound() {
	if 'boulder' in sm.clips {
		sm.play_clip('boulder')
		return
	}
	if !sm.sound_enabled || false {
		return
	}
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 120.0 - (70.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-30.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

pub fn (mut sm SoundManager) play_explosion_sound() {
	if 'explode' in sm.clips {
		sm.play_clip('explode')
		return
	}
	if !sm.sound_enabled || false {
		return
	}
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		freq := 140.0 - (100.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-8.0 * t)
		sample := (math.sin(2.0 * math.pi * freq * t) * 0.4 + noise * 0.6) * env * 22000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

pub fn (mut sm SoundManager) play_door_open_sound() {
	if 'door' in sm.clips {
		sm.play_clip('door')
		return
	}
	if !sm.sound_enabled || false {
		return
	}
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 587.33 + (400.0 * math.sin(25.0 * math.pi * t))
		env := math.exp(-6.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 16000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

pub fn (mut sm SoundManager) play_death_sound() {
	if 'die' in sm.clips {
		sm.play_clip('die')
		return
	}
	if !sm.sound_enabled || false {
		return
	}
	sample_rate := 44100
	duration_ms := 350
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0 - (320.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-6.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 17000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

pub fn (mut sm SoundManager) play_win_sound() {
	if 'win' in sm.clips {
		sm.play_clip('win')
		return
	}
	if !sm.sound_enabled || false {
		return
	}
	sample_rate := 44100
	duration_ms := 550
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	note_len := num_samples / notes.len

	for i in 0 .. num_samples {
		note_idx := i / note_len
		freq := notes[note_idx]
		t_note := f64(i % note_len) / f64(sample_rate)
		env := math.exp(-8.0 * t_note)
		sample := math.sin(2.0 * math.pi * freq * t_note) * env * 18000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}
