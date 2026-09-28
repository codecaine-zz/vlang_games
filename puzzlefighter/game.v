module main

import rand

pub const pf_cols = 6
pub const pf_rows = 12
pub const max_colors = 4 // 1: Red, 2: Blue, 3: Green, 4: Yellow

pub enum GemNature {
	normal
	crash_orb  // Detonator for that color
	counter    // Countdown timer gem (e.g. 5, 4, 3, 2, 1 -> normal)
	diamond    // Clears all gems of the color it touches
}

pub struct GemCell {
pub mut:
	color     int       // 1..4 (0 is empty)
	nature    GemNature = .normal
	timer     int       // For counter gems (5..0)
	power_id  int       // ID of giant power block (0 if regular)
	power_w   int       // 1, 2, 3
	power_h   int       // 1, 2, 3
}

pub struct GemPair {
pub mut:
	c1     int = 2
	r1     f64 = -1.0
	color1 int
	nat1   GemNature = .normal

	c2     int = 2
	r2     f64 = -2.0
	color2 int
	nat2   GemNature = .normal

	rot    int // 0: sub is above (r2=r1-1, c2=c1), 1: sub is right (r2=r1, c2=c1+1), 2: sub is below, 3: sub is left
}

pub enum BoardState {
	falling
	clearing
	settling
	game_over
}

pub struct Pos {
pub:
	r int
	c int
}

pub struct PlayerBoard {
pub mut:
	grid             [12][6]GemCell
	pair             GemPair
	next_pair        GemPair
	state            BoardState = .falling
	score            int
	chain_count      int
	pending_garbage  int
	clearing_cells   []Pos
	clear_timer      f64
	fall_speed       f64 = 2.0
	is_cpu           bool
	cpu_timer        f64
	target_c         int = 2
	target_rot       int
}

pub fn new_gem_pair() GemPair {
	c1 := rand.int_in_range(1, max_colors + 1) or { 1 }
	c2 := rand.int_in_range(1, max_colors + 1) or { 2 }

	// 20% chance of a Crash Orb
	mut nat1 := GemNature.normal
	if rand.int_in_range(0, 5) or { 0 } == 0 {
		nat1 = .crash_orb
	}
	mut nat2 := GemNature.normal
	if rand.int_in_range(0, 5) or { 0 } == 0 {
		nat2 = .crash_orb
	}

	return GemPair{
		c1: 2, r1: 0.0, color1: c1, nat1: nat1
		c2: 2, r2: -1.0, color2: c2, nat2: nat2
		rot: 0
	}
}

pub fn new_player_board(is_cpu bool) PlayerBoard {
	mut pb := PlayerBoard{
		is_cpu: is_cpu
	}
	pb.pair = new_gem_pair()
	pb.next_pair = new_gem_pair()
	return pb
}

pub fn (mut pb PlayerBoard) spawn_pair() bool {
	// Spawn at column 2 (or 3)
	if pb.grid[0][2].color != 0 {
		pb.state = .game_over
		return false
	}

	pb.pair = pb.next_pair
	pb.pair.c1 = 2
	pb.pair.r1 = 0.0
	pb.pair.rot = 0
	pb.update_sub_coords()

	pb.next_pair = new_gem_pair()
	pb.state = .falling
	pb.chain_count = 0

	// If CPU, pick best placement target
	if pb.is_cpu {
		pb.cpu_plan_move()
	}
	return true
}

pub fn (mut pb PlayerBoard) update_sub_coords() {
	c1 := pb.pair.c1
	r1 := pb.pair.r1
	match pb.pair.rot {
		0 { // Sub above
			pb.pair.c2 = c1
			pb.pair.r2 = r1 - 1.0
		}
		1 { // Sub right
			pb.pair.c2 = c1 + 1
			pb.pair.r2 = r1
		}
		2 { // Sub below
			pb.pair.c2 = c1
			pb.pair.r2 = r1 + 1.0
		}
		3 { // Sub left
			pb.pair.c2 = c1 - 1
			pb.pair.r2 = r1
		}
		else {}
	}
}

pub fn (mut pb PlayerBoard) rotate(dir int) bool {
	if pb.state != .falling {
		return false
	}
	new_rot := (pb.pair.rot + dir + 4) % 4
	c1 := pb.pair.c1
	mut new_c1 := c1

	// Wall kicks
	if new_rot == 1 && c1 == pf_cols - 1 { // Rotating sub right at right wall
		new_c1 = pf_cols - 2
	} else if new_rot == 3 && c1 == 0 { // Rotating sub left at left wall
		new_c1 = 1
	}

	pb.pair.c1 = new_c1
	pb.pair.rot = new_rot
	pb.update_sub_coords()
	return true
}

pub fn (mut pb PlayerBoard) move_pair(dir int) bool {
	if pb.state != .falling {
		return false
	}
	target_c1 := pb.pair.c1 + dir
	target_c2 := pb.pair.c2 + dir

	if target_c1 < 0 || target_c1 >= pf_cols || target_c2 < 0 || target_c2 >= pf_cols {
		return false
	}

	// Check collision with existing blocks
	if pb.pair.r1 >= 0 && pb.grid[int(pb.pair.r1)][target_c1].color != 0 {
		return false
	}
	if pb.pair.r2 >= 0 && pb.grid[int(pb.pair.r2)][target_c2].color != 0 {
		return false
	}

	pb.pair.c1 = target_c1
	pb.pair.c2 = target_c2
	return true
}

pub fn (mut pb PlayerBoard) hard_drop() {
	if pb.state != .falling {
		return
	}
	land1 := pb.get_landing_row(pb.pair.c1)
	land2 := pb.get_landing_row(pb.pair.c2)
	match pb.pair.rot {
		0 {
			pb.pair.r1 = f64(land1)
			pb.pair.r2 = f64(land1 - 1)
		}
		2 {
			pb.pair.r1 = f64(land1 - 1)
			pb.pair.r2 = f64(land1)
		}
		else {
			min_r := if land1 < land2 { land1 } else { land2 }
			pb.pair.r1 = f64(min_r)
			pb.pair.r2 = f64(min_r)
		}
	}
	pb.lock_pair()
}

pub fn (pb PlayerBoard) get_landing_row(c int) int {
	for r in 0 .. pf_rows {
		if pb.grid[r][c].color != 0 {
			return r - 1
		}
	}
	return pf_rows - 1
}

// Lock pair into board
pub fn (mut pb PlayerBoard) lock_pair() int {
	c1 := pb.pair.c1
	c2 := pb.pair.c2

	if c1 == c2 {
		// Vertical alignment
		land_r := pb.get_landing_row(c1)
		if land_r < 1 {
			pb.state = .game_over
			return 0
		}
		if pb.pair.rot == 0 { // Sub is above Main
			pb.grid[land_r][c1] = GemCell{color: pb.pair.color1, nature: pb.pair.nat1}
			pb.grid[land_r - 1][c1] = GemCell{color: pb.pair.color2, nature: pb.pair.nat2}
		} else { // Sub is below Main (rot == 2)
			pb.grid[land_r][c1] = GemCell{color: pb.pair.color2, nature: pb.pair.nat2}
			pb.grid[land_r - 1][c1] = GemCell{color: pb.pair.color1, nature: pb.pair.nat1}
		}
	} else {
		// Horizontal alignment
		land1 := pb.get_landing_row(c1)
		land2 := pb.get_landing_row(c2)
		if land1 < 0 || land2 < 0 {
			pb.state = .game_over
			return 0
		}
		pb.grid[land1][c1] = GemCell{color: pb.pair.color1, nature: pb.pair.nat1}
		pb.grid[land2][c2] = GemCell{color: pb.pair.color2, nature: pb.pair.nat2}
	}

	// Decrement counter timers on board
	for r in 0 .. pf_rows {
		for c in 0 .. pf_cols {
			if pb.grid[r][c].nature == .counter {
				pb.grid[r][c].timer--
				if pb.grid[r][c].timer <= 0 {
					pb.grid[r][c].nature = .normal
				}
			}
		}
	}

	pb.detect_power_fusions()
	return pb.check_crash_detonations()
}

// Detect and tag 2x2 giant power gem fusions
pub fn (mut pb PlayerBoard) detect_power_fusions() {
	mut pid := 1
	for r in 0 .. pf_rows - 1 {
		for c in 0 .. pf_cols - 1 {
			col := pb.grid[r][c].color
			if col != 0 && pb.grid[r][c].nature == .normal {
				if pb.grid[r][c + 1].color == col && pb.grid[r + 1][c].color == col && pb.grid[r + 1][c + 1].color == col &&
				   pb.grid[r][c + 1].nature == .normal && pb.grid[r + 1][c].nature == .normal && pb.grid[r + 1][c + 1].nature == .normal {
					pb.grid[r][c].power_id = pid
					pb.grid[r][c + 1].power_id = pid
					pb.grid[r + 1][c].power_id = pid
					pb.grid[r + 1][c + 1].power_id = pid
					pid++
				}
			}
		}
	}
}

// Find and explode any gems triggered by Crash Orbs
pub fn (mut pb PlayerBoard) check_crash_detonations() int {
	mut matched := [12][6]bool{}
	mut found := false

	for r in 0 .. pf_rows {
		for c in 0 .. pf_cols {
			cell := pb.grid[r][c]
			if cell.color != 0 && cell.nature == .crash_orb {
				// Find all connected gems of same color using flood fill
				mut visited := [12][6]bool{}
				mut queue := [Pos{r: r, c: c}]
				visited[r][c] = true
				mut cluster := []Pos{}

				for queue.len > 0 {
					p := queue.pop()
					cluster << p
					neighbors := [
						Pos{r: p.r - 1, c: p.c},
						Pos{r: p.r + 1, c: p.c},
						Pos{r: p.r, c: p.c - 1},
						Pos{r: p.r, c: p.c + 1},
					]
					for nb in neighbors {
						if nb.r >= 0 && nb.r < pf_rows && nb.c >= 0 && nb.c < pf_cols {
							if !visited[nb.r][nb.c] && pb.grid[nb.r][nb.c].color == cell.color {
								visited[nb.r][nb.c] = true
								queue << nb
							}
						}
					}
				}

				if cluster.len > 1 {
					found = true
					for p in cluster {
						matched[p.r][p.c] = true
					}
				}
			}
		}
	}

	if found {
		mut pos_list := []Pos{}
		for r in 0 .. pf_rows {
			for c in 0 .. pf_cols {
				if matched[r][c] {
					pos_list << Pos{r: r, c: c}
				}
			}
		}
		pb.clearing_cells = pos_list
		pb.chain_count++
		pb.state = .clearing
		pb.clear_timer = 0.35
		return pos_list.len
	} else {
		pb.apply_garbage_drop()
		pb.spawn_pair()
		return 0
	}
}

// Clear detonated cells and apply gravity
pub fn (mut pb PlayerBoard) apply_clearing() int {
	count := pb.clearing_cells.len
	for p in pb.clearing_cells {
		pb.grid[p.r][p.c] = GemCell{}
	}
	pb.clearing_cells.clear()

	points := count * 100 * pb.chain_count
	pb.score += points

	// Calculate garbage sent to opponent
	garbage_units := (count / 2) * pb.chain_count

	pb.apply_gravity()
	pb.detect_power_fusions()

	// Check if settling triggers further crash explosions
	next_detonations := pb.check_crash_detonations()
	if next_detonations > 0 {
		return garbage_units + (next_detonations / 2) * pb.chain_count
	}
	return garbage_units
}

pub fn (mut pb PlayerBoard) apply_gravity() bool {
	mut moved := false
	for c in 0 .. pf_cols {
		mut write_r := pf_rows - 1
		for r := pf_rows - 1; r >= 0; r-- {
			if pb.grid[r][c].color != 0 {
				if r != write_r {
					pb.grid[write_r][c] = pb.grid[r][c]
					pb.grid[r][c] = GemCell{}
					moved = true
				}
				write_r--
			}
		}
	}
	return moved
}

// Receive incoming garbage from opponent
pub fn (mut pb PlayerBoard) receive_garbage(units int) {
	pb.pending_garbage += units
}

// Drop pending garbage as counter gems from top
pub fn (mut pb PlayerBoard) apply_garbage_drop() {
	if pb.pending_garbage <= 0 {
		return
	}
	drops := if pb.pending_garbage > 12 { 12 } else { pb.pending_garbage }
	pb.pending_garbage -= drops

	for i in 0 .. drops {
		c := i % pf_cols
		land := pb.get_landing_row(c)
		if land >= 0 {
			col := rand.int_in_range(1, max_colors + 1) or { 1 }
			pb.grid[land][c] = GemCell{
				color: col
				nature: .counter
				timer: 5
			}
		}
	}
}

// AI Heuristic Decision for CPU player
pub fn (mut pb PlayerBoard) cpu_plan_move() {
	mut best_score := -999999
	mut best_c := 2
	mut best_rot := 0

	// Test all valid rotations and columns
	for rot in 0 .. 4 {
		for c in 0 .. pf_cols {
			// Determine sub gem column based on rotation
			mut c2 := c
			match rot {
				1 { c2 = c + 1 }
				3 { c2 = c - 1 }
				else {}
			}

			// Validate horizontal bounds
			if c2 < 0 || c2 >= pf_cols {
				continue
			}

			// Determine landing rows for gem 1 and gem 2
			mut r1 := 0
			mut r2 := 0

			if c == c2 {
				// Vertical orientation
				land := pb.get_landing_row(c)
				if land < 1 {
					continue // Column is full or overflow
				}
				if rot == 0 { // Gem 2 is above Gem 1
					r1 = land
					r2 = land - 1
				} else { // Gem 1 is above Gem 2 (rot == 2)
					r2 = land
					r1 = land - 1
				}
			} else {
				// Horizontal orientation
				land1 := pb.get_landing_row(c)
				land2 := pb.get_landing_row(c2)
				if land1 < 0 || land2 < 0 {
					continue
				}
				r1 = land1
				r2 = land2
			}

			mut score := 0

			// 1. Crash Orb detonating adjacent same-color gems
			if pb.pair.nat1 == .crash_orb {
				mut detonates := false
				for d in [[-1, 0], [1, 0], [0, -1], [0, 1]] {
					nr := r1 + d[0]
					nc := c + d[1]
					if nr >= 0 && nr < pf_rows && nc >= 0 && nc < pf_cols {
						if pb.grid[nr][nc].color == pb.pair.color1 {
							detonates = true
							break
						}
					}
				}
				if detonates {
					score += 800
				} else {
					score -= 60
				}
			} else {
				// Normal gem: reward clustering same colors
				for d in [[-1, 0], [1, 0], [0, -1], [0, 1]] {
					nr := r1 + d[0]
					nc := c + d[1]
					if nr >= 0 && nr < pf_rows && nc >= 0 && nc < pf_cols {
						if pb.grid[nr][nc].color == pb.pair.color1 {
							score += 90
						}
					}
				}
			}

			if pb.pair.nat2 == .crash_orb {
				mut detonates := false
				for d in [[-1, 0], [1, 0], [0, -1], [0, 1]] {
					nr := r2 + d[0]
					nc := c2 + d[1]
					if nr >= 0 && nr < pf_rows && nc >= 0 && nc < pf_cols {
						if pb.grid[nr][nc].color == pb.pair.color2 {
							detonates = true
							break
						}
					}
				}
				if detonates {
					score += 800
				} else {
					score -= 60
				}
			} else {
				// Normal gem: reward clustering same colors
				for d in [[-1, 0], [1, 0], [0, -1], [0, 1]] {
					nr := r2 + d[0]
					nc := c2 + d[1]
					if nr >= 0 && nr < pf_rows && nc >= 0 && nc < pf_cols {
						if pb.grid[nr][nc].color == pb.pair.color2 {
							score += 90
						}
					}
				}
			}

			// 2. Bonus if gem 1 and gem 2 are same color and placed together
			if pb.pair.color1 == pb.pair.color2 && pb.pair.nat1 == .normal && pb.pair.nat2 == .normal {
				score += 60
			}

			// 3. Keep column height low and safe, especially spawn column 2
			min_land := if r1 < r2 { r1 } else { r2 }
			score -= (pf_rows - min_land) * 12
			if c == 2 || c2 == 2 {
				if min_land < 3 {
					score -= 600 // DANGER: Spawn column almost blocked!
				}
			}

			if score > best_score {
				best_score = score
				best_c = c
				best_rot = rot
			}
		}
	}
	pb.target_c = best_c
	pb.target_rot = best_rot
}

pub fn (mut pb PlayerBoard) update(dt f64) int {
	mut garbage_sent := 0
	match pb.state {
		.falling {
			if pb.is_cpu {
				pb.cpu_timer += dt
				if pb.cpu_timer > 0.15 {
					pb.cpu_timer = 0
					if pb.pair.rot != pb.target_rot {
						pb.rotate(1)
					} else if pb.pair.c1 < pb.target_c {
						pb.move_pair(1)
					} else if pb.pair.c1 > pb.target_c {
						pb.move_pair(-1)
					}
				}
			}

			pb.pair.r1 += pb.fall_speed * dt
			pb.update_sub_coords()

			land1 := pb.get_landing_row(pb.pair.c1)
			land2 := pb.get_landing_row(pb.pair.c2)

			if int(pb.pair.r1) >= land1 || int(pb.pair.r2) >= land2 {
				pb.lock_pair()
			}
		}
		.clearing {
			pb.clear_timer -= dt
			if pb.clear_timer <= 0 {
				garbage_sent = pb.apply_clearing()
			}
		}
		.settling {
			pb.apply_gravity()
			pb.check_crash_detonations()
		}
		.game_over {}
	}
	return garbage_sent
}
