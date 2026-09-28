module main

import math
import rand

pub enum GameMode {
	free_ski
	slalom
	tree_slalom
	yeti_survival
}

pub enum SkierPose {
	stopped
	turn_hard_left
	turn_left
	turn_diag_left
	ski_straight
	turn_diag_right
	turn_right
	turn_hard_right
	tuck_fast
	airborne
	trick_daffy
	trick_spin
	trick_backflip
	trick_spread
	crashed
	eaten
}

pub enum ObstacleType {
	small_tree
	large_pine
	tree_stump
	rock
	snow_mogul
	jump_ramp
	slalom_blue
	slalom_red
	dog
	snowboarder
	lift_pole
}

pub struct Obstacle {
pub mut:
	x      f64
	y      f64
	kind   ObstacleType
	w      int
	h      int
	passed bool
	vx     f64 // for moving npcs like snowboarder or dog
	anim_f int
}

pub struct SnowParticle {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	max_l f64
	size  int
}

pub struct SkiTrack {
pub mut:
	x1 f64
	y1 f64
	x2 f64
	y2 f64
}

pub struct Yeti {
pub mut:
	active   bool
	x        f64
	y        f64
	vx       f64
	vy       f64
	speed    f64 = 360.0
	state    int // 0: running, 1: grabbing, 2: eating
	eat_time f64
	anim_t   f64
	frame    int
}

pub struct SkiGame {
pub mut:
	mode          GameMode = .free_ski
	// Skier State
	x             f64 = 0.0
	y             f64 = 0.0
	vx            f64
	vy            f64
	pose          SkierPose = .stopped
	crash_timer   f64
	air_time      f64
	altitude      f64
	trick_count   int
	trick_points  int
	spin_angle    f64

	// World & Generation
	obstacles     []Obstacle
	last_gen_y    f64
	tracks        []SkiTrack
	particles     []SnowParticle

	// Yeti Boss
	yeti          Yeti

	// Scoring & Game Stats
	score         int
	distance_m    int
	max_speed     f64
	time_elapsed  f64
	slalom_gates_passed int
	slalom_gates_total  int
	slalom_penalty      int
	is_game_over  bool
	banner_text   string
	banner_timer  f64

	// Audio notification triggers
	sound_event   string
}

pub fn new_ski_game() SkiGame {
	mut g := SkiGame{}
	g.reset_game()
	return g
}

pub fn (mut g SkiGame) reset_game() {
	g.x = 0.0
	g.y = 0.0
	g.vx = 0.0
	g.vy = 0.0
	g.pose = .stopped
	g.crash_timer = 0.0
	g.air_time = 0.0
	g.altitude = 0.0
	g.trick_count = 0
	g.trick_points = 0
	g.spin_angle = 0.0

	g.obstacles.clear()
	g.tracks.clear()
	g.particles.clear()
	g.last_gen_y = 0.0

	g.yeti = Yeti{
		active: g.mode == .yeti_survival
		x: 0.0
		y: if g.mode == .yeti_survival { -400.0 } else { 0.0 }
	}

	g.score = 0
	g.distance_m = 0
	g.max_speed = 0.0
	g.time_elapsed = 0.0
	g.slalom_gates_passed = 0
	g.slalom_gates_total = 0
	g.slalom_penalty = 0
	g.is_game_over = false
	g.banner_text = 'PRESS DOWN OR SPACE TO SKI!'
	g.banner_timer = 3.0
	g.sound_event = ''

	// Seed starting mountain terrain
	g.generate_terrain_ahead(1500.0)
}

pub fn (mut g SkiGame) steer_left() {
	if g.pose == .crashed || g.pose == .eaten {
		return
	}
	if g.pose == .airborne || g.is_trick_pose(g.pose) {
		g.pose = .trick_daffy
		g.trick_count++
		g.trick_points += 250
		g.sound_event = 'trick'
		return
	}

	g.pose = match g.pose {
		.stopped { SkierPose.turn_diag_left }
		.turn_hard_right { SkierPose.turn_right }
		.turn_right { SkierPose.turn_diag_right }
		.turn_diag_right { SkierPose.ski_straight }
		.ski_straight { SkierPose.turn_diag_left }
		.tuck_fast { SkierPose.turn_diag_left }
		.turn_diag_left { SkierPose.turn_left }
		.turn_left { SkierPose.turn_hard_left }
		.turn_hard_left { SkierPose.turn_hard_left }
		else { SkierPose.turn_diag_left }
	}
}

pub fn (mut g SkiGame) steer_right() {
	if g.pose == .crashed || g.pose == .eaten {
		return
	}
	if g.pose == .airborne || g.is_trick_pose(g.pose) {
		g.pose = .trick_spin
		g.trick_count++
		g.trick_points += 300
		g.sound_event = 'trick'
		return
	}

	g.pose = match g.pose {
		.stopped { SkierPose.turn_diag_right }
		.turn_hard_left { SkierPose.turn_left }
		.turn_left { SkierPose.turn_diag_left }
		.turn_diag_left { SkierPose.ski_straight }
		.ski_straight { SkierPose.turn_diag_right }
		.tuck_fast { SkierPose.turn_diag_right }
		.turn_diag_right { SkierPose.turn_right }
		.turn_right { SkierPose.turn_hard_right }
		.turn_hard_right { SkierPose.turn_hard_right }
		else { SkierPose.turn_diag_right }
	}
}

pub fn (mut g SkiGame) steer_down() {
	if g.pose == .crashed || g.pose == .eaten {
		return
	}
	if g.pose == .airborne || g.is_trick_pose(g.pose) {
		g.pose = .trick_spread
		g.trick_count++
		g.trick_points += 200
		g.sound_event = 'trick'
		return
	}
	if g.pose == .ski_straight {
		g.pose = .tuck_fast
	} else {
		g.pose = .ski_straight
	}
}

pub fn (mut g SkiGame) steer_up() {
	if g.pose == .crashed || g.pose == .eaten {
		return
	}
	if g.pose == .airborne || g.is_trick_pose(g.pose) {
		g.pose = .trick_backflip
		g.trick_count++
		g.trick_points += 500
		g.sound_event = 'trick'
		return
	}
	// Braking or turning uphill to stop
	if g.pose == .tuck_fast {
		g.pose = .ski_straight
	} else if g.pose == .ski_straight {
		g.pose = .turn_diag_left
	} else {
		g.pose = .stopped
		g.vx = 0
		g.vy = 0
	}
}

pub fn (mut g SkiGame) is_trick_pose(p SkierPose) bool {
	return p == .trick_daffy || p == .trick_spin || p == .trick_backflip || p == .trick_spread
}

pub fn (mut g SkiGame) update(dt f64) {
	g.sound_event = ''
	g.time_elapsed += dt
	if g.banner_timer > 0.0 {
		g.banner_timer -= dt
	}

	// 1. Crash Recovery
	if g.pose == .crashed {
		g.crash_timer -= dt
		g.vx *= 0.85
		g.vy *= 0.85
		g.x += g.vx * dt
		g.y += g.vy * dt
		if g.crash_timer <= 0.0 {
			g.pose = .stopped
			g.banner_text = 'RECOVERED! GO!'
			g.banner_timer = 1.5
		}
		g.update_particles(dt)
		return
	}

	// 2. Skier Physics and Velocity Targets
	target_vx := match g.pose {
		.stopped { 0.0 }
		.turn_hard_left { -280.0 }
		.turn_left { -190.0 }
		.turn_diag_left { -120.0 }
		.ski_straight { 0.0 }
		.turn_diag_right { 120.0 }
		.turn_right { 190.0 }
		.turn_hard_right { 280.0 }
		.tuck_fast { 0.0 }
		else { g.vx }
	}

	target_vy := match g.pose {
		.stopped { 0.0 }
		.turn_hard_left { 20.0 }
		.turn_left { 90.0 }
		.turn_diag_left { 200.0 }
		.ski_straight { 320.0 }
		.turn_diag_right { 200.0 }
		.turn_right { 90.0 }
		.turn_hard_right { 20.0 }
		.tuck_fast { 480.0 }
		else { g.vy }
	}

	if g.pose != .airborne && !g.is_trick_pose(g.pose) && g.pose != .eaten {
		g.vx += (target_vx - g.vx) * 8.0 * dt
		g.vy += (target_vy - g.vy) * 8.0 * dt
	}

	// 3. Airborne & Jump Physics
	if g.pose == .airborne || g.is_trick_pose(g.pose) {
		g.air_time += dt
		g.altitude = math.sin(g.air_time * math.pi / 0.8) * 36.0

		if g.pose == .trick_spin {
			g.spin_angle += 720.0 * dt
		}

		if g.air_time >= 0.8 || g.altitude <= 0.0 {
			// Landed!
			g.altitude = 0.0
			g.air_time = 0.0
			if g.is_trick_pose(g.pose) {
				g.score += g.trick_points
				g.banner_text = 'TRICK LANDED! +${g.trick_points} PTS'
				g.banner_timer = 2.0
				g.sound_event = 'trick'
				g.spawn_snow_puff(g.x, g.y, 14)
			}
			g.pose = .ski_straight
			g.trick_points = 0
		}
	}

	// Update Position
	old_x := g.x
	old_y := g.y
	g.x += g.vx * dt
	g.y += g.vy * dt

	speed := math.sqrt(g.vx * g.vx + g.vy * g.vy)
	if speed > g.max_speed {
		g.max_speed = speed
	}
	g.distance_m = int(g.y / 10.0)

	// Add ski track
	if g.pose != .stopped && g.pose != .crashed && g.altitude <= 2.0 && g.pose != .eaten {
		g.tracks << SkiTrack{
			x1: old_x
			y1: old_y
			x2: g.x
			y2: g.y
		}
		if g.tracks.len > 120 {
			g.tracks.delete(0)
		}
	}

	// 4. Obstacle Collision & Gate Detection
	g.check_obstacle_collisions()

	// 5. Yeti AI (The Monster!)
	g.update_yeti(dt)

	// 6. Terrain Generation Ahead
	if g.y + 1200.0 > g.last_gen_y {
		g.generate_terrain_ahead(1000.0)
	}

	// 7. Cleanup Far Obstacles
	g.cleanup_obstacles()

	// 8. Update Particles
	g.update_particles(dt)
}

fn (mut g SkiGame) check_obstacle_collisions() {
	if g.pose == .crashed || g.pose == .eaten {
		return
	}

	skier_box_w := 14.0
	skier_box_h := 14.0

	for mut ob in g.obstacles {
		// Update moving NPCs
		if ob.kind == .snowboarder || ob.kind == .dog {
			ob.x += ob.vx * 0.016
			if ob.x < g.x - 400.0 { ob.vx = math.abs(ob.vx) }
			if ob.x > g.x + 400.0 { ob.vx = -math.abs(ob.vx) }
		}

		// Check slalom gate passing
		if (ob.kind == .slalom_blue || ob.kind == .slalom_red) && !ob.passed {
			if g.y >= ob.y {
				ob.passed = true
				g.slalom_gates_total++
				if (ob.kind == .slalom_blue && g.x < ob.x) || (ob.kind == .slalom_red && g.x > ob.x) {
					g.slalom_gates_passed++
					g.score += 500
					g.sound_event = 'gate'
					g.banner_text = 'GATE PASS! +500'
					g.banner_timer = 1.0
				} else {
					g.slalom_penalty += 5
					g.banner_text = 'MISSED GATE! +5s PENALTY'
					g.banner_timer = 1.5
				}
			}
			continue
		}

		// Altitude jump evasion
		if g.altitude > 12.0 && ob.kind != .large_pine && ob.kind != .lift_pole {
			continue
		}

		// AABB Collision
		dx := math.abs(g.x - ob.x)
		dy := math.abs(g.y - ob.y)

		if dx < (skier_box_w + f64(ob.w)) / 2.0 && dy < (skier_box_h + f64(ob.h)) / 2.0 {
			match ob.kind {
				.snow_mogul {
					// Hop into air
					if g.pose != .airborne && !g.is_trick_pose(g.pose) {
						g.pose = .airborne
						g.air_time = 0.0
						g.sound_event = 'jump'
						g.spawn_snow_puff(g.x, g.y, 6)
					}
				}
				.jump_ramp {
					// Big Air Ramp Launch!
					g.pose = .airborne
					g.air_time = 0.0
					g.vy = math.max(g.vy, 420.0)
					g.sound_event = 'jump'
					g.banner_text = 'BIG AIR! PRESS ARROWS FOR TRICKS!'
					g.banner_timer = 2.0
					g.spawn_snow_puff(g.x, g.y, 16)
				}
				.dog {
					// Bark & wipeout
					g.trigger_crash()
				}
				else {
					// Tree, Rock, Stump, Lift pole crash!
					g.trigger_crash()
				}
			}
		}
	}
}

fn (mut g SkiGame) trigger_crash() {
	g.pose = .crashed
	g.crash_timer = 1.6
	g.sound_event = 'crash'
	g.banner_text = 'WIPEOUT! OUCH!'
	g.banner_timer = 2.0
	g.altitude = 0.0
	g.spawn_snow_puff(g.x, g.y, 25)
}

fn (mut g SkiGame) update_yeti(dt f64) {
	// Yeti spawns at 2000m (y=20000) or mode is survival
	if !g.yeti.active {
		if g.y >= 20000.0 || g.y <= -2000.0 {
			g.yeti.active = true
			g.yeti.x = g.x + (rand.f64() * 200.0 - 100.0)
			g.yeti.y = g.y - 350.0
			g.sound_event = 'yeti_roar'
			g.banner_text = 'WARNING: ABOMINABLE SNOW MONSTER SPAWNED!'
			g.banner_timer = 3.0
		}
		return
	}

	// Yeti hunting behavior
	g.yeti.anim_t += dt
	if g.yeti.anim_t >= 0.15 {
		g.yeti.anim_t = 0
		g.yeti.frame = (g.yeti.frame + 1) % 2
	}

	dx := g.x - g.yeti.x
	dy := g.y - g.yeti.y
	dist := math.sqrt(dx * dx + dy * dy)

	if g.yeti.state == 0 {
		// Running chase
		if dist > 8.0 {
			g.yeti.x += (dx / dist) * g.yeti.speed * dt
			g.yeti.y += (dy / dist) * g.yeti.speed * dt
		}

		if dist < 22.0 {
			// Grabbed player!
			g.yeti.state = 1
			g.pose = .eaten
			g.sound_event = 'yeti_crunch'
			g.banner_text = 'NOM NOM NOM! EATEN BY YETI!'
			g.banner_timer = 5.0
			g.is_game_over = true
		}
	} else if g.yeti.state == 1 {
		g.yeti.eat_time += dt
		if g.yeti.eat_time > 1.2 {
			g.yeti.state = 2 // Pick teeth satisfaction
		}
	}
}

fn (mut g SkiGame) generate_terrain_ahead(length f64) {
	start_y := g.last_gen_y
	end_y := start_y + length
	g.last_gen_y = end_y

	step := if g.mode == .tree_slalom { 45.0 } else { 70.0 }
	mut cur_y := start_y + 80.0

	for cur_y < end_y {
		// Slalom Gates Mode Generation
		if g.mode == .slalom {
			if int(cur_y) % 240 < int(step) {
				gate_x := (rand.f64() * 2.0 - 1.0) * 140.0
				is_blue := (int(cur_y / 240.0) % 2 == 0)
				g.obstacles << Obstacle{
					x: gate_x
					y: cur_y
					kind: if is_blue { ObstacleType.slalom_blue } else { ObstacleType.slalom_red }
					w: 28
					h: 16
				}
			}
		}

		// Spawn density
		items := 2 + rand.int_in_range(0, 3) or { 1 }
		for _ in 0 .. items {
			ox := (rand.f64() * 2.0 - 1.0) * 550.0
			oy := cur_y + (rand.f64() * step)

			kind_roll := rand.int_in_range(0, 100) or { 0 }
			mut kind := ObstacleType.small_tree
			mut w := 16
			mut h := 16

			if kind_roll < 45 {
				kind = .large_pine
				w = 24
				h = 32
			} else if kind_roll < 65 {
				kind = .small_tree
				w = 14
				h = 18
			} else if kind_roll < 78 {
				kind = .rock
				w = 16
				h = 10
			} else if kind_roll < 86 {
				kind = .tree_stump
				w = 12
				h = 10
			} else if kind_roll < 92 {
				kind = .snow_mogul
				w = 20
				h = 8
			} else if kind_roll < 97 {
				kind = .jump_ramp
				w = 26
				h = 12
			} else {
				kind = .dog
				w = 14
				h = 10
			}

			g.obstacles << Obstacle{
				x: ox
				y: oy
				kind: kind
				w: w
				h: h
				vx: if kind == .dog { 40.0 } else { 0.0 }
			}
		}
		cur_y += step
	}
}

fn (mut g SkiGame) cleanup_obstacles() {
	min_y := g.y - 500.0
	for i := g.obstacles.len - 1; i >= 0; i-- {
		if g.obstacles[i].y < min_y {
			g.obstacles.delete(i)
		}
	}
}

fn (mut g SkiGame) spawn_snow_puff(x f64, y f64, count int) {
	for _ in 0 .. count {
		g.particles << SnowParticle{
			x: x + (rand.f64() * 10.0 - 5.0)
			y: y + (rand.f64() * 10.0 - 5.0)
			vx: (rand.f64() * 2.0 - 1.0) * 90.0
			vy: (rand.f64() * 2.0 - 1.0) * 70.0
			life: 0.0
			max_l: 0.3 + rand.f64() * 0.3
			size: 2 + rand.int_in_range(0, 3) or { 1 }
		}
	}
}

fn (mut g SkiGame) update_particles(dt f64) {
	for i := g.particles.len - 1; i >= 0; i-- {
		mut p := g.particles[i]
		p.life += dt
		p.x += p.vx * dt
		p.y += p.vy * dt
		if p.life >= p.max_l {
			g.particles.delete(i)
		} else {
			g.particles[i] = p
		}
	}
}
