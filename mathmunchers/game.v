module main

import math
import rand

pub const grid_cols = 6
pub const grid_rows = 5

pub struct MathMunchersGame {
pub mut:
	state                   GameState  = .start_menu
	difficulty              Difficulty = .medium
	grid                    [][]Cell
	player                  Player
	troggles                []Troggle
	troggle_warnings        []TroggleWarning
	particles               []Particle
	floating_texts          []FloatingText
	bonus_stars             []BonusStar
	current_rule            RuleInfo
	level                   int = 1
	score                   int
	high_score              int
	troggle_spawn_timer     f64
	troggle_spawn_interval f64 = 6.0
	screen_shake_timer      f64
	freeze_timer            f64
	bonus_timer             f64
	message_timer           f64
	message_text            string
	global_anim_time        f64
	seed                    u32 = 12345
}

pub fn new_mathmunchers_game() MathMunchersGame {
	save_data := load_save_data()
	mut game := MathMunchersGame{
		high_score: save_data.high_score
		difficulty: save_data.difficulty
		grid:       [][]Cell{len: grid_rows, init: []Cell{len: grid_cols}}
	}
	game.start_new_game()
	game.state = .start_menu
	return game
}

pub fn is_prime(n int) bool {
	if n <= 1 {
		return false
	}
	if n <= 3 {
		return true
	}
	if n % 2 == 0 || n % 3 == 0 {
		return false
	}
	mut i := 5
	for i * i <= n {
		if n % i == 0 || n % (i + 2) == 0 {
			return false
		}
		i += 6
	}
	return true
}

pub fn evaluate_rule(val int, expr string, rule RuleInfo) bool {
	match rule.rule_type {
		.multiples {
			if rule.param <= 0 {
				return false
			}
			return val > 0 && val % rule.param == 0
		}
		.factors {
			if val <= 0 {
				return false
			}
			return rule.param % val == 0
		}
		.primes {
			return is_prime(val)
		}
		.equals {
			return val == rule.param
		}
		.greater_than {
			return val > rule.param
		}
		.less_than {
			return val < rule.param
		}
		.squares {
			if val < 0 {
				return false
			}
			sq := int(math.sqrt(val))
			return sq * sq == val
		}
	}
}

pub fn generate_rule_for_level(level int) RuleInfo {
	rule_idx := (level - 1) % 6
	match rule_idx {
		0 {
			param := 3 + (level * 2) % 7
			return RuleInfo{
				rule_type:   .multiples
				param:       param
				title:       'MULTIPLES OF ${param}'
				description: 'Eat numbers that divide evenly by ${param}'
			}
		}
		1 {
			param := 12 + (level * 6) % 37
			return RuleInfo{
				rule_type:   .factors
				param:       param
				title:       'FACTORS OF ${param}'
				description: 'Eat numbers that divide into ${param}'
			}
		}
		2 {
			return RuleInfo{
				rule_type:   .primes
				param:       0
				title:       'PRIME NUMBERS'
				description: 'Eat numbers greater than 1 with no other divisors'
			}
		}
		3 {
			target := 10 + (level * 2)
			return RuleInfo{
				rule_type:   .equals
				param:       target
				title:       'EQUALS ${target}'
				description: 'Eat expressions or numbers equal to ${target}'
			}
		}
		4 {
			target := 15 + (level * 3)
			return RuleInfo{
				rule_type:   .greater_than
				param:       target
				title:       'GREATER THAN ${target}'
				description: 'Eat numbers larger than ${target}'
			}
		}
		else {
			return RuleInfo{
				rule_type:   .squares
				param:       0
				title:       'SQUARE NUMBERS'
				description: 'Eat perfect square numbers (1, 4, 9, 16, 25...)'
			}
		}
	}
}

pub fn (g &MathMunchersGame) count_remaining_targets() int {
	mut count := 0
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			cell := &g.grid[r][c]
			if !cell.eaten && evaluate_rule(cell.value, cell.expr, g.current_rule) {
				count++
			}
		}
	}
	return count
}

pub fn (mut g MathMunchersGame) generate_expression(val int) string {
	if g.current_rule.rule_type == .equals && rand.intn(2) or { 0 } == 1 {
		op := rand.intn(3) or { 0 }
		match op {
			0 {
				a := rand.intn(val - 1) or { 1 } + 1
				b := val - a
				return '${a} + ${b}'
			}
			1 {
				diff := rand.intn(10) or { 1 } + 1
				a := val + diff
				return '${a} - ${diff}'
			}
			else {
				if val > 0 && val % 2 == 0 {
					a := val / 2
					return '${a} x 2'
				}
			}
		}
	}
	return '${val}'
}

pub fn (mut g MathMunchersGame) populate_grid() {
	mut target_count := 0
	target_needed := 10 + rand.intn(3) or { 2 }

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			mut is_tgt := false
			mut val := 0

			if target_count < target_needed && (rand.intn(100) or { 0 } < 45 || r * grid_cols + c >= (grid_rows * grid_cols - (target_needed - target_count))) {
				is_tgt = true
				target_count++
				val = g.generate_target_value()
			} else {
				val = g.generate_distractor_value()
			}

			mut ptype := PowerUpType.none
			if !is_tgt && rand.intn(15) or { 0 } == 0 {
				ptype = if rand.intn(2) or { 0 } == 0 { PowerUpType.freeze } else { PowerUpType.safe_zone }
			}

			expr := g.generate_expression(val)
			g.grid[r][c] = Cell{
				value:     val
				expr:      expr
				is_target: is_tgt
				eaten:     false
				power_up:  ptype
			}
		}
	}
}

fn (g MathMunchersGame) generate_target_value() int {
	match g.current_rule.rule_type {
		.multiples {
			p := if g.current_rule.param > 0 { g.current_rule.param } else { 3 }
			mult := rand.intn(10) or { 1 } + 1
			return p * mult
		}
		.factors {
			p := if g.current_rule.param > 0 { g.current_rule.param } else { 24 }
			mut factors := []int{}
			for i in 1 .. p + 1 {
				if p % i == 0 {
					factors << i
				}
			}
			if factors.len > 0 {
				idx := rand.intn(factors.len) or { 0 }
				return factors[idx]
			}
			return 1
		}
		.primes {
			primes := [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
			idx := rand.intn(primes.len) or { 0 }
			return primes[idx]
		}
		.equals {
			return g.current_rule.param
		}
		.greater_than {
			return g.current_rule.param + rand.intn(30) or { 1 } + 1
		}
		.less_than {
			if g.current_rule.param <= 1 {
				return 0
			}
			return rand.intn(g.current_rule.param) or { 0 }
		}
		.squares {
			base := rand.intn(9) or { 1 } + 1
			return base * base
		}
	}
}

fn (g MathMunchersGame) generate_distractor_value() int {
	for _ in 0 .. 100 {
		cand := rand.intn(60) or { 1 } + 1
		if !evaluate_rule(cand, '${cand}', g.current_rule) {
			return cand
		}
	}
	if g.current_rule.rule_type == .multiples && g.current_rule.param > 0 {
		return g.current_rule.param * 2 + 1
	}
	return g.current_rule.param + 1
}

pub fn (mut g MathMunchersGame) set_difficulty(d Difficulty) {
	g.difficulty = d
	save_data := SaveData{
		high_score:       g.high_score
		save_state_valid: true
		level:            g.level
		score:            g.score
		lives:            g.player.lives
		sound_enabled:    true
		difficulty:       g.difficulty
	}
	save_data_to_file(&save_data)
}

pub fn (mut g MathMunchersGame) cycle_difficulty() {
	next_diff := match g.difficulty {
		.easy { Difficulty.medium }
		.medium { Difficulty.hard }
		else { Difficulty.easy }
	}
	g.set_difficulty(next_diff)
}

pub fn (mut g MathMunchersGame) start_new_game() {
	g.score = 0
	g.level = 1
	starting_lives := match g.difficulty {
		.easy { 4 }
		.hard { 2 }
		else { 3 }
	}
	g.player = Player{
		grid_x:           0
		grid_y:           0
		real_x:           0.0
		real_y:           0.0
		lives:            starting_lives
		score:            0
		combo:            0
		extra_life_score: 10000
	}
	g.troggles.clear()
	g.troggle_warnings.clear()
	g.particles.clear()
	g.floating_texts.clear()
	g.bonus_stars.clear()
	g.current_rule = generate_rule_for_level(g.level)
	g.populate_grid()

	g.troggle_spawn_interval = match g.difficulty {
		.easy { 7.5 }
		.hard { 3.5 }
		else { 5.0 }
	}
	g.troggle_spawn_timer = 3.0
	g.state = .playing
}

pub fn (mut g MathMunchersGame) next_level() {
	g.level++
	g.player.grid_x = 0
	g.player.grid_y = 0
	g.player.real_x = 0.0
	g.player.real_y = 0.0
	g.player.combo = 0
	g.troggles.clear()
	g.troggle_warnings.clear()
	g.bonus_stars.clear()

	if (g.level - 1) % 3 == 0 && g.level > 1 {
		g.state = .bonus_round
		g.bonus_timer = 8.0
		return
	}

	g.current_rule = generate_rule_for_level(g.level)
	g.populate_grid()

	base_interval := match g.difficulty {
		.easy { 6.5 }
		.hard { 3.2 }
		else { 4.5 }
	}
	g.troggle_spawn_interval = math.max(2.0, base_interval - f64(g.level) * 0.3)
	g.troggle_spawn_timer = 2.0
	g.state = .playing
}

pub fn (mut g MathMunchersGame) add_score(pts int, mut sm SoundManager) {
	mult := match g.difficulty {
		.easy { 1.0 }
		.hard { 2.0 }
		else { 1.5 }
	}
	final_pts := int(f64(pts) * mult)
	g.score += final_pts

	if g.score >= g.player.extra_life_score {
		g.player.lives++
		g.player.extra_life_score += 10000
		g.floating_texts << FloatingText{
			x:     400.0
			y:     80.0
			text:  'EXTRA MUNCHER! +1 LIFE'
			color: Color{r: 255, g: 220, b: 50}
			life:  1.5
		}
		sm.play_sound('extralife')
	}
	if g.score > g.high_score {
		g.high_score = g.score
		save_data := SaveData{
			high_score:       g.high_score
			save_state_valid: true
			level:            g.level
			score:            g.score
			lives:            g.player.lives
			difficulty:       g.difficulty
		}
		save_data_to_file(&save_data)
	}
}

pub fn (mut g MathMunchersGame) munch_cell(mut sm SoundManager) {
	if g.state != .playing {
		return
	}
	px := g.player.grid_x
	py := g.player.grid_y
	if py < 0 || py >= grid_rows || px < 0 || px >= grid_cols {
		return
	}

	mut cell := &g.grid[py][px]
	if cell.eaten {
		return
	}

	g.player.munch_anim_timer = 0.35

	if cell.power_up == .freeze {
		g.freeze_timer = 5.0
		g.floating_texts << FloatingText{
			x:     f64(px * 122 + 90)
			y:     f64(py * 85 + 130)
			text:  'FREEZE!'
			color: Color{r: 100, g: 220, b: 255}
			life:  1.2
		}
		sm.play_sound('freeze')
	}

	is_correct := evaluate_rule(cell.value, cell.expr, g.current_rule)

	if is_correct {
		cell.eaten = true
		cell.flash_timer = 0.5
		cell.dissolve_timer = 0.5
		g.player.combo++
		points := 100 * g.player.combo
		g.add_score(points, mut sm)

		g.spawn_particles(f64(px * 122 + 100), f64(py * 85 + 155), Color{r: 50, g: 255, b: 120}, 25)
		g.spawn_particles(f64(px * 122 + 100), f64(py * 85 + 155), Color{r: 255, g: 220, b: 80}, 15)

		g.floating_texts << FloatingText{
			x:     f64(px * 122 + 90)
			y:     f64(py * 85 + 130)
			text:  '+${points}'
			color: Color{r: 100, g: 255, b: 140}
			life:  1.0
		}
		sm.play_sound('munch')

		if g.count_remaining_targets() == 0 {
			g.add_score(500 * g.level, mut sm)
			g.next_level()
			sm.play_sound('win')
		}
	} else {
		g.player.combo = 0
		g.player.lives--
		cell.is_wrong_flash = true
		cell.flash_timer = 0.6
		g.screen_shake_timer = 0.35
		g.spawn_particles(f64(px * 122 + 100), f64(py * 85 + 155), Color{r: 255, g: 60, b: 60}, 20)
		g.floating_texts << FloatingText{
			x:     f64(px * 122 + 90)
			y:     f64(py * 85 + 130)
			text:  'WRONG!'
			color: Color{r: 255, g: 80, b: 80}
			life:  1.0
		}
		sm.play_sound('wrong')

		if g.player.lives <= 0 {
			g.state = .game_over
			sm.play_sound('gameover')
		}
	}
}

pub fn (mut g MathMunchersGame) queue_troggle_warning() {
	max_troggles := match g.difficulty {
		.easy { 1 }
		.hard { 3 }
		else { 2 }
	}
	if g.troggles.len + g.troggle_warnings.len >= max_troggles {
		return
	}
	kind := match rand.intn(5) or { 0 } {
		0 { TroggleType.reggie }
		1 { TroggleType.smartie }
		2 { TroggleType.glutton }
		3 { TroggleType.bashful }
		else { TroggleType.helper }
	}
	tx := rand.intn(grid_cols) or { 0 }
	ty := if rand.intn(2) or { 0 } == 0 { 0 } else { grid_rows - 1 }
	g.troggle_warnings << TroggleWarning{
		grid_x:    tx
		grid_y:    ty
		timer:     1.5
		kind:      kind
		edge_side: if ty == 0 { 0 } else { 2 }
	}
}

pub fn (mut g MathMunchersGame) spawn_troggle_from_warning(w TroggleWarning) {
	base_interval := match g.difficulty {
		.easy { 2.4 }
		.hard { 1.2 }
		else { 1.8 }
	}
	g.troggles << Troggle{
		grid_x:        w.grid_x
		grid_y:        w.grid_y
		real_x:        f64(w.grid_x)
		real_y:        f64(w.grid_y)
		kind:          w.kind
		move_timer:    0.0
		move_interval: math.max(0.8, base_interval - f64(g.level) * 0.1)
		active:        true
	}
}

pub fn (mut g MathMunchersGame) update(dt f64, mut sm SoundManager) {
	g.global_anim_time += dt

	if g.screen_shake_timer > 0 {
		g.screen_shake_timer -= dt
	}
	if g.freeze_timer > 0 {
		g.freeze_timer -= dt
	}
	if g.player.munch_anim_timer > 0 {
		g.player.munch_anim_timer -= dt
	}
	if g.player.invincibility_timer > 0 {
		g.player.invincibility_timer -= dt
	}

	target_px := f64(g.player.grid_x)
	target_py := f64(g.player.grid_y)
	g.player.real_x += (target_px - g.player.real_x) * math.min(1.0, dt * 18.0)
	g.player.real_y += (target_py - g.player.real_y) * math.min(1.0, dt * 18.0)

	if g.state == .bonus_round {
		g.bonus_timer -= dt
		if rand.intn(15) or { 0 } == 0 {
			bx := 60.0 + rand.f64() * 680.0
			g.bonus_stars << BonusStar{
				x:     bx
				y:     100.0
				vy:    180.0 + rand.f64() * 120.0
				value: 200
			}
		}

		mut active_stars := []BonusStar{}
		for mut bs in g.bonus_stars {
			bs.y += bs.vy * dt
			m_pixel_x := 45.0 + g.player.real_x * 122.0 + 50.0
			if math.abs(bs.x - m_pixel_x) < 50.0 && bs.y >= 440.0 && bs.y <= 520.0 {
				g.add_score(bs.value, mut sm)
				g.spawn_particles(bs.x, bs.y, Color{r: 255, g: 230, b: 50}, 15)
				sm.play_sound('munch')
			} else if bs.y < 580.0 {
				active_stars << bs
			}
		}
		g.bonus_stars = active_stars

		if g.bonus_timer <= 0 {
			g.current_rule = generate_rule_for_level(g.level)
			g.populate_grid()
			g.state = .playing
		}
		return
	}

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if g.grid[r][c].flash_timer > 0 {
				g.grid[r][c].flash_timer -= dt
			}
			if g.grid[r][c].dissolve_timer > 0 {
				g.grid[r][c].dissolve_timer -= dt
			}
		}
	}

	mut active_particles := []Particle{}
	for mut p in g.particles {
		p.life -= dt
		if p.life > 0 {
			p.x += p.vx * dt
			p.y += p.vy * dt
			active_particles << p
		}
	}
	g.particles = active_particles

	mut active_texts := []FloatingText{}
	for mut ft in g.floating_texts {
		ft.life -= dt
		if ft.life > 0 {
			ft.y -= 30.0 * dt
			active_texts << ft
		}
	}
	g.floating_texts = active_texts

	if g.state != .playing {
		return
	}

	g.troggle_spawn_timer += dt
	if g.troggle_spawn_timer >= g.troggle_spawn_interval {
		g.troggle_spawn_timer = 0.0
		g.queue_troggle_warning()
		sm.play_sound('troggle')
	}

	mut active_warnings := []TroggleWarning{}
	for mut w in g.troggle_warnings {
		w.timer -= dt
		if w.timer <= 0 {
			g.spawn_troggle_from_warning(w)
		} else {
			active_warnings << w
		}
	}
	g.troggle_warnings = active_warnings

	if g.freeze_timer <= 0 {
		for i in 0 .. g.troggles.len {
			mut tr := &g.troggles[i]
			tr.move_timer += dt
			tr.anim_timer += dt

			t_target_x := f64(tr.grid_x)
			t_target_y := f64(tr.grid_y)
			tr.real_x += (t_target_x - tr.real_x) * math.min(1.0, dt * 12.0)
			tr.real_y += (t_target_y - tr.real_y) * math.min(1.0, dt * 12.0)

			if tr.move_timer >= tr.move_interval {
				tr.move_timer = 0.0
				tr.anim_frame = 1 - tr.anim_frame

				match tr.kind {
					.reggie {
						tr.grid_x = (tr.grid_x + 1) % grid_cols
						if !g.grid[tr.grid_y][tr.grid_x].eaten {
							new_val := g.generate_distractor_value()
							g.grid[tr.grid_y][tr.grid_x].value = new_val
							g.grid[tr.grid_y][tr.grid_x].expr = '${new_val}'
						}
					}
					.smartie {
						if tr.grid_x < g.player.grid_x {
							tr.grid_x++
						} else if tr.grid_x > g.player.grid_x {
							tr.grid_x--
						} else if tr.grid_y < g.player.grid_y {
							tr.grid_y++
						} else if tr.grid_y > g.player.grid_y {
							tr.grid_y--
						}
					}
					.glutton {
						dir := rand.intn(4) or { 0 }
						match dir {
							0 { tr.grid_x = math.min(grid_cols - 1, tr.grid_x + 1) }
							1 { tr.grid_x = math.max(0, tr.grid_x - 1) }
							2 { tr.grid_y = math.min(grid_rows - 1, tr.grid_y + 1) }
							else { tr.grid_y = math.max(0, tr.grid_y - 1) }
						}
						g.grid[tr.grid_y][tr.grid_x].eaten = true

						if g.count_remaining_targets() == 0 {
							g.add_score(500 * g.level, mut sm)
							g.next_level()
							sm.play_sound('win')
						}
					}
					.bashful {
						dist := math.abs(tr.grid_x - g.player.grid_x) + math.abs(tr.grid_y - g.player.grid_y)
						if dist <= 2 {
							if tr.grid_x < g.player.grid_x {
								tr.grid_x = math.max(0, tr.grid_x - 1)
							} else {
								tr.grid_x = math.min(grid_cols - 1, tr.grid_x + 1)
							}
						} else {
							if tr.grid_x < g.player.grid_x {
								tr.grid_x++
							} else if tr.grid_x > g.player.grid_x {
								tr.grid_x--
							}
						}
					}
					.helper {
						dir := rand.intn(4) or { 0 }
						match dir {
							0 { tr.grid_x = math.min(grid_cols - 1, tr.grid_x + 1) }
							1 { tr.grid_x = math.max(0, tr.grid_x - 1) }
							2 { tr.grid_y = math.min(grid_rows - 1, tr.grid_y + 1) }
							else { tr.grid_y = math.max(0, tr.grid_y - 1) }
						}
						if !evaluate_rule(g.grid[tr.grid_y][tr.grid_x].value, g.grid[tr.grid_y][tr.grid_x].expr,
							g.current_rule) {
							g.grid[tr.grid_y][tr.grid_x].eaten = true
						}
					}
				}

				if tr.kind != .helper && tr.grid_x == g.player.grid_x && tr.grid_y == g.player.grid_y {
					if g.player.invincibility_timer <= 0 {
						g.player.lives--
						g.player.combo = 0
						g.player.invincibility_timer = 2.0
						g.screen_shake_timer = 0.4
						sm.play_sound('hit')

						if g.player.lives <= 0 {
							g.state = .game_over
							sm.play_sound('gameover')
						}
					}
				}
			}
		}
	}

	sm.update_bgm(g.state == .playing)
}

fn (mut g MathMunchersGame) spawn_particles(x f64, y f64, color Color, count int) {
	for _ in 0 .. count {
		angle := rand.f64() * 2.0 * math.pi
		speed := 40.0 + rand.f64() * 140.0
		g.particles << Particle{
			x:        x
			y:        y
			vx:       math.cos(angle) * speed
			vy:       math.sin(angle) * speed
			color:    color
			life:     0.4 + rand.f64() * 0.4
			max_life: 0.8
			size:     3 + rand.intn(4) or { 1 }
		}
	}
}
