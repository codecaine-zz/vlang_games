module main

import math
import rand
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
	sm.load_clip('bgm', 'lolo_bgm.wav')
	sm.load_clip('step', 'lolo_step.wav')
	sm.load_clip('heart', 'lolo_heart.wav')
	sm.load_clip('shot', 'lolo_shot.wav')
	sm.load_clip('egg', 'lolo_egg.wav')
	sm.load_clip('push', 'lolo_push.wav')
	sm.load_clip('chest', 'lolo_chest.wav')
	sm.load_clip('door', 'lolo_door.wav')
	sm.load_clip('victory', 'lolo_victory.wav')
	sm.load_clip('death', 'lolo_death.wav')
	sm.load_clip('medusa', 'lolo_medusa.wav')
	sm.load_clip('warp', 'lolo_warp.wav')
	sm.load_clip('slide', 'lolo_slide.wav')
	sm.load_clip('hammer', 'lolo_hammer.wav')
	sm.load_clip('badge', 'lolo_badge.wav')
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
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['step'] {
		mutable_sm.play_sfx_pcm(clip, 0.6)
	} else {
		mutable_sm.play_sfx_pcm(gen_step(), 0.6)
	}
}

pub fn (sm &SoundManager) play_heart() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['heart'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
	} else {
		mutable_sm.play_sfx_pcm(gen_heart(), 0.85)
	}
}

pub fn (sm &SoundManager) play_shot() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['shot'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
	} else {
		mutable_sm.play_sfx_pcm(gen_shot(), 0.85)
	}
}

pub fn (sm &SoundManager) play_egg() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['egg'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
	} else {
		mutable_sm.play_sfx_pcm(gen_egg(), 0.85)
	}
}

pub fn (sm &SoundManager) play_push() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['push'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
	} else {
		mutable_sm.play_sfx_pcm(gen_push(), 0.85)
	}
}

pub fn (sm &SoundManager) play_chest() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['chest'] {
		mutable_sm.play_sfx_pcm(clip, 0.95)
	} else {
		mutable_sm.play_sfx_pcm(gen_chest(), 0.95)
	}
}

pub fn (sm &SoundManager) play_undo() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_undo(), 0.75)
}

pub fn (sm &SoundManager) play_victory() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['victory'] {
		mutable_sm.play_sfx_pcm(clip, 0.95)
	} else {
		mutable_sm.play_sfx_pcm(gen_victory(), 0.95)
	}
}

pub fn (sm &SoundManager) play_warp() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['warp'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
	} else {
		mutable_sm.play_sfx_pcm(gen_warp(), 0.85)
	}
}

pub fn (sm &SoundManager) play_slide() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['slide'] {
		mutable_sm.play_sfx_pcm(clip, 0.8)
	} else {
		mutable_sm.play_sfx_pcm(gen_slide(), 0.8)
	}
}

pub fn (sm &SoundManager) play_key() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_key(), 0.85)
}

pub fn (sm &SoundManager) play_spike() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['medusa'] {
		mutable_sm.play_sfx_pcm(clip, 0.9)
	} else {
		mutable_sm.play_sfx_pcm(gen_spike(), 0.9)
	}
}

pub fn (sm &SoundManager) play_powerup() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_powerup(), 0.85)
}

pub fn (sm &SoundManager) play_prism() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_prism(), 0.85)
}

pub fn (sm &SoundManager) play_phase() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_phase(), 0.85)
}

pub fn (sm &SoundManager) play_plate() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_plate(), 0.85)
}

pub fn (sm &SoundManager) play_badge() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['badge'] {
		mutable_sm.play_sfx_pcm(clip, 0.9)
	} else {
		mutable_sm.play_sfx_pcm(gen_badge(), 0.9)
	}
}

pub fn (sm &SoundManager) play_laser() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_laser(), 0.85)
}

pub fn (sm &SoundManager) play_hammer() {
	if !sm.sound_enabled || false { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['hammer'] {
		mutable_sm.play_sfx_pcm(clip, 0.9)
	} else {
		mutable_sm.play_sfx_pcm(gen_hammer(), 0.9)
	}
}

fn gen_step() []i16 {
	sample_rate := 44100
	duration_ms := 35
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 320.0 - (180.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-35.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 14000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_heart() []i16 {
	sample_rate := 44100
	notes := [587.33, 880.00, 1174.66]
	note_dur := 55
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-18.0 * t)
			val := (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env * 18000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_shot() []i16 {
	sample_rate := 44100
	duration_ms := 110
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1400.0 - (1100.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-12.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 24000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_egg() []i16 {
	sample_rate := 44100
	duration_ms := 150
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 300.0 + (700.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-8.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 22000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_push() []i16 {
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 140.0 - (60.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-22.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 25000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_chest() []i16 {
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	note_dur := 80
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-10.0 * t)
			val := (math.sin(2.0 * math.pi * freq * t) + 0.4 * math.sin(4.0 * math.pi * freq * t)) * env * 22000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_undo() []i16 {
	sample_rate := 44100
	duration_ms := 70
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 700.0 - (400.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-25.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 16000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_victory() []i16 {
	sample_rate := 44100
	notes := [659.25, 783.99, 880.00, 1046.50, 1318.51]
	note_dur := 110
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-8.0 * t)
			val := (math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)) * env * 24000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_warp() []i16 {
	sample_rate := 44100
	duration_ms := 250
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 300.0 + 900.0 * (f64(i) / f64(num_samples))
		env := math.sin(math.pi * (f64(i) / f64(num_samples)))
		val := math.sin(2.0 * math.pi * freq * t) * env * 20000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_slide() []i16 {
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * 0.5
		sub := math.sin(2.0 * math.pi * 220.0 * t) * 0.5
		env := math.exp(-12.0 * t)
		val := (noise + sub) * env * 18000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_key() []i16 {
	sample_rate := 44100
	notes := [880.0, 1174.66]
	note_dur := 70
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-20.0 * t)
			val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_spike() []i16 {
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * 0.7
		zap := math.sin(2.0 * math.pi * (800.0 - 500.0 * (f64(i) / f64(num_samples))) * t) * 0.3
		env := math.exp(-10.0 * t)
		val := (noise + zap) * env * 22000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_powerup() []i16 {
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_dur := 45
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-15.0 * t)
			val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_prism() []i16 {
	sample_rate := 44100
	duration_ms := 90
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1200.0 + math.sin(t * 100.0) * 400.0
		env := math.exp(-25.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_phase() []i16 {
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0 + 800.0 * (f64(i) / f64(num_samples))
		env := math.sin(math.pi * (f64(i) / f64(num_samples)))
		val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_plate() []i16 {
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-30.0 * t)
		val := math.sin(2.0 * math.pi * 500.0 * t) * env * 16000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_badge() []i16 {
	sample_rate := 44100
	notes := [783.99, 987.77, 1174.66, 1567.98]
	note_dur := 70
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-12.0 * t)
			val := math.sin(2.0 * math.pi * freq * t) * env * 20000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_laser() []i16 {
	sample_rate := 44100
	duration_ms := 140
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 900.0 - (500.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-16.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 22000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_hammer() []i16 {
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 220.0 - 120.0 * (f64(i) / f64(num_samples))
		env := math.exp(-14.0 * t)
		val := (if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }) * env * 24000.0
		pcm[i] = i16(val)
	}
	return pcm
}

pub fn (sm &SoundManager) play_bomb() {
	if !sm.sound_enabled || !sm.sfx_enabled { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_bomb(), 0.95)
}

pub fn (sm &SoundManager) play_dry_fire() {
	if !sm.sound_enabled || !sm.sfx_enabled { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_dry_fire(), 0.6)
}

fn gen_bomb() []i16 {
	sample_rate := 44100
	duration_ms := 400
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * 0.8
		rumble := math.sin(2.0 * math.pi * (110.0 - 70.0 * (f64(i) / f64(num_samples))) * t) * 0.4
		env := math.exp(-8.0 * t)
		val := (noise + rumble) * env * 28000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_dry_fire() []i16 {
	sample_rate := 44100
	duration_ms := 45
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1800.0 - (1200.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-40.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 14000.0
		pcm[i] = i16(val)
	}
	return pcm
}
