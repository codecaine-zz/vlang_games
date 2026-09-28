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
	sm.load_clip('bgm', 'chipschallenge_bgm.wav')
	sm.load_clip('step', 'chip_step.wav')
	sm.load_clip('chip', 'chip_collect.wav')
	sm.load_clip('key', 'chip_key.wav')
	sm.load_clip('door', 'chip_door.wav')
	sm.load_clip('socket', 'chip_socket.wav')
	sm.load_clip('win', 'chip_win.wav')
	sm.load_clip('death', 'chip_death.wav')
	sm.load_clip('push', 'chip_push.wav')
	sm.load_clip('boot', 'chip_boot.wav')
	sm.load_clip('splash', 'chip_splash.wav')
	sm.load_clip('burn', 'chip_burn.wav')
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

pub fn (sm &SoundManager) play_step() {
	if clip := sm.sfx_clips['step'] {
		sm.play_sfx_pcm(clip, 0.6)
		return
	}
	// Procedural fallback
	dur := 0.035
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 110.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * 620.0 * t) * env * 12000.0)
	}
	sm.play_sfx_pcm(pcm, 0.6)
}

pub fn (sm &SoundManager) play_chip() {
	if clip := sm.sfx_clips['chip'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.12
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := if t < 0.06 { 1318.51 } else { 1975.53 }
		env := math.exp(-math.fmod(t, 0.06) * 32.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 18000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (sm &SoundManager) play_key() {
	if clip := sm.sfx_clips['key'] {
		sm.play_sfx_pcm(clip, 0.85)
		return
	}
	dur := 0.14
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := if t < 0.07 { 880.0 } else { 1174.66 }
		env := math.exp(-math.fmod(t, 0.07) * 26.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 17000.0)
	}
	sm.play_sfx_pcm(pcm, 0.85)
}

pub fn (sm &SoundManager) play_door() {
	if clip := sm.sfx_clips['door'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.20
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 14.0)
		freq := 280.0 * math.exp(-t * 8.0) + 90.0
		noise := (rand.f64() * 2.0 - 1.0) * 0.35
		pcm[i] = i16((math.sin(2.0 * math.pi * freq * t) * 0.65 + noise) * env * 18000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (sm &SoundManager) play_socket() {
	if clip := sm.sfx_clips['socket'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.26
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	notes := [523.25, 659.25, 783.99, 1046.50]
	for i in 0 .. count {
		t := f64(i) / 44100.0
		n_idx := int(t / (dur / 4.0))
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		env := math.exp(-math.fmod(t, dur / 4.0) * 20.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 18000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (sm &SoundManager) play_win() {
	if clip := sm.sfx_clips['win'] {
		sm.play_sfx_pcm(clip, 0.95)
		return
	}
	dur := 0.50
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	for i in 0 .. count {
		t := f64(i) / 44100.0
		n_idx := int(t / (dur / 5.0))
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		env := math.exp(-math.fmod(t, dur / 5.0) * 10.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 19000.0)
	}
	sm.play_sfx_pcm(pcm, 0.95)
}

pub fn (sm &SoundManager) play_death() {
	if clip := sm.sfx_clips['death'] {
		sm.play_sfx_pcm(clip, 0.95)
		return
	}
	dur := 0.32
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := 480.0 * math.exp(-t * 9.0) + 60.0
		env := math.exp(-t * 8.0)
		noise := (rand.f64() * 2.0 - 1.0) * 0.25
		pcm[i] = i16((math.sin(2.0 * math.pi * freq * t) * 0.75 + noise) * env * 20000.0)
	}
	sm.play_sfx_pcm(pcm, 0.95)
}

pub fn (sm &SoundManager) play_push() {
	if clip := sm.sfx_clips['push'] {
		sm.play_sfx_pcm(clip, 0.8)
		return
	}
	dur := 0.15
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.sin(math.pi * (t / dur))
		noise := (rand.f64() * 2.0 - 1.0) * 0.5
		sub := math.sin(2.0 * math.pi * 120.0 * t) * 0.5
		pcm[i] = i16((noise + sub) * env * 16000.0)
	}
	sm.play_sfx_pcm(pcm, 0.8)
}

pub fn (sm &SoundManager) play_boot() {
	if clip := sm.sfx_clips['boot'] {
		sm.play_sfx_pcm(clip, 0.85)
		return
	}
	dur := 0.16
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := if t < 0.08 { 783.99 } else { 1046.50 }
		env := math.exp(-math.fmod(t, 0.08) * 22.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 17000.0)
	}
	sm.play_sfx_pcm(pcm, 0.85)
}

pub fn (sm &SoundManager) play_splash() {
	if clip := sm.sfx_clips['splash'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.20
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 14.0)
		noise := (rand.f64() * 2.0 - 1.0) * 0.7
		sweep := math.sin(2.0 * math.pi * (340.0 - 220.0 * (t / dur)) * t) * 0.3
		pcm[i] = i16((noise + sweep) * env * 18000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (sm &SoundManager) play_burn() {
	if clip := sm.sfx_clips['burn'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.22
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 12.0)
		noise := (rand.f64() * 2.0 - 1.0) * 0.8
		pcm[i] = i16(noise * env * 19000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}
