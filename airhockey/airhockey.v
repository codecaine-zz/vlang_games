module main

import math
import rand

pub enum AIDifficulty {
	easy
	medium
	hard
}

pub enum GameState {
	serve
	playing
	goal_celebration
	game_over
}

pub struct Puck {
pub mut:
	x      f64
	y      f64
	vx     f64
	vy     f64
	radius f64 = 16.0
	trail  [][]f64
}

pub struct Mallet {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	prev_x   f64
	prev_y   f64
	radius   f64 = 28.0
	is_p1    bool
}

pub struct Particle {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	max_l f64
	r     u8
	g     u8
	b     u8
}

pub struct AirHockeyGame {
pub mut:
	table_x      f64 = 50.0
	table_y      f64 = 90.0
	table_w      f64 = 840.0
	table_h      f64 = 500.0
	goal_h       f64 = 180.0
	puck         Puck
	p1_mallet    Mallet
	p2_mallet    Mallet
	score_p1     int
	score_p2     int
	max_score    int = 7
	state        GameState = .serve
	is_two_player bool
	difficulty   AIDifficulty = .medium
	particles    []Particle
	goal_timer   f64
	goal_scorer  int // 1 or 2
	sound_event  string
	sound_speed  f64
}

pub fn new_airhockey_game(is_2p bool) AirHockeyGame {
	mut g := AirHockeyGame{
		is_two_player: is_2p
	}
	g.reset_game()
	return g
}

pub fn (mut g AirHockeyGame) reset_game() {
	g.score_p1 = 0
	g.score_p2 = 0
	g.state = .serve
	g.goal_scorer = 0
	g.particles.clear()
	g.reset_positions(1)
}

pub fn (mut g AirHockeyGame) reset_positions(server int) {
	cy := g.table_y + g.table_h / 2.0
	cx := g.table_x + g.table_w / 2.0

	g.p1_mallet = Mallet{
		x: g.table_x + g.table_w * 0.2
		y: cy
		prev_x: g.table_x + g.table_w * 0.2
		prev_y: cy
		is_p1: true
	}

	g.p2_mallet = Mallet{
		x: g.table_x + g.table_w * 0.8
		y: cy
		prev_x: g.table_x + g.table_w * 0.8
		prev_y: cy
		is_p1: false
	}

	puck_x := if server == 1 { cx - 100.0 } else { cx + 100.0 }
	g.puck = Puck{
		x: puck_x
		y: cy
		vx: 0
		vy: 0
	}
	g.puck.trail.clear()
}

pub fn (mut g AirHockeyGame) spawn_sparks(x f64, y f64, count int, r u8, gr u8, b u8) {
	for _ in 0 .. count {
		angle := rand.f64() * math.pi * 2.0
		speed := rand.f64() * 250.0 + 80.0
		g.particles << Particle{
			x: x
			y: y
			vx: math.cos(angle) * speed
			vy: math.sin(angle) * speed
			life: 0.4 + rand.f64() * 0.3
			max_l: 0.7
			r: r
			g: gr
			b: b
		}
	}
}

pub fn (mut g AirHockeyGame) update(dt f64, p1_input_x f64, p1_input_y f64, p2_input_x f64, p2_input_y f64) {
	// Update particles
	for mut p in g.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.life -= dt
	}
	g.particles = g.particles.filter(it.life > 0)

	if g.state == .goal_celebration {
		g.goal_timer -= dt
		if g.goal_timer <= 0 {
			if g.score_p1 >= g.max_score || g.score_p2 >= g.max_score {
				g.state = .game_over
				g.sound_event = 'victory'
			} else {
				g.state = .playing
				// Server is the player who was scored on
				server := if g.goal_scorer == 1 { 2 } else { 1 }
				g.reset_positions(server)
			}
		}
		return
	}

	if g.state == .game_over {
		return
	}

	cx := g.table_x + g.table_w / 2.0
	cy := g.table_y + g.table_h / 2.0
	goal_top := g.table_y + (g.table_h - g.goal_h) / 2.0
	goal_bot := goal_top + g.goal_h

	// Update P1 Mallet
	g.p1_mallet.prev_x = g.p1_mallet.x
	g.p1_mallet.prev_y = g.p1_mallet.y

	// Smooth target follow
	g.p1_mallet.x += (p1_input_x - g.p1_mallet.x) * math.min(1.0, dt * 25.0)
	g.p1_mallet.y += (p1_input_y - g.p1_mallet.y) * math.min(1.0, dt * 25.0)

	// Clamp P1 to left half-court
	g.p1_mallet.x = math.clamp(g.p1_mallet.x, g.table_x + g.p1_mallet.radius, cx - g.p1_mallet.radius)
	g.p1_mallet.y = math.clamp(g.p1_mallet.y, g.table_y + g.p1_mallet.radius, g.table_y + g.table_h - g.p1_mallet.radius)

	g.p1_mallet.vx = (g.p1_mallet.x - g.p1_mallet.prev_x) / dt
	g.p1_mallet.vy = (g.p1_mallet.y - g.p1_mallet.prev_y) / dt

	// Update P2 / AI Mallet
	g.p2_mallet.prev_x = g.p2_mallet.x
	g.p2_mallet.prev_y = g.p2_mallet.y

	if g.is_two_player {
		g.p2_mallet.x += (p2_input_x - g.p2_mallet.x) * math.min(1.0, dt * 25.0)
		g.p2_mallet.y += (p2_input_y - g.p2_mallet.y) * math.min(1.0, dt * 25.0)
	} else {
		g.update_ai(dt)
	}

	// Clamp P2 to right half-court
	g.p2_mallet.x = math.clamp(g.p2_mallet.x, cx + g.p2_mallet.radius, g.table_x + g.table_w - g.p2_mallet.radius)
	g.p2_mallet.y = math.clamp(g.p2_mallet.y, g.table_y + g.p2_mallet.radius, g.table_y + g.table_h - g.p2_mallet.radius)

	g.p2_mallet.vx = (g.p2_mallet.x - g.p2_mallet.prev_x) / dt
	g.p2_mallet.vy = (g.p2_mallet.y - g.p2_mallet.prev_y) / dt

	// Update Puck Physics
	// Friction decay
	g.puck.vx *= math.pow(0.993, dt * 60.0)
	g.puck.vy *= math.pow(0.993, dt * 60.0)

	// Speed cap
	puck_speed := math.sqrt(g.puck.vx * g.puck.vx + g.puck.vy * g.puck.vy)
	max_puck_speed := 950.0
	if puck_speed > max_puck_speed {
		g.puck.vx = (g.puck.vx / puck_speed) * max_puck_speed
		g.puck.vy = (g.puck.vy / puck_speed) * max_puck_speed
	}

	g.puck.x += g.puck.vx * dt
	g.puck.y += g.puck.vy * dt

	// Trail recording
	if puck_speed > 100.0 {
		g.puck.trail << [g.puck.x, g.puck.y]
		if g.puck.trail.len > 12 {
			g.puck.trail.delete(0)
		}
	} else if g.puck.trail.len > 0 {
		g.puck.trail.delete(0)
	}

	// Check Mallet-Puck Collisions
	g.handle_mallet_collision(mut g.p1_mallet)
	g.handle_mallet_collision(mut g.p2_mallet)

	// Check Wall Collisions (Top & Bottom)
	if g.puck.y - g.puck.radius < g.table_y {
		g.puck.y = g.table_y + g.puck.radius
		g.puck.vy = -g.puck.vy * 0.95
		g.sound_event = 'rail'
		g.sound_speed = math.abs(g.puck.vy)
		g.spawn_sparks(g.puck.x, g.table_y, 8, 100, 200, 255)
	} else if g.puck.y + g.puck.radius > g.table_y + g.table_h {
		g.puck.y = g.table_y + g.table_h - g.puck.radius
		g.puck.vy = -g.puck.vy * 0.95
		g.sound_event = 'rail'
		g.sound_speed = math.abs(g.puck.vy)
		g.spawn_sparks(g.puck.x, g.table_y + g.table_h, 8, 100, 200, 255)
	}

	// Check Left Goal & Wall Collisions
	if g.puck.x - g.puck.radius < g.table_x {
		// Is it inside goal mouth?
		if g.puck.y >= goal_top && g.puck.y <= goal_bot {
			// GOAL FOR PLAYER 2!
			g.score_p2++
			g.goal_scorer = 2
			g.state = .goal_celebration
			g.goal_timer = 2.0
			g.sound_event = 'goal'
			g.spawn_sparks(g.table_x, g.puck.y, 40, 255, 100, 100)
			return
		} else {
			// Bounce off left wall
			g.puck.x = g.table_x + g.puck.radius
			g.puck.vx = -g.puck.vx * 0.95
			g.sound_event = 'rail'
			g.sound_speed = math.abs(g.puck.vx)
			g.spawn_sparks(g.table_x, g.puck.y, 8, 100, 200, 255)
		}
	}

	// Check Right Goal & Wall Collisions
	if g.puck.x + g.puck.radius > g.table_x + g.table_w {
		if g.puck.y >= goal_top && g.puck.y <= goal_bot {
			// GOAL FOR PLAYER 1!
			g.score_p1++
			g.goal_scorer = 1
			g.state = .goal_celebration
			g.goal_timer = 2.0
			g.sound_event = 'goal'
			g.spawn_sparks(g.table_x + g.table_w, g.puck.y, 40, 100, 255, 100)
			return
		} else {
			// Bounce off right wall
			g.puck.x = g.table_x + g.table_w - g.puck.radius
			g.puck.vx = -g.puck.vx * 0.95
			g.sound_event = 'rail'
			g.sound_speed = math.abs(g.puck.vx)
			g.spawn_sparks(g.table_x + g.table_w, g.puck.y, 8, 100, 200, 255)
		}
	}
	// Anti-stuck corner / rail auto-clearance
	puck_speed_sq := g.puck.vx * g.puck.vx + g.puck.vy * g.puck.vy
	if puck_speed_sq < 900.0 { // speed < 30 px/s
		// If in corners or pressed against side walls
		in_right_corner := g.puck.x > g.table_x + g.table_w - 90.0 && (g.puck.y < g.table_y + 90.0 || g.puck.y > g.table_y + g.table_h - 90.0)
		in_left_corner := g.puck.x < g.table_x + 90.0 && (g.puck.y < g.table_y + 90.0 || g.puck.y > g.table_y + g.table_h - 90.0)
		if in_right_corner {
			// Clear towards center-left
			dir_y := if g.puck.y < cy { 120.0 } else { -120.0 }
			g.puck.vx = -180.0
			g.puck.vy = dir_y
		} else if in_left_corner {
			dir_y := if g.puck.y < cy { 120.0 } else { -120.0 }
			g.puck.vx = 180.0
			g.puck.vy = dir_y
		}
	}
}

pub fn (mut g AirHockeyGame) handle_mallet_collision(mut m Mallet) {
	dx := g.puck.x - m.x
	dy := g.puck.y - m.y
	dist := math.sqrt(dx * dx + dy * dy)
	min_dist := g.puck.radius + m.radius

	if dist < min_dist && dist > 0.0001 {
		// Normal vector
		nx := dx / dist
		ny := dy / dist

		// Separate puck and mallet
		overlap := min_dist - dist
		g.puck.x += nx * overlap * 0.7
		g.puck.y += ny * overlap * 0.7
		m.x -= nx * overlap * 0.3
		m.y -= ny * overlap * 0.3

		// Relative velocity
		rvx := g.puck.vx - m.vx
		rvy := g.puck.vy - m.vy
		vel_along_normal := rvx * nx + rvy * ny

		if vel_along_normal < 0 {
			// Elastic restitution
			restitution := 1.25
			impulse := -(1.0 + restitution) * vel_along_normal
			g.puck.vx += nx * impulse
			g.puck.vy += ny * impulse

			// Impart extra momentum from mallet swing
			g.puck.vx += m.vx * 0.65
			g.puck.vy += m.vy * 0.65

			g.sound_event = 'hit'
			g.sound_speed = math.max(100.0, math.sqrt(g.puck.vx * g.puck.vx + g.puck.vy * g.puck.vy))
			g.spawn_sparks(g.puck.x, g.puck.y, 14, 255, 220, 80)
		} else {
			// If pushing out from overlap, ensure positive separation velocity
			g.puck.vx += nx * 120.0
			g.puck.vy += ny * 120.0
		}
	}
}

pub fn (mut g AirHockeyGame) update_ai(dt f64) {
	cx := g.table_x + g.table_w / 2.0
	cy := g.table_y + g.table_h / 2.0
	ai_base_x := g.table_x + g.table_w * 0.85
	right_wall := g.table_x + g.table_w - g.p2_mallet.radius

	mut target_x := ai_base_x
	mut target_y := cy
	mut ai_speed := 420.0

	// Check if puck is in defensive corner (upper right or lower right)
	is_in_corner := g.puck.x > g.table_x + g.table_w - 120.0 && (g.puck.y < g.table_y + 110.0 || g.puck.y > g.table_y + g.table_h - 110.0)

	// Check if puck is behind the AI mallet (puck closer to AI goal than AI mallet)
	puck_behind_ai := g.puck.x > g.p2_mallet.x - 10.0

	if is_in_corner || puck_behind_ai {
		// When puck is behind AI or trapped in corner:
		// AI should retreat to goal defense / behind puck, not jam into the corner!
		target_x = math.min(right_wall, g.puck.x + 55.0)
		target_y = if g.puck.y < cy {
			math.min(g.table_y + g.table_h - 80.0, cy + 40.0)
		} else {
			math.max(g.table_y + 80.0, cy - 40.0)
		}
		ai_speed = 480.0
	} else {
		match g.difficulty {
			.easy {
				ai_speed = 290.0
				if g.puck.x > cx + 40.0 {
					target_x = math.min(right_wall, g.puck.x + 35.0)
					target_y = g.puck.y
				} else {
					target_y = g.puck.y * 0.5 + cy * 0.5
				}
			}
			.medium {
				ai_speed = 480.0
				if g.puck.x > cx {
					// Position slightly behind and above/below puck to shoot at P1 goal
					target_x = math.min(right_wall, g.puck.x + 32.0)
					target_y = g.puck.y
				} else {
					// Defend goal line with prediction
					target_x = ai_base_x
					target_y = math.clamp(g.puck.y + g.puck.vy * 0.15, g.table_y + 60.0, g.table_y + g.table_h - 60.0)
				}
			}
			.hard {
				ai_speed = 700.0
				if g.puck.x > cx - 20.0 {
					// Strike position behind the puck angled towards P1 goal
					target_x = math.min(right_wall, g.puck.x + 28.0)
					target_y = g.puck.y + (g.puck.y - cy) * 0.08
				} else {
					// Intercept trajectory
					intercept_time := (ai_base_x - g.puck.x) / math.max(120.0, g.puck.vx)
					predicted_y := g.puck.y + g.puck.vy * intercept_time
					target_x = ai_base_x
					target_y = math.clamp(predicted_y, g.table_y + 40.0, g.table_y + g.table_h - 40.0)
				}
			}
		}
	}

	dx := target_x - g.p2_mallet.x
	dy := target_y - g.p2_mallet.y
	dist := math.sqrt(dx * dx + dy * dy)

	if dist > 1.0 {
		step := math.min(dist, ai_speed * dt)
		g.p2_mallet.x += (dx / dist) * step
		g.p2_mallet.y += (dy / dist) * step
	}
}
