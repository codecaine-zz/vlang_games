module main

import math
import rand

pub enum PoolGameType {
	eight_ball
	nine_ball
	practice
}

pub enum BallGroup {
	unassigned
	solids // 1-7
	stripes // 9-15
}

pub enum TurnState {
	aiming
	power_pull
	balls_moving
	ball_in_hand
	game_over
}

pub struct Ball {
pub mut:
	id       int // 0: Cue ball, 1-7: Solids, 8: Black 8-Ball, 9-15: Stripes
	x        f64
	y        f64
	vx       f64
	vy       f64
	radius   f64 = 11.0
	is_cue   bool
	is_solid bool
	is_eight bool
	potted   bool
	spin_x   f64 // English / side spin
	spin_y   f64 // Topspin / Backspin
}

pub struct Pocket {
pub mut:
	x      f64
	y      f64
	radius f64 = 18.0
}

pub struct PoolPlayer {
pub mut:
	name   string
	is_ai  bool
	group  BallGroup = .unassigned
	score  int
}

pub struct PoolGame {
pub mut:
	typ           PoolGameType = .eight_ball
	state         TurnState    = .aiming
	players       []PoolPlayer
	current_p_idx int
	balls         []Ball
	pockets       []Pocket
	// Table Boundaries
	table_x       f64 = 100.0
	table_y       f64 = 120.0
	table_w       f64 = 600.0
	table_h       f64 = 340.0
	cushion_thick f64 = 28.0
	// Cue Aiming
	aim_angle     f64 = 0.0 // Angle in radians
	cue_power     f64 = 0.0 // 0.0 to 1.0
	power_pulling bool
	english_x     f64 = 0.0 // Side spin
	english_y     f64 = 0.0 // Follow / Draw
	// Turn Assessment
	first_ball_hit int = -1
	potted_this_shot []int
	cue_scratched bool
	foul_reason   string
	celebration   string
	celeb_timer   f64
	ai_diff       int = 1 // 0: Easy, 1: Medium, 2: Master
}

pub fn new_pool_game() PoolGame {
	mut game := PoolGame{
		typ: .eight_ball
		state: .aiming
		players: [
			PoolPlayer{ name: 'Player 1', is_ai: false }
		]
		current_p_idx: 0
		balls: []Ball{cap: 16}
		pockets: []Pocket{cap: 6}
	}
	game.init_pockets()
	game.rack_8ball()
	return game
}

pub fn (mut g PoolGame) init_pockets() {
	g.pockets.clear()
	cx := g.table_x + g.cushion_thick
	cy := g.table_y + g.cushion_thick
	cw := g.table_w - g.cushion_thick * 2.0
	ch := g.table_h - g.cushion_thick * 2.0

	// 6 Pockets: Top-Left, Top-Center, Top-Right, Bottom-Left, Bottom-Center, Bottom-Right
	g.pockets << Pocket{ x: cx, y: cy }
	g.pockets << Pocket{ x: cx + cw * 0.5, y: cy - 2.0 }
	g.pockets << Pocket{ x: cx + cw, y: cy }
	g.pockets << Pocket{ x: cx, y: cy + ch }
	g.pockets << Pocket{ x: cx + cw * 0.5, y: cy + ch + 2.0 }
	g.pockets << Pocket{ x: cx + cw, y: cy + ch }
}

pub fn (mut g PoolGame) set_mode(typ PoolGameType, is_2p bool, is_ai bool) {
	g.typ = typ
	g.players.clear()
	g.players << PoolPlayer{ name: 'Player 1', is_ai: false }

	if is_ai {
		g.players << PoolPlayer{ name: 'CPU Hustler', is_ai: true }
	} else if is_2p {
		g.players << PoolPlayer{ name: 'Player 2', is_ai: false }
	}

	g.current_p_idx = 0
	if typ == .nine_ball {
		g.rack_9ball()
	} else {
		g.rack_8ball()
	}
	g.state = .aiming
	g.celebration = ''
}

pub fn (mut g PoolGame) rack_8ball() {
	g.balls.clear()

	// Cue Ball (Head string position)
	g.balls << Ball{
		id: 0
		x: g.table_x + g.table_w * 0.28
		y: g.table_y + g.table_h * 0.5
		is_cue: true
	}

	// 15 Object Balls in standard triangle rack
	rack_apex_x := g.table_x + g.table_w * 0.72
	rack_apex_y := g.table_y + g.table_h * 0.5
	r := 11.0
	row_w := r * math.sqrt(3.0) + 0.5

	ball_order := [1, 9, 2, 8, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15]
	mut idx := 0

	for row := 0; row < 5; row++ {
		rx := rack_apex_x + f64(row) * row_w
		for col := 0; col <= row; col++ {
			ry := rack_apex_y + (f64(col) - f64(row) * 0.5) * (r * 2.0 + 0.5)
			b_id := ball_order[idx]
			g.balls << Ball{
				id: b_id
				x: rx
				y: ry
				is_solid: (b_id >= 1 && b_id <= 7)
				is_eight: (b_id == 8)
			}
			idx++
		}
	}
}

pub fn (mut g PoolGame) rack_9ball() {
	g.balls.clear()

	// Cue Ball
	g.balls << Ball{
		id: 0
		x: g.table_x + g.table_w * 0.28
		y: g.table_y + g.table_h * 0.5
		is_cue: true
	}

	// 9 Object Balls in diamond shape (1 at front, 9 in center)
	rack_apex_x := g.table_x + g.table_w * 0.72
	rack_apex_y := g.table_y + g.table_h * 0.5
	r := 11.0
	row_w := r * math.sqrt(3.0) + 0.5

	diamond_order := [1, 2, 3, 4, 9, 5, 6, 7, 8]
	mut d_idx := 0
	row_counts := [1, 2, 3, 2, 1]

	for row, count in row_counts {
		rx := rack_apex_x + f64(row) * row_w
		for col := 0; col < count; col++ {
			ry := rack_apex_y + (f64(col) - f64(count - 1) * 0.5) * (r * 2.0 + 0.5)
			b_id := diamond_order[d_idx]
			g.balls << Ball{
				id: b_id
				x: rx
				y: ry
				is_solid: (b_id <= 8)
				is_eight: false
			}
			d_idx++
		}
	}
}

pub fn (mut g PoolGame) strike_cue_ball(power f64, mut sound_mgr SoundManager) {
	if g.balls.len == 0 || g.balls[0].potted {
		return
	}

	speed := 150.0 + power * 650.0
	g.balls[0].vx = math.cos(g.aim_angle) * speed
	g.balls[0].vy = math.sin(g.aim_angle) * speed
	g.balls[0].spin_x = g.english_x
	g.balls[0].spin_y = g.english_y

	g.first_ball_hit = -1
	g.potted_this_shot.clear()
	g.cue_scratched = false
	g.foul_reason = ''
	g.state = .balls_moving

	sound_mgr.play_cue_strike(power)
}

pub fn (mut g PoolGame) update(dt f64, mut sound_mgr SoundManager) {
	// Update celebration timer
	if g.celeb_timer > 0.0 {
		g.celeb_timer -= dt
		if g.celeb_timer <= 0.0 {
			g.celebration = ''
		}
	}

	match g.state {
		.aiming {
			if g.players[g.current_p_idx].is_ai {
				g.update_ai_aim(dt, mut sound_mgr)
			}
		}
		.power_pull {
			if !g.players[g.current_p_idx].is_ai {
				g.cue_power = math.min(1.0, g.cue_power + 1.5 * dt)
			}
		}
		.balls_moving {
			g.update_physics(dt, mut sound_mgr)
			if g.are_all_balls_stopped() {
				g.process_turn_outcome(mut sound_mgr)
			}
		}
		.ball_in_hand {
			if g.players[g.current_p_idx].is_ai {
				g.balls[0].x = g.table_x + g.table_w * 0.28
				g.balls[0].y = g.table_y + g.table_h * 0.5
				g.balls[0].potted = false
				g.state = .aiming
			}
		}
		.game_over {}
	}
}

pub fn (mut g PoolGame) update_physics(dt f64, mut sound_mgr SoundManager) {
	inner_min_x := g.table_x + g.cushion_thick + 11.0
	inner_max_x := g.table_x + g.table_w - g.cushion_thick - 11.0
	inner_min_y := g.table_y + g.cushion_thick + 11.0
	inner_max_y := g.table_y + g.table_h - g.cushion_thick - 11.0

	// 1. Move balls & apply friction
	for mut b in g.balls {
		if b.potted { continue }

		b.x += b.vx * dt
		b.y += b.vy * dt

		// Apply spin draw/follow to cue ball
		if b.is_cue && math.abs(b.spin_y) > 0.01 {
			b.vx += math.cos(g.aim_angle) * b.spin_y * 120.0 * dt
			b.vy += math.sin(g.aim_angle) * b.spin_y * 120.0 * dt
			b.spin_y *= 0.96
		}

		// Rolling friction decay
		b.vx *= 0.985
		b.vy *= 0.985

		// Stop threshold
		speed_sq := b.vx * b.vx + b.vy * b.vy
		if speed_sq < 3.0 {
			b.vx = 0.0
			b.vy = 0.0
		}

		// 2. Check Pocket drops
		for p in g.pockets {
			dx := b.x - p.x
			dy := b.y - p.y
			dist := math.sqrt(dx * dx + dy * dy)
			if dist < p.radius {
				b.potted = true
				b.vx = 0.0
				b.vy = 0.0
				g.potted_this_shot << b.id
				sound_mgr.play_pocket_drop()
				if b.is_cue {
					g.cue_scratched = true
					sound_mgr.play_scratch()
				}
				break
			}
		}

		if b.potted { continue }

		// 3. Cushion Rail Reflections
		if b.x < inner_min_x {
			b.x = inner_min_x
			b.vx = -b.vx * 0.88
			sound_mgr.play_cushion_hit(math.abs(b.vx) / 400.0)
		} else if b.x > inner_max_x {
			b.x = inner_max_x
			b.vx = -b.vx * 0.88
			sound_mgr.play_cushion_hit(math.abs(b.vx) / 400.0)
		}

		if b.y < inner_min_y {
			b.y = inner_min_y
			b.vy = -b.vy * 0.88
			sound_mgr.play_cushion_hit(math.abs(b.vy) / 400.0)
		} else if b.y > inner_max_y {
			b.y = inner_max_y
			b.vy = -b.vy * 0.88
			sound_mgr.play_cushion_hit(math.abs(b.vy) / 400.0)
		}
	}

	// 4. Ball-to-Ball Elastic Collisions (Circle-to-Circle)
	for i := 0; i < g.balls.len; i++ {
		for j := i + 1; j < g.balls.len; j++ {
			if g.balls[i].potted || g.balls[j].potted { continue }

			dx := g.balls[j].x - g.balls[i].x
			dy := g.balls[j].y - g.balls[i].y
			dist := math.sqrt(dx * dx + dy * dy)
			min_dist := g.balls[i].radius + g.balls[j].radius

			if dist < min_dist && dist > 0.001 {
				// Record first ball hit by cue
				if g.balls[i].is_cue && g.first_ball_hit == -1 {
					g.first_ball_hit = g.balls[j].id
				} else if g.balls[j].is_cue && g.first_ball_hit == -1 {
					g.first_ball_hit = g.balls[i].id
				}

				// Normal vector
				nx := dx / dist
				ny := dy / dist

				// Separate overlapping balls
				overlap := (min_dist - dist) * 0.5
				g.balls[i].x -= nx * overlap
				g.balls[i].y -= ny * overlap
				g.balls[j].x += nx * overlap
				g.balls[j].y += ny * overlap

				// Relative velocity along normal
				kx := g.balls[i].vx - g.balls[j].vx
				ky := g.balls[i].vy - g.balls[j].vy
				p_val := 2.0 * (nx * kx + ny * ky) / 2.0

				if p_val > 0.0 {
					g.balls[i].vx -= p_val * nx * 0.95
					g.balls[i].vy -= p_val * ny * 0.95
					g.balls[j].vx += p_val * nx * 0.95
					g.balls[j].vy += p_val * ny * 0.95

					sound_mgr.play_ball_collision(p_val / 350.0)
				}
			}
		}
	}
}

pub fn (g &PoolGame) are_all_balls_stopped() bool {
	for b in g.balls {
		if b.potted { continue }
		if b.vx != 0.0 || b.vy != 0.0 {
			return false
		}
	}
	return true
}

fn (mut g PoolGame) process_turn_outcome(mut sound_mgr SoundManager) {
	mut p := &g.players[g.current_p_idx]
	mut switch_turn := true

	// Check Scratches
	if g.cue_scratched {
		g.foul_reason = 'CUE BALL SCRATCH! BALL-IN-HAND'
		g.balls[0].potted = false
		g.balls[0].x = g.table_x + g.table_w * 0.28
		g.balls[0].y = g.table_y + g.table_h * 0.5
		g.balls[0].vx = 0.0
		g.balls[0].vy = 0.0
		g.state = .ball_in_hand
		g.switch_player()
		return
	}

	// Check 8-Ball Game Rules
	if g.typ == .eight_ball {
		mut potted_8 := false
		for b_id in g.potted_this_shot {
			if b_id == 8 { potted_8 = true }
		}

		if potted_8 {
			// Check if legal 8-ball win (all own balls cleared)
			all_own_cleared := g.are_all_group_balls_potted(p.group)
			if all_own_cleared {
				g.celebration = '${p.name.to_upper()} WINS THE GAME!'
				sound_mgr.play_victory()
			} else {
				g.celebration = 'EARLY 8-BALL POTTED! ${p.name.to_upper()} LOSES!'
				sound_mgr.play_scratch()
			}
			g.state = .game_over
			return
		}

		// Assign groups on first legal pot
		if p.group == .unassigned && g.potted_this_shot.len > 0 {
			first_pot := g.potted_this_shot[0]
			if first_pot >= 1 && first_pot <= 7 {
				p.group = .solids
				if g.players.len > 1 { g.players[1 - g.current_p_idx].group = .stripes }
				switch_turn = false
			} else if first_pot >= 9 && first_pot <= 15 {
				p.group = .stripes
				if g.players.len > 1 { g.players[1 - g.current_p_idx].group = .solids }
				switch_turn = false
			}
		} else if p.group != .unassigned {
			// Continue turn if legally potted own ball
			for b_id in g.potted_this_shot {
				if p.group == .solids && b_id >= 1 && b_id <= 7 { switch_turn = false }
				if p.group == .stripes && b_id >= 9 && b_id <= 15 { switch_turn = false }
			}
		}
	} else if g.typ == .nine_ball {
		mut potted_9 := false
		for b_id in g.potted_this_shot {
			if b_id == 9 { potted_9 = true }
		}

		if potted_9 {
			g.celebration = '${p.name.to_upper()} WINS 9-BALL!'
			sound_mgr.play_victory()
			g.state = .game_over
			return
		}
		if g.potted_this_shot.len > 0 {
			switch_turn = false
		}
	} else {
		// Practice
		switch_turn = false
	}

	if switch_turn {
		g.switch_player()
	}

	g.state = .aiming
}

fn (mut g PoolGame) switch_player() {
	if g.players.len > 1 {
		g.current_p_idx = 1 - g.current_p_idx
	}
}

pub fn (g &PoolGame) are_all_group_balls_potted(group BallGroup) bool {
	if group == .unassigned { return false }
	for b in g.balls {
		if b.potted || b.is_cue || b.is_eight { continue }
		if group == .solids && b.is_solid { return false }
		if group == .stripes && !b.is_solid { return false }
	}
	return true
}

// Smart AI Aiming
fn (mut g PoolGame) update_ai_aim(_ f64, mut sound_mgr SoundManager) {
	if g.balls.len == 0 || g.balls[0].potted { return }

	// Find best target object ball and pocket angle
	mut best_angle := 0.0
	mut best_dist := 9999.0

	for b in g.balls {
		if b.potted || b.is_cue { continue }
		dx := b.x - g.balls[0].x
		dy := b.y - g.balls[0].y
		dist := math.sqrt(dx * dx + dy * dy)
		if dist < best_dist {
			best_dist = dist
			best_angle = math.atan2(dy, dx)
		}
	}

	g.aim_angle = best_angle + (rand.f64() * 0.04 - 0.02)
	power := 0.5 + rand.f64() * 0.3
	g.strike_cue_ball(power, mut sound_mgr)
}
