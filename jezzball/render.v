module main

import math


pub fn render_jezz_game(renderer &Renderer, mut g JezzGame, win_w int, win_h int, mouse_x int, mouse_y int) {
	// 1. Clear Background
	set_render_draw_color(renderer, 12, 16, 24, 255)
	clear_rect := Rect{0, 0, win_w, win_h}
	render_fill_rect(renderer, &clear_rect)

	// Playfield offsets
	ox := (win_w - arena_w) / 2
	oy := 60

	// 2. Draw Playfield Grid & Walls
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			cell_type := g.grid[r][c]
			cx := ox + c * cell_size
			cy := oy + r * cell_size

			match cell_type {
				0 {
					if (r * grid_cols + c) % 8 == 0 {
						set_render_draw_color(renderer, 24, 32, 48, 255)
						render_draw_point(renderer, cx + 6, cy + 6)
					}
				}
				1 {
					// Perimeter border
					set_render_draw_color(renderer, 60, 75, 95, 255)
					p_rect := Rect{cx, cy, cell_size, cell_size}
					render_fill_rect(renderer, &p_rect)
					set_render_draw_color(renderer, 90, 110, 140, 255)
					render_draw_rect(renderer, &p_rect)
				}
				2 {
					// Permanent Built Solid Wall (High-tech Laser Barrier)
					set_render_draw_color(renderer, 0, 180, 255, 255)
					w_rect := Rect{cx, cy, cell_size, cell_size}
					render_fill_rect(renderer, &w_rect)
					set_render_draw_color(renderer, 220, 245, 255, 255)
					hi_rect := Rect{cx + 2, cy + 2, cell_size - 4, cell_size - 4}
					render_fill_rect(renderer, &hi_rect)
				}
				3 {
					// Captured Territory (Glowing Circuit Pattern)
					set_render_draw_color(renderer, 15, 45, 75, 255)
					c_rect := Rect{cx, cy, cell_size, cell_size}
					render_fill_rect(renderer, &c_rect)
					set_render_draw_color(renderer, 25, 75, 120, 255)
					render_draw_rect(renderer, &c_rect)
				}
				else {}
			}
		}
	}

	// 3. Draw Active Expanding Wall Beams
	if g.wall.active {
		start_px := ox + g.wall.start_gx * cell_size + cell_size / 2
		start_py := oy + g.wall.start_gy * cell_size + cell_size / 2

		set_render_draw_color(renderer, 255, 220, 40, 255)

		if g.wall.orient == .horizontal {
			x1 := start_px - int(g.wall.neg_len)
			x2 := start_px + int(g.wall.pos_len)
			y := start_py - 2
			w_beam := Rect{x1, y, x2 - x1, 5}
			render_fill_rect(renderer, &w_beam)
			// Core highlight
			set_render_draw_color(renderer, 255, 255, 255, 255)
			c_beam := Rect{x1, y + 1, x2 - x1, 3}
			render_fill_rect(renderer, &c_beam)
		} else {
			y1 := start_py - int(g.wall.neg_len)
			y2 := start_py + int(g.wall.pos_len)
			x := start_px - 2
			w_beam := Rect{x, y1, 5, y2 - y1}
			render_fill_rect(renderer, &w_beam)
			// Core highlight
			set_render_draw_color(renderer, 255, 255, 255, 255)
			c_beam := Rect{x + 1, y1, 3, y2 - y1}
			render_fill_rect(renderer, &c_beam)
		}
	}

	// 4. Draw Kinetic Energy Atoms
	for b in g.balls {
		// Trail
		for i in 0 .. b.trail.len {
			pt := b.trail[i]
			fade := u8((f64(i) / f64(b.trail.len)) * 120.0)
			trail_col := if b.is_blue { Color{0, 180, 255, fade} } else { Color{255, 80, 80, fade} }
			draw_filled_circle(renderer, ox + int(pt.x), oy + int(pt.y), int(b.radius * 0.7), trail_col)
		}

		bx := ox + int(b.x)
		by := oy + int(b.y)
		r := int(b.radius)

		if b.is_blue {
			// Blue Energy Atom
			draw_filled_circle(renderer, bx, by, r + 2, Color{0, 150, 255, 120})
			draw_filled_circle(renderer, bx, by, r, Color{0, 220, 255, 255})
			draw_filled_circle(renderer, bx - 2, by - 2, r - 3, Color{255, 255, 255, 255})
		} else {
			// Red Energy Atom
			draw_filled_circle(renderer, bx, by, r + 2, Color{255, 50, 50, 120})
			draw_filled_circle(renderer, bx, by, r, Color{255, 90, 90, 255})
			draw_filled_circle(renderer, bx - 2, by - 2, r - 3, Color{255, 255, 255, 255})
		}
	}

	// 5. Draw Particles
	for p in g.particles {
		px := ox + int(p.x)
		py := oy + int(p.y)
		set_render_draw_color(renderer, p.col.r, p.col.g, p.col.b, 255)
		p_rect := Rect{px - 1, py - 1, 3, 3}
		render_fill_rect(renderer, &p_rect)
	}

	// 6. Draw Crosshair / Wall Emitter at Mouse Position
	if mouse_x >= ox && mouse_x < ox + arena_w && mouse_y >= oy && mouse_y < oy + arena_h {
		render_crosshair(renderer, mouse_x, mouse_y, g.orient)
	}

	// 7. Top & Bottom HUD Dashboard
	render_jezz_hud(renderer, g, win_w, win_h, ox, oy)
}

fn render_crosshair(renderer &Renderer, mx int, my int, orient WallOrientation) {
	col := Color{255, 230, 80, 220}
	set_render_draw_color(renderer, col.r, col.g, col.b, col.a)

	draw_filled_circle(renderer, mx, my, 3, col)

	if orient == .horizontal {
		render_draw_line(renderer, mx - 16, my, mx + 16, my)
		render_draw_line(renderer, mx - 16, my, mx - 10, my - 5)
		render_draw_line(renderer, mx - 16, my, mx - 10, my + 5)
		render_draw_line(renderer, mx + 16, my, mx + 10, my - 5)
		render_draw_line(renderer, mx + 16, my, mx + 10, my + 5)
	} else {
		render_draw_line(renderer, mx, my - 16, mx, my + 16)
		render_draw_line(renderer, mx, my - 16, mx - 5, my - 10)
		render_draw_line(renderer, mx, my - 16, mx + 5, my - 10)
		render_draw_line(renderer, mx, my + 16, mx - 5, my + 10)
		render_draw_line(renderer, mx, my + 16, mx + 5, my + 10)
	}
}

fn render_jezz_hud(renderer &Renderer, g JezzGame, win_w int, win_h int, ox int, oy int) {
	// Top Banner Bar
	set_render_draw_color(renderer, 20, 26, 40, 255)
	bar_rect := Rect{0, 0, win_w, 50}
	render_fill_rect(renderer, &bar_rect)

	set_render_draw_color(renderer, 45, 60, 90, 255)
	render_draw_line(renderer, 0, 49, win_w, 49)

	// Metrics
	draw_text(renderer, 20, 16, 'LEVEL ${g.level}', 2, Color{255, 255, 255, 255})
	draw_text(renderer, 150, 16, 'SCORE: ${g.score}', 2, Color{255, 215, 0, 255})

	// Lives display (Red Hearts / Shields)
	mut heart_str := ''
	for _ in 0 .. g.lives {
		heart_str += '<3 '
	}
	draw_text(renderer, 350, 16, 'LIVES: ${heart_str}', 2, Color{255, 60, 80, 255})

	// Containment Progress Bar
	bar_x := 560
	bar_y := 14
	bar_w := 240
	bar_h := 22

	set_render_draw_color(renderer, 30, 40, 60, 255)
	pbg := Rect{bar_x, bar_y, bar_w, bar_h}
	render_fill_rect(renderer, &pbg)

	fill_w := int(f64(bar_w) * (math.min(100.0, g.cleared_pct) / 100.0))
	fill_col := if g.cleared_pct >= g.target_pct { Color{0, 255, 120, 255} } else { Color{0, 180, 255, 255} }
	set_render_draw_color(renderer, fill_col.r, fill_col.g, fill_col.b, 255)
	pfill := Rect{bar_x, bar_y, fill_w, bar_h}
	render_fill_rect(renderer, &pfill)

	// 75% Target threshold mark
	target_x := bar_x + int(f64(bar_w) * (g.target_pct / 100.0))
	set_render_draw_color(renderer, 255, 60, 60, 255)
	render_draw_line(renderer, target_x, bar_y - 3, target_x, bar_y + bar_h + 3)

	// Border
	set_render_draw_color(renderer, 120, 145, 180, 255)
	render_draw_rect(renderer, &pbg)

	// % Cleared text overlay
	draw_text_centered(renderer, bar_x + bar_w / 2, bar_y + 4, '${int(g.cleared_pct)}% / ${int(g.target_pct)}%', 1, Color{255, 255, 255, 255})

	// Bottom Tool Strip
	by := oy + arena_h + 10
	orient_str := match g.orient {
		.horizontal { 'HORIZONTAL [R-CLICK / SPACE]' }
		.vertical { 'VERTICAL [R-CLICK / SPACE]' }
	}
	draw_text(renderer, ox, by, 'WALL ORIENTATION: ${orient_str}', 1, Color{255, 230, 80, 255})
	draw_text(renderer, ox + arena_w - 240, by, 'RESTART [R]  |  SOUND [O] | F11: Fullscreen', 1, Color{180, 190, 210, 255})

	// Animated Center Announcement Banner
	if g.banner_timer > 0.0 && g.banner_text != '' {
		banner_w := g.banner_text.len * 8 * 2 + 40
		bx := win_w / 2 - banner_w / 2
		ban_y := win_h / 2 - 25

		set_render_draw_color(renderer, 10, 15, 25, 240)
		bg_rect := Rect{bx, ban_y, banner_w, 48}
		render_fill_rect(renderer, &bg_rect)

		set_render_draw_color(renderer, 0, 220, 255, 255)
		render_draw_rect(renderer, &bg_rect)

		draw_text_centered(renderer, win_w / 2, ban_y + 16, g.banner_text, 2, Color{255, 240, 100, 255})
	}
}
