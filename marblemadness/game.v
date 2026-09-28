module main

import math
import rand

pub enum GameState {
	title
	level_intro
	playing
	paused
	level_clear
	game_over
	victory
}

pub enum MarbleState {
	rolling
	airborne
	in_tube
	shattered
	reforming
	swallowed
	finished
}

pub struct Shard {
pub mut:
	pos        Vec3
	vel        Vec3
	target_pos Vec3
	rot        f32
	rot_speed  f32
	size       f32
}

pub struct Marble {
pub mut:
	pos             Vec3
	vel             Vec3
	rot_x           f32
	rot_y           f32
	rot_z           f32
	state           MarbleState = .airborne
	state_timer     f32
	is_player       bool        = true
	is_ai           bool
	is_rival        bool
	last_ground_z   f32
	fall_start_z    f32
	turbo_active    bool
	grace_timer     f32
	speed_mph       f32
	shards          []Shard
	tube_target_x   f32
	tube_target_y   f32
	respawn_x       f32
	respawn_y       f32
	respawn_z       f32
	checkpoint_x    f32
	checkpoint_y    f32
	checkpoint_z    f32
}

pub struct Muncher {
pub mut:
	pos         Vec3
	jaw_open    f32
	timer       f32
	is_chewing  bool
	chew_timer  f32
}

pub struct Sweeper {
pub mut:
	pos     Vec3
	start_x f32
	start_y f32
	end_x   f32
	end_y   f32
	z       f32
	speed   f32
	dir     f32 = 1.0
}

pub struct Bird {
pub mut:
	pos          Vec3
	vel          Vec3
	spawn_pos    Vec3
	patrol_dir_x f32
	patrol_dir_y f32
	timer        f32
	carrying     bool
}

pub struct Particle {
pub mut:
	pos      Vec3
	vel      Vec3
	life     f32
	max_life f32
	r        u8
	g        u8
	b        u8
	size     f32
}

pub struct MarbleGame {
pub mut:
	state           GameState = .title
	current_level   int       = 1
	level_data      LevelData
	time_left       f32       = 65.0
	score           int
	high_score      int       = 35000
	bonus_time_awarded int
	bonus_score_awarded int

	player          Marble
	rival           Marble
	has_rival       bool

	munchers        []Muncher
	sweepers        []Sweeper
	birds           []Bird
	particles       []Particle

	global_time     f32
	intro_timer     f32
	clear_timer     f32
	game_over_timer f32
	victory_timer   f32

	// Camera & Screen Shake
	cam_x           f32 = 400.0
	cam_y           f32 = 250.0
	target_cam_x    f32 = 400.0
	target_cam_y    f32 = 250.0
	shake_trauma    f32
	shake_x         f32
	shake_y         f32

	// Modern Trackball / Mouse Controls
	mouse_dx        f32
	mouse_dy        f32
	mouse_enabled   bool = true

	// Keyboard Controls
	input_up        bool
	input_down      bool
	input_left      bool
	input_right     bool
	input_turbo     bool
	input_jump      bool
	control_diagonal bool

	// Sound trigger flags
	sound_play_bounce   bool
	sound_bounce_int    f32
	sound_play_shatter  bool
	sound_play_respawn  bool
	sound_play_muncher  bool
	sound_play_boost    bool
	sound_play_spring   bool
	sound_play_tube     bool
	sound_play_warning  bool
	sound_play_goal     bool
	sound_play_gameover bool
}

pub fn new_marble_game() MarbleGame {
	mut game := MarbleGame{
		level_data: get_level_by_number(1)
	}
	game.init_title()
	return game
}

pub fn (mut g MarbleGame) init_title() {
	g.state = .title
	g.current_level = 1
	g.score = 0
	g.load_level(1, 65.0)
}

pub fn (mut g MarbleGame) start_game(start_lvl int) {
	g.current_level = start_lvl
	g.score = 0
	init_time := f32(match start_lvl {
		1 { 65.0 }
		2 { 75.0 }
		3 { 80.0 }
		4 { 80.0 }
		5 { 80.0 }
		6 { 85.0 }
		else { 65.0 }
	})
	g.load_level(start_lvl, init_time)
	g.state = .level_intro
	g.intro_timer = 2.0
}

pub fn (mut g MarbleGame) load_level(lvl_num int, carryover_time f32) {
	g.current_level = lvl_num
	g.level_data = get_level_by_number(lvl_num)
	g.time_left = carryover_time
	g.particles.clear()

	def := g.level_data.def

	g.player = Marble{
		pos: vec3(def.start_x, def.start_y, def.start_z + 0.6)
		vel: vec3(0, 0, 0)
		state: .rolling
		is_player: true
		is_rival: false
		checkpoint_x: def.start_x
		checkpoint_y: def.start_y
		checkpoint_z: def.start_z
		respawn_x: def.start_x
		respawn_y: def.start_y
		respawn_z: def.start_z
		fall_start_z: def.start_z
		grace_timer: 1.0
	}

	g.has_rival = def.has_rival
	if def.has_rival {
		g.rival = Marble{
			pos: vec3(def.rival_start_x, def.rival_start_y, def.rival_start_z + 0.6)
			vel: vec3(0, 0, 0)
			state: .rolling
			is_player: false
			is_ai: true
			is_rival: true
			checkpoint_x: def.rival_start_x
			checkpoint_y: def.rival_start_y
			checkpoint_z: def.rival_start_z
			respawn_x: def.rival_start_x
			respawn_y: def.rival_start_y
			respawn_z: def.rival_start_z
			grace_timer: 1.0
		}
	}

	g.munchers.clear()
	for m_pos in g.level_data.munchers {
		g.munchers << Muncher{
			pos: m_pos
		}
	}

	g.sweepers.clear()
	for sw in g.level_data.sweepers {
		g.sweepers << Sweeper{
			pos: vec3(sw.start_x, sw.start_y, sw.z)
			start_x: sw.start_x
			start_y: sw.start_y
			end_x: sw.end_x
			end_y: sw.end_y
			z: sw.z
			speed: sw.speed
		}
	}

	g.birds.clear()
	for b in g.level_data.birds {
		g.birds << Bird{
			pos: vec3(b.spawn_x, b.spawn_y, b.spawn_z)
			spawn_pos: vec3(b.spawn_x, b.spawn_y, b.spawn_z)
			patrol_dir_x: b.patrol_dir_x
			patrol_dir_y: b.patrol_dir_y
		}
	}

	sx, sy := world_to_screen(g.player.pos.x, g.player.pos.y, g.player.pos.z, 0, 0)
	g.cam_x = 420.0 - sx
	g.cam_y = 320.0 - sy
	g.target_cam_x = g.cam_x
	g.target_cam_y = g.cam_y
	g.shake_trauma = 0.0
}

pub fn (mut g MarbleGame) trigger_shake(amount f32) {
	g.shake_trauma = f32(math.min(1.0, f64(g.shake_trauma + amount)))
}

pub fn (mut g MarbleGame) shatter_marble(mut m Marble) {
	m.state = .shattered
	m.state_timer = 0.0
	m.shards.clear()
	g.sound_play_shatter = true
	g.trigger_shake(0.6)

	num_shards := 18
	for i in 0 .. num_shards {
		angle := f32(i) * (2.0 * math.pi / f32(num_shards))
		spd := 3.2 + f32(rand.intn(100) or { 50 }) * 0.025
		m.shards << Shard{
			pos: m.pos
			vel: vec3(
				f32(math.cos(angle)) * spd + m.vel.x * 0.3,
				f32(math.sin(angle)) * spd + m.vel.y * 0.3,
				4.0 + f32(rand.intn(100) or { 50 }) * 0.04
			)
			target_pos: m.pos
			rot: 0.0
			rot_speed: (f32(rand.intn(100) or { 50 }) - 50.0) * 0.25
			size: 0.12 + f32(rand.intn(60) or { 30 }) * 0.002
		}
	}

	if m.is_player {
		g.time_left = f32(math.max(0.0, f64(g.time_left - 3.0)))
	}
}

pub fn (mut g MarbleGame) respawn_marble(mut m Marble) {
	m.state = .reforming
	m.state_timer = 0.0
	m.grace_timer = 1.5
	m.pos = vec3(m.checkpoint_x, m.checkpoint_y, m.checkpoint_z + marble_radius + 0.02)
	m.vel = vec3(0, 0, 0)
	m.fall_start_z = m.pos.z
	g.sound_play_respawn = true

	if m.is_player {
		g.time_left = f32(math.max(0.0, f64(g.time_left - 3.0)))
	}
}

pub fn (mut g MarbleGame) add_particle(pos Vec3, vel Vec3, life f32, r u8, g_col u8, b u8, size f32) {
	g.particles << Particle{
		pos: pos
		vel: vel
		life: life
		max_life: life
		r: r
		g: g_col
		b: b
		size: size
	}
}

pub fn (mut g MarbleGame) update(dt f32) {
	g.global_time += dt

	// Decay camera trauma & compute screen shake
	if g.shake_trauma > 0 {
		g.shake_trauma = f32(math.max(0.0, f64(g.shake_trauma - dt * 1.5)))
		shake_mag := g.shake_trauma * g.shake_trauma * 16.0
		g.shake_x = (f32(rand.intn(200) or { 100 }) - 100.0) * 0.01 * shake_mag
		g.shake_y = (f32(rand.intn(200) or { 100 }) - 100.0) * 0.01 * shake_mag
	} else {
		g.shake_x = 0
		g.shake_y = 0
	}

	match g.state {
		.title {
			g.update_disappearing_tiles()
		}
		.level_intro {
			g.intro_timer -= dt
			if g.intro_timer <= 0 {
				g.state = .playing
			}
		}
		.playing {
			g.update_playing(dt)
		}
		.paused {}
		.level_clear {
			g.clear_timer -= dt
			if rand.intn(4) or { 0 } == 0 {
				gx := g.level_data.def.goal_x + (f32(rand.intn(60) or { 30 }) - 30.0) * 0.1
				gy := g.level_data.def.goal_y + (f32(rand.intn(60) or { 30 }) - 30.0) * 0.1
				g.add_particle(
					vec3(gx, gy, 1.0 + f32(rand.intn(30) or { 15 }) * 0.1),
					vec3((f32(rand.intn(40) or { 20 }) - 20.0) * 0.1, (f32(rand.intn(40) or { 20 }) - 20.0) * 0.1, 4.0 + f32(rand.intn(40) or { 20 }) * 0.1),
					1.2,
					u8(rand.intn(200) or { 100 } + 55),
					u8(rand.intn(200) or { 100 } + 55),
					u8(rand.intn(200) or { 100 } + 55),
					0.18
				)
			}
			g.update_particles(dt)

			if g.clear_timer <= 0 {
				if g.current_level >= 6 {
					g.state = .victory
					g.victory_timer = 6.0
				} else {
					next_lvl := g.current_level + 1
					carry_time := g.time_left + f32(match next_lvl {
						2 { 30.0 }
						3 { 35.0 }
						4 { 35.0 }
						5 { 40.0 }
						6 { 45.0 }
						else { 30.0 }
					})
					g.load_level(next_lvl, carry_time)
					g.state = .level_intro
					g.intro_timer = 2.0
				}
			}
		}
		.game_over {
			g.game_over_timer -= dt
			g.update_particles(dt)
		}
		.victory {
			g.victory_timer -= dt
			g.update_particles(dt)
		}
	}
}

fn (mut g MarbleGame) update_disappearing_tiles() {
	cycle := f32(math.fmod(f64(g.global_time), 3.0))
	for y in 0 .. g.level_data.tiles.len {
		for x in 0 .. g.level_data.tiles[y].len {
			if g.level_data.tiles[y][x].tile_type == .disappearing {
				g.level_data.tiles[y][x].is_active = cycle < 1.8
			}
		}
	}
}

fn (mut g MarbleGame) update_playing(dt f32) {
	g.time_left -= dt
	if g.time_left <= 0 {
		g.time_left = 0
		g.state = .game_over
		g.game_over_timer = 4.0
		g.sound_play_gameover = true
		return
	}

	if g.time_left < 10.0 && int(g.time_left * 2) % 2 == 0 && f32(math.fmod(f64(g.time_left * 2), 1.0)) < dt * 2.0 {
		g.sound_play_warning = true
	}

	g.update_disappearing_tiles()

	// 4x Sub-stepping for ultra precision physics
	sub_steps := 4
	sub_dt := dt / f32(sub_steps)

	for _ in 0 .. sub_steps {
		g.update_player_marble(sub_dt)
		if g.has_rival {
			g.update_rival_marble(sub_dt)
			g.check_marble_marble_collision()
		}
	}

	// Update Speedometer in MPH
	g.player.speed_mph = g.player.vel.len_2d() * 3.8

	// Clear mouse delta after frame consumption
	g.mouse_dx = 0
	g.mouse_dy = 0

	g.update_munchers(dt)
	g.update_sweepers(dt)
	g.update_birds(dt)
	g.update_bumpers()
	g.update_particles(dt)

	// Dynamic Camera with velocity lookahead
	lookahead_dist := math.min(100.0, f64(g.player.vel.len_2d() * 7.0))
	vel_norm := g.player.vel.normalized_2d()
	look_sx := (vel_norm.x - vel_norm.y) * (tile_w * 0.5) * f32(lookahead_dist * 0.02)
	look_sy := (vel_norm.x + vel_norm.y) * (tile_h * 0.5) * f32(lookahead_dist * 0.02)

	target_x, target_y := world_to_screen(g.player.pos.x, g.player.pos.y, g.player.pos.z, 0, 0)
	g.target_cam_x = 420.0 - target_x - look_sx
	g.target_cam_y = 320.0 - target_y - look_sy
	g.cam_x += (g.target_cam_x - g.cam_x) * f32(math.min(1.0, f64(dt * 7.0)))
	g.cam_y += (g.target_cam_y - g.cam_y) * f32(math.min(1.0, f64(dt * 7.0)))
}

fn (mut g MarbleGame) update_player_marble(dt f32) {
	mut p := &g.player
	if p.grace_timer > 0 {
		p.grace_timer -= dt
	}

	match p.state {
		.rolling, .airborne {
			mut ax := f32(0.0)
			mut ay := f32(0.0)

			// Modern Trackball / Mouse input integration
			if g.mouse_enabled && (math.abs(f64(g.mouse_dx)) > 0.01 || math.abs(f64(g.mouse_dy)) > 0.01) {
				// Convert screen mouse movement (dx, dy) into isometric world acceleration (ax, ay)
				// screen_x = (x - y) * (W/2)  =>  dx = (ax - ay) * (W/2)
				// screen_y = (x + y) * (H/2)  =>  dy = (ax + ay) * (H/2)
				u := g.mouse_dx / (tile_w * 0.5)
				v := g.mouse_dy / (tile_h * 0.5)
				mouse_acc_scale := f32(18.0)
				ax += (u + v) * 0.5 * mouse_acc_scale
				ay += (v - u) * 0.5 * mouse_acc_scale
			}

			// Keyboard input
			move_speed := if g.input_turbo { f32(36.0) } else { f32(22.0) }
			if g.input_turbo && (g.input_up || g.input_down || g.input_left || g.input_right) {
				p.turbo_active = true
				if rand.intn(2) or { 0 } == 0 {
					g.sound_play_boost = true
					// Glowing speed streak trail
					g.add_particle(
						p.pos.sub(p.vel.scale(0.04)),
						vec3((f32(rand.intn(20) or { 10 }) - 10.0) * 0.05, (f32(rand.intn(20) or { 10 }) - 10.0) * 0.05, 0.4),
						0.35,
						80, 220, 255,
						0.14
					)
				}
			} else {
				p.turbo_active = false
			}

			if g.control_diagonal {
				if g.input_up { ay -= move_speed }
				if g.input_down { ay += move_speed }
				if g.input_left { ax -= move_speed }
				if g.input_right { ax += move_speed }
			} else {
				// Screen-relative 8-way mapping
				if g.input_up {
					ax -= move_speed * 0.707
					ay -= move_speed * 0.707
				}
				if g.input_down {
					ax += move_speed * 0.707
					ay += move_speed * 0.707
				}
				if g.input_left {
					ax -= move_speed * 0.707
					ay += move_speed * 0.707
				}
				if g.input_right {
					ax += move_speed * 0.707
					ay -= move_speed * 0.707
				}
			}

			// Micro-Hop / Jump when Space is pressed
			if g.input_jump && p.state == .rolling {
				p.vel.z = 6.8
				p.state = .airborne
				g.input_jump = false
				g.sound_play_spring = true
			}

			p.vel.x += ax * dt
			p.vel.y += ay * dt

			// Gravity
			p.vel.z -= gravity * dt
			if p.vel.z < terminal_fall_velocity {
				p.vel.z = terminal_fall_velocity
			}

			// Velocity Integration
			p.pos.x += p.vel.x * dt
			p.pos.y += p.vel.y * dt
			p.pos.z += p.vel.z * dt

			// Continuous Heightfield Collision
			valid_tile, surface_h, dz_dx, dz_dy, t_type := get_surface_info(g.level_data.tiles, p.pos.x, p.pos.y, g.global_time)

			if valid_tile && p.pos.z <= surface_h + marble_radius {
				fall_speed := -p.vel.z

				if p.grace_timer <= 0.0 && fall_speed > shatter_impact_speed {
					g.shatter_marble(mut p)
					return
				}

				p.pos.z = surface_h + marble_radius
				p.state = .rolling

				if fall_speed > 2.0 {
					p.vel.z = fall_speed * 0.28
					g.sound_play_bounce = true
					g.sound_bounce_int = f32(math.min(1.0, f64(fall_speed / 10.0)))
					if fall_speed > 8.0 {
						g.trigger_shake(0.25)
					}
				} else {
					p.vel.z = 0.0
				}

				// Slope Gravity Acceleration
				slope_acc := f32(18.0)
				p.vel.x -= dz_dx * slope_acc * dt
				p.vel.y -= dz_dy * slope_acc * dt

				// Surface Friction with Slip vs Grip
				mut friction := f32(4.5)
				if t_type == .ice {
					friction = 0.35
					// Ice particle sparks
					if rand.intn(3) or { 0 } == 0 {
						g.add_particle(
							p.pos,
							vec3(0, 0, 0.5),
							0.25,
							200, 240, 255,
							0.08
						)
					}
				}
				p.vel.x *= f32(math.max(0.0, 1.0 - friction * dt))
				p.vel.y *= f32(math.max(0.0, 1.0 - friction * dt))

				if t_type == .flat && p.vel.len_2d() < 4.0 {
					p.checkpoint_x = p.pos.x
					p.checkpoint_y = p.pos.y
					p.checkpoint_z = surface_h
				}

				match t_type {
					.catapult {
						p.vel.z = 15.0
						p.vel.y += 5.0
						p.state = .airborne
						g.sound_play_spring = true
						g.trigger_shake(0.4)
					}
					.tube_in {
						gx := int(math.floor(f64(p.pos.x)))
						gy := int(math.floor(f64(p.pos.y)))
						target_x := g.level_data.tiles[gy][gx].target_x
						target_y := g.level_data.tiles[gy][gx].target_y
						p.state = .in_tube
						p.state_timer = 0.0
						p.tube_target_x = f32(target_x) + 0.5
						p.tube_target_y = f32(target_y) + 0.5
						p.vel = vec3(0, 0, 0)
						g.sound_play_tube = true
					}
					.hazard_acid {
						if p.grace_timer <= 0.0 {
							p.state = .swallowed
							p.state_timer = 0.0
							g.sound_play_muncher = true
						}
					}
					.goal {
						p.state = .finished
						g.state = .level_clear
						g.clear_timer = 3.5
						g.sound_play_goal = true
						time_bonus := int(g.time_left) * 100
						g.bonus_time_awarded = int(g.time_left)
						g.bonus_score_awarded = time_bonus + g.current_level * 1000
						g.score += g.bonus_score_awarded
						if g.score > g.high_score {
							g.high_score = g.score
						}
					}
					else {}
				}
			} else {
				p.state = .airborne
				p.vel.x *= f32(math.max(0.0, 1.0 - 0.4 * dt))
				p.vel.y *= f32(math.max(0.0, 1.0 - 0.4 * dt))
			}

			// Accurate 3D angular roll
			p.rot_x += (p.vel.y / marble_radius) * dt
			p.rot_y += (p.vel.x / marble_radius) * dt
			p.rot_z += (p.vel.x - p.vel.y) * 0.5 * dt

			if p.pos.z < -4.0 {
				g.respawn_marble(mut p)
			}
		}
		.in_tube {
			p.state_timer += dt
			t := math.min(1.0, f64(p.state_timer / 1.0))
			p.pos.x = p.pos.x + (p.tube_target_x - p.pos.x) * (dt * 6.0)
			p.pos.y = p.pos.y + (p.tube_target_y - p.pos.y) * (dt * 6.0)
			if t >= 1.0 || (math.abs(f64(p.pos.x - p.tube_target_x)) < 0.2 && math.abs(f64(p.pos.y - p.tube_target_y)) < 0.2) {
				p.pos.x = p.tube_target_x
				p.pos.y = p.tube_target_y
				p.vel = vec3(0, 6.0, 5.0)
				p.state = .airborne
			}
		}
		.shattered {
			p.state_timer += dt
			for mut shard in p.shards {
				shard.pos.x += shard.vel.x * dt
				shard.pos.y += shard.vel.y * dt
				shard.pos.z += shard.vel.z * dt
				shard.vel.z -= gravity * dt
				shard.rot += shard.rot_speed * dt
			}
			if p.state_timer > 1.0 {
				g.respawn_marble(mut p)
			}
		}
		.reforming {
			p.state_timer += dt
			p.pos.x = p.checkpoint_x
			p.pos.y = p.checkpoint_y
			p.pos.z = p.checkpoint_z + marble_radius + 0.02
			p.vel = vec3(0, 0, 0)
			if p.state_timer > 0.6 {
				p.state = .rolling
				p.grace_timer = 1.0
			}
		}
		.swallowed {
			p.state_timer += dt
			p.pos.z -= 1.8 * dt
			if p.state_timer > 1.0 {
				g.respawn_marble(mut p)
			}
		}
		.finished {
			p.vel.x *= 0.92
			p.vel.y *= 0.92
			p.pos.x += p.vel.x * dt
			p.pos.y += p.vel.y * dt
		}
	}
}

fn (mut g MarbleGame) update_rival_marble(dt f32) {
	mut r := &g.rival

	match r.state {
		.rolling, .airborne {
			mut dir_x := g.level_data.def.goal_x - r.pos.x
			mut dir_y := g.level_data.def.goal_y - r.pos.y

			dist_to_player := (r.pos.x - g.player.pos.x) * (r.pos.x - g.player.pos.x) + (r.pos.y - g.player.pos.y) * (r.pos.y - g.player.pos.y)
			if dist_to_player < 20.0 && g.player.state == .rolling {
				dir_x = g.player.pos.x - r.pos.x
				dir_y = g.player.pos.y - r.pos.y
			}

			len := math.sqrt(f64(dir_x * dir_x + dir_y * dir_y))
			if len > 0.1 {
				dir_x /= f32(len)
				dir_y /= f32(len)
			}

			ai_speed := f32(15.0)
			r.vel.x += dir_x * ai_speed * dt
			r.vel.y += dir_y * ai_speed * dt

			r.vel.z -= gravity * dt
			if r.vel.z < terminal_fall_velocity {
				r.vel.z = terminal_fall_velocity
			}

			r.pos.x += r.vel.x * dt
			r.pos.y += r.vel.y * dt
			r.pos.z += r.vel.z * dt

			valid_tile, surface_h, dz_dx, dz_dy, t_type := get_surface_info(g.level_data.tiles, r.pos.x, r.pos.y, g.global_time)
			if valid_tile && r.pos.z <= surface_h + marble_radius {
				r.pos.z = surface_h + marble_radius
				r.state = .rolling
				r.vel.z = 0

				slope_acc := f32(16.0)
				r.vel.x -= dz_dx * slope_acc * dt
				r.vel.y -= dz_dy * slope_acc * dt

				r.vel.x *= f32(math.max(0.0, 1.0 - 4.0 * dt))
				r.vel.y *= f32(math.max(0.0, 1.0 - 4.0 * dt))

				if t_type == .goal {
					r.state = .finished
				}
			} else {
				r.state = .airborne
			}

			r.rot_x += (r.vel.y / marble_radius) * dt
			r.rot_y += (r.vel.x / marble_radius) * dt

			if r.pos.z < -4.0 {
				r.pos = vec3(r.checkpoint_x, r.checkpoint_y, r.checkpoint_z + 1.0)
				r.vel = vec3(0, 0, 0)
			}
		}
		.shattered {
			r.state_timer += dt
			if r.state_timer > 1.0 {
				r.pos = vec3(r.checkpoint_x, r.checkpoint_y, r.checkpoint_z + 1.0)
				r.state = .airborne
			}
		}
		else {}
	}
}

fn (mut g MarbleGame) check_marble_marble_collision() {
	if g.player.state != .rolling && g.player.state != .airborne {
		return
	}
	if g.rival.state != .rolling && g.rival.state != .airborne {
		return
	}

	dx := g.player.pos.x - g.rival.pos.x
	dy := g.player.pos.y - g.rival.pos.y
	dz := g.player.pos.z - g.rival.pos.z
	dist := math.sqrt(f64(dx * dx + dy * dy + dz * dz))
	min_dist := marble_radius * 2.2

	if dist < min_dist && dist > 0.001 {
		nx := f32(f64(dx) / dist)
		ny := f32(f64(dy) / dist)
		nz := f32(f64(dz) / dist)

		rvx := g.player.vel.x - g.rival.vel.x
		rvy := g.player.vel.y - g.rival.vel.y
		rvz := g.player.vel.z - g.rival.vel.z
		vel_along_normal := rvx * nx + rvy * ny + rvz * nz

		if vel_along_normal < 0 {
			restitution := f32(1.3)
			impulse := -(1.0 + restitution) * vel_along_normal / f32(1.0 + 0.67)

			g.player.vel.x += impulse * nx * 1.25
			g.player.vel.y += impulse * ny * 1.25
			g.player.vel.z += impulse * nz * 0.8

			g.rival.vel.x -= impulse * nx * 0.75
			g.rival.vel.y -= impulse * ny * 0.75

			g.sound_play_bounce = true
			g.sound_bounce_int = 1.0
			g.trigger_shake(0.35)

			for _ in 0 .. 8 {
				g.add_particle(
					g.player.pos.add(g.rival.pos).scale(0.5),
					vec3((f32(rand.intn(20) or { 10 }) - 10.0) * 0.25, (f32(rand.intn(20) or { 10 }) - 10.0) * 0.25, 2.5),
					0.5,
					255, 220, 100,
					0.14
				)
			}
		}
	}
}

fn (mut g MarbleGame) update_munchers(dt f32) {
	for mut m in g.munchers {
		m.timer += dt
		m.jaw_open = f32(0.5 + 0.5 * math.sin(f64(m.timer * 4.0)))

		if g.player.state == .rolling {
			dx := g.player.pos.x - m.pos.x
			dy := g.player.pos.y - m.pos.y
			dist := math.sqrt(f64(dx * dx + dy * dy))
			if dist < 0.55 && m.jaw_open > 0.3 {
				m.is_chewing = true
				g.player.state = .swallowed
				g.player.state_timer = 0.0
				g.sound_play_muncher = true
			}
		}
	}
}

fn (mut g MarbleGame) update_sweepers(dt f32) {
	for mut sw in g.sweepers {
		dx := sw.end_x - sw.start_x
		dy := sw.end_y - sw.start_y
		len := math.sqrt(f64(dx * dx + dy * dy))
		if len > 0.01 {
			ux := f32(f64(dx) / len)
			uy := f32(f64(dy) / len)
			sw.pos.x += ux * sw.speed * sw.dir * dt
			sw.pos.y += uy * sw.speed * sw.dir * dt

			dot := (sw.pos.x - sw.start_x) * ux + (sw.pos.y - sw.start_y) * uy
			if dot >= f32(len) {
				sw.dir = -1.0
			} else if dot <= 0.0 {
				sw.dir = 1.0
			}
		}

		if g.player.state == .rolling || g.player.state == .airborne {
			p_dx := g.player.pos.x - sw.pos.x
			p_dy := g.player.pos.y - sw.pos.y
			p_dz := math.abs(f64(g.player.pos.z - sw.z))
			if math.sqrt(f64(p_dx * p_dx + p_dy * p_dy)) < 0.9 && p_dz < 1.0 {
				g.player.vel.x += sw.dir * 14.0
				g.player.vel.y += sw.dir * 14.0
				g.sound_play_bounce = true
				g.sound_bounce_int = 0.9
				g.trigger_shake(0.3)
			}
		}
	}
}

fn (mut g MarbleGame) update_birds(dt f32) {
	for mut b in g.birds {
		b.timer += dt
		b.pos.x = b.spawn_pos.x + f32(math.sin(f64(b.timer * 1.5))) * 4.0 * b.patrol_dir_x
		b.pos.y = b.spawn_pos.y + f32(math.cos(f64(b.timer * 1.5))) * 3.0 * b.patrol_dir_y
		b.pos.z = b.spawn_pos.z + f32(math.sin(f64(b.timer * 3.0))) * 0.8

		if !b.carrying && (g.player.state == .rolling || g.player.state == .airborne) {
			dx := g.player.pos.x - b.pos.x
			dy := g.player.pos.y - b.pos.y
			dz := g.player.pos.z - b.pos.z
			if math.sqrt(f64(dx * dx + dy * dy + dz * dz)) < 0.85 {
				b.carrying = true
				g.player.vel.z = 8.5
				g.player.vel.x += b.patrol_dir_x * 4.5
				g.sound_play_spring = true
				g.trigger_shake(0.2)
			}
		}
	}
}

fn (mut g MarbleGame) update_bumpers() {
	for b_pos in g.level_data.bumpers {
		if g.player.state == .rolling || g.player.state == .airborne {
			dx := g.player.pos.x - b_pos.x
			dy := g.player.pos.y - b_pos.y
			p_pos_z := g.player.pos.z - b_pos.z
			dz := math.abs(f64(p_pos_z))
			dist := math.sqrt(f64(dx * dx + dy * dy))
			if dist < 0.75 && dz < 1.0 {
				nx := f32(f64(dx) / dist)
				ny := f32(f64(dy) / dist)
				g.player.vel.x = nx * 18.0
				g.player.vel.y = ny * 18.0
				g.player.vel.z = 5.0
				g.sound_play_bounce = true
				g.sound_bounce_int = 1.0
				g.trigger_shake(0.3)
			}
		}
	}
}

fn (mut g MarbleGame) update_particles(dt f32) {
	for mut p in g.particles {
		p.pos.x += p.vel.x * dt
		p.pos.y += p.vel.y * dt
		p.pos.z += p.vel.z * dt
		p.life -= dt
	}
	g.particles = g.particles.filter(it.life > 0)
}
