module main

import math
import rand

enum GameState {
	menu
	playing
	paused
	game_over
}

struct Platform {
mut:
	x     f32
	y     f32
	width f32
}

struct DroneEnemy {
mut:
	x          f32
	y          f32
	vy         f32
	shoot_timer f32
	active     bool = true
}

struct Shuriken {
mut:
	x      f32
	y      f32
	vx     f32 = 650.0
	active bool = true
}

struct DroneLaser {
mut:
	x      f32
	y      f32
	vx     f32 = -380.0
	active bool = true
}

struct ShinobiGame {
mut:
	state             GameState = .menu
	score             int
	high_score        int = 5000
	stage             int = 1
	lives             int = 3
	player_x          f32 = 150.0
	player_y          f32 = 300.0
	player_vx         f32
	player_vy         f32
	is_grounded       bool
	double_jump_ready bool = true
	is_slashing       bool
	slash_timer       f32
	platforms         []Platform
	drones            []DroneEnemy
	shurikens         []Shuriken
	lasers            []DroneLaser
	sound_mgr         SoundManager
	scroll_speed      f32 = 220.0
	spawn_timer       f32
	shake_trauma      f32
	key_left          bool
	key_right         bool
	key_jump          bool
}

fn new_shinobi_game() ShinobiGame {
	mut g := ShinobiGame{
		sound_mgr: new_sound_manager()
	}
	g.reset_game()
	return g
}

fn (mut g ShinobiGame) reset_game() {
	g.score = 0
	g.stage = 1
	g.lives = 3
	g.scroll_speed = 220.0
	g.shake_trauma = 0.0
	g.reset_stage()
	g.state = .playing
}

fn (mut g ShinobiGame) reset_stage() {
	g.player_x = 150.0
	g.player_y = 300.0
	g.player_vx = 0.0
	g.player_vy = 0.0
	g.is_grounded = true
	g.double_jump_ready = true
	g.is_slashing = false
	g.slash_timer = 0.0

	g.platforms = [
		Platform{ x: 0.0, y: 440.0, width: 450.0 },
		Platform{ x: 500.0, y: 380.0, width: 350.0 },
		Platform{ x: 900.0, y: 420.0, width: 400.0 },
	]

	g.drones.clear()
	g.shurikens.clear()
	g.lasers.clear()

	g.drones << DroneEnemy{ x: 600.0, y: 250.0 }
}

fn (mut g ShinobiGame) jump() {
	if g.state != .playing { return }

	if g.is_grounded {
		g.player_vy = -450.0
		g.is_grounded = false
		g.double_jump_ready = true
		g.sound_mgr.play_jump_sound()
	} else if g.double_jump_ready {
		g.player_vy = -420.0
		g.double_jump_ready = false
		g.sound_mgr.play_jump_sound()
	}
}

fn (mut g ShinobiGame) slash() {
	if g.state != .playing { return }
	g.is_slashing = true
	g.slash_timer = 0.2
	g.sound_mgr.play_slash_sound()

	// Katana Slash Area Check
	slash_box_x := g.player_x + 10.0
	slash_box_y := g.player_y - 20.0

	for mut d in g.drones {
		if !d.active { continue }
		if math.abs(d.x - slash_box_x) < 55.0 && math.abs(d.y - slash_box_y) < 40.0 {
			d.active = false
			g.score += 250
			g.shake_trauma = math.min(1.0, g.shake_trauma + 0.28)
			g.sound_mgr.play_explosion_sound()
		}
	}
}

fn (mut g ShinobiGame) throw_shuriken() {
	if g.state != .playing { return }
	g.shurikens << Shuriken{ x: g.player_x + 16.0, y: g.player_y - 8.0 }
	g.sound_mgr.play_shuriken_sound()
}

fn (mut g ShinobiGame) update(dt f32) {
	if g.state != .playing { return }

	if g.shake_trauma > 0.0 {
		g.shake_trauma = math.max(0.0, g.shake_trauma - dt * 2.2)
	}

	g.score += int(dt * 50.0)
	if g.score > g.high_score { g.high_score = g.score }

	if g.slash_timer > 0 {
		g.slash_timer -= dt
		if g.slash_timer <= 0 {
			g.is_slashing = false
		}
	}

	// 1. Horizontal Movement & Gravity
	g.player_vx = 0.0
	if g.key_left { g.player_vx = -140.0 }
	if g.key_right { g.player_vx = 140.0 }

	g.player_x += g.player_vx * dt
	if g.player_x < 40 { g.player_x = 40 }
	if g.player_x > 760 { g.player_x = 760 }

	if !g.is_grounded {
		g.player_vy += 950.0 * dt
	}
	g.player_y += g.player_vy * dt

	// 2. Scroll Rooftop Platforms Left
	for mut p in g.platforms {
		p.x -= g.scroll_speed * dt
		if p.x + p.width < -50 {
			p.x = 850.0 + f32(rand.intn(100) or { 50 })
			p.y = 350.0 + f32(rand.intn(120) or { 40 })
			p.width = 300.0 + f32(rand.intn(200) or { 50 })
		}
	}

	// Check Platform Floor Collision
	g.is_grounded = false
	for p in g.platforms {
		if g.player_x >= p.x - 12.0 && g.player_x <= p.x + p.width + 12.0 {
			if g.player_y >= p.y - 28.0 && g.player_y <= p.y + 10.0 && g.player_vy >= 0 {
				g.player_y = p.y - 24.0
				g.player_vy = 0.0
				g.is_grounded = true
				g.double_jump_ready = true
				break
			}
		}
	}

	// Fall into rooftop gap pit -> Death
	if g.player_y > 620 {
		g.handle_player_death()
		return
	}

	// 3. Update Shurikens
	for mut s in g.shurikens {
		if !s.active { continue }
		s.x += s.vx * dt
		if s.x > 820 { s.active = false }

		for mut d in g.drones {
			if !d.active { continue }
			if math.abs(s.x - d.x) < 25.0 && math.abs(s.y - d.y) < 25.0 {
				s.active = false
				d.active = false
				g.score += 200
				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.22)
				g.sound_mgr.play_explosion_sound()
				break
			}
		}
	}
	g.shurikens = g.shurikens.filter(it.active)

	// 4. Update Drones & Lasers
	g.spawn_timer += dt
	if g.spawn_timer > 3.5 {
		g.spawn_timer = 0.0
		g.drones << DroneEnemy{ x: 840.0, y: 220.0 + f32(rand.intn(150) or { 50 }) }
	}

	for mut d in g.drones {
		if !d.active { continue }
		d.x -= (g.scroll_speed + 50.0) * dt
		d.shoot_timer += dt

		if d.shoot_timer > 2.2 {
			d.shoot_timer = 0.0
			g.lasers << DroneLaser{ x: d.x - 15.0, y: d.y }
		}

		if d.x < -40 { d.active = false }

		// Touch Drone
		if math.abs(d.x - g.player_x) < 24.0 && math.abs(d.y - g.player_y) < 24.0 {
			g.handle_player_death()
			return
		}
	}
	g.drones = g.drones.filter(it.active)

	for mut l in g.lasers {
		if !l.active { continue }
		l.x += l.vx * dt
		if l.x < -20 { l.active = false }

		// Touch Laser
		if math.abs(l.x - g.player_x) < 18.0 && math.abs(l.y - g.player_y) < 18.0 {
			if g.is_slashing {
				// Deflect laser with katana!
				l.active = false
				g.score += 150
				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.25)
				g.sound_mgr.play_slash_sound()
			} else {
				g.handle_player_death()
				return
			}
		}
	}
	g.lasers = g.lasers.filter(it.active)
}

fn (mut g ShinobiGame) handle_player_death() {
	g.lives--
	g.shake_trauma = math.min(1.0, g.shake_trauma + 0.60)
	if g.lives <= 0 {
		g.state = .game_over
	} else {
		g.reset_stage()
	}
}
