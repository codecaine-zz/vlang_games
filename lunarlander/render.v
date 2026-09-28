import math
import os
import rand

pub struct LunarLanderTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm LunarLanderTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/lunarlander.png',
		'./assets/sprites/lunarlander.png',
		'../assets/sprites/lunarlander.png',
		'lunarlander/assets/sprites/lunarlander.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('lunarlander Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn render_lunarlander_game(renderer &Renderer, mut g LunarLanderGame, tex &Texture) {
	// Deep space black background
	set_render_draw_color(renderer, 5, 5, 12, 255)
	render_clear(renderer)

	mut sx := 0
	mut sy := 0
	if g.shake_trauma > 0 {
		trauma_pwr := g.shake_trauma * g.shake_trauma
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

	// 1. Draw Mountain Terrain Line
	set_render_draw_color(renderer, 150, 160, 180, 255)
	for i in 0 .. g.terrain_points.len - 1 {
		p1 := g.terrain_points[i]
		p2 := g.terrain_points[i + 1]
		render_draw_line(renderer, int(p1.x), int(p1.y), int(p2.x), int(p2.y))
	}

	// 2. Draw Landing Pads with Multipliers
	for pad in g.pads {
		set_render_draw_color(renderer, 0, 255, 100, 255)
		p_line := Rect{ x: int(pad.start_x), y: int(pad.y), w: int(pad.end_x - pad.start_x), h: 4 }
		render_fill_rect(renderer, &p_line)

		// Multiplier Label
		draw_text(renderer, int(pad.start_x) + 8, int(pad.y) + 8, "${pad.multiplier}X", 1, Color{ r: 0, g: 255, b: 100, a: 255 })
	}

	// 3. Draw Particles
	for p in g.particles {
		alpha := u8(p.life / p.max_life * 255.0)
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		rect := Rect{ x: int(p.x) - 1, y: int(p.y) - 1, w: 3, h: 3 }
		render_fill_rect(renderer, &rect)
	}

	// 4. Draw Vector Lander Ship
	if g.state == .playing || g.state == .touchdown || g.state == .paused {
		draw_lunar_lander(renderer, g.x, g.y, g.angle, g.key_thrust, g.key_rot_left, g.key_rot_right, tex)
	}

	// 5. Draw Telemetry HUD
	draw_text(renderer, 20, 15, "SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	draw_text(renderer, 320, 15, "HIGH: ${g.high_score}", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
	draw_text(renderer, 650, 15, "SHIPS: ${g.lives}", 2, Color{ r: 0, g: 255, b: 255, a: 255 })

	// Telemetry Metrics
	v_speed := int(g.vy)
	h_speed := int(g.vx)
	v_color := if g.vy > 65.0 { Color{ r: 255, g: 50, b: 50, a: 255 } } else { Color{ r: 0, g: 255, b: 100, a: 255 } }

	draw_text(renderer, 20, 45, "HORIZ SPEED: ${h_speed} M/S", 1, Color{ r: 200, g: 200, b: 200, a: 255 })
	draw_text(renderer, 20, 60, "VERT SPEED:  ${v_speed} M/S", 1, v_color)

	// Fuel Bar
	draw_text(renderer, 600, 45, "FUEL", 1, Color{ r: 200, g: 200, b: 200, a: 255 })
	fuel_w := int((g.fuel / g.max_fuel) * 120.0)
	if fuel_w > 0 {
		f_color := if g.fuel < 25.0 { Color{ r: 255, g: 50, b: 50, a: 255 } } else { Color{ r: 0, g: 200, b: 255, a: 255 } }
		set_render_draw_color(renderer, f_color.r, f_color.g, f_color.b, 255)
		f_bar := Rect{ x: 650, y: 45, w: fuel_w, h: 12 }
		render_fill_rect(renderer, &f_bar)
	}

	// 6. Overlay Menus
	if g.state == .menu {
		draw_text_centered(renderer, 400, 180, "LUNAR LANDER", 4, Color{ r: 0, g: 200, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 240, "VECTOR THRUST GRAVITY SIMULATOR", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
		draw_text_centered(renderer, 400, 340, "PRESS SPACE TO START", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 400, "CONTROLS: A/D OR ARROWS ROTATE | SPACE THRUST", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
		draw_text_centered(renderer, 400, 420, "LAND SOFTLY ON GREEN PADS (< 65 M/S VERT SPEED)", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
	} else if g.state == .touchdown {
		if tex != unsafe { nil } {
			// Draw astronaut & flag beside lander
			ast_src := Rect{x: 0, y: 128, w: 64, h: 64}
			ast_dst := Rect{x: int(g.x) + 26, y: int(g.y) - 8, w: 32, h: 32}
			render_copy(renderer, tex, &ast_src, &ast_dst)

			flag_src := Rect{x: 64, y: 128, w: 64, h: 64}
			flag_dst := Rect{x: int(g.x) + 54, y: int(g.y) - 16, w: 32, h: 40}
			render_copy(renderer, tex, &flag_src, &flag_dst)
		}
		draw_text_centered(renderer, 400, 220, "SUCCESSFUL TOUCHDOWN!", 3, Color{ r: 0, g: 255, b: 100, a: 255 })
		draw_text_centered(renderer, 400, 270, "+${g.touchdown_pts} POINTS BONUS", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
		draw_text_centered(renderer, 400, 340, "PRESS SPACE TO NEXT LANDING", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	} else if g.state == .crashed {
		draw_text_centered(renderer, 400, 220, "LANDER DESTROYED - HARD IMPACT!", 3, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 310, "PRESS SPACE TO TRY AGAIN", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	} else if g.state == .game_over {
		draw_text_centered(renderer, 400, 220, "GAME OVER - ALL LANDERS LOST", 4, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 310, "FINAL SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 370, "PRESS SPACE OR R TO RESTART", 2, Color{ r: 0, g: 255, b: 100, a: 255 })
	} else if g.state == .paused {
		draw_text_centered(renderer, 400, 280, "- PAUSED -", 3, Color{ r: 255, g: 255, b: 0, a: 255 })
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}

fn draw_lunar_lander(renderer &Renderer, x f32, y f32, angle f32, is_thrusting bool, is_rotating_left bool, is_rotating_right bool, tex &Texture) {
	if tex != unsafe { nil } {
		col_x := if is_thrusting {
			1 * 64
		} else if is_rotating_left {
			2 * 64
		} else if is_rotating_right {
			3 * 64
		} else {
			0
		}
		src := Rect{x: col_x, y: 0, w: 64, h: 64}
		dst := Rect{x: int(x) - 24, y: int(y) - 24, w: 48, h: 48}
		angle_deg := f64(angle * 180.0 / f32(math.pi))
		render_copy_ex(renderer, tex, &src, &dst, angle_deg, unsafe { nil }, RendererFlip.none)
		return
	}

	cos_a := f32(math.cos(angle))
	sin_a := f32(math.sin(angle))

	// 16-Bit Apollo Lunar Excursion Module (LEM)
	// 1. Lower Descent Stage (Gold Mylar Thermal Foil with Brass Bevels)
	descent_pts := [
		Point{ x: -12, y: 0 },
		Point{ x: 12, y: 0 },
		Point{ x: 10, y: 10 },
		Point{ x: -10, y: 10 },
	]
	set_render_draw_color(renderer, 235, 185, 30, 255)
	for i in 0 .. descent_pts.len {
		p1 := descent_pts[i]
		p2 := descent_pts[(i + 1) % descent_pts.len]
		rx1 := x + (p1.x * cos_a - p1.y * sin_a)
		ry1 := y + (p1.x * sin_a + p1.y * cos_a)
		rx2 := x + (p2.x * cos_a - p2.y * sin_a)
		ry2 := y + (p2.x * sin_a + p2.y * cos_a)
		render_draw_line(renderer, int(rx1), int(ry1), int(rx2), int(ry2))
	}

	// 2. Upper Ascent Stage Cabin (White/Alloy with Cyan Cockpit Triangular Windows)
	ascent_pts := [
		Point{ x: -8, y: -12 },
		Point{ x: 8, y: -12 },
		Point{ x: 11, y: -2 },
		Point{ x: -11, y: -2 },
	]
	set_render_draw_color(renderer, 240, 245, 255, 255)
	for i in 0 .. ascent_pts.len {
		p1 := ascent_pts[i]
		p2 := ascent_pts[(i + 1) % ascent_pts.len]
		rx1 := x + (p1.x * cos_a - p1.y * sin_a)
		ry1 := y + (p1.x * sin_a + p1.y * cos_a)
		rx2 := x + (p2.x * cos_a - p2.y * sin_a)
		ry2 := y + (p2.x * sin_a + p2.y * cos_a)
		render_draw_line(renderer, int(rx1), int(ry1), int(rx2), int(ry2))
	}

	// Triangular Cockpit Windows (Cyan Glass)
	set_render_draw_color(renderer, 0, 220, 255, 255)
	w_lx := x + (-4.0 * cos_a - (-7.0) * sin_a)
	w_ly := y + (-4.0 * sin_a + (-7.0) * cos_a)
	w_rx := x + (4.0 * cos_a - (-7.0) * sin_a)
	w_ry := y + (4.0 * sin_a + (-7.0) * cos_a)
	render_draw_point(renderer, int(w_lx), int(w_ly))
	render_draw_point(renderer, int(w_rx), int(w_ry))

	// 3. RCS Quad Thrusters on sides
	set_render_draw_color(renderer, 160, 170, 185, 255)
	rcs_l_x := x + (-12.0 * cos_a - (-6.0) * sin_a)
	rcs_l_y := y + (-12.0 * sin_a + (-6.0) * cos_a)
	rcs_r_x := x + (12.0 * cos_a - (-6.0) * sin_a)
	rcs_r_y := y + (12.0 * sin_a + (-6.0) * cos_a)
	render_draw_line(renderer, int(rcs_l_x), int(rcs_l_y), int(rcs_l_x - 3.0 * cos_a), int(rcs_l_y - 3.0 * sin_a))
	render_draw_line(renderer, int(rcs_r_x), int(rcs_r_y), int(rcs_r_x + 3.0 * cos_a), int(rcs_r_y + 3.0 * sin_a))

	// 4. Landing Struts & Footpad Dishes
	set_render_draw_color(renderer, 200, 200, 210, 255)
	leg_l_x := x + (-14.0 * cos_a - 16.0 * sin_a)
	leg_l_y := y + (-14.0 * sin_a + 16.0 * cos_a)
	leg_r_x := x + (14.0 * cos_a - 16.0 * sin_a)
	leg_r_y := y + (14.0 * sin_a + 16.0 * cos_a)

	render_draw_line(renderer, int(x - 8.0 * cos_a), int(y - 8.0 * sin_a), int(leg_l_x), int(leg_l_y))
	render_draw_line(renderer, int(x + 8.0 * cos_a), int(y + 8.0 * sin_a), int(leg_r_x), int(leg_r_y))

	// Footpads
	set_render_draw_color(renderer, 235, 185, 30, 255)
	render_draw_line(renderer, int(leg_l_x - 4.0 * cos_a), int(leg_l_y), int(leg_l_x + 4.0 * cos_a), int(leg_l_y))
	render_draw_line(renderer, int(leg_r_x - 4.0 * cos_a), int(leg_r_y), int(leg_r_x + 4.0 * cos_a), int(leg_r_y))
}
