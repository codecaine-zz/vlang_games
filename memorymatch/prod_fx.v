module main

import gg
import math
import time

#include "@VMODROOT/fx_helper.h"

fn C.get_fx_mode_c() int
fn C.set_fx_mode_c(mode int)
fn C.cycle_fx_mode_c(now f64) int
fn C.get_fx_toast_until_c() f64
fn C.trigger_shockwave_c(x f32, y f32, max_r f32, r u8, g u8, b u8)
fn C.update_shockwaves_c(dt f32)
fn C.get_active_shockwaves_c(out_data &f32, max_count int) int

fn C.get_audio_rms_c() f32
fn C.get_audio_peak_c() f32
fn C.get_audio_bass_c() f32
fn C.set_game_paused_c(paused int)

fn C.trigger_shake_c(trauma f32)
fn C.update_shake_c(dt f32)
fn C.get_shake_x_c() f32
fn C.get_shake_y_c() f32
fn C.get_shake_trauma_c() f32

fn C.trigger_sparks_c(x f32, y f32, base_vx f32, base_vy f32, count int, r u8, g u8, b u8)
fn C.update_sparks_c(dt f32)
fn C.get_active_sparks_c(out_data &f32, max_count int) int

fn C.trigger_floating_score_c(x f32, y f32, score int, r u8, g u8, b u8)
fn C.update_floating_scores_c(dt f32)
fn C.get_active_floating_scores_c(out_data &f32, max_count int) int

pub fn prod_fx_cycle_mode() int {
	t := f64(time.ticks()) / 1000.0
	return C.cycle_fx_mode_c(t)
}

pub fn prod_fx_trigger_shockwave(x f32, y f32, max_r f32, r u8, g u8, b u8) {
	C.trigger_shockwave_c(x, y, max_r, r, g, b)
}

pub fn prod_fx_trigger_shake(trauma f32) {
	C.trigger_shake_c(trauma)
}

pub fn prod_fx_get_shake() (f32, f32) {
	return C.get_shake_x_c(), C.get_shake_y_c()
}

pub fn prod_fx_trigger_sparks(x f32, y f32, base_vx f32, base_vy f32, count int, r u8, g u8, b u8) {
	C.trigger_sparks_c(x, y, base_vx, base_vy, count, r, g, b)
}

pub fn prod_fx_trigger_floating_score(x f32, y f32, score int, r u8, g u8, b u8) {
	C.trigger_floating_score_c(x, y, score, r, g, b)
}

pub fn prod_fx_set_paused(paused bool) {
	C.set_game_paused_c(if paused { 1 } else { 0 })
}

pub fn prod_fx_handle_key(key gg.KeyCode) bool {
	if key in [.f10, .o] {
		prod_fx_cycle_mode()
		return true
	}
	return false
}

pub fn prod_fx_handle_mouse(mx int, my int, win_w int, win_h int) bool {
	// Check click inside top-right FX badge [w - 170 .. w - 16, 10 .. 38]
	if mx >= win_w - 175 && mx <= win_w - 15 && my >= 10 && my <= 38 {
		prod_fx_cycle_mode()
		return true
	}
	return false
}

fn prod_fx_render(ctx &gg.Context) {
	ws := ctx.window_size()
	w := ws.width
	h := ws.height
	if w <= 0 || h <= 0 {
		return
	}
	t := f64(time.ticks()) / 1000.0
	mode := C.get_fx_mode_c()
	C.update_shockwaves_c(0.016)
	C.update_shake_c(0.016)
	C.update_sparks_c(0.016)
	C.update_floating_scores_c(0.016)

	// 1. Environmental & Atmospheric Background FX
	prod_fx_draw_parallax_starfield(ctx, w, h, t, mode)

	// 2. Shockwave / Impact Ripple Rings
	prod_fx_draw_shockwaves(ctx)

	// 3. Kinetic Directional Spark Debris
	prod_fx_draw_sparks(ctx)

	// 4. Floating Combo & Score Popups
	prod_fx_draw_floating_scores(ctx)

	// 5. Widescreen Arcade Wings & Real-time Audio Reactive Equalizer Bars
	prod_fx_draw_widescreen_wings(ctx, w, h, t, mode)

	// 6. CRT Post-Processing according to Mode
	match mode {
		0 {
			// Arcade CRT Pro: Sony Trinitron RGB Aperture Grille, Scanlines, Cathode Beam, Curved Glass Bezel, Specular Sheen
			prod_fx_draw_rgb_aperture_grille(ctx, w, h)
			prod_fx_draw_scanlines(ctx, w, h, t)
			prod_fx_draw_crt_glass_bezel(ctx, w, h)
			prod_fx_draw_specular_sheen(ctx, w, h)
			prod_fx_draw_particles(ctx, w, h, t, 0)
		}
		1 {
			// Cyber Bloom: Neon Grid, Chromatic Fringe, Glowing Particles
			prod_fx_draw_chromatic_fringe(ctx, w, h, t)
			prod_fx_draw_particles(ctx, w, h, t, 1)
		}
		2 {
			// Clean HD: Minimalist crisp display, zero scanlines, subtle framing
			prod_fx_draw_subtle_frame(ctx, w, h)
		}
		3 {
			// Vintage Amber: 1980s Monochrome Phosphor Glow
			prod_fx_draw_amber_phosphor(ctx, w, h, t)
			prod_fx_draw_scanlines(ctx, w, h, t)
			prod_fx_draw_crt_glass_bezel(ctx, w, h)
		}
		else {}
	}

	// 7. Screen Shake Edge Vignette Flash on High Trauma
	trauma := C.get_shake_trauma_c()
	if trauma > 0.12 {
		alpha := u8(math.min(180.0, f64(trauma * 160.0)))
		shake_col := gg.Color{r: 255, g: 60, b: 60, a: alpha}
		ctx.draw_rect_empty(0, 0, f32(w), f32(h), shake_col)
	}

	// 8. Interactive OSD Top-Right Badge & Banner
	prod_fx_draw_osd(ctx, w, h, t, mode)
}

fn prod_fx_draw_widescreen_wings(ctx &gg.Context, w int, h int, t f64, mode int) {
	expected_w := int(f32(h) * 4.0 / 3.0)
	if w <= expected_w + 24 {
		return
	}
	wing_w := f32(w - expected_w) / 2.0
	fw := f32(w)
	fh := f32(h)

	// Background Depth Gradient for Wings
	steps := 12
	step_w := wing_w / f32(steps)
	for i in 0 .. steps {
		dist_from_edge := f32(i) / f32(steps)
		alpha := u8(24.0 * (1.0 - dist_from_edge * 0.75))
		col := gg.Color{r: 0, g: 0, b: 0, a: alpha}
		ctx.draw_rect_filled(f32(i) * step_w, 0, step_w + 1.0, fh, col)
		ctx.draw_rect_filled(fw - wing_w + f32(steps - 1 - i) * step_w, 0, step_w + 1.0, fh, col)
	}

	// Real-Time Audio Reactive Equalizer Visualizer Bars in the Wings
	eq_bars := 18
	eq_h := fh * 0.65
	eq_y_start := fh * 0.18
	bar_slot_h := eq_h / f32(eq_bars)

	audio_rms := f64(C.get_audio_rms_c())
	audio_peak := f64(C.get_audio_peak_c())
	audio_bass := f64(C.get_audio_bass_c())

	for b := 0; b < eq_bars; b++ {
		fb := f64(b)
		freq_weight := if b < 6 {
			audio_bass * 3.5
		} else if b < 12 {
			audio_rms * 2.8
		} else {
			audio_peak * 2.5
		}
		// Harmonic ambient dance base
		wave1 := math.sin(t * 3.8 + fb * 0.72)
		wave2 := math.cos(t * 2.4 - fb * 0.45)
		ambient_dance := math.max(0.04, (wave1 * 0.15 + wave2 * 0.12 + 0.15))

		// Combine real-time acoustic energy with smooth ambient presence
		eq_val := math.min(1.0, ambient_dance + freq_weight * (0.8 + 0.4 * math.sin(fb * 0.8 + t * 5.0)))

		bar_len := f32(eq_val) * (wing_w * 0.42)
		bar_y := eq_y_start + f32(b) * bar_slot_h

		// Color spectrum: cyan to violet/amber
		mut r_col := u8(40 + b * 11)
		mut g_col := u8(160 - b * 5)
		mut b_col := u8(255 - b * 6)
		if mode == 3 { // Amber mode
			r_col = 255
			g_col = u8(160 + b * 4)
			b_col = 40
		}

		bar_alpha := u8(math.min(180.0, 70.0 + eq_val * 90.0))
		bar_col := gg.Color{r: r_col, g: g_col, b: b_col, a: bar_alpha}

		// Left wing equalizer bar
		ctx.draw_rect_filled(wing_w - bar_len - 14.0, bar_y + 2.0, bar_len, bar_slot_h - 4.0, bar_col)
		// Right wing equalizer bar
		ctx.draw_rect_filled(fw - wing_w + 14.0, bar_y + 2.0, bar_len, bar_slot_h - 4.0, bar_col)
	}

	// Glowing Neon Playfield Boundary Dividers
	pulse := 0.5 + 0.5 * math.sin(t * 2.2)
	divider_alpha := u8(65.0 + 35.0 * pulse)
	glow_col := if mode == 3 {
		gg.Color{r: 255, g: 170, b: 40, a: divider_alpha}
	} else if mode == 1 {
		gg.Color{r: 255, g: 40, b: 180, a: divider_alpha}
	} else {
		gg.Color{r: 50, g: 140, b: 240, a: divider_alpha}
	}

	core_col := if mode == 3 {
		gg.Color{r: 255, g: 220, b: 120, a: u8(130.0 + 40.0 * pulse)}
	} else if mode == 1 {
		gg.Color{r: 255, g: 160, b: 240, a: u8(130.0 + 40.0 * pulse)}
	} else {
		gg.Color{r: 160, g: 220, b: 255, a: u8(130.0 + 40.0 * pulse)}
	}

	// Left divider
	ctx.draw_rect_filled(wing_w - 2.5, 0, 5.0, fh, glow_col)
	ctx.draw_rect_filled(wing_w - 0.75, 0, 1.5, fh, core_col)

	// Right divider
	r_x := fw - wing_w
	ctx.draw_rect_filled(r_x - 2.5, 0, 5.0, fh, glow_col)
	ctx.draw_rect_filled(r_x - 0.75, 0, 1.5, fh, core_col)
}

fn prod_fx_draw_parallax_starfield(ctx &gg.Context, w int, h int, t f64, mode int) {
	if mode == 2 {
		return // Clean HD disables ambient stars
	}
	fw := f64(w)
	fh := f64(h)

	// Layer 0: Distant micro-stars (slow, subtle twinkle)
	for i in 0 .. 32 {
		fi := f64(i)
		seed := math.sin(fi * 14.123) * 43758.54
		frac_x := seed - math.floor(seed)
		seed2 := math.sin(fi * 91.567) * 23421.67
		frac_y := seed2 - math.floor(seed2)

		px := f32(math.fmod(frac_x * fw + t * 4.0, fw))
		py := f32(math.fmod(frac_y * fh + t * 2.0, fh))

		twinkle := 0.5 + 0.5 * math.sin(t * 3.0 + fi * 1.5)
		alpha := u8(25.0 + 35.0 * twinkle)
		ctx.draw_rect_filled(px, py, 1.0, 1.0, gg.Color{r: 200, g: 220, b: 255, a: alpha})
	}

	// Layer 1: Midground drifting stars (2x speed, soft colored tint)
	for i in 0 .. 18 {
		fi := f64(i)
		seed := math.sin(fi * 47.891) * 31245.89
		frac_x := seed - math.floor(seed)
		seed2 := math.sin(fi * 73.234) * 15678.91
		frac_y := seed2 - math.floor(seed2)

		px := f32(math.fmod(frac_x * fw + t * 8.5, fw))
		py := f32(math.fmod(frac_y * fh + t * 4.2, fh))

		twinkle := 0.5 + 0.5 * math.sin(t * 2.4 + fi * 2.1)
		alpha := u8(40.0 + 45.0 * twinkle)
		col := match i % 3 {
			0 { gg.Color{r: 120, g: 200, b: 255, a: alpha} }
			1 { gg.Color{r: 255, g: 210, b: 140, a: alpha} }
			else { gg.Color{r: 220, g: 160, b: 255, a: alpha} }
		}
		ctx.draw_rect_filled(px, py, 1.5, 1.5, col)
	}

	// Layer 2: Foreground cosmic dust motes with 4-point cross shimmer
	for i in 0 .. 8 {
		fi := f64(i)
		seed := math.sin(fi * 83.127) * 54321.12
		frac_x := seed - math.floor(seed)
		seed2 := math.sin(fi * 39.456) * 67891.23
		frac_y := seed2 - math.floor(seed2)

		px := f32(math.fmod(frac_x * fw + t * 14.0, fw))
		py := f32(math.fmod(frac_y * fh + t * 7.0, fh))

		twinkle := 0.5 + 0.5 * math.sin(t * 4.0 + fi * 0.9)
		alpha := u8(55.0 + 55.0 * twinkle)
		glow_col := gg.Color{r: 255, g: 255, b: 255, a: alpha}

		ctx.draw_rect_filled(px - 1.0, py, 3.0, 1.0, glow_col)
		ctx.draw_rect_filled(px, py - 1.0, 1.0, 3.0, glow_col)
	}
}

fn prod_fx_draw_shockwaves(ctx &gg.Context) {
	mut data := [56]f32{} // up to 8 shockwaves * 7 floats
	count := C.get_active_shockwaves_c(&data[0], 8)
	if count <= 0 {
		return
	}

	for i in 0 .. count {
		idx := i * 7
		x := data[idx + 0]
		y := data[idx + 1]
		radius := data[idx + 2]
		life := data[idx + 3]
		r := u8(data[idx + 4])
		g := u8(data[idx + 5])
		b := u8(data[idx + 6])

		alpha := u8(math.max(0.0, math.min(255.0, f64(life * 180.0))))
		ring_col := gg.Color{r: r, g: g, b: b, a: alpha}
		ctx.draw_circle_empty(x, y, radius, ring_col)

		if radius > 12.0 {
			inner_alpha := u8(math.max(0.0, math.min(255.0, f64(life * 100.0))))
			ctx.draw_circle_empty(x, y, radius - 6.0, gg.Color{r: r, g: g, b: b, a: inner_alpha})
		}
	}
}

fn prod_fx_draw_sparks(ctx &gg.Context) {
	mut data := [192]f32{} // 32 sparks * 6 floats
	count := C.get_active_sparks_c(&data[0], 32)
	if count <= 0 {
		return
	}
	for i in 0 .. count {
		idx := i * 6
		x := data[idx + 0]
		y := data[idx + 1]
		life := data[idx + 2]
		r := u8(data[idx + 3])
		g := u8(data[idx + 4])
		b := u8(data[idx + 5])

		alpha := u8(math.max(0.0, math.min(255.0, f64(life * 255.0))))
		// Center spark core
		ctx.draw_rect_filled(x - 1.5, y - 1.5, 3.0, 3.0, gg.Color{r: 255, g: 255, b: 255, a: alpha})
		// Cross glare flares
		ctx.draw_rect_filled(x - 3.5, y - 0.5, 7.0, 1.0, gg.Color{r: r, g: g, b: b, a: u8(alpha / 2)})
		ctx.draw_rect_filled(x - 0.5, y - 3.5, 1.0, 7.0, gg.Color{r: r, g: g, b: b, a: u8(alpha / 2)})
	}
}

fn prod_fx_draw_floating_scores(ctx &gg.Context) {
	mut data := [56]f32{} // 8 floating scores * 7 floats
	count := C.get_active_floating_scores_c(&data[0], 8)
	if count <= 0 {
		return
	}
	for i in 0 .. count {
		idx := i * 7
		x := data[idx + 0]
		y := data[idx + 1]
		score := int(data[idx + 2])
		life := data[idx + 3]
		r := u8(data[idx + 4])
		g := u8(data[idx + 5])
		b := u8(data[idx + 6])

		alpha := u8(math.max(0.0, math.min(255.0, f64(life * 255.0))))
		text := if score > 0 { '+${score}' } else { '${score}' }
		// Drop shadow
		ctx.draw_text(int(x + 1.0), int(y + 1.0), text,
			size:          16
			color:         gg.Color{r: 0, g: 0, b: 0, a: u8(f64(alpha) * 0.75)}
			align:         .center
			vertical_align: .middle
		)
		// Glowing floating text
		ctx.draw_text(int(x), int(y), text,
			size:          16
			color:         gg.Color{r: r, g: g, b: b, a: alpha}
			align:         .center
			vertical_align: .middle
		)
	}
}

fn prod_fx_draw_rgb_aperture_grille(ctx &gg.Context, w int, h int) {
	fh := f32(h)
	// Sony Trinitron PVM vertical RGB phosphor triads
	mut x := 0
	for x < w {
		fx := f32(x)
		ctx.draw_rect_filled(fx, 0, 1.0, fh, gg.Color{r: 255, g: 0, b: 0, a: 5})
		if x + 1 < w {
			ctx.draw_rect_filled(fx + 1.0, 0, 1.0, fh, gg.Color{r: 0, g: 255, b: 0, a: 5})
		}
		if x + 2 < w {
			ctx.draw_rect_filled(fx + 2.0, 0, 1.0, fh, gg.Color{r: 0, g: 0, b: 255, a: 5})
		}
		x += 3
	}
}

fn prod_fx_draw_scanlines(ctx &gg.Context, w int, h int, t f64) {
	scan_col := gg.Color{r: 0, g: 0, b: 0, a: 16}
	fw := f32(w)
	mut y := 0
	for y < h {
		ctx.draw_rect_filled(0, f32(y), fw, 1, scan_col)
		y += 3
	}

	// CRT Electron beam cathode sweep line
	beam_pos := f32((t * 0.22 - math.floor(t * 0.22)) * f64(h))
	beam_col := gg.Color{r: 255, g: 255, b: 255, a: 9}
	ctx.draw_rect_filled(0, beam_pos, fw, 2, beam_col)
}

fn prod_fx_draw_crt_glass_bezel(ctx &gg.Context, w int, h int) {
	fw := f32(w)
	fh := f32(h)

	// Smooth radial corner shadow simulating curved Trinitron CRT glass monitor
	for i in 0 .. 16 {
		inset := f32(i * 3)
		alpha := u8(4 + i * 2)
		col := gg.Color{r: 0, g: 0, b: 0, a: alpha}
		ctx.draw_rect_filled(0, inset, fw, 3, col)
		ctx.draw_rect_filled(0, fh - inset - 3, fw, 3, col)
		ctx.draw_rect_filled(inset, 0, 3, fh, col)
		ctx.draw_rect_filled(fw - inset - 3, 0, 3, fh, col)
	}

	// 4 Distinct Curved Glass Corner Bezels
	corner_rad := f32(28.0)
	dark_corner := gg.Color{r: 0, g: 0, b: 0, a: 210}
	for step := 0; step < 8; step++ {
		offset := f32(step) * 3.5
		ctx.draw_circle_empty(corner_rad, corner_rad, corner_rad + offset, dark_corner)
		ctx.draw_circle_empty(fw - corner_rad, corner_rad, corner_rad + offset, dark_corner)
		ctx.draw_circle_empty(corner_rad, fh - corner_rad, corner_rad + offset, dark_corner)
		ctx.draw_circle_empty(fw - corner_rad, fh - corner_rad, corner_rad + offset, dark_corner)
	}
}

fn prod_fx_draw_specular_sheen(ctx &gg.Context, w int, h int) {
	// 45-degree diagonal specular glass reflection streak on upper-left monitor
	fw := f32(w)
	fh := f32(h)
	diag_len := math.min(fw * 0.35, fh * 0.35)

	sheen_col := gg.Color{r: 255, g: 255, b: 255, a: 6}
	ctx.draw_triangle_filled(0, 0, diag_len, 0, 0, diag_len, sheen_col)

	sheen_core := gg.Color{r: 255, g: 255, b: 255, a: 3}
	ctx.draw_triangle_filled(0, 0, diag_len * 0.6, 0, 0, diag_len * 0.6, sheen_core)
}

fn prod_fx_draw_chromatic_fringe(ctx &gg.Context, w int, h int, t f64) {
	fw := f32(w)
	fh := f32(h)
	pulse := f32(0.5 + 0.5 * math.sin(t * 1.5))

	// Left edge cyan fringe
	cyan_col := gg.Color{r: 0, g: 220, b: 255, a: u8(18.0 + 10.0 * pulse)}
	ctx.draw_rect_filled(0, 0, 2, fh, cyan_col)

	// Right edge magenta fringe
	mag_col := gg.Color{r: 255, g: 40, b: 180, a: u8(18.0 + 10.0 * pulse)}
	ctx.draw_rect_filled(fw - 2, 0, 2, fh, mag_col)
}

fn prod_fx_draw_amber_phosphor(ctx &gg.Context, w int, h int, t f64) {
	// Fullscreen amber phosphor composite warmth tint
	fw := f32(w)
	fh := f32(h)
	pulse := 0.5 + 0.5 * math.sin(t * 1.8)
	amber_alpha := u8(22.0 + 6.0 * pulse)
	amber_col := gg.Color{r: 255, g: 155, b: 25, a: amber_alpha}
	ctx.draw_rect_filled(0, 0, fw, fh, amber_col)
}

fn prod_fx_draw_subtle_frame(ctx &gg.Context, w int, h int) {
	fw := f32(w)
	fh := f32(h)
	edge_col := gg.Color{r: 0, g: 0, b: 0, a: 35}
	ctx.draw_rect_filled(0, 0, fw, 2, edge_col)
	ctx.draw_rect_filled(0, fh - 2, fw, 2, edge_col)
	ctx.draw_rect_filled(0, 0, 2, fh, edge_col)
	ctx.draw_rect_filled(fw - 2, 0, 2, fh, edge_col)
}

fn prod_fx_draw_particles(ctx &gg.Context, w int, h int, t f64, theme int) {
	for i in 0 .. 30 {
		fi := f64(i)
		seed := math.sin(fi * 12.9898) * 43758.5453
		frac := seed - math.floor(seed)
		speed := 0.08 + frac * 0.14
		phase := frac + t * speed
		py := f32((phase - math.floor(phase)) * f64(h))
		px := f32((0.5 + 0.48 * math.sin(fi * 2.31 + t * 0.18)) * f64(w))
		pulse := 0.5 + 0.5 * math.sin(t * 2.2 + fi * 1.7)
		glow := u8(60.0 + 80.0 * pulse)
		size := f32(1.5 + (i % 3) * 0.75)
		alpha := u8(30.0 + 40.0 * pulse)

		col := if theme == 1 { // Cyber bloom vibrant motes
			match i % 4 {
				0 { gg.Color{r: 0, g: 240, b: 255, a: alpha} }
				1 { gg.Color{r: 255, g: 50, b: 180, a: alpha} }
				2 { gg.Color{r: 255, g: 220, b: 60, a: alpha} }
				else { gg.Color{r: 160, g: 80, b: 255, a: alpha} }
			}
		} else { // Classic arcade CRT motes
			match i % 4 {
				0 { gg.Color{r: glow, g: u8(int(glow) * 3 / 4 + 60), b: 255, a: alpha} }
				1 { gg.Color{r: 255, g: glow, b: 120, a: alpha} }
				2 { gg.Color{r: glow, g: 255, b: 180, a: alpha} }
				else { gg.Color{r: 200, g: 150, b: 255, a: alpha} }
			}
		}
		ctx.draw_rect_filled(px - size, py - size, size * 2, size * 2, col)
	}
}

fn prod_fx_draw_osd(ctx &gg.Context, w int, _h int, t f64, mode int) {
	fw := f32(w)
	mode_label := match mode {
		0 { 'ARCADE CRT PRO' }
		1 { 'CYBER BLOOM' }
		2 { 'CLEAN HD' }
		else { 'VINTAGE AMBER' }
	}

	mode_icon := match mode {
		0 { 'CRT' }
		1 { 'NEON' }
		2 { 'HD' }
		else { 'AMBER' }
	}

	// 1. Top-Right Clickable FX Badge in the Wing Header
	badge_w := f32(148.0)
	badge_h := f32(24.0)
	badge_x := fw - badge_w - 18.0
	badge_y := f32(12.0)

	ctx.draw_rounded_rect_filled(badge_x, badge_y, badge_w, badge_h, 6.0, gg.Color{r: 15, g: 20, b: 32, a: 210})
	ctx.draw_rounded_rect_empty(badge_x, badge_y, badge_w, badge_h, 6.0, gg.Color{r: 0, g: 220, b: 255, a: 160})
	ctx.draw_text(int(badge_x + badge_w / 2.0), int(badge_y + badge_h / 2.0), '[F10] ${mode_icon}',
		size:          12
		color:         gg.Color{r: 180, g: 240, b: 255, a: 255}
		align:         .center
		vertical_align: .middle
	)

	// 2. Animated Toast Banner sliding down on mode change
	toast_until := C.get_fx_toast_until_c()
	if t < toast_until {
		time_left := toast_until - t
		alpha_factor := if time_left < 0.4 { time_left / 0.4 } else { 1.0 }
		alpha := u8(math.min(255.0, 240.0 * alpha_factor))

		toast_w := f32(320.0)
		toast_h := f32(38.0)
		toast_x := (fw - toast_w) / 2.0
		toast_y := f32(24.0 + (1.0 - alpha_factor) * -15.0)

		// Pill shadow & card body
		ctx.draw_rounded_rect_filled(toast_x, toast_y, toast_w, toast_h, 10.0, gg.Color{r: 10, g: 15, b: 25, a: alpha})
		ctx.draw_rounded_rect_empty(toast_x, toast_y, toast_w, toast_h, 10.0, gg.Color{r: 0, g: 220, b: 255, a: alpha})

		ctx.draw_text(int(toast_x + toast_w / 2.0), int(toast_y + 13.0), 'DISPLAY PROFILE: ${mode_label}',
			size:          14
			color:         gg.Color{r: 255, g: 235, b: 120, a: alpha}
			align:         .center
			vertical_align: .middle
		)
		ctx.draw_text(int(toast_x + toast_w / 2.0), int(toast_y + 27.0), 'PRESS [F10] OR [O] TO CYCLE FILTER',
			size:          10
			color:         gg.Color{r: 160, g: 200, b: 240, a: alpha}
			align:         .center
			vertical_align: .middle
		)
	}
}
