module main

import math
import rand

pub enum GameState {
	title
	world_intro
	playing
	paused
	world_clear
	game_over
	victory
}

pub struct LaserBolt {
pub mut:
	pos       Vec3
	vel       Vec3
	is_player bool
	damage    int = 1
	life      f32 = 2.5
	radius    f32 = 18.0
}

pub struct DragonSegment {
pub mut:
	pos       Vec3
	radius    f32 = 48.0
	health    int = 4
	destroyed bool
	is_head   bool
}

pub struct DragonBoss {
pub mut:
	pos          Vec3
	segments     []DragonSegment
	active       bool = true
	timer        f32
	attack_timer f32
	flash_timer  f32
	phase        int
	target_x     f32
	target_y     f32
	path_history []Vec3
}

pub struct Player {
pub mut:
	pos            Vec3
	vel            Vec3
	speed_kmh      f32 = 180.0
	max_speed_kmh  f32 = 360.0
	base_speed_kmh f32 = 190.0
	health         int = 3
	max_health     int = 3
	lives          int = 3
	score          int
	combo_count    int
	on_ground      bool = true
	is_jumping     bool
	tilt_angle     f32
	invuln_timer   f32
	shield_timer   f32
	boost_timer    f32
	fire_cooldown  f32
	run_anim_timer f32
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

pub struct PopText {
pub mut:
	text string
	x    f32
	y    f32
	life f32
	r    u8
	g    u8
	b    u8
}

pub struct WorldRunnerGame {
pub mut:
	state           GameState = .title
	current_world   int       = 1
	theme           WorldTheme
	player          Player
	camera          Camera
	obstacles       []Obstacle
	lasers          []LaserBolt
	particles       []Particle
	pop_texts       []PopText
	boss            DragonBoss
	has_boss        bool

	global_time     f32
	state_timer     f32
	time_left       f32 = 90.0
	high_score      int = 50000

	// Track curvature & hills
	track_curve     f32
	target_curve    f32
	track_hill      f32
	target_hill     f32

	// Camera shake trauma
	shake_trauma    f32
	shake_x         f32
	shake_y         f32

	// Controls
	input_left      bool
	input_right     bool
	input_up        bool
	input_down      bool
	input_jump      bool
	input_fire      bool
	input_boost     bool

	// Mouse steering
	mouse_dx        f32
	mouse_dy        f32

	// Sound triggers
	sound_laser     bool
	sound_jump      bool
	sound_boost     bool
	sound_explosion bool
	sound_powerup   bool
	sound_dragon    bool
	sound_victory   bool
	sound_crash     bool
}

pub fn new_worldrunner_game() WorldRunnerGame {
	mut game := WorldRunnerGame{
		theme: get_world_theme(1)
	}
	game.init_title()
	return game
}

pub fn (mut g WorldRunnerGame) init_title() {
	g.state = .title
	g.current_world = 1
	g.load_world(1, 90.0)
}

pub fn (mut g WorldRunnerGame) start_game(world_num int) {
	g.current_world = world_num
	g.score_reset_or_keep()
	init_time := f32(match world_num {
		1 { 90.0 }
		2 { 95.0 }
		3 { 100.0 }
		4 { 100.0 }
		5 { 110.0 }
		else { 90.0 }
	})
	g.load_world(world_num, init_time)
	g.state = .world_intro
	g.state_timer = 2.2
}

fn (mut g WorldRunnerGame) score_reset_or_keep() {
	if g.state == .title || g.state == .game_over {
		g.player.score = 0
		g.player.lives = 3
		g.player.combo_count = 0
	}
}

pub fn (mut g WorldRunnerGame) load_world(world_num int, carry_time f32) {
	g.current_world = world_num
	g.theme = get_world_theme(world_num)
	g.time_left = carry_time

	g.player = Player{
		pos: vec3(0, 0, 50.0)
		vel: vec3(0, 0, 0)
		speed_kmh: 190.0
		health: 3
		max_health: 3
		lives: g.player.lives
		score: g.player.score
		combo_count: g.player.combo_count
		invuln_timer: 2.0
	}

	g.camera = Camera{
		x: 0
		y: 115.0
		z: -140.0
		focal_len: 440.0
		horizon_y: 240.0
	}

	g.obstacles = generate_world_obstacles(world_num)
	g.lasers.clear()
	g.particles.clear()
	g.pop_texts.clear()
	g.shake_trauma = 0.0

	// Initialize Segmented Serpent Dragon Boss
	g.has_boss = g.theme.has_dragon
	if g.has_boss {
		boss_start_z := g.theme.track_length - 800.0
		mut segments := []DragonSegment{}
		// Head
		segments << DragonSegment{
			pos: vec3(0, 190, boss_start_z)
			radius: 58.0
			health: 14
			is_head: true
		}
		// 12 body segments
		for i in 1 .. 13 {
			segments << DragonSegment{
				pos: vec3(0, 190, boss_start_z + f32(i * 65))
				radius: 46.0 - f32(i) * 1.3
				health: 4
				is_head: false
			}
		}
		// Tail
		segments << DragonSegment{
			pos: vec3(0, 190, boss_start_z + 850.0)
			radius: 24.0
			health: 4
			is_head: false
		}

		g.boss = DragonBoss{
			pos: vec3(0, 190, boss_start_z)
			segments: segments
			active: true
			target_x: 0
			target_y: 190.0
		}
	}
}

pub fn (mut g WorldRunnerGame) trigger_shake(amount f32) {
	g.shake_trauma = f32(math.min(1.0, f64(g.shake_trauma + amount)))
}

pub fn (mut g WorldRunnerGame) add_pop_text(text string, x f32, y f32, r u8, g_col u8, b u8) {
	g.pop_texts << PopText{
		text: text
		x: x
		y: y
		life: 1.2
		r: r
		g: g_col
		b: b
	}
}

pub fn (mut g WorldRunnerGame) add_explosion_particles(pos Vec3, count int) {
	g.sound_explosion = true
	g.trigger_shake(0.35)
	for _ in 0 .. count {
		angle := f32(rand.intn(360) or { 0 }) * math.pi / 180.0
		pitch := f32(rand.intn(180) or { 90 } - 90) * math.pi / 180.0
		spd := 140.0 + f32(rand.intn(280) or { 140 })
		g.particles << Particle{
			pos: pos
			vel: vec3(
				f32(math.cos(angle) * math.cos(pitch)) * spd,
				f32(math.sin(pitch)) * spd + 90.0,
				f32(math.sin(angle) * math.cos(pitch)) * spd
			)
			life: 0.6 + f32(rand.intn(30) or { 15 }) * 0.01
			max_life: 0.8
			r: 255
			g: u8(130 + rand.intn(125) or { 80 })
			b: 40
			size: f32(15.0 + f64(rand.intn(12) or { 6 }))
		}
	}
}

pub fn (mut g WorldRunnerGame) update(dt f32) {
	g.global_time += dt

	if g.shake_trauma > 0 {
		g.shake_trauma = f32(math.max(0.0, f64(g.shake_trauma - dt * 1.6)))
		shake_mag := g.shake_trauma * g.shake_trauma * 20.0
		g.shake_x = (f32(rand.intn(200) or { 100 }) - 100.0) * 0.01 * shake_mag
		g.shake_y = (f32(rand.intn(200) or { 100 }) - 100.0) * 0.01 * shake_mag
	} else {
		g.shake_x = 0
		g.shake_y = 0
	}

	match g.state {
		.title {}
		.world_intro {
			g.state_timer -= dt
			if g.state_timer <= 0 {
				g.state = .playing
			}
		}
		.playing {
			g.update_playing(dt)
		}
		.paused {}
		.world_clear {
			g.state_timer -= dt
			g.update_particles(dt)
			g.update_pop_texts(dt)
			if g.state_timer <= 0 {
				if g.current_world >= 5 {
					g.state = .victory
					g.state_timer = 6.0
				} else {
					g.start_game(g.current_world + 1)
				}
			}
		}
		.game_over {
			g.state_timer -= dt
			g.update_particles(dt)
			g.update_pop_texts(dt)
		}
		.victory {
			g.state_timer -= dt
			g.update_particles(dt)
			g.update_pop_texts(dt)
		}
	}
}

fn (mut g WorldRunnerGame) update_pop_texts(dt f32) {
	for mut pt in g.pop_texts {
		pt.y -= dt * 38.0
		pt.life -= dt
	}
	g.pop_texts = g.pop_texts.filter(it.life > 0)
}

fn (mut g WorldRunnerGame) update_particles(dt f32) {
	for mut p in g.particles {
		p.pos.x += p.vel.x * dt
		p.pos.y += p.vel.y * dt
		p.pos.z += p.vel.z * dt
		p.vel.y -= 450.0 * dt
		p.life -= dt
	}
	g.particles = g.particles.filter(it.life > 0)
}

fn (mut g WorldRunnerGame) update_playing(dt f32) {
	g.time_left -= dt
	if g.time_left <= 0 {
		g.time_left = 0
		g.player_die()
		return
	}

	g.update_player(dt)
	g.update_camera(dt)
	g.update_track_curves(dt)
	g.update_obstacles(dt)
	g.update_lasers(dt)
	if g.has_boss {
		g.update_dragon_boss(dt)
	}
	g.update_particles(dt)
	g.update_pop_texts(dt)

	if g.player.pos.z >= g.theme.track_length && (!g.has_boss || !g.boss.active) {
		g.state = .world_clear
		g.state_timer = 4.0
		g.sound_victory = true
		time_bonus := int(g.time_left) * 100
		g.player.score += time_bonus + g.current_world * 2500
		g.add_pop_text('WORLD ${g.current_world} CLEARED!', 420, 200, 40, 255, 120)
		if g.player.score > g.high_score {
			g.high_score = g.player.score
		}
	}
}

fn (mut g WorldRunnerGame) update_player(dt f32) {
	mut p := &g.player

	if p.invuln_timer > 0 { p.invuln_timer -= dt }
	if p.shield_timer > 0 { p.shield_timer -= dt }
	if p.fire_cooldown > 0 { p.fire_cooldown -= dt }

	// High-Octane Speed Scaling
	if g.input_boost || p.boost_timer > 0 {
		if p.boost_timer > 0 { p.boost_timer -= dt }
		p.speed_kmh += (p.max_speed_kmh - p.speed_kmh) * (dt * 6.5)
		if rand.intn(3) or { 0 } == 0 {
			g.sound_boost = true
		}
	} else if g.input_down {
		p.speed_kmh += (85.0 - p.speed_kmh) * (dt * 7.5)
	} else {
		p.speed_kmh += (p.base_speed_kmh - p.speed_kmh) * (dt * 4.0)
	}

	forward_spd := p.speed_kmh * 4.4
	p.vel.z = forward_spd
	p.pos.z += p.vel.z * dt

	// Responsive Lateral Strafe (X)
	mut target_vx := f32(0.0)
	if g.input_left { target_vx -= 720.0; p.tilt_angle = -0.25 }
	if g.input_right { target_vx += 720.0; p.tilt_angle = 0.25 }

	if math.abs(f64(g.mouse_dx)) > 0.01 {
		target_vx += g.mouse_dx * 32.0
		p.tilt_angle = f32(math.max(-0.35, math.min(0.35, f64(g.mouse_dx * 0.025))))
		g.mouse_dx = 0
	}

	if !g.input_left && !g.input_right && math.abs(f64(g.mouse_dx)) <= 0.01 {
		p.tilt_angle *= 0.82
	}

	p.vel.x += (target_vx - p.vel.x) * f32(math.min(1.0, f64(dt * 14.0)))
	p.pos.x += p.vel.x * dt

	if p.pos.x < -440.0 { p.pos.x = -440.0; p.vel.x = 0 }
	if p.pos.x > 440.0 { p.pos.x = 440.0; p.vel.x = 0 }

	// High Jetpack Jump (Y)
	if g.input_jump && p.on_ground {
		p.vel.y = 540.0
		p.on_ground = false
		p.is_jumping = true
		g.sound_jump = true
	}

	if !p.on_ground {
		p.vel.y -= 1150.0 * dt
		p.pos.y += p.vel.y * dt
		if p.pos.y <= 0 {
			p.pos.y = 0
			p.vel.y = 0
			p.on_ground = true
			p.is_jumping = false
		}
	}

	p.run_anim_timer += dt * (p.speed_kmh / 38.0)

	// Rapid-Fire Dual Laser Cannons
	if g.input_fire && p.fire_cooldown <= 0 {
		p.fire_cooldown = 0.14
		g.sound_laser = true

		g.lasers << LaserBolt{
			pos: vec3(p.pos.x - 24.0, p.pos.y + 24.0, p.pos.z + 40.0)
			vel: vec3(p.vel.x * 0.2, 0, p.vel.z + 1500.0)
			is_player: true
			damage: 1
		}
		g.lasers << LaserBolt{
			pos: vec3(p.pos.x + 24.0, p.pos.y + 24.0, p.pos.z + 40.0)
			vel: vec3(p.vel.x * 0.2, 0, p.vel.z + 1500.0)
			is_player: true
			damage: 1
		}
	}
}

fn (mut g WorldRunnerGame) update_camera(dt f32) {
	target_cam_x := g.player.pos.x * 0.68
	target_cam_y := 115.0 + g.player.pos.y * 0.4
	target_cam_z := g.player.pos.z - 160.0

	g.camera.x += (target_cam_x - g.camera.x) * f32(math.min(1.0, f64(dt * 8.5)))
	g.camera.y += (target_cam_y - g.camera.y) * f32(math.min(1.0, f64(dt * 8.5)))
	g.camera.z = target_cam_z

	// Dynamic FOV tunnel vision scaling
	speed_ratio := (g.player.speed_kmh - 180.0) / 180.0
	g.camera.focal_len = 440.0 + speed_ratio * 100.0
}

fn (mut g WorldRunnerGame) update_track_curves(dt f32) {
	z := g.player.pos.z
	g.target_curve = f32(math.sin(f64(z * 0.00065))) * 1.9
	g.target_hill = f32(math.cos(f64(z * 0.00085))) * 2.3

	g.track_curve += (g.target_curve - g.track_curve) * (dt * 3.2)
	g.track_hill += (g.target_hill - g.track_hill) * (dt * 3.2)
}

fn (mut g WorldRunnerGame) update_obstacles(dt f32) {
	for mut obs in g.obstacles {
		if !obs.active { continue }
		obs.timer += dt
		obs.rot_y += dt * 2.6

		dz := obs.pos.z - g.player.pos.z
		if dz >= -65.0 && dz <= 65.0 {
			dx := math.abs(f64(obs.pos.x - g.player.pos.x))
			dy := math.abs(f64(obs.pos.y - g.player.pos.y))

			match obs.obs_type {
				.energy_ring {
					if dx < 65.0 && dy < 65.0 {
						obs.active = false
						g.player.boost_timer = 3.2
						g.player.score += 350
						g.sound_powerup = true
						g.add_pop_text('+350 TURBO SURGE!', g.player.pos.x, 150, 60, 245, 255)
					}
				}
				.item_pod {
					if dx < 48.0 && dy < 48.0 {
						obs.active = false
						g.sound_powerup = true
						match obs.item_type {
							.speed_boost {
								g.player.boost_timer = 4.5
								g.add_pop_text('HYPER BOOST 360 KM/H!', g.player.pos.x, 150, 60, 245, 255)
							}
							.invincible_shield {
								g.player.shield_timer = 8.5
								g.add_pop_text('SHIELD BARRIER!', g.player.pos.x, 150, 255, 215, 0)
							}
							.health_pack {
								if g.player.health < g.player.max_health { g.player.health++ }
								g.add_pop_text('+1 HEALTH!', g.player.pos.x, 150, 40, 255, 120)
							}
							else {
								g.player.score += 500
								g.add_pop_text('+500 PTS!', g.player.pos.x, 150, 255, 255, 255)
							}
						}
					}
				}
				.pit {
					if dx < f64(obs.size.x * 0.5) && g.player.on_ground {
						g.player_hit(1)
					}
				}
				else {
					if dx < f64(obs.size.x * 0.5 + 20.0) && dy < f64(obs.size.y * 0.5 + 20.0) {
						if g.player.shield_timer > 0 {
							obs.active = false
							g.add_explosion_particles(obs.pos, 18)
							g.player.score += 250
							g.add_pop_text('+250 SMASH!', obs.pos.x, obs.pos.y + 40.0, 255, 215, 0)
						} else {
							g.player_hit(1)
							obs.active = false
							g.add_explosion_particles(obs.pos, 16)
						}
					}
				}
			}
		}

		if obs.obs_type == .turret_pod && dz >= 200.0 && dz <= 1200.0 {
			if int(obs.timer * 1.6) != int((obs.timer - dt) * 1.6) {
				g.lasers << LaserBolt{
					pos: vec3(obs.pos.x, obs.pos.y + 20.0, obs.pos.z - 30.0)
					vel: vec3(0, 0, -620.0)
					is_player: false
					damage: 1
				}
			}
		}
	}
}

fn (mut g WorldRunnerGame) update_lasers(dt f32) {
	for mut bolt in g.lasers {
		bolt.pos.x += bolt.vel.x * dt
		bolt.pos.y += bolt.vel.y * dt
		bolt.pos.z += bolt.vel.z * dt
		bolt.life -= dt

		if bolt.is_player {
			for mut obs in g.obstacles {
				if !obs.active || obs.obs_type == .energy_ring || obs.obs_type == .pit { continue }
				dz := math.abs(f64(bolt.pos.z - obs.pos.z))
				if dz < 45.0 {
					dx := math.abs(f64(bolt.pos.x - obs.pos.x))
					dy := math.abs(f64(bolt.pos.y - obs.pos.y))
					if dx < f64(obs.size.x * 0.5) && dy < f64(obs.size.y * 0.5) {
						bolt.life = 0
						obs.health -= bolt.damage
						if obs.health <= 0 {
							obs.active = false
							g.add_explosion_particles(obs.pos, 18)
							g.player.score += 150
							g.player.combo_count++
							combo_bonus := g.player.combo_count * 50
							g.player.score += combo_bonus
							if g.player.combo_count > 1 {
								g.add_pop_text('COMBO x${g.player.combo_count} (+${combo_bonus})', obs.pos.x, obs.pos.y + 40.0, 255, 220, 80)
							} else {
								g.add_pop_text('+150', obs.pos.x, obs.pos.y + 40.0, 255, 240, 80)
							}
						}
					}
				}
			}

			if g.has_boss && g.boss.active {
				for mut seg in g.boss.segments {
					if seg.destroyed { continue }
					dz := math.abs(f64(bolt.pos.z - seg.pos.z))
					if dz < 55.0 {
						dx := math.abs(f64(bolt.pos.x - seg.pos.x))
						dy := math.abs(f64(bolt.pos.y - seg.pos.y))
						if dx < f64(seg.radius) && dy < f64(seg.radius) {
							bolt.life = 0
							seg.health -= bolt.damage
							g.boss.flash_timer = 0.12
							if seg.health <= 0 {
								seg.destroyed = true
								g.add_explosion_particles(seg.pos, 25)
								g.player.score += if seg.is_head { 3500 } else { 600 }
								g.add_pop_text(if seg.is_head { '+3500 BOSS HEAD!' } else { '+600 SEGMENT' }, seg.pos.x, seg.pos.y + 40.0, 255, 215, 0)
							}
						}
					}
				}
			}
		} else {
			dz := math.abs(f64(bolt.pos.z - g.player.pos.z))
			if dz < 38.0 {
				dx := math.abs(f64(bolt.pos.x - g.player.pos.x))
				dy := math.abs(f64(bolt.pos.y - (g.player.pos.y + 24.0)))
				if dx < 30.0 && dy < 38.0 {
					bolt.life = 0
					g.player_hit(1)
				}
			}
		}
	}

	g.lasers = g.lasers.filter(it.life > 0 && it.pos.z >= g.camera.z && it.pos.z <= g.camera.z + 2500.0)
}

fn (mut g WorldRunnerGame) update_dragon_boss(dt f32) {
	if !g.boss.active { return }
	mut boss := &g.boss
	boss.timer += dt
	boss.attack_timer += dt
	if boss.flash_timer > 0 { boss.flash_timer -= dt }

	boss.pos.z = g.player.pos.z + 460.0 + f32(math.sin(f64(boss.timer * 1.6))) * 190.0
	boss.pos.x = f32(math.sin(f64(boss.timer * 2.3))) * 290.0
	boss.pos.y = 145.0 + f32(math.cos(f64(boss.timer * 1.9))) * 115.0

	boss.path_history.prepend(boss.pos)
	if boss.path_history.len > 120 {
		boss.path_history.delete(boss.path_history.len - 1)
	}

	for i in 0 .. boss.segments.len {
		history_idx := i * 7
		if history_idx < boss.path_history.len {
			boss.segments[i].pos = boss.path_history[history_idx]
		}
	}

	if boss.attack_timer >= 1.9 {
		boss.attack_timer = 0.0
		g.sound_dragon = true
		g.lasers << LaserBolt{
			pos: vec3(boss.pos.x, boss.pos.y, boss.pos.z - 40.0)
			vel: vec3(
				(g.player.pos.x - boss.pos.x) * 0.85,
				(g.player.pos.y - boss.pos.y) * 0.85,
				-680.0
			)
			is_player: false
			damage: 1
			radius: 26.0
		}
	}

	if boss.segments.len > 0 && boss.segments[0].destroyed {
		boss.active = false
		g.add_explosion_particles(boss.pos, 55)
		g.sound_victory = true
		g.player.score += 10000
		g.add_pop_text('+10000 DRAGON OBLITERATED!', 420, 180, 40, 255, 120)
	}
}

pub fn (mut g WorldRunnerGame) player_hit(damage int) {
	if g.player.invuln_timer > 0 || g.player.shield_timer > 0 { return }

	g.player.health -= damage
	g.player.invuln_timer = 2.0
	g.player.combo_count = 0
	g.sound_crash = true
	g.trigger_shake(0.5)

	if g.player.health <= 0 {
		g.player_die()
	}
}

pub fn (mut g WorldRunnerGame) player_die() {
	g.player.lives--
	g.player.combo_count = 0
	g.add_explosion_particles(g.player.pos, 30)
	g.sound_crash = true
	g.trigger_shake(0.7)

	if g.player.lives <= 0 {
		g.state = .game_over
		g.state_timer = 4.0
	} else {
		g.player.health = g.player.max_health
		g.player.invuln_timer = 3.0
		g.player.speed_kmh = 190.0
		g.player.on_ground = true
		g.player.pos.y = 0
	}
}
