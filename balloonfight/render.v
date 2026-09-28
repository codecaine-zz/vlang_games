module main

import math
import rand

fn draw_game(renderer &Renderer, ge &GameEngine) {
	mut ren := unsafe { &Renderer(renderer) }
	mut sx := f32(0.0)
	mut sy := f32(0.0)
	if ge.shake_trauma > 0 {
		mag := f32(ge.shake_trauma * ge.shake_trauma * 16.0)
		sx = (rand.f32() * 2.0 - 1.0) * mag
		sy = (rand.f32() * 2.0 - 1.0) * mag
	}
	ren.offset_x += sx
	ren.offset_y += sy
	defer {
		ren.offset_x -= sx
		ren.offset_y -= sy
	}

	// Background Clear (Dark NES Night Sky)
	set_render_draw_color(renderer, 15, 23, 42, 255)
	render_clear(renderer)

	// Stars in night sky
	draw_starfield(renderer, ge.elapsed_time)

	// Water surface & waves
	draw_water_ocean(renderer, ge.water_level, ge.elapsed_time)

	// Platforms
	for plat in ge.platforms {
		draw_platform(renderer, plat)
	}

	// Storm Clouds & Lightning Sparks
	for cloud in ge.clouds {
		draw_cloud(renderer, cloud)
	}
	for spark in ge.sparks {
		draw_spark(renderer, spark, ge.trip_scroll_x, ge.mode == .balloon_trip, ge.sprite_texture)
	}

	// Balloon Trip Mode Items
	if ge.mode == .balloon_trip {
		for tb in ge.trip_balloons {
			if !tb.collected {
				draw_trip_balloon(renderer, tb, ge.trip_scroll_x, ge.sprite_texture)
			}
		}
	}

	// Floating Bonus Bubbles
	for bubble in ge.bubbles {
		if bubble.active {
			draw_bonus_bubble(renderer, bubble, ge.elapsed_time)
		}
	}

	// Particles
	draw_particles(renderer, ge.particles)

	// Enemies
	for enemy in ge.enemies {
		if enemy.active {
			draw_enemy(renderer, enemy, ge.elapsed_time, ge.sprite_texture)
		}
	}

	// Players
	if ge.state == .playing || ge.state == .phase_clear || ge.state == .paused {
		for p in ge.players {
			if p.state != .dead {
				draw_player(renderer, p, ge.elapsed_time, ge.sprite_texture)
			}
		}
	}

	// Giant Fish
	if ge.fish.active {
		draw_giant_fish(renderer, ge.fish, ge.sprite_texture)
	}

	// Floating Score Popups
	for ft in ge.float_texts {
		if ft.life > 0 {
			draw_float_text(renderer, ft)
		}
	}

	// HUD
	draw_hud(renderer, ge)

	// Screen Overlays
	match ge.state {
		.title { draw_title_screen(renderer, ge) }
		.paused { draw_paused_screen(renderer) }
		.phase_clear { draw_phase_clear_screen(renderer, ge) }
		.game_over { draw_game_over_screen(renderer, ge) }
		else {}
	}
}

fn draw_starfield(renderer &Renderer, t f64) {
	min_x, _, max_x, _ := renderer.visible_bounds()
	width_span := int(math.max(800.0, max_x - min_x))
	set_render_draw_color(renderer, 248, 250, 252, 180)
	for i in 0 .. 60 {
		x := int(min_x) + int((i * 67 + int(t * 10.0)) % width_span)
		y := int((i * 43) % 480)
		render_draw_point(renderer, x, y)
	}
}

fn draw_water_ocean(renderer &Renderer, water_y f64, t f64) {
	min_x, _, max_x, _ := renderer.visible_bounds()
	start_x := int(min_x) - 15
	end_x := int(max_x) + 15
	w_span := end_x - start_x

	// Ocean body
	set_render_draw_color(renderer, 14, 116, 144, 255)
	water_rect := Rect{
		x: start_x
		y: int(water_y)
		w: w_span
		h: int(600.0 - water_y)
	}
	render_fill_rect(renderer, &water_rect)

	// Animated Wave Surface Line
	set_render_draw_color(renderer, 34, 211, 238, 255)
	for x := start_x; x < end_x; x += 15 {
		wave_offset := int(math.sin(t * 5.0 + f64(x) * 0.05) * 4.0)
		render_draw_line(renderer, x, int(water_y) + wave_offset, x + 15, int(water_y) - wave_offset)
	}
}

fn draw_platform(renderer &Renderer, plat Platform) {
	// Platform cloud grass top
	set_render_draw_color(renderer, 52, 211, 153, 255)
	top_rect := Rect{
		x: int(plat.x)
		y: int(plat.y)
		w: int(plat.w)
		h: 6
	}
	render_fill_rect(renderer, &top_rect)

	// Platform body
	set_render_draw_color(renderer, 15, 118, 110, 255)
	body_rect := Rect{
		x: int(plat.x)
		y: int(plat.y) + 6
		w: int(plat.w)
		h: int(plat.h) - 6
	}
	render_fill_rect(renderer, &body_rect)
}

fn draw_player(renderer &Renderer, p Player, t f64, tex &Texture) {
	px := int(p.motion.x)
	py := int(p.motion.y)
	is_flap := int(t * 12.0) % 2 == 1

	if tex != unsafe { nil } {
		// Draw Parachute
		if p.state == .parachuting {
			src := Rect{x: 0, y: 96, w: 32, h: 32}
			dst := Rect{x: px - 16, y: py - 32, w: 32, h: 32}
			render_copy(renderer, tex, &src, &dst)
		} else {
			// Draw Balloons
			if p.balloons >= 1 {
				src_b1 := Rect{x: 0, y: 64, w: 32, h: 32} // Red
				dst_b1 := Rect{x: px - 22, y: py - 32, w: 24, h: 24}
				render_copy(renderer, tex, &src_b1, &dst_b1)
			}
			if p.balloons >= 2 {
				src_b2 := Rect{x: 32, y: 64, w: 32, h: 32} // Blue
				dst_b2 := Rect{x: px - 2, y: py - 32, w: 24, h: 24}
				render_copy(renderer, tex, &src_b2, &dst_b2)
			}
		}

		// Draw Player Fighter Body
		src_x := if p.id == 0 {
			if is_flap { 32 } else { 0 }
		} else {
			if is_flap { 96 } else { 64 }
		}
		src_p := Rect{x: src_x, y: 0, w: 32, h: 32}
		dst_p := Rect{x: px - 16, y: py - 16, w: 32, h: 32}
		render_copy(renderer, tex, &src_p, &dst_p)
		return
	}

	// Procedural Fallback
	body_color := if p.id == 0 {
		Color{ r: 59, g: 130, b: 246 }
	} else {
		Color{ r: 239, g: 68, b: 68 }
	}

	set_render_draw_color(renderer, body_color.r, body_color.g, body_color.b, body_color.a)
	b_rect := Rect{ x: px - 10, y: py - 10, w: 20, h: 20 }
	render_fill_rect(renderer, &b_rect)

	set_render_draw_color(renderer, 248, 250, 252, 255)
	wing_y := if is_flap { py + 4 } else { py - 4 }
	render_draw_line(renderer, px - 10, py, px - 18, wing_y)
	render_draw_line(renderer, px + 10, py, px + 18, wing_y)

	if p.state == .parachuting {
		set_render_draw_color(renderer, 250, 204, 21, 255)
		para := Rect{ x: px - 16, y: py - 32, w: 32, h: 12 }
		render_fill_rect(renderer, &para)
		set_render_draw_color(renderer, 226, 232, 240, 255)
		render_draw_line(renderer, px - 14, py - 20, px - 6, py - 10)
		render_draw_line(renderer, px + 14, py - 20, px + 6, py - 10)
	} else {
		if p.balloons >= 1 {
			draw_balloon(renderer, px - 10, py - 26, Color{ r: 239, g: 68, b: 68 }, unsafe { nil })
			set_render_draw_color(renderer, 226, 232, 240, 180)
			render_draw_line(renderer, px - 10, py - 18, px - 4, py - 10)
		}
		if p.balloons >= 2 {
			draw_balloon(renderer, px + 10, py - 26, Color{ r: 59, g: 130, b: 246 }, unsafe { nil })
			set_render_draw_color(renderer, 226, 232, 240, 180)
			render_draw_line(renderer, px + 10, py - 18, px + 4, py - 10)
		}
	}
}

fn draw_enemy(renderer &Renderer, enemy Enemy, t f64, tex &Texture) {
	ex := int(enemy.motion.x)
	ey := int(enemy.motion.y)
	is_flap := enemy.wing_flap || (int(t * 10.0 + f64(enemy.id)) % 2 == 1)

	if tex != unsafe { nil } {
		// Parachute or Balloons
		if enemy.state == .parachuting {
			src := Rect{x: 32, y: 96, w: 32, h: 32}
			dst := Rect{x: ex - 16, y: ey - 32, w: 32, h: 32}
			render_copy(renderer, tex, &src, &dst)
		} else if enemy.state == .flying || enemy.state == .pumping {
			b_src_x := match enemy.rank {
				.yellow { 64 }
				.pink { 96 }
				.red { 0 }
			}
			if enemy.balloons >= 1 {
				src_b1 := Rect{x: b_src_x, y: 64, w: 32, h: 32}
				dst_b1 := Rect{x: ex - 22, y: ey - 32, w: 24, h: 24}
				render_copy(renderer, tex, &src_b1, &dst_b1)
			}
			if enemy.balloons >= 2 {
				src_b2 := Rect{x: b_src_x, y: 64, w: 32, h: 32}
				dst_b2 := Rect{x: ex - 2, y: ey - 32, w: 24, h: 24}
				render_copy(renderer, tex, &src_b2, &dst_b2)
			}
		}

		// Enemy Body
		base_x := match enemy.rank {
			.yellow { 0 }
			.pink { 64 }
			.red { 128 }
		}
		src_x := if is_flap { base_x + 32 } else { base_x }
		src_e := Rect{x: src_x, y: 32, w: 32, h: 32}
		dst_e := Rect{x: ex - 16, y: ey - 16, w: 32, h: 32}
		flip := if enemy.facing_right { RendererFlip.none } else { RendererFlip.horizontal }
		render_copy_ex(renderer, tex, &src_e, &dst_e, 0.0, unsafe { nil }, flip)
		return
	}

	// Procedural Fallback
	color := match enemy.rank {
		.yellow { Color{ r: 250, g: 204, b: 21 } }
		.pink { Color{ r: 236, g: 72, b: 153 } }
		.red { Color{ r: 239, g: 68, b: 68 } }
	}

	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	b_rect := Rect{ x: ex - 9, y: ey - 9, w: 18, h: 18 }
	render_fill_rect(renderer, &b_rect)

	// Animated Wings
	wing_y := if is_flap { ey - 10 } else { ey - 3 }
	wing := if enemy.facing_right {
		Rect{ x: ex - 12, y: wing_y, w: 8, h: 6 }
	} else {
		Rect{ x: ex + 4, y: wing_y, w: 8, h: 6 }
	}
	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	render_fill_rect(renderer, &wing)

	// Beak
	set_render_draw_color(renderer, 245, 130, 20, 255)
	beak := if enemy.facing_right {
		Rect{ x: ex + 7, y: ey - 2, w: 6, h: 5 }
	} else {
		Rect{ x: ex - 13, y: ey - 2, w: 6, h: 5 }
	}
	render_fill_rect(renderer, &beak)

	// Eye White
	set_render_draw_color(renderer, 255, 255, 255, 255)
	eye_w := if enemy.facing_right {
		Rect{ x: ex - 2, y: ey - 6, w: 6, h: 6 }
	} else {
		Rect{ x: ex - 4, y: ey - 6, w: 6, h: 6 }
	}
	render_fill_rect(renderer, &eye_w)

	// Eye Pupil
	set_render_draw_color(renderer, 15, 23, 42, 255)
	eye_p := if enemy.facing_right {
		Rect{ x: ex + 1, y: ey - 4, w: 3, h: 3 }
	} else {
		Rect{ x: ex - 4, y: ey - 4, w: 3, h: 3 }
	}
	render_fill_rect(renderer, &eye_p)

	if enemy.state == .parachuting {
		set_render_draw_color(renderer, 248, 250, 252, 255)
		para := Rect{ x: ex - 16, y: ey - 30, w: 32, h: 12 }
		render_fill_rect(renderer, &para)
	} else if enemy.state == .flying || enemy.state == .pumping {
		if enemy.balloons >= 1 {
			draw_balloon(renderer, ex - 10, ey - 25, color, unsafe { nil })
		}
		if enemy.balloons >= 2 {
			draw_balloon(renderer, ex + 10, ey - 25, color, unsafe { nil })
		}
	}
}

fn draw_bonus_bubble(renderer &Renderer, bubble BonusBubble, t f64) {
	bx := int(bubble.x)
	by := int(bubble.y)
	rad := int(bubble.radius)

	// Animated shimmering alpha and gleam
	shimmer := u8(160 + int(math.sin(t * 8.0 + bubble.phase) * 40.0))

	// Outer glowing translucent bubble circle
	set_render_draw_color(renderer, 56, 189, 248, shimmer)
	outer_rect := Rect{ x: bx - rad, y: by - rad, w: rad * 2, h: rad * 2 }
	render_fill_rect(renderer, &outer_rect)

	// Inner lighter body
	set_render_draw_color(renderer, 186, 230, 253, u8(math.min(255, int(shimmer) + 30)))
	inner_rect := Rect{ x: bx - rad + 2, y: by - rad + 2, w: (rad - 2) * 2, h: (rad - 2) * 2 }
	render_fill_rect(renderer, &inner_rect)

	// Specular highlight gleam
	set_render_draw_color(renderer, 255, 255, 255, 240)
	gleam := Rect{ x: bx - rad + 3, y: by - rad + 3, w: 3, h: 3 }
	render_fill_rect(renderer, &gleam)
}

fn draw_particles(renderer &Renderer, particles []Particle) {
	for part in particles {
		if part.life <= 0 {
			continue
		}
		alpha_factor := math.clamp(part.life / part.max_life, 0.0, 1.0)
		alpha := u8(f64(part.color.a) * alpha_factor)
		set_render_draw_color(renderer, part.color.r, part.color.g, part.color.b, alpha)
		sz := int(math.max(1.0, part.size * alpha_factor))
		p_rect := Rect{
			x: int(part.x) - (sz / 2)
			y: int(part.y) - (sz / 2)
			w: sz
			h: sz
		}
		render_fill_rect(renderer, &p_rect)
	}
}

fn draw_float_text(renderer &Renderer, ft FloatText) {
	alpha_factor := math.clamp(ft.life / 1.0, 0.0, 1.0)
	alpha := u8(255.0 * alpha_factor)
	color := Color{
		r: ft.color.r
		g: ft.color.g
		b: ft.color.b
		a: alpha
	}
	draw_text_centered(renderer, int(ft.x), int(ft.y), ft.text, 1, color)
}

fn draw_balloon(renderer &Renderer, x int, y int, color Color, tex &Texture) {
	if tex != unsafe { nil } {
		src := Rect{x: 128, y: 64, w: 32, h: 32} // Orange/Trip
		dst := Rect{x: x - 12, y: y - 14, w: 24, h: 28}
		render_copy(renderer, tex, &src, &dst)
		return
	}
	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	b_rect := Rect{ x: x - 8, y: y - 10, w: 16, h: 18 }
	render_fill_rect(renderer, &b_rect)

	set_render_draw_color(renderer, u8(math.min(255, int(color.r) + 70)), u8(math.min(255, int(color.g) + 70)), u8(math.min(255, int(color.b) + 70)), 255)
	render_draw_line(renderer, x - 6, y - 8, x + 6, y - 8)

	set_render_draw_color(renderer, 255, 255, 255, 230)
	shine := Rect{ x: x - 4, y: y - 6, w: 3, h: 3 }
	render_fill_rect(renderer, &shine)

	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	knot := Rect{ x: x - 2, y: y + 8, w: 4, h: 2 }
	render_fill_rect(renderer, &knot)
}

fn draw_giant_fish(renderer &Renderer, fish GiantFish, tex &Texture) {
	fx := int(fish.x)
	fy := int(fish.y)

	if tex != unsafe { nil } {
		src := Rect{x: 0, y: 128, w: 64, h: 64}
		dst := Rect{x: fx - 32, y: fy - 32, w: 64, h: 64}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	set_render_draw_color(renderer, 234, 179, 8, 255)
	body := Rect{ x: fx - 25, y: fy - 25, w: 50, h: 50 }
	render_fill_rect(renderer, &body)

	set_render_draw_color(renderer, 15, 23, 42, 255)
	mouth := Rect{ x: fx - 20, y: fy - 20, w: 40, h: 20 }
	render_fill_rect(renderer, &mouth)

	set_render_draw_color(renderer, 248, 250, 252, 255)
	for i in 0 .. 5 {
		t_rect := Rect{ x: fx - 18 + (i * 8), y: fy - 20, w: 4, h: 6 }
		render_fill_rect(renderer, &t_rect)
	}
}

fn draw_cloud(renderer &Renderer, cloud Cloud) {
	cx := int(cloud.x)
	cy := int(cloud.y)

	set_render_draw_color(renderer, 100, 116, 139, 255)
	c_rect := Rect{ x: cx - 25, y: cy - 12, w: 50, h: 24 }
	render_fill_rect(renderer, &c_rect)
}

fn draw_spark(renderer &Renderer, spark Spark, scroll_x f64, is_trip bool, tex &Texture) {
	mut sx := int(spark.x)
	if is_trip {
		sx = int(spark.x - scroll_x)
	}
	sy := int(spark.y)
	rad := int(spark.radius)

	if tex != unsafe { nil } {
		src := Rect{x: 64, y: 96, w: 32, h: 32}
		dst := Rect{x: sx - 12, y: sy - 12, w: 24, h: 24}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	set_render_draw_color(renderer, 250, 204, 21, 255)
	s_rect := Rect{ x: sx - rad, y: sy - rad, w: rad * 2, h: rad * 2 }
	render_fill_rect(renderer, &s_rect)
}

fn draw_trip_balloon(renderer &Renderer, tb TripBalloon, scroll_x f64, tex &Texture) {
	sx := int(tb.x - scroll_x)
	sy := int(tb.y)

	draw_balloon(renderer, sx, sy, Color{ r: 168, g: 85, b: 247 }, tex)
}

fn draw_hud(renderer &Renderer, ge &GameEngine) {
	// Top Header HUD Bar
	set_render_draw_color(renderer, 15, 23, 42, 220)
	bar := Rect{
		x: 0
		y: 0
		w: 800
		h: 40
	}
	render_fill_rect(renderer, &bar)
	set_render_draw_color(renderer, 30, 41, 59, 255)
	render_draw_line(renderer, 0, 40, 800, 40)

	if ge.players.len > 0 {
		p1 := ge.players[0]
		draw_text(renderer, 20, 12, '1P SCORE: ${p1.score}', 1, Color{
			r: 59
			g: 130
			b: 246
		})
		draw_text(renderer, 200, 12, 'LIVES: ${p1.lives}', 1, Color{
			r: 52
			g: 211
			b: 153
		})
	}

	draw_text_centered(renderer, 400, 12, 'HIGH: ${ge.high_score}', 1, Color{
		r: 250
		g: 204
		b: 21
	})

	if ge.mode != .balloon_trip {
		draw_text(renderer, 640, 12, 'PHASE: ${ge.phase}', 1, Color{
			r: 236
			g: 72
			b: 153
		})
	} else {
		draw_text(renderer, 620, 12, 'BALLOON TRIP', 1, Color{
			r: 168
			g: 85
			b: 247
		})
	}
}

fn draw_title_screen(renderer &Renderer, ge &GameEngine) {
	set_render_draw_color(renderer, 15, 23, 42, 235)
	overlay := Rect{
		x: 0
		y: 0
		w: 800
		h: 600
	}
	render_fill_rect(renderer, &overlay)

	draw_text_centered(renderer, 400, 100, 'BALLOON FIGHT', 4, Color{
		r: 239
		g: 68
		b: 68
	})
	draw_text_centered(renderer, 400, 150, '1984 NES ARCADE CLASSIC RECREATION', 2, Color{
		r: 250
		g: 204
		b: 21
	})

	draw_text_centered(renderer, 400, 240, '[1] MODE A : 1 PLAYER CLASSIC', 2, Color{
		r: 59
		g: 130
		b: 246
	})
	draw_text_centered(renderer, 400, 280, '[2] MODE B : 2 PLAYER CO-OP', 2, Color{
		r: 52
		g: 211
		b: 153
	})
	draw_text_centered(renderer, 400, 320, '[3] BALLOON TRIP BONUS MODE', 2, Color{
		r: 168
		g: 85
		b: 247
	})

	draw_text_centered(renderer, 400, 400, '--- CONTROLS ---', 1, Color{
		r: 148
		g: 163
		b: 184
	})
	draw_text_centered(renderer, 400, 420, 'P1: WASD / Arrows to Move, Space / W / Up to Flap Wings', 1, Color{
		r: 226
		g: 232
		b: 240
	})
	draw_text_centered(renderer, 400, 440, 'P2: IJKL to Move, O to Flap Wings', 1, Color{
		r: 226
		g: 232
		b: 240
	})
	draw_text_centered(renderer, 400, 460, 'P: Pause  |  R: Reset  |  M: Mute Sound', 1, Color{
		r: 226
		g: 232
		b: 240
	})

	if int(ge.elapsed_time * 4.0) % 2 == 0 {
		draw_text_centered(renderer, 400, 520, 'PRESS [1], [2], OR [3] TO START GAME', 2, Color{
			r: 34
			g: 211
			b: 238
		})
	}
}

fn draw_paused_screen(renderer &Renderer) {
	set_render_draw_color(renderer, 15, 23, 42, 180)
	overlay := Rect{
		x: 0
		y: 0
		w: 800
		h: 600
	}
	render_fill_rect(renderer, &overlay)

	draw_text_centered(renderer, 400, 270, 'GAME PAUSED', 3, Color{
		r: 250
		g: 204
		b: 21
	})
	draw_text_centered(renderer, 400, 310, 'Press [P] to Resume', 1, Color{
		r: 226
		g: 232
		b: 240
	})
}

fn draw_phase_clear_screen(renderer &Renderer, ge &GameEngine) {
	set_render_draw_color(renderer, 15, 23, 42, 200)
	overlay := Rect{
		x: 0
		y: 0
		w: 800
		h: 600
	}
	render_fill_rect(renderer, &overlay)

	draw_text_centered(renderer, 400, 240, 'PHASE ${ge.phase - 1} CLEARED!', 4, Color{
		r: 52
		g: 211
		b: 153
	})
	draw_text_centered(renderer, 400, 300, 'PREPARE FOR PHASE ${ge.phase}...', 2, Color{
		r: 34
		g: 211
		b: 238
	})
	draw_text_centered(renderer, 400, 370, 'Press [Space] to Continue', 1, Color{
		r: 226
		g: 232
		b: 240
	})
}

fn draw_game_over_screen(renderer &Renderer, ge &GameEngine) {
	set_render_draw_color(renderer, 15, 23, 42, 220)
	overlay := Rect{
		x: 0
		y: 0
		w: 800
		h: 600
	}
	render_fill_rect(renderer, &overlay)

	draw_text_centered(renderer, 400, 220, 'GAME OVER', 4, Color{
		r: 239
		g: 68
		b: 68
	})
	draw_text_centered(renderer, 400, 290, 'FINAL SCORE: ${ge.score}', 2, Color{
		r: 250
		g: 204
		b: 21
	})
	draw_text_centered(renderer, 400, 320, 'HIGH SCORE: ${ge.high_score}', 1, Color{
		r: 148
		g: 163
		b: 184
	})

	draw_text_centered(renderer, 400, 400, 'Press [R] or [1] to Replay', 2, Color{
		r: 226
		g: 232
		b: 240
	})
}
