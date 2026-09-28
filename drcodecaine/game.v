module main

import math
import rand
import os



pub enum GameState {
	title
	options
	playing
	clearing_matches
	cascade_falling
	stage_clear
	paused
	game_over
}

pub enum PillColor {
	red
	yellow
	blue
}

pub enum CellType {
	empty
	virus
	pill_left
	pill_right
	pill_top
	pill_bottom
	pill_single
}

pub struct Cell {
pub mut:
	cell_type CellType = .empty
	color     PillColor = .red
	is_matched bool
}

pub enum PillOrientation {
	horizontal // (x, y) = c1 (left), (x+1, y) = c2 (right)
	vertical   // (x, y) = c1 (bottom), (x, y-1) = c2 (top)
}

pub struct ActivePill {
pub mut:
	x           int
	y           int
	c1          PillColor
	c2          PillColor
	orientation PillOrientation
}

pub struct Particle {
pub mut:
	x      f32
	y      f32
	vx     f32
	vy     f32
	color  Color
	life   f32
	size   f32
	active bool = true
}

pub struct ScorePopup {
pub mut:
	x      f32
	y      f32
	text   string
	color  Color
	timer  f32 = 0.8
	active bool = true
}

pub enum DropSpeed {
	low
	med
	hi
}

pub struct DrMarioGame {
pub mut:
	state          GameState = .title
	grid           [16][8]Cell
	active_pill    ActivePill
	has_active_pill bool
	next_c1        PillColor = .red
	next_c2        PillColor = .yellow
	// Hold / Stash Queue
	hold_c1        PillColor = .red
	hold_c2        PillColor = .yellow
	has_hold_pill  bool
	can_hold       bool = true
	// Features
	ghost_enabled  bool = true
	level          int // 0..20
	speed          DropSpeed = .med
	high_score     int       = 10000
	score          int
	viruses_left   int
	red_viruses    int
	yellow_viruses int
	blue_viruses   int
	drop_timer     f32
	chain_count    int
	anim_timer     f32
	state_timer    f32
	sound_mgr      SoundManager
	particles      []Particle
	score_popups   []ScorePopup
	screen_shake   f32
	pill_toss_progress f32
	stage_clear_timer  f32
	// Virus Animation Timers
	red_anim_timer     f32
	yellow_anim_timer  f32
	blue_anim_timer    f32
	crt_filter     bool = true
	// Textures
	sprite_texture &Texture = unsafe { nil }
	has_sprite_texture bool
	// Controls
	key_left       bool
	key_right      bool
	key_down       bool
	das_timer      f32
}

pub fn (mut g DrMarioGame) init_textures(renderer &Renderer) {
	paths := [
		'assets/sprites/drmario.png',
		'./assets/sprites/drmario.png',
		'../assets/sprites/drmario.png',
		'drmario/assets/sprites/drmario.png',
	]
	for p in paths {
		if os.exists(p) {
			g.sprite_texture = load_texture(renderer.ctx, p)
			if g.sprite_texture != unsafe { nil } && g.sprite_texture.valid {
				println('drmario Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn new_dr_mario_game() DrMarioGame {
	mut g := DrMarioGame{
		sound_mgr: new_sound_manager()
	}
	g.reset_to_title()
	return g
}

pub fn (mut g DrMarioGame) reset_to_title() {
	g.state = .title
	g.particles.clear()
	g.score_popups.clear()
	g.clear_grid()
}

pub fn (mut g DrMarioGame) clear_grid() {
	for r in 0 .. 16 {
		for c in 0 .. 8 {
			g.grid[r][c] = Cell{ cell_type: .empty }
		}
	}
	g.has_active_pill = false
}

pub fn (mut g DrMarioGame) start_game(level int, speed DropSpeed) {
	g.level = level
	g.speed = speed
	g.score = 0
	g.init_stage(level)
}

pub fn (mut g DrMarioGame) init_stage(level int) {
	g.clear_grid()
	g.state = .playing
	g.chain_count = 0
	g.drop_timer = 0.0
	g.particles.clear()
	g.score_popups.clear()

	// Number of viruses: (level + 1) * 4
	total_viruses := (level + 1) * 4
	g.viruses_left = total_viruses
	g.red_viruses = 0
	g.yellow_viruses = 0
	g.blue_viruses = 0

	// Generate viruses in lower 10 rows (rows 6..15)
	max_row := 15
	min_row := match level {
		0...3 { 10 }
		4...8 { 8 }
		9...14 { 6 }
		else { 4 }
	}

	mut placed := 0
	for placed < total_viruses {
		r := min_row + (rand.intn(max_row - min_row + 1) or { 0 })
		c := rand.intn(8) or { 0 }

		if g.grid[r][c].cell_type == .empty {
			v_color := match placed % 3 {
				0 { PillColor.red }
				1 { PillColor.yellow }
				else { PillColor.blue }
			}

			// Prevent accidental 3-in-a-row initial clusters
			if c >= 2 && g.grid[r][c - 1].cell_type == .virus && g.grid[r][c - 1].color == v_color
				&& g.grid[r][c - 2].cell_type == .virus && g.grid[r][c - 2].color == v_color {
				continue
			}
			if r <= 13 && g.grid[r + 1][c].cell_type == .virus && g.grid[r + 1][c].color == v_color
				&& g.grid[r + 2][c].cell_type == .virus && g.grid[r + 2][c].color == v_color {
				continue
			}

			g.grid[r][c] = Cell{
				cell_type: .virus
				color: v_color
			}
			match v_color {
				.red { g.red_viruses++ }
				.yellow { g.yellow_viruses++ }
				.blue { g.blue_viruses++ }
			}
			placed++
		}
	}

	g.randomize_next_pill()
	g.spawn_new_pill()
	g.count_viruses()
}

pub fn (mut g DrMarioGame) count_viruses() int {
	mut count := 0
	mut red := 0
	mut yellow := 0
	mut blue := 0
	for r in 0 .. 16 {
		for c in 0 .. 8 {
			if g.grid[r][c].cell_type == .virus {
				count++
				match g.grid[r][c].color {
					.red { red++ }
					.yellow { yellow++ }
					.blue { blue++ }
				}
			}
		}
	}
	g.viruses_left = count
	g.red_viruses = red
	g.yellow_viruses = yellow
	g.blue_viruses = blue
	return count
}

pub fn (mut g DrMarioGame) trigger_stage_clear() {
	if g.state == .stage_clear {
		return
	}
	g.viruses_left = 0
	g.red_viruses = 0
	g.yellow_viruses = 0
	g.blue_viruses = 0
	g.state = .stage_clear
	g.stage_clear_timer = 2.4
	g.has_active_pill = false
	g.sound_mgr.play_stage_clear()
	for i := 0; i < 40; i++ {
		color := match i % 3 {
			0 { Color{ r: 255, g: 60, b: 60, a: 255 } }
			1 { Color{ r: 255, g: 220, b: 40, a: 255 } }
			else { Color{ r: 60, g: 150, b: 255, a: 255 } }
		}
		g.add_particles(f32(320 + (i * 37) % 160), f32(140 + (i * 29) % 280), 3, color)
	}
}

pub fn (mut g DrMarioGame) randomize_next_pill() {
	g.next_c1 = match rand.intn(3) or { 0 } {
		0 { PillColor.red }
		1 { PillColor.yellow }
		else { PillColor.blue }
	}
	g.next_c2 = match rand.intn(3) or { 1 } {
		0 { PillColor.red }
		1 { PillColor.yellow }
		else { PillColor.blue }
	}
}

pub fn (mut g DrMarioGame) spawn_new_pill() {
	// Center at top: columns 3 and 4 at row 0
	if g.grid[0][3].cell_type != .empty || g.grid[0][4].cell_type != .empty {
		// Bottle overflowed to neck -> Game Over!
		g.state = .game_over
		g.sound_mgr.play_game_over()
		return
	}

	g.active_pill = ActivePill{
		x: 3
		y: 0
		c1: g.next_c1
		c2: g.next_c2
		orientation: .horizontal
	}
	g.has_active_pill = true
	g.can_hold = true
	g.pill_toss_progress = 0.0
	g.randomize_next_pill()
	g.chain_count = 0
}

pub fn (g &DrMarioGame) get_ghost_y() int {
	if !g.has_active_pill {
		return 0
	}
	p := g.active_pill
	mut test_y := p.y

	for {
		next_y := test_y + 1
		mut can_drop := false
		match p.orientation {
			.horizontal {
				if next_y < 16 && g.grid[next_y][p.x].cell_type == .empty && g.grid[next_y][p.x + 1].cell_type == .empty {
					can_drop = true
				}
			}
			.vertical {
				if next_y < 16 && g.grid[next_y][p.x].cell_type == .empty {
					can_drop = true
				}
			}
		}
		if can_drop {
			test_y = next_y
		} else {
			break
		}
	}
	return test_y
}

pub fn (mut g DrMarioGame) hard_drop() {
	if !g.has_active_pill || g.state != .playing {
		return
	}
	target_y := g.get_ghost_y()
	dropped_dist := target_y - g.active_pill.y
	g.active_pill.y = target_y
	g.score += dropped_dist * 2 // Hard drop distance bonus
	g.sound_mgr.play_hard_drop()
	g.screen_shake = 0.15

	// Impact landing particles
	hx := f32(310 + g.active_pill.x * 24 + 12)
	hy := f32(148 + target_y * 24 + 20)
	g.add_particles(hx, hy, 8, Color{ r: 240, g: 240, b: 255, a: 255 })

	g.lock_active_pill()
}

pub fn (mut g DrMarioGame) hold_current_pill() {
	if !g.has_active_pill || g.state != .playing || !g.can_hold {
		return
	}
	g.can_hold = false
	g.sound_mgr.play_hold()
	cur_c1 := g.active_pill.c1
	cur_c2 := g.active_pill.c2

	if !g.has_hold_pill {
		g.has_hold_pill = true
		g.hold_c1 = cur_c1
		g.hold_c2 = cur_c2
		g.spawn_new_pill()
		g.can_hold = false // Keep hold locked until newly spawned pill is locked
	} else {
		temp_c1 := g.hold_c1
		temp_c2 := g.hold_c2
		g.hold_c1 = cur_c1
		g.hold_c2 = cur_c2
		g.active_pill = ActivePill{
			x: 3
			y: 0
			c1: temp_c1
			c2: temp_c2
			orientation: .horizontal
		}
		g.can_hold = false
	}
}

pub fn (mut g DrMarioGame) get_drop_interval() f32 {
	return match g.speed {
		.low { 0.70 }
		.med { 0.45 }
		.hi { 0.22 }
	}
}

pub fn (mut g DrMarioGame) move_horizontal(dx int) {
	if !g.has_active_pill || g.state != .playing {
		return
	}

	p := g.active_pill
	new_x := p.x + dx

	match p.orientation {
		.horizontal {
			if dx < 0 {
				if new_x >= 0 && g.grid[p.y][new_x].cell_type == .empty {
					g.active_pill.x = new_x
				}
			} else {
				if new_x + 1 < 8 && g.grid[p.y][new_x + 1].cell_type == .empty {
					g.active_pill.x = new_x
				}
			}
		}
		.vertical {
			if new_x >= 0 && new_x < 8 {
				if g.grid[p.y][new_x].cell_type == .empty && (p.y == 0 || g.grid[p.y - 1][new_x].cell_type == .empty) {
					g.active_pill.x = new_x
				}
			}
		}
	}
}

pub fn (mut g DrMarioGame) rotate_pill(clockwise bool) {
	if !g.has_active_pill || g.state != .playing {
		return
	}

	mut p := g.active_pill

	if p.orientation == .horizontal {
		// Rotate to Vertical: bottom at (x, y), top at (x, y-1)
		// Needs (x, y-1) to be empty
		if p.y > 0 && g.grid[p.y - 1][p.x].cell_type == .empty {
			g.active_pill.orientation = .vertical
			if !clockwise {
				// Swap colors for CCW
				temp := g.active_pill.c1
				g.active_pill.c1 = g.active_pill.c2
				g.active_pill.c2 = temp
			}
			g.sound_mgr.play_rotate()
		}
	} else {
		// Rotate to Horizontal: left at (x, y), right at (x+1, y)
		if p.x + 1 < 8 && g.grid[p.y][p.x + 1].cell_type == .empty {
			g.active_pill.orientation = .horizontal
			if clockwise {
				temp := g.active_pill.c1
				g.active_pill.c1 = g.active_pill.c2
				g.active_pill.c2 = temp
			}
			g.sound_mgr.play_rotate()
		}
		// Wall kick left if at right boundary
		else if p.x == 7 && g.grid[p.y][6].cell_type == .empty {
			g.active_pill.x = 6
			g.active_pill.orientation = .horizontal
			if clockwise {
				temp := g.active_pill.c1
				g.active_pill.c1 = g.active_pill.c2
				g.active_pill.c2 = temp
			}
			g.sound_mgr.play_rotate()
		}
	}
}

pub fn (mut g DrMarioGame) lock_active_pill() {
	if !g.has_active_pill {
		return
	}
	p := g.active_pill

	match p.orientation {
		.horizontal {
			g.grid[p.y][p.x] = Cell{
				cell_type: .pill_left
				color: p.c1
			}
			g.grid[p.y][p.x + 1] = Cell{
				cell_type: .pill_right
				color: p.c2
			}
		}
		.vertical {
			g.grid[p.y][p.x] = Cell{
				cell_type: .pill_bottom
				color: p.c1
			}
			if p.y > 0 {
				g.grid[p.y - 1][p.x] = Cell{
					cell_type: .pill_top
					color: p.c2
				}
			}
		}
	}

	g.has_active_pill = false
	g.sound_mgr.play_drop()
	g.state = .clearing_matches
	g.state_timer = 0.15
}

pub fn (mut g DrMarioGame) check_and_clear_matches() bool {
	// Scan horizontal and vertical lines for 4+ consecutive segments of identical color
	mut matched := false

	// Clear matched flags
	for r in 0 .. 16 {
		for c in 0 .. 8 {
			g.grid[r][c].is_matched = false
		}
	}

	// 1. Horizontal Matches
	for r in 0 .. 16 {
		mut c := 0
		for c < 8 {
			if g.grid[r][c].cell_type == .empty {
				c++
				continue
			}
			cur_color := g.grid[r][c].color
			mut match_len := 1
			for check_c := c + 1; check_c < 8; check_c++ {
				if g.grid[r][check_c].cell_type != .empty && g.grid[r][check_c].color == cur_color {
					match_len++
				} else {
					break
				}
			}
			if match_len >= 4 {
				matched = true
				for k in 0 .. match_len {
					g.grid[r][c + k].is_matched = true
				}
			}
			c += match_len
		}
	}

	// 2. Vertical Matches
	for c in 0 .. 8 {
		mut r := 0
		for r < 16 {
			if g.grid[r][c].cell_type == .empty {
				r++
				continue
			}
			cur_color := g.grid[r][c].color
			mut match_len := 1
			for check_r := r + 1; check_r < 16; check_r++ {
				if g.grid[check_r][c].cell_type != .empty && g.grid[check_r][c].color == cur_color {
					match_len++
				} else {
					break
				}
			}
			if match_len >= 4 {
				matched = true
				for k in 0 .. match_len {
					g.grid[r + k][c].is_matched = true
				}
			}
			r += match_len
		}
	}

	if matched {
		g.chain_count++
		g.sound_mgr.play_match(g.chain_count)

		mut viruses_cleared := 0
		for r in 0 .. 16 {
			for c in 0 .. 8 {
				if g.grid[r][c].is_matched {
					cell := g.grid[r][c]
					if cell.cell_type == .virus {
						viruses_cleared++
						g.viruses_left--
						match cell.color {
							.red { g.red_viruses-- }
							.yellow { g.yellow_viruses-- }
							.blue { g.blue_viruses-- }
						}
						g.sound_mgr.play_virus_kill(cell.color, g.chain_count)
					}

					// Particle burst
					part_c := match cell.color {
						.red { Color{ r: 255, g: 60, b: 60, a: 255 } }
						.yellow { Color{ r: 255, g: 220, b: 40, a: 255 } }
						.blue { Color{ r: 60, g: 150, b: 255, a: 255 } }
					}
					g.add_particles(f32(300 + c * 24), f32(120 + r * 24), 8, part_c)

					// Decouple neighboring pill halves
					if cell.cell_type == .pill_left && c + 1 < 8 && g.grid[r][c + 1].cell_type == .pill_right && !g.grid[r][c + 1].is_matched {
						g.grid[r][c + 1].cell_type = .pill_single
					} else if cell.cell_type == .pill_right && c - 1 >= 0 && g.grid[r][c - 1].cell_type == .pill_left && !g.grid[r][c - 1].is_matched {
						g.grid[r][c - 1].cell_type = .pill_single
					} else if cell.cell_type == .pill_top && r + 1 < 16 && g.grid[r + 1][c].cell_type == .pill_bottom && !g.grid[r + 1][c].is_matched {
						g.grid[r + 1][c].cell_type = .pill_single
					} else if cell.cell_type == .pill_bottom && r - 1 >= 0 && g.grid[r - 1][c].cell_type == .pill_top && !g.grid[r - 1][c].is_matched {
						g.grid[r - 1][c].cell_type = .pill_single
					}

					g.grid[r][c] = Cell{ cell_type: .empty }
				}
			}
		}

		// Score Calculation
		pts := viruses_cleared * 100 * int(math.pow(2.0, f64(g.chain_count - 1)))
		if pts > 0 {
			g.score += pts
			g.add_score_popup(400.0, 200.0, '+${pts}', Color{ r: 255, g: 230, b: 60, a: 255 })
		}

		g.screen_shake = if g.chain_count > 1 { f32(0.35) } else { f32(0.20) }

		if g.count_viruses() == 0 {
			g.trigger_stage_clear()
		}
	}

	return matched
}

pub fn (mut g DrMarioGame) apply_gravity_step() bool {
	// Drop unsupported pills downwards by 1 row
	mut moved := false

	for r := 14; r >= 0; r-- {
		for c in 0 .. 8 {
			cell := g.grid[r][c]
			if cell.cell_type in [.pill_single, .pill_bottom] {
				if g.grid[r + 1][c].cell_type == .empty {
					g.grid[r + 1][c] = cell
					g.grid[r][c] = Cell{ cell_type: .empty }
					moved = true
				}
			} else if cell.cell_type == .pill_left {
				// Horizontal pair: only falls if BOTH columns below are empty
				if c + 1 < 8 && g.grid[r][c + 1].cell_type == .pill_right {
					if g.grid[r + 1][c].cell_type == .empty && g.grid[r + 1][c + 1].cell_type == .empty {
						g.grid[r + 1][c] = g.grid[r][c]
						g.grid[r + 1][c + 1] = g.grid[r][c + 1]
						g.grid[r][c] = Cell{ cell_type: .empty }
						g.grid[r][c + 1] = Cell{ cell_type: .empty }
						moved = true
					}
				}
			}
		}
	}

	return moved
}

pub fn (mut g DrMarioGame) add_particles(x f32, y f32, count int, color Color) {
	for _ in 0 .. count {
		angle := f32(rand.intn(360) or { 0 }) * f32(math.pi / 180.0)
		speed := 30.0 + f32(rand.intn(80) or { 40 })
		g.particles << Particle{
			x: x
			y: y
			vx: f32(math.cos(f64(angle))) * speed
			vy: f32(math.sin(f64(angle))) * speed
			color: color
			life: 0.3 + f32(rand.intn(20) or { 10 }) / 100.0
			size: 4.0 + f32(rand.intn(3) or { 1 })
			active: true
		}
	}
}

pub fn (mut g DrMarioGame) add_score_popup(x f32, y f32, text string, color Color) {
	g.score_popups << ScorePopup{
		x: x
		y: y
		text: text
		color: color
		timer: 0.8
		active: true
	}
}

pub fn (mut g DrMarioGame) update(dt f32) {
	g.anim_timer += dt * 5.0

	// BGM Streaming
	g.sound_mgr.update_bgm(g.state in [.playing, .clearing_matches, .cascade_falling])

	if g.screen_shake > 0.0 {
		g.screen_shake -= dt
	}
	if g.pill_toss_progress < 1.0 {
		g.pill_toss_progress += dt * 4.0
	}

	// Particle update
	for mut pt in g.particles {
		if !pt.active {
			continue
		}
		pt.life -= dt
		pt.x += pt.vx * dt
		pt.y += pt.vy * dt
		if pt.life <= 0.0 {
			pt.active = false
		}
	}

	// Score popup update
	for mut sp in g.score_popups {
		if !sp.active {
			continue
		}
		sp.timer -= dt
		sp.y -= 20.0 * dt
		if sp.timer <= 0.0 {
			sp.active = false
		}
	}

	g.particles = g.particles.filter(it.active)
	g.score_popups = g.score_popups.filter(it.active)

	if g.score > g.high_score {
		g.high_score = g.score
	}

	if g.state == .stage_clear {
		g.stage_clear_timer -= dt
		if g.stage_clear_timer <= 0.0 {
			g.next_level()
		}
		return
	}

	if g.state == .paused || g.state == .title || g.state == .game_over {
		return
	}

	// Check if all viruses have been eradicated
	if g.count_viruses() == 0 {
		g.trigger_stage_clear()
		return
	}

	// Handling Clears and Cascades
	if g.state == .clearing_matches {
		g.state_timer -= dt
		if g.state_timer <= 0.0 {
			matched := g.check_and_clear_matches()
			if g.count_viruses() == 0 {
				g.trigger_stage_clear()
				return
			}
			if matched {
				g.state = .cascade_falling
				g.state_timer = 0.12
			} else {
				g.state = .playing
				g.spawn_new_pill()
			}
		}
		return
	}

	if g.state == .cascade_falling {
		g.state_timer -= dt
		if g.state_timer <= 0.0 {
			g.state_timer = 0.10
			moved := g.apply_gravity_step()
			if !moved {
				if g.count_viruses() == 0 {
					g.trigger_stage_clear()
					return
				}
				// Re-check for matches caused by falling blocks
				g.state = .clearing_matches
				g.state_timer = 0.10
			}
		}
		return
	}

	// Active Pill Physics
	if g.has_active_pill && g.state == .playing {
		drop_interval := if g.key_down { 0.05 } else { g.get_drop_interval() }

		g.drop_timer += dt
		if g.drop_timer >= drop_interval {
			g.drop_timer = 0.0

			p := g.active_pill
			mut can_drop := false

			match p.orientation {
				.horizontal {
					if p.y + 1 < 16 && g.grid[p.y + 1][p.x].cell_type == .empty && g.grid[p.y + 1][p.x + 1].cell_type == .empty {
						can_drop = true
					}
				}
				.vertical {
					if p.y + 1 < 16 && g.grid[p.y + 1][p.x].cell_type == .empty {
						can_drop = true
					}
				}
			}

			if can_drop {
				g.active_pill.y++
			} else {
				g.lock_active_pill()
			}
		}
	}
}

pub fn (mut g DrMarioGame) next_level() {
	g.level++
	if g.level > 20 {
		g.level = 20
	}
	g.init_stage(g.level)
}
