module main

import math
import os

pub struct WorldRunnerTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm WorldRunnerTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/worldrunner.png',
		'./assets/sprites/worldrunner.png',
		'../assets/sprites/worldrunner.png',
		'worldrunner/assets/sprites/worldrunner.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('worldrunner Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn render_game(renderer &Renderer, game &WorldRunnerGame, win_w int, win_h int, tex &Texture) {
	// 1. Render Atmospheric Skybox, Nebula & Hyperspace Warp
	render_skybox_and_nebula(renderer, game, win_w, win_h)

	// 2. Render Infinite 3D Scanline Checkerboard Floor with Dynamic Glow
	render_3d_floor_hd(renderer, game, win_w, win_h)

	// 3. Render Volumetric 3D Obstacles & Items
	render_3d_volumetric_obstacles(renderer, game, win_w, win_h, tex)

	// 4. Render Segmented Serpent Dragon Boss
	if game.has_boss && game.boss.active {
		render_dragon_boss_hd(renderer, game, win_w, win_h, tex)
	}

	// 5. Render Glowing Laser Bolts & Smart Lock-On Reticle
	render_lasers_hd(renderer, game, win_w, win_h)
	render_smart_reticle(renderer, game, win_w, win_h)

	// 6. Render 3D Shaded Player Commando & Jetpack Exhaust
	render_player_commando_hd(renderer, game, win_w, win_h, tex)

	// 7. Render 3D Shrapnel Particles
	render_particles_3d(renderer, game, win_w, win_h)

	// 8. Render Floating Pop Text
	render_pop_texts(renderer, game)

	// 9. Render Glassmorphic Modern HUD & Overlays
	render_modern_hud(renderer, game, win_w)
	render_screen_overlays(renderer, game, win_w, win_h)
}

// 1. Atmospheric Skybox, Glowing Planet & Hyperspace Warp Streaks
fn render_skybox_and_nebula(renderer &Renderer, game &WorldRunnerGame, win_w int, win_h int) {
	theme := game.theme
	horizon_y := int(f32(win_h) * 0.52 + game.shake_y)

	// Sky Gradient
	for y := 0; y < horizon_y; y++ {
		t := f32(y) / f32(horizon_y)
		r := u8(f32(theme.sky_top.r) * (1.0 - t) + f32(theme.sky_bot.r) * t)
		g := u8(f32(theme.sky_top.g) * (1.0 - t) + f32(theme.sky_bot.g) * t)
		b := u8(f32(theme.sky_top.b) * (1.0 - t) + f32(theme.sky_bot.b) * t)
		set_render_draw_color(renderer, r, g, b, 255)
		render_draw_line(renderer, 0, y, win_w, y)
	}

	// Nebula Clouds
	neb := theme.nebula_col
	draw_filled_circle(renderer, win_w * 3 / 4, horizon_y / 2, 75, u8(neb.r * 50 / 100), u8(neb.g * 50 / 100), u8(neb.b * 50 / 100))
	draw_filled_circle(renderer, win_w / 4, horizon_y / 3, 55, u8(neb.r * 40 / 100), u8(neb.g * 40 / 100), u8(neb.b * 40 / 100))

	// Glowing Planetary Body / Sun with Planetary Ring
	sun_x := win_w / 2 - int(game.camera.x * 0.15)
	sun_y := horizon_y - 45
	draw_filled_circle(renderer, sun_x, sun_y, 45, theme.sun_color.r, theme.sun_color.g, theme.sun_color.b)
	draw_filled_circle(renderer, sun_x, sun_y, 54, u8(theme.sun_color.r * 65 / 100), u8(theme.sun_color.g * 65 / 100), u8(theme.sun_color.b * 65 / 100))

	// Planetary Ring
	set_render_draw_color(renderer, 240, 245, 255, 160)
	render_draw_line(renderer, sun_x - 70, sun_y + 12, sun_x + 70, sun_y - 12)
	render_draw_line(renderer, sun_x - 68, sun_y + 13, sun_x + 68, sun_y - 11)

	// Twinkling Starfield
	set_render_draw_color(renderer, 245, 250, 255, 255)
	for i := 0; i < 50; i++ {
		star_seed := i * 1997 + 89
		sx := (star_seed * 47) % win_w
		sy := (star_seed * 31) % (horizon_y - 15)
		render_draw_point(renderer, sx, sy)
	}

	// Hyperspace Warp Streaks (at high speed > 260 KM/H)
	if game.player.speed_kmh > 260.0 {
		warp_intensity := (game.player.speed_kmh - 260.0) / 90.0
		num_streaks := int(warp_intensity * 25.0)
		set_render_draw_color(renderer, 100, 220, 255, 220)
		cx := win_w / 2
		cy := horizon_y
		for i := 0; i < num_streaks; i++ {
			seed := i * 997 + int(game.global_time * 60.0)
			ang := f64((seed * 37) % 360) * math.pi / 180.0
			dist := 60.0 + f64((seed * 71) % 400)
			len := 20.0 + warp_intensity * 60.0
			x1 := cx + int(math.cos(ang) * dist)
			y1 := cy + int(math.sin(ang) * dist * 0.6)
			x2 := cx + int(math.cos(ang) * (dist + len))
			y2 := cy + int(math.sin(ang) * (dist + len) * 0.6)
			render_draw_line(renderer, x1, y1, x2, y2)
		}
	}
}

// 2. Infinite 3D Scanline Checkerboard Floor with Dynamic Floor Light Reflections
fn render_3d_floor_hd(renderer &Renderer, game &WorldRunnerGame, win_w int, win_h int) {
	theme := game.theme
	horizon_y := int(f32(win_h) * 0.52 + game.shake_y)
	cam_h := game.camera.y
	focal_len := game.camera.focal_len
	cx := f32(win_w) * 0.5

	num_lanes := 10

	for y := horizon_y + 1; y < win_h; y++ {
		dy := f32(y - horizon_y)
		if dy < 1.0 { continue }

		z_dist := (cam_h * focal_len) / dy
		if z_dist <= 0 { continue }

		world_z := game.camera.z + z_dist

		// Curve & Hill displacement
		curve_off := (z_dist * z_dist) * game.track_curve * 0.00003
		center_x := cx - (game.camera.x - curve_off) * (focal_len / z_dist)
		track_half_w := 480.0 * (focal_len / z_dist)

		tile_z_size := f32(160.0)
		z_idx := int(math.floor(f64(world_z / tile_z_size)))

		fog_t := math.min(1.0, f64(z_dist / 2400.0))

		lane_w_px := (track_half_w * 2.0) / f32(num_lanes)

		// Dynamic Jetpack Exhaust & Laser Light on Floor
		mut light_add := 0.0
		dz_player := math.abs(f64(world_z - game.player.pos.z))
		if dz_player < 180.0 {
			light_add = math.max(0.0, (1.0 - dz_player / 180.0) * 55.0)
		}

		for lane in 0 .. num_lanes {
			x_start := int(center_x - track_half_w + f32(lane) * lane_w_px)
			x_end := int(center_x - track_half_w + f32(lane + 1) * lane_w_px)

			if x_end < 0 || x_start > win_w { continue }
			clamped_x_start := if x_start < 0 { 0 } else { x_start }
			clamped_x_end := if x_end > win_w { win_w } else { x_end }

			is_check := (lane + z_idx) % 2 == 0
			base_col := if is_check { theme.floor_color_a } else { theme.floor_color_b }

			r := u8(math.min(255.0, (f64(base_col.r) + light_add) * (1.0 - fog_t) + f64(theme.sky_bot.r) * fog_t))
			g := u8(math.min(255.0, (f64(base_col.g) + light_add * 0.8) * (1.0 - fog_t) + f64(theme.sky_bot.g) * fog_t))
			b := u8(math.min(255.0, (f64(base_col.b) + light_add * 0.4) * (1.0 - fog_t) + f64(theme.sky_bot.b) * fog_t))

			set_render_draw_color(renderer, r, g, b, 255)
			render_draw_line(renderer, clamped_x_start, y, clamped_x_end, y)
		}

		// Glowing Neon Track Border Rails
		border_col := theme.grid_line_col
		set_render_draw_color(renderer, border_col.r, border_col.g, border_col.b, 255)
		render_draw_point(renderer, int(center_x - track_half_w), y)
		render_draw_point(renderer, int(center_x + track_half_w), y)
	}
}

// 3. Volumetric 3D Obstacles with Extruded Top & Side Faces
fn render_3d_volumetric_obstacles(renderer &Renderer, game &WorldRunnerGame, win_w int, win_h int, tex &Texture) {
	for obs in game.obstacles {
		if !obs.active { continue }
		proj := project_3d(obs.pos, game.camera, game.track_curve, game.track_hill, win_w, win_h)
		if !proj.visible { continue }

		sx := int(proj.sx + game.shake_x)
		sy := int(proj.sy + game.shake_y)
		scale := proj.scale

		sw := int(obs.size.x * scale)
		sh := int(obs.size.y * scale)
		sd := int(obs.size.z * scale * 0.4)

		if tex != unsafe { nil } && sw > 8 && sh > 8 {
			src := match obs.obs_type {
				.pillar { Rect{x: 0, y: 64, w: 64, h: 64} }
				.crystal_spire { Rect{x: 64, y: 64, w: 64, h: 64} }
				.energy_ring { Rect{x: 128, y: 64, w: 64, h: 64} }
				else { Rect{x: 0, y: 0, w: 0, h: 0} }
			}
			if src.w > 0 {
				dst := Rect{x: sx - sw / 2, y: sy - sh, w: sw, h: sh}
				render_copy(renderer, tex, &src, &dst)
				continue
			}
		}

		match obs.obs_type {
			.pillar {
				// Volumetric 3D Stone Monolith
				// Front Face
				front := Rect{x: sx - sw / 2, y: sy - sh, w: sw, h: sh}
				set_render_draw_color(renderer, 175, 185, 205, 255)
				render_fill_rect(renderer, &front)
				// Top Face
				fill_quad(renderer, sx - sw / 2, sy - sh, sx - sw / 2 + sd, sy - sh - sd, sx + sw / 2 + sd, sy - sh - sd, sx + sw / 2, sy - sh, 225, 235, 250)
				// Right Extruded Side Face
				fill_quad(renderer, sx + sw / 2, sy - sh, sx + sw / 2 + sd, sy - sh - sd, sx + sw / 2 + sd, sy - sd, sx + sw / 2, sy, 120, 130, 150)
				// Glowing Cyber Rune Core
				set_render_draw_color(renderer, 60, 220, 255, 255)
				render_draw_line(renderer, sx, sy - sh + 4, sx, sy - 4)
			}
			.brick_wall {
				// Volumetric 3D Brick Wall
				front := Rect{x: sx - sw / 2, y: sy - sh, w: sw, h: sh}
				set_render_draw_color(renderer, 220, 85, 50, 255)
				render_fill_rect(renderer, &front)
				// Top Face
				fill_quad(renderer, sx - sw / 2, sy - sh, sx - sw / 2 + sd, sy - sh - sd, sx + sw / 2 + sd, sy - sh - sd, sx + sw / 2, sy - sh, 255, 140, 95)
				// Side Face
				fill_quad(renderer, sx + sw / 2, sy - sh, sx + sw / 2 + sd, sy - sh - sd, sx + sw / 2 + sd, sy - sd, sx + sw / 2, sy, 150, 45, 25)
				// Mortar Lines
				set_render_draw_color(renderer, 255, 220, 160, 255)
				render_draw_rect(renderer, &front)
			}
			.crystal_spire {
				// Faceted 3D Crystal Spire
				top_y := sy - sh
				fill_triangle(renderer, sx, top_y, sx - sw / 2, sy, sx, sy)
				set_render_draw_color(renderer, 255, 140, 255, 255)
				fill_triangle(renderer, sx, top_y, sx, sy, sx + sw / 2, sy)
				// Prismatic Ridge Highlight
				set_render_draw_color(renderer, 255, 255, 255, 255)
				render_draw_line(renderer, sx, top_y, sx, sy)
			}
			.pit {
				// 3D Depth Abyss Chasm
				rect := Rect{x: sx - sw / 2, y: sy - 4, w: sw, h: math.max(8, int(obs.size.z * scale * 0.45))}
				set_render_draw_color(renderer, 4, 6, 12, 255)
				render_fill_rect(renderer, &rect)
				set_render_draw_color(renderer, 255, 50, 50, 255)
				render_draw_rect(renderer, &rect)
			}
			.energy_ring {
				// Spinning 3D Neon Ring
				rad := int(obs.size.x * scale * 0.5)
				draw_filled_circle(renderer, sx, sy - rad, rad, 50, 230, 255)
				draw_filled_circle(renderer, sx, sy - rad, rad - int(7.0 * scale), 8, 16, 32)
			}
			.turret_pod {
				rad := int(obs.size.x * scale * 0.45)
				draw_filled_circle(renderer, sx, sy - rad, rad, 205, 50, 50)
				draw_filled_circle(renderer, sx, sy - rad, rad / 2, 255, 225, 80)
			}
			.item_pod {
				rad := int(obs.size.x * scale * 0.5)
				col_r := if obs.item_type == .speed_boost { u8(50) } else { u8(255) }
				col_g := if obs.item_type == .health_pack { u8(255) } else { u8(215) }
				col_b := if obs.item_type == .speed_boost { u8(255) } else { u8(50) }
				draw_filled_circle(renderer, sx, sy - rad, rad, col_r, col_g, col_b)
				draw_filled_circle(renderer, sx, sy - rad, rad / 2, 255, 255, 255)
			}
		}
	}
}

// 4. Segmented Multi-Jointed Serpent Dragon Boss
fn render_dragon_boss_hd(renderer &Renderer, game &WorldRunnerGame, win_w int, win_h int, tex &Texture) {
	boss := &game.boss

	for i := boss.segments.len - 1; i >= 0; i-- {
		seg := boss.segments[i]
		if seg.destroyed { continue }

		proj := project_3d(seg.pos, game.camera, game.track_curve, game.track_hill, win_w, win_h)
		if !proj.visible { continue }

		sx := int(proj.sx + game.shake_x)
		sy := int(proj.sy + game.shake_y)
		rad := int(seg.radius * proj.scale)
		if rad < 3 { continue }

		if tex != unsafe { nil } {
			src := if seg.is_head {
				Rect{x: 0, y: 192, w: 64, h: 64}
			} else if i == boss.segments.len - 1 {
				Rect{x: 128, y: 192, w: 64, h: 64}
			} else {
				Rect{x: 64, y: 192, w: 64, h: 64}
			}
			dst := Rect{x: sx - rad, y: sy - rad, w: rad * 2, h: rad * 2}
			render_copy(renderer, tex, &src, &dst)
			continue
		}

		if boss.flash_timer > 0 {
			draw_filled_circle(renderer, sx, sy, rad, 255, 255, 255)
		} else if seg.is_head {
			// Dragon Head (Crimson & Golden Horns & Glowing Demonic Eyes)
			draw_filled_circle(renderer, sx, sy, rad, 245, 35, 35)
			draw_filled_circle(renderer, sx, sy, rad * 2 / 3, 255, 140, 20)

			// Horns
			set_render_draw_color(renderer, 255, 215, 0, 255)
			render_draw_line(renderer, sx - rad / 2, sy - rad / 2, sx - rad, sy - rad)
			render_draw_line(renderer, sx + rad / 2, sy - rad / 2, sx + rad, sy - rad)

			// Demonic Eyes
			draw_filled_circle(renderer, sx - rad / 3, sy - rad / 4, rad / 5, 255, 255, 50)
			draw_filled_circle(renderer, sx + rad / 3, sy - rad / 4, rad / 5, 255, 255, 50)
		} else {
			// Shaded Scale Ridge Segment
			pulse := u8(180 + 60 * math.sin(f64(game.global_time * 8.0 + f32(i))))
			draw_filled_circle(renderer, sx, sy, rad, pulse, 35, 55)
			draw_filled_circle(renderer, sx, sy, rad * 3 / 4, 255, 180, 50)
			draw_filled_circle(renderer, sx, sy, rad / 3, 255, 240, 180)
		}
	}
}

// 5. Glowing Lasers & Smart Lock-On Reticle
fn render_lasers_hd(renderer &Renderer, game &WorldRunnerGame, win_w int, win_h int) {
	for bolt in game.lasers {
		proj := project_3d(bolt.pos, game.camera, game.track_curve, game.track_hill, win_w, win_h)
		if !proj.visible { continue }

		sx := int(proj.sx + game.shake_x)
		sy := int(proj.sy + game.shake_y)
		rad := math.max(3, int(bolt.radius * proj.scale))

		if bolt.is_player {
			// Cyan/White Plasma Bolt
			draw_filled_circle(renderer, sx, sy, rad, 50, 230, 255)
			draw_filled_circle(renderer, sx, sy, rad / 2, 255, 255, 255)
		} else {
			// Red Enemy Plasma Bolt
			draw_filled_circle(renderer, sx, sy, rad, 255, 45, 45)
			draw_filled_circle(renderer, sx, sy, rad / 2, 255, 235, 140)
		}
	}
}

fn render_smart_reticle(renderer &Renderer, game &WorldRunnerGame, win_w int, win_h int) {
	reticle_x := win_w / 2 + int(game.player.pos.x * 0.3)
	reticle_y := int(f32(win_h) * 0.52 - 40.0)

	// Smart Target Lock Brackets
	bracket_sz := 14
	set_render_draw_color(renderer, 60, 245, 255, 240)
	render_draw_line(renderer, reticle_x - bracket_sz, reticle_y - bracket_sz, reticle_x - bracket_sz / 2, reticle_y - bracket_sz)
	render_draw_line(renderer, reticle_x - bracket_sz, reticle_y - bracket_sz, reticle_x - bracket_sz, reticle_y - bracket_sz / 2)

	render_draw_line(renderer, reticle_x + bracket_sz, reticle_y - bracket_sz, reticle_x + bracket_sz / 2, reticle_y - bracket_sz)
	render_draw_line(renderer, reticle_x + bracket_sz, reticle_y - bracket_sz, reticle_x + bracket_sz, reticle_y - bracket_sz / 2)

	render_draw_line(renderer, reticle_x - bracket_sz, reticle_y + bracket_sz, reticle_x - bracket_sz / 2, reticle_y + bracket_sz)
	render_draw_line(renderer, reticle_x - bracket_sz, reticle_y + bracket_sz, reticle_x - bracket_sz, reticle_y + bracket_sz / 2)

	render_draw_line(renderer, reticle_x + bracket_sz, reticle_y + bracket_sz, reticle_x + bracket_sz / 2, reticle_y + bracket_sz)
	render_draw_line(renderer, reticle_x + bracket_sz, reticle_y + bracket_sz, reticle_x + bracket_sz, reticle_y + bracket_sz / 2)

	draw_filled_circle(renderer, reticle_x, reticle_y, 3, 255, 255, 255)
}

// 6. 3D Shaded Player Commando & Jetpack Exhaust
fn render_player_commando_hd(renderer &Renderer, game &WorldRunnerGame, win_w int, win_h int, tex &Texture) {
	p := &game.player
	if p.invuln_timer > 0 && int(p.invuln_timer * 16.0) % 2 == 0 { return }

	proj := project_3d(p.pos, game.camera, game.track_curve, game.track_hill, win_w, win_h)
	if !proj.visible { return }

	sx := int(proj.sx + game.shake_x)
	sy := int(proj.sy + game.shake_y)
	scale := proj.scale

	// Ground Shadow Projection
	shadow_proj := project_3d(vec3(p.pos.x, 0, p.pos.z), game.camera, game.track_curve, game.track_hill, win_w, win_h)
	if shadow_proj.visible {
		sh_x := int(shadow_proj.sx + game.shake_x)
		sh_y := int(shadow_proj.sy + game.shake_y)
		rad_x := int(36.0 * scale)
		rad_y := int(14.0 * scale)
		set_render_draw_color(renderer, 0, 0, 0, 185)
		for dy := -rad_y; dy <= rad_y; dy++ {
			dx_lim := int(f32(rad_x) * f32(math.sqrt(math.max(0.0, 1.0 - f64(dy * dy) / f64(rad_y * rad_y)))))
			render_draw_line(renderer, sh_x - dx_lim, sh_y + dy, sh_x + dx_lim, sh_y + dy)
		}
	}

	// Shield Barrier
	if p.shield_timer > 0 {
		shield_col := u8(180 + 75 * math.sin(f64(game.global_time * 14.0)))
		draw_filled_circle(renderer, sx, sy - int(38.0 * scale), int(46.0 * scale), shield_col, 255, 120)
	}

	if tex != unsafe { nil } {
		anim_frame := if !p.on_ground {
			3
		} else if p.speed_kmh > p.max_speed_kmh * 0.9 {
			4
		} else {
			int(p.run_anim_timer * 12.0) % 3
		}
		src := Rect{x: anim_frame * 64, y: 0, w: 64, h: 64}
		dw := int(64.0 * scale)
		dh := int(64.0 * scale)
		dst := Rect{x: sx - dw / 2, y: sy - dh, w: dw, h: dh}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	// Runner Torso & Jetpack
	body_w := int(30.0 * scale)
	body_h := int(44.0 * scale)

	rect := Rect{x: sx - body_w / 2, y: sy - body_h, w: body_w, h: body_h}
	set_render_draw_color(renderer, 245, 45, 45, 255)
	render_fill_rect(renderer, &rect)

	thruster := Rect{x: sx - body_w / 3, y: sy - body_h * 3 / 4, w: body_w * 2 / 3, h: body_h / 2}
	set_render_draw_color(renderer, 35, 45, 65, 255)
	render_fill_rect(renderer, &thruster)

	// Head Visor
	draw_filled_circle(renderer, sx, sy - body_h - int(12.0 * scale), int(12.0 * scale), 255, 215, 0)
	draw_filled_circle(renderer, sx, sy - body_h - int(12.0 * scale), int(6.0 * scale), 60, 225, 255)

	// Jetpack Flames / Running Legs
	if p.on_ground {
		anim_step := int(p.run_anim_timer * 12.0) % 4
		leg_off := if anim_step == 0 || anim_step == 2 { 7 } else { -7 }
		set_render_draw_color(renderer, 20, 30, 50, 255)
		render_draw_line(renderer, sx - 9, sy, sx - 9, sy + leg_off)
		render_draw_line(renderer, sx + 9, sy, sx + 9, sy - leg_off)
	} else {
		// Dual Jetpack Exhaust Flame Cones
		draw_filled_circle(renderer, sx - 9, sy + 6, int(9.0 * scale), 255, 140, 20)
		draw_filled_circle(renderer, sx + 9, sy + 6, int(9.0 * scale), 255, 140, 20)
		draw_filled_circle(renderer, sx - 9, sy + 6, int(4.0 * scale), 255, 255, 255)
		draw_filled_circle(renderer, sx + 9, sy + 6, int(4.0 * scale), 255, 255, 255)
	}
}

fn render_particles_3d(renderer &Renderer, game &WorldRunnerGame, win_w int, win_h int) {
	for p in game.particles {
		proj := project_3d(p.pos, game.camera, game.track_curve, game.track_hill, win_w, win_h)
		if !proj.visible { continue }

		sx := int(proj.sx + game.shake_x)
		sy := int(proj.sy + game.shake_y)
		sz := math.max(2, int(p.size * proj.scale))

		rect := Rect{x: sx - sz / 2, y: sy - sz / 2, w: sz, h: sz}
		set_render_draw_color(renderer, p.r, p.g, p.b, 255)
		render_fill_rect(renderer, &rect)
	}
}

fn render_pop_texts(renderer &Renderer, game &WorldRunnerGame) {
	for pt in game.pop_texts {
		draw_text_centered_shadow(renderer, pt.text, int(pt.x), int(pt.y), 2, Color{r: pt.r, g: pt.g, b: pt.b}, Color{r: 0, g: 0, b: 0})
	}
}

// 9. Glassmorphic Modern HUD
fn render_modern_hud(renderer &Renderer, game &WorldRunnerGame, win_w int) {
	hud_h := 46
	rect := Rect{x: 0, y: 0, w: win_w, h: hud_h}
	set_render_draw_color(renderer, 8, 14, 28, 235)
	render_fill_rect(renderer, &rect)
	set_render_draw_color(renderer, 60, 220, 255, 255)
	render_draw_line(renderer, 0, hud_h - 1, win_w, hud_h - 1)

	// 1. SCORE
	draw_text_shadow(renderer, 'SCORE', 25, 8, 2, Color{r: 160, g: 190, b: 230}, Color{r: 0, g: 0, b: 0})
	draw_text_shadow(renderer, '${game.player.score:06d}', 25, 24, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})

	// 2. SPEEDOMETER GAUGE (KM/H)
	spd := int(game.player.speed_kmh)
	spd_col := if spd > 280 { Color{r: 255, g: 80, b: 80} } else { Color{r: 80, g: 255, b: 180} }
	draw_text_shadow(renderer, 'SPEED', 150, 8, 2, Color{r: 160, g: 190, b: 230}, Color{r: 0, g: 0, b: 0})
	draw_text_shadow(renderer, '${spd:03d} KM/H', 150, 24, 2, spd_col, Color{r: 0, g: 0, b: 0})

	// Speed bar
	bar_w := 70
	prog := math.min(1.0, f64(game.player.speed_kmh) / 350.0)
	s_bg := Rect{x: 270, y: 26, w: bar_w, h: 10}
	set_render_draw_color(renderer, 25, 35, 55, 255)
	render_fill_rect(renderer, &s_bg)
	s_fill := Rect{x: 270, y: 26, w: int(f64(bar_w) * prog), h: 10}
	set_render_draw_color(renderer, 60, 220, 255, 255)
	render_fill_rect(renderer, &s_fill)

	// 3. TIME COUNTDOWN
	time_int := int(math.ceil(f64(game.time_left)))
	time_col := if time_int < 10 { Color{r: 255, g: 45, b: 45} } else { Color{r: 255, g: 215, b: 0} }
	draw_text_shadow(renderer, 'TIME', 370, 8, 2, Color{r: 160, g: 190, b: 230}, Color{r: 0, g: 0, b: 0})
	draw_text_shadow(renderer, '${time_int:03d}s', 370, 24, 2, time_col, Color{r: 0, g: 0, b: 0})

	// 4. HEALTH HEARTS
	draw_text_shadow(renderer, 'HEALTH', 475, 8, 2, Color{r: 160, g: 190, b: 230}, Color{r: 0, g: 0, b: 0})
	mut heart_str := ''
	for h := 0; h < game.player.health; h++ { heart_str += '*' }
	draw_text_shadow(renderer, heart_str, 475, 24, 2, Color{r: 255, g: 50, b: 80}, Color{r: 0, g: 0, b: 0})

	// 5. WORLD NAME & DISTANCE PROGRESS
	draw_text_shadow(renderer, game.theme.name, 590, 8, 2, Color{r: 200, g: 240, b: 255}, Color{r: 0, g: 0, b: 0})

	dist_prog := math.min(1.0, math.max(0.0, f64(game.player.pos.z) / f64(game.theme.track_length)))
	d_bg := Rect{x: 590, y: 26, w: 180, h: 10}
	set_render_draw_color(renderer, 25, 35, 55, 255)
	render_fill_rect(renderer, &d_bg)
	d_fill := Rect{x: 590, y: 26, w: int(180.0 * dist_prog), h: 10}
	set_render_draw_color(renderer, 40, 240, 120, 255)
	render_fill_rect(renderer, &d_fill)
}

fn render_screen_overlays(renderer &Renderer, game &WorldRunnerGame, win_w int, win_h int) {
	cx := win_w / 2

	match game.state {
		.title {
			rect := Rect{x: 60, y: 55, w: win_w - 120, h: win_h - 110}
			set_render_draw_color(renderer, 8, 14, 28, 245)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 60, 220, 255, 255)
			render_draw_rect(renderer, &rect)

			draw_text_centered_shadow(renderer, '3D WORLD RUNNER', cx, 80, 4, Color{r: 255, g: 215, b: 0}, Color{r: 180, g: 80, b: 0})
			draw_text_centered_shadow(renderer, 'COSMIC HARRIER 3D ARCADE MASTERPIECE', cx, 125, 2, Color{r: 80, g: 220, b: 255}, Color{r: 0, g: 0, b: 0})

			draw_text_centered_shadow(renderer, 'PRESS SPACE OR ENTER TO START', cx, 180, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, '[ 1 - 5 ] WORLD SELECT', cx, 215, 2, Color{r: 255, g: 200, b: 80}, Color{r: 0, g: 0, b: 0})

			// Controls
			draw_text_centered_shadow(renderer, '--- CONTROLS ---', cx, 265, 2, Color{r: 180, g: 200, b: 240}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'A / D / ARROWS / MOUSE : 3D LATERAL STRAFE & AIM', cx, 295, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'SPACE / K / X : HIGH JETPACK JUMP', cx, 320, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'J / Z / L-CLICK : FIRE DUAL LASER CANNONS', cx, 345, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'W / SHIFT : TURBO BOOST (320+ KM/H)', cx, 370, 2, Color{r: 80, g: 255, b: 180}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'S / DOWN : ACTIVE AIR BRAKE (80 KM/H)', cx, 395, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'F11 : FULLSCREEN | M : AUDIO | P : PAUSE | R : RESTART', cx, 425, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.world_intro {
			draw_text_centered_shadow(renderer, game.theme.name, cx, win_h / 2 - 35, 4, Color{r: 255, g: 215, b: 0}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'PREPARE FOR WARP SPEED!', cx, win_h / 2 + 15, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.world_clear {
			box := Rect{x: cx - 220, y: win_h / 2 - 80, w: 440, h: 160}
			set_render_draw_color(renderer, 8, 16, 36, 245)
			render_fill_rect(renderer, &box)
			set_render_draw_color(renderer, 60, 220, 255, 255)
			render_draw_rect(renderer, &box)

			draw_text_centered_shadow(renderer, 'WORLD COMPLETED!', cx, win_h / 2 - 60, 3, Color{r: 40, g: 255, b: 120}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'DRAGON GUARDIAN DEFEATED', cx, win_h / 2 - 15, 2, Color{r: 255, g: 220, b: 0}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'WARPING TO NEXT PLANET...', cx, win_h / 2 + 20, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.game_over {
			draw_text_centered_shadow(renderer, 'GAME OVER', cx, win_h / 2 - 40, 5, Color{r: 255, g: 50, b: 50}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'PRESS SPACE TO CONTINUE', cx, win_h / 2 + 30, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.victory {
			box := Rect{x: cx - 260, y: win_h / 2 - 110, w: 520, h: 220}
			set_render_draw_color(renderer, 8, 16, 36, 245)
			render_fill_rect(renderer, &box)
			set_render_draw_color(renderer, 255, 215, 0, 255)
			render_draw_rect(renderer, &box)

			draw_text_centered_shadow(renderer, 'COSMIC CHAMPION!', cx, win_h / 2 - 90, 4, Color{r: 255, g: 215, b: 0}, Color{r: 180, g: 80, b: 0})
			draw_text_centered_shadow(renderer, 'ALL 5 WORLDS CONQUERED', cx, win_h / 2 - 40, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'FINAL SCORE: ${game.player.score:06d}', cx, win_h / 2 - 10, 3, Color{r: 40, g: 255, b: 120}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'PRESS SPACE TO RETURN TO TITLE', cx, win_h / 2 + 65, 2, Color{r: 255, g: 200, b: 80}, Color{r: 0, g: 0, b: 0})
		}
		.paused {
			draw_text_centered_shadow(renderer, 'PAUSED', cx, win_h / 2 - 20, 4, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		else {}
	}
}

fn fill_quad(renderer &Renderer, x0 int, y0 int, x1 int, y1 int, x2 int, y2 int, x3 int, y3 int, r u8, g u8, b u8) {
	set_render_draw_color(renderer, r, g, b, 255)
	fill_triangle(renderer, x0, y0, x1, y1, x2, y2)
	fill_triangle(renderer, x0, y0, x2, y2, x3, y3)
}

fn draw_filled_circle(renderer &Renderer, cx int, cy int, radius int, r u8, g u8, b u8) {
	set_render_draw_color(renderer, r, g, b, 255)
	for dy := -radius; dy <= radius; dy++ {
		dx_limit := int(math.sqrt(math.max(0.0, f64(radius * radius - dy * dy))))
		render_draw_line(renderer, cx - dx_limit, cy + dy, cx + dx_limit, cy + dy)
	}
}

fn fill_triangle(renderer &Renderer, x0 int, y0 int, x1 int, y1 int, x2 int, y2 int) {
	mut ax := x0; mut ay := y0; mut bx := x1; mut by := y1; mut cx := x2; mut cy := y2

	if ay > by {
		tmp_x := ax; tmp_y := ay; ax = bx; ay = by; bx = tmp_x; by = tmp_y
	}
	if ay > cy {
		tmp_x := ax; tmp_y := ay; ax = cx; ay = cy; cx = tmp_x; cy = tmp_y
	}
	if by > cy {
		tmp_x := bx; tmp_y := by; bx = cx; by = cy; cx = tmp_x; cy = tmp_y
	}

	if cy == ay { return }

	for y := ay; y <= cy; y++ {
		mut x_start := 0
		mut x_end := 0

		if y < by {
			if by == ay { continue }
			t1 := f32(y - ay) / f32(by - ay)
			t2 := f32(y - ay) / f32(cy - ay)
			x_start = int(f32(ax) + t1 * f32(bx - ax))
			x_end = int(f32(ax) + t2 * f32(cx - ax))
		} else {
			if cy == by { continue }
			t1 := f32(y - by) / f32(cy - by)
			t2 := f32(y - ay) / f32(cy - ay)
			x_start = int(f32(bx) + t1 * f32(cx - bx))
			x_end = int(f32(ax) + t2 * f32(cx - ax))
		}

		if x_start > x_end {
			tmp := x_start
			x_start = x_end
			x_end = tmp
		}

		render_draw_line(renderer, x_start, y, x_end, y)
	}
}
