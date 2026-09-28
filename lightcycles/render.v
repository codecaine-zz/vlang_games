module main

import math
import rand

pub struct CrashParticle {
pub mut:
	x        f64
	y        f64
	dx       f64
	dy       f64
	life     f64
	max_life f64
	color    Color
	size     f64
}

pub fn create_crash_particles(cx f64, cy f64, col Color) []CrashParticle {
	mut parts := []CrashParticle{cap: 60}
	for _ in 0 .. 50 {
		angle := (f64(rand.intn(360) or { 0 }) * math.pi) / 180.0
		speed := 50.0 + f64(rand.intn(220) or { 100 })
		life := 0.5 + f64(rand.intn(40) or { 20 }) / 100.0
		parts << CrashParticle{
			x:        cx
			y:        cy
			dx:       math.cos(angle) * speed
			dy:       math.sin(angle) * speed
			life:     life
			max_life: life
			color:    col
			size:     3.0 + f64(rand.intn(4) or { 2 })
		}
	}
	return parts
}

pub fn update_crash_particles(mut particles []CrashParticle, dt f64) {
	for mut p in particles {
		p.x += p.dx * dt
		p.y += p.dy * dt
		p.life -= dt
	}
	mut alive := []CrashParticle{cap: particles.len}
	for p in particles {
		if p.life > 0 {
			alive << p
		}
	}
	particles = alive.clone()
}

pub fn render_crash_particles(renderer &Renderer, particles []CrashParticle) {
	for p in particles {
		alpha := u8(math.clamp(p.life / p.max_life * 255.0, 0, 255))
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		sz := int(p.size)
		rect := Rect{x: int(p.x) - sz / 2, y: int(p.y) - sz / 2, w: sz, h: sz}
		render_fill_rect(renderer, &rect)
	}
}

pub fn render_lightcycles_arena(renderer &Renderer, game &LightCyclesGame, win_w int, win_h int, particles []CrashParticle) {
	// Dark Grid Arena Background
	set_render_draw_color(renderer, 8, 10, 18, 255)
	render_clear(renderer)

	// Arena boundaries
	arena_pad_x := 30
	arena_pad_y := 75
	arena_w := win_w - arena_pad_x * 2
	arena_h := win_h - arena_pad_y - 45

	cell_w := f64(arena_w) / f64(game.cols)
	cell_h := f64(arena_h) / f64(game.rows)

	// Glowing Cyber Grid Lines
	set_render_draw_color(renderer, 20, 26, 42, 255)
	for r := 0; r < game.rows; r += 5 {
		gy := arena_pad_y + int(f64(r) * cell_h)
		render_draw_line(renderer, arena_pad_x, gy, arena_pad_x + arena_w, gy)
	}
	for c := 0; c < game.cols; c += 5 {
		gx := arena_pad_x + int(f64(c) * cell_w)
		render_draw_line(renderer, gx, arena_pad_y, gx, arena_pad_y + arena_h)
	}

	// Arena Border Neon Wall
	set_render_draw_color(renderer, 70, 90, 140, 255)
	render_draw_rect(renderer, &Rect{
		x: arena_pad_x
		y: arena_pad_y
		w: arena_w
		h: arena_h
	})

	// Render Light Trails
	p1_trail_color := Color{r: 30, g: 220, b: 255}
	p2_trail_color := Color{r: 255, g: 110, b: 30}

	for r in 0 .. game.rows {
		for c in 0 .. game.cols {
			val := game.grid[r][c]
			if val == 1 {
				// P1 Trail
				set_render_draw_color(renderer, p1_trail_color.r, p1_trail_color.g, p1_trail_color.b, 255)
				tx := arena_pad_x + int(f64(c) * cell_w)
				ty := arena_pad_y + int(f64(r) * cell_h)
				rect := Rect{x: tx, y: ty, w: int(cell_w) + 1, h: int(cell_h) + 1}
				render_fill_rect(renderer, &rect)
			} else if val == 2 {
				// P2 Trail
				set_render_draw_color(renderer, p2_trail_color.r, p2_trail_color.g, p2_trail_color.b, 255)
				tx := arena_pad_x + int(f64(c) * cell_w)
				ty := arena_pad_y + int(f64(r) * cell_h)
				rect := Rect{x: tx, y: ty, w: int(cell_w) + 1, h: int(cell_h) + 1}
				render_fill_rect(renderer, &rect)
			}
		}
	}

	// Render Light Cycle Heads
	// P1 Head
	p1_hx := arena_pad_x + int(f64(game.p1.c) * cell_w)
	p1_hy := arena_pad_y + int(f64(game.p1.r) * cell_h)
	set_render_draw_color(renderer, 255, 255, 255, 255)
	p1_head_rect := Rect{x: p1_hx - 2, y: p1_hy - 2, w: int(cell_w) + 4, h: int(cell_h) + 4}
	render_fill_rect(renderer, &p1_head_rect)

	// P2 Head
	p2_hx := arena_pad_x + int(f64(game.p2.c) * cell_w)
	p2_hy := arena_pad_y + int(f64(game.p2.r) * cell_h)
	set_render_draw_color(renderer, 255, 255, 255, 255)
	p2_head_rect := Rect{x: p2_hx - 2, y: p2_hy - 2, w: int(cell_w) + 4, h: int(cell_h) + 4}
	render_fill_rect(renderer, &p2_head_rect)

	// Particles
	render_crash_particles(renderer, particles)

	// Top HUD
	// P1 Info
	draw_text(renderer, arena_pad_x, 15, 'P1: CYAN', 2, p1_trail_color)
	draw_text(renderer, arena_pad_x, 38, 'SCORE: ${game.p1_score}', 2, Color{r: 255, g: 255, b: 255})
	// P1 Boost Bar
	set_render_draw_color(renderer, 30, 40, 60, 255)
	render_fill_rect(renderer, &Rect{x: arena_pad_x + 130, y: 38, w: 100, h: 14})
	set_render_draw_color(renderer, p1_trail_color.r, p1_trail_color.g, p1_trail_color.b, 255)
	render_fill_rect(renderer, &Rect{x: arena_pad_x + 130, y: 38, w: int(game.p1.boost_energy), h: 14})

	// Match Target in Center
	draw_text_centered(renderer, win_w / 2, 15, 'TRON LIGHT CYCLES', 2, Color{r: 255, g: 215, b: 0})
	mode_str := if game.mode == .pve { '1P VS AI (${game.diff})' } else { '2P LOCAL VERSUS' }
	draw_text_centered(renderer, win_w / 2, 38, '${mode_str} | FIRST TO ${game.target_score}', 1, Color{r: 160, g: 180, b: 220})

	// P2 Info
	p2_label := if game.mode == .pve { 'AI: ORANGE' } else { 'P2: ORANGE' }
	draw_text(renderer, win_w - arena_pad_x - 210, 15, p2_label, 2, p2_trail_color)
	draw_text(renderer, win_w - arena_pad_x - 210, 38, 'SCORE: ${game.p2_score}', 2, Color{r: 255, g: 255, b: 255})
	// P2 Boost Bar
	set_render_draw_color(renderer, 30, 40, 60, 255)
	render_fill_rect(renderer, &Rect{x: win_w - arena_pad_x - 85, y: 38, w: 85, h: 14})
	set_render_draw_color(renderer, p2_trail_color.r, p2_trail_color.g, p2_trail_color.b, 255)
	render_fill_rect(renderer, &Rect{x: win_w - arena_pad_x - 85, y: 38, w: int(game.p2.boost_energy * 0.85), h: 14})

	// Bottom Instructions
	draw_text_centered(renderer, win_w / 2, win_h - 28, '[WASD/ARROWS] P1 MOVE  [SPACE] BOOST  [M] MODE  [D] DIFF  [R] RESTART  [F11] Fullscreen', 1, Color{r: 140, g: 160, b: 200})

	// Round Over / Match Over Modal Overlay
	if game.state == .round_over || game.state == .match_over {
		set_render_draw_color(renderer, 0, 0, 0, 180)
		render_fill_rect(renderer, &Rect{x: 0, y: 0, w: win_w, h: win_h})

		mx := (win_w - 480) / 2
		my := (win_h - 200) / 2
		set_render_draw_color(renderer, 20, 26, 44, 255)
		modal_rect := Rect{x: mx, y: my, w: 480, h: 200}
		render_fill_rect(renderer, &modal_rect)
		set_render_draw_color(renderer, 70, 90, 150, 255)
		render_draw_rect(renderer, &modal_rect)

		if game.state == .match_over {
			winner_txt := if game.p1_score >= game.target_score { 'PLAYER 1 WINS MATCH!' } else { 'PLAYER 2 / AI WINS MATCH!' }
			col := if game.p1_score >= game.target_score { p1_trail_color } else { p2_trail_color }
			draw_text_centered(renderer, win_w / 2, my + 35, winner_txt, 3, col)
			draw_text_centered(renderer, win_w / 2, my + 85, 'FINAL: ${game.p1_score} - ${game.p2_score}', 2, Color{r: 255, g: 255, b: 255})
			draw_text_centered(renderer, win_w / 2, my + 135, 'PRESS [SPACE] OR [R] TO PLAY AGAIN', 2, Color{r: 80, g: 255, b: 120})
		} else {
			round_txt := if game.round_winner == 1 { 'PLAYER 1 WINS ROUND!' } else if game.round_winner == 2 { 'PLAYER 2 WINS ROUND!' } else { 'DOUBLE CRASH! DRAW!' }
			col := if game.round_winner == 1 { p1_trail_color } else if game.round_winner == 2 { p2_trail_color } else { Color{r: 255, g: 215, b: 0} }
			draw_text_centered(renderer, win_w / 2, my + 35, round_txt, 3, col)
			draw_text_centered(renderer, win_w / 2, my + 85, 'SCORE: ${game.p1_score} - ${game.p2_score}', 2, Color{r: 255, g: 255, b: 255})
			draw_text_centered(renderer, win_w / 2, my + 135, 'PRESS [SPACE] FOR NEXT ROUND', 2, Color{r: 80, g: 255, b: 120})
		}
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}
