module main

import math
import rand

pub const map_cols = 25
pub const map_rows = 18
pub const tile_size = 32
pub const arena_w = map_cols * tile_size // 800
pub const arena_h = map_rows * tile_size // 576

pub enum GameMode {
	menu
	quest
	versus
	game_over
}

pub enum ArrowType {
	normal
	brambly
	bomb
	laser
}

pub enum ArrowState {
	in_flight
	stuck
	collectible
}

pub enum MonsterType {
	skeleton
	slime
	bat
	reaper
	boss
}

pub enum ArcherColor {
	green
	blue
	pink
	yellow
}

pub struct Archer {
pub mut:
	id           int
	name         string
	color        ArcherColor
	x            f64
	y            f64
	vx           f64
	vy           f64
	w            f64 = 20.0
	h            f64 = 28.0
	facing       int = 1 // 1 = right, -1 = left
	aim_x        f64 = 1.0
	aim_y        f64 = 0.0
	is_grounded  bool
	is_wall_slide bool
	wall_dir     int
	arrows       int = 3
	max_arrows   int = 5
	lives        int = 3
	score        int
	is_dashing   bool
	dash_timer   f64
	dash_cooldown f64
	dash_vx      f64
	dash_vy      f64
	invuln_timer f64
	bow_charge   f64
	shield       bool
	wings        bool
	is_bot       bool
	bot_target_x f64
	bot_target_y f64
	bot_action_t f64
	arrow_type   ArrowType = .normal
}

pub struct Arrow {
pub mut:
	id          int
	owner_id    int
	arrow_type  ArrowType
	x           f64
	y           f64
	vx          f64
	vy          f64
	state       ArrowState = .in_flight
	stuck_timer f64
	rot_angle   f64
}

pub struct Monster {
pub mut:
	id          int
	m_type      MonsterType
	x           f64
	y           f64
	vx          f64
	vy          f64
	w           f64 = 24.0
	h           f64 = 24.0
	hp          int = 1
	max_hp      int = 1
	facing      int = 1
	attack_t    f64
	anim_timer  f64
}

pub struct Chest {
pub mut:
	x       f64
	y       f64
	opened  bool
	content ArrowType = .normal
}

pub struct TowerFallGame {
pub mut:
	mode            GameMode = .menu
	menu_selected   int
	players         []Archer
	arrows          []Arrow
	monsters        []Monster
	chests          []Chest
	map_tiles       [][]bool
	bramble_tiles   [][]bool
	particles       []Particle
	quest_wave      int = 1
	max_quest_wave  int = 1
	score           int
	high_score      int
	unlocked_arenas int = 1
	current_arena   int
	shake_timer     f64
	shake_intensity f64
	slow_mo_timer   f64
	toast_msg       string
	toast_timer     f64
	sound_mgr       SoundManager
}

pub fn new_towerfall_game() TowerFallGame {
	mut g := TowerFallGame{
		sound_mgr: new_sound_manager()
	}
	saved := load_towerfall_save()
	if saved.high_score > 0 { g.high_score = saved.high_score }
	if saved.max_quest_wave > 0 { g.max_quest_wave = saved.max_quest_wave }
	if saved.unlocked_arenas > 0 { g.unlocked_arenas = saved.unlocked_arenas }

	g.init_map(0)
	return g
}

pub fn (mut g TowerFallGame) init_map(arena_idx int) {
	g.current_arena = arena_idx
	g.map_tiles = [][]bool{len: map_rows, init: []bool{len: map_cols}}
	g.bramble_tiles = [][]bool{len: map_rows, init: []bool{len: map_cols}}

	// Border Walls
	for r in 0 .. map_rows {
		for c in 0 .. map_cols {
			if r == 0 || r == map_rows - 1 || c == 0 || c == map_cols - 1 {
				// Leave wraparound gap in center of left/right/top/bottom walls
				if (c == 0 || c == map_cols - 1) && (r >= 7 && r <= 10) {
					g.map_tiles[r][c] = false
				} else if (r == 0 || r == map_rows - 1) && (c >= 11 && c <= 13) {
					g.map_tiles[r][c] = false
				} else {
					g.map_tiles[r][c] = true
				}
			}
		}
	}

	// Layout specific platforms based on arena
	match arena_idx {
		0 { // Sacred Ground (Classic Layout)
			g.add_platform(4, 5, 5)
			g.add_platform(16, 5, 5)
			g.add_platform(9, 9, 7)
			g.add_platform(3, 13, 6)
			g.add_platform(16, 13, 6)
		}
		1 { // Sunken City (Vertical Platforms)
			g.add_platform(2, 6, 4)
			g.add_platform(19, 6, 4)
			g.add_platform(7, 8, 4)
			g.add_platform(14, 8, 4)
			g.add_platform(10, 12, 5)
			g.add_platform(4, 14, 4)
			g.add_platform(17, 14, 4)
		}
		2 { // King's Court (Central Tower)
			g.add_platform(8, 6, 9)
			g.add_platform(10, 10, 5)
			g.add_platform(4, 11, 4)
			g.add_platform(17, 11, 4)
			g.add_platform(6, 15, 13)
		}
		else { // Tower of Dusk (Floating Blocks)
			g.add_platform(3, 4, 4)
			g.add_platform(18, 4, 4)
			g.add_platform(8, 7, 9)
			g.add_platform(4, 11, 5)
			g.add_platform(16, 11, 5)
			g.add_platform(9, 14, 7)
		}
	}

	g.spawn_chests()
}

fn (mut g TowerFallGame) add_platform(start_c int, r int, len int) {
	for c in start_c .. start_c + len {
		if r >= 0 && r < map_rows && c >= 0 && c < map_cols {
			g.map_tiles[r][c] = true
		}
	}
}

fn (mut g TowerFallGame) spawn_chests() {
	g.chests.clear()
	g.chests << Chest{ x: 120.0, y: 130.0, content: .brambly }
	g.chests << Chest{ x: 650.0, y: 130.0, content: .bomb }
	g.chests << Chest{ x: 380.0, y: 260.0, content: .laser }
}

pub fn (mut g TowerFallGame) start_quest() {
	g.mode = .quest
	g.quest_wave = 1
	g.score = 0
	g.players.clear()
	g.arrows.clear()
	g.monsters.clear()
	g.init_map(0)

	g.players << Archer{
		id: 1
		name: 'P1 Archer'
		color: .green
		x: 200.0
		y: 350.0
		arrows: 3
		lives: 3
	}
	g.spawn_quest_wave()
}

pub fn (mut g TowerFallGame) start_versus() {
	g.mode = .versus
	g.players.clear()
	g.arrows.clear()
	g.monsters.clear()
	g.init_map(0)

	// P1 Human
	g.players << Archer{
		id: 1
		name: 'Player 1'
		color: .green
		x: 150.0
		y: 350.0
		arrows: 3
		lives: 5
	}

	// P2 Bot or Player
	g.players << Archer{
		id: 2
		name: 'Archer Bot'
		color: .pink
		x: 650.0
		y: 350.0
		arrows: 3
		lives: 5
		is_bot: true
	}
}

pub fn (mut g TowerFallGame) spawn_quest_wave() {
	g.monsters.clear()
	count := 3 + g.quest_wave * 2
	for i in 0 .. count {
		m_type := match (g.quest_wave + i) % 4 {
			0 { MonsterType.skeleton }
			1 { MonsterType.slime }
			2 { MonsterType.bat }
			else { MonsterType.reaper }
		}
		spawn_x := 100.0 + f64((i * 120) % 600)
		spawn_y := 80.0 + f64((i * 70) % 300)
		hp := if m_type == .reaper { 2 } else { 1 }
		g.monsters << Monster{
			id: i + 1
			m_type: m_type
			x: spawn_x
			y: spawn_y
			hp: hp
			max_hp: hp
		}
	}
	g.sound_mgr.play_wave_clear()
}

pub fn (mut g TowerFallGame) update(dt f64) {
	if g.mode == .menu || g.mode == .game_over {
		return
	}

	if g.slow_mo_timer > 0.0 {
		g.slow_mo_timer -= dt
		return
	}

	if g.shake_timer > 0.0 {
		g.shake_timer -= dt
	}

	if g.toast_timer > 0.0 {
		g.toast_timer -= dt
	}

	// 1. Update Archers Physics & AI
	for mut p in g.players {
		if p.lives <= 0 { continue }

		if p.is_bot {
			g.update_bot_ai(mut p, dt)
		}

		// Dash cooldown & duration
		if p.is_dashing {
			p.dash_timer -= dt
			p.vx = p.dash_vx
			p.vy = p.dash_vy
			if p.dash_timer <= 0.0 {
				p.is_dashing = false
			}
		} else {
			// Gravity & Friction
			if !p.is_grounded {
				gravity := if p.is_wall_slide { 180.0 } else { 850.0 }
				p.vy += gravity * dt
			}
			p.vx *= 0.82
		}

		if p.dash_cooldown > 0.0 { p.dash_cooldown -= dt }
		if p.invuln_timer > 0.0 { p.invuln_timer -= dt }

		// Move & Tile Collision
		g.move_archer(mut p, dt)

		// Check Chest Pickup
		for mut c in g.chests {
			if !c.opened && math.abs(p.x - c.x) < 24.0 && math.abs(p.y - c.y) < 24.0 {
				c.opened = true
				p.arrow_type = c.content
				p.arrows = math.min(p.max_arrows, p.arrows + 2)
				g.sound_mgr.play_arrow_catch()
				spawn_burst(mut g.particles, c.x, c.y, 12, Color{255, 215, 0, 255})
			}
		}
	}

	// 2. Update Arrows
	for i := g.arrows.len - 1; i >= 0; i-- {
		mut a := unsafe { &g.arrows[i] }
		if a.state == .in_flight {
			// Gravity drop for normal/brambly/bomb arrows
			if a.arrow_type != .laser {
				a.vy += 220.0 * dt
			}
			a.x += a.vx * dt
			a.y += a.vy * dt
			a.rot_angle = math.atan2(a.vy, a.vx)

			// Spawn Arrow Trail Particles
			if rand.f64() < 0.6 {
				trail_col := match a.arrow_type {
					.normal { Color{255, 220, 100, 200} }
					.brambly { Color{80, 220, 90, 200} }
					.bomb { Color{255, 90, 40, 200} }
					.laser { Color{80, 230, 255, 200} }
				}
				g.particles << Particle{
					x: a.x
					y: a.y
					vx: -a.vx * 0.1
					vy: -a.vy * 0.1
					life: 0.15
					max_l: 0.15
					color: trail_col
					size: 2
				}
			}

			// Screen Wrap for Arrows
			g.wrap_position(mut a.x, mut a.y)

			// Check Tile Impact
			tile_c := int(a.x) / tile_size
			tile_r := int(a.y) / tile_size
			if tile_r >= 0 && tile_r < map_rows && tile_c >= 0 && tile_c < map_cols {
				if g.map_tiles[tile_r][tile_c] {
					a.state = .stuck
					a.vx = 0.0
					a.vy = 0.0
					g.sound_mgr.play_arrow_hit_wall()
					spawn_arrow_spark(mut g.particles, a.x, a.y, a.vx, a.vy)

					if a.arrow_type == .brambly {
						g.bramble_tiles[tile_r][tile_c] = true
					} else if a.arrow_type == .bomb {
						g.trigger_explosion(a.x, a.y)
					}
				}
			}

			// Check Archer Impact
			for mut p in g.players {
				if p.lives <= 0 { continue }

				if math.abs(a.x - p.x) < 16.0 && math.abs(a.y - (p.y - 10.0)) < 20.0 {
					// Dodge Dash Arrow Catching!
					if p.is_dashing {
						a.state = .collectible
						p.arrows = math.min(p.max_arrows, p.arrows + 1)
						g.sound_mgr.play_arrow_catch()
						g.toast_msg = '${p.name} CAUGHT ARROW!'
						g.toast_timer = 1.5
						spawn_burst(mut g.particles, p.x, p.y, 16, Color{80, 240, 255, 255})
						break
					}

					// Shield Protection
					if p.shield {
						p.shield = false
						a.state = .stuck
						g.sound_mgr.play_arrow_hit_wall()
						break
					}

					// Kill Archer!
					if p.invuln_timer <= 0.0 {
						p.lives--
						g.sound_mgr.play_player_death()
						g.trigger_shake(0.35, 12.0)
						g.slow_mo_timer = 0.15
						spawn_burst(mut g.particles, p.x, p.y, 30, Color{240, 40, 40, 255})

						if a.owner_id != p.id {
							for mut killer in g.players {
								if killer.id == a.owner_id {
									killer.score += 500
								}
							}
						}
						a.state = .collectible
						p.x = 100.0 + rand.f64() * 600.0
						p.y = 200.0
						p.invuln_timer = 2.0
					}
				}
			}

			// Check Monster Impact in Quest Mode
			if g.mode == .quest {
				for mut m in g.monsters {
					if m.hp > 0 && math.abs(a.x - m.x) < 18.0 && math.abs(a.y - m.y) < 18.0 {
						m.hp--
						g.sound_mgr.play_player_death()
						spawn_burst(mut g.particles, m.x, m.y, 18, Color{255, 120, 40, 255})
						a.state = .stuck
						if m.hp <= 0 {
							g.score += 200
							if g.score > g.high_score { g.high_score = g.score }
						}
					}
				}
			}

		} else if a.state == .stuck || a.state == .collectible {
			// Check pickup by archers
			for mut p in g.players {
				if p.lives > 0 && math.abs(a.x - p.x) < 22.0 && math.abs(a.y - p.y) < 22.0 {
					p.arrows = math.min(p.max_arrows, p.arrows + 1)
					g.sound_mgr.play_arrow_catch()
					g.arrows.delete(i)
					break
				}
			}
		}
	}

	// 3. Update Monsters in Quest Mode
	if g.mode == .quest {
		mut active_monsters := 0
		for mut m in g.monsters {
			if m.hp <= 0 { continue }
			active_monsters++

			// Simple Monster AI
			m.x += f64(m.facing) * 45.0 * dt
			g.wrap_position(mut m.x, mut m.y)

			// Turn at walls
			tc := int(m.x) / tile_size
			tr := int(m.y) / tile_size
			if tc >= 0 && tc < map_cols && tr >= 0 && tr < map_rows {
				if g.map_tiles[tr][tc] {
					m.facing *= -1
				}
			}

			// Check hurt archers
			for mut p in g.players {
				if p.lives > 0 && p.invuln_timer <= 0.0 && math.abs(m.x - p.x) < 18.0 && math.abs(m.y - p.y) < 18.0 {
					p.lives--
					p.invuln_timer = 2.0
					g.sound_mgr.play_player_death()
					g.trigger_shake(0.25, 8.0)
					spawn_burst(mut g.particles, p.x, p.y, 20, Color{240, 50, 50, 255})
				}
			}
		}

		// Check Quest Wave Clear
		if active_monsters == 0 {
			g.quest_wave++
			if g.quest_wave > g.max_quest_wave {
				g.max_quest_wave = g.quest_wave
			}
			g.spawn_quest_wave()
			g.save_progress()
		}
	}

	// 4. Update Particles
	update_particles(mut g.particles, dt)
}

fn (mut g TowerFallGame) trigger_explosion(x f64, y f64) {
	g.sound_mgr.play_explosion()
	g.trigger_shake(0.4, 15.0)
	spawn_burst(mut g.particles, x, y, 35, Color{255, 100, 30, 255})

	// Damage surrounding archers & destroy brambles
	for mut p in g.players {
		if p.lives > 0 && math.abs(p.x - x) < 60.0 && math.abs(p.y - y) < 60.0 {
			if p.invuln_timer <= 0.0 {
				p.lives--
				p.invuln_timer = 2.0
				g.sound_mgr.play_player_death()
			}
		}
	}
}

fn (mut g TowerFallGame) update_bot_ai(mut p Archer, dt f64) {
	p.bot_action_t -= dt
	if p.bot_action_t <= 0.0 {
		p.bot_action_t = 0.3 + rand.f64() * 0.4

		// Target P1
		if g.players.len > 0 {
			p1 := g.players[0]
			dx := p1.x - p.x
			dy := p1.y - p.y
			p.facing = if dx > 0 { 1 } else { -1 }

			// Aim towards P1
			dist := math.sqrt(dx * dx + dy * dy)
			if dist > 0 {
				p.aim_x = dx / dist
				p.aim_y = dy / dist
			}

			// Shoot arrow if facing target & has arrows
			if p.arrows > 0 && dist < 350.0 && rand.f64() < 0.6 {
				g.shoot_arrow(mut p)
			} else if rand.f64() < 0.4 {
				// Jump / Dodge
				p.vy = -420.0
			}
		}
	}
	p.vx = f64(p.facing) * 160.0
}

pub fn (mut g TowerFallGame) shoot_arrow(mut p Archer) {
	if p.arrows <= 0 { return }
	p.arrows--
	g.sound_mgr.play_bow_shoot()

	speed := 650.0
	ax := p.x + p.aim_x * 16.0
	ay := p.y - 8.0 + p.aim_y * 16.0

	g.arrows << Arrow{
		id: g.arrows.len + 1
		owner_id: p.id
		arrow_type: p.arrow_type
		x: ax
		y: ay
		vx: p.aim_x * speed
		vy: p.aim_y * speed
		state: .in_flight
		rot_angle: math.atan2(p.aim_y, p.aim_x)
	}
}

pub fn (mut g TowerFallGame) dodge_dash(mut p Archer, dir_x f64, dir_y f64) {
	if p.dash_cooldown > 0.0 { return }
	p.is_dashing = true
	p.dash_timer = 0.18
	p.dash_cooldown = 0.6
	p.dash_vx = dir_x * 520.0
	p.dash_vy = dir_y * 520.0
	g.sound_mgr.play_dodge_dash()
	spawn_burst(mut g.particles, p.x, p.y, 12, Color{220, 240, 255, 255})
}

fn (mut g TowerFallGame) move_archer(mut p Archer, dt f64) {
	// Move Horizontal
	p.x += p.vx * dt
	g.wrap_position(mut p.x, mut p.y)

	// Move Vertical
	p.y += p.vy * dt
	g.wrap_position(mut p.x, mut p.y)

	// Tile Snap Collision
	tile_c := int(p.x) / tile_size
	tile_r := int(p.y) / tile_size

	p.is_grounded = false
	p.is_wall_slide = false

	if tile_r >= 0 && tile_r < map_rows && tile_c >= 0 && tile_c < map_cols {
		// Ground check
		below_r := int(p.y + p.h / 2) / tile_size
		if below_r < map_rows && g.map_tiles[below_r][tile_c] {
			p.is_grounded = true
			p.vy = 0.0
			p.y = f64(below_r * tile_size) - p.h / 2
		}

		// Wall slide check
		side_c := int(p.x + f64(p.facing) * (p.w / 2 + 2.0)) / tile_size
		if side_c >= 0 && side_c < map_cols && g.map_tiles[tile_r][side_c] && !p.is_grounded {
			p.is_wall_slide = true
			p.wall_dir = p.facing
		}
	}
}

pub fn (mut g TowerFallGame) wrap_position(mut x &f64, mut y &f64) {
	unsafe {
		if *x < 0.0 { *x = f64(arena_w - 4) }
		else if *x >= f64(arena_w) { *x = 4.0 }

		if *y < 0.0 { *y = f64(arena_h - 4) }
		else if *y >= f64(arena_h) { *y = 4.0 }
	}
}

pub fn (mut g TowerFallGame) trigger_shake(duration f64, intensity f64) {
	g.shake_timer = duration
	g.shake_intensity = intensity
}

pub fn (mut g TowerFallGame) save_progress() {
	if g.score > g.high_score {
		g.high_score = g.score
	}
	mut saved := load_towerfall_save()
	saved.high_score = g.high_score
	saved.max_quest_wave = g.max_quest_wave
	saved.unlocked_arenas = g.unlocked_arenas
	save_towerfall_data(&saved)
}

pub fn (mut g TowerFallGame) save_state() {
	g.save_progress()
	mut saved := load_towerfall_save()
	saved.save_state_valid = true
	saved.mode = int(g.mode)
	saved.quest_wave = g.quest_wave
	saved.score = g.score
	if g.players.len > 0 {
		saved.p1_lives = g.players[0].lives
		saved.p1_arrows = g.players[0].arrows
		saved.p1_x = g.players[0].x
		saved.p1_y = g.players[0].y
	}
	if g.players.len > 1 {
		saved.p2_lives = g.players[1].lives
		saved.p2_arrows = g.players[1].arrows
		saved.p2_x = g.players[1].x
		saved.p2_y = g.players[1].y
	}
	saved.arena_idx = g.current_arena
	save_towerfall_data(&saved)

	g.toast_msg = 'GAME SAVED (F5)'
	g.toast_timer = 2.0
}

pub fn (mut g TowerFallGame) load_state() {
	saved := load_towerfall_save()
	if !saved.save_state_valid {
		g.toast_msg = 'NO SAVE FOUND'
		g.toast_timer = 2.0
		return
	}
	if saved.high_score > 0 { g.high_score = saved.high_score }
	if saved.max_quest_wave > 0 { g.max_quest_wave = saved.max_quest_wave }
	g.quest_wave = saved.quest_wave
	g.score = saved.score
	g.init_map(saved.arena_idx)

	if saved.mode == 1 {
		g.start_quest()
	} else if saved.mode == 2 {
		g.start_versus()
	}

	if g.players.len > 0 {
		g.players[0].lives = saved.p1_lives
		g.players[0].arrows = saved.p1_arrows
		g.players[0].x = saved.p1_x
		g.players[0].y = saved.p1_y
	}
	if g.players.len > 1 {
		g.players[1].lives = saved.p2_lives
		g.players[1].arrows = saved.p2_arrows
		g.players[1].x = saved.p2_x
		g.players[1].y = saved.p2_y
	}

	g.toast_msg = 'GAME LOADED (F9)'
	g.toast_timer = 2.0
}
