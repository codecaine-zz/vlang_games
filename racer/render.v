module main

import math

pub fn (game &RacerGame) render(renderer &Renderer) {
	// Clear Background (Offroad dark green grass)
	set_render_draw_color(renderer, 25, 45, 30, 255)
	render_clear(renderer)

	// Render Track Tiles
	for r in 0 .. track_rows {
		for c in 0 .. track_cols {
			t := game.track_tiles[r][c]
			x := c * track_tile_size
			y := r * track_tile_size
			rect := Rect{ x: x, y: y, w: track_tile_size, h: track_tile_size }

			match t {
				.asphalt {
					set_render_draw_color(renderer, 45, 48, 58, 255)
					render_fill_rect(renderer, &rect)
				}
				.start_finish {
					// Checkered finish pattern
					for i in 0 .. 4 {
						for j in 0 .. 4 {
							col_b := if (i + j) % 2 == 0 { u8(240) } else { u8(20) }
							set_render_draw_color(renderer, col_b, col_b, col_b, 255)
							sq := Rect{ x: x + i * 8, y: y + j * 8, w: 8, h: 8 }
							render_fill_rect(renderer, &sq)
						}
					}
				}
				.turbo_pad {
					set_render_draw_color(renderer, 0, 220, 255, 255)
					render_fill_rect(renderer, &rect)
				}
				.oil_slick {
					set_render_draw_color(renderer, 20, 20, 25, 255)
					render_fill_rect(renderer, &rect)
				}
				.barrier {
					set_render_draw_color(renderer, 200, 50, 50, 255)
					render_fill_rect(renderer, &rect)
				}
				else {}
			}
		}
	}

	// Render Skid Marks
	set_render_draw_color(renderer, 20, 20, 20, 255)
	for s in game.skid_marks {
		s_rect := Rect{ x: int(s.x) - 3, y: int(s.y) - 3, w: 6, h: 6 }
		render_fill_rect(renderer, &s_rect)
	}

	// Render Checkpoint Gates (semi-transparent line guides)
	set_render_draw_color(renderer, 255, 215, 0, 150)
	for cp in game.checkpoints {
		gate_rect := Rect{ x: int(cp.x), y: int(cp.y), w: int(cp.w), h: int(cp.h) }
		render_draw_rect(renderer, &gate_rect)
	}

	// Render Smoke & Turbo Particles
	for p in game.particles {
		sz := int(p.size)
		set_render_draw_color(renderer, p.r, p.g, p.b, 255)
		p_rect := Rect{ x: int(p.x) - sz / 2, y: int(p.y) - sz / 2, w: sz, h: sz }
		render_fill_rect(renderer, &p_rect)
	}

	// Render AI Competitor Cars
	for ai in game.ai_cars {
		render_car(renderer, ai)
	}

	// Render Player Car
	render_car(renderer, game.player)

	// Render HUD Overlay & Minimap
	render_racer_hud(renderer, game)
}

fn render_car(renderer &Renderer, car Car) {
	// Car dimensions: 28 length x 16 width
	length := 28.0
	width := 16.0

	cos_h := math.cos(car.heading)
	sin_h := math.sin(car.heading)

	// Center point
	cx := car.x
	cy := car.y

	// Corner offsets
	fwd_x := cos_h * (length / 2.0)
	fwd_y := sin_h * (length / 2.0)
	side_x := -sin_h * (width / 2.0)
	side_y := cos_h * (width / 2.0)

	// 4 vertices of car bounding box
	v1_x := int(cx + fwd_x + side_x)
	v1_y := int(cy + fwd_y + side_y)
	v2_x := int(cx + fwd_x - side_x)
	v2_y := int(cy + fwd_y - side_y)
	v3_x := int(cx - fwd_x - side_x)
	v3_y := int(cy - fwd_y - side_y)
	v4_x := int(cx - fwd_x + side_x)
	v4_y := int(cy - fwd_y + side_y)

	// Draw Chassis body
	set_render_draw_color(renderer, car.color_r, car.color_g, car.color_b, 255)
	render_draw_line(renderer, v1_x, v1_y, v2_x, v2_y)
	render_draw_line(renderer, v2_x, v2_y, v3_x, v3_y)
	render_draw_line(renderer, v3_x, v3_y, v4_x, v4_y)
	render_draw_line(renderer, v4_x, v4_y, v1_x, v1_y)

	// Fill center rectangle approximation
	box_rect := Rect{ x: int(cx - 10), y: int(cy - 6), w: 20, h: 12 }
	render_fill_rect(renderer, &box_rect)

	// Headlights vector lines
	hl1_x := int(cx + fwd_x * 0.9 + side_x * 0.6)
	hl1_y := int(cy + fwd_y * 0.9 + side_y * 0.6)
	hl2_x := int(cx + fwd_x * 0.9 - side_x * 0.6)
	hl2_y := int(cy + fwd_y * 0.9 - side_y * 0.6)

	set_render_draw_color(renderer, 255, 255, 200, 255)
	render_draw_line(renderer, hl1_x, hl1_y, hl1_x + int(cos_h * 12), hl1_y + int(sin_h * 12))
	render_draw_line(renderer, hl2_x, hl2_y, hl2_x + int(cos_h * 12), hl2_y + int(sin_h * 12))
}

fn render_racer_hud(renderer &Renderer, game &RacerGame) {
	// Top Header Bar
	set_render_draw_color(renderer, 15, 20, 30, 220)
	bar_rect := Rect{ x: 0, y: 0, w: 960, h: 45 }
	render_fill_rect(renderer, &bar_rect)

	// Lap & Timer Metrics
	draw_text(renderer, 20, 12, 'LAP: ${game.player.lap}/${total_laps}', 2, Color{r: 255, g: 215, b: 0})

	milli := int(game.player.lap_time * 100) % 100
	sec := int(game.player.lap_time) % 60
	min := int(game.player.lap_time) / 60
	draw_text(renderer, 240, 12, 'TIME: ${min:02d}:${sec:02d}.${milli:02d}', 2, Color{r: 255, g: 255, b: 255})

	speed_mph := int(math.abs(game.player.speed) * 0.4)
	draw_text(renderer, 550, 12, 'SPEED: ${speed_mph} MPH', 2, Color{r: 100, g: 220, b: 255})

	// Minimap Radar Box in bottom-right corner
	mm_x := 800
	mm_y := 520
	mm_w := 140
	mm_h := 100
	set_render_draw_color(renderer, 10, 15, 25, 200)
	mm_rect := Rect{ x: mm_x, y: mm_y, w: mm_w, h: mm_h }
	render_fill_rect(renderer, &mm_rect)
	set_render_draw_color(renderer, 70, 90, 140, 255)
	render_draw_rect(renderer, &mm_rect)

	// Player dot on minimap
	pm_x := mm_x + int((game.player.x / f64(track_cols * track_tile_size)) * f64(mm_w))
	pm_y := mm_y + int((game.player.y / f64(track_rows * track_tile_size)) * f64(mm_h))
	set_render_draw_color(renderer, 50, 220, 255, 255)
	p_dot := Rect{ x: pm_x - 2, y: pm_y - 2, w: 5, h: 5 }
	render_fill_rect(renderer, &p_dot)

	// AI dots on minimap
	for ai in game.ai_cars {
		aim_x := mm_x + int((ai.x / f64(track_cols * track_tile_size)) * f64(mm_w))
		aim_y := mm_y + int((ai.y / f64(track_rows * track_tile_size)) * f64(mm_h))
		set_render_draw_color(renderer, ai.color_r, ai.color_g, ai.color_b, 255)
		ai_dot := Rect{ x: aim_x - 2, y: aim_y - 2, w: 4, h: 4 }
		render_fill_rect(renderer, &ai_dot)
	}

	// Countdown Overlay
	if game.countdown > 0 {
		count_txt := if game.countdown > 2.0 { '3' } else if game.countdown > 1.0 { '2' } else { '1' }
		draw_text_centered(renderer, 480, 260, count_txt, 8, Color{r: 255, g: 215, b: 0})
	} else if game.race_time < 1.0 {
		draw_text_centered(renderer, 480, 260, 'GO!', 8, Color{r: 80, g: 255, b: 100})
	}

	// Victory / Race Finish Banner
	if game.race_finished {
		set_render_draw_color(renderer, 0, 0, 0, 180)
		full_rect := Rect{ x: 0, y: 0, w: 960, h: 640 }
		render_fill_rect(renderer, &full_rect)

		draw_text_centered(renderer, 480, 240, 'RACE FINISHED!', 5, Color{r: 255, g: 215, b: 0})
		draw_text_centered(renderer, 480, 320, 'PRESS [R] TO RESTART  [F11] Fullscreen', 2, Color{r: 255, g: 255, b: 255})
	}
}
