module main

import gg
import math
import sokol.sgl

// Color constants (Cyberpunk palette)
const color_cyan = gg.rgb(0, 240, 255)
const color_magenta = gg.rgb(255, 0, 128)
const color_yellow = gg.rgb(255, 220, 0)
const color_neon_green = gg.rgb(50, 255, 120)
const color_red = gg.rgb(255, 40, 60)

fn render_frame(mut app App) {
	app.gg.begin()

	w, h := get_logical_size(app)

	// 1. Setup Sokol 3D Perspective Projection
	sgl.defaults()
	sgl.matrix_mode_projection()

	fov := if app.player.is_boosting { f32(82.0) } else { f32(65.0) }
	aspect := f32(w) / f32(h)
	sgl.perspective(sgl.rad(fov), aspect, 0.1, 300.0)

	sgl.matrix_mode_modelview()
	sgl.load_identity()

	// Dynamic 3D Chase Camera
	cam_x := app.player.x * 0.45
	cam_y := app.player.y + 2.8
	cam_z := app.player.z - 6.5

	target_x := app.player.x * 0.7
	target_y := app.player.y + 0.8
	target_z := app.player.z + 15.0

	sgl.lookat(cam_x, cam_y, cam_z, target_x, target_y, target_z, 0.0, 1.0, 0.0)

	// 2. Render 3D World Components
	draw_starfield(app.stars, app.player.z)
	draw_highway_track(app.player.z)

	// Draw Speed Pads
	for pad in app.speed_pads {
		if pad.z > app.player.z - 10.0 && pad.z < app.player.z + 120.0 {
			draw_speed_pad(pad)
		}
	}

	for gem in app.gems {
		if !gem.collected && gem.z > app.player.z - 5.0 && gem.z < app.player.z + 120.0 {
			draw_gem(gem, app.frame_count)
		}
	}

	// Draw Obstacles
	for obs in app.obstacles {
		if obs.z > app.player.z - 5.0 && obs.z < app.player.z + 120.0 {
			draw_obstacle(obs)
		}
	}

	// Draw 3D Particles
	draw_particles(app.particles)

	// Draw Player Ship
	if app.state == .playing || app.state == .paused {
		draw_player_ship(app.player, app.frame_count)
	}

	// Reset projection to 2D orthographic using logical window dimensions (Retina DPI friendly)
	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0.0, f32(w), f32(h), 0.0, -1.0, 1.0)
	sgl.matrix_mode_modelview()
	sgl.load_identity()

	// 3. Render 2D HUD overlay via gg
	draw_hud(mut app)

	app.gg.end()
}

fn draw_starfield(stars []Star3D, player_z f32) {
	sgl.begin_lines()
	sgl.c4b(200, 220, 255, 180)
	for star in stars {
		// Wrap stars along Z axis as player moves forward
		rel_z := f32(math.fmod(star.z - player_z, 200.0)) + player_z
		if rel_z > player_z - 5.0 {
			sgl.v3f(star.x, star.y, rel_z)
			sgl.v3f(star.x, star.y, rel_z + star.length)
		}
	}
	sgl.end()
}

fn draw_highway_track(player_z f32) {
	track_width := f32(7.5)
	segment_len := f32(5.0)
	start_seg := int((player_z - 10.0) / segment_len)
	end_seg := start_seg + 30

	// Track surface panels
	sgl.begin_quads()
	for i in start_seg .. end_seg {
		z0 := f32(i) * segment_len
		z1 := z0 + segment_len

		// Alternating subtle road segment tone
		if i % 2 == 0 {
			sgl.c4b(15, 18, 35, 255)
		} else {
			sgl.c4b(22, 26, 48, 255)
		}

		sgl.v3f(-track_width, 0.0, z0)
		sgl.v3f(track_width, 0.0, z0)
		sgl.v3f(track_width, 0.0, z1)
		sgl.v3f(-track_width, 0.0, z1)
	}
	sgl.end()

	// Lane Dividers and Neon Guardrails
	sgl.begin_lines()

	// Outer glowing side rails (Cyan)
	sgl.c4b(0, 240, 255, 255)
	for i in start_seg .. end_seg {
		z0 := f32(i) * segment_len
		z1 := z0 + segment_len
		sgl.v3f(-track_width, 0.1, z0)
		sgl.v3f(-track_width, 0.1, z1)
		sgl.v3f(track_width, 0.1, z0)
		sgl.v3f(track_width, 0.1, z1)
	}

	// Elevated Light Pillars (Magenta)
	sgl.c4b(255, 0, 128, 200)
	for i in start_seg .. end_seg {
		if i % 3 == 0 {
			z0 := f32(i) * segment_len
			sgl.v3f(-track_width, 0.1, z0)
			sgl.v3f(-track_width, 1.8, z0)

			sgl.v3f(track_width, 0.1, z0)
			sgl.v3f(track_width, 1.8, z0)
		}
	}

	// Dashed Lane Markings (Yellow)
	sgl.c4b(255, 220, 0, 220)
	lane_positions := [-2.5, 2.5]
	for lane_x in lane_positions {
		for i in start_seg .. end_seg {
			if i % 2 == 0 {
				z0 := f32(i) * segment_len
				z1 := z0 + segment_len * 0.5
				sgl.v3f(f32(lane_x), 0.02, z0)
				sgl.v3f(f32(lane_x), 0.02, z1)
			}
		}
	}

	sgl.end()
}

fn draw_player_ship(p Player, frame i64) {
	if p.invulnerable_timer > 0.0 && frame % 4 < 2 {
		return // Invulnerability flashing flicker
	}

	sgl.push_matrix()
	sgl.translate(p.x, p.y + 0.35, p.z)

	// Steering roll & jump pitch tilt
	sgl.rotate(sgl.rad(p.roll_angle), 0.0, 0.0, 1.0)
	sgl.rotate(sgl.rad(p.pitch_angle), 1.0, 0.0, 0.0)

	// 3D Ship Fuselage (Triangular sleek stealth craft)
	sgl.begin_triangles()

	// Nose Top Left
	sgl.c3b(0, 220, 255)
	sgl.v3f(0.0, 0.25, 1.2)
	sgl.v3f(-0.8, 0.05, -0.8)
	sgl.v3f(0.0, 0.5, -0.4)

	// Nose Top Right
	sgl.c3b(0, 180, 240)
	sgl.v3f(0.0, 0.25, 1.2)
	sgl.v3f(0.0, 0.5, -0.4)
	sgl.v3f(0.8, 0.05, -0.8)

	// Left Wing Flap
	sgl.c3b(255, 0, 128)
	sgl.v3f(-0.8, 0.05, -0.8)
	sgl.v3f(-1.6, 0.0, -1.0)
	sgl.v3f(0.0, 0.2, -0.5)

	// Right Wing Flap
	sgl.c3b(220, 0, 110)
	sgl.v3f(0.8, 0.05, -0.8)
	sgl.v3f(0.0, 0.2, -0.5)
	sgl.v3f(1.6, 0.0, -1.0)

	// Bottom Hull
	sgl.c3b(20, 30, 60)
	sgl.v3f(0.0, -0.15, 1.2)
	sgl.v3f(0.8, 0.05, -0.8)
	sgl.v3f(-0.8, 0.05, -0.8)

	// Cockpit Glass
	sgl.c3b(255, 230, 100)
	sgl.v3f(0.0, 0.35, 0.6)
	sgl.v3f(-0.25, 0.25, 0.0)
	sgl.v3f(0.25, 0.25, 0.0)

	// Animated Thruster Cone (Rear)
	flicker := f32(math.sin(f64(frame) * 0.4)) * 0.15
	flame_len := if p.is_boosting { -1.8 - flicker * 2.0 } else { -0.9 - flicker }
	sgl.c3b(255, 120, 0)
	sgl.v3f(0.0, 0.2, -0.6)
	sgl.v3f(-0.3, 0.1, -0.6)
	sgl.v3f(0.0, 0.15, flame_len)

	sgl.c3b(255, 220, 50)
	sgl.v3f(0.0, 0.2, -0.6)
	sgl.v3f(0.0, 0.15, flame_len)
	sgl.v3f(0.3, 0.1, -0.6)

	sgl.end()

	// Ship Wireframe Outlines (Glow Effect)
	sgl.begin_lines()
	sgl.c3b(255, 255, 255)
	sgl.v3f(0.0, 0.25, 1.2)
	sgl.v3f(-1.6, 0.0, -1.0)

	sgl.v3f(0.0, 0.25, 1.2)
	sgl.v3f(1.6, 0.0, -1.0)

	sgl.v3f(-1.6, 0.0, -1.0)
	sgl.v3f(1.6, 0.0, -1.0)
	sgl.end()

	sgl.pop_matrix()
}

fn draw_obstacle(o Obstacle) {
	sgl.push_matrix()
	sgl.translate(o.x, o.y + o.height * 0.5, o.z)

	r, g, b := u8(255), u8(40), u8(60)

	// Render Filled Red Cube
	sgl.begin_quads()
	sgl.c4b(r, g, b, 210)

	hx := o.width * 0.5
	hy := o.height * 0.5
	hz := o.depth * 0.5

	// Front
	sgl.v3f(-hx, -hy, hz)
	sgl.v3f(hx, -hy, hz)
	sgl.v3f(hx, hy, hz)
	sgl.v3f(-hx, hy, hz)

	// Back
	sgl.v3f(-hx, -hy, -hz)
	sgl.v3f(-hx, hy, -hz)
	sgl.v3f(hx, hy, -hz)
	sgl.v3f(hx, -hy, -hz)

	// Top
	sgl.c4b(255, 80, 100, 230)
	sgl.v3f(-hx, hy, -hz)
	sgl.v3f(-hx, hy, hz)
	sgl.v3f(hx, hy, hz)
	sgl.v3f(hx, hy, -hz)

	// Sides
	sgl.c4b(200, 20, 50, 210)
	sgl.v3f(-hx, -hy, -hz)
	sgl.v3f(-hx, -hy, hz)
	sgl.v3f(-hx, hy, hz)
	sgl.v3f(-hx, hy, -hz)

	sgl.v3f(hx, -hy, -hz)
	sgl.v3f(hx, hy, -hz)
	sgl.v3f(hx, hy, hz)
	sgl.v3f(hx, -hy, hz)
	sgl.end()

	// Glowing Neon Wireframe Lines
	sgl.begin_lines()
	sgl.c3b(255, 255, 255)
	// Front Face Wire
	sgl.v3f(-hx, -hy, hz)
	sgl.v3f(hx, -hy, hz)
	sgl.v3f(hx, -hy, hz)
	sgl.v3f(hx, hy, hz)
	sgl.v3f(hx, hy, hz)
	sgl.v3f(-hx, hy, hz)
	sgl.v3f(-hx, hy, hz)
	sgl.v3f(-hx, -hy, hz)
	// Connecting Edges
	sgl.v3f(-hx, hy, hz)
	sgl.v3f(-hx, hy, -hz)
	sgl.v3f(hx, hy, hz)
	sgl.v3f(hx, hy, -hz)
	sgl.end()

	sgl.pop_matrix()
}

fn draw_gem(g Gem, frame i64) {
	sgl.push_matrix()
	gem_y := f32(g.y + 0.6 + math.sin(f64(frame) * 0.08 + f64(g.z)) * 0.15)
	sgl.translate(g.x, gem_y, g.z)
	sgl.rotate(sgl.rad(f32(frame * 3) + g.z * 10.0), 0.0, 1.0, 0.0)

	// 3D Octahedron / Diamond shape
	sgl.begin_triangles()
	sgl.c3b(255, 220, 0)
	r := f32(0.45)

	// Top Pyramid
	sgl.v3f(0.0, r * 1.3, 0.0)
	sgl.v3f(-r, 0.0, r)
	sgl.v3f(r, 0.0, r)

	sgl.c3b(255, 180, 0)
	sgl.v3f(0.0, r * 1.3, 0.0)
	sgl.v3f(r, 0.0, r)
	sgl.v3f(r, 0.0, -r)

	sgl.c3b(255, 240, 80)
	sgl.v3f(0.0, r * 1.3, 0.0)
	sgl.v3f(r, 0.0, -r)
	sgl.v3f(-r, 0.0, -r)

	sgl.c3b(230, 160, 0)
	sgl.v3f(0.0, r * 1.3, 0.0)
	sgl.v3f(-r, 0.0, -r)
	sgl.v3f(-r, 0.0, r)

	// Bottom Pyramid
	sgl.c3b(200, 140, 0)
	sgl.v3f(0.0, -r * 1.3, 0.0)
	sgl.v3f(r, 0.0, r)
	sgl.v3f(-r, 0.0, r)

	sgl.v3f(0.0, -r * 1.3, 0.0)
	sgl.v3f(r, 0.0, -r)
	sgl.v3f(r, 0.0, r)
	sgl.end()

	sgl.pop_matrix()
}

fn draw_speed_pad(s SpeedPad) {
	sgl.push_matrix()
	sgl.translate(s.x, 0.03, s.z)

	sgl.begin_triangles()
	sgl.c3b(50, 255, 120)

	// Forward Chevron Arrow
	sgl.v3f(0.0, 0.0, 2.0)
	sgl.v3f(-1.5, 0.0, -1.0)
	sgl.v3f(0.0, 0.0, -0.3)

	sgl.v3f(0.0, 0.0, 2.0)
	sgl.v3f(0.0, 0.0, -0.3)
	sgl.v3f(1.5, 0.0, -1.0)
	sgl.end()

	sgl.pop_matrix()
}

fn draw_particles(particles []Particle3D) {
	sgl.begin_quads()
	for p in particles {
		if p.life > 0.0 {
			alpha := u8(p.life * 255.0)
			sgl.c4b(p.r, p.g, p.b, alpha)
			hs := p.size * 0.5
			sgl.v3f(p.x - hs, p.y - hs, p.z)
			sgl.v3f(p.x + hs, p.y - hs, p.z)
			sgl.v3f(p.x + hs, p.y + hs, p.z)
			sgl.v3f(p.x - hs, p.y + hs, p.z)
		}
	}
	sgl.end()
}

// Helper to get true logical screen dimensions accounting for Retina DPI scaling
fn get_logical_size(app &App) (int, int) {
	ws := app.gg.window_size()
	if ws.width > 0 && ws.height > 0 {
		return ws.width, ws.height
	}
	return 1280, 720
}

// Helper to draw horizontally centered text with guaranteed positioning and scaled font sizes
fn draw_text_centered(app &App, y int, text string, cfg gg.TextCfg) {
	scale := if app.gg.scale > 0.0 { app.gg.scale } else { f32(1.0) }
	w, _ := get_logical_size(app)

	// Calculate font metrics in logical space
	tw := int(f32(text.len) * f32(cfg.size) * 0.54)
	x := int(f32((w - tw) / 2) / scale)
	scaled_y := int(f32(y) / scale)

	text_cfg := gg.TextCfg{
		color: cfg.color
		size: int(f32(cfg.size) / scale)
		bold: cfg.bold
		mono: cfg.mono
		italic: cfg.italic
		align: cfg.align
		vertical_align: cfg.vertical_align
	}

	app.gg.draw_text(x, scaled_y, text, text_cfg)
}

fn draw_card_box(app &App, card_x int, card_y int, card_w int, card_h int, bg_color gg.Color, border_color gg.Color) {
	scale := if app.gg.scale > 0.0 { app.gg.scale } else { f32(1.0) }
	cx := f32(card_x) / scale
	cy := f32(card_y) / scale
	cw := f32(card_w) / scale
	ch := f32(card_h) / scale

	app.gg.draw_rect_filled(cx, cy, cw, ch, bg_color)
	app.gg.draw_rect_empty(cx, cy, cw, ch, border_color)
}

fn draw_hud(mut app App) {
	scale := if app.gg.scale > 0.0 { app.gg.scale } else { f32(1.0) }
	w, h := get_logical_size(app)

	// 1. Sleek Top Header Bar
	app.gg.draw_rect_filled(0, 0, f32(w) / scale, 56.0 / scale, gg.rgba(12, 18, 40, 240))
	app.gg.draw_line(0, 56.0 / scale, f32(w) / scale, 56.0 / scale, color_cyan)

	// Score (Left side)
	app.gg.draw_text(int(24.0 / scale), int(18.0 / scale), 'SCORE: ${app.player.score}', gg.TextCfg{
		color: color_yellow
		size: int(20.0 / scale)
		bold: true
	})

	score_w := int(f32(('SCORE: ${app.player.score}').len) * 20.0 * 0.54)

	// High Score
	app.gg.draw_text(int(f32(44 + score_w) / scale), int(20.0 / scale), 'HIGH: ${app.high_score}', gg.TextCfg{
		color: color_cyan
		size: int(16.0 / scale)
		bold: true
	})

	high_w := int(f32(('HIGH: ${app.high_score}').len) * 16.0 * 0.54)

	// Shields Indicator (High-contrast cyan bars [ III ])
	mut shield_bars := ''
	for _ in 0 .. app.player.shields {
		shield_bars += 'I '
	}
	app.gg.draw_text(int(f32(68 + score_w + high_w) / scale), int(19.0 / scale), 'SHIELDS: [ ${shield_bars}]', gg.TextCfg{
		color: color_neon_green
		size: int(16.0 / scale)
		bold: true
	})

	// Multiplier Badge (Centered in header)
	if app.player.multiplier > 1 {
		mult_str := '${app.player.multiplier}X MULTIPLIER!'
		draw_text_centered(app, 18, mult_str, gg.TextCfg{
			color: color_magenta
			size: 20
			bold: true
		})
	}

	// Distance & Sound status (Right side with clean margins)
	snd_status := if app.sound.sound_enabled { 'SOUND: ON' } else { 'SOUND: OFF' }
	snd_w := int(f32(snd_status.len) * 15.0 * 0.54)
	snd_x := w - snd_w - 30
	app.gg.draw_text(int(f32(snd_x) / scale), int(20.0 / scale), snd_status, gg.TextCfg{
		color: color_neon_green
		size: int(15.0 / scale)
	})

	dist_str := 'DIST: ${int(app.player.z)}m'
	dist_w := int(f32(dist_str.len) * 18.0 * 0.54)
	dist_x := snd_x - dist_w - 35
	app.gg.draw_text(int(f32(dist_x) / scale), int(18.0 / scale), dist_str, gg.TextCfg{
		color: gg.white
		size: int(18.0 / scale)
		bold: true
	})

	// 2. Bottom Speedometer & Boost Bar
	app.gg.draw_rect_filled(24.0 / scale, f32(h - 70) / scale, 240.0 / scale, 52.0 / scale, gg.rgba(15, 22, 45, 220))
	app.gg.draw_rect_empty(24.0 / scale, f32(h - 70) / scale, 240.0 / scale, 52.0 / scale, color_cyan)

	curr_speed := int(app.speed * 3.6) // km/h conversion feel
	app.gg.draw_text(int(36.0 / scale), int(f32(h - 62) / scale), 'SPEED: ${curr_speed} KM/H', gg.TextCfg{
		color: if app.player.is_boosting { color_magenta } else { color_cyan }
		size: int(16.0 / scale)
		bold: true
	})

	// Boost Meter Fill
	boost_pct := f32(app.player.boost_charge) / 100.0
	app.gg.draw_rect_filled(36.0 / scale, f32(h - 34) / scale, (216.0 * boost_pct) / scale, 12.0 / scale, color_neon_green)
	app.gg.draw_rect_empty(36.0 / scale, f32(h - 34) / scale, 216.0 / scale, 12.0 / scale, gg.white)
	app.gg.draw_text(int(40.0 / scale), int(f32(h - 35) / scale), 'HYPER BOOST [SHIFT]', gg.TextCfg{
		color: gg.black
		size: int(10.0 / scale)
		bold: true
	})

	// Near Miss Notification Text (Centered)
	if app.near_miss_text_timer > 0.0 {
		alpha := u8(math.min(1.0, app.near_miss_text_timer) * 255.0)
		draw_text_centered(app, 90, '⚡ NEAR MISS +200! ⚡', gg.TextCfg{
			color: gg.rgba(255, 0, 128, alpha)
			size: 26
			bold: true
		})
	}

	// 3. State Screens (Title, Paused, GameOver) - Perfectly centered in the middle of screen
	if app.state == .title {
		app.gg.draw_rect_filled(0, 0, f32(w) / scale, f32(h) / scale, gg.rgba(6, 10, 24, 235))

		// Centered Glassmorphism Card Container (680x360 centered in 1280x720)
		card_w := 680
		card_h := 360
		card_x := (w - card_w) / 2
		card_y := (h - card_h) / 2

		draw_card_box(app, card_x, card_y, card_w, card_h, gg.rgba(14, 20, 45, 230), color_cyan)

		// Title & Subtitle (Centered inside card)
		draw_text_centered(app, card_y + 28, 'NEON VECTOR RUN 3D', gg.TextCfg{
			color: color_cyan
			size: 30
			bold: true
		})

		draw_text_centered(app, card_y + 75, 'High-Speed 3D Highway Dodge', gg.TextCfg{
			color: color_magenta
			size: 18
		})

		// Controls Section
		draw_text_centered(app, card_y + 130, '— GAME CONTROLS —', gg.TextCfg{
			color: color_yellow
			size: 15
			bold: true
		})

		draw_text_centered(app, card_y + 165, '[RIGHT] / [D] : Steer Right  |  [LEFT] / [A] : Steer Left', gg.TextCfg{
			color: gg.white
			size: 14
		})

		draw_text_centered(app, card_y + 195, '[SPACE] or [W] : Jump Over Hurdles', gg.TextCfg{
			color: gg.white
			size: 14
		})

		draw_text_centered(app, card_y + 225, '[SHIFT] or [S] : Hyper Boost Speed', gg.TextCfg{
			color: gg.white
			size: 14
		})

		draw_text_centered(app, card_y + 250, '[M] : Sound  |  [P] : Pause  |  [CMD+Q] / [ESC] : Quit | F11: Fullscreen', gg.TextCfg{
			color: gg.white
			size: 14
		})

		draw_text_centered(app, card_y + 308, 'PRESS [SPACE] TO START RACE', gg.TextCfg{
			color: color_neon_green
			size: 19
			bold: true
		})
	} else if app.state == .paused {
		app.gg.draw_rect_filled(0, 0, f32(w) / scale, f32(h) / scale, gg.rgba(0, 0, 0, 190))

		draw_text_centered(app, h / 2 - 40, 'PAUSED', gg.TextCfg{
			color: color_yellow
			size: 36
			bold: true
		})

		draw_text_centered(app, h / 2 + 15, 'Press [P] to Resume', gg.TextCfg{
			color: gg.white
			size: 18
		})
	} else if app.state == .game_over {
		app.gg.draw_rect_filled(0, 0, f32(w) / scale, f32(h) / scale, gg.rgba(20, 5, 15, 235))

		card_w := 680
		card_h := 330
		card_x := (w - card_w) / 2
		card_y := (h - card_h) / 2

		draw_card_box(app, card_x, card_y, card_w, card_h, gg.rgba(25, 10, 20, 230), color_red)

		draw_text_centered(app, card_y + 30, 'CRASH SYSTEM OVERRIDE', gg.TextCfg{
			color: color_red
			size: 28
			bold: true
		})

		draw_text_centered(app, card_y + 85, 'FINAL SCORE: ${app.player.score}', gg.TextCfg{
			color: color_yellow
			size: 22
			bold: true
		})

		draw_text_centered(app, card_y + 125, 'DISTANCE: ${int(app.player.z)} meters', gg.TextCfg{
			color: color_cyan
			size: 17
		})

		draw_text_centered(app, card_y + 160, 'HIGH SCORE: ${app.high_score}', gg.TextCfg{
			color: color_magenta
			size: 17
		})

		draw_text_centered(app, card_y + 240, 'PRESS [R] OR [SPACE] TO RESTART  [F11] Fullscreen', gg.TextCfg{
			color: color_neon_green
			size: 20
			bold: true
		})
	}
}
