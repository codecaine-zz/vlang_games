module main

import math
import rand

pub const cube_w = 64.0
pub const cube_h = 48.0
pub const pyramid_apex_x = 420.0
pub const pyramid_apex_y = 130.0

pub fn get_isometric_cube_pos(r int, c int) (f64, f64) {
	cx := pyramid_apex_x + (f64(c) - f64(r) * 0.5) * cube_w
	cy := pyramid_apex_y + f64(r) * cube_h
	return cx, cy
}

pub fn draw_isometric_cube(renderer &Renderer, cx f64, cy f64, state int) {
	// Top Face (Diamond)
	top_col := if state == 1 { Color{r: 255, g: 215, b: 0} } else { Color{r: 30, g: 140, b: 240} } // Gold vs Blue
	left_col := Color{r: 15, g: 50, b: 140}
	right_col := Color{r: 120, g: 30, b: 150}

	icx := int(cx)
	icy := int(cy)
	hw := int(cube_w / 2.0)
	hh := int(cube_h / 2.0)

	// Top Diamond Face
	set_render_draw_color(renderer, top_col.r, top_col.g, top_col.b, 255)
	for dy := -hh; dy <= hh; dy++ {
		dx_max := hw - int(math.abs(f64(dy)) * f64(hw) / f64(hh))
		render_draw_line(renderer, icx - dx_max, icy + dy, icx + dx_max, icy + dy)
	}
	set_render_draw_color(renderer, 255, 255, 255, 120)
	render_draw_line(renderer, icx - hw, icy, icx, icy - hh)
	render_draw_line(renderer, icx, icy - hh, icx + hw, icy)

	// Left Parallelogram Face
	set_render_draw_color(renderer, left_col.r, left_col.g, left_col.b, 255)
	for dy := 0; dy <= hh; dy++ {
		dx_max := int(f64(dy) * f64(hw) / f64(hh))
		render_draw_line(renderer, icx - hw + dx_max, icy + dy, icx - hw + dx_max, icy + dy + hh)
	}

	// Right Parallelogram Face
	set_render_draw_color(renderer, right_col.r, right_col.g, right_col.b, 255)
	for dy := 0; dy <= hh; dy++ {
		dx_max := int(f64(dy) * f64(hw) / f64(hh))
		render_draw_line(renderer, icx + dx_max, icy + hh - dy, icx + dx_max, icy + 2 * hh - dy)
	}

	// Black Edges
	set_render_draw_color(renderer, 10, 15, 30, 255)
	render_draw_line(renderer, icx - hw, icy, icx, icy + hh)
	render_draw_line(renderer, icx, icy + hh, icx + hw, icy)
	render_draw_line(renderer, icx, icy + hh, icx, icy + 2 * hh)
	render_draw_line(renderer, icx - hw, icy + hh, icx, icy + 2 * hh)
	render_draw_line(renderer, icx, icy + 2 * hh, icx + hw, icy + hh)
}

pub fn draw_qbert_actor(renderer &Renderer, r int, c int, from_r int, from_c int, t f64, is_cursing bool) {
	start_x, start_y := get_isometric_cube_pos(from_r, from_c)
	end_x, end_y := get_isometric_cube_pos(r, c)

	// Parabolic hop arc
	cur_x := start_x + (end_x - start_x) * t
	hop_h := math.sin(t * math.pi) * 28.0
	cur_y := start_y + (end_y - start_y) * t - hop_h - 18.0

	ix := int(cur_x)
	iy := int(cur_y)

	// Q*bert Orange Body
	set_render_draw_color(renderer, 245, 120, 25, 255)
	for dy := -12; dy <= 12; dy++ {
		dx_max := int(math.sqrt(f64(144 - dy * dy)))
		render_draw_line(renderer, ix - dx_max, iy + dy, ix + dx_max, iy + dy)
	}

	// Long Snout (Tubular Nose)
	set_render_draw_color(renderer, 235, 90, 20, 255)
	render_fill_rect(renderer, &Rect{x: ix - 18, y: iy + 2, w: 10, h: 8})
	set_render_draw_color(renderer, 40, 10, 5, 255)
	render_fill_rect(renderer, &Rect{x: ix - 19, y: iy + 4, w: 3, h: 4})

	// Big Cartoon Eyes
	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_fill_rect(renderer, &Rect{x: ix - 6, y: iy - 14, w: 6, h: 8})
	render_fill_rect(renderer, &Rect{x: ix + 2, y: iy - 14, w: 6, h: 8})

	set_render_draw_color(renderer, 10, 10, 10, 255)
	render_fill_rect(renderer, &Rect{x: ix - 4, y: iy - 11, w: 3, h: 4})
	render_fill_rect(renderer, &Rect{x: ix + 4, y: iy - 11, w: 3, h: 4})

	// Cute Red Shoes
	set_render_draw_color(renderer, 220, 30, 40, 255)
	render_fill_rect(renderer, &Rect{x: ix - 10, y: iy + 12, w: 8, h: 5})
	render_fill_rect(renderer, &Rect{x: ix + 2, y: iy + 12, w: 8, h: 5})

	// Curse Comic Speech Bubble
	if is_cursing {
		bubble_w := 90
		bubble_h := 26
		bx := ix - bubble_w / 2
		by := iy - 48
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_fill_rect(renderer, &Rect{x: bx, y: by, w: bubble_w, h: bubble_h})
		set_render_draw_color(renderer, 20, 20, 20, 255)
		render_draw_rect(renderer, &Rect{x: bx, y: by, w: bubble_w, h: bubble_h})
		draw_text_centered(renderer, ix, by + 5, '@!#?@!', 2, Color{r: 220, g: 30, b: 30})
	}
}

pub fn draw_coily_actor(renderer &Renderer, r int, c int, from_r int, from_c int, t f64, hatched bool) {
	start_x, start_y := get_isometric_cube_pos(from_r, from_c)
	end_x, end_y := get_isometric_cube_pos(r, c)
	cur_x := start_x + (end_x - start_x) * t
	hop_h := math.sin(t * math.pi) * 24.0
	cur_y := start_y + (end_y - start_y) * t - hop_h - 16.0
	ix := int(cur_x)
	iy := int(cur_y)

	if !hatched {
		// Purple Egg
		set_render_draw_color(renderer, 170, 60, 220, 255)
		for dy := -10; dy <= 10; dy++ {
			dx_max := int(math.sqrt(f64(100 - dy * dy)) * 0.9)
			render_draw_line(renderer, ix - dx_max, iy + dy, ix + dx_max, iy + dy)
		}
	} else {
		// Coiled Purple Snake
		set_render_draw_color(renderer, 150, 40, 200, 255)
		render_fill_rect(renderer, &Rect{x: ix - 8, y: iy - 10, w: 16, h: 20})
		// Snake Eyes
		set_render_draw_color(renderer, 255, 230, 40, 255)
		render_fill_rect(renderer, &Rect{x: ix - 6, y: iy - 8, w: 4, h: 4})
		render_fill_rect(renderer, &Rect{x: ix + 2, y: iy - 8, w: 4, h: 4})
		// Red Tongue
		set_render_draw_color(renderer, 240, 30, 40, 255)
		render_draw_line(renderer, ix, iy - 2, ix, iy + 6)
	}
}

pub fn draw_red_ball(renderer &Renderer, r int, c int, from_r int, from_c int, t f64) {
	start_x, start_y := get_isometric_cube_pos(from_r, from_c)
	end_x, end_y := get_isometric_cube_pos(r, c)
	cur_x := start_x + (end_x - start_x) * t
	hop_h := math.sin(t * math.pi) * 22.0
	cur_y := start_y + (end_y - start_y) * t - hop_h - 14.0
	ix := int(cur_x)
	iy := int(cur_y)

	set_render_draw_color(renderer, 235, 40, 50, 255)
	for dy := -8; dy <= 8; dy++ {
		dx_max := int(math.sqrt(f64(64 - dy * dy)))
		render_draw_line(renderer, ix - dx_max, iy + dy, ix + dx_max, iy + dy)
	}
	// Highlight
	set_render_draw_color(renderer, 255, 180, 190, 255)
	render_fill_rect(renderer, &Rect{x: ix - 4, y: iy - 4, w: 3, h: 3})
}

pub fn render_qbert_game(renderer &Renderer, game &QbertGame, win_w int, win_h int) {
	// Deep Arcade Space Background
	set_render_draw_color(renderer, 8, 8, 18, 255)
	render_clear(renderer)

	mut sx := 0
	mut sy := 0
	if game.shake_trauma > 0 {
		trauma_pwr := game.shake_trauma * game.shake_trauma
		max_offset := f32(18.0) * trauma_pwr
		sx = int((rand.f32() * 2.0 - 1.0) * max_offset)
		sy = int((rand.f32() * 2.0 - 1.0) * max_offset)
		unsafe {
			renderer.offset_x += sx
			renderer.offset_y += sy
		}
	}
	defer {
		if sx != 0 || sy != 0 {
			unsafe {
				renderer.offset_x -= sx
				renderer.offset_y -= sy
			}
		}
	}

	// Draw 28 Isometric Cubes
	for r in 0 .. pyramid_rows {
		for c in 0 .. r + 1 {
			idx := get_cube_index(r, c)
			if idx != -1 {
				cx, cy := get_isometric_cube_pos(r, c)
				draw_isometric_cube(renderer, cx, cy, game.cubes[idx])
			}
		}
	}

	// Draw Escape Discs
	for disc in game.discs {
		if disc.active {
			dx, dy := get_isometric_cube_pos(disc.r, disc.c)
			set_render_draw_color(renderer, 255, 215, 0, 255)
			idx := int(dx)
			idy := int(dy) - 10
			for d_dy := -6; d_dy <= 6; d_dy++ {
				dx_max := int(math.sqrt(f64(36 - d_dy * d_dy)) * 2.2)
				render_draw_line(renderer, idx - dx_max, idy + d_dy, idx + dx_max, idy + d_dy)
			}
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_draw_line(renderer, idx - 8, idy, idx + 8, idy)
		}
	}

	// Draw Enemies
	if game.red_ball.is_alive {
		draw_red_ball(renderer, game.red_ball.r, game.red_ball.c, game.red_ball.from_r, game.red_ball.from_c, game.red_ball.anim_t)
	}
	if game.coily.is_alive {
		draw_coily_actor(renderer, game.coily.r, game.coily.c, game.coily.from_r, game.coily.from_c, game.coily.anim_t, game.coily_hatched)
	}

	// Draw Q*bert Player
	if game.player.is_alive {
		draw_qbert_actor(renderer, game.player.r, game.player.c, game.player.from_r, game.player.from_c, game.player.anim_t, game.state == .cursing)
	}

	// Left HUD: Target Indicator & Lives
	draw_text(renderer, 40, 30, 'CHANGE TO:', 2, Color{r: 180, g: 190, b: 220})
	draw_isometric_cube(renderer, 85, 95, 1) // Target gold cube sample

	draw_text(renderer, 40, 160, 'LIVES: ${game.lives}', 2, Color{r: 255, g: 215, b: 0})
	draw_text(renderer, 40, 190, 'ROUND: ${game.round_num}', 2, Color{r: 140, g: 180, b: 240})

	// Center Top Title
	draw_text_centered(renderer, win_w / 2, 25, 'Q*BERT', 3, Color{r: 255, g: 140, b: 30})

	// Right HUD: Score & Controls
	draw_text(renderer, win_w - 240, 30, 'SCORE', 2, Color{r: 180, g: 190, b: 220})
	draw_text(renderer, win_w - 240, 55, '${game.score}', 3, Color{r: 255, g: 255, b: 255})

	draw_text(renderer, win_w - 240, 100, 'HIGH SCORE', 2, Color{r: 180, g: 190, b: 220})
	draw_text(renderer, win_w - 240, 125, '${game.high_score}', 3, Color{r: 255, g: 215, b: 0})

	draw_text(renderer, win_w - 220, 175, 'CONTROLS (DIAGONAL):', 1, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, win_w - 220, 195, '[Q / 7] UP-LEFT', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, win_w - 220, 212, '[E / 9] UP-RIGHT', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, win_w - 220, 229, '[A / 1] DOWN-LEFT', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, win_w - 220, 246, '[D / 3] DOWN-RIGHT', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, win_w - 220, 268, '[ARROWS/WASD] SUPPORTED', 1, Color{r: 140, g: 160, b: 200})

	// Round Clear / Game Over Overlays
	if game.state == .level_cleared || game.state == .game_over {
		set_render_draw_color(renderer, 0, 0, 0, 190)
		render_fill_rect(renderer, &Rect{x: 0, y: 0, w: win_w, h: win_h})

		mx := (win_w - 440) / 2
		my := (win_h - 220) / 2
		set_render_draw_color(renderer, 20, 26, 44, 255)
		modal_rect := Rect{x: mx, y: my, w: 440, h: 220}
		render_fill_rect(renderer, &modal_rect)
		set_render_draw_color(renderer, 70, 90, 160, 255)
		render_draw_rect(renderer, &modal_rect)

		if game.state == .level_cleared {
			draw_text_centered(renderer, win_w / 2, my + 30, 'PYRAMID CLEARED!', 3, Color{r: 255, g: 215, b: 0})
			draw_text_centered(renderer, win_w / 2, my + 75, 'ALL CUBES CONVERTED!', 2, Color{r: 80, g: 255, b: 120})
			draw_text_centered(renderer, win_w / 2, my + 120, 'SCORE: ${game.score}', 2, Color{r: 255, g: 255, b: 255})
			draw_text_centered(renderer, win_w / 2, my + 165, 'PRESS [SPACE] FOR NEXT ROUND', 2, Color{r: 140, g: 180, b: 240})
		} else {
			draw_text_centered(renderer, win_w / 2, my + 30, 'GAME OVER', 3, Color{r: 255, g: 60, b: 60})
			draw_text_centered(renderer, win_w / 2, my + 75, '@!#?@! NO LIVES LEFT!', 2, Color{r: 240, g: 120, b: 120})
			draw_text_centered(renderer, win_w / 2, my + 120, 'FINAL SCORE: ${game.score}', 2, Color{r: 255, g: 255, b: 255})
			draw_text_centered(renderer, win_w / 2, my + 165, 'PRESS [SPACE] OR [R] TO RETRY', 2, Color{r: 140, g: 180, b: 240})
		}
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}
