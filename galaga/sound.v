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
	sm.load_clip('laser', 'laser.wav')
	sm.load_clip('explosion', 'explosion.wav')
	sm.load_clip('tractor', 'ufo.wav')
	sm.load_clip('hit', 'hit.wav')
	sm.load_clip('start', 'win.wav')
	sm.load_clip('bgm', 'galaga_bgm.wav')
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

pub fn (sm &SoundManager) play_shoot_sound(is_dual bool) {
	if sm.play_clip('laser') {
		return
	}
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	duration_ms := if is_dual { 90 } else { 65 }
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq1 := 1450.0 - (950.0 * progress)
		env := math.exp(-18.0 * t)
		mut s := math.sin(2.0 * math.pi * freq1 * t)
		if is_dual {
			freq2 := 1150.0 - (750.0 * progress)
			s = (s + math.sin(2.0 * math.pi * freq2 * t)) * 0.6
		}
		pcm[i] = i16(s * env * 21000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_enemy_dive() {
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	duration_ms := 260
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		// Frequency drop with classic pitch vibrato modulation
		vib := 1.0 + 0.12 * math.sin(2.0 * math.pi * 32.0 * t)
		freq := (1600.0 - 1100.0 * progress) * vib
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - 0.7 * progress
		pcm[i] = i16(sq * env * 12000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_enemy_bullet() {
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	duration_ms := 45
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq := 900.0 - 650.0 * progress
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.2 { 1.0 } else { -1.0 }
		env := math.exp(-25.0 * t)
		pcm[i] = i16(sq * env * 11000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_kill_enemy(enemy_type EnemyType, is_diving bool) {
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	duration_ms := match enemy_type {
		.zako { 150 }
		.goei { 200 }
		.boss { if is_diving { 380 } else { 280 } }
	}
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		noise := (f64((i * 1103515245 + 12345) & 0xFFFF) / 32768.0 - 1.0)
		decay := match enemy_type {
			.zako { -16.0 }
			.goei { -12.0 }
			.boss { -7.0 }
		}
		env := math.exp(decay * progress)

		f_sweep := match enemy_type {
			.zako { 500.0 - 320.0 * progress }
			.goei { 350.0 - 240.0 * progress }
			.boss { 200.0 - 150.0 * progress }
		}
		tone := math.sin(2.0 * math.pi * f_sweep * t)
		val := (noise * 0.65 + tone * 0.35) * env * 24000.0
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, val)))
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_explosion_sound() {
	sm.play_kill_enemy(.zako, false)
}

pub fn (sm &SoundManager) play_boss_hit() {
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	duration_ms := 55
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-35.0 * t)
		ring := math.sin(2.0 * math.pi * 1850.0 * t) * 0.7 + math.sin(2.0 * math.pi * 2770.0 * t) * 0.3
		pcm[i] = i16(ring * env * 22000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_hit_sound() {
	sm.play_boss_hit()
}

pub fn (sm &SoundManager) play_tractor_beam_sound() {
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		amp := 0.6 + 0.4 * math.sin(2.0 * math.pi * 14.0 * t)
		freq := 380.0 + 80.0 * math.sin(2.0 * math.pi * 7.0 * t)
		saw := 2.0 * (t * freq - math.floor(t * freq + 0.5))
		pcm[i] = i16(saw * amp * 13000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_player_captured() {
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	duration_ms := 480
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		// Spiraling alarm steps
		step := int(progress * 12.0)
		freq := 880.0 * math.pow(0.85, f64(step))
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - 0.4 * progress
		pcm[i] = i16(sq * env * 17000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_rescue_fanfare() {
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50, 1567.98] // C5, E5, G5, C6, G6
	note_dur_ms := 75
	total_samples := (sample_rate * (note_dur_ms * notes.len)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_samples := (sample_rate * note_dur_ms) / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-8.0 * (f64(i) / f64(note_samples)))
			p1 := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
			sine := math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.3
			pcm[start_sample + i] = i16((p1 * 0.7 + sine) * env * 22000.0)
		}
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_player_death() {
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	duration_ms := 550
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		noise := (f64((i * 1103515245 + 12345) & 0xFFFF) / 32768.0 - 1.0)
		sub := math.sin(2.0 * math.pi * (180.0 * math.exp(-6.0 * t)) * t)
		env := math.exp(-4.5 * progress)
		pcm[i] = i16((noise * 0.6 + sub * 0.4) * env * 28000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_stage_start_sound() {
	if sm.play_clip('start') {
		return
	}
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	notes := [440.0, 554.37, 659.25, 880.0]
	note_dur_ms := 80
	total_samples := (sample_rate * (note_dur_ms * 3 + 160)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_dur := if n_idx == notes.len - 1 { 160 } else { note_dur_ms }
		note_samples := (sample_rate * note_dur) / 1000
		attack_samples := sample_rate * 2 / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples { break }
			t := f64(i) / f64(sample_rate)
			decay := if n_idx == notes.len - 1 { -6.0 } else { -10.0 }
			env := math.exp(decay * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
			pcm[start_sample + i] = i16(harm * env * attack * 20000.0)
		}
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_stage_clear_sound() {
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50, 1174.66, 1318.51] // C5 to E6
	note_dur_ms := 70
	total_samples := (sample_rate * (note_dur_ms * notes.len + 120)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_dur := if n_idx == notes.len - 1 { note_dur_ms + 120 } else { note_dur_ms }
		note_samples := (sample_rate * note_dur) / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-6.0 * (f64(i) / f64(note_samples)))
			p := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
			pcm[start_sample + i] = i16(p * env * 19000.0)
		}
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_game_over_sound() {
	if !sm.sound_enabled || false { return }
	sample_rate := 44100
	notes := [440.0, 415.30, 392.00, 349.23] // A4, Ab4, G4, F4
	note_dur_ms := 140
	total_samples := (sample_rate * (note_dur_ms * notes.len)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_samples := (sample_rate * note_dur_ms) / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-5.0 * (f64(i) / f64(note_samples)))
			p := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
			pcm[start_sample + i] = i16(p * env * 18000.0)
		}
	}
	sm.play_pcm(pcm)
}
