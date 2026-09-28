module main

import math
import rand

pub enum GameMode {
	solo
	vs_ai
	vs_2p
}

pub enum AimPhase {
	position // Step 1: Slide starting stance left/right
	angle    // Step 2: Aim oscillating launch arrow
	power    // Step 3: Oscillating power & hook meter
	rolling  // Ball is in motion down the lane
	settling // Pins are falling and settling
	sweep    // Pinsetter clears fallen pins
	frame_over
	game_over
}

pub struct Pin {
pub mut:
	id       int
	x        f64 // Pin center X (lane coordinates)
	y        f64 // Pin center Y
	init_x   f64 // Rack resting X
	init_y   f64 // Rack resting Y
	vx       f64
	vy       f64
	tilt     f64 // Tilt angle from vertical in radians
	v_tilt   f64 // Angular velocity of tilt
	rot      f64 // Planar orientation rotation
	v_rot    f64
	standing bool = true
	knocked  bool
	wobble   f64
	wobble_t f64
	settled  bool
	mass     f64 = 1.53 // 3 lb 8 oz (~1.53 kg)
	radius   f64 = 11.5
}

pub struct Ball {
pub mut:
	x         f64
	y         f64
	vx        f64
	vy        f64
	radius    f64 = 17.5 // Bowling ball standard radius
	mass      f64 = 6.80 // 15 lb (~6.8 kg)
	spin      f64        // Lateral RPM spin (hook effect)
	speed     f64
	active    bool
	in_gutter bool
}

pub struct FrameScore {
pub mut:
	roll1      int = -1
	roll2      int = -1
	roll3      int = -1 // For 10th frame
	cumulative int = -1
	is_strike  bool
	is_spare   bool
}

pub struct PlayerState {
pub mut:
	name          string
	frames        [10]FrameScore
	current_frame int
	current_roll  int // 0: First roll, 1: Second roll, 2: 10th frame bonus
	total_score   int
	strikes       int
	spares        int
	is_ai         bool
}

pub struct BowlingGame {
pub mut:
	mode           GameMode = .solo
	phase          AimPhase = .position
	players        []PlayerState
	current_player int
	pins           []Pin
	ball           Ball
	aim_x          f64 = 406.0 // Default setup slightly right of center towards 1-3 pocket
	aim_angle      f64 = 0.0   // Radians from straight ahead (-0.12 to +0.12)
	power          f64 = 0.65  // 0.2 to 1.0
	hook           f64 = 0.35  // -1.0 to 1.0 (Hook spin towards pocket)
	power_dir      f64 = 1.0
	angle_dir      f64 = 1.0
	state_timer    f64
	celebration    string
	celeb_timer    f64
	ai_diff        int = 1 // 0: Novice, 1: Pro, 2: Hall of Fame
	// Lane dimensions in game world
	lane_left      f64 = 250.0
	lane_right     f64 = 550.0
	lane_top       f64 = 95.0  // Pin deck back
	lane_bottom    f64 = 620.0 // Foul line
	oil_end_y      f64 = 310.0 // Backend friction starts here (dry lane)
	sweep_y        f64
	particles      []Particle
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
	size     int
}

// Initialize standard 10-pin triangle rack with authentic spacing
pub fn init_pins() []Pin {
	mut pins := []Pin{cap: 10}
	center_x := 400.0
	row_dist := 26.0
	pin_dist := 27.5

	// Pin 1 (Headpin, Row 1)
	pins << Pin{ id: 1, x: center_x, y: 195.0, init_x: center_x, init_y: 195.0 }

	// Pins 2, 3 (Row 2)
	pins << Pin{ id: 2, x: center_x - pin_dist * 0.5, y: 195.0 - row_dist, init_x: center_x - pin_dist * 0.5, init_y: 195.0 - row_dist }
	pins << Pin{ id: 3, x: center_x + pin_dist * 0.5, y: 195.0 - row_dist, init_x: center_x + pin_dist * 0.5, init_y: 195.0 - row_dist }

	// Pins 4, 5, 6 (Row 3)
	pins << Pin{ id: 4, x: center_x - pin_dist, y: 195.0 - row_dist * 2.0, init_x: center_x - pin_dist, init_y: 195.0 - row_dist * 2.0 }
	pins << Pin{ id: 5, x: center_x, y: 195.0 - row_dist * 2.0, init_x: center_x, init_y: 195.0 - row_dist * 2.0 }
	pins << Pin{ id: 6, x: center_x + pin_dist, y: 195.0 - row_dist * 2.0, init_x: center_x + pin_dist, init_y: 195.0 - row_dist * 2.0 }

	// Pins 7, 8, 9, 10 (Row 4)
	pins << Pin{ id: 7, x: center_x - pin_dist * 1.5, y: 195.0 - row_dist * 3.0, init_x: center_x - pin_dist * 1.5, init_y: 195.0 - row_dist * 3.0 }
	pins << Pin{ id: 8, x: center_x - pin_dist * 0.5, y: 195.0 - row_dist * 3.0, init_x: center_x - pin_dist * 0.5, init_y: 195.0 - row_dist * 3.0 }
	pins << Pin{ id: 9, x: center_x + pin_dist * 0.5, y: 195.0 - row_dist * 3.0, init_x: center_x + pin_dist * 0.5, init_y: 195.0 - row_dist * 3.0 }
	pins << Pin{ id: 10, x: center_x + pin_dist * 1.5, y: 195.0 - row_dist * 3.0, init_x: center_x + pin_dist * 1.5, init_y: 195.0 - row_dist * 3.0 }

	return pins
}

pub fn new_bowling_game() BowlingGame {
	mut game := BowlingGame{
		mode: .solo
		phase: .position
		players: [
			PlayerState{ name: 'Player 1', is_ai: false }
		]
		current_player: 0
		pins: init_pins()
		ball: Ball{ x: 406.0, y: 580.0, active: false }
		aim_x: 406.0
		sweep_y: 75.0
	}
	return game
}

pub fn (mut g BowlingGame) set_mode(mode GameMode) {
	g.mode = mode
	g.players.clear()
	match mode {
		.solo {
			g.players << PlayerState{ name: 'Player 1', is_ai: false }
		}
		.vs_ai {
			g.players << PlayerState{ name: 'Player 1', is_ai: false }
			g.players << PlayerState{ name: 'CPU Walter', is_ai: true }
		}
		.vs_2p {
			g.players << PlayerState{ name: 'Player 1', is_ai: false }
			g.players << PlayerState{ name: 'Player 2', is_ai: false }
		}
	}
	g.reset_game()
}

pub fn (mut g BowlingGame) reset_game() {
	for mut p in g.players {
		p.current_frame = 0
		p.current_roll = 0
		p.total_score = 0
		p.strikes = 0
		p.spares = 0
		for i in 0 .. 10 {
			p.frames[i] = FrameScore{}
		}
	}
	g.current_player = 0
	g.reset_pins()
	g.reset_ball()
	g.phase = .position
	g.celebration = ''
}

pub fn (mut g BowlingGame) reset_pins() {
	g.pins = init_pins()
}

pub fn (mut g BowlingGame) reset_ball() {
	g.ball = Ball{
		x: g.aim_x
		y: g.lane_bottom - 40.0
		vx: 0.0
		vy: 0.0
		active: false
		in_gutter: false
	}
}

pub fn (mut g BowlingGame) launch_ball(mut sound_mgr SoundManager) {
	// Ball speed: 280 to 520 px/s (roughly 14 to 22 mph)
	speed := 280.0 + g.power * 260.0
	g.ball.x = g.aim_x
	g.ball.y = g.lane_bottom - 40.0
	g.ball.vx = math.sin(g.aim_angle) * speed
	g.ball.vy = -math.cos(g.aim_angle) * speed
	g.ball.speed = speed
	g.ball.spin = g.hook * 90.0 // Lateral hook RPM
	g.ball.active = true
	g.ball.in_gutter = false
	g.phase = .rolling
	g.state_timer = 0.0

	sound_mgr.play_roll_sound(g.power)
}

pub fn (mut g BowlingGame) update(dt f64, mut sound_mgr SoundManager) {
	// Update celebration banner timer
	if g.celeb_timer > 0.0 {
		g.celeb_timer -= dt
		if g.celeb_timer <= 0.0 {
			g.celebration = ''
		}
	}

	// Update particle effects
	for i := g.particles.len - 1; i >= 0; i-- {
		mut p := &g.particles[i]
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.life -= dt
		if p.life <= 0.0 {
			g.particles.delete(i)
		}
	}

	match g.phase {
		.position {
			if g.players[g.current_player].is_ai {
				g.update_ai_aim(dt, mut sound_mgr)
			}
		}
		.angle {
			if !g.players[g.current_player].is_ai {
				// Oscillating angle
				g.aim_angle += g.angle_dir * 0.22 * dt
				if g.aim_angle > 0.10 {
					g.aim_angle = 0.10
					g.angle_dir = -1.0
				} else if g.aim_angle < -0.10 {
					g.aim_angle = -0.10
					g.angle_dir = 1.0
				}
			} else {
				g.update_ai_angle(dt, mut sound_mgr)
			}
		}
		.power {
			if !g.players[g.current_player].is_ai {
				// Oscillating power meter
				g.power += g.power_dir * 1.5 * dt
				if g.power > 1.0 {
					g.power = 1.0
					g.power_dir = -1.0
				} else if g.power < 0.2 {
					g.power = 0.2
					g.power_dir = 1.0
				}
			} else {
				g.update_ai_power(dt, mut sound_mgr)
			}
		}
		.rolling {
			// Sub-step physics (4 sub-steps for smooth and rigid collision resolution)
			sub_steps := 4
			sub_dt := dt / f64(sub_steps)
			for _ in 0 .. sub_steps {
				g.update_ball_physics(sub_dt, mut sound_mgr)
				g.update_pins_physics(sub_dt, mut sound_mgr)
			}
		}
		.settling {
			g.state_timer += dt
			sub_steps := 4
			sub_dt := dt / f64(sub_steps)
			for _ in 0 .. sub_steps {
				g.update_pins_physics(sub_dt, mut sound_mgr)
			}
			if g.state_timer > 2.0 {
				g.process_roll_results(mut sound_mgr)
			}
		}
		.sweep {
			g.state_timer += dt
			g.sweep_y += 320.0 * dt
			if g.sweep_y > 230.0 {
				g.finish_sweep()
			}
		}
		.frame_over {
			g.state_timer += dt
			if g.state_timer > 1.4 {
				g.advance_turn()
			}
		}
		.game_over {}
	}
}

fn (mut g BowlingGame) update_ball_physics(dt f64, mut sound_mgr SoundManager) {
	if !g.ball.active {
		return
	}

	// 1. Hook Traction Physics
	// On the oiled front lane (y > oil_end_y), the ball skids with low traction.
	// On the dry backend (y <= oil_end_y), the ball grips and curves laterally towards pocket!
	if !g.ball.in_gutter {
		friction_coeff := if g.ball.y <= g.oil_end_y {
			// Dry backend: strong traction
			1.4
		} else {
			// Slick oiled heads: minor traction
			0.22
		}
		g.ball.vx -= g.ball.spin * friction_coeff * dt
	}

	g.ball.x += g.ball.vx * dt
	g.ball.y += g.ball.vy * dt

	// 2. Gutter Detection
	if !g.ball.in_gutter {
		if g.ball.x - g.ball.radius < g.lane_left {
			g.ball.x = g.lane_left - 12.0
			g.ball.vx = 0.0
			g.ball.in_gutter = true
			sound_mgr.play_gutter_sound()
		} else if g.ball.x + g.ball.radius > g.lane_right {
			g.ball.x = g.lane_right + 12.0
			g.ball.vx = 0.0
			g.ball.in_gutter = true
			sound_mgr.play_gutter_sound()
		}
	}

	// 3. Ball-Pin Rigid Collision Dynamics
	if !g.ball.in_gutter {
		for mut pin in g.pins {
			if !pin.standing && pin.tilt > 0.45 {
				continue
			}

			dx := pin.x - g.ball.x
			dy := pin.y - g.ball.y
			dist := math.sqrt(dx * dx + dy * dy)
			min_dist := g.ball.radius + pin.radius

			if dist < min_dist && dist > 0.001 {
				// Normal vector
				nx := dx / dist
				ny := dy / dist

				// Relative velocity along normal
				rel_vx := g.ball.vx - pin.vx
				rel_vy := g.ball.vy - pin.vy
				approach_speed := rel_vx * nx + rel_vy * ny

				if approach_speed > 0.0 {
					// 2D Elastic Momentum Transfer
					impulse := (1.0 + 0.6) * approach_speed * (g.ball.mass * pin.mass) / (g.ball.mass + pin.mass)

					// Pin acceleration & trajectory
					pin.vx += (nx * impulse) / pin.mass
					pin.vy += (ny * impulse) / pin.mass

					// Torque & tilt rotation based on impact angle
					impact_offset := (nx * (-g.ball.vy) + ny * g.ball.vx) / math.max(1.0, g.ball.speed)
					pin.v_tilt += (approach_speed / 40.0) * (1.0 + math.abs(impact_offset) * 0.8)
					pin.v_rot += impact_offset * 15.0

					// Ball momentum deflection (Law of Action-Reaction)
					g.ball.vx -= (nx * impulse) / g.ball.mass
					g.ball.vy -= (ny * impulse) / g.ball.mass

					// Topple determination
					if pin.v_tilt > 2.2 || approach_speed > 120.0 {
						pin.standing = false
						pin.knocked = true
					} else {
						// Glancing brush - pin wobbles but may stay standing!
						pin.wobble = 0.35
						pin.wobble_t = 0.0
					}

					// Spawn collision wood fragments
					for _ in 0 .. 5 {
						g.particles << Particle{
							x: pin.x
							y: pin.y
							vx: (rand.f64() * 160.0 - 80.0) + pin.vx * 0.3
							vy: (rand.f64() * 160.0 - 80.0) + pin.vy * 0.3
							life: 0.35
							max_life: 0.35
							color: Color{ r: 250, g: 250, b: 255 }
							size: 2
						}
					}

					sound_mgr.play_pin_hit(approach_speed / 400.0)
				}
			}
		}
	}

	// Ball passes pin deck pit
	if g.ball.y < g.lane_top - 20.0 {
		g.ball.active = false
		g.phase = .settling
		g.state_timer = 0.0
	}
}

fn (mut g BowlingGame) update_pins_physics(dt f64, mut sound_mgr SoundManager) {
	kickback_l := g.lane_left - 8.0
	kickback_r := g.lane_right + 8.0

	for i := 0; i < 10; i++ {
		mut p1 := &g.pins[i]

		// Update wobble & tilt restoring forces
		if p1.standing {
			if p1.wobble > 0.0 {
				p1.wobble_t += dt * 14.0
				p1.wobble *= 0.95
				p1.tilt = math.sin(p1.wobble_t) * p1.wobble
				if p1.wobble < 0.02 {
					p1.wobble = 0.0
					p1.tilt = 0.0
				}
			}
			continue
		}

		// Flying / Fallen pin dynamics
		p1.x += p1.vx * dt
		p1.y += p1.vy * dt
		p1.tilt = math.min(1.57, p1.tilt + p1.v_tilt * dt)
		p1.rot += p1.v_rot * dt

		// Sliding friction
		p1.vx *= 0.965
		p1.vy *= 0.965
		p1.v_tilt *= 0.92
		p1.v_rot *= 0.94

		// 1. Kickback Side Cushion Bounce (Pins bounce off side walls)
		if p1.x < kickback_l {
			p1.x = kickback_l
			p1.vx = -p1.vx * 0.55
			p1.v_rot = (rand.f64() * 8.0 - 4.0)
		} else if p1.x > kickback_r {
			p1.x = kickback_r
			p1.vx = -p1.vx * 0.55
			p1.v_rot = (rand.f64() * 8.0 - 4.0)
		}

		// 2. Multi-Body Pin-to-Pin Collisions
		for j := 0; j < 10; j++ {
			if i == j { continue }
			mut p2 := &g.pins[j]

			dx := p2.x - p1.x
			dy := p2.y - p1.y
			dist := math.sqrt(dx * dx + dy * dy)
			min_dist := p1.radius + p2.radius

			if dist < min_dist && dist > 0.001 {
				nx := dx / dist
				ny := dy / dist

				rel_vx := p1.vx - p2.vx
				rel_vy := p1.vy - p2.vy
				rel_speed := rel_vx * nx + rel_vy * ny

				if rel_speed > 0.0 {
					// Elastic pin-to-pin impact
					impulse := (1.0 + 0.55) * rel_speed * (p1.mass * p2.mass) / (p1.mass + p2.mass)

					p1.vx -= (nx * impulse) / p1.mass
					p1.vy -= (ny * impulse) / p1.mass
					p2.vx += (nx * impulse) / p2.mass
					p2.vy += (ny * impulse) / p2.mass

					p2.v_tilt += (rel_speed / 45.0)
					p2.v_rot += (rand.f64() * 10.0 - 5.0)

					// Knock threshold: Requires significant impact energy to knock standing pin!
					if p2.standing && (rel_speed > 45.0 || p2.v_tilt > 1.8) {
						p2.standing = false
						p2.knocked = true
						sound_mgr.play_pin_hit(math.min(1.0, rel_speed / 250.0))
					} else if p2.standing {
						// Minor nudge: wobble
						p2.wobble = 0.28
						p2.wobble_t = 0.0
					}
				}
			}
		}
	}
}

pub fn (mut g BowlingGame) count_fallen_pins() int {
	mut count := 0
	for p in g.pins {
		if !p.standing {
			count++
		}
	}
	return count
}

fn (mut g BowlingGame) process_roll_results(mut sound_mgr SoundManager) {
	fallen := g.count_fallen_pins()
	mut p := &g.players[g.current_player]
	f_idx := p.current_frame

	if f_idx < 9 {
		// Standard Frames 1-9
		if p.current_roll == 0 {
			p.frames[f_idx].roll1 = fallen
			if fallen == 10 {
				// STRIKE!
				p.frames[f_idx].is_strike = true
				p.strikes++
				g.celebration = 'X  STRIKE!!'
				g.celeb_timer = 2.0
				sound_mgr.play_strike_fanfare()
				g.phase = .sweep
				g.sweep_y = 75.0
				return
			} else if fallen == 0 {
				g.celebration = '-  GUTTER BALL'
				g.celeb_timer = 2.0
			} else if fallen == 8 || fallen == 7 {
				// Check for split
				if g.is_split_standing() {
					g.celebration = 'SPLIT LEAVE!'
					g.celeb_timer = 2.0
				}
			}
			// Second roll setup
			g.phase = .sweep
			g.sweep_y = 75.0
		} else {
			// Second Roll
			prev_fallen := p.frames[f_idx].roll1
			this_roll := math.max(0, fallen - prev_fallen)
			p.frames[f_idx].roll2 = this_roll

			if fallen == 10 {
				// SPARE!
				p.frames[f_idx].is_spare = true
				p.spares++
				g.celebration = '/  SPARE!!'
				g.celeb_timer = 2.0
				sound_mgr.play_spare_fanfare()
			}
			g.calculate_cumulative_scores()
			g.phase = .frame_over
			g.state_timer = 0.0
		}
	} else {
		// 10th Frame (Special Rules)
		if p.current_roll == 0 {
			p.frames[9].roll1 = fallen
			if fallen == 10 {
				p.frames[9].is_strike = true
				p.strikes++
				g.celebration = 'X  STRIKE!!'
				g.celeb_timer = 2.0
				sound_mgr.play_strike_fanfare()
			}
			g.phase = .sweep
			g.sweep_y = 75.0
		} else if p.current_roll == 1 {
			prev_roll := p.frames[9].roll1
			if prev_roll == 10 {
				p.frames[9].roll2 = fallen
				if fallen == 10 {
					g.celebration = 'DOUBLE STRIKE!!'
					g.celeb_timer = 2.0
					sound_mgr.play_strike_fanfare()
				}
			} else {
				this_roll := math.max(0, fallen - prev_roll)
				p.frames[9].roll2 = this_roll
				if fallen == 10 {
					p.frames[9].is_spare = true
					p.spares++
					g.celebration = '/  SPARE!!'
					g.celeb_timer = 2.0
					sound_mgr.play_spare_fanfare()
				}
			}
			// Check if bonus 3rd roll is awarded
			if p.frames[9].roll1 == 10 || p.frames[9].is_spare || p.frames[9].roll2 == 10 {
				g.phase = .sweep
				g.sweep_y = 75.0
			} else {
				g.calculate_cumulative_scores()
				g.phase = .frame_over
				g.state_timer = 0.0
			}
		} else {
			// 3rd bonus roll
			p.frames[9].roll3 = fallen
			if fallen == 10 {
				g.celebration = 'TURKEY! 300 GLORY!!'
				g.celeb_timer = 2.0
				sound_mgr.play_strike_fanfare()
			}
			g.calculate_cumulative_scores()
			g.phase = .frame_over
			g.state_timer = 0.0
		}
	}
}

pub fn (g &BowlingGame) is_split_standing() bool {
	// 7-10 split: Pin 7 and Pin 10 standing without headpin
	mut pin1_down := false
	mut pin7_up := false
	mut pin10_up := false

	for p in g.pins {
		if p.id == 1 && !p.standing { pin1_down = true }
		if p.id == 7 && p.standing { pin7_up = true }
		if p.id == 10 && p.standing { pin10_up = true }
	}
	return pin1_down && pin7_up && pin10_up
}

fn (mut g BowlingGame) finish_sweep() {
	mut p := &g.players[g.current_player]
	f_idx := p.current_frame

	if f_idx < 9 {
		if p.frames[f_idx].is_strike || p.current_roll == 1 {
			// Clear all pins for next frame
			g.reset_pins()
			g.calculate_cumulative_scores()
			g.advance_turn()
		} else {
			// Roll 2: Remove fallen pins, leave standing pins on spot
			for mut pin in g.pins {
				if !pin.standing {
					pin.x = -999.0 // Move off lane
					pin.y = -999.0
				} else {
					// Stand upright on resting spot
					pin.x = pin.init_x
					pin.y = pin.init_y
					pin.vx = 0.0
					pin.vy = 0.0
					pin.tilt = 0.0
					pin.v_tilt = 0.0
					pin.wobble = 0.0
				}
			}
			p.current_roll = 1
			g.phase = .position
			g.reset_ball()
		}
	} else {
		// 10th frame sweeps
		if p.current_roll == 0 {
			if p.frames[9].is_strike {
				g.reset_pins()
			} else {
				for mut pin in g.pins {
					if !pin.standing {
						pin.x = -999.0
						pin.y = -999.0
					} else {
						pin.x = pin.init_x
						pin.y = pin.init_y
						pin.vx = 0.0
						pin.vy = 0.0
						pin.tilt = 0.0
					}
				}
			}
			p.current_roll = 1
			g.phase = .position
			g.reset_ball()
		} else if p.current_roll == 1 {
			g.reset_pins()
			p.current_roll = 2
			g.phase = .position
			g.reset_ball()
		}
	}
}

fn (mut g BowlingGame) advance_turn() {
	mut p := &g.players[g.current_player]

	if g.players.len > 1 {
		g.current_player = (g.current_player + 1) % g.players.len
		mut next_p := &g.players[g.current_player]
		if g.current_player == 0 {
			next_p.current_frame++
		}
	} else {
		p.current_frame++
	}

	p = &g.players[g.current_player]
	p.current_roll = 0

	if p.current_frame >= 10 {
		g.calculate_cumulative_scores()
		g.phase = .game_over
		g.celebration = 'MATCH FINISHED!'
		g.celeb_timer = 5.0
		return
	}

	g.reset_pins()
	g.reset_ball()
	g.phase = .position
}

pub fn (mut g BowlingGame) calculate_cumulative_scores() {
	for mut p in g.players {
		mut running_total := 0

		for f := 0; f < 10; f++ {
			mut frame := &p.frames[f]

			if f < 9 {
				if frame.is_strike {
					// Strike = 10 + next 2 rolls
					next_f := p.frames[f + 1]
					if next_f.roll1 != -1 {
						if next_f.is_strike {
							// Next frame was strike
							if f + 1 == 9 {
								// Frame 10 roll 2
								if next_f.roll2 != -1 {
									running_total += 10 + 10 + next_f.roll2
									frame.cumulative = running_total
								}
							} else {
								next_next_f := p.frames[f + 2]
								if next_next_f.roll1 != -1 {
									running_total += 10 + 10 + next_next_f.roll1
									frame.cumulative = running_total
								}
							}
						} else if next_f.roll2 != -1 {
							running_total += 10 + next_f.roll1 + next_f.roll2
							frame.cumulative = running_total
						}
					}
				} else if frame.is_spare {
					// Spare = 10 + next 1 roll
					next_f := p.frames[f + 1]
					if next_f.roll1 != -1 {
						running_total += 10 + next_f.roll1
						frame.cumulative = running_total
					}
				} else if frame.roll1 != -1 && frame.roll2 != -1 {
					// Open Frame
					running_total += frame.roll1 + frame.roll2
					frame.cumulative = running_total
				}
			} else {
				// 10th Frame
				if frame.roll1 != -1 && frame.roll2 != -1 {
					mut frame_10_sum := frame.roll1 + frame.roll2
					if frame.roll3 != -1 {
						frame_10_sum += frame.roll3
					}
					running_total += frame_10_sum
					frame.cumulative = running_total
				}
			}
		}
		p.total_score = running_total
	}
}

// AI Bowler Logic with authentic pocket targeting
fn (mut g BowlingGame) update_ai_aim(dt f64, mut _ SoundManager) {
	// AI targets the 1-3 pocket (X = 407.5) with left hook
	mut target_stance := 408.0
	match g.ai_diff {
		0 { target_stance = 398.0 + (rand.f64() * 24.0 - 12.0) } // Novice
		1 { target_stance = 406.0 + (rand.f64() * 8.0 - 4.0) }   // Pro
		else { target_stance = 407.5 + (rand.f64() * 2.0 - 1.0) } // Master
	}

	diff := target_stance - g.aim_x
	if math.abs(diff) > 2.0 {
		g.aim_x += (diff / math.abs(diff)) * 70.0 * dt
	} else {
		g.phase = .angle
	}
}

fn (mut g BowlingGame) update_ai_angle(_ f64, mut _ SoundManager) {
	g.aim_angle = -0.018 // Slight inward entry angle towards pocket
	g.phase = .power
}

fn (mut g BowlingGame) update_ai_power(_ f64, mut sound_mgr SoundManager) {
	g.power = 0.72 + (rand.f64() * 0.08 - 0.04)
	g.hook = 0.38
	g.launch_ball(mut sound_mgr)
}
