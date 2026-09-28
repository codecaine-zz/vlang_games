module main

import math
import rand


const cell_sz = 105
const cell_gap = 14
const board_pad = 16

pub struct MergeParticle {
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

pub fn create_merge_burst(cx f64, cy f64, col Color) []MergeParticle {
	mut parts := []MergeParticle{cap: 30}
	for _ in 0 .. 25 {
		angle := (f64(rand.intn(360) or { 0 }) * math.pi) / 180.0
		speed := 40.0 + f64(rand.intn(120) or { 60 })
		life := 0.3 + f64(rand.intn(30) or { 15 }) / 100.0
		parts << MergeParticle{
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

pub fn update_merge_particles(mut particles []MergeParticle, dt f64) {
	for mut p in particles {
		p.x += p.dx * dt
		p.y += p.dy * dt
		p.life -= dt
	}
	mut alive := []MergeParticle{cap: particles.len}
	for p in particles {
		if p.life > 0 {
			alive << p
		}
	}
	particles = alive.clone()
}

pub fn render_merge_particles(renderer &Renderer, particles []MergeParticle) {
	for p in particles {
		alpha := u8(math.clamp(p.life / p.max_life * 255.0, 0, 255))
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		sz := int(p.size)
		rect := Rect{x: int(p.x) - sz / 2, y: int(p.y) - sz / 2, w: sz, h: sz}
		render_fill_rect(renderer, &rect)
	}
}

pub fn get_tile_color(val int) (Color, Color) {
	match val {
		0 { return Color{r: 25, g: 30, b: 46}, Color{r: 40, g: 50, b: 75} }
		2 { return Color{r: 38, g: 58, b: 85}, Color{r: 70, g: 110, b: 160} }
		4 { return Color{r: 25, g: 95, b: 110}, Color{r: 60, g: 170, b: 195} }
		8 { return Color{r: 215, g: 120, b: 35}, Color{r: 255, g: 170, b: 80} }
		16 { return Color{r: 235, g: 85, b: 30}, Color{r: 255, g: 135, b: 70} }
		32 { return Color{r: 240, g: 50, b: 50}, Color{r: 255, g: 100, b: 100} }
		64 { return Color{r: 230, g: 25, b: 45}, Color{r: 255, g: 75, b: 95} }
		128 { return Color{r: 235, g: 195, b: 45}, Color{r: 255, g: 235, b: 110} }
		256 { return Color{r: 245, g: 210, b: 30}, Color{r: 255, g: 245, b: 90} }
		512 { return Color{r: 30, g: 210, b: 120}, Color{r: 90, g: 255, b: 175} }
		1024 { return Color{r: 20, g: 195, b: 240}, Color{r: 100, g: 235, b: 255} }
		2048 { return Color{r: 215, g: 35, b: 235}, Color{r: 255, g: 110, b: 255} }
		else { return Color{r: 155, g: 40, b: 255}, Color{r: 210, g: 120, b: 255} }
	}
}

pub fn draw_rounded_tile(renderer &Renderer, x int, y int, w int, h int, bg Color, border Color) {
	// Background
	set_render_draw_color(renderer, bg.r, bg.g, bg.b, bg.a)
	rect := Rect{x: x, y: y, w: w, h: h}
	render_fill_rect(renderer, &rect)

	// Top and left glow border
	set_render_draw_color(renderer, border.r, border.g, border.b, border.a)
	render_draw_line(renderer, x, y, x + w - 1, y)
	render_draw_line(renderer, x, y, x, y + h - 1)
	render_draw_line(renderer, x + 1, y + 1, x + w - 2, y + 1)
	render_draw_line(renderer, x + 1, y + 1, x + 1, y + h - 2)

	// Bottom-right shadow line
	set_render_draw_color(renderer, u8(bg.r * 2 / 3), u8(bg.g * 2 / 3), u8(bg.b * 2 / 3), 255)
	render_draw_line(renderer, x, y + h - 1, x + w - 1, y + h - 1)
	render_draw_line(renderer, x + w - 1, y, x + w - 1, y + h - 1)
}

pub fn render_game_2048(renderer &Renderer, game &Game2048, win_w int, win_h int, particles []MergeParticle) {
	// Dark space background
	set_render_draw_color(renderer, 12, 15, 24, 255)
	render_clear(renderer)

	// Header Panel
	draw_text(renderer, 50, 25, '2048', 4, Color{r: 255, g: 215, b: 0})
	draw_text(renderer, 52, 65, 'NEON PULSE', 1, Color{r: 80, g: 220, b: 255})

	// Score Box
	score_box_w := 140
	score_box_h := 55
	score_x := win_w - 350
	best_x := win_w - 190
	top_y := 25

	draw_rounded_tile(renderer, score_x, top_y, score_box_w, score_box_h, Color{r: 22, g: 28, b: 42}, Color{r: 60, g: 80, b: 120})
	draw_text_centered(renderer, score_x + score_box_w / 2, top_y + 8, 'SCORE', 1, Color{r: 160, g: 180, b: 210})
	draw_text_centered(renderer, score_x + score_box_w / 2, top_y + 26, '${game.score}', 2, Color{r: 255, g: 255, b: 255})

	draw_rounded_tile(renderer, best_x, top_y, score_box_w, score_box_h, Color{r: 22, g: 28, b: 42}, Color{r: 60, g: 80, b: 120})
	draw_text_centered(renderer, best_x + score_box_w / 2, top_y + 8, 'BEST', 1, Color{r: 160, g: 180, b: 210})
	draw_text_centered(renderer, best_x + score_box_w / 2, top_y + 26, '${game.best_score}', 2, Color{r: 255, g: 215, b: 0})

	// Board Outer Frame
	board_grid_w := 4 * cell_sz + 3 * cell_gap + 2 * board_pad
	board_grid_h := board_grid_w
	board_x := (win_w - board_grid_w) / 2
	board_y := 115

	draw_rounded_tile(renderer, board_x, board_y, board_grid_w, board_grid_h, Color{r: 18, g: 22, b: 34}, Color{r: 45, g: 58, b: 88})

	// Render 4x4 Grid Tiles
	for r in 0 .. 4 {
		for c in 0 .. 4 {
			val := game.grid[r][c]
			tx := board_x + board_pad + c * (cell_sz + cell_gap)
			ty := board_y + board_pad + r * (cell_sz + cell_gap)

			bg_col, border_col := get_tile_color(val)
			draw_rounded_tile(renderer, tx, ty, cell_sz, cell_sz, bg_col, border_col)

			if val > 0 {
				val_str := '${val}'
				scale := if val < 100 { 3 } else if val < 1000 { 2 } else { 2 }
				cx := tx + cell_sz / 2
				cy := ty + (cell_sz - 8 * scale) / 2
				txt_col := if val <= 4 { Color{r: 240, g: 245, b: 255} } else { Color{r: 255, g: 255, b: 255} }
				draw_text_centered(renderer, cx, cy, val_str, scale, txt_col)
			}
		}
	}

	// Render Merge Particles
	render_merge_particles(renderer, particles)

	// Bottom Instructions
	draw_text_centered(renderer, win_w / 2, win_h - 45, '[ARROWS or WASD] SLIDE TILES  [U] UNDO  [R] RESTART  [S] SOUND  [F11] Fullscreen', 1, Color{r: 150, g: 175, b: 215})

	// Victory Modal
	if game.state == .won && !game.keep_playing {
		set_render_draw_color(renderer, 0, 0, 0, 190)
		render_fill_rect(renderer, &Rect{x: 0, y: 0, w: win_w, h: win_h})

		mx := (win_w - 440) / 2
		my := (win_h - 220) / 2
		draw_rounded_tile(renderer, mx, my, 440, 220, Color{r: 24, g: 30, b: 48}, Color{r: 255, g: 215, b: 0})

		draw_text_centered(renderer, win_w / 2, my + 30, 'YOU WIN! 2048 REACHED!', 3, Color{r: 255, g: 215, b: 0})
		draw_text_centered(renderer, win_w / 2, my + 80, 'Score: ${game.score}', 2, Color{r: 80, g: 220, b: 255})
		draw_text_centered(renderer, win_w / 2, my + 130, 'PRESS [SPACE] TO KEEP PLAYING', 2, Color{r: 80, g: 255, b: 120})
		draw_text_centered(renderer, win_w / 2, my + 165, 'PRESS [R] TO RESTART  [F11] Fullscreen', 1, Color{r: 180, g: 200, b: 230})
	} else if game.state == .game_over {
		set_render_draw_color(renderer, 0, 0, 0, 190)
		render_fill_rect(renderer, &Rect{x: 0, y: 0, w: win_w, h: win_h})

		mx := (win_w - 440) / 2
		my := (win_h - 220) / 2
		draw_rounded_tile(renderer, mx, my, 440, 220, Color{r: 24, g: 30, b: 48}, Color{r: 255, g: 60, b: 80})

		draw_text_centered(renderer, win_w / 2, my + 35, 'GAME OVER!', 3, Color{r: 255, g: 60, b: 80})
		draw_text_centered(renderer, win_w / 2, my + 85, 'Final Score: ${game.score}', 2, Color{r: 255, g: 255, b: 255})
		draw_text_centered(renderer, win_w / 2, my + 135, 'PRESS [U] TO UNDO OR [R] TO RETRY', 2, Color{r: 80, g: 220, b: 255})
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}
