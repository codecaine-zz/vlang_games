module main

import math
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

	sm.load_clip('bgm', 'game2048_bgm.wav')
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

pub fn (sm &SoundManager) play_slide_sound() {
	if !sm.sound_enabled || false {
		return
	}
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 450.0 - (280.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-40.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.2 * math.sin(4.0 * math.pi * freq * t)
		val := harm * env * attack * 12000.0
		pcm[i] = i16(val)
	}

	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_merge_sound(val int) {
	if !sm.sound_enabled || false {
		return
	}
	sample_rate := 44100
	duration_ms := 130
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	// Pentatonic scale based on tile power of 2
	mut power := 0
	mut temp := val
	for temp > 2 {
		temp /= 2
		power++
	}

	scale_notes := [
		261.63, // 4: C4
		293.66, // 8: D4
		329.63, // 16: E4
		392.00, // 32: G4
		440.00, // 64: A4
		523.25, // 128: C5
		587.33, // 256: D5
		659.25, // 512: E5
		783.99, // 1024: G5
		1046.50, // 2048: C6
		1174.66, // 4096: D6
		1318.51, // 8192: E6
	]
	idx := if power < scale_notes.len { power } else { scale_notes.len - 1 }
	freq := scale_notes[idx]

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-18.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t) + 0.15 * math.sin(6.0 * math.pi * freq * t)
		val_f := harm * env * attack * 18000.0
		pcm[i] = i16(val_f)
	}

	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_win_sound() {
	if !sm.sound_enabled || false {
		return
	}
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51] // C5, E5, G5, C6, E6
	note_dur_ms := 80
	total_samples := (sample_rate * (note_dur_ms * 4 + 200)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_dur := if n_idx == notes.len - 1 { 200 } else { note_dur_ms }
		note_samples := (sample_rate * note_dur) / 1000
		attack_samples := sample_rate * 2 / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			decay := if n_idx == notes.len - 1 { -6.0 } else { -10.0 }
			env := math.exp(decay * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
			val := harm * env * attack * 22000.0
			pcm[start_sample + i] = i16(val)
		}
	}

	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_game_over_sound() {
	if !sm.sound_enabled || false {
		return
	}
	sample_rate := 44100
	notes := [330.0, 311.13, 293.66, 261.63]
	note_dur_ms := 90
	total_samples := (sample_rate * note_dur_ms * notes.len) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_samples := (sample_rate * note_dur_ms) / 1000
		attack_samples := sample_rate * 2 / 1000
		for i in 0 .. note_samples {
			t := f64(i) / f64(sample_rate)
			env := math.exp(-8.0 * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			val := math.sin(2.0 * math.pi * freq * t) * env * attack * 16000.0
			pcm[start_sample + i] = i16(val)
		}
	}

	sm.play_pcm(pcm)
}
