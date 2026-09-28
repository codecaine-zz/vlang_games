module main

import math

pub fn render_game(renderer &Renderer, game &MarbleGame, win_w int, win_h int) {
	// 1. Dark Modern Cyber/Slate Background
	set_render_draw_color(renderer, 10, 14, 24, 255)
	render_clear(renderer)

	// Background grid with perspective depth
	cx := game.cam_x + game.shake_x
	cy := game.cam_y + game.shake_y
	draw_modern_background_grid(renderer, win_w, win_h, cx, cy)

	// 2. Render 3D Isometric Map & Terrain
	render_isometric_map(renderer, game, cx, cy)

	// 3. Render Soft Ambient Occlusion & Drop Shadows
	render_modern_shadows(renderer, game, cx, cy)

	// 4. Render Entities & 3D Shaded Marbles
	render_entities(renderer, game, cx, cy)

	// 5. Render Speed Streaks & Particles
	render_particles(renderer, game, cx, cy)

	// 6. Modern Glassmorphic HUD and Overlays
	render_modern_hud(renderer, game, win_w)
	render_screen_overlays(renderer, game, win_w, win_h)
}

fn draw_modern_background_grid(renderer &Renderer, w int, h int, cx f32, cy f32) {
	spacing := 60
	offset_x := int(f32(math.fmod(f64(cx), f64(spacing))))
	offset_y := int(f32(math.fmod(f64(cy), f64(spacing))))

	set_render_draw_color(renderer, 20, 26, 42, 255)
	for x := -spacing + offset_x; x < w + spacing; x += spacing {
		render_draw_line(renderer, x, 0, x, h)
	}
	for y := -spacing + offset_y; y < h + spacing; y += spacing {
		render_draw_line(renderer, 0, y, w, y)
	}
}

// Render the 3D isometric tiles sorted from back to front
fn render_isometric_map(renderer &Renderer, game &MarbleGame, cx f32, cy f32) {
	tiles := game.level_data.tiles
	h := tiles.len
	if h == 0 { return }
	w := tiles[0].len

	for sum := 0; sum <= w + h - 2; sum++ {
		for y := 0; y < h; y++ {
			x := sum - y
			if x >= 0 && x < w {
				t := tiles[y][x]
				if t.tile_type == .empty { continue }
				if t.tile_type == .disappearing && !t.is_active { continue }
				render_single_tile(renderer, game, x, y, t, cx, cy)
			}
		}
	}
}

fn render_single_tile(renderer &Renderer, game &MarbleGame, gx int, gy int, t Tile, cx f32, cy f32) {
	fx := f32(gx)
	fy := f32(gy)

	mut z0 := t.base_z
	mut z1 := t.base_z
	mut z2 := t.base_z
	mut z3 := t.base_z

	match t.tile_type {
		.slope_x_up {
			z1 += t.height
			z2 += t.height
		}
		.slope_x_down {
			z0 += t.height
			z3 += t.height
		}
		.slope_y_up {
			z2 += t.height
			z3 += t.height
		}
		.slope_y_down {
			z0 += t.height
			z1 += t.height
		}
		.slope_xy_down {
			z0 += t.height
			z1 += t.height * 0.5
			z3 += t.height * 0.5
		}
		.slope_xy_up {
			z2 += t.height
			z1 += t.height * 0.5
			z3 += t.height * 0.5
		}
		.wave {
			freq := 2.5
			amp := f32(0.4)
			gt := game.global_time * 4.0
			z0 += f32(math.sin(f64(gt + (fx + fy) * f32(freq)))) * amp
			z1 += f32(math.sin(f64(gt + (fx + 1.0 + fy) * f32(freq)))) * amp
			z2 += f32(math.sin(f64(gt + (fx + 1.0 + fy + 1.0) * f32(freq)))) * amp
			z3 += f32(math.sin(f64(gt + (fx + fy + 1.0) * f32(freq)))) * amp
		}
		else {}
	}

	// Project corners to screen
	s0x, s0y := world_to_screen(fx, fy, z0, cx, cy)
	s1x, s1y := world_to_screen(fx + 1.0, fy, z1, cx, cy)
	s2x, s2y := world_to_screen(fx + 1.0, fy + 1.0, z2, cx, cy)
	s3x, s3y := world_to_screen(fx, fy + 1.0, z3, cx, cy)

	// Base bottom corners for 3D wall extrusion
	floor_z := f32(0.0)
	b1x, b1y := world_to_screen(fx + 1.0, fy, floor_z, cx, cy)
	b2x, b2y := world_to_screen(fx + 1.0, fy + 1.0, floor_z, cx, cy)
	b3x, b3y := world_to_screen(fx, fy + 1.0, floor_z, cx, cy)

	// Theme colors
	is_checker := (gx + gy) % 2 == 0
	mut top_r := u8(180)
	mut top_g := u8(190)
	mut top_b := u8(200)

	match t.tile_type {
		.ice {
			top_r = if is_checker { u8(170) } else { u8(215) }
			top_g = if is_checker { u8(220) } else { u8(245) }
			top_b = if is_checker { u8(255) } else { u8(255) }
		}
		.wave {
			top_r = if is_checker { u8(80) } else { u8(120) }
			top_g = if is_checker { u8(150) } else { u8(190) }
			top_b = if is_checker { u8(230) } else { u8(255) }
		}
		.catapult {
			top_r = 255
			top_g = 210
			top_b = 20
		}
		.tube_in, .tube_out {
			top_r = 50
			top_g = 190
			top_b = 240
		}
		.hazard_acid {
			top_r = 30
			top_g = 220
			top_b = 80
		}
		.goal {
			top_r = if is_checker { u8(250) } else { u8(25) }
			top_g = if is_checker { u8(250) } else { u8(25) }
			top_b = if is_checker { u8(250) } else { u8(25) }
		}
		else {
			match game.level_data.def.theme_color {
				0 { // Practice: Blue / Slate
					top_r = if is_checker { u8(140) } else { u8(175) }
					top_g = if is_checker { u8(160) } else { u8(195) }
					top_b = if is_checker { u8(200) } else { u8(230) }
				}
				1 { // Beginner: Emerald
					top_r = if is_checker { u8(110) } else { u8(145) }
					top_g = if is_checker { u8(180) } else { u8(215) }
					top_b = if is_checker { u8(130) } else { u8(165) }
				}
				2 { // Intermediate: Amber / Sunset
					top_r = if is_checker { u8(215) } else { u8(240) }
					top_g = if is_checker { u8(130) } else { u8(165) }
					top_b = if is_checker { u8(90) } else { u8(120) }
				}
				3 { // Aerial: Cyan / Platinum
					top_r = if is_checker { u8(130) } else { u8(165) }
					top_g = if is_checker { u8(200) } else { u8(230) }
					top_b = if is_checker { u8(235) } else { u8(255) }
				}
				4 { // Silly: Neon Violet
					top_r = if is_checker { u8(190) } else { u8(220) }
					top_g = if is_checker { u8(110) } else { u8(145) }
					top_b = if is_checker { u8(220) } else { u8(250) }
				}
				else { // Ultimate: Golden Obsidian
					top_r = if is_checker { u8(230) } else { u8(255) }
					top_g = if is_checker { u8(195) } else { u8(225) }
					top_b = if is_checker { u8(70) } else { u8(110) }
				}
			}
		}
	}

	// 1. Draw Extruded Left Wall (Dark Ambient Shadow)
	if z3 > floor_z || z2 > floor_z {
		wall_l_r := u8(top_r * 40 / 100)
		wall_l_g := u8(top_g * 40 / 100)
		wall_l_b := u8(top_b * 40 / 100)
		fill_quad(renderer, int(s3x), int(s3y), int(s2x), int(s2y), int(b2x), int(b2y), int(b3x), int(b3y), wall_l_r, wall_l_g, wall_l_b)
	}

	// 2. Draw Extruded Right Wall (Mid Tone Shading)
	if z2 > floor_z || z1 > floor_z {
		wall_r_r := u8(top_r * 62 / 100)
		wall_r_g := u8(top_g * 62 / 100)
		wall_r_b := u8(top_b * 62 / 100)
		fill_quad(renderer, int(s2x), int(s2y), int(s1x), int(s1y), int(b1x), int(b1y), int(b2x), int(b2y), wall_r_r, wall_r_g, wall_r_b)
	}

	// 3. Draw Top Diamond Face
	fill_quad(renderer, int(s0x), int(s0y), int(s1x), int(s1y), int(s2x), int(s2y), int(s3x), int(s3y), top_r, top_g, top_b)

	// Modern Bevelled Edge Outlines
	set_render_draw_color(renderer, u8(math.min(255, int(top_r) + 25)), u8(math.min(255, int(top_g) + 25)), u8(math.min(255, int(top_b) + 25)), 255)
	render_draw_line(renderer, int(s0x), int(s0y), int(s1x), int(s1y))
	render_draw_line(renderer, int(s0x), int(s0y), int(s3x), int(s3y))

	set_render_draw_color(renderer, u8(top_r * 70 / 100), u8(top_g * 70 / 100), u8(top_b * 70 / 100), 255)
	render_draw_line(renderer, int(s1x), int(s1y), int(s2x), int(s2y))
	render_draw_line(renderer, int(s3x), int(s3y), int(s2x), int(s2y))

	// Special tile decor
	match t.tile_type {
		.catapult {
			mid_x := (s0x + s1x + s2x + s3x) * 0.25
			mid_y := (s0y + s1y + s2y + s3y) * 0.25
			draw_filled_circle(renderer, int(mid_x), int(mid_y), 7, 255, 60, 40)
			draw_filled_circle(renderer, int(mid_x), int(mid_y), 3, 255, 255, 255)
		}
		.tube_in, .tube_out {
			mid_x := (s0x + s1x + s2x + s3x) * 0.25
			mid_y := (s0y + s1y + s2y + s3y) * 0.25
			draw_filled_circle(renderer, int(mid_x), int(mid_y), 9, 15, 30, 50)
			draw_filled_circle(renderer, int(mid_x), int(mid_y), 6, 80, 200, 255)
			draw_filled_circle(renderer, int(mid_x), int(mid_y), 3, 255, 255, 255)
		}
		.goal {
			mid_x := (s0x + s1x + s2x + s3x) * 0.25
			mid_y := (s0y + s1y + s2y + s3y) * 0.25
			set_render_draw_color(renderer, 255, 215, 0, 255)
			render_draw_line(renderer, int(mid_x - 12), int(mid_y), int(mid_x - 12), int(mid_y - 32))
			render_draw_line(renderer, int(mid_x + 12), int(mid_y), int(mid_x + 12), int(mid_y - 32))
			render_draw_line(renderer, int(mid_x - 12), int(mid_y - 32), int(mid_x + 12), int(mid_y - 32))
		}
		else {}
	}
}

fn fill_quad(renderer &Renderer, x0 int, y0 int, x1 int, y1 int, x2 int, y2 int, x3 int, y3 int, r u8, g u8, b u8) {
	set_render_draw_color(renderer, r, g, b, 255)
	fill_triangle(renderer, x0, y0, x1, y1, x2, y2)
	fill_triangle(renderer, x0, y0, x2, y2, x3, y3)
}

fn fill_triangle(renderer &Renderer, x0 int, y0 int, x1 int, y1 int, x2 int, y2 int) {
	render_fill_triangle(renderer, f32(x0), f32(y0), f32(x1), f32(y1), f32(x2), f32(y2))
}

fn draw_filled_circle(renderer &Renderer, cx int, cy int, radius int, r u8, g u8, b u8) {
	set_render_draw_color(renderer, r, g, b, 255)
	render_fill_circle(renderer, f32(cx), f32(cy), f32(radius))
}

// Dual-layer soft contact + drop shadow
fn render_modern_shadows(renderer &Renderer, game &MarbleGame, cx f32, cy f32) {
	if game.player.state == .rolling || game.player.state == .airborne {
		render_single_modern_shadow(renderer, game, game.player.pos, cx, cy)
	}
	if game.has_rival && (game.rival.state == .rolling || game.rival.state == .airborne) {
		render_single_modern_shadow(renderer, game, game.rival.pos, cx, cy)
	}
}

fn render_single_modern_shadow(renderer &Renderer, game &MarbleGame, pos Vec3, cx f32, cy f32) {
	valid, ground_z, _, _, _ := get_surface_info(game.level_data.tiles, pos.x, pos.y, game.global_time)
	if !valid { return }

	sx, sy := world_to_screen(pos.x, pos.y, ground_z, cx, cy)
	altitude := math.max(0.0, f64(pos.z - ground_z))
	scale := f32(math.max(0.25, 1.0 - altitude * 0.12))

	// Layer 1: Diffuse outer shadow
	rad_x := int(15.0 * scale)
	rad_y := int(8.0 * scale)
	set_render_draw_color(renderer, 0, 0, 0, 140)
	for dy := -rad_y; dy <= rad_y; dy++ {
		dx_limit := int(f32(rad_x) * f32(math.sqrt(math.max(0.0, 1.0 - f64(dy * dy) / f64(rad_y * rad_y)))))
		render_draw_line(renderer, int(sx) - dx_limit, int(sy) + dy, int(sx) + dx_limit, int(sy) + dy)
	}

	// Layer 2: Tight contact ambient occlusion (when near ground)
	if altitude < 0.4 {
		c_rad_x := int(9.0 * scale)
		c_rad_y := int(5.0 * scale)
		set_render_draw_color(renderer, 0, 0, 0, 220)
		for dy := -c_rad_y; dy <= c_rad_y; dy++ {
			dx_limit := int(f32(c_rad_x) * f32(math.sqrt(math.max(0.0, 1.0 - f64(dy * dy) / f64(c_rad_y * c_rad_y)))))
			render_draw_line(renderer, int(sx) - dx_limit, int(sy) + dy, int(sx) + dx_limit, int(sy) + dy)
		}
	}
}

fn render_entities(renderer &Renderer, game &MarbleGame, cx f32, cy f32) {
	for m in game.munchers {
		sx, sy := world_to_screen(m.pos.x, m.pos.y, m.pos.z, cx, cy)
		render_muncher(renderer, int(sx), int(sy), m.jaw_open)
	}

	for b in game.level_data.bumpers {
		sx, sy := world_to_screen(b.x, b.y, b.z, cx, cy)
		draw_filled_circle(renderer, int(sx), int(sy), 10, 240, 50, 50)
		draw_filled_circle(renderer, int(sx), int(sy), 6, 255, 255, 255)
		draw_filled_circle(renderer, int(sx), int(sy), 2, 240, 50, 50)
	}

	for sw in game.sweepers {
		sx, sy := world_to_screen(sw.pos.x, sw.pos.y, sw.z, cx, cy)
		render_sweeper(renderer, int(sx), int(sy))
	}

	if game.has_rival {
		render_modern_marble(renderer, &game.rival, false, cx, cy)
	}

	render_modern_marble(renderer, &game.player, true, cx, cy)

	for b in game.birds {
		sx, sy := world_to_screen(b.pos.x, b.pos.y, b.pos.z, cx, cy)
		render_bird(renderer, int(sx), int(sy), b.patrol_dir_x, b.timer)
	}
}

// 3D Phong Shaded Marble with Multi-Point Lighting & Fresnel Rim
fn render_modern_marble(renderer &Renderer, m &Marble, is_player bool, cx f32, cy f32) {
	match m.state {
		.rolling, .airborne, .finished {
			sx, sy := world_to_screen(m.pos.x, m.pos.y, m.pos.z, cx, cy)
			rad := 12

			// Outer base sphere
			draw_filled_circle(renderer, int(sx), int(sy), rad, 8, 12, 18)

			for dy := -rad; dy <= rad; dy++ {
				dx_lim := int(math.sqrt(f64(rad * rad - dy * dy)))
				for dx := -dx_lim; dx <= dx_lim; dx++ {
					// 3D Sphere surface normal
					nx := f32(dx) / f32(rad)
					ny := f32(dy) / f32(rad)
					nz := f32(math.sqrt(math.max(0.0, 1.0 - f64(nx * nx + ny * ny))))

					// Primary Key Light (-0.5, -0.6, 0.7)
					key_dot := nx * (-0.45) + ny * (-0.60) + nz * 0.65
					key_light := math.max(0.0, f64(key_dot))

					// Secondary Warm Ambient Fill Light (0.5, 0.6, 0.3)
					fill_dot := nx * 0.5 + ny * 0.6 + nz * 0.3
					fill_light := math.max(0.0, f64(fill_dot)) * 0.35

					// Fresnel rim glow around edges (1.0 - nz)
					fresnel := math.pow(1.0 - f64(nz), 2.5) * 0.6

					total_light := math.max(0.12, math.min(1.0, key_light + fill_light + fresnel))

					// 3D Rolling texture pattern
					surf_u := nx * 0.8 + f32(math.sin(f64(m.rot_y))) * 0.55
					surf_v := ny * 0.8 + f32(math.cos(f64(m.rot_x))) * 0.55
					stripe := int(math.floor(f64((surf_u + surf_v) * 4.2))) % 2 == 0

					mut cr := f64(0)
					mut cg := f64(0)
					mut cb := f64(0)

					if is_player {
						if stripe {
							cr = 40.0 * total_light + 20.0
							cg = 140.0 * total_light + 30.0
							cb = 255.0 * total_light
						} else {
							cr = 240.0 * total_light
							cg = 245.0 * total_light
							cb = 255.0 * total_light
						}
						// Turbo Boost Neon Glow
						if m.turbo_active {
							cr = math.min(255.0, cr + 70.0)
							cg = math.min(255.0, cg + 90.0)
							cb = math.min(255.0, cb + 40.0)
						}
					} else {
						// Rival Black/Steel Marble
						if stripe {
							cr = 35.0 * total_light + 10.0
							cg = 35.0 * total_light + 10.0
							cb = 40.0 * total_light + 10.0
						} else {
							cr = 160.0 * total_light + 20.0
							cg = 165.0 * total_light + 20.0
							cb = 175.0 * total_light + 20.0
						}
					}

					// Glossy Specular Highlight Spot
					spec := math.pow(math.max(0.0, f64(key_dot)), 16.0)
					if spec > 0.15 {
						cr = math.min(255.0, cr + spec * 220.0)
						cg = math.min(255.0, cg + spec * 220.0)
						cb = math.min(255.0, cb + spec * 240.0)
					}

					set_render_draw_color(renderer, u8(cr), u8(cg), u8(cb), 255)
					render_draw_point(renderer, int(sx) + dx, int(sy) + dy)
				}
			}
		}
		.shattered {
			for shard in m.shards {
				sx, sy := world_to_screen(shard.pos.x, shard.pos.y, shard.pos.z, cx, cy)
				sz := int(shard.size * 32.0)
				rect := Rect{x: int(sx) - sz / 2, y: int(sy) - sz / 2, w: sz, h: sz}
				set_render_draw_color(renderer, 220, 240, 255, 255)
				render_fill_rect(renderer, &rect)
			}
		}
		.reforming {
			sx, sy := world_to_screen(m.pos.x, m.pos.y, m.pos.z, cx, cy)
			ring_rad := int(22.0 * (1.0 - m.state_timer / 0.6))
			draw_filled_circle(renderer, int(sx), int(sy), math.max(3, ring_rad), 80, 220, 255)
		}
		.swallowed {
			sx, sy := world_to_screen(m.pos.x, m.pos.y, m.pos.z, cx, cy)
			draw_filled_circle(renderer, int(sx), int(sy), 8, 30, 120, 220)
		}
		else {}
	}
}

fn render_muncher(renderer &Renderer, sx int, sy int, jaw_open f32) {
	draw_filled_circle(renderer, sx, sy, 13, 20, 190, 60)
	mouth_h := int(jaw_open * 11.0)
	if mouth_h > 1 {
		draw_filled_circle(renderer, sx, sy, mouth_h, 15, 35, 10)
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_draw_line(renderer, sx - 7, sy - mouth_h / 2, sx - 4, sy)
		render_draw_line(renderer, sx + 7, sy - mouth_h / 2, sx + 4, sy)
	}
	draw_filled_circle(renderer, sx - 6, sy - 9, 3, 255, 240, 0)
	draw_filled_circle(renderer, sx + 6, sy - 9, 3, 255, 240, 0)
}

fn render_sweeper(renderer &Renderer, sx int, sy int) {
	rect := Rect{x: sx - 18, y: sy - 6, w: 36, h: 12}
	set_render_draw_color(renderer, 245, 190, 10, 255)
	render_fill_rect(renderer, &rect)
	set_render_draw_color(renderer, 200, 40, 30, 255)
	for x := sx - 16; x <= sx + 16; x += 6 {
		render_draw_line(renderer, x, sy - 6, x, sy + 6)
	}
}

fn render_bird(renderer &Renderer, sx int, sy int, dir_x f32, timer f32) {
	wing_flap := int(f32(math.sin(f64(timer * 12.0))) * 9.0)
	draw_filled_circle(renderer, sx, sy, 7, 180, 60, 200)
	set_render_draw_color(renderer, 220, 110, 240, 255)
	render_draw_line(renderer, sx, sy, sx - 18, sy - wing_flap)
	render_draw_line(renderer, sx, sy, sx + 18, sy - wing_flap)
	beak_dir := if dir_x >= 0 { 9 } else { -9 }
	set_render_draw_color(renderer, 255, 215, 0, 255)
	render_draw_line(renderer, sx, sy, sx + beak_dir, sy + 2)
}

fn render_particles(renderer &Renderer, game &MarbleGame, cx f32, cy f32) {
	for p in game.particles {
		sx, sy := world_to_screen(p.pos.x, p.pos.y, p.pos.z, cx, cy)
		sz := int(p.size * 22.0)
		rect := Rect{x: int(sx) - sz / 2, y: int(sy) - sz / 2, w: sz, h: sz}
		set_render_draw_color(renderer, p.r, p.g, p.b, 255)
		render_fill_rect(renderer, &rect)
	}
}

// Glassmorphic Modern HUD with Speedometer Dial
fn render_modern_hud(renderer &Renderer, game &MarbleGame, win_w int) {
	hud_h := 50
	// Translucent Frosted Bar
	rect := Rect{x: 0, y: 0, w: win_w, h: hud_h}
	set_render_draw_color(renderer, 8, 12, 22, 235)
	render_fill_rect(renderer, &rect)
	// Neon Accent Line
	set_render_draw_color(renderer, 40, 180, 255, 255)
	render_draw_line(renderer, 0, hud_h - 1, win_w, hud_h - 1)

	// 1. TIME REMAINING
	time_int := int(math.ceil(f64(game.time_left)))
	time_col := if time_int < 10 {
		Color{r: 255, g: 50, b: 50}
	} else {
		Color{r: 255, g: 220, b: 20}
	}
	draw_text_shadow(renderer, 'TIME', 25, 8, 2, Color{r: 160, g: 190, b: 230}, Color{r: 0, g: 0, b: 0})
	draw_text_shadow(renderer, '${time_int:02d}s', 25, 26, 2, time_col, Color{r: 0, g: 0, b: 0})

	// 2. SPEEDOMETER DIAL & MPH
	speed_mph := int(game.player.speed_mph)
	draw_text_shadow(renderer, 'SPEED', 140, 8, 2, Color{r: 160, g: 190, b: 230}, Color{r: 0, g: 0, b: 0})
	draw_text_shadow(renderer, '${speed_mph:02d} MPH', 140, 26, 2, Color{r: 80, g: 255, b: 180}, Color{r: 0, g: 0, b: 0})

	// Speed bar
	bar_w := 60
	speed_prog := math.min(1.0, f64(game.player.speed_mph) / 60.0)
	s_bg := Rect{x: 235, y: 28, w: bar_w, h: 10}
	set_render_draw_color(renderer, 25, 35, 55, 255)
	render_fill_rect(renderer, &s_bg)
	s_fill := Rect{x: 235, y: 28, w: int(f64(bar_w) * speed_prog), h: 10}
	set_render_draw_color(renderer, 60, 220, 255, 255)
	render_fill_rect(renderer, &s_fill)

	// 3. SCORE & HIGH
	draw_text_shadow(renderer, 'SCORE', 330, 8, 2, Color{r: 160, g: 190, b: 230}, Color{r: 0, g: 0, b: 0})
	draw_text_shadow(renderer, '${game.score:06d}', 330, 26, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})

	draw_text_shadow(renderer, 'HIGH', 460, 8, 2, Color{r: 160, g: 190, b: 230}, Color{r: 0, g: 0, b: 0})
	draw_text_shadow(renderer, '${game.high_score:06d}', 460, 26, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})

	// 4. LEVEL NAME
	draw_text_shadow(renderer, 'RACE ${game.current_level}', 590, 8, 2, Color{r: 255, g: 180, b: 60}, Color{r: 0, g: 0, b: 0})
	draw_text_shadow(renderer, game.level_data.def.name, 590, 26, 2, Color{r: 220, g: 240, b: 255}, Color{r: 0, g: 0, b: 0})

	// 5. Mini Progress Bar
	start_y := game.level_data.def.start_y
	goal_y := game.level_data.def.goal_y
	total_dist := math.max(1.0, f64(goal_y - start_y))
	cur_prog := math.min(1.0, math.max(0.0, f64(game.player.pos.y - start_y) / total_dist))

	gauge_x := win_w - 110
	gauge_w := 85
	g_bg := Rect{x: gauge_x, y: 26, w: gauge_w, h: 12}
	set_render_draw_color(renderer, 25, 35, 55, 255)
	render_fill_rect(renderer, &g_bg)
	g_fill := Rect{x: gauge_x, y: 26, w: int(f64(gauge_w) * cur_prog), h: 12}
	set_render_draw_color(renderer, 40, 240, 120, 255)
	render_fill_rect(renderer, &g_fill)
	draw_text(renderer, 'GOAL', gauge_x, 10, 1, Color{r: 180, g: 220, b: 255})
}

fn render_screen_overlays(renderer &Renderer, game &MarbleGame, win_w int, win_h int) {
	cx := win_w / 2

	match game.state {
		.title {
			rect := Rect{x: 60, y: 70, w: win_w - 120, h: win_h - 120}
			set_render_draw_color(renderer, 10, 15, 30, 240)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 40, 200, 255, 255)
			render_draw_rect(renderer, &rect)

			draw_text_centered_shadow(renderer, 'MARBLE MADNESS', cx, 100, 4, Color{r: 255, g: 215, b: 0}, Color{r: 180, g: 80, b: 0})
			draw_text_centered_shadow(renderer, 'MODERNIZED 3D ARCADE REMAKE', cx, 145, 2, Color{r: 100, g: 220, b: 255}, Color{r: 0, g: 0, b: 0})

			draw_text_centered_shadow(renderer, 'PRESS SPACE OR ENTER TO START', cx, 200, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, '[ 1 - 6 ] PRACTICE LEVEL SELECT', cx, 240, 2, Color{r: 255, g: 200, b: 80}, Color{r: 0, g: 0, b: 0})

			// Controls Info
			draw_text_centered_shadow(renderer, '--- MODERN CONTROLS ---', cx, 290, 2, Color{r: 180, g: 200, b: 240}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'MOUSE / TRACKBALL : 360 DEGREE STEERING', cx, 320, 2, Color{r: 80, g: 255, b: 180}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'WASD / ARROWS : SMOOTH 8-WAY MOVEMENT', cx, 345, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'SPACE / J / Z : TURBO BOOST & MICRO-JUMP', cx, 370, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'TAB : TOGGLE MOUSE CAPTURE', cx, 395, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'T : TOGGLE SCREEN vs DIAGONAL MODES', cx, 420, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'F11 : TOGGLE FULLSCREEN | M : SOUND | P : PAUSE', cx, 445, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.level_intro {
			draw_text_centered_shadow(renderer, 'GET READY!', cx, win_h / 2 - 40, 4, Color{r: 255, g: 220, b: 0}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'RACE ${game.current_level}: ${game.level_data.def.name}', cx, win_h / 2 + 10, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.level_clear {
			box := Rect{x: cx - 220, y: win_h / 2 - 90, w: 440, h: 180}
			set_render_draw_color(renderer, 10, 20, 40, 240)
			render_fill_rect(renderer, &box)
			set_render_draw_color(renderer, 40, 220, 255, 255)
			render_draw_rect(renderer, &box)

			draw_text_centered_shadow(renderer, 'RACE COMPLETED!', cx, win_h / 2 - 70, 3, Color{r: 40, g: 255, b: 120}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'TIME BONUS: +${game.bonus_time_awarded} SECONDS', cx, win_h / 2 - 20, 2, Color{r: 255, g: 220, b: 0}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'SCORE BONUS: +${game.bonus_score_awarded} PTS', cx, win_h / 2 + 10, 2, Color{r: 100, g: 220, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'ADVANCING TO NEXT RACE...', cx, win_h / 2 + 45, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.game_over {
			draw_text_centered_shadow(renderer, 'OUT OF TIME!', cx, win_h / 2 - 50, 4, Color{r: 255, g: 50, b: 50}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'GAME OVER', cx, win_h / 2, 4, Color{r: 255, g: 220, b: 0}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'FINAL SCORE: ${game.score:06d}', cx, win_h / 2 + 50, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'PRESS SPACE TO PLAY AGAIN', cx, win_h / 2 + 80, 2, Color{r: 100, g: 220, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.victory {
			box := Rect{x: cx - 260, y: win_h / 2 - 120, w: 520, h: 240}
			set_render_draw_color(renderer, 10, 20, 50, 245)
			render_fill_rect(renderer, &box)
			set_render_draw_color(renderer, 255, 215, 0, 255)
			render_draw_rect(renderer, &box)

			draw_text_centered_shadow(renderer, 'CHAMPION!', cx, win_h / 2 - 100, 4, Color{r: 255, g: 215, b: 0}, Color{r: 180, g: 80, b: 0})
			draw_text_centered_shadow(renderer, 'YOU CONQUERED THE ULTIMATE RACE!', cx, win_h / 2 - 45, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'FINAL SCORE: ${game.score:06d}', cx, win_h / 2 - 10, 3, Color{r: 40, g: 255, b: 120}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'MARBLE MASTER TROPHY AWARDED', cx, win_h / 2 + 35, 2, Color{r: 100, g: 220, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'PRESS SPACE TO RETURN TO TITLE', cx, win_h / 2 + 75, 2, Color{r: 255, g: 200, b: 80}, Color{r: 0, g: 0, b: 0})
		}
		.paused {
			draw_text_centered_shadow(renderer, 'PAUSED', cx, win_h / 2 - 20, 4, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		else {}
	}
}
