module main

import math
import rand

pub const track_cols = 30
pub const track_rows = 22
pub const track_tile_size = 32
pub const total_laps = 3

pub enum TrackTileType {
	offroad = 0
	asphalt = 1
	start_finish = 2
	turbo_pad = 3
	oil_slick = 4
	barrier = 5
}

pub struct CheckpointGate {
pub mut:
	id   int
	x    f64
	y    f64
	w    f64
	h    f64
}

pub struct Car {
pub mut:
	id                 int
	is_ai              bool
	x                  f64
	y                  f64
	heading            f64 // Radians
	speed              f64
	max_speed          f64 = 340.0
	acceleration       f64 = 380.0
	friction           f64 = 0.98
	steering           f64
	drift_factor       f64
	is_drifting        bool
	is_spinning        bool
	spin_timer         f64
	spin_cooldown      f64
	boost_timer        f64
	current_checkpoint int
	checkpoints_passed int
	lap                int = 1
	lap_time           f64
	best_lap           f64 = 999.0
	finished           bool
	total_time         f64
	color_r            u8  = 50
	color_g            u8  = 200
	color_b            u8  = 255
	target_waypoint    int
}

pub struct Waypoint {
pub mut:
	x f64
	y f64
}

pub struct Particle {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	r        u8
	g        u8
	b        u8
	life     f64
	max_life f64
	size     f64
}

pub struct SkidMark {
pub mut:
	x    f64
	y    f64
	life f64 = 3.0
}

pub struct RacerGame {
pub mut:
	track_tiles        [][]TrackTileType
	checkpoints        []CheckpointGate
	waypoints          []Waypoint
	player             Car
	ai_cars            []Car
	skid_marks         []SkidMark
	particles          []Particle
	countdown          f64 = 3.0
	race_started       bool
	race_finished      bool
	race_time          f64
	sound_event_engine bool
	sound_event_skid   bool
	sound_event_crash  bool
	sound_event_boost  bool
	sound_event_gate   bool
}

pub fn new_racer_game() RacerGame {
	mut game := RacerGame{}
	game.build_cyber_track()
	return game
}

pub fn (mut game RacerGame) build_cyber_track() {
	game.track_tiles = [][]TrackTileType{len: track_rows, init: []TrackTileType{len: track_cols, init: .offroad}}

	// Outer track loop layout (circuit curve)
	for r in 2 .. track_rows - 2 {
		for c in 2 .. track_cols - 2 {
			// Inner hole (creating race track loop)
			if r >= 6 && r <= track_rows - 7 && c >= 6 && c <= track_cols - 7 {
				game.track_tiles[r][c] = .offroad
			} else {
				game.track_tiles[r][c] = .asphalt
			}
		}
	}

	// Start / Finish Line spanning full track width at row 17 (cols 2..5)
	for c in 2 .. 6 {
		game.track_tiles[17][c] = .start_finish
	}

	// Turbo Pads & Oil Slicks
	game.track_tiles[3][14] = .turbo_pad
	game.track_tiles[18][22] = .turbo_pad
	game.track_tiles[4][22] = .oil_slick
	game.track_tiles[18][13] = .oil_slick

	// Checkpoint Gates spanning the full width/height of asphalt lanes
	// CP0: Start/Finish line (cols 2..5, row 17) -> width 128, height 32
	// CP1: Top straight (col 14, rows 2..5) -> width 32, height 128
	// CP2: Right straight (cols 24..27, row 10) -> width 128, height 32
	// CP3: Bottom straight (col 15, rows 16..19) -> width 32, height 128
	game.checkpoints = [
		CheckpointGate{ id: 0, x: 2 * track_tile_size, y: 17 * track_tile_size, w: 4 * track_tile_size, h: 32 },
		CheckpointGate{ id: 1, x: 14 * track_tile_size, y: 2 * track_tile_size, w: 32, h: 4 * track_tile_size },
		CheckpointGate{ id: 2, x: 24 * track_tile_size, y: 10 * track_tile_size, w: 4 * track_tile_size, h: 32 },
		CheckpointGate{ id: 3, x: 15 * track_tile_size, y: 16 * track_tile_size, w: 32, h: 4 * track_tile_size },
	]

	// Waypoints for AI racers - centered in asphalt lanes (128 = col center, 576/128 = row center)
	game.waypoints = [
		Waypoint{ x: 128, y: 352 }, // W0: Mid left straight
		Waypoint{ x: 128, y: 128 }, // W1: Top-left corner
		Waypoint{ x: 480, y: 128 }, // W2: Mid top straight
		Waypoint{ x: 832, y: 128 }, // W3: Top-right corner
		Waypoint{ x: 832, y: 352 }, // W4: Mid right straight
		Waypoint{ x: 832, y: 576 }, // W5: Bottom-right corner
		Waypoint{ x: 480, y: 576 }, // W6: Mid bottom straight
		Waypoint{ x: 128, y: 576 }, // W7: Bottom-left corner
	]

	// Initialize Player Car (Grid position near start line, facing North)
	game.player = Car{
		id: 0
		is_ai: false
		x: 112.0 // col 3.5
		y: 592.0 // row 18.5 (just behind start line at row 17)
		heading: -math.pi / 2.0 // Facing north up the track
		color_r: 50, color_g: 220, color_b: 255
	}

	// Initialize AI Cars
	game.ai_cars = [
		Car{
			id: 1, is_ai: true, x: 80.0, y: 592.0, heading: -math.pi / 2.0
			color_r: 255, color_g: 60, color_b: 100, max_speed: 310
		},
		Car{
			id: 2, is_ai: true, x: 144.0, y: 624.0, heading: -math.pi / 2.0
			color_r: 255, color_g: 215, color_b: 0, max_speed: 325
		},
		Car{
			id: 3, is_ai: true, x: 80.0, y: 624.0, heading: -math.pi / 2.0
			color_r: 100, color_g: 255, color_b: 100, max_speed: 300
		},
	]
}

pub fn (mut game RacerGame) update(dt f64, input_accel bool, input_brake bool, input_left bool, input_right bool, input_handbrake bool) {
	// Sound flags reset
	game.sound_event_engine = false
	game.sound_event_skid = false
	game.sound_event_crash = false
	game.sound_event_boost = false
	game.sound_event_gate = false

	if game.countdown > 0 {
		game.countdown -= dt
		if game.countdown <= 0 {
			game.race_started = true
		} else {
			return
		}
	}

	if game.race_started && !game.race_finished {
		game.race_time += dt
	}

	// Update Player Car Physics
	game.update_car(mut game.player, dt, input_accel, input_brake, input_left, input_right, input_handbrake)

	// Update AI Cars
	for mut ai in game.ai_cars {
		game.update_ai_car(mut ai, dt)
	}

	// Update Skid Marks & Particles
	for mut s in game.skid_marks {
		s.life -= dt
	}
	game.skid_marks = game.skid_marks.filter(it.life > 0)

	for mut p in game.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.life -= dt
	}
	game.particles = game.particles.filter(it.life > 0)
}

pub fn (mut game RacerGame) update_car(mut car Car, dt f64, accel bool, brake bool, left bool, right bool, handbrake bool) {
	if car.finished { return }

	car.lap_time += dt

	if car.spin_cooldown > 0 {
		car.spin_cooldown -= dt
	}

	if car.spin_timer > 0 {
		car.spin_timer -= dt
		car.heading += 12.0 * dt
		car.speed *= 0.96
		if car.spin_timer <= 0 {
			car.is_spinning = false
			car.spin_cooldown = 1.5
		}
		vx := math.cos(car.heading) * car.speed
		vy := math.sin(car.heading) * car.speed
		car.x += vx * dt
		car.y += vy * dt
		car.x = math.clamp(car.x, 16.0, f64(track_cols * track_tile_size - 16))
		car.y = math.clamp(car.y, 16.0, f64(track_rows * track_tile_size - 16))
		return
	}

	// Surface tile detection
	tx := int(car.x / track_tile_size)
	ty := int(car.y / track_tile_size)
	mut current_surface := TrackTileType.offroad
	if tx >= 0 && tx < track_cols && ty >= 0 && ty < track_rows {
		current_surface = game.track_tiles[ty][tx]
	}

	// Surface Speed & Friction modifiers
	mut max_sp := car.max_speed
	mut friction_rate := car.friction

	if current_surface == .offroad {
		max_sp *= 0.4
		friction_rate = 0.92
	} else if current_surface == .turbo_pad {
		car.boost_timer = 1.0
		game.sound_event_boost = true
	} else if current_surface == .oil_slick && car.spin_timer <= 0 && car.spin_cooldown <= 0 {
		car.is_spinning = true
		car.spin_timer = 0.8
		game.sound_event_crash = true
	}

	if car.boost_timer > 0 {
		car.boost_timer -= dt
		max_sp *= 1.4
	}

	// Engine Throttle & Braking
	if accel {
		car.speed += car.acceleration * dt
		game.sound_event_engine = true
	} else if brake {
		car.speed -= car.acceleration * 1.2 * dt
	} else {
		car.speed *= friction_rate
	}

	car.speed = math.clamp(car.speed, -max_sp * 0.4, max_sp)

	// Steering Geometry
	steering_sensitivity := 2.5
	if left { car.heading -= steering_sensitivity * (car.speed / max_sp) * dt }
	if right { car.heading += steering_sensitivity * (car.speed / max_sp) * dt }

	// Drift Mechanic
	if handbrake && math.abs(car.speed) > 100 {
		car.is_drifting = true
		car.drift_factor = math.min(1.0, car.drift_factor + dt * 3.0)
		game.sound_event_skid = true

		// Spawn tire smoke & skid marks
		game.skid_marks << SkidMark{ x: car.x, y: car.y }
		game.particles << Particle{
			x: car.x + (rand.f64() - 0.5) * 10
			y: car.y + (rand.f64() - 0.5) * 10
			vx: (rand.f64() - 0.5) * 30
			vy: (rand.f64() - 0.5) * 30
			r: 220, g: 220, b: 230
			life: 0.4, max_life: 0.4
			size: 6
		}
	} else {
		car.is_drifting = false
		car.drift_factor = math.max(0.0, car.drift_factor - dt * 4.0)
	}

	// Velocity vector from heading + drift angle
	vx := math.cos(car.heading) * car.speed
	vy := math.sin(car.heading) * car.speed

	car.x += vx * dt
	car.y += vy * dt

	// World boundary collision
	car.x = math.clamp(car.x, 16.0, f64(track_cols * track_tile_size - 16))
	car.y = math.clamp(car.y, 16.0, f64(track_rows * track_tile_size - 16))

	// Checkpoint Gates Verification
	next_cp := (car.current_checkpoint + 1) % game.checkpoints.len
	cp := game.checkpoints[next_cp]

	if car.x >= cp.x && car.x <= cp.x + cp.w && car.y >= cp.y && car.y <= cp.y + cp.h {
		car.current_checkpoint = next_cp
		car.checkpoints_passed++
		game.sound_event_gate = true

		// Check full lap completion at finish line gate
		if next_cp == 0 {
			if car.lap_time < car.best_lap {
				car.best_lap = car.lap_time
			}
			car.lap_time = 0
			car.lap++
			if car.lap > total_laps {
				car.finished = true
				car.total_time = game.race_time
				if !car.is_ai {
					game.race_finished = true
				}
			}
		}
	}
}

pub fn (mut game RacerGame) update_ai_car(mut car Car, dt f64) {
	if car.finished { return }

	target := game.waypoints[car.target_waypoint]
	dx := target.x - car.x
	dy := target.y - car.y
	dist := math.sqrt(dx * dx + dy * dy)

	if dist < 40.0 {
		car.target_waypoint = (car.target_waypoint + 1) % game.waypoints.len
	}

	desired_heading := math.atan2(dy, dx)
	mut diff := desired_heading - car.heading
	for diff > math.pi { diff -= 2.0 * math.pi }
	for diff < -math.pi { diff += 2.0 * math.pi }

	mut left := false
	mut right := false
	if diff < -0.1 { left = true }
	if diff > 0.1 { right = true }

	handbrake := math.abs(diff) > 0.8
	game.update_car(mut car, dt, true, false, left, right, handbrake)
}

