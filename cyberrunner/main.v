module main

import gg
import math
import os
import rand
import sokol.sapp

enum GameState {
	title
	playing
	paused
	game_over
}

struct Player {
mut:
	x                  f32
	y                  f32
	z                  f32
	vx                 f32
	vy                 f32
	target_x           f32
	roll_angle         f32
	pitch_angle        f32
	is_jumping         bool
	boost_charge       f32 = 100.0
	is_boosting        bool
	boost_timer        f32
	shields            int = 3
	invulnerable_timer f32
	score              int
	multiplier         int = 1
	near_miss_count    int
}

struct Obstacle {
mut:
	x         f32
	y         f32
	z         f32
	width     f32
	height    f32
	depth     f32
	passed    bool
	destroyed bool
}

struct Gem {
mut:
	x         f32
	y         f32
	z         f32
	collected bool
}

struct SpeedPad {
mut:
	x f32
	z f32
}

struct Particle3D {
mut:
	x    f32
	y    f32
	z    f32
	vx   f32
	vy   f32
	vz   f32
	r    u8
	g    u8
	b    u8
	size f32
	life f32 // 1.0 down to 0.0
}

struct Star3D {
mut:
	x      f32
	y      f32
	z      f32
	length f32
}

struct App {
mut:
	gg                    &gg.Context = unsafe { nil }
	state                 GameState   = .title
	sound                 SoundManager
	player                Player
	obstacles             []Obstacle
	gems                  []Gem
	speed_pads            []SpeedPad
	particles             []Particle3D
	stars                 []Star3D
	base_speed            f32 = 20.0
	speed                 f32 = 20.0
	high_score            int
	frame_count           i64
	last_spawn_z          f32
	near_miss_text_timer  f32
	move_left             bool
	move_right            bool
}

fn (mut app App) init_game() {
	app.player = Player{
		x: 0.0
		y: 0.0
		z: 0.0
		target_x: 0.0
		shields: 3
		invulnerable_timer: 0.0
		score: 0
		multiplier: 1
		boost_charge: 100.0
	}
	app.obstacles.clear()
	app.gems.clear()
	app.speed_pads.clear()
	app.particles.clear()
	app.base_speed = 20.0
	app.speed = 20.0
	app.last_spawn_z = 30.0

	// Pre-generate stars in 3D field
	app.stars.clear()
	for _ in 0 .. 150 {
		app.stars << Star3D{
			x: f32(rand.f64() * 120.0 - 60.0)
			y: f32(rand.f64() * 60.0 + 2.0)
			z: f32(rand.f64() * 200.0)
			length: f32(rand.f64() * 3.0 + 1.0)
		}
	}
}

fn (mut app App) spawn_track_elements() {
	// Relaxed 35 to 65 meter gap distance between obstacles
	for app.last_spawn_z < app.player.z + 160.0 {
		app.last_spawn_z += f32(rand.f64() * 30.0 + 35.0)
		z_pos := app.last_spawn_z
		pattern := rand.intn(4) or { 0 }

		lane_positions := [-2.5, 0.0, 2.5]

		match pattern {
			0, 1 {
				// Single obstacle block in 1 lane — leaves the OTHER 2 LANES 100% OPEN!
				obs_lane := rand.intn(3) or { 0 }
				app.obstacles << Obstacle{
					x: f32(lane_positions[obs_lane])
					y: 0.0
					z: z_pos
					width: 1.0
					height: 1.0
					depth: 0.8
				}

				// Place gems and speed pads in open safe lanes to guide the player
				for i in 0 .. 3 {
					if i != obs_lane {
						app.gems << Gem{
							x: f32(lane_positions[i])
							y: 0.2
							z: z_pos
						}
					}
				}
			}
			2 {
				// Low hurdle in ONLY ONE lane — leaves the OTHER 2 LANES 100% OPEN!
				hurdle_lane := rand.intn(3) or { 1 }
				app.obstacles << Obstacle{
					x: f32(lane_positions[hurdle_lane])
					y: 0.0
					z: z_pos
					width: 1.0
					height: 0.4 // Extra low for effortless jump clearance
					depth: 0.8
				}

				// Place Speed Boost Pad in open lane
				open_lane := (hurdle_lane + 1) % 3
				app.speed_pads << SpeedPad{
					x: f32(lane_positions[open_lane])
					z: z_pos
				}

				// Hovering bonus gem over hurdle
				app.gems << Gem{
					x: f32(lane_positions[hurdle_lane])
					y: 1.6
					z: z_pos
				}
			}
			else {
				// Pure bonus section: Speed boost pad + energy gems in all lanes (0 obstacles!)
				pad_lane := rand.intn(3) or { 1 }
				app.speed_pads << SpeedPad{
					x: f32(lane_positions[pad_lane])
					z: z_pos
				}
				for lane in lane_positions {
					app.gems << Gem{
						x: f32(lane)
						y: 0.3
						z: z_pos + 4.0
					}
				}
			}
		}
	}
}

fn (mut app App) update_game(dt f32) {
	if app.state != .playing { return }
	app.frame_count++

	if app.near_miss_text_timer > 0.0 {
		app.near_miss_text_timer -= dt
	}
	if app.player.invulnerable_timer > 0.0 {
		app.player.invulnerable_timer -= dt
	}

	// 1. Instantaneous Steering & Wing Banking
	dx := app.player.target_x - app.player.x
	app.player.x += dx * 28.0 * dt
	app.player.roll_angle = dx * 12.0

	// 2. Floatier Jumping Physics
	if app.player.is_jumping {
		app.player.y += app.player.vy * dt
		app.player.vy -= 20.0 * dt // Reduced gravity for floatier airtime
		app.player.pitch_angle = app.player.vy * 0.8
		if app.player.y <= 0.0 {
			app.player.y = 0.0
			app.player.vy = 0.0
			app.player.is_jumping = false
			app.player.pitch_angle = 0.0
		}
	}

	// 3. Hyper Boost Management
	if app.player.is_boosting {
		app.speed = app.base_speed * 1.6
		app.player.boost_timer -= dt
		app.player.boost_charge = f32(math.max(0.0, f64(app.player.boost_charge - 30.0 * dt)))

		// Spawn thruster trail particles
		if app.frame_count % 2 == 0 {
			app.particles << Particle3D{
				x: app.player.x + f32(rand.f64() * 0.4 - 0.2)
				y: app.player.y + 0.2
				z: app.player.z - 0.8
				vx: f32(rand.f64() * 1.0 - 0.5)
				vy: f32(rand.f64() * 1.0 - 0.5)
				vz: -5.0
				r: 255
				g: 0
				b: 128
				size: 0.35
				life: 1.0
			}
		}

		if app.player.boost_timer <= 0.0 || app.player.boost_charge <= 0.0 {
			app.player.is_boosting = false
		}
	} else {
		// Gentle speed escalation over distance
		app.speed = app.base_speed + f32(app.player.score) * 0.0006
		app.player.boost_charge = f32(math.min(100.0, f64(app.player.boost_charge + 10.0 * dt)))
	}

	// Move player forward
	app.player.z += app.speed * dt
	app.player.score += int(app.speed * dt * f32(app.player.multiplier))

	// Spawn upcoming track elements
	app.spawn_track_elements()

	// 4. Forgiving Collision & Interaction Checks
	p_min_x := app.player.x - 0.45
	p_max_x := app.player.x + 0.45
	p_min_y := app.player.y
	p_max_y := app.player.y + 0.4
	p_min_z := app.player.z - 0.3
	p_max_z := app.player.z + 0.6

	// Check Obstacles
	for mut obs in app.obstacles {
		if obs.destroyed { continue }

		o_min_x := obs.x - obs.width * 0.5
		o_max_x := obs.x + obs.width * 0.5
		o_min_y := obs.y
		o_max_y := obs.y + obs.height
		o_min_z := obs.z - obs.depth * 0.3
		o_max_z := obs.z + obs.depth * 0.3

		// AABB 3D Collision Check
		if app.player.invulnerable_timer <= 0.0 &&
		   (p_min_x <= o_max_x && p_max_x >= o_min_x) &&
		   (p_min_y <= o_max_y && p_max_y >= o_min_y) &&
		   (p_min_z <= o_max_z && p_max_z >= o_min_z) {

			if app.player.shields > 1 {
				// Shield impact!
				app.player.shields--
				app.player.invulnerable_timer = 1.5
				obs.destroyed = true
				app.sound.play_shield_hit()

				// Deflection spark particles
				for _ in 0 .. 15 {
					app.particles << Particle3D{
						x: app.player.x
						y: app.player.y + 0.5
						z: app.player.z
						vx: f32(rand.f64() * 6.0 - 3.0)
						vy: f32(rand.f64() * 6.0 - 1.0)
						vz: f32(rand.f64() * 6.0 - 3.0)
						r: 0
						g: 240
						b: 255
						size: 0.3
						life: 0.8
					}
				}
			} else {
				// Final Shield Depleted -> Crash Game Over!
				app.player.shields = 0
				app.sound.play_crash_sound()
				app.state = .game_over

				if app.player.score > app.high_score {
					app.high_score = app.player.score
				}

				// Spawn explosion debris
				for _ in 0 .. 30 {
					app.particles << Particle3D{
						x: app.player.x
						y: app.player.y + 0.5
						z: app.player.z
						vx: f32(rand.f64() * 12.0 - 6.0)
						vy: f32(rand.f64() * 12.0 - 2.0)
						vz: f32(rand.f64() * 12.0 - 6.0)
						r: 255
						g: u8(rand.intn(100) or { 40 })
						b: 60
						size: f32(rand.f64() * 0.5 + 0.2)
						life: 1.0
					}
				}
				return
			}
		}

		// Near-Miss Bonus Check
		if !obs.passed && app.player.z > obs.z + 1.0 {
			obs.passed = true
			dist_x := math.abs(app.player.x - obs.x)
			if dist_x < 1.8 && app.player.y < obs.height + 0.5 {
				app.player.score += 200 * app.player.multiplier
				app.player.multiplier = math.min(8, app.player.multiplier + 1)
				app.near_miss_text_timer = 1.2
				app.sound.play_near_miss()
			}
		}
	}

	// Check Gems
	for mut gem in app.gems {
		if !gem.collected {
			if math.abs(app.player.x - gem.x) < 1.3 &&
			   math.abs(app.player.y - gem.y) < 1.3 &&
			   math.abs(app.player.z - gem.z) < 1.6 {
				gem.collected = true
				app.player.score += 100 * app.player.multiplier
				app.player.boost_charge = f32(math.min(100.0, f64(app.player.boost_charge + 15.0)))
				app.sound.play_gem_pickup()

				// Sparkle burst
				for _ in 0 .. 6 {
					app.particles << Particle3D{
						x: gem.x
						y: gem.y
						z: gem.z
						vx: f32(rand.f64() * 4.0 - 2.0)
						vy: f32(rand.f64() * 4.0 - 2.0)
						vz: f32(rand.f64() * 4.0 - 2.0)
						r: 255
						g: 220
						b: 0
						size: 0.25
						life: 1.0
					}
				}
			}
		}
	}

	// Check Speed Pads
	for pad in app.speed_pads {
		if math.abs(app.player.x - pad.x) < 1.5 &&
		   math.abs(app.player.z - pad.z) < 2.0 && app.player.y < 1.0 {
			app.player.is_boosting = true
			app.player.boost_timer = 2.0
			app.sound.play_boost_sound()
		}
	}

	// Update Particles
	for mut p in app.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.z += p.vz * dt
		p.life -= 1.8 * dt
	}
	app.particles = app.particles.filter(it.life > 0.0)

	// Clean up old obstacles & gems far behind player
	app.obstacles = app.obstacles.filter(it.z > app.player.z - 20.0)
	app.gems = app.gems.filter(it.z > app.player.z - 20.0)
	app.speed_pads = app.speed_pads.filter(it.z > app.player.z - 20.0)
}

fn frame_cb(mut app App) {
	dt := f32(0.0166) // 60fps tick
	app.frame_count++

	if os.getenv('SNAPSHOT') == '1' || os.args.contains('--snap') {
		if app.frame_count == 1 {
			app.init_game()
			app.state = .playing
			app.player.score = 4250
			app.player.multiplier = 3
			app.player.boost_charge = 85.0
		}
	}

	app.update_game(dt)
	app.sound.update()
	render_frame(mut app)
	prod_fx_render(app.gg)

	if os.getenv('SNAPSHOT') == '1' || os.args.contains('--snap') {
		if app.frame_count >= 15 {
			path := os.real_path('screenshots/cyberrunner.png')
			eprintln('Saving screenshot to: ${path}')
			sapp.screenshot_png(path) or { eprintln('Screenshot error: ${err}') }
			app.gg.quit()
		}
	}
}

fn key_down(key gg.KeyCode, mut app App) {
	match key {
		.a, .left {
			app.move_left = true
			if app.state == .title {
				app.player.target_x = f32(math.min(2.5, f64(app.player.target_x + 2.5)))
			} else if app.state == .playing {
				if app.player.target_x < 2.0 {
					app.player.target_x += 2.5 // Move Left on screen
					app.sound.play_steer_sound()
				}
			}
		}
		.d, .right {
			app.move_right = true
			if app.state == .title {
				app.player.target_x = f32(math.max(-2.5, f64(app.player.target_x - 2.5)))
			} else if app.state == .playing {
				if app.player.target_x > -2.0 {
					app.player.target_x -= 2.5 // Move Right on screen
					app.sound.play_steer_sound()
				}
			}
		}
		.w, .space {
			if app.state == .title {
				app.init_game()
				app.state = .playing
			} else if app.state == .game_over {
				app.init_game()
				app.state = .playing
			} else if app.state == .playing {
				if !app.player.is_jumping {
					app.player.is_jumping = true
					app.player.vy = 13.5 // Floatier jump launch
					app.sound.play_jump_sound()
				}
			}
		}
		.left_shift, .right_shift, .s, .down {
			if app.state == .playing && app.player.boost_charge > 20.0 {
				app.player.is_boosting = true
				app.player.boost_timer = 1.5
				app.sound.play_boost_sound()
			}
		}
		.r {
			app.init_game()
			app.state = .playing
		}
		.p {
			if app.state == .playing {
				app.state = .paused
			} else if app.state == .paused {
				app.state = .playing
			}
		}
		.m {
			app.sound.toggle_music()
		}
		.f11, .grave_accent {
					gg.toggle_fullscreen()
				}
				.f10 {
					prod_fx_cycle_mode()
				}
		.q {
			if app.gg.is_key_down(.left_super) || app.gg.is_key_down(.right_super) || app.gg.is_key_down(.left_control) || app.gg.is_key_down(.right_control) {
				app.gg.quit()
			}
		}
		.escape {
			app.gg.quit()
		}
		else {}
	}
}

fn key_up(key gg.KeyCode, mut app App) {
	match key {
		.a, .left {
			app.move_left = false
		}
		.d, .right {
			app.move_right = false
		}
		else {}
	}
}

fn event_cb(ev &gg.Event, mut app App) {
	match ev.typ {
		.key_down {
			if (ev.key_code == .q && (u32(ev.modifiers) & u32(gg.Modifier.super) != 0 || u32(ev.modifiers) & u32(gg.Modifier.ctrl) != 0)) || ev.key_code == .escape {
				app.gg.quit()
				return
			}
			key_down(ev.key_code, mut app)
		}
		.key_up {
			key_up(ev.key_code, mut app)
		}
		else {}
	}
}

fn main() {
	mut app := &App{
		sound: new_sound_manager()
	}
	app.init_game()

	app.gg = gg.new_context(
		width: 1280
		height: 720
		window_title: 'Neon Vector Run 3D'
		fullscreen: true
		frame_fn: frame_cb
		event_fn: event_cb
		user_data: app
		bg_color: gg.rgb(8, 12, 28)
	)

	app.gg.run()
}
