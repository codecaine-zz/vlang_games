module main

import math
import rand

enum GameState {
	menu
	playing
	paused
	touchdown
	crashed
	game_over
}

struct TerrainPoint {
	x f32
	y f32
}

struct LandingPad {
	start_x    f32
	end_x      f32
	y          f32
	multiplier int
}

struct Particle {
mut:
	x       f32
	y       f32
	vx      f32
	vy      f32
	life    f32
	max_life f32
	color   Color
}

struct LunarLanderGame {
mut:
	state          GameState = .menu
	score          int
	high_score     int = 5000
	stage          int = 1
	lives          int = 3
	x              f32 = 100.0
	y              f32 = 80.0
	vx             f32
	vy             f32
	angle          f32 // Radians (0 = upright facing up)
	fuel           f32 = 100.0
	max_fuel       f32 = 100.0
	gravity        f32 = 45.0
	main_thrust    f32 = 120.0
	rcs_torque     f32 = 2.2
	terrain_points []TerrainPoint
	pads           []LandingPad
	particles      []Particle
	sound_mgr      SoundManager
	key_thrust     bool
	key_rot_left   bool
	key_rot_right  bool
	touchdown_pts  int
	touchdown_msg  string
	shake_trauma   f32
}

fn new_lunarlander_game() LunarLanderGame {
	mut g := LunarLanderGame{
		sound_mgr: new_sound_manager()
	}
	g.reset_game()
	return g
}

fn (mut g LunarLanderGame) reset_game() {
	g.score = 0
	g.stage = 1
	g.lives = 3
	g.shake_trauma = 0.0
	g.generate_terrain()
	g.reset_lander()
	g.state = .playing
}

fn (mut g LunarLanderGame) reset_lander() {
	g.x = f32(rand.intn(200) or { 100 }) + 100.0
	g.y = 70.0
	g.vx = f32(rand.intn(40) or { 20 }) - 20.0
	g.vy = 0.0
	g.angle = 0.0
	g.fuel = 100.0
	g.state = .playing
}

fn (mut g LunarLanderGame) generate_terrain() {
	g.terrain_points.clear()
	g.pads.clear()

	mut current_x := f32(0.0)
	g.terrain_points << TerrainPoint{ x: 0.0, y: 480.0 }

	// Generate 3 landing pads across screen
	pad_x1 := f32(150.0)
	pad_x2 := f32(400.0)
	pad_x3 := f32(620.0)

	g.pads << LandingPad{ start_x: pad_x1, end_x: pad_x1 + 60.0, y: 460.0, multiplier: 2 }
	g.pads << LandingPad{ start_x: pad_x2, end_x: pad_x2 + 45.0, y: 500.0, multiplier: 5 }
	g.pads << LandingPad{ start_x: pad_x3, end_x: pad_x3 + 70.0, y: 440.0, multiplier: 3 }

	for current_x < 800.0 {
		// Check if near any pad
		mut on_pad := false
		for pad in g.pads {
			if current_x >= pad.start_x && current_x <= pad.end_x {
				g.terrain_points << TerrainPoint{ x: current_x, y: pad.y }
				on_pad = true
				break
			}
		}
		if !on_pad {
			y_val := 420.0 + f32(math.sin(current_x * 0.02)) * 60.0 + f32(rand.intn(40) or { 0 })
			g.terrain_points << TerrainPoint{ x: current_x, y: y_val }
		}
		current_x += 20.0
	}
	g.terrain_points << TerrainPoint{ x: 800.0, y: 520.0 }
}

fn (mut g LunarLanderGame) update(dt f32) {
	if g.shake_trauma > 0 {
		g.shake_trauma -= 2.0 * dt
		if g.shake_trauma < 0 {
			g.shake_trauma = 0
		}
	}

	if g.state != .playing { return }

	// Apply Gravity
	g.vy += g.gravity * dt

	// Main Thruster
	if g.key_thrust && g.fuel > 0 {
		g.fuel -= 14.0 * dt
		if g.fuel < 0 { g.fuel = 0 }

		ax := f32(math.sin(g.angle)) * g.main_thrust
		ay := -f32(math.cos(g.angle)) * g.main_thrust

		g.vx += ax * dt
		g.vy += ay * dt

		g.shake_trauma += 0.06 * dt
		if g.shake_trauma > 0.08 { g.shake_trauma = 0.08 }
		g.spawn_exhaust_particle()
		g.sound_mgr.play_thrust_sound()
	}

	// Rotational Thrusters
	if g.key_rot_left && g.fuel > 0 {
		g.angle -= g.rcs_torque * dt
		g.fuel -= 3.0 * dt
		g.sound_mgr.play_rcs_sound()
	}
	if g.key_rot_right && g.fuel > 0 {
		g.angle += g.rcs_torque * dt
		g.fuel -= 3.0 * dt
		g.sound_mgr.play_rcs_sound()
	}

	// Update Position
	g.x += g.vx * dt
	g.y += g.vy * dt

	// Screen Wrap / Bounds
	if g.x < 10 { g.x = 10; g.vx = -g.vx * 0.5 }
	if g.x > 790 { g.x = 790; g.vx = -g.vx * 0.5 }

	// Update Particles
	for mut p in g.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.life -= dt
	}
	g.particles = g.particles.filter(it.life > 0)

	// Check Terrain / Landing Pad Collisions
	terrain_y := g.get_terrain_height_at(g.x)
	if g.y >= terrain_y - 12.0 {
		g.y = terrain_y - 12.0
		g.evaluate_landing()
	}
}

fn (g &LunarLanderGame) get_terrain_height_at(x f32) f32 {
	if g.terrain_points.len < 2 { return 500.0 }
	for i in 0 .. g.terrain_points.len - 1 {
		p1 := g.terrain_points[i]
		p2 := g.terrain_points[i + 1]
		if x >= p1.x && x <= p2.x {
			t := (x - p1.x) / (p2.x - p1.x)
			return p1.y + t * (p2.y - p1.y)
		}
	}
	return 500.0
}

fn (mut g LunarLanderGame) evaluate_landing() {
	// Check landing pad bounds
	mut landed_pad_mult := 0
	for pad in g.pads {
		if g.x >= pad.start_x && g.x <= pad.end_x {
			landed_pad_mult = pad.multiplier
			break
		}
	}

	abs_angle := f32(math.abs(g.angle))
	abs_vx := f32(math.abs(g.vx))

	// Touchdown Criteria: On Pad, vy < 65, |vx| < 35, |angle| < 0.28 (~16 deg)
	if landed_pad_mult > 0 && g.vy < 65.0 && abs_vx < 35.0 && abs_angle < 0.28 {
		// Successful Landing!
		pts := (500 + int(g.fuel) * 10) * landed_pad_mult
		g.touchdown_pts = pts
		g.score += pts
		if g.score > g.high_score { g.high_score = g.score }
		g.state = .touchdown
		g.shake_trauma += 0.22
		if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
		g.sound_mgr.play_touchdown_sound()
	} else {
		// Crash Explosion!
		g.state = .crashed
		g.lives--
		g.shake_trauma += 0.65
		if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
		g.spawn_explosion()
		g.sound_mgr.play_crash_sound()
		if g.lives <= 0 {
			g.state = .game_over
		}
	}
}

fn (mut g LunarLanderGame) spawn_exhaust_particle() {
	ex := g.x - f32(math.sin(g.angle)) * 14.0
	ey := g.y + f32(math.cos(g.angle)) * 14.0

	g.particles << Particle{
		x: ex
		y: ey
		vx: -f32(math.sin(g.angle)) * 80.0 + f32((rand.intn(40) or { 20 }) - 20)
		vy: f32(math.cos(g.angle)) * 80.0 + f32((rand.intn(40) or { 20 }) - 20)
		life: 0.25
		max_life: 0.25
		color: Color{ r: 255, g: 150, b: 0, a: 255 }
	}
}

fn (mut g LunarLanderGame) spawn_explosion() {
	for _ in 0 .. 30 {
		ang := f32(rand.intn(360) or { 0 }) * f32(math.pi) / 180.0
		spd := f32(rand.intn(120) or { 40 }) + 30.0
		g.particles << Particle{
			x: g.x
			y: g.y
			vx: f32(math.cos(ang)) * spd
			vy: f32(math.sin(ang)) * spd
			life: 0.5
			max_life: 0.5
			color: Color{ r: 255, g: 80, b: 0, a: 255 }
		}
	}
}
