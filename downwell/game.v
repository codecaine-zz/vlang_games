module main

import math
import rand

pub fn new_downwell_game() DownwellGame {
	mut game := DownwellGame{
		high_score: load_save_data().high_score
	}
	game.start_new_game()
	return game
}

pub fn (mut g DownwellGame) start_new_game() {
	g.stage = 1
	g.score = 0
	g.zone = .cavern
	g.game_over = false
	g.victory = false
	g.shop_active = false
	g.screen_shake = 0.0

	g.player = Player{
		x: 7.0 * f64(g.block_size)
		y: 2.0 * f64(g.block_size)
		vx: 0
		vy: 0
		w: 22
		h: 26
		hp: 4
		max_hp: 4
		gems: 0
		ammo: 8
		max_ammo: 8
		weapon: .standard
		facing_right: true
		is_grounded: false
		can_shoot: true
		shoot_cooldown: 0
		combo: 0
		invuln_timer: 0
	}

	g.generate_level()
}

pub fn (mut g DownwellGame) generate_level() {
	g.well_width = 14
	g.well_height = 160
	g.camera_y = 0.0
	g.bullets.clear()
	g.enemies.clear()
	g.pickups.clear()
	g.particles.clear()
	g.shop_items.clear()

	// Reallocate grid
	g.grid = [][]Block{len: g.well_height, init: []Block{len: g.well_width, init: Block{kind: .empty, hp: 1}}}

	// Outer walls
	for y in 0 .. g.well_height {
		g.grid[y][0] = Block{kind: .solid, hp: 999}
		g.grid[y][g.well_width - 1] = Block{kind: .solid, hp: 999}
	}

	// Starting platform
	for x in 1 .. g.well_width - 1 {
		g.grid[4][x] = Block{kind: .solid, hp: 999}
	}
	// Hole in start platform
	g.grid[4][6] = Block{kind: .empty, hp: 0}
	g.grid[4][7] = Block{kind: .empty, hp: 0}

	// Generate well obstacles, destructible blocks, platforms, side shops
	for y in 8 .. g.well_height - 10 {
		// Shop placement
		if y % 45 == 0 {
			g.grid[y][1] = Block{kind: .shop_door, hp: 999}
			g.grid[y + 1][1] = Block{kind: .solid, hp: 999}
			g.grid[y + 1][2] = Block{kind: .solid, hp: 999}
			continue
		}

		// Row pattern generation
		roll := rand.intn(100) or { 0 }
		if roll < 40 {
			// Platform with gap
			gap_x := 1 + rand.intn(g.well_width - 4) or { 3 }
			for x in 1 .. g.well_width - 1 {
				if x < gap_x || x > gap_x + 2 {
					if (x + y) % 3 == 0 {
						g.grid[y][x] = Block{kind: .destructible, hp: 2}
					} else if (x + y) % 7 == 0 {
						g.grid[y][x] = Block{kind: .gem_block, hp: 1}
					} else {
						g.grid[y][x] = Block{kind: .solid, hp: 999}
					}
				}
			}
		} else if roll < 70 {
			// Scattered blocks
			for x in 2 .. g.well_width - 2 {
				if rand.intn(100) or { 0 } < 30 {
					g.grid[y][x] = Block{kind: .destructible, hp: 2}
				}
			}
		}

		// Enemy spawning
		if y % 5 == 0 && rand.intn(100) or { 0 } < 65 {
			ex := f64(2 + rand.intn(g.well_width - 4) or { 2 }) * f64(g.block_size)
			ey := f64(y) * f64(g.block_size)
			eroll := rand.intn(100) or { 0 }

			if eroll < 40 {
				g.enemies << Enemy{
					x: ex
					y: ey
					vx: if (rand.intn(2) or { 0 }) == 0 { 60.0 } else { -60.0 }
					vy: 0
					w: 24
					h: 20
					hp: 1
					max_hp: 1
					kind: .bat
					is_red: false
					active: true
				}
			} else if eroll < 70 {
				g.enemies << Enemy{
					x: ex
					y: ey
					vx: if (rand.intn(2) or { 0 }) == 0 { 30.0 } else { -30.0 }
					vy: 0
					w: 26
					h: 22
					hp: 2
					max_hp: 2
					kind: .turtle
					is_red: true
					active: true
				}
			} else if eroll < 90 {
				g.enemies << Enemy{
					x: ex
					y: ey
					vx: 0
					vy: if (rand.intn(2) or { 0 }) == 0 { 40.0 } else { -40.0 }
					w: 22
					h: 22
					hp: 2
					max_hp: 2
					kind: .eye
					is_red: false
					active: true
				}
			} else {
				g.enemies << Enemy{
					x: f64(g.block_size)
					y: ey
					vx: 0
					vy: 50.0
					w: 20
					h: 20
					hp: 1
					max_hp: 1
					kind: .crawler
					is_red: false
					active: true
				}
			}
		}
	}

	// Bottom zone exit platform
	for x in 1 .. g.well_width - 1 {
		g.grid[g.well_height - 2][x] = Block{kind: .solid, hp: 999}
	}
	g.grid[g.well_height - 2][6] = Block{kind: .empty, hp: 0}
	g.grid[g.well_height - 2][7] = Block{kind: .empty, hp: 0}
}

pub fn (mut g DownwellGame) update(dt f64, key_left bool, key_right bool, key_jump bool, key_shoot bool) {
	if g.game_over || g.victory {
		return
	}

	if g.screen_shake > 0 {
		g.screen_shake -= dt * 5.0
		if g.screen_shake < 0 {
			g.screen_shake = 0
		}
	}

	if g.shop_active {
		return
	}

	g.update_player(dt, key_left, key_right, key_jump, key_shoot)
	g.update_bullets(dt)
	g.update_enemies(dt)
	g.update_pickups(dt)
	g.update_particles(dt)

	// Camera tracking
	target_cam := g.player.y - 200.0
	if target_cam > g.camera_y {
		g.camera_y += (target_cam - g.camera_y) * 8.0 * dt
	}

	// Track depth
	current_depth := g.player.y / f64(g.block_size)
	if current_depth > g.depth {
		g.depth = current_depth
		g.score += int((current_depth - g.depth) * 10.0)
	}

	// Check stage finish condition (falling past bottom)
	if g.player.y > f64((g.well_height - 3) * g.block_size) {
		if g.stage >= 3 {
			g.victory = true
			g.score += 5000 + g.player.gems * 10
			if g.score > g.high_score {
				g.high_score = g.score
				mut sd := load_save_data()
				sd.high_score = g.high_score
				save_data_to_file(&sd)
			}
		} else {
			g.stage++
			g.score += 1000
			g.player.y = 2.0 * f64(g.block_size)
			g.player.vy = 0
			g.generate_level()
		}
	}

	// Check player out of bounds (killed if squished off top of scrolling camera)
	if g.player.y < g.camera_y - 100.0 {
		g.player.hp = 0
	}

	if g.player.hp <= 0 {
		g.game_over = true
		if g.score > g.high_score {
			g.high_score = g.score
			mut sd := load_save_data()
			sd.high_score = g.high_score
			save_data_to_file(&sd)
		}
	}
}

fn (mut g DownwellGame) update_player(dt f64, key_left bool, key_right bool, key_jump bool, key_shoot bool) {
	mut p := &g.player

	if p.invuln_timer > 0 {
		p.invuln_timer -= dt
		if p.invuln_timer < 0 {
			p.invuln_timer = 0
		}
	}
	if p.shoot_cooldown > 0 {
		p.shoot_cooldown -= dt
		if p.shoot_cooldown < 0 {
			p.shoot_cooldown = 0
		}
	}

	// Horizontal movement
	accel := 1200.0
	max_speed := 220.0

	if key_left {
		p.vx -= accel * dt
		if p.vx < -max_speed {
			p.vx = -max_speed
		}
		p.facing_right = false
	} else if key_right {
		p.vx += accel * dt
		if p.vx > max_speed {
			p.vx = max_speed
		}
		p.facing_right = true
	} else {
		p.vx *= math.pow(0.01, dt)
	}

	// Gravity
	gravity := 750.0
	p.vy += gravity * dt
	if p.vy > 550.0 {
		p.vy = 550.0
	}

	// Jump
	if key_jump && p.is_grounded {
		p.vy = -340.0
		p.is_grounded = false
		p.can_shoot = true
		g.last_sound_event = 'jump'
	}

	// Gunboots firing
	want_fire := key_shoot || (key_jump && !p.is_grounded)
	if want_fire && p.can_shoot && p.shoot_cooldown <= 0 && p.ammo > 0 {
		g.fire_gunboots()
	}

	// Move X & Horizontal collisions
	p.x += p.vx * dt
	g.check_player_collision_x()

	// Move Y & Vertical collisions
	p.y += p.vy * dt
	p.is_grounded = false
	g.check_player_collision_y()

	// Enemy interactions (Stomping vs getting hit)
	g.check_player_enemy_collisions()
}

fn (mut g DownwellGame) fire_gunboots() {
	mut p := &g.player
	p.ammo--
	g.screen_shake = 0.15
	g.last_sound_event = 'shoot'

	match p.weapon {
		.standard {
			p.shoot_cooldown = 0.18
			p.vy = math.min(p.vy, -160.0)
			g.bullets << Bullet{
				x: p.x + p.w / 2 - 4
				y: p.y + p.h
				dx: p.vx * 0.2
				dy: 520.0
				w: 8
				h: 16
				damage: 1
				lifetime: 0.8
				from_player: true
			}
		}
		.machinegun {
			p.shoot_cooldown = 0.09
			p.vy = math.min(p.vy, -140.0)
			spread := (rand.f64() - 0.5) * 60.0
			g.bullets << Bullet{
				x: p.x + p.w / 2 - 3
				y: p.y + p.h
				dx: spread
				dy: 600.0
				w: 6
				h: 14
				damage: 1
				lifetime: 0.7
				from_player: true
			}
		}
		.shotgun {
			p.shoot_cooldown = 0.35
			p.vy = math.min(p.vy, -240.0)
			for i in -2 .. 3 {
				g.bullets << Bullet{
					x: p.x + p.w / 2 - 4
					y: p.y + p.h
					dx: f64(i) * 70.0
					dy: 480.0
					w: 8
					h: 12
					damage: 1
					lifetime: 0.5
					from_player: true
				}
			}
		}
		.laser {
			p.shoot_cooldown = 0.28
			p.vy = math.min(p.vy, -200.0)
			g.bullets << Bullet{
				x: p.x + p.w / 2 - 5
				y: p.y + p.h
				dx: 0
				dy: 850.0
				w: 10
				h: 30
				damage: 3
				lifetime: 0.6
				from_player: true
			}
		}
		.burst {
			p.shoot_cooldown = 0.22
			p.vy = math.min(p.vy, -180.0)
			for offset in 0 .. 3 {
				g.bullets << Bullet{
					x: p.x + p.w / 2 - 4
					y: p.y + p.h + f64(offset * 12)
					dx: (rand.f64() - 0.5) * 30.0
					dy: 560.0
					w: 8
					h: 14
					damage: 1
					lifetime: 0.7
					from_player: true
				}
			}
		}
	}

	// Muzzle particles
	for _ in 0 .. 5 {
		g.particles << Particle{
			x: p.x + p.w / 2
			y: p.y + p.h
			dx: (rand.f64() - 0.5) * 120.0
			dy: 100.0 + rand.f64() * 100.0
			life: 0.2
			max_life: 0.2
			color: Color{r: 255, g: 220, b: 80}
			size: 3
		}
	}
}

fn (mut g DownwellGame) check_player_collision_x() {
	mut p := &g.player
	min_bx := math.max(0, int(p.x / f64(g.block_size)))
	max_bx := math.min(g.well_width - 1, int((p.x + p.w) / f64(g.block_size)))
	min_by := math.max(0, int(p.y / f64(g.block_size)))
	max_by := math.min(g.well_height - 1, int((p.y + p.h) / f64(g.block_size)))

	for by in min_by .. max_by + 1 {
		for bx in min_bx .. max_bx + 1 {
			block := g.grid[by][bx]
			if block.kind == .solid || block.kind == .destructible || block.kind == .gem_block {
				bx_left := f64(bx * g.block_size)
				bx_right := bx_left + f64(g.block_size)
				by_top := f64(by * g.block_size)
				by_bot := by_top + f64(g.block_size)

				if p.x < bx_right && p.x + p.w > bx_left && p.y < by_bot && p.y + p.h > by_top {
					if p.vx > 0 {
						p.x = bx_left - p.w
						p.vx = 0
					} else if p.vx < 0 {
						p.x = bx_right
						p.vx = 0
					}
				}
			} else if block.kind == .shop_door {
				bx_left := f64(bx * g.block_size)
				by_top := f64(by * g.block_size)
				if p.x < bx_left + f64(g.block_size) && p.x + p.w > bx_left && p.y < by_top + f64(g.block_size) && p.y + p.h > by_top {
					g.open_shop()
				}
			}
		}
	}
}

fn (mut g DownwellGame) check_player_collision_y() {
	mut p := &g.player
	min_bx := math.max(0, int(p.x / f64(g.block_size)))
	max_bx := math.min(g.well_width - 1, int((p.x + p.w) / f64(g.block_size)))
	min_by := math.max(0, int(p.y / f64(g.block_size)))
	max_by := math.min(g.well_height - 1, int((p.y + p.h) / f64(g.block_size)))

	for by in min_by .. max_by + 1 {
		for bx in min_bx .. max_bx + 1 {
			block := g.grid[by][bx]
			if block.kind == .solid || block.kind == .destructible || block.kind == .gem_block {
				bx_left := f64(bx * g.block_size)
				bx_right := bx_left + f64(g.block_size)
				by_top := f64(by * g.block_size)
				by_bot := by_top + f64(g.block_size)

				if p.x < bx_right && p.x + p.w > bx_left && p.y < by_bot && p.y + p.h > by_top {
					if p.vy > 0 {
						p.y = by_top - p.h
						p.vy = 0
						p.is_grounded = true
						p.ammo = p.max_ammo
						p.can_shoot = true
						p.combo = 0
					} else if p.vy < 0 {
						p.y = by_bot
						p.vy = 0
					}
				}
			}
		}
	}
}

fn (mut g DownwellGame) check_player_enemy_collisions() {
	mut p := &g.player
	for mut e in g.enemies {
		if !e.active {
			continue
		}
		// AABB overlap check
		if p.x < e.x + e.w && p.x + p.w > e.x && p.y < e.y + e.h && p.y + p.h > e.y {
			// Check if player stomps enemy from above
			if p.vy > 0 && p.y + p.h - p.vy * 0.05 <= e.y + e.h * 0.5 {
				if e.is_red {
					// Red enemy hurts on stomp!
					if p.invuln_timer <= 0 {
						p.hp--
						p.invuln_timer = 1.0
						g.screen_shake = 0.3
						p.vy = -200.0
					}
				} else {
					// Successful stomp!
					e.active = false
					p.vy = -280.0
					p.ammo = p.max_ammo
					p.combo++
					g.score += 100 * p.combo
					p.gems += 2 + p.combo
					g.last_sound_event = 'stomp'

					// Spawn reward particles & pickup
					g.spawn_particles(e.x + e.w / 2, e.y + e.h / 2, 10, Color{r: 255, g: 80, b: 80})
					g.pickups << Pickup{
						x: e.x + e.w / 2
						y: e.y + e.h / 2
						kind: .gem
						amount: 3
						active: true
					}
				}
			} else {
				// Side/Bottom collision -> Player takes damage
				if p.invuln_timer <= 0 {
					p.hp--
					p.invuln_timer = 1.2
					g.screen_shake = 0.4
					p.vx = if p.x < e.x { -200.0 } else { 200.0 }
					p.vy = -180.0
					g.last_sound_event = 'hit'
				}
			}
		}
	}
}

fn (mut g DownwellGame) update_bullets(dt f64) {
	for mut b in g.bullets {
		if b.lifetime <= 0 {
			continue
		}
		b.lifetime -= dt
		b.x += b.dx * dt
		b.y += b.dy * dt

		// Check collision with blocks
		bx := int((b.x + b.w / 2) / f64(g.block_size))
		by := int((b.y + b.h / 2) / f64(g.block_size))

		if bx >= 0 && bx < g.well_width && by >= 0 && by < g.well_height {
			mut blk := &g.grid[by][bx]
			if blk.kind == .solid {
				b.lifetime = 0
			} else if blk.kind == .destructible {
				blk.hp--
				b.lifetime = 0
				if blk.hp <= 0 {
					blk.kind = .empty
					g.score += 20
					g.spawn_particles(f64(bx * g.block_size + 16), f64(by * g.block_size + 16), 6, Color{r: 180, g: 140, b: 100})
				}
			} else if blk.kind == .gem_block {
				blk.hp--
				b.lifetime = 0
				if blk.hp <= 0 {
					blk.kind = .empty
					g.score += 50
					g.player.gems += 5
					g.spawn_particles(f64(bx * g.block_size + 16), f64(by * g.block_size + 16), 12, Color{r: 255, g: 215, b: 0})
				}
			}
		}

		// Check collision with enemies
		if b.from_player {
			for mut e in g.enemies {
				if !e.active {
					continue
				}
				if b.x < e.x + e.w && b.x + b.w > e.x && b.y < e.y + e.h && b.y + b.h > e.y {
					e.hp -= b.damage
					b.lifetime = 0
					g.spawn_particles(b.x, b.y, 5, Color{r: 255, g: 120, b: 50})
					if e.hp <= 0 {
						e.active = false
						g.score += 150
						g.player.gems += 4
						g.pickups << Pickup{
							x: e.x + e.w / 2
							y: e.y + e.h / 2
							kind: .gem
							amount: 4
							active: true
						}
					}
				}
			}
		}
	}

	// Filter inactive bullets
	g.bullets = g.bullets.filter(it.lifetime > 0)
}

fn (mut g DownwellGame) update_enemies(dt f64) {
	for mut e in g.enemies {
		if !e.active {
			continue
		}
		e.frame_timer += dt

		match e.kind {
			.bat {
				e.x += e.vx * dt
				e.vy = math.sin(e.frame_timer * 4.0) * 30.0
				e.y += e.vy * dt
				if e.x < f64(g.block_size) || e.x > f64((g.well_width - 1) * g.block_size - int(e.w)) {
					e.vx = -e.vx
				}
			}
			.turtle {
				e.x += e.vx * dt
				if e.x < f64(g.block_size) || e.x > f64((g.well_width - 1) * g.block_size - int(e.w)) {
					e.vx = -e.vx
				}
			}
			.eye {
				e.y += e.vy * dt
				if e.y < g.camera_y || e.y > g.camera_y + 500.0 {
					e.vy = -e.vy
				}
			}
			.crawler {
				e.y += e.vy * dt
				if e.y < 0 || e.y > f64(g.well_height * g.block_size) {
					e.vy = -e.vy
				}
			}
		}
	}
}

fn (mut g DownwellGame) update_pickups(dt f64) {
	p := &g.player
	for mut pk in g.pickups {
		if !pk.active {
			continue
		}
		// Magnet toward player if close
		dx := (p.x + p.w / 2) - pk.x
		dy := (p.y + p.h / 2) - pk.y
		dist := math.sqrt(dx * dx + dy * dy)
		if dist < 120.0 {
			pk.x += (dx / dist) * 220.0 * dt
			pk.y += (dy / dist) * 220.0 * dt
		}

		if dist < 25.0 {
			pk.active = false
			match pk.kind {
				.gem { g.player.gems += pk.amount }
				.health {
					g.player.hp = math.min(g.player.max_hp, g.player.hp + 1)
				}
				.max_health {
					g.player.max_hp++
					g.player.hp++
				}
				.ammo {
					g.player.max_ammo += 2
					g.player.ammo = g.player.max_ammo
				}
			}
			g.spawn_particles(pk.x, pk.y, 8, Color{r: 255, g: 255, b: 255})
		}
	}
	g.pickups = g.pickups.filter(it.active)
}

fn (mut g DownwellGame) update_particles(dt f64) {
	for mut pt in g.particles {
		pt.life -= dt
		pt.x += pt.dx * dt
		pt.y += pt.dy * dt
	}
	g.particles = g.particles.filter(it.life > 0)
}

fn (mut g DownwellGame) spawn_particles(x f64, y f64, count int, color Color) {
	for _ in 0 .. count {
		angle := rand.f64() * 2.0 * math.pi
		speed := 40.0 + rand.f64() * 140.0
		life := 0.2 + rand.f64() * 0.3
		g.particles << Particle{
			x: x
			y: y
			dx: math.cos(angle) * speed
			dy: math.sin(angle) * speed
			life: life
			max_life: life
			color: color
			size: 3
		}
	}
}

pub fn (mut g DownwellGame) open_shop() {
	if g.shop_active {
		return
	}
	g.shop_active = true
	g.shop_items = [
		ShopItem{name: 'Health Refill (+1 HP)', cost: 15, kind: .health, bought: false},
		ShopItem{name: 'Max HP Up (+1 Max)', cost: 30, kind: .max_health, bought: false},
		ShopItem{name: 'Machinegun Boots', cost: 25, kind: .ammo, bought: false},
		ShopItem{name: 'Shotgun Boots', cost: 35, kind: .ammo, bought: false},
	]
}

pub fn (mut g DownwellGame) buy_shop_item(idx int) {
	if idx < 0 || idx >= g.shop_items.len {
		return
	}
	mut item := &g.shop_items[idx]
	if item.bought || g.player.gems < item.cost {
		return
	}
	g.player.gems -= item.cost
	item.bought = true

	match idx {
		0 { g.player.hp = math.min(g.player.max_hp, g.player.hp + 1) }
		1 { g.player.max_hp++; g.player.hp++ }
		2 { g.player.weapon = .machinegun; g.player.max_ammo += 4; g.player.ammo = g.player.max_ammo }
		3 { g.player.weapon = .shotgun; g.player.max_ammo += 2; g.player.ammo = g.player.max_ammo }
		else {}
	}
}

pub fn (mut g DownwellGame) close_shop() {
	g.shop_active = false
}
