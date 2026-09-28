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
			sample_rate:   44100
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
	sm.load_clip('bgm', 'bowling_bgm.wav')
	sm.load_clip('roll', 'bowling_roll.wav')
	sm.load_clip('strike', 'bowling_strike.wav')
	sm.load_clip('hit', 'bowling_hit.wav')
	sm.load_clip('gutter', 'bowling_gutter.wav')
	sm.load_clip('pinsetter', 'bowling_pinsetter.wav')
	sm.load_clip('cheer', 'bowling_cheer.wav')
	sm.load_clip('foul', 'bowling_foul.wav')
	sm.load_clip('win', 'bowling_win.wav')
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

pub fn (mut sm SoundManager) play_roll_sound(power f64) {
	if 'roll' in sm.clips {
		sm.play_clip('roll')
		return
	}
	dur := 1.2
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	vol := math.clamp(0.4 + power * 0.5, 0.2, 1.0)

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * 0.4
		rumble := math.sin(2.0 * math.pi * 65.0 * t) * 0.6
		sample := (noise + rumble) * vol * math.min(1.0, t * 4.0) * math.max(0.0, 1.0 - t / dur)
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_pin_hit(intensity f64) {
	if 'hit' in sm.clips {
		sm.play_clip('hit')
		return
	}
	dur := 0.22
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	vol := math.clamp(0.4 + intensity * 0.6, 0.2, 1.0)

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-35.0 * t) * 0.7
		tone1 := math.sin(2.0 * math.pi * 950.0 * t) * math.exp(-40.0 * t) * 0.5
		tone2 := math.sin(2.0 * math.pi * 1450.0 * t) * math.exp(-45.0 * t) * 0.4
		sample := (noise + tone1 + tone2) * vol
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_strike_sound() {
	if 'strike' in sm.clips {
		sm.play_clip('strike')
		return
	}
	dur := 0.6
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-12.0 * t) * 0.8
		bass := math.sin(2.0 * math.pi * 85.0 * t) * math.exp(-8.0 * t) * 0.6
		sample := (noise + bass) * 0.9
		samples << i16(sample * 24000.0)
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_gutter_sound() {
	if 'gutter' in sm.clips {
		sm.play_clip('gutter')
		return
	}
	dur := 0.3
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-20.0 * t) * 0.6
		thud := math.sin(2.0 * math.pi * 90.0 * t) * math.exp(-25.0 * t) * 0.7
		sample := (noise + thud) * 0.7
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_pinsetter_sweep() {
	if 'pinsetter' in sm.clips {
		sm.play_clip('pinsetter')
		return
	}
	dur := 0.4
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		hum := math.sin(2.0 * math.pi * 120.0 * t) * 0.3
		gear := math.sin(2.0 * math.pi * 380.0 * t) * 0.2
		sample := (hum + gear) * 0.6
		samples << i16(sample * 12000.0)
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_cheer_sound() {
	if 'cheer' in sm.clips {
		sm.play_clip('cheer')
		return
	}
	dur := 1.0
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		clap := (rand.f64() * 2.0 - 1.0) * math.sin(t * math.pi) * 0.5
		samples << i16(clap * 14000.0)
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_strike_fanfare() {
	if 'win' in sm.clips {
		sm.play_clip('win')
		return
	}
	sm.play_cheer_sound()
}

pub fn (mut sm SoundManager) play_spare_fanfare() {
	if 'cheer' in sm.clips {
		sm.play_clip('cheer')
		return
	}
	sm.play_cheer_sound()
}
