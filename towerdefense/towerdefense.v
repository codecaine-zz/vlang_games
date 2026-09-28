module main

import math
import rand

const grid_cols = 15
const grid_rows = 11
const tile_size = 40
const offset_x = 100
const offset_y = 80

enum GameState {
	menu
	playing
	paused
	game_over
	victory
}

enum TurretType {
	laser
	cannon
	frost
}

enum CreepType {
	normal
	scout
	tank
	boss
}

struct Point {
	x f32
	y f32
}

struct Creep {
mut:
	id          int
	creep_type  CreepType
	x           f32
	y           f32
	waypoint_idx int
	speed       f32
	hp          f32
	max_hp      f32
	reward      int
	slow_timer  f32
	active      bool = true
}

struct Turret {
mut:
	grid_x     int
	grid_y     int
	turret_type TurretType
	level      int = 1
	range      f32
	damage     f32
	cooldown   f32
	max_cooldown f32
	target_id  int = -1
	target_x   f32
	target_y   f32
}

struct TowerDefenseGame {
mut:
	state          GameState = .menu
	score          int
	high_score     int = 5000
	wave           int = 1
	lives          int = 10
	gold           int = 350
	selected_gx    int = 7
	selected_gy    int = 5
	selected_type  TurretType = .laser
	waypoints      []Point
	path_grid      [][]bool
	turrets        []Turret
	creeps         []Creep
	sound_mgr      SoundManager
	wave_timer     f32
	spawn_timer    f32
	creeps_left    int = 10
	toast_msg      string
	toast_timer    f32
}

fn new_towerdefense_game() TowerDefenseGame {
	mut g := TowerDefenseGame{
		sound_mgr: new_sound_manager()
	}
	saved := load_td_save()
	if saved.high_score > 0 {
		g.high_score = saved.high_score
	}
	g.reset_game()
	return g
}

fn (mut g TowerDefenseGame) reset_game() {
	g.score = 0
	g.wave = 1
	g.lives = 10
	g.gold = 350
	g.init_waypoints()
	g.turrets.clear()
	g.start_wave()
	g.state = .playing
}

fn (mut g TowerDefenseGame) init_waypoints() {
	g.waypoints = [
		Point{ x: f32(offset_x + 0 * tile_size + 20), y: f32(offset_y + 2 * tile_size + 20) },
		Point{ x: f32(offset_x + 5 * tile_size + 20), y: f32(offset_y + 2 * tile_size + 20) },
		Point{ x: f32(offset_x + 5 * tile_size + 20), y: f32(offset_y + 8 * tile_size + 20) },
		Point{ x: f32(offset_x + 10 * tile_size + 20), y: f32(offset_y + 8 * tile_size + 20) },
		Point{ x: f32(offset_x + 10 * tile_size + 20), y: f32(offset_y + 2 * tile_size + 20) },
		Point{ x: f32(offset_x + 14 * tile_size + 20), y: f32(offset_y + 2 * tile_size + 20) },
		Point{ x: f32(offset_x + 14 * tile_size + 20), y: f32(offset_y + 9 * tile_size + 20) },
	]

	// Mark path tiles in grid
	g.path_grid = [][]bool{len: grid_rows, init: []bool{len: grid_cols, init: false}}

	for i in 0 .. g.waypoints.len - 1 {
		p1 := g.waypoints[i]
		p2 := g.waypoints[i + 1]

		gx1 := int((p1.x - f32(offset_x)) / f32(tile_size))
		gy1 := int((p1.y - f32(offset_y)) / f32(tile_size))
		gx2 := int((p2.x - f32(offset_x)) / f32(tile_size))
		gy2 := int((p2.y - f32(offset_y)) / f32(tile_size))

		min_x := if gx1 < gx2 { gx1 } else { gx2 }
		max_x := if gx1 > gx2 { gx1 } else { gx2 }
		min_y := if gy1 < gy2 { gy1 } else { gy2 }
		max_y := if gy1 > gy2 { gy1 } else { gy2 }

		for r in min_y .. max_y + 1 {
			for c in min_x .. max_x + 1 {
				if r >= 0 && r < grid_rows && c >= 0 && c < grid_cols {
					g.path_grid[r][c] = true
				}
			}
		}
	}
}

fn (mut g TowerDefenseGame) start_wave() {
	g.creeps.clear()
	g.creeps_left = 8 + g.wave * 4
	g.spawn_timer = 0.0
}

fn (mut g TowerDefenseGame) update(dt f32) {
	if g.state != .playing { return }

	// 1. Spawn Creeps
	if g.creeps_left > 0 {
		g.spawn_timer -= dt
		if g.spawn_timer <= 0 {
			g.spawn_timer = 1.0 - f32(g.wave) * 0.05
			if g.spawn_timer < 0.35 { g.spawn_timer = 0.35 }

			g.spawn_creep()
			g.creeps_left--
		}
	}

	// 2. Update Creeps
	mut active_creeps := 0
	for mut c in g.creeps {
		if !c.active { continue }
		active_creeps++

		if c.slow_timer > 0 {
			c.slow_timer -= dt
		}

		current_speed := if c.slow_timer > 0 { c.speed * 0.5 } else { c.speed }

		// Move towards current waypoint
		target_wp := g.waypoints[c.waypoint_idx]
		dx := target_wp.x - c.x
		dy := target_wp.y - c.y
		dist := f32(math.sqrt(dx * dx + dy * dy))

		if dist < 6.0 {
			c.waypoint_idx++
			if c.waypoint_idx >= g.waypoints.len {
				// Creep reached base core!
				c.active = false
				g.lives--
				g.sound_mgr.play_alarm_sound()
				if g.lives <= 0 {
					g.state = .game_over
				}
				continue
			}
		} else {
			c.x += (dx / dist) * current_speed * dt
			c.y += (dy / dist) * current_speed * dt
		}
	}

	// 3. Update Turrets & Firing
	for mut t in g.turrets {
		if t.cooldown > 0 {
			t.cooldown -= dt
		}

		tx := f32(offset_x + t.grid_x * tile_size + 20)
		ty := f32(offset_y + t.grid_y * tile_size + 20)

		// Find nearest creep in range
		mut best_creep_idx := -1
		mut min_dist := t.range

		for idx in 0 .. g.creeps.len {
			c := g.creeps[idx]
			if !c.active { continue }
			c_dx := c.x - tx
			c_dy := c.y - ty
			c_dist := f32(math.sqrt(c_dx * c_dx + c_dy * c_dy))

			if c_dist <= min_dist {
				min_dist = c_dist
				best_creep_idx = idx
			}
		}

		if best_creep_idx >= 0 {
			mut target := &g.creeps[best_creep_idx]
			t.target_id = target.id
			t.target_x = target.x
			t.target_y = target.y

			if t.cooldown <= 0 {
				t.cooldown = t.max_cooldown

				match t.turret_type {
					.laser {
						target.hp -= t.damage
						g.sound_mgr.play_laser_sound()
					}
					.cannon {
						// Splash Area Damage (radius 50)
						for mut c in g.creeps {
							if !c.active { continue }
							c_dx := c.x - target.x
							c_dy := c.y - target.y
							if f32(math.sqrt(c_dx * c_dx + c_dy * c_dy)) <= 50.0 {
								c.hp -= t.damage
							}
						}
						g.sound_mgr.play_cannon_sound()
					}
					.frost {
						target.hp -= t.damage
						target.slow_timer = 2.0
						g.sound_mgr.play_laser_sound()
					}
				}

				if target.hp <= 0 {
					target.active = false
					g.gold += target.reward
					g.score += target.reward * 10
					if g.score > g.high_score { g.high_score = g.score }
					g.sound_mgr.play_reward_sound()
				}
			}
		} else {
			t.target_id = -1
		}
	}

	g.creeps = g.creeps.filter(it.active)

	// Check Wave Completion
	if g.creeps_left <= 0 && g.creeps.len == 0 {
		if g.wave >= 20 {
			g.state = .victory
		} else {
			g.wave++
			g.gold += 100 + g.wave * 20
			g.start_wave()
		}
	}
}

fn (mut g TowerDefenseGame) upgrade_turret(gx int, gy int) {
	if g.state != .playing { return }
	for mut t in g.turrets {
		if t.grid_x == gx && t.grid_y == gy {
			base_cost := match t.turret_type {
				.laser { 100 }
				.cannon { 150 }
				.frost { 125 }
			}
			upgrade_cost := (base_cost * t.level) / 2
			if g.gold >= upgrade_cost {
				g.gold -= upgrade_cost
				t.level++
				t.damage *= 1.3
				t.range *= 1.15
				t.max_cooldown *= 0.9
				g.sound_mgr.play_reward_sound()
			}
			return
		}
	}
}

fn (mut g TowerDefenseGame) sell_turret(gx int, gy int) {
	if g.state != .playing { return }
	for i in 0 .. g.turrets.len {
		if g.turrets[i].grid_x == gx && g.turrets[i].grid_y == gy {
			t := g.turrets[i]
			base_cost := match t.turret_type {
				.laser { 100 }
				.cannon { 150 }
				.frost { 125 }
			}
			total_value := base_cost + (t.level - 1) * (base_cost / 2)
			refund := (total_value * 7) / 10
			g.gold += refund
			g.turrets.delete(i)
			g.sound_mgr.play_reward_sound()
			return
		}
	}
}

fn (mut g TowerDefenseGame) spawn_creep() {
	c_type := match rand.intn(4) or { 0 } {
		0 { CreepType.normal }
		1 { CreepType.scout }
		2 { CreepType.tank }
		else { CreepType.boss }
	}

	hp_mult := 1.0 + f32(g.wave) * 0.25

	spd, hp, reward := match c_type {
		.normal { f32(90.0), 100.0 * hp_mult, 15 }
		.scout { f32(160.0), 60.0 * hp_mult, 20 }
		.tank { f32(55.0), 350.0 * hp_mult, 40 }
		.boss { f32(45.0), 1200.0 * hp_mult, 150 }
	}

	start_wp := g.waypoints[0]
	g.creeps << Creep{
		id: rand.intn(100000) or { 1 }
		creep_type: c_type
		x: start_wp.x
		y: start_wp.y
		waypoint_idx: 1
		speed: spd
		hp: hp
		max_hp: hp
		reward: reward
		active: true
	}
}

fn (mut g TowerDefenseGame) place_turret(gx int, gy int, t_type TurretType) {
	if g.state != .playing { return }
	if gx < 0 || gx >= grid_cols || gy < 0 || gy >= grid_rows { return }

	// Cannot place on path tiles
	if g.path_grid[gy][gx] { return }

	// Cannot place on existing turret
	for t in g.turrets {
		if t.grid_x == gx && t.grid_y == gy { return }
	}

	cost := match t_type {
		.laser { 100 }
		.cannon { 150 }
		.frost { 125 }
	}

	if g.gold >= cost {
		g.gold -= cost
		range, dmg, cooldown := match t_type {
			.laser { f32(140.0), f32(35.0), f32(0.25) }
			.cannon { f32(110.0), f32(80.0), f32(0.85) }
			.frost { f32(120.0), f32(20.0), f32(0.45) }
		}

		g.turrets << Turret{
			grid_x: gx
			grid_y: gy
			turret_type: t_type
			range: range
			damage: dmg
			cooldown: 0.0
			max_cooldown: cooldown
		}
		g.save_progress()
	}
}

pub fn (mut g TowerDefenseGame) save_progress() {
	if g.score > g.high_score {
		g.high_score = g.score
	}
	mut saved := load_td_save()
	saved.high_score = g.high_score
	if g.wave > saved.max_wave {
		saved.max_wave = g.wave
	}
	saved.wave = g.wave
	saved.score = g.score
	saved.lives = g.lives
	saved.gold = g.gold

	mut t_lines := []string{}
	for t in g.turrets {
		t_type_int := int(t.turret_type)
		t_lines << '${t.grid_x},${t.grid_y},${t_type_int},${t.level}'
	}
	saved.turret_lines = t_lines
	save_td_data(&saved)
}

pub fn (mut g TowerDefenseGame) save_state() {
	g.save_progress()
	mut saved := load_td_save()
	saved.save_state_valid = true
	save_td_data(&saved)

	g.toast_msg = 'GAME SAVED (F5)'
	g.toast_timer = 2.0
}

pub fn (mut g TowerDefenseGame) load_state() {
	saved := load_td_save()
	if !saved.save_state_valid {
		g.toast_msg = 'NO SAVE FOUND'
		g.toast_timer = 2.0
		return
	}
	if saved.high_score > 0 {
		g.high_score = saved.high_score
	}
	g.wave = saved.wave
	g.score = saved.score
	g.lives = saved.lives
	g.gold = saved.gold
	g.turrets.clear()

	for line in saved.turret_lines {
		tokens := line.split(',')
		if tokens.len == 4 {
			gx := tokens[0].int()
			gy := tokens[1].int()
			t_type := unsafe { TurretType(tokens[2].int()) }
			lvl := tokens[3].int()

			range, dmg, cooldown := match t_type {
				.laser { f32(140.0), f32(35.0), f32(0.25) }
				.cannon { f32(110.0), f32(80.0), f32(0.85) }
				.frost { f32(120.0), f32(20.0), f32(0.45) }
			}
			g.turrets << Turret{
				grid_x: gx
				grid_y: gy
				turret_type: t_type
				level: lvl
				range: range
				damage: dmg
				cooldown: 0.0
				max_cooldown: cooldown
			}
		}
	}
	g.state = .playing
	g.toast_msg = 'GAME LOADED (F9)'
	g.toast_timer = 2.0
}
