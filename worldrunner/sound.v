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
	cur_world     int = 1
	sample_pos    f64
	sfx_buffer    []i16
	sfx_read_pos  int
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

	sm.load_clip('bgm', 'worldrunner_bgm.wav')
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
	unsafe {
		mut msm := &SoundManager(sm)
		msm.sound_enabled = !msm.sound_enabled
		msm.sfx_enabled = msm.sound_enabled
		msm.enabled = msm.sound_enabled
		if !msm.sound_enabled {
			msm.voices.clear()
			msm.bgm_active = false
		}
		return msm.sound_enabled
	}
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

pub fn (sm &SoundManager) set_world(w int) {
	unsafe {
		mut msm := &SoundManager(sm)
		msm.cur_world = w
		msm.sample_pos = 0.0
	}
}

pub fn (sm &SoundManager) play_sfx(samples []i16) {
	if !sm.sound_enabled || !sm.sfx_enabled { return }
	sm.play_sfx_pcm(samples)
}

pub fn (sm &SoundManager) synthesize_title_bgm(t f64, _total_sample int) f64 {
	step_time := 0.123
	step := int(t / step_time) % 32

	lead_notes := [
		329.63, 392.00, 493.88, 587.33, 659.25, 587.33, 493.88, 392.00, // Em
		261.63, 329.63, 392.00, 523.25, 587.33, 523.25, 392.00, 329.63, // C
		293.66, 369.99, 440.00, 587.33, 659.25, 587.33, 440.00, 369.99, // D
		246.94, 311.13, 369.99, 493.88, 587.33, 493.88, 369.99, 311.13  // B
	]
	bass_notes := [82.41, 65.41, 73.42, 61.74]

	freq := lead_notes[step]
	bass_freq := bass_notes[step / 8]

	local_t := math.fmod(t, step_time)
	env := math.pow(1.0 - (local_t / step_time), 1.5)

	lead := (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env
	bass := math.sin(2.0 * math.pi * bass_freq * t) * 0.8
	return (lead * 12000.0 + bass * 14000.0)
}

pub fn (sm &SoundManager) synthesize_world_bgm(world_num int, is_boss bool, t f64, total_sample int) f64 {
	match world_num {
		1 {
			// World 1: Solar Plains - Upbeat Driving Synthwave (135 BPM, D Minor)
			step_time := 0.111
			step := int(t / step_time) % 32
			lead_notes := [
				293.66, 349.23, 440.00, 523.25, 587.33, 523.25, 440.00, 349.23, // Dm
				261.63, 329.63, 392.00, 523.25, 659.25, 523.25, 392.00, 329.63, // C
				233.08, 293.66, 349.23, 466.16, 587.33, 466.16, 349.23, 293.66, // Bb
				220.00, 277.18, 329.63, 440.00, 554.37, 440.00, 329.63, 277.18  // A
			]
			bass_notes := [73.42, 65.41, 58.27, 55.00] // D1, C1, Bb0, A0
			freq := if is_boss { lead_notes[step] * 1.5 } else { lead_notes[step] }
			bass_freq := bass_notes[step / 8]

			local_t := math.fmod(t, step_time)
			env := math.pow(1.0 - (local_t / step_time), 1.3)
			noise := if step % 2 == 1 { (f64((total_sample * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * env * 0.25 } else { 0.0 }

			lead := math.sin(2.0 * math.pi * freq * t) * env
			bass := (math.sin(2.0 * math.pi * bass_freq * t) + 0.3 * math.sin(4.0 * math.pi * bass_freq * t)) * 0.9
			return (lead * 11000.0 + bass * 13000.0 + noise * 10000.0)
		}
		2 {
			// World 2: Crystal Caverns - Mystical Prismatic Cosmic Arpeggios (128 BPM, A Minor)
			step_time := 0.117
			step := int(t / step_time) % 32
			lead_notes := [
				440.00, 523.25, 659.25, 880.00, 1046.50, 880.00, 659.25, 523.25, // Am
				349.23, 440.00, 523.25, 698.46, 880.00, 698.46, 523.25, 440.00,  // F
				392.00, 493.88, 587.33, 783.99, 987.77, 783.99, 587.33, 493.88,  // G
				329.63, 415.30, 493.88, 659.25, 830.61, 659.25, 493.88, 415.30  // E7
			]
			bass_notes := [55.00, 43.65, 49.00, 41.20]
			freq := lead_notes[step]
			bass_freq := bass_notes[step / 8]

			local_t := math.fmod(t, step_time)
			env := math.pow(1.0 - (local_t / step_time), 2.0)
			lead := (math.sin(2.0 * math.pi * freq * t) + 0.4 * math.sin(6.0 * math.pi * freq * t)) * env
			bass := math.sin(2.0 * math.pi * bass_freq * t) * 0.85
			return (lead * 12000.0 + bass * 14000.0)
		}
		3 {
			// World 3: Magma Wasteland - Heavy Industrial Driving Cyber Riffs (142 BPM, E Minor)
			step_time := 0.105
			step := int(t / step_time) % 32
			lead_notes := [
				164.81, 196.00, 220.00, 246.94, 329.63, 246.94, 220.00, 196.00, // Em
				174.61, 207.65, 233.08, 261.63, 349.23, 261.63, 233.08, 207.65, // F
				146.83, 174.61, 196.00, 220.00, 293.66, 220.00, 196.00, 174.61, // D
				130.81, 164.81, 196.00, 246.94, 261.63, 246.94, 196.00, 164.81  // C
			]
			bass_notes := [41.20, 43.65, 36.71, 32.70]
			freq := lead_notes[step]
			bass_freq := bass_notes[step / 8]

			local_t := math.fmod(t, step_time)
			env := math.pow(1.0 - (local_t / step_time), 1.1)
			noise := if step % 2 == 0 { (f64((total_sample * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * env * 0.35 } else { 0.0 }

			lead := (math.sin(2.0 * math.pi * freq * t) + 0.5 * math.sin(3.0 * math.pi * freq * t)) * env
			bass := (math.sin(2.0 * math.pi * bass_freq * t) + 0.4 * math.sin(2.0 * math.pi * (bass_freq * 1.5) * t)) * 0.95
			return (lead * 10000.0 + bass * 15000.0 + noise * 11000.0)
		}
		4 {
			// World 4: Cyber Matrix - 16th-Note Acid Techno Sequencer (148 BPM, C Minor)
			step_time := 0.101
			step := int(t / step_time) % 32
			lead_notes := [
				261.63, 311.13, 392.00, 466.16, 523.25, 466.16, 392.00, 311.13, // Cm
				233.08, 293.66, 349.23, 466.16, 587.33, 466.16, 349.23, 293.66, // Bb
				207.65, 261.63, 311.13, 415.30, 523.25, 415.30, 311.13, 261.63, // Ab
				196.00, 246.94, 293.66, 392.00, 493.88, 392.00, 293.66, 246.94  // G
			]
			bass_notes := [65.41, 58.27, 51.91, 49.00]
			freq := lead_notes[step]
			bass_freq := bass_notes[step / 8]

			local_t := math.fmod(t, step_time)
			env := math.pow(1.0 - (local_t / step_time), 1.6)

			lead := math.sin(2.0 * math.pi * freq * t + math.sin(2.0 * math.pi * 14.0 * t) * 1.5) * env
			bass := math.sin(2.0 * math.pi * bass_freq * t) * 0.9
			return (lead * 12000.0 + bass * 13500.0)
		}
		else {
			// World 5: Cosmic Abyss - Epic Boss Symphony (152 BPM, F# Minor)
			step_time := 0.098
			step := int(t / step_time) % 32
			lead_notes := [
				369.99, 440.00, 554.37, 739.99, 880.00, 739.99, 554.37, 440.00, // F#m
				293.66, 369.99, 440.00, 587.33, 739.99, 587.33, 440.00, 369.99, // D
				246.94, 293.66, 369.99, 493.88, 587.33, 493.88, 369.99, 293.66, // Bm
				277.18, 349.23, 415.30, 554.37, 698.46, 554.37, 415.30, 349.23  // C#7
			]
			bass_notes := [46.25, 36.71, 30.87, 34.65]
			freq := lead_notes[step]
			bass_freq := bass_notes[step / 8]

			local_t := math.fmod(t, step_time)
			env := math.pow(1.0 - (local_t / step_time), 1.2)
			noise := if step % 2 == 1 { (f64((total_sample * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * env * 0.3 } else { 0.0 }

			lead := (math.sin(2.0 * math.pi * freq * t) + 0.5 * math.sin(2.0 * math.pi * (freq * 2.0) * t)) * env
			bass := (math.sin(2.0 * math.pi * bass_freq * t) + 0.3 * math.sin(4.0 * math.pi * bass_freq * t)) * 0.95
			return (lead * 13000.0 + bass * 15000.0 + noise * 12000.0)
		}
	}
}

pub fn (sm &SoundManager) play_laser() {
	sample_rate := 44100
	duration := 0.09
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1300.0 - t * 7500.0
		env := math.pow(1.0 - (t / duration), 1.2)
		val := math.sin(2.0 * math.pi * math.max(100.0, freq) * t) * env * 22000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (sm &SoundManager) play_jump() {
	sample_rate := 44100
	duration := 0.15
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 260.0 + t * 1500.0
		env := 1.0 - (t / duration)
		val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (sm &SoundManager) play_boost() {
	sample_rate := 44100
	duration := 0.20
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 200.0 + t * 1000.0
		env := 1.0 - (t / duration)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * 0.4
		val := (math.sin(2.0 * math.pi * freq * t) * 0.7 + noise) * env * 24000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (sm &SoundManager) play_explosion() {
	sample_rate := 44100
	duration := 0.28
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.pow(1.0 - (t / duration), 1.2)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0)
		sub := math.sin(2.0 * math.pi * 65.0 * t) * 0.5
		val := (noise * 0.75 + sub) * env * 26000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (sm &SoundManager) play_powerup() {
	sample_rate := 44100
	duration := 0.26
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	notes := [587.33, 739.99, 880.00, 1174.66]
	note_len := duration / f64(notes.len)

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(t / note_len)
		cur_note := if note_idx < notes.len { notes[note_idx] } else { notes[notes.len - 1] }
		local_t := math.fmod(t, note_len)
		env := 1.0 - (local_t / note_len)
		val := math.sin(2.0 * math.pi * cur_note * t) * env * 19000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (sm &SoundManager) play_dragon_roar() {
	sample_rate := 44100
	duration := 0.40
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		carrier := 95.0 + math.sin(2.0 * math.pi * 18.0 * t) * 45.0
		mod := math.sin(2.0 * math.pi * 8.0 * t) * 60.0
		env := math.pow(1.0 - (t / duration), 0.7)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * 0.35
		val := (math.sin(2.0 * math.pi * (carrier + mod) * t) + noise) * env * 25000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (sm &SoundManager) play_victory() {
	sample_rate := 44100
	duration := 0.60
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	note_len := duration / f64(notes.len)

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(t / note_len)
		cur_note := if note_idx < notes.len { notes[note_idx] } else { notes[notes.len - 1] }
		local_t := math.fmod(t, note_len)
		env := 1.0 - (local_t / note_len)
		val := math.sin(2.0 * math.pi * cur_note * t) * env * 20000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (sm &SoundManager) play_crash() {
	sample_rate := 44100
	duration := 0.22
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 480.0 - t * 1500.0
		env := 1.0 - (t / duration)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * 0.6
		val := (math.sin(2.0 * math.pi * math.max(60.0, freq) * t) * 0.4 + noise) * env * 24000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}
