module main

import math
import rand

pub enum MicroType {
	defuse_bomb
	catch_gem
	dodge_laser
	arm_wrestle
	stop_needle
	unicycle_balance
	pattern_match
	pop_targets
}

pub enum GamePhase {
	title
	intermission
	playing
	round_result
	game_over
}

pub struct MicroMayhemGame {
pub mut:
	phase               GamePhase = .title
	lives               int = 4
	score               int
	streak              int
	games_cleared       int
	speed_multiplier    f64 = 1.0
	current_micro       MicroType = .defuse_bomb
	instruction         string
	game_timer          f64
	game_duration       f64 = 4.0
	intermission_timer  f64
	result_timer        f64
	is_success          bool
	is_finished         bool
	sound_event         string
	last_tick_sec       int = -1

	// Sub-game 1: Defuse Bomb
	bomb_target_wire    int // 0: Red, 1: Green, 2: Blue
	bomb_cut_wire       int = -1

	// Sub-game 2: Catch Gem
	gem_basket_x        f64 = 450.0
	gem_x               f64 = 450.0
	gem_y               f64 = 120.0
	gem_vy              f64 = 280.0
	gem_caught          bool

	// Sub-game 3: Dodge Laser
	player_lane         int = 1 // 0: Left, 1: Center, 2: Right
	laser_danger_lane   int // 0: Left, 1: Center, 2: Right

	// Sub-game 4: Arm Wrestle Mash
	wrestle_meter       f64 = 0.45 // 0.0 to 1.0 (win at >= 0.85)

	// Sub-game 5: Stop Needle
	needle_pos          f64 // 0.0 to 1.0
	needle_dir          f64 = 1.0
	needle_target_min   f64 = 0.4
	needle_target_max   f64 = 0.6
	needle_stopped      bool

	// Sub-game 6: Unicycle Balance
	unicycle_tilt       f64 // -1.0 to 1.0 (fails if |tilt| > 0.65)
	unicycle_vel        f64

	// Sub-game 7: Pattern Match
	pattern_seq         []int
	player_seq          []int

	// Sub-game 8: Pop Targets
	pop_targets_list    [][]f64 // [x, y, radius, popped (0 or 1)]
}

pub fn new_micromayhem_game() MicroMayhemGame {
	mut g := MicroMayhemGame{}
	g.reset()
	return g
}

pub fn (mut g MicroMayhemGame) reset() {
	g.phase = .title
	g.lives = 5
	g.score = 0
	g.streak = 0
	g.games_cleared = 0
	g.speed_multiplier = 1.0
	g.is_success = false
	g.is_finished = false
}

pub fn (mut g MicroMayhemGame) start_game() {
	g.lives = 5
	g.score = 0
	g.streak = 0
	g.games_cleared = 0
	g.speed_multiplier = 1.0
	g.intermission_timer = 1.5
	g.phase = .intermission
	g.sound_event = 'speedup'
}

pub fn (mut g MicroMayhemGame) next_microgame() {
	g.is_finished = false
	g.is_success = false
	g.last_tick_sec = -1

	// Smooth gradual speed ramp-up
	g.speed_multiplier = math.min(1.8, 1.0 + f64(g.games_cleared) * 0.035)
	g.game_duration = 5.5 / g.speed_multiplier
	g.game_timer = g.game_duration

	// Pick random microgame
	pick := rand.int_in_range(0, 8) or { 0 }
	g.current_micro = match pick {
		0 { MicroType.defuse_bomb }
		1 { MicroType.catch_gem }
		2 { MicroType.dodge_laser }
		3 { MicroType.arm_wrestle }
		4 { MicroType.stop_needle }
		5 { MicroType.unicycle_balance }
		6 { MicroType.pattern_match }
		else { MicroType.pop_targets }
	}

	// Initialize chosen microgame
	match g.current_micro {
		.defuse_bomb {
			g.bomb_target_wire = rand.int_in_range(0, 3) or { 0 }
			g.bomb_cut_wire = -1
			wire_name := match g.bomb_target_wire {
				0 { 'RED' }
				1 { 'GREEN' }
				else { 'BLUE' }
			}
			g.instruction = 'CUT ${wire_name} WIRE! [Click or 1-3]'
		}
		.catch_gem {
			g.gem_basket_x = 450.0
			g.gem_x = f64(rand.int_in_range(200, 740) or { 450 })
			g.gem_y = 100.0
			g.gem_vy = 180.0 * g.speed_multiplier
			g.gem_caught = false
			g.instruction = 'CATCH THE FALLING GEM! [Mouse or A/D]'
		}
		.dodge_laser {
			g.player_lane = 1
			g.laser_danger_lane = rand.int_in_range(0, 3) or { 1 }
			g.instruction = 'DODGE THE RED DANGER LANE! [A/D or Click]'
		}
		.arm_wrestle {
			g.wrestle_meter = 0.45
			g.instruction = 'MASH SPACE OR CLICK RAPIDLY!'
		}
		.stop_needle {
			g.needle_pos = 0.05
			g.needle_dir = 1.0
			target_w := 0.40 / math.sqrt(g.speed_multiplier)
			g.needle_target_min = 0.5 - target_w / 2.0
			g.needle_target_max = 0.5 + target_w / 2.0
			g.needle_stopped = false
			g.instruction = 'STOP NEEDLE IN GREEN ZONE! [Space / Click]'
		}
		.unicycle_balance {
			g.unicycle_tilt = if rand.f64() < 0.5 { 0.10 } else { -0.10 }
			g.unicycle_vel = 0
			g.instruction = 'BALANCE THE UNICYCLE! [A/D or Arrows]'
		}
		.pattern_match {
			g.pattern_seq.clear()
			g.player_seq.clear()
			for _ in 0 .. 3 {
				g.pattern_seq << rand.int_in_range(1, 4) or { 1 }
			}
			g.instruction = 'MEMORIZE & REPEAT PATTERN! [1-3 or Click]'
		}
		.pop_targets {
			g.pop_targets_list.clear()
			for i in 0 .. 3 {
				tx := 220.0 + f64(i) * 240.0 + rand.f64() * 40.0
				ty := 260.0 + rand.f64() * 100.0
				g.pop_targets_list << [tx, ty, 45.0, 0.0]
			}
			g.instruction = 'POP ALL 3 TARGETS! [Click or 1-3]'
		}
	}

	g.phase = .playing
}

pub fn (mut g MicroMayhemGame) update(dt f64, mx f64) {
	if g.phase == .intermission {
		g.intermission_timer -= dt
		if g.intermission_timer <= 0 {
			g.next_microgame()
		}
		return
	}

	if g.phase == .round_result {
		g.result_timer -= dt
		if g.result_timer <= 0 {
			if g.lives <= 0 {
				g.phase = .game_over
			} else {
				g.phase = .intermission
				g.intermission_timer = 1.0
			}
		}
		return
	}

	if g.phase != .playing {
		return
	}

	g.game_timer -= dt

	// Audio clock tick
	cur_sec := int(g.game_timer * 3.0)
	if cur_sec != g.last_tick_sec {
		g.last_tick_sec = cur_sec
		g.sound_event = 'tick'
	}

	// Update active microgame physics/state
	match g.current_micro {
		.catch_gem {
			g.gem_basket_x = math.clamp(mx, 120.0, 820.0)
			g.gem_y += g.gem_vy * dt
			// Check collision with basket at y = 480
			if g.gem_y >= 460.0 && g.gem_y <= 500.0 && !g.gem_caught {
				if math.abs(g.gem_x - g.gem_basket_x) < 65.0 {
					g.gem_caught = true
					g.is_success = true
					g.is_finished = true
				}
			}
			if g.gem_y > 520.0 && !g.gem_caught {
				g.is_success = false
				g.is_finished = true
			}
		}
		.arm_wrestle {
			// Gentle passive decay against player
			decay := (0.22 * g.speed_multiplier) * dt
			g.wrestle_meter = math.max(0.0, g.wrestle_meter - decay)
			if g.wrestle_meter >= 0.65 {
				g.is_success = true
				g.is_finished = true
			}
		}
		.stop_needle {
			if !g.needle_stopped {
				needle_speed := 1.15 * g.speed_multiplier
				g.needle_pos += g.needle_dir * needle_speed * dt
				if g.needle_pos >= 1.0 {
					g.needle_pos = 1.0
					g.needle_dir = -1.0
				} else if g.needle_pos <= 0.0 {
					g.needle_pos = 0.0
					g.needle_dir = 1.0
				}
			}
		}
		.unicycle_balance {
			// Gentle physics angular acceleration
			g.unicycle_vel += g.unicycle_tilt * 1.8 * dt
			g.unicycle_tilt += g.unicycle_vel * dt
			if math.abs(g.unicycle_tilt) > 0.85 {
				g.is_success = false
				g.is_finished = true
			}
		}
		.pop_targets {
			mut all_popped := true
			for t in g.pop_targets_list {
				if t[3] == 0.0 {
					all_popped = false
					break
				}
			}
			if all_popped {
				g.is_success = true
				g.is_finished = true
			}
		}
		else {}
	}

	// End of timer or game finished
	if g.game_timer <= 0 || g.is_finished {
		g.finish_microgame()
	}
}

pub fn (mut g MicroMayhemGame) finish_microgame() {
	if g.phase != .playing {
		return
	}

	// Evaluate success if not evaluated already
	match g.current_micro {
		.defuse_bomb {
			g.is_success = (g.bomb_cut_wire == g.bomb_target_wire)
		}
		.dodge_laser {
			g.is_success = (g.player_lane != g.laser_danger_lane)
		}
		.unicycle_balance {
			g.is_success = (math.abs(g.unicycle_tilt) <= 0.85)
		}
		.pattern_match {
			g.is_success = (g.player_seq.len == g.pattern_seq.len && g.player_seq == g.pattern_seq)
		}
		else {}
	}

	if g.is_success {
		g.score += int(100.0 * g.speed_multiplier) + g.streak * 25
		g.streak++
		g.games_cleared++
		g.sound_event = 'win'
	} else {
		g.lives--
		g.streak = 0
		g.sound_event = 'fail'
	}

	g.phase = .round_result
	g.result_timer = 1.2
}

pub fn (mut g MicroMayhemGame) handle_key_action(key int) {
	if g.phase != .playing {
		return
	}

	match g.current_micro {
		.defuse_bomb {
			if key == 1 || key == 2 || key == 3 {
				g.bomb_cut_wire = key - 1
				g.finish_microgame()
			}
		}
		.catch_gem {
			if key == -1 {
				g.gem_basket_x = math.max(120.0, g.gem_basket_x - 50.0)
			} else if key == 1 {
				g.gem_basket_x = math.min(820.0, g.gem_basket_x + 50.0)
			}
		}
		.dodge_laser {
			if key == -1 && g.player_lane > 0 {
				g.player_lane--
				g.sound_event = 'pop'
			} else if key == 1 && g.player_lane < 2 {
				g.player_lane++
				g.sound_event = 'pop'
			}
		}
		.arm_wrestle {
			if key == 0 { // Space mash
				g.wrestle_meter = math.min(1.0, g.wrestle_meter + 0.16)
				g.sound_event = 'pop'
			}
		}
		.stop_needle {
			if key == 0 && !g.needle_stopped {
				g.needle_stopped = true
				if g.needle_pos >= g.needle_target_min && g.needle_pos <= g.needle_target_max {
					g.is_success = true
				} else {
					g.is_success = false
				}
				g.is_finished = true
			}
		}
		.unicycle_balance {
			if key == -1 { // nudge left
				g.unicycle_vel -= 1.2
			} else if key == 1 { // nudge right
				g.unicycle_vel += 1.2
			}
		}
		.pattern_match {
			if key >= 1 && key <= 3 {
				g.player_seq << key
				g.sound_event = 'pop'
				if g.player_seq.len == g.pattern_seq.len {
					g.finish_microgame()
				}
			}
		}
		.pop_targets {
			if key >= 1 && key <= 3 {
				idx := key - 1
				if idx < g.pop_targets_list.len && g.pop_targets_list[idx][3] == 0.0 {
					g.pop_targets_list[idx][3] = 1.0
					g.sound_event = 'pop'
				}
			}
		}
	}
}

pub fn (mut g MicroMayhemGame) handle_click(mx f64, my f64) {
	if g.phase != .playing {
		return
	}

	match g.current_micro {
		.defuse_bomb {
			bx := 470.0
			by := 320.0
			for i in 0 .. 3 {
				wx := bx - 140.0 + f64(i) * 140.0
				wy := by + 120.0
				if mx >= wx - 50.0 && mx <= wx + 50.0 && my >= wy - 10.0 && my <= wy + 50.0 {
					g.handle_key_action(i + 1)
					break
				}
			}
		}
		.dodge_laser {
			lane_w := 260.0
			for lane in 0 .. 3 {
				lx := 80.0 + f64(lane) * lane_w
				if mx >= lx && mx <= lx + lane_w {
					g.player_lane = lane
					g.sound_event = 'pop'
					break
				}
			}
		}
		.arm_wrestle {
			g.handle_key_action(0)
		}
		.stop_needle {
			g.handle_key_action(0)
		}
		.pattern_match {
			for i in 0 .. 3 {
				px := 470.0 - 120.0 + f64(i) * 120.0
				if mx >= px - 35.0 && mx <= px + 35.0 && my >= 230.0 && my <= 300.0 {
					g.handle_key_action(i + 1)
					break
				}
			}
		}
		.pop_targets {
			for mut t in g.pop_targets_list {
				if t[3] == 0.0 {
					dx := mx - t[0]
					dy := my - t[1]
					if math.sqrt(dx * dx + dy * dy) <= t[2] + 15.0 {
						t[3] = 1.0
						g.sound_event = 'pop'
						break
					}
				}
			}
		}
		else {}
	}
}
