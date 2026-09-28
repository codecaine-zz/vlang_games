module main

import math
import os
import time

pub struct SimonTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm SimonTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/simon.png',
		'./assets/sprites/simon.png',
		'../assets/sprites/simon.png',
		'simon/assets/sprites/simon.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('simon Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn render_simon_console(renderer &Renderer, game &SimonGame, screen_w int, screen_h int, mouse_x int, mouse_y int, tex &Texture) {
	// Deep cyber arcade background
	set_render_draw_color(renderer, 10, 12, 20, 255)
	render_clear(renderer)

	ticks := u32(time.ticks())

	// 1. Perspective Cyber Horizon Grid & Floating Dust
	set_render_draw_blend_mode(renderer, .blend)
	set_render_draw_color(renderer, 24, 32, 54, 180)
	for y := 60; y < screen_h; y += 40 {
		render_draw_line(renderer, 0, y, screen_w, y)
	}
	for x := 0; x < screen_w; x += 50 {
		render_draw_line(renderer, x, 48, x, screen_h)
	}

	cx := screen_w / 2
	cy := screen_h / 2 + 10
	outer_rad := 200
	inner_rad := 85

	// 2. Dynamic Radial Ambient Neon Glow when Pad is active
	if game.lit_pad >= 0 && game.lit_pad < 4 {
		glow_colors := [
			Color{r: 34, g: 197, b: 94},  // Green
			Color{r: 239, g: 68, b: 68},  // Red
			Color{r: 234, g: 179, b: 8},  // Yellow
			Color{r: 59, g: 130, b: 246}, // Blue
		]
		gc := glow_colors[game.lit_pad]
		for gr := 280; gr >= 180; gr -= 20 {
			alpha := u8((280 - gr) * 2)
			set_render_draw_color(renderer, gc.r, gc.g, gc.b, alpha)
			fill_circle(renderer, cx, cy, gr)
		}
	}

	// 3. Audio-Reactive VU Meter Equalizer Strobe along Outer Rim
	for angle_i := 0; angle_i < 36; angle_i++ {
		ang_rad := f64(angle_i) * (2.0 * math.pi / 36.0)
		vu_pulse := int(math.sin(f64(ticks) * 0.008 + f64(angle_i)) * 6.0)
		bar_r1 := outer_rad + 28
		bar_r2 := bar_r1 + 6 + int(math.max(0, vu_pulse))
		bx1 := cx + int(f64(bar_r1) * math.cos(ang_rad))
		by1 := cy + int(f64(bar_r1) * math.sin(ang_rad))
		bx2 := cx + int(f64(bar_r2) * math.cos(ang_rad))
		by2 := cy + int(f64(bar_r2) * math.sin(ang_rad))
		set_render_draw_color(renderer, 0, 220, 255, 160)
		render_draw_line(renderer, bx1, by1, bx2, by2)
	}

	// 4. Outer Console Chasis (Multi-layered Brushed Titanium & Chrome)
	set_render_draw_blend_mode(renderer, .none)
	set_render_draw_color(renderer, 20, 22, 30, 255)
	fill_circle(renderer, cx, cy, outer_rad + 24)

	set_render_draw_color(renderer, 48, 54, 70, 255)
	fill_circle(renderer, cx, cy, outer_rad + 14)

	set_render_draw_color(renderer, 14, 16, 22, 255)
	fill_circle(renderer, cx, cy, outer_rad + 4)

	// Neon Rim Bevel Ring
	set_render_draw_color(renderer, 70, 80, 110, 255)
	draw_circle(renderer, cx, cy, outer_rad + 3)

	// 5. Draw the 4 Frosted Neon Quadrant Pads
	pad_colors_off := [
		Color{r: 20, g: 100, b: 40},   // Green Off
		Color{r: 140, g: 25, b: 35},   // Red Off
		Color{r: 150, g: 120, b: 20},  // Yellow Off
		Color{r: 20, g: 55, b: 140},   // Blue Off
	]

	pad_colors_lit := [
		Color{r: 74, g: 255, b: 120},  // Green Lit
		Color{r: 255, g: 70, b: 85},   // Red Lit
		Color{r: 255, g: 245, b: 80},  // Yellow Lit
		Color{r: 80, g: 180, b: 255},  // Blue Lit
	]

	for pad_idx in 0 .. 4 {
		is_lit := game.lit_pad == pad_idx
		base_col := if is_lit { pad_colors_lit[pad_idx] } else { pad_colors_off[pad_idx] }

		draw_quadrant_pad(renderer, cx, cy, inner_rad, outer_rad, pad_idx, base_col, is_lit)

		if is_lit && tex != unsafe { nil } {
			pad_pos_x := if pad_idx == 0 || pad_idx == 2 { cx - 140 } else { cx + 90 }
			pad_pos_y := if pad_idx == 0 || pad_idx == 1 { cy - 140 } else { cy + 90 }
			src := Rect{x: pad_idx * 64, y: 0, w: 64, h: 64}
			dst := Rect{x: pad_pos_x, y: pad_pos_y, w: 50, h: 50}
			render_copy(renderer, tex, &src, &dst)
		}
	}

	// 6. Black Chamfered Separator Cross Spoke Lines
	set_render_draw_color(renderer, 10, 11, 16, 255)
	render_fill_rect(renderer, &Rect{x: cx - 6, y: cy - outer_rad - 6, w: 12, h: (outer_rad + 6) * 2})
	render_fill_rect(renderer, &Rect{x: cx - outer_rad - 6, y: cy - 6, w: (outer_rad + 6) * 2, h: 12})

	// 7. Center Console Hub (Obsidian disc with Gold/Chrome Rim)
	set_render_draw_color(renderer, 35, 40, 52, 255)
	fill_circle(renderer, cx, cy, inner_rad + 6)

	set_render_draw_color(renderer, 245, 195, 30, 255)
	draw_circle(renderer, cx, cy, inner_rad + 5)

	set_render_draw_color(renderer, 15, 17, 24, 255)
	fill_circle(renderer, cx, cy, inner_rad)

	set_render_draw_color(renderer, 55, 62, 85, 255)
	draw_circle(renderer, cx, cy, inner_rad)

	if tex != unsafe { nil } {
		// Center Badge
		src_badge := Rect{x: 0, y: 64, w: 64, h: 64}
		dst_badge := Rect{x: cx - 18, y: cy - 70, w: 36, h: 36}
		render_copy(renderer, tex, &src_badge, &dst_badge)
	} else {
		// Center Logo & LED Score Display
		draw_text_centered(renderer, cx, cy - 58, 'CYBER SIMON', 1, Color{r: 255, g: 215, b: 0})
	}

	// 8. 7-Segment Style LED Box with Cyan Phosphor
	led_rect := Rect{x: cx - 44, y: cy - 36, w: 88, h: 36}
	set_render_draw_color(renderer, 6, 8, 14, 255)
	render_fill_rect(renderer, &led_rect)
	set_render_draw_color(renderer, 0, 220, 255, 200)
	render_draw_rect(renderer, &led_rect)

	score_str := if game.sequence.len > 0 { '${game.sequence.len:02d}' } else { '--' }
	draw_text_centered(renderer, cx, cy - 28, score_str, 2, Color{r: 0, g: 255, b: 240})

	// Status Prompt text inside hub
	status_text := match game.state {
		.attract { 'PRESS SPACE' }
		.playback { 'OBSERVE...' }
		.player_turn { 'YOUR TURN!' }
		.round_success { 'PERFECT!' }
		.game_over { 'SEQUENCE OVER' }
	}
	status_col := match game.state {
		.playback { Color{r: 255, g: 210, b: 60} }
		.player_turn { Color{r: 60, g: 255, b: 140} }
		.round_success { Color{r: 80, g: 240, b: 255} }
		.game_over { Color{r: 255, g: 70, b: 70} }
		else { Color{r: 200, g: 210, b: 240} }
	}
	draw_text_centered(renderer, cx, cy + 12, status_text, 1, status_col)

	// Mode Pill inside hub
	mode_label := match game.mode {
		.classic { 'CLASSIC' }
		.reverse { 'REVERSE' }
		.speed { 'SPEED' }
	}
	draw_text_centered(renderer, cx, cy + 34, '[M] ${mode_label}', 1, Color{r: 0, g: 220, b: 255})

	// 9. Pad Keyboard Labels on outer ring
	draw_text_centered(renderer, cx - 130, cy - 130, '[Q / 1]', 1, Color{r: 140, g: 255, b: 160})
	draw_text_centered(renderer, cx + 130, cy - 130, '[W / 2]', 1, Color{r: 255, g: 140, b: 150})
	draw_text_centered(renderer, cx - 130, cy + 120, '[A / 3]', 1, Color{r: 255, g: 240, b: 140})
	draw_text_centered(renderer, cx + 130, cy + 120, '[S / 4]', 1, Color{r: 140, g: 200, b: 255})

	// 10. Top Header & High Scores Bar
	hud_h := 48
	set_render_draw_color(renderer, 10, 12, 18, 255)
	render_fill_rect(renderer, &Rect{x: 0, y: 0, w: screen_w, h: hud_h})
	set_render_draw_color(renderer, 0, 200, 255, 120)
	render_draw_line(renderer, 0, hud_h, screen_w, hud_h)

	draw_text(renderer, 24, 16, 'CYBER SIMON PRO', 2, Color{r: 255, g: 215, b: 0})

	cur_hs := match game.mode {
		.classic { game.high_score_classic }
		.reverse { game.high_score_reverse }
		.speed { game.high_score_speed }
	}
	draw_text(renderer, screen_w - 360, 16, 'RECORD: ${cur_hs}  STREAK: ${game.streak}', 2, Color{r: 0, g: 240, b: 255})

	// 11. Bottom Instructions Footer
	footer_y := screen_h - 28
	draw_text_centered(renderer, screen_w / 2, footer_y, '[CLICK/KEYS 1-4/Q-S] PLAY PAD  [SPACE] START  [M] MODE  [R] RESET  [S] SOUND  [F11] Fullscreen', 1, Color{r: 180, g: 195, b: 230})

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}

fn draw_quadrant_pad(renderer &Renderer, cx int, cy int, inner_r int, outer_r int, quad int, col Color, is_lit bool) {
	start_deg := match quad {
		0 { 182.0 }
		1 { 272.0 }
		2 { 92.0 }
		else { 2.0 }
	}
	end_deg := start_deg + 86.0

	bands := 3
	step := 2.0
	r_total := f32(outer_r - (inner_r + 4))

	for b_idx := 0; b_idx < bands; b_idx++ {
		r1 := f32(inner_r + 4) + r_total * (f32(b_idx) / f32(bands))
		r2 := f32(inner_r + 4) + r_total * (f32(b_idx + 1) / f32(bands))

		// Color brightness based on band
		dist_from_mid := math.abs(f64(b_idx) - 1.0) / 1.5
		mut r_val := f64(col.r)
		mut g_val := f64(col.g)
		mut b_val := f64(col.b)

		if is_lit {
			core_factor := math.max(0.0, 1.0 - dist_from_mid * 1.5)
			r_val = math.min(255.0, r_val + core_factor * 120.0)
			g_val = math.min(255.0, g_val + core_factor * 120.0)
			b_val = math.min(255.0, b_val + core_factor * 120.0)
		} else {
			brightness := 0.75 + (1.0 - dist_from_mid) * 0.25
			r_val *= brightness
			g_val *= brightness
			b_val *= brightness
		}

		set_render_draw_color(renderer, u8(r_val), u8(g_val), u8(b_val), 255)

		mut deg := start_deg
		for deg < end_deg {
			next_deg := math.min(deg + step, end_deg)
			rad1 := (deg * math.pi) / 180.0
			rad2 := (next_deg * math.pi) / 180.0

			cos1 := f32(math.cos(rad1))
			sin1 := f32(math.sin(rad1))
			cos2 := f32(math.cos(rad2))
			sin2 := f32(math.sin(rad2))

			p1_x := f32(cx) + r1 * cos1
			p1_y := f32(cy) + r1 * sin1
			p2_x := f32(cx) + r2 * cos1
			p2_y := f32(cy) + r2 * sin1
			p3_x := f32(cx) + r2 * cos2
			p3_y := f32(cy) + r2 * sin2
			p4_x := f32(cx) + r1 * cos2
			p4_y := f32(cy) + r1 * sin2

			render_fill_triangle(renderer, p1_x, p1_y, p2_x, p2_y, p3_x, p3_y)
			render_fill_triangle(renderer, p1_x, p1_y, p3_x, p3_y, p4_x, p4_y)
			deg += step
		}
	}
}

fn fill_circle(renderer &Renderer, cx int, cy int, radius int) {
	render_fill_circle(renderer, f32(cx), f32(cy), f32(radius))
}

fn draw_circle(renderer &Renderer, cx int, cy int, radius int) {
	render_draw_circle(renderer, f32(cx), f32(cy), f32(radius))
}

pub fn get_pad_under_mouse(cx int, cy int, inner_r int, outer_r int, mx int, my int) int {
	dx := mx - cx
	dy := my - cy
	dist_sq := dx * dx + dy * dy
	if dist_sq < (inner_r + 4) * (inner_r + 4) || dist_sq > outer_r * outer_r {
		return -1
	}

	// Calculate angle in degrees [0..360)
	mut angle := (math.atan2(f64(dy), f64(dx)) * 180.0) / math.pi
	if angle < 0.0 {
		angle += 360.0
	}

	if angle >= 180.0 && angle < 270.0 {
		return 0 // Green (Top-Left)
	} else if angle >= 270.0 && angle < 360.0 {
		return 1 // Red (Top-Right)
	} else if angle >= 90.0 && angle < 180.0 {
		return 2 // Yellow (Bottom-Left)
	} else if angle >= 0.0 && angle < 90.0 {
		return 3 // Blue (Bottom-Right)
	}
	return -1
}
