module main

import math
import os
import encoding.binary
import sokol.audio

const audio_sample_rate = 44100

pub enum BgmTrack {
	gothic_rondo
	vampires_eclipse
	bloodlust_symphony
	off
}

pub type BgmType = BgmTrack

pub fn (sm &SoundManager) set_bgm(bgm_type BgmTrack) {
	unsafe {
		mut msm := &SoundManager(sm)
		msm.bgm_type = bgm_type
		msm.bgm_track = bgm_type
		msm.update_bgm(true)
	}
}

pub fn (sm &SoundManager) cycle_bgm() BgmTrack {
	unsafe {
		mut msm := &SoundManager(sm)
		msm.bgm_track = match msm.bgm_track {
			.gothic_rondo { BgmTrack.vampires_eclipse }
			.vampires_eclipse { BgmTrack.bloodlust_symphony }
			.bloodlust_symphony { BgmTrack.off }
			.off { BgmTrack.gothic_rondo }
		}
		msm.bgm_type = msm.bgm_track
		msm.update_bgm(true)
		return msm.bgm_track
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
	bgm_type      BgmTrack = .gothic_rondo
	bgm_track     BgmTrack = .gothic_rondo
	current_bgm   BgmTrack = .off
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
	sm.load_clip('whip', 'vs_whip.wav')
	sm.load_clip('wand', 'vs_wand.wav')
	sm.load_clip('knife', 'vs_knife.wav')
	sm.load_clip('axe', 'vs_axe.wav')
	sm.load_clip('bible', 'vs_bible.wav')
	sm.load_clip('lightning', 'vs_lightning.wav')
	sm.load_clip('fire', 'vs_fire.wav')
	sm.load_clip('nuke', 'vs_nuke.wav')
	sm.load_clip('laser', 'vs_laser.wav')
	sm.load_clip('hit', 'vs_hit.wav')
	sm.load_clip('kill', 'vs_kill.wav')
	sm.load_clip('smash', 'vs_smash.wav')
	sm.load_clip('gem', 'vs_gem.wav')
	sm.load_clip('gem_big', 'vs_gem_big.wav')
	sm.load_clip('item', 'vs_item.wav')
	sm.load_clip('heal', 'vs_heal.wav')
	sm.load_clip('freeze', 'vs_freeze.wav')
	sm.load_clip('hurt', 'vs_hurt.wav')
	sm.load_clip('levelup', 'vs_levelup.wav')
	sm.load_clip('chest', 'vs_chest.wav')
	sm.load_clip('evolve', 'vs_evolve.wav')
	sm.load_clip('ultimate', 'vs_ultimate.wav')
	sm.load_clip('bgm_rondo', 'vampiresurvivors_rondo.wav')
	sm.load_clip('bgm_eclipse', 'vampiresurvivors_eclipse.wav')
	sm.load_clip('bgm_symphony', 'vampiresurvivors_symphony.wav')
}

pub fn (sm &SoundManager) toggle_music() bool {
	unsafe {
		mut msm := &SoundManager(sm)
		msm.bgm_enabled = !msm.bgm_enabled
		if !msm.bgm_enabled {
			msm.voices = msm.voices.filter(!it.is_bgm)
			msm.bgm_active = false
			msm.current_bgm = .off
		} else {
			if msm.bgm_track == .off {
				msm.bgm_track = .gothic_rondo
				msm.bgm_type = .gothic_rondo
			}
			msm.update_bgm(true)
		}
		return msm.bgm_enabled && msm.bgm_track != .off
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
		if !msm.sound_enabled || !msm.bgm_enabled || msm.bgm_track == .off || !is_active {
			if msm.bgm_active {
				msm.voices = msm.voices.filter(!it.is_bgm)
				msm.bgm_active = false
				msm.current_bgm = .off
			}
			return
		}

		if !msm.bgm_active || msm.current_bgm != msm.bgm_track {
			clip_name := match msm.bgm_track {
				.gothic_rondo { 'bgm_rondo' }
				.vampires_eclipse { 'bgm_eclipse' }
				.bloodlust_symphony { 'bgm_symphony' }
				.off { '' }
			}
			if clip_name != '' {
				if clip := msm.clips[clip_name] {
					if clip.len > 0 {
						msm.voices = msm.voices.filter(!it.is_bgm)
						msm.voices << ActiveVoice{
							samples: clip
							pos:     0
							volume:  0.42
							looping: true
							is_bgm:  true
						}
						msm.bgm_active = true
						msm.current_bgm = msm.bgm_track
					}
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
				if msm.voices.len < 24 {
					msm.voices << ActiveVoice{
						samples: clip
						pos:     0
						volume:  0.7
						looping: false
						is_bgm:  false
					}
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
			is_bgm:  false
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
		if msm.voices.len < 24 {
			msm.voices << ActiveVoice{
				samples: s
				pos:     0
				volume:  v
				looping: false
				is_bgm:  false
			}
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

pub fn (sm &SoundManager) queue_sfx_clip(name string, fallback_fn fn () []i16, vol f32) {
	if !sm.sound_enabled || !sm.sfx_enabled {
		return
	}
	unsafe {
		mut msm := &SoundManager(sm)
		// Check preloaded WAV clips first for instant crisp playback
		if name in msm.clips {
			clip := msm.clips[name]
			if clip.len > 0 {
				if msm.voices.len < 24 {
					msm.voices << ActiveVoice{
						samples: clip
						pos:     0
						volume:  vol
						looping: false
						is_bgm:  false
					}
				}
				return
			}
		}
		if name in msm.sfx_clips {
			pcm := msm.sfx_clips[name]
			if pcm.len > 0 {
				sm.play_sfx_pcm(pcm, vol)
				return
			}
		}
		// Fallback synthesis
		pcm := fallback_fn()
		if pcm.len > 0 {
			sm.play_sfx_pcm(pcm, vol)
		}
	}
}

pub fn (sm &SoundManager) play_whip_sound() {
	sm.queue_sfx_clip('whip', fn () []i16 {
		num_samples := 3500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 900.0 * math.exp(-t * 22.0) + 90.0
			noise := (math.sin(f64(i) * 0.45) * 2.0 - 1.0) * 0.4
			wave := math.sin(t * freq * 2.0 * math.pi) + noise
			env := math.exp(-t * 28.0)
			samples[i] = i16(wave * env * 14000.0)
		}
		return samples
	}, 0.9)
}

pub fn (sm &SoundManager) play_magic_wand_sound() {
	sm.queue_sfx_clip('wand', fn () []i16 {
		num_samples := 3000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 450.0 + 800.0 * t
			wave := math.sin(t * freq * 2.0 * math.pi)
			env := (1.0 - f64(i) / f64(num_samples))
			samples[i] = i16(wave * env * 10000.0)
		}
		return samples
	}, 0.8)
}

pub fn (sm &SoundManager) play_knife_sound() {
	sm.queue_sfx_clip('knife', fn () []i16 {
		num_samples := 2000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 1200.0 - 600.0 * t
			wave := if math.sin(t * freq * 2.0 * math.pi) > 0.0 { 1.0 } else { -1.0 }
			env := (1.0 - f64(i) / f64(num_samples))
			samples[i] = i16(wave * env * 8000.0)
		}
		return samples
	}, 0.8)
}

pub fn (sm &SoundManager) play_axe_sound() {
	sm.queue_sfx_clip('axe', fn () []i16 {
		num_samples := 4000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 240.0 + math.sin(t * 18.0) * 40.0
			wave := math.sin(t * freq * 2.0 * math.pi)
			env := (1.0 - f64(i) / f64(num_samples))
			samples[i] = i16(wave * env * 11000.0)
		}
		return samples
	}, 0.85)
}

pub fn (sm &SoundManager) play_bible_sound() {
	sm.queue_sfx_clip('bible', fn () []i16 {
		num_samples := 5000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			wave := math.sin(t * 523.25 * 2.0 * math.pi) + 0.5 * math.sin(t * 783.99 * 2.0 * math.pi)
			env := math.exp(-t * 10.0)
			samples[i] = i16(wave * env * 9000.0)
		}
		return samples
	}, 0.8)
}

pub fn (sm &SoundManager) play_lightning_sound() {
	sm.queue_sfx_clip('lightning', fn () []i16 {
		num_samples := 6000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 31)) * 2.0 - 1.0)
			env := math.exp(-t * 12.0)
			samples[i] = i16(noise * env * 14000.0)
		}
		return samples
	}, 0.9)
}

pub fn (sm &SoundManager) play_fire_sound() {
	sm.queue_sfx_clip('fire', fn () []i16 {
		num_samples := 5000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 23)) * 2.0 - 1.0)
			env := math.exp(-t * 10.0)
			samples[i] = i16(noise * env * 12000.0)
		}
		return samples
	}, 0.85)
}

pub fn (sm &SoundManager) play_nuke_sound() {
	sm.queue_sfx_clip('nuke', fn () []i16 {
		num_samples := 14000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			sub := math.sin(t * (70.0 - t * 40.0) * 2.0 * math.pi) * math.exp(-t * 3.0)
			noise := (math.sin(f64(i * 47)) * 2.0 - 1.0) * math.exp(-t * 6.0)
			samples[i] = i16((sub * 0.65 + noise * 0.45) * 16000.0)
		}
		return samples
	}, 0.95)
}

pub fn (sm &SoundManager) play_laser_sound() {
	sm.queue_sfx_clip('laser', fn () []i16 {
		num_samples := 4000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 1600.0 * math.exp(-t * 18.0) + 400.0
			phase := t * freq
			saw := (phase - math.floor(phase)) * 2.0 - 1.0
			env := math.exp(-t * 14.0)
			samples[i] = i16(saw * env * 11000.0)
		}
		return samples
	}, 0.8)
}

pub fn (sm &SoundManager) play_gem_pickup_sound(val int) {
	clip_name := if val >= 25 { 'gem_big' } else { 'gem' }
	sm.queue_sfx_clip(clip_name, fn () []i16 {
		num_samples := 2500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			wave := math.sin(t * 880.0 * 2.0 * math.pi)
			env := math.exp(-t * 22.0)
			samples[i] = i16(wave * env * 11000.0)
		}
		return samples
	}, 0.8)
}

pub fn (sm &SoundManager) play_level_up_sound() {
	sm.queue_sfx_clip('levelup', fn () []i16 {
		notes := [523.25, 659.25, 783.99, 1046.50]
		note_len := 2200
		mut samples := []i16{len: notes.len * note_len}
		for n_i, freq in notes {
			for i in 0 .. note_len {
				t := f64(i) / 44100.0
				wave := math.sin(t * freq * 2.0 * math.pi) + 0.3 * math.sin(t * freq * 4.0 * math.pi)
				env := 1.0 - f64(i) / f64(note_len)
				samples[n_i * note_len + i] = i16(wave * env * 12000.0)
			}
		}
		return samples
	}, 0.9)
}

pub fn (sm &SoundManager) play_hit_sound() {
	sm.queue_sfx_clip('hit', fn () []i16 {
		num_samples := 2000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 37)) * 2.0 - 1.0)
			env := math.exp(-t * 30.0)
			samples[i] = i16(noise * env * 12000.0)
		}
		return samples
	}, 0.75)
}

pub fn (sm &SoundManager) play_kill_sound() {
	sm.queue_sfx_clip('kill', fn () []i16 {
		num_samples := 2500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 41)) * 2.0 - 1.0)
			env := math.exp(-t * 25.0)
			samples[i] = i16(noise * env * 12000.0)
		}
		return samples
	}, 0.8)
}

pub fn (sm &SoundManager) play_chest_sound() {
	sm.queue_sfx_clip('chest', fn () []i16 {
		notes := [440.0, 554.37, 659.25, 880.0, 1108.73]
		note_len := 2500
		mut samples := []i16{len: notes.len * note_len}
		for n_i, freq in notes {
			for i in 0 .. note_len {
				t := f64(i) / 44100.0
				sq := if math.sin(t * freq * 2.0 * math.pi) > 0.0 { 1.0 } else { -1.0 }
				env := 1.0 - f64(i) / f64(note_len)
				samples[n_i * note_len + i] = i16(sq * env * 10000.0)
			}
		}
		return samples
	}, 0.9)
}

pub fn (sm &SoundManager) play_rosary_sound() {
	sm.queue_sfx_clip('lightning', fn () []i16 {
		num_samples := 9000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 43)) * 2.0 - 1.0)
			env := math.exp(-t * 5.0)
			samples[i] = i16(noise * env * 16000.0)
		}
		return samples
	}, 0.9)
}

pub fn (sm &SoundManager) play_vacuum_sound() {
	sm.queue_sfx_clip('gem_big', fn () []i16 {
		num_samples := 6000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 200.0 + 800.0 * (t / 0.136)
			wave := math.sin(t * freq * 2.0 * math.pi)
			samples[i] = i16(wave * 11000.0)
		}
		return samples
	}, 0.85)
}

pub fn (sm &SoundManager) play_evolution_sound() {
	sm.queue_sfx_clip('evolve', fn () []i16 {
		notes := [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
		note_len := 2200
		mut samples := []i16{len: notes.len * note_len}
		for n_i, freq in notes {
			for i in 0 .. note_len {
				t := f64(i) / 44100.0
				wave := math.sin(t * freq * 2.0 * math.pi) + 0.4 * math.sin(t * freq * 3.0 * math.pi)
				env := 1.0 - f64(i) / f64(note_len)
				samples[n_i * note_len + i] = i16(wave * env * 13000.0)
			}
		}
		return samples
	}, 0.95)
}

pub fn (sm &SoundManager) play_smash_sound() {
	sm.queue_sfx_clip('smash', fn () []i16 {
		num_samples := 2500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 67)) * 2.0 - 1.0)
			env := math.exp(-t * 35.0)
			samples[i] = i16(noise * env * 11000.0)
		}
		return samples
	}, 0.8)
}

pub fn (sm &SoundManager) play_heal_sound() {
	sm.queue_sfx_clip('heal', fn () []i16 {
		num_samples := 3500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			wave := math.sin(t * 600.0 * 2.0 * math.pi)
			env := math.exp(-t * 20.0)
			samples[i] = i16(wave * env * 12000.0)
		}
		return samples
	}, 0.85)
}

pub fn (sm &SoundManager) play_freeze_sound() {
	sm.queue_sfx_clip('freeze', fn () []i16 {
		num_samples := 4000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			wave := math.sin(t * 1200.0 * 2.0 * math.pi)
			env := math.exp(-t * 15.0)
			samples[i] = i16(wave * env * 10000.0)
		}
		return samples
	}, 0.85)
}

pub fn (sm &SoundManager) play_hurt_sound() {
	sm.queue_sfx_clip('hurt', fn () []i16 {
		num_samples := 2500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			wave := math.sin(t * 120.0 * 2.0 * math.pi)
			env := math.exp(-t * 25.0)
			samples[i] = i16(wave * env * 12000.0)
		}
		return samples
	}, 0.85)
}

pub fn (sm &SoundManager) play_ultimate_sound() {
	sm.queue_sfx_clip('ultimate', fn () []i16 {
		num_samples := 12000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			boom := math.sin(t * (240.0 - t * 450.0) * 2.0 * math.pi) * math.exp(-t * 4.0)
			noise := (math.sin(f64(i * 83)) * 2.0 - 1.0) * math.exp(-t * 8.0)
			samples[i] = i16((boom * 0.6 + noise * 0.4) * 16000.0)
		}
		return samples
	}, 0.95)
}

pub fn (sm &SoundManager) play_combo_sound() {
	sm.queue_sfx_clip('item', fn () []i16 {
		notes := [880.0, 1174.66, 1760.0]
		note_len := 1500
		mut samples := []i16{len: notes.len * note_len}
		for n_i, freq in notes {
			for i in 0 .. note_len {
				t := f64(i) / 44100.0
				wave := math.sin(t * freq * 2.0 * math.pi)
				env := math.exp(-t * 25.0)
				samples[n_i * note_len + i] = i16(wave * env * 11000.0)
			}
		}
		return samples
	}, 0.85)
}

pub fn (sm &SoundManager) play_jackpot_sound() {
	sm.queue_sfx_clip('chest', fn () []i16 {
		notes := [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98, 2093.00]
		note_len := 1800
		mut samples := []i16{len: notes.len * note_len}
		for n_i, freq in notes {
			for i in 0 .. note_len {
				t := f64(i) / 44100.0
				sq := if math.sin(t * freq * 2.0 * math.pi) > 0.0 { 1.0 } else { -1.0 }
				env := 1.0 - f64(i) / f64(note_len)
				samples[n_i * note_len + i] = i16(sq * env * 12000.0)
			}
		}
		return samples
	}, 0.95)
}


