module main

import math
import rand

const world_w = 800
const world_h = 600
const max_lives = 5

enum PowerUpType {
	spread_shot
	shield
	rapid_fire
	emp_nuke
	plasma_beam
	extra_life
}

struct PowerUp {
pub mut:
	x     f64
	y     f64
	dx    f64
	dy    f64
	kind  PowerUpType
	timer f64 = 10.0
}

enum AsteroidSize {
	large
	medium
	small
}

struct Asteroid {
pub mut:
	x         f64
	y         f64
	dx        f64
	dy        f64
	size      AsteroidSize
	radius    f64
	rot       f64
	rot_speed f64
	shape     []f64 // radiuses offset for 10 vertices
}

struct Bullet {
pub mut:
	x         f64
	y         f64
	dx        f64
	dy        f64
	life      f64 = 1.2
	is_plasma bool
	is_ufo    bool
}

struct Ship {
pub mut:
	x              f64 = world_w / 2.0
	y              f64 = world_h / 2.0
	dx             f64
	dy             f64
	angle          f64 = -math.pi / 2.0
	thrusting      bool
	invuln_timer   f64 = 3.0
	active_powerup PowerUpType = .spread_shot
	powerup_timer  f64
	has_powerup    bool
	shield_active  bool
	shield_hits    int
	fire_cooldown  f64
}

struct Ufo {
pub mut:
	x          f64
	y          f64
	dx         f64
	dy         f64
	is_hunter  bool
	fire_timer f64
	active     bool
	radius     f64 = 16.0
}

struct AsteroidsGame {
pub mut:
	ship               Ship
	asteroids          []Asteroid
	bullets            []Bullet
	powerups           []PowerUp
	ufos               []Ufo
	score              int
	lives              int  = 3
	wave               int  = 1
	game_over          bool
	ufo_spawn_timer    f64
	ufo_spawn_interval f64  = 12.0
	emp_triggered      bool
	shake_trauma       f64
	last_sound_event   string
	last_sound_param   int
}

fn new_asteroids_game() AsteroidsGame {
	mut game := AsteroidsGame{
		ship: Ship{}
	}
	game.reset()
	return game
}

fn (mut g AsteroidsGame) reset() {
	g.ship = Ship{
		x: world_w / 2.0
		y: world_h / 2.0
	}
	g.asteroids = []Asteroid{}
	g.bullets = []Bullet{}
	g.powerups = []PowerUp{}
	g.ufos = []Ufo{}
	g.score = 0
	g.lives = 3
	g.wave = 1
	g.game_over = false
	g.ufo_spawn_timer = 0.0
	g.emp_triggered = false
	g.shake_trauma = 0.0
	g.last_sound_event = ''
	g.spawn_wave()
}

fn (mut g AsteroidsGame) spawn_wave() {
	g.asteroids.clear()
	count := 3 + g.wave
	for _ in 0 .. count {
		g.spawn_asteroid_at_edge()
	}
}

fn (mut g AsteroidsGame) spawn_asteroid_at_edge() {
	mut x := 0.0
	mut y := 0.0
	side := rand.intn(4) or { 0 }
	match side {
		0 {
			x = rand.f64() * world_w
			y = -30.0
		}
		1 {
			x = world_w + 30.0
			y = rand.f64() * world_h
		}
		2 {
			x = rand.f64() * world_w
			y = world_h + 30.0
		}
		else {
			x = -30.0
			y = rand.f64() * world_h
		}
	}

	angle := rand.f64() * 2.0 * math.pi
	speed := 40.0 + rand.f64() * 40.0 + f64(g.wave * 5)
	dx := math.cos(angle) * speed
	dy := math.sin(angle) * speed

	g.spawn_asteroid(x, y, dx, dy, .large)
}

fn (mut g AsteroidsGame) spawn_asteroid(x f64, y f64, dx f64, dy f64, size AsteroidSize) {
	radius := match size {
		.large { 36.0 }
		.medium { 22.0 }
		.small { 12.0 }
	}

	mut shape := []f64{cap: 10}
	for _ in 0 .. 10 {
		offset := 0.75 + rand.f64() * 0.5
		shape << offset
	}

	rot_speed := (rand.f64() - 0.5) * 3.0

	g.asteroids << Asteroid{
		x:         x
		y:         y
		dx:        dx
		dy:        dy
		size:      size
		radius:    radius
		rot:       rand.f64() * 2.0 * math.pi
		rot_speed: rot_speed
		shape:     shape
	}
}

fn (mut g AsteroidsGame) trigger_hyperspace() {
	if g.game_over {
		return
	}
	g.ship.x = rand.f64() * world_w
	g.ship.y = rand.f64() * world_h
	g.ship.dx = 0.0
	g.ship.dy = 0.0
	g.ship.invuln_timer = 1.0
	g.shake_trauma = math.min(1.0, g.shake_trauma + 0.25)
	g.last_sound_event = 'warp'
}

fn (mut g AsteroidsGame) activate_shield() {
	if g.game_over {
		return
	}
	g.ship.shield_active = true
	g.ship.shield_hits = 3
	g.last_sound_event = 'shield'
}

fn (mut g AsteroidsGame) step(dt f64, rot_input f64, thrust_input bool, fire_input bool, hyperspace_input bool, shield_input bool) {
	if g.game_over {
		return
	}
	g.last_sound_event = ''
	g.emp_triggered = false
	if g.shake_trauma > 0.0 {
		g.shake_trauma = math.max(0.0, g.shake_trauma - dt * 2.2)
	}

	// Hyperspace / Shield controls
	if hyperspace_input {
		g.trigger_hyperspace()
	}
	if shield_input && !g.ship.shield_active {
		g.activate_shield()
	}

	// Ship Rotation & Thrust
	g.ship.angle += rot_input * 4.0 * dt
	g.ship.thrusting = thrust_input

	if thrust_input {
		accel := 350.0 * dt
		g.ship.dx += math.cos(g.ship.angle) * accel
		g.ship.dy += math.sin(g.ship.angle) * accel

		// Cap max ship speed
		speed := math.sqrt(g.ship.dx * g.ship.dx + g.ship.dy * g.ship.dy)
		if speed > 400.0 {
			g.ship.dx = (g.ship.dx / speed) * 400.0
			g.ship.dy = (g.ship.dy / speed) * 400.0
		}
	} else {
		// Drag / friction
		g.ship.dx *= math.pow(0.98, dt * 60.0)
		g.ship.dy *= math.pow(0.98, dt * 60.0)
	}

	// Move ship
	g.ship.x += g.ship.dx * dt
	g.ship.y += g.ship.dy * dt

	// Wrap ship around edges
	if g.ship.x < 0 {
		g.ship.x += world_w
	} else if g.ship.x > world_w {
		g.ship.x -= world_w
	}
	if g.ship.y < 0 {
		g.ship.y += world_h
	} else if g.ship.y > world_h {
		g.ship.y -= world_h
	}

	// Timers
	if g.ship.invuln_timer > 0.0 {
		g.ship.invuln_timer -= dt
		if g.ship.invuln_timer < 0.0 {
			g.ship.invuln_timer = 0.0
		}
	}
	if g.ship.fire_cooldown > 0.0 {
		g.ship.fire_cooldown -= dt
	}
	if g.ship.has_powerup {
		g.ship.powerup_timer -= dt
		if g.ship.powerup_timer <= 0.0 {
			g.ship.has_powerup = false
		}
	}

	// Fire logic
	if fire_input && g.ship.fire_cooldown <= 0.0 {
		g.fire_bullet()
	}

	// UFO Spawner
	g.ufo_spawn_timer += dt
	if g.ufo_spawn_timer >= g.ufo_spawn_interval && g.ufos.len < 2 {
		g.ufo_spawn_timer = 0.0
		g.spawn_ufo()
	}

	// Update UFOs
	for i := g.ufos.len - 1; i >= 0; i-- {
		mut ufo := g.ufos[i]
		ufo.x += ufo.dx * dt
		ufo.y += ufo.dy * dt
		ufo.fire_timer += dt

		if ufo.fire_timer >= 1.8 {
			ufo.fire_timer = 0.0
			g.ufo_fire(ufo)
		}

		// Despawn offscreen
		if ufo.x < -40.0 || ufo.x > world_w + 40.0 || ufo.y < -40.0 || ufo.y > world_h + 40.0 {
			g.ufos.delete(i)
		} else {
			g.ufos[i] = ufo
		}
	}

	// Update Asteroids
	for i in 0 .. g.asteroids.len {
		mut ast := g.asteroids[i]
		ast.x += ast.dx * dt
		ast.y += ast.dy * dt
		ast.rot += ast.rot_speed * dt

		if ast.x < -40.0 {
			ast.x += world_w + 80.0
		} else if ast.x > world_w + 40.0 {
			ast.x -= world_w + 80.0
		}
		if ast.y < -40.0 {
			ast.y += world_h + 80.0
		} else if ast.y > world_h + 40.0 {
			ast.y -= world_h + 80.0
		}
		g.asteroids[i] = ast
	}

	// Update Bullets
	for i := g.bullets.len - 1; i >= 0; i-- {
		mut b := g.bullets[i]
		b.x += b.dx * dt
		b.y += b.dy * dt
		b.life -= dt

		if b.x < 0 {
			b.x += world_w
		} else if b.x > world_w {
			b.x -= world_w
		}
		if b.y < 0 {
			b.y += world_h
		} else if b.y > world_h {
			b.y -= world_h
		}

		if b.life <= 0.0 {
			g.bullets.delete(i)
		} else {
			g.bullets[i] = b
		}
	}

	// Update Power-ups
	for i := g.powerups.len - 1; i >= 0; i-- {
		mut p := g.powerups[i]
		p.x += p.dx * dt
		p.y += p.dy * dt
		p.timer -= dt

		// Collect check
		dist := math.sqrt((g.ship.x - p.x) * (g.ship.x - p.x) + (g.ship.y - p.y) * (g.ship.y - p.y))
		if dist < 26.0 {
			g.apply_powerup(p.kind)
			g.powerups.delete(i)
			g.last_sound_event = 'powerup'
			continue
		}

		if p.timer <= 0.0 {
			g.powerups.delete(i)
		} else {
			g.powerups[i] = p
		}
	}

	// Collisions: Bullets vs Asteroids
	for i := g.bullets.len - 1; i >= 0; i-- {
		if i >= g.bullets.len {
			continue
		}
		b := g.bullets[i]
		if b.is_ufo {
			continue
		}

		for j := g.asteroids.len - 1; j >= 0; j-- {
			ast := g.asteroids[j]
			dist := math.sqrt((b.x - ast.x) * (b.x - ast.x) + (b.y - ast.y) * (b.y - ast.y))

			if dist < ast.radius {
				// Destroy / split asteroid
				g.score += match ast.size {
					.large { 20 }
					.medium { 50 }
					.small { 100 }
				}
				g.shake_trauma = math.min(1.0, g.shake_trauma + match ast.size {
					.large { 0.22 }
					.medium { 0.15 }
					.small { 0.10 }
				})
				g.last_sound_event = 'explosion'
				g.last_sound_param = match ast.size {
					.large { 3 }
					.medium { 2 }
					.small { 1 }
				}

				// Spawn powerup chance (20% for large/medium)
				if (ast.size == .large || ast.size == .medium) && rand.f64() < 0.25 {
					g.spawn_powerup(ast.x, ast.y)
				}

				// Split asteroid
				if ast.size == .large {
					g.spawn_asteroid(ast.x, ast.y, ast.dx + 40.0, ast.dy - 30.0, .medium)
					g.spawn_asteroid(ast.x, ast.y, ast.dx - 40.0, ast.dy + 30.0, .medium)
				} else if ast.size == .medium {
					g.spawn_asteroid(ast.x, ast.y, ast.dx + 60.0, ast.dy + 50.0, .small)
					g.spawn_asteroid(ast.x, ast.y, ast.dx - 60.0, ast.dy - 50.0, .small)
				}

				g.asteroids.delete(j)

				// Plasma beam punches through, normal bullets get destroyed
				if !b.is_plasma {
					g.bullets.delete(i)
					break
				}
			}
		}
	}

	// Collisions: Bullets vs UFOs
	for i := g.bullets.len - 1; i >= 0; i-- {
		if i >= g.bullets.len {
			continue
		}
		b := g.bullets[i]
		if b.is_ufo {
			continue
		}

		for j := g.ufos.len - 1; j >= 0; j-- {
			ufo := g.ufos[j]
			dist := math.sqrt((b.x - ufo.x) * (b.x - ufo.x) + (b.y - ufo.y) * (b.y - ufo.y))

			if dist < ufo.radius + 6.0 {
				g.score += if ufo.is_hunter { 500 } else { 200 }
				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.35)
				g.last_sound_event = 'explosion'
				g.last_sound_param = 3
				g.spawn_powerup(ufo.x, ufo.y)
				g.ufos.delete(j)

				if !b.is_plasma {
					g.bullets.delete(i)
					break
				}
			}
		}
	}

	// Collisions: Ship vs Asteroids / UFO Bullets
	if g.ship.invuln_timer <= 0.0 {
		for i := g.asteroids.len - 1; i >= 0; i-- {
			ast := g.asteroids[i]
			dist := math.sqrt((g.ship.x - ast.x) * (g.ship.x - ast.x) + (g.ship.y - ast.y) * (g.ship.y - ast.y))

			if dist < ast.radius + 10.0 {
				g.ship_hit()
				break
			}
		}
	}

	// Collisions: Ship vs UFO Bullets
	if g.ship.invuln_timer <= 0.0 {
		for i := g.bullets.len - 1; i >= 0; i-- {
			b := g.bullets[i]
			if !b.is_ufo {
				continue
			}
			dist := math.sqrt((g.ship.x - b.x) * (g.ship.x - b.x) + (g.ship.y - b.y) * (g.ship.y - b.y))

			if dist < 14.0 {
				g.bullets.delete(i)
				g.ship_hit()
				break
			}
		}
	}

	// Wave progression check
	if g.asteroids.len == 0 {
		g.wave++
		g.spawn_wave()
	}
}

fn (mut g AsteroidsGame) ship_hit() {
	if g.ship.shield_active {
		g.ship.shield_hits--
		g.shake_trauma = math.min(1.0, g.shake_trauma + 0.35)
		g.last_sound_event = 'shield'
		if g.ship.shield_hits <= 0 {
			g.ship.shield_active = false
		}
		g.ship.invuln_timer = 0.8
		return
	}

	g.lives--
	g.shake_trauma = math.min(1.0, g.shake_trauma + 0.65)
	g.last_sound_event = 'explosion'
	g.last_sound_param = 3

	if g.lives <= 0 {
		g.game_over = true
	} else {
		g.ship.x = world_w / 2.0
		g.ship.y = world_h / 2.0
		g.ship.dx = 0.0
		g.ship.dy = 0.0
		g.ship.invuln_timer = 3.0
	}
}

fn (mut g AsteroidsGame) fire_bullet() {
	is_rapid := g.ship.has_powerup && g.ship.active_powerup == .rapid_fire
	is_spread := g.ship.has_powerup && g.ship.active_powerup == .spread_shot
	is_plasma := g.ship.has_powerup && g.ship.active_powerup == .plasma_beam

	speed := if is_plasma { 700.0 } else { 550.0 }
	g.ship.fire_cooldown = if is_rapid { 0.08 } else if is_spread { 0.18 } else { 0.22 }

	if is_plasma {
		g.last_sound_event = 'plasma'
		dx := math.cos(g.ship.angle) * speed + g.ship.dx
		dy := math.sin(g.ship.angle) * speed + g.ship.dy
		g.bullets << Bullet{
			x:         g.ship.x
			y:         g.ship.y
			dx:        dx
			dy:        dy
			life:      1.5
			is_plasma: true
		}
	} else if is_spread {
		g.last_sound_event = 'laser'
		angles := [g.ship.angle - 0.25, g.ship.angle, g.ship.angle + 0.25]
		for a in angles {
			dx := math.cos(a) * speed + g.ship.dx
			dy := math.sin(a) * speed + g.ship.dy
			g.bullets << Bullet{
				x:  g.ship.x
				y:  g.ship.y
				dx: dx
				dy: dy
			}
		}
	} else {
		g.last_sound_event = 'laser'
		dx := math.cos(g.ship.angle) * speed + g.ship.dx
		dy := math.sin(g.ship.angle) * speed + g.ship.dy
		g.bullets << Bullet{
			x:  g.ship.x
			y:  g.ship.y
			dx: dx
			dy: dy
		}
	}
}

fn (mut g AsteroidsGame) spawn_ufo() {
	is_hunter := rand.f64() < 0.5
	y := 50.0 + rand.f64() * (world_h - 100.0)
	dx := if rand.f64() < 0.5 { 80.0 } else { -80.0 }
	x := if dx > 0 { -30.0 } else { world_w + 30.0 }

	g.ufos << Ufo{
		x:         x
		y:         y
		dx:        dx
		dy:        (rand.f64() - 0.5) * 40.0
		is_hunter: is_hunter
	}
}

fn (mut g AsteroidsGame) ufo_fire(ufo Ufo) {
	mut angle := rand.f64() * 2.0 * math.pi
	if ufo.is_hunter {
		// Aim towards player ship
		angle = math.atan2(g.ship.y - ufo.y, g.ship.x - ufo.x) + (rand.f64() - 0.5) * 0.3
	}

	speed := 280.0
	g.bullets << Bullet{
		x:      ufo.x
		y:      ufo.y
		dx:     math.cos(angle) * speed
		dy:     math.sin(angle) * speed
		life:   2.0
		is_ufo: true
	}
}

fn (mut g AsteroidsGame) spawn_powerup(x f64, y f64) {
	kinds := [
		PowerUpType.spread_shot,
		PowerUpType.shield,
		PowerUpType.rapid_fire,
		PowerUpType.emp_nuke,
		PowerUpType.plasma_beam,
		PowerUpType.extra_life,
	]
	idx := rand.intn(kinds.len) or { 0 }
	ang := rand.f64() * 2.0 * math.pi
	sp := 20.0 + rand.f64() * 20.0

	g.powerups << PowerUp{
		x:     x
		y:     y
		dx:    math.cos(ang) * sp
		dy:    math.sin(ang) * sp
		kind:  kinds[idx]
		timer: 10.0
	}
}

fn (mut g AsteroidsGame) apply_powerup(kind PowerUpType) {
	match kind {
		.emp_nuke {
			g.emp_triggered = true
			g.shake_trauma = math.min(1.0, g.shake_trauma + 0.55)
			g.last_sound_event = 'emp'
			// Destroy small asteroids & damage UFOs
			for i := g.asteroids.len - 1; i >= 0; i-- {
				if g.asteroids[i].size == .small {
					g.score += 100
					g.asteroids.delete(i)
				}
			}
			g.ufos.clear()
		}
		.shield {
			g.activate_shield()
		}
		.extra_life {
			if g.lives < max_lives {
				g.lives++
			}
		}
		else {
			g.ship.has_powerup = true
			g.ship.active_powerup = kind
			g.ship.powerup_timer = 10.0
		}
	}
}
