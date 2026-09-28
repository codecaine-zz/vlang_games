module main

import math
import rand

enum GameState {
	menu
	playing
	paused
	game_over
	wave_clear
}

struct Silo {
mut:
	x    f32
	y    f32
	ammo int = 10
}

struct City {
mut:
	x      f32
	y      f32
	active bool = true
}

struct ICBM {
mut:
	start_x f32
	start_y f32
	target_x f32
	target_y f32
	x       f32
	y       f32
	speed   f32
	active  bool
}

struct Interceptor {
mut:
	start_x  f32
	start_y  f32
	target_x f32
	target_y f32
	x        f32
	y        f32
	speed    f32 = 450.0
	active   bool
}

struct BlastCloud {
mut:
	x          f32
	y          f32
	radius     f32
	max_radius f32 = 35.0
	timer      f32 = 1.2
	active     bool = true
}

struct MissileCommandGame {
mut:
	state        GameState = .menu
	score        int
	high_score   int = 5000
	wave         int = 1
	crosshair_x  f32 = 400.0
	crosshair_y  f32 = 300.0
	silos        []Silo
	cities       []City
	icbms        []ICBM
	interceptors []Interceptor
	blasts       []BlastCloud
	sound_mgr    SoundManager
	wave_timer   f32
	spawn_timer  f32
	icbms_left   int = 12
	shake_trauma f32
}

fn new_missilecommand_game() MissileCommandGame {
	mut g := MissileCommandGame{
		sound_mgr: new_sound_manager()
	}
	g.reset_game()
	return g
}

fn (mut g MissileCommandGame) reset_game() {
	g.score = 0
	g.wave = 1
	g.reset_silos()
	g.reset_cities()
	g.start_wave()
	g.state = .playing
}

fn (mut g MissileCommandGame) reset_silos() {
	g.silos = [
		Silo{ x: 60.0, y: 530.0, ammo: 10 },
		Silo{ x: 400.0, y: 530.0, ammo: 10 },
		Silo{ x: 740.0, y: 530.0, ammo: 10 },
	]
}

fn (mut g MissileCommandGame) reset_cities() {
	g.cities = [
		City{ x: 140.0, y: 540.0, active: true },
		City{ x: 210.0, y: 540.0, active: true },
		City{ x: 280.0, y: 540.0, active: true },
		City{ x: 520.0, y: 540.0, active: true },
		City{ x: 590.0, y: 540.0, active: true },
		City{ x: 660.0, y: 540.0, active: true },
	]
}

fn (mut g MissileCommandGame) start_wave() {
	g.icbms.clear()
	g.interceptors.clear()
	g.blasts.clear()

	for mut s in g.silos {
		s.ammo = 10
	}
	g.icbms_left = 10 + g.wave * 4
	g.spawn_timer = 0.0
}

fn (mut g MissileCommandGame) update(dt f32) {
	if g.state != .playing { return }

	if g.shake_trauma > 0.0 {
		g.shake_trauma -= dt * 2.0
		if g.shake_trauma < 0.0 {
			g.shake_trauma = 0.0
		}
	}

	// Spawn ICBM Warheads
	if g.icbms_left > 0 {
		g.spawn_timer -= dt
		if g.spawn_timer <= 0 {
			g.spawn_timer = 1.2 - f32(g.wave) * 0.08
			if g.spawn_timer < 0.4 { g.spawn_timer = 0.4 }

			g.spawn_icbm()
			g.icbms_left--
		}
	}

	// Update Blast Clouds
	for mut b in g.blasts {
		if !b.active { continue }
		b.timer -= dt
		if b.radius < b.max_radius {
			b.radius += 50.0 * dt
			if b.radius > b.max_radius { b.radius = b.max_radius }
		}
		if b.timer <= 0 {
			b.active = false
		}
	}
	g.blasts = g.blasts.filter(it.active)

	// Update Interceptors
	for mut m in g.interceptors {
		if !m.active { continue }
		dx := m.target_x - m.x
		dy := m.target_y - m.y
		dist := f32(math.sqrt(dx * dx + dy * dy))

		if dist <= m.speed * dt || dist < 10.0 {
			m.active = false
			g.blasts << BlastCloud{ x: m.target_x, y: m.target_y }
			g.shake_trauma += 0.08
			if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
			g.sound_mgr.play_boom_sound()
		} else {
			m.x += (dx / dist) * m.speed * dt
			m.y += (dy / dist) * m.speed * dt
		}
	}
	g.interceptors = g.interceptors.filter(it.active)

	// Update ICBM Warheads
	for mut icbm in g.icbms {
		if !icbm.active { continue }
		dx := icbm.target_x - icbm.x
		dy := icbm.target_y - icbm.y
		dist := f32(math.sqrt(dx * dx + dy * dy))

		if dist < 8.0 {
			icbm.active = false
			g.handle_icbm_impact(icbm.target_x, icbm.target_y)
		} else {
			icbm.x += (dx / dist) * icbm.speed * dt
			icbm.y += (dy / dist) * icbm.speed * dt
		}

		// Check collision with any Blast Cloud
		for b in g.blasts {
			if !b.active { continue }
			b_dx := icbm.x - b.x
			b_dy := icbm.y - b.y
			if f32(math.sqrt(b_dx * b_dx + b_dy * b_dy)) < b.radius {
				icbm.active = false
				g.score += 100
				if g.score > g.high_score { g.high_score = g.score }
				g.shake_trauma += 0.16
				if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
				g.blasts << BlastCloud{ x: icbm.x, y: icbm.y, max_radius: 25.0, timer: 0.8 }
				break
			}
		}
	}
	g.icbms = g.icbms.filter(it.active)

	// Wave Completion check
	if g.icbms_left <= 0 && g.icbms.len == 0 {
		g.wave++
		g.start_wave()
	}
}

struct TargetPoint {
	x f32
	y f32
}

fn (mut g MissileCommandGame) spawn_icbm() {
	sx := f32(rand.intn(760) or { 380 }) + 20.0

	mut targets := []TargetPoint{}
	for c in g.cities {
		if c.active { targets << TargetPoint{ x: c.x, y: c.y } }
	}
	for s in g.silos {
		if s.ammo > 0 { targets << TargetPoint{ x: s.x, y: s.y } }
	}

	tx := if targets.len > 0 { targets[rand.intn(targets.len) or { 0 }].x } else { f32(400.0) }
	ty := f32(540.0)
	spd := 65.0 + f32(g.wave) * 10.0

	g.icbms << ICBM{
		start_x: sx
		start_y: 0.0
		target_x: tx
		target_y: ty
		x: sx
		y: 0.0
		speed: spd
		active: true
	}
}

fn (mut g MissileCommandGame) fire_interceptor(tx f32, ty f32) {
	if g.state != .playing { return }

	// Find best silo with ammo closest to target
	mut best_silo_idx := -1
	mut min_dist := f32(99999.0)

	for i in 0 .. g.silos.len {
		if g.silos[i].ammo > 0 {
			dx := g.silos[i].x - tx
			dy := g.silos[i].y - ty
			dist := f32(math.sqrt(dx * dx + dy * dy))
			if dist < min_dist {
				min_dist = dist
				best_silo_idx = i
			}
		}
	}

	if best_silo_idx >= 0 {
		g.silos[best_silo_idx].ammo--
		sx := g.silos[best_silo_idx].x
		sy := g.silos[best_silo_idx].y

		g.interceptors << Interceptor{
			start_x: sx
			start_y: sy
			target_x: tx
			target_y: ty
			x: sx
			y: sy
			active: true
		}
		g.sound_mgr.play_launch_sound()
	}
}

fn (mut g MissileCommandGame) handle_icbm_impact(tx f32, ty f32) {
	g.shake_trauma += 0.60
	if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
	g.sound_mgr.play_city_hit_sound()
	g.blasts << BlastCloud{ x: tx, y: ty, max_radius: 40.0, timer: 1.5 }

	// Destroy city if in radius
	for mut c in g.cities {
		if c.active && math.abs(c.x - tx) < 30.0 {
			c.active = false
		}
	}

	// Check Game Over (all 6 cities destroyed)
	mut active_cities := 0
	for c in g.cities {
		if c.active { active_cities++ }
	}
	if active_cities == 0 {
		g.state = .game_over
	}
}
