module main

import math
import rand

pub fn new_nuclear_throne_game() NuclearThroneGame {
	mut game := NuclearThroneGame{
		high_score: load_save_data().high_score
	}
	game.start_new_game()
	return game
}

pub fn (mut g NuclearThroneGame) start_new_game() {
	g.stage = 1
	g.substage = 1
	g.score = 0
	g.game_over = false
	g.victory = false
	g.mutation_screen = false
	g.screen_shake = 0.0
	g.rads_to_next_level = 30
	g.boss_spawned = false

	g.player = Player{
		x: 600.0
		y: 600.0
		vx: 0
		vy: 0
		w: 24
		h: 24
		hp: 8
		max_hp: 8
		rads: 0
		level: 1
		weapon: .revolver
		secondary_weapon: .shotgun
		ammo: 100
		max_ammo: 200
		character: .fish
		roll_timer: 0
		shield_timer: 0
		invuln_timer: 0
		shoot_cooldown: 0
		aim_angle: 0
		kills: 0
	}

	g.active_mutations.clear()
	g.generate_stage()
}

pub fn (mut g NuclearThroneGame) generate_stage() {
	g.camera_x = g.player.x - 400.0
	g.camera_y = g.player.y - 300.0
	g.bullets.clear()
	g.enemies.clear()
	g.pickups.clear()
	g.particles.clear()
	g.boss_spawned = false

	// Reallocate 30x30 arena grid
	g.grid = [][]WallBlock{len: g.rows, init: []WallBlock{len: g.cols, init: WallBlock{solid: false, hp: 1}}}

	// Outer boundary walls
	for r in 0 .. g.rows {
		g.grid[r][0] = WallBlock{solid: true, hp: 999}
		g.grid[r][g.cols - 1] = WallBlock{solid: true, hp: 999}
	}
	for c in 0 .. g.cols {
		g.grid[0][c] = WallBlock{solid: true, hp: 999}
		g.grid[g.rows - 1][c] = WallBlock{solid: true, hp: 999}
	}

	// Random wall pillars & cover
	for r in 3 .. g.rows - 3 {
		for c in 3 .. g.cols - 3 {
			// Keep center clear around spawn
			if r >= 12 && r <= 18 && c >= 12 && c <= 18 {
				continue
			}
			if (rand.intn(100) or { 0 }) < 22 {
				g.grid[r][c] = WallBlock{solid: true, hp: 3}
			}
		}
	}

	// Place Chests
	g.pickups << Pickup{
		x: 300.0
		y: 300.0
		kind: .weapon_chest
		weapon_kind: .machinegun
		active: true
	}
	g.pickups << Pickup{
		x: 900.0
		y: 900.0
		kind: .weapon_chest
		weapon_kind: .laser_rifle
		active: true
	}

	// Spawn Enemies based on floor
	if g.substage == 3 {
		// Boss Floor!
		g.spawn_boss()
	} else {
		// Regular stage enemies
		enemy_count := 12 + g.stage * 4 + g.substage * 3
		for _ in 0 .. enemy_count {
			mut rx := f64(3 + rand.intn(g.cols - 6) or { 5 }) * f64(g.tile_size)
			mut ry := f64(3 + rand.intn(g.rows - 6) or { 5 }) * f64(g.tile_size)
			
			// Don't spawn on top of player
			if math.abs(rx - g.player.x) < 150.0 && math.abs(ry - g.player.y) < 150.0 {
				rx += 250.0
			}

			roll := rand.intn(100) or { 0 }
			if roll < 35 {
				g.enemies << Enemy{
					x: rx
					y: ry
					vx: 0
					vy: 0
					w: 20
					h: 20
					hp: 3
					max_hp: 3
					kind: .maggot
					active: true
				}
			} else if roll < 65 {
				g.enemies << Enemy{
					x: rx
					y: ry
					vx: 0
					vy: 0
					w: 24
					h: 24
					hp: 6
					max_hp: 6
					kind: .bandit
					active: true
				}
			} else if roll < 85 {
				g.enemies << Enemy{
					x: rx
					y: ry
					vx: 0
					vy: 0
					w: 28
					h: 28
					hp: 10
					max_hp: 10
					kind: .scorpion
					active: true
				}
			} else {
				g.enemies << Enemy{
					x: rx
					y: ry
					vx: 0
					vy: 0
					w: 22
					h: 22
					hp: 5
					max_hp: 5
					kind: .assassin
					active: true
				}
			}
		}
	}
}

fn (mut g NuclearThroneGame) spawn_boss() {
	g.boss_spawned = true
	g.enemies << Enemy{
		x: 600.0
		y: 250.0
		vx: 0
		vy: 0
		w: 48
		h: 48
		hp: 80
		max_hp: 80
		kind: .big_bandit
		active: true
	}
}

pub fn (mut g NuclearThroneGame) update(dt f64, move_x f64, move_y f64, aim_angle f64, shoot bool, ability bool, swap_weapon bool) {
	if g.game_over || g.victory {
		return
	}

	if g.screen_shake > 0 {
		g.screen_shake -= dt * 5.0
		if g.screen_shake < 0 {
			g.screen_shake = 0
		}
	}

	if g.mutation_screen {
		return
	}

	g.player.aim_angle = aim_angle

	if swap_weapon {
		g.swap_weapons()
	}

	g.update_player(dt, move_x, move_y, shoot, ability)
	g.update_bullets(dt)
	g.update_enemies(dt)
	g.update_pickups(dt)
	g.update_particles(dt)

	// Smooth Camera Tracking
	target_cam_x := g.player.x - 400.0
	target_cam_y := g.player.y - 300.0
	g.camera_x += (target_cam_x - g.camera_x) * 6.0 * dt
	g.camera_y += (target_cam_y - g.camera_y) * 6.0 * dt

	// Check stage clear condition
	if g.enemies.len == 0 && !g.mutation_screen {
		if g.substage >= 3 {
			if g.stage >= 2 {
				g.victory = true
				g.score += 10000 + g.player.kills * 100
				if g.score > g.high_score {
					g.high_score = g.score
					mut sd := load_save_data()
					sd.high_score = g.high_score
					save_data_to_file(&sd)
				}
			} else {
				g.stage++
				g.substage = 1
				g.score += 2000
				g.player.x = 600.0
				g.player.y = 600.0
				g.generate_stage()
			}
		} else {
			g.substage++
			g.score += 1000
			g.player.x = 600.0
			g.player.y = 600.0
			g.generate_stage()
		}
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

fn (mut g NuclearThroneGame) swap_weapons() {
	tmp := g.player.weapon
	g.player.weapon = g.player.secondary_weapon
	g.player.secondary_weapon = tmp
}

fn (mut g NuclearThroneGame) update_player(dt f64, move_x f64, move_y f64, shoot bool, ability bool) {
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
	if p.roll_timer > 0 {
		p.roll_timer -= dt
		if p.roll_timer < 0 {
			p.roll_timer = 0
		}
	}
	if p.shield_timer > 0 {
		p.shield_timer -= dt
		if p.shield_timer < 0 {
			p.shield_timer = 0
		}
	}

	// Ability trigger
	if ability {
		match p.character {
			.fish {
				if p.roll_timer <= 0 {
					p.roll_timer = 0.5
					p.invuln_timer = 0.4
					roll_speed := 450.0
					p.vx = math.cos(p.aim_angle) * roll_speed
					p.vy = math.sin(p.aim_angle) * roll_speed
				}
			}
			.crystal {
				if p.shield_timer <= 0 {
					p.shield_timer = 1.5
				}
			}
			.robot {
				// Convert secondary weapon to ammo & health
				p.hp = math.min(p.max_hp, p.hp + 2)
				p.ammo = math.min(p.max_ammo, p.ammo + 40)
			}
		}
	}

	// Player Movement Speed & Multipliers
	mut move_speed := 200.0
	for m in g.active_mutations {
		if m == .extra_feet {
			move_speed = 260.0
		}
	}

	if p.roll_timer <= 0 {
		p.vx = move_x * move_speed
		p.vy = move_y * move_speed
	}

	p.x += p.vx * dt
	g.check_player_wall_collision_x()
	p.y += p.vy * dt
	g.check_player_wall_collision_y()

	// Shooting
	if shoot && p.shoot_cooldown <= 0 && p.ammo > 0 {
		g.fire_player_weapon()
	}
}

fn (mut g NuclearThroneGame) fire_player_weapon() {
	mut p := &g.player
	p.ammo--
	g.screen_shake = 0.12
	g.last_sound_event = if p.weapon == .laser_rifle { 'laser' } else { 'shoot' }

	match p.weapon {
		.revolver {
			p.shoot_cooldown = 0.16
			g.bullets << Bullet{
				x: p.x + p.w / 2
				y: p.y + p.h / 2
				dx: math.cos(p.aim_angle) * 700.0
				dy: math.sin(p.aim_angle) * 700.0
				w: 8
				h: 8
				damage: 2
				lifetime: 1.2
				from_player: true
				color: Color{r: 255, g: 220, b: 60}
			}
		}
		.shotgun {
			p.shoot_cooldown = 0.45
			for i in -2 .. 3 {
				spread := p.aim_angle + f64(i) * 0.12
				g.bullets << Bullet{
					x: p.x + p.w / 2
					y: p.y + p.h / 2
					dx: math.cos(spread) * 600.0
					dy: math.sin(spread) * 600.0
					w: 6
					h: 6
					damage: 1
					lifetime: 0.6
					from_player: true
					color: Color{r: 255, g: 160, b: 40}
				}
			}
		}
		.laser_rifle {
			p.shoot_cooldown = 0.25
			mut dmg := 4
			for m in g.active_mutations {
				if m == .laser_brain {
					dmg = 8
				}
			}
			g.bullets << Bullet{
				x: p.x + p.w / 2
				y: p.y + p.h / 2
				dx: math.cos(p.aim_angle) * 1100.0
				dy: math.sin(p.aim_angle) * 1100.0
				w: 12
				h: 12
				damage: dmg
				lifetime: 1.0
				from_player: true
				is_laser: true
				color: Color{r: 80, g: 240, b: 255}
			}
		}
		.grenade_launcher {
			p.shoot_cooldown = 0.60
			g.bullets << Bullet{
				x: p.x + p.w / 2
				y: p.y + p.h / 2
				dx: math.cos(p.aim_angle) * 450.0
				dy: math.sin(p.aim_angle) * 450.0
				w: 10
				h: 10
				damage: 8
				lifetime: 1.5
				from_player: true
				is_explosive: true
				color: Color{r: 255, g: 80, b: 40}
			}
		}
		.machinegun {
			p.shoot_cooldown = 0.08
			spread := p.aim_angle + (rand.f64() - 0.5) * 0.15
			g.bullets << Bullet{
				x: p.x + p.w / 2
				y: p.y + p.h / 2
				dx: math.cos(spread) * 750.0
				dy: math.sin(spread) * 750.0
				w: 6
				h: 6
				damage: 1
				lifetime: 1.0
				from_player: true
				color: Color{r: 255, g: 240, b: 120}
			}
		}
		.crossbow {
			p.shoot_cooldown = 0.50
			g.bullets << Bullet{
				x: p.x + p.w / 2
				y: p.y + p.h / 2
				dx: math.cos(p.aim_angle) * 900.0
				dy: math.sin(p.aim_angle) * 900.0
				w: 10
				h: 6
				damage: 6
				lifetime: 1.3
				from_player: true
				color: Color{r: 200, g: 200, b: 220}
			}
		}
	}
}

fn (mut g NuclearThroneGame) check_player_wall_collision_x() {
	p := &g.player
	min_c := math.max(0, int(p.x / f64(g.tile_size)))
	max_c := math.min(g.cols - 1, int((p.x + p.w) / f64(g.tile_size)))
	min_r := math.max(0, int(p.y / f64(g.tile_size)))
	max_r := math.min(g.rows - 1, int((p.y + p.h) / f64(g.tile_size)))

	for r in min_r .. max_r + 1 {
		for c in min_c .. max_c + 1 {
			if g.grid[r][c].solid {
				bx_left := f64(c * g.tile_size)
				bx_right := bx_left + f64(g.tile_size)
				by_top := f64(r * g.tile_size)
				by_bot := by_top + f64(g.tile_size)

				if p.x < bx_right && p.x + p.w > bx_left && p.y < by_bot && p.y + p.h > by_top {
					if p.vx > 0 {
						g.player.x = bx_left - p.w
					} else if p.vx < 0 {
						g.player.x = bx_right
					}
				}
			}
		}
	}
}

fn (mut g NuclearThroneGame) check_player_wall_collision_y() {
	p := &g.player
	min_c := math.max(0, int(p.x / f64(g.tile_size)))
	max_c := math.min(g.cols - 1, int((p.x + p.w) / f64(g.tile_size)))
	min_r := math.max(0, int(p.y / f64(g.tile_size)))
	max_r := math.min(g.rows - 1, int((p.y + p.h) / f64(g.tile_size)))

	for r in min_r .. max_r + 1 {
		for c in min_c .. max_c + 1 {
			if g.grid[r][c].solid {
				bx_left := f64(c * g.tile_size)
				bx_right := bx_left + f64(g.tile_size)
				by_top := f64(r * g.tile_size)
				by_bot := by_top + f64(g.tile_size)

				if p.x < bx_right && p.x + p.w > bx_left && p.y < by_bot && p.y + p.h > by_top {
					if p.vy > 0 {
						g.player.y = by_top - p.h
					} else if p.vy < 0 {
						g.player.y = by_bot
					}
				}
			}
		}
	}
}

fn (mut g NuclearThroneGame) update_bullets(dt f64) {
	for mut b in g.bullets {
		if b.lifetime <= 0 {
			continue
		}
		b.lifetime -= dt
		b.x += b.dx * dt
		b.y += b.dy * dt

		// Check wall collisions
		c := int(b.x / f64(g.tile_size))
		r := int(b.y / f64(g.tile_size))
		if c >= 0 && c < g.cols && r >= 0 && r < g.rows {
			if g.grid[r][c].solid {
				b.lifetime = 0
				if b.is_explosive {
					g.trigger_explosion(b.x, b.y, 60.0, 15)
				} else {
					if g.grid[r][c].hp < 999 {
						g.grid[r][c].hp--
						if g.grid[r][c].hp <= 0 {
							g.grid[r][c].solid = false
						}
					}
				}
			}
		}

		// Bullet vs Player/Enemy hit test
		if b.from_player {
			for mut e in g.enemies {
				if !e.active {
					continue
				}
				if b.x >= e.x && b.x <= e.x + e.w && b.y >= e.y && b.y <= e.y + e.h {
					e.hp -= b.damage
					if !b.is_laser {
						b.lifetime = 0
					}
					g.spawn_particles(b.x, b.y, 6, Color{r: 255, g: 100, b: 50})
					if b.is_explosive {
						g.trigger_explosion(b.x, b.y, 60.0, 15)
					}
					if e.hp <= 0 {
						g.kill_enemy(mut e)
					}
				}
			}
		} else {
			// Enemy bullet hitting player
			p := &g.player
			if b.x >= p.x && b.x <= p.x + p.w && b.y >= p.y && b.y <= p.y + p.h {
				b.lifetime = 0
				if p.shield_timer > 0 {
					// Crystal Shield absorbs bullet!
					g.spawn_particles(b.x, b.y, 8, Color{r: 100, g: 255, b: 255})
				} else if p.invuln_timer <= 0 {
					g.player.hp -= b.damage
					g.player.invuln_timer = 1.0
					g.screen_shake = 0.3
					g.spawn_particles(p.x, p.y, 10, Color{r: 255, g: 40, b: 40})
				}
			}
		}
	}
	g.bullets = g.bullets.filter(it.lifetime > 0)
}

fn (mut g NuclearThroneGame) trigger_explosion(x f64, y f64, radius f64, damage int) {
	g.screen_shake = 0.4
	g.spawn_particles(x, y, 24, Color{r: 255, g: 140, b: 20})
	g.last_sound_event = 'explosion'

	// Damage enemies in splash radius
	for mut e in g.enemies {
		if !e.active {
			continue
		}
		dx := (e.x + e.w / 2) - x
		dy := (e.y + e.h / 2) - y
		dist := math.sqrt(dx * dx + dy * dy)
		if dist <= radius {
			e.hp -= damage
			if e.hp <= 0 {
				g.kill_enemy(mut e)
			}
		}
	}
}

fn (mut g NuclearThroneGame) kill_enemy(mut e Enemy) {
	e.active = false
	g.player.kills++
	g.score += e.max_hp * 50

	// Bloodlust mutation heal check
	for m in g.active_mutations {
		if m == .bloodlust {
			if (rand.intn(100) or { 0 }) < 25 {
				g.player.hp = math.min(g.player.max_hp, g.player.hp + 1)
			}
		}
	}

	// Drop Rads
	rad_count := if e.kind == .big_bandit { 25 } else { 3 + e.max_hp / 2 }
	for _ in 0 .. rad_count {
		rx := e.x + (rand.f64() - 0.5) * 30.0
		ry := e.y + (rand.f64() - 0.5) * 30.0
		g.pickups << Pickup{
			x: rx
			y: ry
			kind: .rad
			amount: 1
			active: true
		}
	}
}

fn (mut g NuclearThroneGame) update_enemies(dt f64) {
	p := &g.player
	for mut e in g.enemies {
		if !e.active {
			continue
		}
		dx := (p.x + p.w / 2) - (e.x + e.w / 2)
		dy := (p.y + p.h / 2) - (e.y + e.h / 2)
		dist := math.sqrt(dx * dx + dy * dy)
		e.angle = math.atan2(dy, dx)
		e.shoot_timer += dt

		match e.kind {
			.maggot {
				// Melee rusher
				if dist > 10.0 {
					e.x += (dx / dist) * 130.0 * dt
					e.y += (dy / dist) * 130.0 * dt
				}
				if dist < 20.0 && g.player.invuln_timer <= 0 && g.player.shield_timer <= 0 {
					g.player.hp--
					g.player.invuln_timer = 0.8
					g.screen_shake = 0.25
				}
			}
			.bandit {
				// Ranged shooter
				if dist > 200.0 {
					e.x += (dx / dist) * 80.0 * dt
					e.y += (dy / dist) * 80.0 * dt
				}
				if e.shoot_timer >= 1.8 {
					e.shoot_timer = 0
					g.bullets << Bullet{
						x: e.x + e.w / 2
						y: e.y + e.h / 2
						dx: math.cos(e.angle) * 380.0
						dy: math.sin(e.angle) * 380.0
						w: 6
						h: 6
						damage: 1
						lifetime: 1.5
						from_player: false
						color: Color{r: 255, g: 80, b: 80}
					}
				}
			}
			.scorpion {
				// Toxic triple shooter
				if e.shoot_timer >= 2.5 {
					e.shoot_timer = 0
					for i in -1 .. 2 {
						spread := e.angle + f64(i) * 0.20
						g.bullets << Bullet{
							x: e.x + e.w / 2
							y: e.y + e.h / 2
							dx: math.cos(spread) * 320.0
							dy: math.sin(spread) * 320.0
							w: 8
							h: 8
							damage: 2
							lifetime: 1.8
							from_player: false
							color: Color{r: 60, g: 255, b: 80}
						}
					}
				}
			}
			.assassin {
				// Stealth lunger
				if dist < 250.0 {
					e.x += (dx / dist) * 220.0 * dt
					e.y += (dy / dist) * 220.0 * dt
				}
				if dist < 24.0 && g.player.invuln_timer <= 0 && g.player.shield_timer <= 0 {
					g.player.hp -= 2
					g.player.invuln_timer = 1.0
					g.screen_shake = 0.35
				}
			}
			.big_bandit {
				// BOSS minigun spray & charge
				if e.shoot_timer >= 0.12 {
					e.shoot_timer = 0
					spread := e.angle + (rand.f64() - 0.5) * 0.40
					g.bullets << Bullet{
						x: e.x + e.w / 2
						y: e.y + e.h / 2
						dx: math.cos(spread) * 440.0
						dy: math.sin(spread) * 440.0
						w: 8
						h: 8
						damage: 1
						lifetime: 2.0
						from_player: false
						color: Color{r: 255, g: 120, b: 40}
					}
				}
			}
		}
	}
	g.enemies = g.enemies.filter(it.active)
}

fn (mut g NuclearThroneGame) update_pickups(dt f64) {
	p := &g.player
	for mut pk in g.pickups {
		if !pk.active {
			continue
		}
		dx := (p.x + p.w / 2) - pk.x
		dy := (p.y + p.h / 2) - pk.y
		dist := math.sqrt(dx * dx + dy * dy)

		if dist < 100.0 {
			pk.x += (dx / dist) * 240.0 * dt
			pk.y += (dy / dist) * 240.0 * dt
		}

		if dist < 25.0 {
			pk.active = false
			match pk.kind {
				.rad {
					g.player.rads += pk.amount
					g.last_sound_event = 'rad'
					if g.player.rads >= g.rads_to_next_level {
						g.level_up()
					}
				}
				.ammo {
					g.player.ammo = math.min(g.player.max_ammo, g.player.ammo + 30)
				}
				.health {
					g.player.hp = math.min(g.player.max_hp, g.player.hp + 2)
				}
				.weapon_chest {
					g.player.secondary_weapon = pk.weapon_kind
					g.player.ammo = g.player.max_ammo
				}
			}
			g.spawn_particles(pk.x, pk.y, 6, Color{r: 80, g: 255, b: 100})
		}
	}
	g.pickups = g.pickups.filter(it.active)
}

fn (mut g NuclearThroneGame) level_up() {
	g.player.rads -= g.rads_to_next_level
	g.player.level++
	g.rads_to_next_level += 25
	g.mutation_screen = true
	g.available_mutations = [.bloodlust, .rhino_skin, .scavenger, .laser_brain, .extra_feet]
}

pub fn (mut g NuclearThroneGame) select_mutation(idx int) {
	if idx < 0 || idx >= g.available_mutations.len {
		return
	}
	mut m := g.available_mutations[idx]
	g.active_mutations << m
	if m == .rhino_skin {
		g.player.max_hp += 2
		g.player.hp += 2
	}
	g.mutation_screen = false
}

fn (mut g NuclearThroneGame) update_particles(dt f64) {
	for mut pt in g.particles {
		pt.life -= dt
		pt.x += pt.dx * dt
		pt.y += pt.dy * dt
	}
	g.particles = g.particles.filter(it.life > 0)
}

fn (mut g NuclearThroneGame) spawn_particles(x f64, y f64, count int, color Color) {
	for _ in 0 .. count {
		angle := rand.f64() * 2.0 * math.pi
		speed := 30.0 + rand.f64() * 120.0
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
