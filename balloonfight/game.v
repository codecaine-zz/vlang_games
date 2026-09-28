module main

import math
import rand
import os



enum GameMode {
	mode_a_1p
	mode_b_2p
	balloon_trip
}

enum GameState {
	title
	playing
	paused
	phase_clear
	game_over
}

enum CharacterState {
	flying
	parachuting
	pumping
	drowning
	dead
}

enum EnemyRank {
	yellow
	pink
	red
}

pub enum AIBehavior {
	patrol
	climb
	dive
	evade
	panic_water
	seek_platform
}

pub struct Particle {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	life     f64
	max_life f64
	color    Color
	size     f64 = 3.0
}

pub struct FloatText {
pub mut:
	x     f64
	y     f64
	vy    f64 = -35.0
	text  string
	color Color
	life  f64 = 1.0
}

pub struct BonusBubble {
pub mut:
	x         f64
	y         f64
	base_x    f64
	vy        f64 = -45.0
	phase     f64
	active    bool = true
	score_val int = 500
	radius    f64 = 10.0
}

struct RankProfile {
	flap_power      f64
	max_vx          f64
	accel           f64
	reaction_time   f64
	desired_alt     f64
	dive_range_x    f64
	prediction_lead f64
	dodge_reflex    f64
}

fn get_rank_profile(rank EnemyRank) RankProfile {
	return match rank {
		.yellow {
			RankProfile{
				flap_power:      190.0
				max_vx:          130.0
				accel:           160.0
				reaction_time:   0.28
				desired_alt:     35.0
				dive_range_x:    35.0
				prediction_lead: 0.0
				dodge_reflex:    0.35
			}
		}
		.pink {
			RankProfile{
				flap_power:      215.0
				max_vx:          175.0
				accel:           220.0
				reaction_time:   0.16
				desired_alt:     50.0
				dive_range_x:    48.0
				prediction_lead: 0.22
				dodge_reflex:    0.68
			}
		}
		.red {
			RankProfile{
				flap_power:      240.0
				max_vx:          225.0
				accel:           290.0
				reaction_time:   0.09
				desired_alt:     70.0
				dive_range_x:    65.0
				prediction_lead: 0.45
				dodge_reflex:    0.92
			}
		}
	}
}

struct Player {
pub mut:
	id            int
	motion        MotionState
	balloons      int = 2
	state         CharacterState = .flying
	score         int
	lives         int = 3
	flap_cooldown f64
	pump_timer    f64
	invincibility f64
	w             f64 = 28.0
	h             f64 = 36.0
	facing_right  bool = true
}

fn new_player(id int, x f64, y f64) Player {
	return Player{
		id:            id
		motion:        MotionState{
			x:           x
			y:           y
			is_grounded: false
		}
		balloons:      2
		state:         .flying
		lives:         3
		invincibility: 2.0
	}
}

struct Enemy {
pub mut:
	id            int
	rank          EnemyRank
	motion        MotionState
	balloons      int = 2
	state         CharacterState = .pumping
	ai_timer      f64
	flap_timer    f64
	pump_timer    f64
	score_val     int = 500
	w             f64 = 28.0
	h             f64 = 36.0
	active        bool = true
	target_x      f64
	target_y      f64
	facing_right  bool = true
	behavior      AIBehavior = .patrol
	dive_cooldown f64
	wing_flap     bool
}

struct GiantFish {
pub mut:
	x        f64
	y        f64 = 550.0
	vy       f64
	active   bool
	state    int // 0: hidden, 1: leaping, 2: diving
	target_x f64
	cooldown f64
}

struct Spark {
pub mut:
	x      f64
	y      f64
	vx     f64
	vy     f64
	radius f64 = 8.0
}

struct Cloud {
pub mut:
	x           f64
	y           f64
	spark_timer f64
}

struct TripBalloon {
pub mut:
	x         f64
	y         f64
	collected bool
	value     int = 300
}

struct GameEngine {
pub mut:
	mode          GameMode  = .mode_a_1p
	state         GameState = .title
	phase         int       = 1
	score         int
	high_score    int = 25000
	elapsed_time  f64
	world_w       f64 = 800.0
	world_h       f64 = 600.0
	water_level   f64 = 540.0
	players       []Player
	enemies       []Enemy
	platforms     []Platform
	fish          GiantFish
	sparks        []Spark
	clouds        []Cloud
	trip_balloons []TripBalloon
	trip_scroll_x f64
	spawn_timer   f64
	next_enemy_id int = 1

	particles     []Particle
	float_texts   []FloatText
	bubbles       []BonusBubble
	shake_trauma  f64

	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut ge GameEngine) init_textures(renderer &Renderer) {
	paths := [
		'assets/sprites/balloonfight.png',
		'./assets/sprites/balloonfight.png',
		'../assets/sprites/balloonfight.png',
		'balloonfight/assets/sprites/balloonfight.png',
	]
	for p in paths {
		if os.exists(p) {
			ge.sprite_texture = load_texture(renderer.ctx, p)
			if ge.sprite_texture != unsafe { nil } && ge.sprite_texture.valid {
				println('balloonfight Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn new_game_engine() GameEngine {
	return GameEngine{
		state:      .title
		mode:       .mode_a_1p
		high_score: 25000
	}
}

fn (ge &GameEngine) start_game(mode GameMode) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mutable_ge.mode = mode
	mutable_ge.state = .playing
	mutable_ge.phase = 1
	mutable_ge.score = 0
	mutable_ge.elapsed_time = 0
	mutable_ge.trip_scroll_x = 0

	mutable_ge.players.clear()
	mutable_ge.players << new_player(0, 300.0, 420.0)

	if mode == .mode_b_2p {
		mutable_ge.players << new_player(1, 500.0, 420.0)
	}

	mutable_ge.setup_stage()
}

fn (ge &GameEngine) setup_stage() {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mutable_ge.enemies.clear()
	mutable_ge.platforms.clear()
	mutable_ge.sparks.clear()
	mutable_ge.clouds.clear()
	mutable_ge.trip_balloons.clear()
	mutable_ge.particles.clear()
	mutable_ge.float_texts.clear()
	mutable_ge.bubbles.clear()
	mutable_ge.fish = GiantFish{}

	if mutable_ge.mode == .balloon_trip {
		for i in 0 .. 50 {
			bx := 400.0 + f64(i * 120)
			by := 150.0 + math.sin(f64(i) * 0.8) * 120.0
			mutable_ge.trip_balloons << TripBalloon{
				x: bx
				y: by
			}
		}
		for i in 0 .. 15 {
			sx := 600.0 + f64(i * 250)
			sy := 100.0 + (rand.f64() * 320.0)
			mutable_ge.sparks << Spark{
				x:  sx
				y:  sy
				vx: 0
				vy: 80.0
			}
		}
		return
	}

	// Platforms
	mutable_ge.platforms << Platform{
		x: 100
		y: 450
		w: 160
		h: 18
	}
	mutable_ge.platforms << Platform{
		x: 540
		y: 450
		w: 160
		h: 18
	}
	mutable_ge.platforms << Platform{
		x: 320
		y: 300
		w: 160
		h: 18
	}
	mutable_ge.platforms << Platform{
		x: 150
		y: 180
		w: 140
		h: 18
	}
	mutable_ge.platforms << Platform{
		x: 510
		y: 180
		w: 140
		h: 18
	}

	// Spawn Enemies
	num_enemies := math.min(6, 2 + mutable_ge.phase)
	for i in 0 .. num_enemies {
		plat_idx := i % mutable_ge.platforms.len
		plat := mutable_ge.platforms[plat_idx]

		mut rank := EnemyRank.yellow
		mut score_val := 500
		if mutable_ge.phase >= 2 && i % 2 == 1 {
			rank = .pink
			score_val = 750
		}
		if mutable_ge.phase >= 4 && i % 3 == 2 {
			rank = .red
			score_val = 1000
		}

		spawn_x := plat.x + 20.0 + (f64(i) * 25.0)
		spawn_y := plat.y - 18.0

		id := mutable_ge.next_enemy_id
		mutable_ge.next_enemy_id++

		mutable_ge.enemies << Enemy{
			id:           id
			rank:         rank
			motion:       MotionState{
				x:           spawn_x
				y:           spawn_y
				is_grounded: true
			}
			balloons:     0
			state:        .pumping
			pump_timer:   1.5
			score_val:    score_val
			active:       true
			facing_right: (i % 2 == 0)
			behavior:     .patrol
		}
	}

	if mutable_ge.phase >= 2 {
		mutable_ge.clouds << Cloud{
			x: 380
			y: 80
		}
	}
}

fn (ge &GameEngine) update(dt f64, p1_left bool, p1_right bool, p1_flap bool, p2_left bool, p2_right bool, p2_flap bool, sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mut sm := unsafe { &SoundManager(sound_mgr) }
	if mutable_ge.state != .playing {
		return
	}

	mutable_ge.elapsed_time += dt

	if mutable_ge.mode == .balloon_trip {
		mutable_ge.update_balloon_trip_mode(dt, p1_left, p1_right, p1_flap, sound_mgr)
		return
	}

	// Update Players
	for i in 0 .. mutable_ge.players.len {
		mut p := unsafe { &Player(&mutable_ge.players[i]) }

		if p.state == .dead {
			continue
		}

		if p.invincibility > 0 {
			p.invincibility -= dt
		}

		left := if i == 0 { p1_left } else { p2_left }
		right := if i == 0 { p1_right } else { p2_right }
		flap := if i == 0 { p1_flap } else { p2_flap }

		if p.state == .pumping {
			p.pump_timer -= dt
			if p.pump_timer <= 0 {
				p.balloons++
				sm.play_pickup()
				if p.balloons >= 2 {
					p.state = .flying
					p.motion.is_grounded = false
					apply_flap(mut p.motion, 200.0)
				} else {
					p.pump_timer = 0.8
				}
			}
			continue
		}

		if left {
			accel := if p.motion.is_grounded { 360.0 } else { 200.0 }
			p.motion.vx -= accel * dt
			p.facing_right = false
		}
		if right {
			accel := if p.motion.is_grounded { 360.0 } else { 200.0 }
			p.motion.vx += accel * dt
			p.facing_right = true
		}

		if p.flap_cooldown > 0 {
			p.flap_cooldown -= dt
		}

		if flap && p.flap_cooldown <= 0 && p.balloons > 0 {
			p.flap_cooldown = 0.18
			apply_flap(mut p.motion, 180.0)
			sm.play_flap()
		}

		if p.state == .parachuting {
			p.motion.vy = 70.0
		}

		update_motion(mut p.motion, dt, mutable_ge.world_w)

		// Platform collisions & ledge support
		if update_platforms_collision(mut p.motion, p.w, p.h, mutable_ge.platforms) {
			if p.state == .parachuting {
				// Player lost both balloons and crashed!
				p.state = .drowning
				sm.play_splash()
				p.lives--
				if p.lives <= 0 {
					p.state = .dead
					mutable_ge.state = .game_over
				} else {
					// Respawn safely with full balloons
					p.motion.x = 400.0
					p.motion.y = 200.0
					p.motion.vx = 0
					p.motion.vy = 0
					p.balloons = 2
					p.state = .flying
					p.invincibility = 2.5
				}
			}
		}

		// Water drowning check
		if p.motion.y >= mutable_ge.water_level {
			p.state = .drowning
			sm.play_splash()
			p.lives--
			if p.lives <= 0 {
				p.state = .dead
				mutable_ge.state = .game_over
			} else {
				// Respawn safely
				p.motion.x = 400.0
				p.motion.y = 200.0
				p.motion.vx = 0
				p.motion.vy = 0
				p.balloons = 2
				p.state = .flying
				p.invincibility = 2.0
			}
		}
	}

	// Update Enemies AI
	for i in 0 .. mutable_ge.enemies.len {
		if !mutable_ge.enemies[i].active {
			continue
		}
		mut enemy := unsafe { &mutable_ge.enemies[i] }
		mutable_ge.update_single_enemy_ai(mut enemy, dt, sound_mgr)
	}

	// Update FX (particles, floating text, bonus bubbles)
	mutable_ge.update_fx(dt, sound_mgr)

	// Balloon Popping Collisions
	mutable_ge.check_balloon_collisions(sound_mgr)

	// Giant Fish Water Hazard
	mutable_ge.update_giant_fish(dt, sound_mgr)

	// Storm Clouds & Spark Emissions
	for mut cloud in mutable_ge.clouds {
		cloud.spark_timer += dt
		if cloud.spark_timer >= 5.0 {
			cloud.spark_timer = 0
			mutable_ge.sparks << Spark{
				x:  cloud.x
				y:  cloud.y + 20.0
				vx: 120.0
				vy: 120.0
			}
		}
	}

	// Update Sparks
	mut keep_sparks := []Spark{}
	for mut spark in mutable_ge.sparks {
		spark.x += spark.vx * dt
		spark.y += spark.vy * dt

		if spark.x <= 10.0 || spark.x >= mutable_ge.world_w - 10.0 {
			spark.vx *= -1.0
		}
		if spark.y <= 10.0 || spark.y >= mutable_ge.water_level - 20.0 {
			spark.vy *= -1.0
		}

		for mut p in mutable_ge.players {
			if (p.state == .flying || p.state == .parachuting) && p.invincibility <= 0 {
				dist := math.hypot(spark.x - p.motion.x, spark.y - p.motion.y)
				if dist <= (spark.radius + 14.0) {
					sm.play_spark_zap()
					p.lives--
					if p.lives <= 0 {
						p.state = .dead
						mutable_ge.state = .game_over
					} else {
						p.motion.x = 400.0
						p.motion.y = 200.0
						p.motion.vx = 0
						p.motion.vy = 0
						p.balloons = 2
						p.state = .flying
						p.invincibility = 2.5
					}
				}
			}
		}
		keep_sparks << spark
	}
	mutable_ge.sparks = keep_sparks

	// Check Phase Clear
	mut active_enemies := 0
	for enemy in mutable_ge.enemies {
		if enemy.active {
			active_enemies++
		}
	}

	if active_enemies == 0 {
		mutable_ge.phase++
		mutable_ge.state = .phase_clear
		sm.play_phase_clear()
	}
}

fn (mut ge GameEngine) spawn_particles(x f64, y f64, count int, color Color) {
	prod_fx_trigger_shockwave(f32(x), f32(y), 90.0, color.r, color.g, color.b)
	for _ in 0 .. count {
		ang := rand.f64() * math.pi * 2.0
		spd := 30.0 + rand.f64() * 140.0
		ge.particles << Particle{
			x:        x
			y:        y
			vx:       math.cos(ang) * spd
			vy:       math.sin(ang) * spd - 30.0
			life:     0.5 + rand.f64() * 0.4
			max_life: 0.9
			color:    color
			size:     2.5 + rand.f64() * 2.0
		}
	}
}

fn (mut ge GameEngine) spawn_float_text(x f64, y f64, text string, color Color) {
	ge.float_texts << FloatText{
		x:     x
		y:     y
		text:  text
		color: color
		life:  1.0
	}
}

fn (mut ge GameEngine) spawn_bonus_bubble(x f64, y f64) {
	ge.bubbles << BonusBubble{
		x:         x
		y:         y
		base_x:    x
		vy:        -45.0 - rand.f64() * 20.0
		phase:     rand.f64() * math.pi * 2.0
		active:    true
		score_val: 500
		radius:    10.0
	}
}

fn (mut ge GameEngine) update_fx(dt f64, sound_mgr &SoundManager) {
	if ge.shake_trauma > 0 {
		ge.shake_trauma = math.max(0.0, ge.shake_trauma - dt * 2.4)
	}

	// Update Particles
	mut keep_particles := []Particle{}
	for mut part in ge.particles {
		part.life -= dt
		if part.life > 0 {
			part.x += part.vx * dt
			part.y += part.vy * dt
			part.vy += 180.0 * dt
			keep_particles << part
		}
	}
	ge.particles = keep_particles

	// Update Floating Texts
	mut keep_texts := []FloatText{}
	for mut ft in ge.float_texts {
		ft.life -= dt
		if ft.life > 0 {
			ft.y += ft.vy * dt
			keep_texts << ft
		}
	}
	ge.float_texts = keep_texts

	// Update Bonus Bubbles
	mut keep_bubbles := []BonusBubble{}
	for mut bubble in ge.bubbles {
		if !bubble.active {
			continue
		}
		bubble.phase += dt * 3.5
		bubble.y += bubble.vy * dt
		bubble.x = bubble.base_x + math.sin(bubble.phase) * 18.0

		// Wrap around screen
		if bubble.x < -15.0 {
			bubble.x += ge.world_w + 30.0
			bubble.base_x += ge.world_w + 30.0
		} else if bubble.x > ge.world_w + 15.0 {
			bubble.x -= ge.world_w + 30.0
			bubble.base_x -= ge.world_w + 30.0
		}

		// Popped at top of screen
		if bubble.y < 20.0 {
			bubble.active = false
			continue
		}

		// Check player collection
		mut collected := false
		mut sm := unsafe { &SoundManager(sound_mgr) }
		for mut p in ge.players {
			if p.state == .flying || p.state == .parachuting {
				dist := math.hypot(wrap_dx(p.motion.x, bubble.x, ge.world_w), p.motion.y - bubble.y)
				if dist <= (14.0 + bubble.radius) {
					collected = true
					sm.play_pickup()
					p.score += bubble.score_val
					ge.score += bubble.score_val
					if ge.score > ge.high_score {
						ge.high_score = ge.score
					}
					ge.spawn_float_text(bubble.x, bubble.y, '+${bubble.score_val}', Color{
						r: 250
						g: 204
						b: 21
					})
					ge.spawn_particles(bubble.x, bubble.y, 8, Color{
						r: 34
						g: 211
						b: 238
					})
					break
				}
			}
		}

		if !collected && bubble.active {
			keep_bubbles << bubble
		}
	}
	ge.bubbles = keep_bubbles
}

fn (ge &GameEngine) update_single_enemy_ai(mut enemy Enemy, dt f64, sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mut sm := unsafe { &SoundManager(sound_mgr) }
	if !enemy.active {
		return
	}

	profile := get_rank_profile(enemy.rank)
	if enemy.flap_timer > 0 {
		enemy.flap_timer -= dt
	}
	if enemy.dive_cooldown > 0 {
		enemy.dive_cooldown -= dt
	}

	match enemy.state {
		.pumping {
			// Find closest player to check for incoming threat
			mut closest_dist := 999999.0
			mut p_dx := 0.0
			for p in mutable_ge.players {
				if p.state != .dead {
					dist_x := wrap_dx(enemy.motion.x, p.motion.x, mutable_ge.world_w)
					dist := math.hypot(dist_x, p.motion.y - enemy.motion.y)
					if dist < closest_dist {
						closest_dist = dist
						p_dx = dist_x
					}
				}
			}

			// Face threat
			if closest_dist < 200.0 {
				enemy.facing_right = p_dx > 0
			}

			// Threat detection & emergency takeoff
			if closest_dist < 110.0 {
				if enemy.balloons >= 1 {
					// Emergency Takeoff with 1 balloon!
					enemy.state = .flying
					enemy.motion.is_grounded = false
					apply_flap(mut enemy.motion, profile.flap_power * 1.1)
					enemy.motion.vx = if p_dx > 0 { -profile.max_vx * 0.7 } else { profile.max_vx * 0.7 }
					sm.play_flap()
					enemy.flap_timer = 0.2
					return
				} else {
					// Panic pumping! 2.5x pumping speed
					enemy.pump_timer -= dt * 1.5
				}
			}

			enemy.pump_timer -= dt
			if enemy.pump_timer <= 0 {
				enemy.balloons++
				if enemy.balloons >= 2 {
					enemy.state = .flying
					enemy.motion.is_grounded = false
					apply_flap(mut enemy.motion, profile.flap_power)
					sm.play_flap()
					enemy.flap_timer = 0.25
				} else {
					enemy.pump_timer = 1.1
				}
			}
		}
		.flying {
			enemy.wing_flap = false

			// 1. Water Danger Check (Top Priority)
			if enemy.motion.y > 420.0 || (enemy.motion.y > 380.0 && enemy.motion.vy > 60.0) {
				enemy.behavior = .panic_water
				if enemy.flap_timer <= 0 {
					apply_flap(mut enemy.motion, profile.flap_power * 1.18)
					enemy.flap_timer = 0.15
					enemy.wing_flap = true
				}
				// Evade Giant Fish if active
				if mutable_ge.fish.active {
					fish_dx := wrap_dx(enemy.motion.x, mutable_ge.fish.x, mutable_ge.world_w)
					if fish_dx > 0 {
						enemy.motion.vx -= profile.accel * dt
					} else {
						enemy.motion.vx += profile.accel * dt
					}
				}
			} else if enemy.motion.y < 40.0 {
				// 2. Ceiling Danger Check (Avoid hitting ceiling repeatedly)
				// Do not flap, let gravity lower the enemy naturally
				enemy.behavior = .patrol
			} else {
				// 3. Spark Avoidance
				mut spark_danger := false
				for spark in mutable_ge.sparks {
					s_dx := wrap_dx(enemy.motion.x, spark.x, mutable_ge.world_w)
					s_dist := math.hypot(s_dx, spark.y - enemy.motion.y)
					if s_dist < 70.0 {
						spark_danger = true
						if s_dx > 0 {
							enemy.motion.vx -= profile.accel * 1.3 * dt
						} else {
							enemy.motion.vx += profile.accel * 1.3 * dt
						}
						if spark.y > enemy.motion.y && enemy.flap_timer <= 0 {
							apply_flap(mut enemy.motion, profile.flap_power)
							enemy.flap_timer = 0.18
							enemy.wing_flap = true
						}
						break
					}
				}

				if !spark_danger {
					// 4. Target Player Selection
					mut closest_idx := -1
					mut min_dist := 999999.0
					for i in 0 .. mutable_ge.players.len {
						p := mutable_ge.players[i]
						if p.state != .dead && p.invincibility < 1.0 {
							dist_x := wrap_dx(enemy.motion.x, p.motion.x, mutable_ge.world_w)
							dist := math.hypot(dist_x, p.motion.y - enemy.motion.y)
							if dist < min_dist {
								min_dist = dist
								closest_idx = i
							}
						}
					}

					if closest_idx < 0 {
						// No target: peaceful patrol
						enemy.behavior = .patrol
						enemy.ai_timer += dt
						if enemy.ai_timer >= 1.2 {
							enemy.ai_timer = 0
							if rand.f64() < 0.6 {
								apply_flap(mut enemy.motion, profile.flap_power * 0.9)
								enemy.wing_flap = true
							}
							enemy.motion.vx = (rand.f64() * 160.0 - 80.0)
						}
					} else {
						closest_p := mutable_ge.players[closest_idx]
						// Lead player horizontal velocity according to rank prediction
						pred_px := closest_p.motion.x + (closest_p.motion.vx * profile.prediction_lead)
						dx := wrap_dx(enemy.motion.x, pred_px, mutable_ge.world_w)
						target_alt := math.max(45.0, closest_p.motion.y - profile.desired_alt)

						// Check if Player is ABOVE and diving to stomp enemy (Defensive Reflex)
						if closest_p.motion.y < enemy.motion.y - 4.0 && math.abs(dx) < 42.0 && closest_p.motion.vy > 10.0 {
							if rand.f64() < profile.dodge_reflex {
								enemy.behavior = .evade
								// Dart sideways out of player's vertical drop path
								dodge_dir := if dx >= 0 { -1.0 } else { 1.0 }
								enemy.motion.vx += dodge_dir * profile.accel * 1.6 * dt
								// If high rank, flap to contest height
								if profile.flap_power >= 215.0 && enemy.flap_timer <= 0 {
									apply_flap(mut enemy.motion, profile.flap_power)
									enemy.flap_timer = 0.16
									enemy.wing_flap = true
								}
							}
						} else if enemy.motion.y < closest_p.motion.y - 12.0 && math.abs(dx) < profile.dive_range_x && enemy.dive_cooldown <= 0 {
							// Enemy is ABOVE Player and aligned: DIVE ATTACK!
							enemy.behavior = .dive
							// Align with player
							if dx > 6.0 {
								enemy.motion.vx += profile.accel * 1.2 * dt
							} else if dx < -6.0 {
								enemy.motion.vx -= profile.accel * 1.2 * dt
							}
							// Fall onto player - no flap
						} else {
							// Contest Altitude / Climb to high ground
							enemy.behavior = .climb
							// Steer horizontally toward target
							if dx > 8.0 {
								enemy.motion.vx += profile.accel * dt
							} else if dx < -8.0 {
								enemy.motion.vx -= profile.accel * dt
							}

							// Flap if below target altitude
							if enemy.motion.y > target_alt && enemy.motion.vy > -90.0 && enemy.flap_timer <= 0 {
								apply_flap(mut enemy.motion, profile.flap_power)
								enemy.flap_timer = profile.reaction_time + (rand.f64() * 0.06)
								enemy.wing_flap = true
							}
						}
					}
				}
			}

			// Clamp horizontal speed
			enemy.motion.vx = math.clamp(enemy.motion.vx, -profile.max_vx, profile.max_vx)
			if enemy.motion.vx > 8.0 {
				enemy.facing_right = true
			} else if enemy.motion.vx < -8.0 {
				enemy.facing_right = false
			}

			update_motion(mut enemy.motion, dt, mutable_ge.world_w)
			update_platforms_collision(mut enemy.motion, enemy.w, enemy.h, mutable_ge.platforms)

			if enemy.motion.y >= mutable_ge.water_level {
				enemy.active = false
				sm.play_splash()
				mutable_ge.spawn_particles(enemy.motion.x, mutable_ge.water_level, 16, Color{ r: 34, g: 211, b: 238 })
				mutable_ge.spawn_bonus_bubble(enemy.motion.x, mutable_ge.water_level)
			}
		}
		.parachuting {
			enemy.behavior = .seek_platform
			enemy.motion.vy = 65.0

			// Smart parachute steering: seek closest platform below
			mut best_plat_x := -1.0
			mut min_dist := 999999.0
			for plat in mutable_ge.platforms {
				if plat.y >= enemy.motion.y - 12.0 {
					plat_center := plat.x + (plat.w / 2.0)
					p_dx := math.abs(wrap_dx(enemy.motion.x, plat_center, mutable_ge.world_w))
					if p_dx < min_dist {
						min_dist = p_dx
						best_plat_x = plat_center
					}
				}
			}

			if best_plat_x >= 0 {
				p_dx := wrap_dx(enemy.motion.x, best_plat_x, mutable_ge.world_w)
				if p_dx > 6.0 {
					enemy.motion.vx += 160.0 * dt
					enemy.facing_right = true
				} else if p_dx < -6.0 {
					enemy.motion.vx -= 160.0 * dt
					enemy.facing_right = false
				}
			}

			enemy.motion.vx = math.clamp(enemy.motion.vx, -90.0, 90.0)
			update_motion(mut enemy.motion, dt, mutable_ge.world_w)

			if update_platforms_collision(mut enemy.motion, enemy.w, enemy.h, mutable_ge.platforms) {
				enemy.state = .pumping
				enemy.balloons = 0
				enemy.pump_timer = 1.0
				enemy.motion.vx = 0
			}

			if enemy.motion.y >= mutable_ge.water_level {
				enemy.active = false
				sm.play_splash()
				mutable_ge.spawn_particles(enemy.motion.x, mutable_ge.water_level, 16, Color{ r: 34, g: 211, b: 238 })
				mutable_ge.spawn_bonus_bubble(enemy.motion.x, mutable_ge.water_level)
			}
		}
		else {}
	}
}

fn (ge &GameEngine) check_balloon_collisions(sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mut sm := unsafe { &SoundManager(sound_mgr) }

	for mut p in mutable_ge.players {
		if p.state != .flying && p.state != .parachuting {
			continue
		}

		for mut enemy in mutable_ge.enemies {
			if !enemy.active {
				continue
			}

			dx := math.abs(wrap_dx(p.motion.x, enemy.motion.x, mutable_ge.world_w))
			dy := math.abs(p.motion.y - enemy.motion.y)

			if dx <= 30.0 && dy <= 34.0 {
				enemy_color := match enemy.rank {
					.yellow { Color{ r: 250, g: 204, b: 21 } }
					.pink { Color{ r: 236, g: 72, b: 153 } }
					.red { Color{ r: 239, g: 68, b: 68 } }
				}

				if enemy.state == .pumping || enemy.state == .parachuting {
					// Defeat pumping or parachuting enemy by running into or stomping them!
					enemy.active = false
					sm.play_pickup()
					p.score += enemy.score_val
					mutable_ge.score += enemy.score_val
					if mutable_ge.score > mutable_ge.high_score {
						mutable_ge.high_score = mutable_ge.score
					}
					mutable_ge.spawn_particles(enemy.motion.x, enemy.motion.y, 14, enemy_color)
					mutable_ge.spawn_float_text(enemy.motion.x, enemy.motion.y - 12.0, '+${enemy.score_val}', Color{
						r: 250
						g: 204
						b: 21
					})
					mutable_ge.spawn_bonus_bubble(enemy.motion.x, enemy.motion.y)
					if p.motion.y < enemy.motion.y {
						p.motion.vy = -160.0
					}
				} else if p.motion.y < enemy.motion.y - 4.0 {
					// Player is ABOVE Enemy -> Player pops enemy balloon!
					p.motion.vy = -180.0 // Tactile upward bounce
					enemy.balloons--
					sm.play_balloon_pop()
					mutable_ge.shake_trauma = math.min(1.0, mutable_ge.shake_trauma + 0.32)
					mutable_ge.spawn_particles(enemy.motion.x, enemy.motion.y - 20.0, 10, enemy_color)
					mutable_ge.spawn_float_text(enemy.motion.x, enemy.motion.y - 15.0, '+250', Color{
						r: 248
						g: 250
						b: 252
					})
					mutable_ge.spawn_bonus_bubble(enemy.motion.x, enemy.motion.y - 10.0)
					if enemy.balloons <= 0 {
						enemy.state = .parachuting
					}
				} else if enemy.motion.y < p.motion.y - 4.0 && p.invincibility <= 0 {
					// Enemy is ABOVE Player -> Enemy pops player balloon!
					if p.state == .flying {
						p.balloons--
						p.invincibility = 0.6 // Invincibility frame window to avoid losing all balloons in 1 frame
						p.motion.vy = 120.0
						sm.play_balloon_pop()
						mutable_ge.shake_trauma = math.min(1.0, mutable_ge.shake_trauma + 0.45)
						mutable_ge.spawn_particles(p.motion.x, p.motion.y - 20.0, 10, Color{ r: 239, g: 68, b: 68 })
						if p.balloons <= 0 {
							// Lost both balloons -> Immediately lose life and respawn/game over!
							p.lives--
							if p.lives <= 0 {
								p.state = .dead
								mutable_ge.state = .game_over
							} else {
								p.motion.x = 400.0
								p.motion.y = 200.0
								p.motion.vx = 0
								p.motion.vy = 0
								p.balloons = 2
								p.state = .flying
								p.invincibility = 2.5
							}
						}
					}
				}
			}
		}
	}
}

fn (ge &GameEngine) update_giant_fish(dt f64, sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mut sm := unsafe { &SoundManager(sound_mgr) }

	if !mutable_ge.fish.active {
		mutable_ge.fish.cooldown += dt
		if mutable_ge.fish.cooldown >= 3.0 {
			for p in mutable_ge.players {
				if p.state == .flying && p.motion.y > 460.0 && p.motion.y < mutable_ge.water_level {
					mutable_ge.fish.active = true
					mutable_ge.fish.state = 1
					mutable_ge.fish.x = p.motion.x
					mutable_ge.fish.y = 560.0
					mutable_ge.fish.vy = -350.0
					mutable_ge.fish.cooldown = 0
					sm.play_fish_gulp()
					break
				}
			}
		}
	} else {
		mutable_ge.fish.y += mutable_ge.fish.vy * dt
		if mutable_ge.fish.state == 1 && mutable_ge.fish.y <= 430.0 {
			mutable_ge.fish.state = 2
			mutable_ge.fish.vy = 280.0
		} else if mutable_ge.fish.state == 2 && mutable_ge.fish.y >= 560.0 {
			mutable_ge.fish.active = false
			mutable_ge.fish.state = 0
		}

		for mut p in mutable_ge.players {
			if p.state != .dead && p.invincibility <= 0 {
				dist := math.hypot(p.motion.x - mutable_ge.fish.x, p.motion.y - mutable_ge.fish.y)
				if dist <= 35.0 {
					p.state = .dead
					p.lives--
					sm.play_fish_gulp()
					mutable_ge.spawn_particles(mutable_ge.fish.x, mutable_ge.fish.y, 16, Color{ r: 234, g: 179, b: 8 })
					mutable_ge.spawn_float_text(mutable_ge.fish.x, mutable_ge.fish.y - 20.0, 'CHOMP!', Color{ r: 239, g: 68, b: 68 })
					if p.lives <= 0 {
						mutable_ge.state = .game_over
					}
				}
			}
		}

		for mut enemy in mutable_ge.enemies {
			if enemy.active {
				dist := math.hypot(enemy.motion.x - mutable_ge.fish.x, enemy.motion.y - mutable_ge.fish.y)
				if dist <= 35.0 {
					enemy.active = false
					sm.play_fish_gulp()
					mutable_ge.spawn_particles(mutable_ge.fish.x, mutable_ge.fish.y, 16, Color{ r: 234, g: 179, b: 8 })
					mutable_ge.spawn_float_text(mutable_ge.fish.x, mutable_ge.fish.y - 20.0, 'CHOMP!', Color{ r: 239, g: 68, b: 68 })
				}
			}
		}
	}
}

fn (ge &GameEngine) update_balloon_trip_mode(dt f64, left bool, right bool, flap bool, sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mut sm := unsafe { &SoundManager(sound_mgr) }
	mutable_ge.trip_scroll_x += 120.0 * dt

	mut p := unsafe { &Player(&mutable_ge.players[0]) }

	if left {
		p.motion.vx -= 180.0 * dt
	}
	if right {
		p.motion.vx += 180.0 * dt
	}
	if flap && p.flap_cooldown <= 0 {
		p.flap_cooldown = 0.18
		apply_flap(mut p.motion, 180.0)
		sm.play_flap()
	}
	if p.flap_cooldown > 0 {
		p.flap_cooldown -= dt
	}

	update_motion(mut p.motion, dt, mutable_ge.world_w)

	for mut tb in mutable_ge.trip_balloons {
		if !tb.collected {
			screen_x := tb.x - mutable_ge.trip_scroll_x
			if screen_x > -20.0 && screen_x < 820.0 {
				dist := math.hypot(p.motion.x - screen_x, p.motion.y - tb.y)
				if dist <= 22.0 {
					tb.collected = true
					p.score += tb.value
					mutable_ge.score += tb.value
					sm.play_pickup()
				}
			}
		}
	}

	for spark in mutable_ge.sparks {
		screen_x := spark.x - mutable_ge.trip_scroll_x
		if screen_x > -20.0 && screen_x < 820.0 {
			dist := math.hypot(p.motion.x - screen_x, p.motion.y - spark.y)
			if dist <= 20.0 {
				p.state = .dead
				mutable_ge.state = .game_over
				sm.play_spark_zap()
			}
		}
	}
}
