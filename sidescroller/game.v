module main

import math
import rand

enum GameState {
	title
	playing
	paused
	stage_clear
	game_over
	victory
}

enum PowerUpType {
	weapon_drop
	shield_core
	overdrive
	combat_drone
	repair_kit
	emp_bomb
	multiplier_orb
}

enum EnemyType {
	scout
	mech
	turret
	kamikaze
	sniper
	boss_behemoth
	boss_dreadnought
	boss_omega
}

struct Player {
pub mut:
	x                f64 = 100.0
	y                f64 = 400.0
	vx               f64
	vy               f64
	w                f64 = 36.0
	h                f64 = 48.0
	hp               f64 = 100.0
	max_hp           f64 = 100.0
	energy           f64 = 100.0
	max_energy       f64 = 100.0
	shield           f64 = 50.0
	max_shield       f64 = 50.0
	active_weapon    WeaponType = .pulse
	ammo             map[string]int
	fire_cooldown    f64
	overdrive_timer  f64
	shield_timer     f64
	invincible_timer f64
	drone_active     bool
	drone_angle      f64
	drone_fire_timer f64
	bombs            int = 3
	is_grounded      bool
	is_crouching     bool
	facing_right     bool = true
	dash_timer       f64
	dash_cooldown    f64
	score            int
	multiplier       int = 1
	mult_timer       f64
}

fn new_player() Player {
	mut ammo_map := map[string]int{}
	ammo_map['PLS'] = 999
	ammo_map['SPD'] = 60
	ammo_map['PLM'] = 30
	ammo_map['MIS'] = 40
	ammo_map['FLM'] = 150
	ammo_map['GRN'] = 25
	ammo_map['LSR'] = 50
	ammo_map['TSL'] = 35

	return Player{
		x:             100.0
		y:             400.0
		hp:            100.0
		max_hp:        100.0
		energy:        100.0
		shield:        50.0
		active_weapon: .pulse
		ammo:          ammo_map
		bombs:         3
		facing_right:  true
	}
}

struct PowerUp {
pub mut:
	x      f64
	y      f64
	vx     f64
	vy     f64
	ptype  PowerUpType
	wtype  WeaponType
	life   f64 = 10.0
	radius f64 = 14.0
}

struct Enemy {
pub mut:
	id          int
	etype       EnemyType
	x           f64
	y           f64
	vx          f64
	vy          f64
	hp          f64
	max_hp      f64
	radius      f64 = 16.0
	shoot_timer f64
	anim_time   f64
	phase       int
	is_boss     bool
	active      bool = true
	target_y    f64
	score_val   int
}

struct Particle {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	color    Color
	size     f64
	life     f64
	max_life f64
	text     string
	is_text  bool
}

struct GameEngine {
pub mut:
	state              GameState = .title
	stage              int       = 1
	score              int
	high_score         int = 50000
	elapsed_time       f64
	player             Player = new_player()
	enemies            []Enemy
	projectiles        []Projectile
	powerups           []PowerUp
	particles          []Particle
	camera_x           f64
	camera_shake       f64
	boss_active        bool
	boss_warning_timer f64
	spawn_timer        f64
	next_enemy_id      int = 1
	stage_distance     f64
	max_stage_distance f64 = 3000.0
	difficulty         int = 1 // 0: Casual, 1: Veteran, 2: Cyber Nightmare
}

fn new_game_engine() GameEngine {
	return GameEngine{
		state:        .title
		stage:        1
		player:       new_player()
		enemies:      []Enemy{}
		projectiles:  []Projectile{}
		powerups:     []PowerUp{}
		particles:    []Particle{}
		high_score:   50000
		difficulty:   1
	}
}

fn (ge &GameEngine) start_game() {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mutable_ge.state = .playing
	mutable_ge.stage = 1
	mutable_ge.score = 0
	mutable_ge.elapsed_time = 0
	mutable_ge.stage_distance = 0
	mutable_ge.player = new_player()
	mutable_ge.enemies.clear()
	mutable_ge.projectiles.clear()
	mutable_ge.powerups.clear()
	mutable_ge.particles.clear()
	mutable_ge.boss_active = false
	mutable_ge.camera_x = 0
}

fn (ge &GameEngine) switch_weapon(next bool) {
	mut p := unsafe { &Player(&ge.player) }
	weapons := [
		WeaponType.pulse,
		.spread,
		.plasma,
		.missile,
		.flame,
		.grenade,
		.hyper_laser,
		.tesla,
	]
	mut cur_idx := 0
	for i, w in weapons {
		if w == p.active_weapon {
			cur_idx = i
			break
		}
	}
	if next {
		cur_idx = (cur_idx + 1) % weapons.len
	} else {
		cur_idx = (cur_idx - 1 + weapons.len) % weapons.len
	}
	p.active_weapon = weapons[cur_idx]
}

fn (ge &GameEngine) set_weapon_by_idx(idx int) {
	mut p := unsafe { &Player(&ge.player) }
	weapons := [
		WeaponType.pulse,
		.spread,
		.plasma,
		.missile,
		.flame,
		.grenade,
		.hyper_laser,
		.tesla,
	]
	if idx >= 0 && idx < weapons.len {
		p.active_weapon = weapons[idx]
	}
}

fn (ge &GameEngine) trigger_emp_bomb(sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	if mutable_ge.player.bombs <= 0 || mutable_ge.state != .playing {
		return
	}
	mutable_ge.player.bombs--
	sound_mgr.play_emp_bomb()
	mutable_ge.camera_shake = 25.0

	// Clear enemy projectiles
	mut new_projs := []Projectile{}
	for pr in mutable_ge.projectiles {
		if !pr.is_enemy {
			new_projs << pr
		}
	}
	mutable_ge.projectiles = new_projs

	// Damage all enemies
	for mut enemy in mutable_ge.enemies {
		if enemy.active {
			dmg := 150.0
			enemy.hp -= dmg
			mutable_ge.add_text_particle(enemy.x, enemy.y - 15.0, 'EMP 150!', Color{
				r: 250
				g: 204
				b: 21
			})
			if enemy.hp <= 0 {
				enemy.active = false
				mutable_ge.score += enemy.score_val * mutable_ge.player.multiplier
				mutable_ge.spawn_explosion(enemy.x, enemy.y, 25.0)
			}
		}
	}

	// Add screen bomb ring particles
	for a in 0 .. 36 {
		angle := f64(a) * (math.pi / 18.0)
		vx := math.cos(angle) * 600.0
		vy := math.sin(angle) * 600.0
		mutable_ge.particles << Particle{
			x:        mutable_ge.player.x
			y:        mutable_ge.player.y
			vx:       vx
			vy:       vy
			color:    Color{
				r: 6
				g: 182
				b: 212
			}
			size:     6.0
			life:     0.6
			max_life: 0.6
		}
	}
}

fn (ge &GameEngine) update(dt f64, key_left bool, key_right bool, key_up bool, key_down bool, key_jump bool, key_fire bool, key_dash bool, sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	if mutable_ge.state != .playing {
		return
	}

	mutable_ge.elapsed_time += dt

	// Update Timers & Camera shake
	if mutable_ge.camera_shake > 0 {
		mutable_ge.camera_shake -= dt * 40.0
		if mutable_ge.camera_shake < 0 {
			mutable_ge.camera_shake = 0
		}
	}

	// Player Timers
	if mutable_ge.player.fire_cooldown > 0 {
		mutable_ge.player.fire_cooldown -= dt
	}
	if mutable_ge.player.overdrive_timer > 0 {
		mutable_ge.player.overdrive_timer -= dt
	}
	if mutable_ge.player.shield_timer > 0 {
		mutable_ge.player.shield_timer -= dt
	}
	if mutable_ge.player.invincible_timer > 0 {
		mutable_ge.player.invincible_timer -= dt
	}
	if mutable_ge.player.dash_timer > 0 {
		mutable_ge.player.dash_timer -= dt
	}
	if mutable_ge.player.dash_cooldown > 0 {
		mutable_ge.player.dash_cooldown -= dt
	}
	if mutable_ge.player.mult_timer > 0 {
		mutable_ge.player.mult_timer -= dt
		if mutable_ge.player.mult_timer <= 0 {
			mutable_ge.player.multiplier = 1
		}
	}

	// Player Physics & Controls
	move_speed := 280.0
	mut p := unsafe { &Player(&mutable_ge.player) }

	if key_left {
		p.vx = -move_speed
		p.facing_right = false
	} else if key_right {
		p.vx = move_speed
		p.facing_right = true
	} else {
		p.vx *= 0.8
	}

	p.is_crouching = key_down && p.is_grounded

	// Jetpack / Jump
	if key_jump {
		if p.is_grounded {
			p.vy = -450.0
			p.is_grounded = false
			mutable_ge.add_spark_particles(p.x, p.y + 20.0, 5)
		} else if p.energy > 0 {
			p.vy -= 800.0 * dt
			if p.vy < -350.0 {
				p.vy = -350.0
			}
			p.energy -= 25.0 * dt
			mutable_ge.add_jetpack_flame(p.x - 10.0, p.y + 15.0)
		}
	} else {
		if p.energy < p.max_energy {
			p.energy += 30.0 * dt
			if p.energy > p.max_energy {
				p.energy = p.max_energy
			}
		}
	}

	// Dash mechanic
	if key_dash && p.dash_cooldown <= 0 {
		p.dash_timer = 0.25
		p.dash_cooldown = 0.8
		p.invincible_timer = 0.3
		if p.facing_right {
			p.vx = 750.0
		} else {
			p.vx = -750.0
		}
		mutable_ge.add_spark_particles(p.x, p.y, 10)
	}

	// Gravity & Move
	gravity := 950.0
	p.vy += gravity * dt
	p.x += p.vx * dt
	p.y += p.vy * dt

	// World Floor collision
	ground_level := 480.0
	if p.y >= ground_level {
		p.y = ground_level
		p.vy = 0
		p.is_grounded = true
	}

	// Screen Bounds & Camera Scrolling
	if p.x < mutable_ge.camera_x + 30.0 {
		p.x = mutable_ge.camera_x + 30.0
	}
	if p.x > mutable_ge.camera_x + 400.0 {
		mutable_ge.camera_x = p.x - 400.0
	}
	mutable_ge.stage_distance = mutable_ge.camera_x

	// Player Drone Companion
	if p.drone_active {
		p.drone_angle += dt * 3.0
		p.drone_fire_timer += dt
		if p.drone_fire_timer >= 0.3 {
			p.drone_fire_timer = 0
			drone_x := p.x + math.cos(p.drone_angle) * 45.0
			drone_y := p.y - 20.0 + math.sin(p.drone_angle) * 20.0
			mutable_ge.projectiles << Projectile{
				x:           drone_x
				y:           drone_y
				vx:          600.0
				vy:          0
				weapon_type: .pulse
				damage:      12.0
				radius:      4.0
				life:        1.2
				max_life:    1.2
				is_enemy:    false
			}
		}
	}

	// Player Weapon Firing
	if key_fire && p.fire_cooldown <= 0 {
		info := get_weapon_info(p.active_weapon)
		cur_ammo := p.ammo[info.symbol] or { 0 }

		if info.ammo_cost == 0 || cur_ammo >= info.ammo_cost {
			if info.ammo_cost > 0 {
				p.ammo[info.symbol] = cur_ammo - info.ammo_cost
			}

			p.fire_cooldown = info.cooldown
			if p.overdrive_timer > 0 {
				p.fire_cooldown *= 0.5
			}

			mut dir_x := 1.0
			mut dir_y := 0.0
			if !p.facing_right {
				dir_x = -1.0
			}
			if key_up {
				dir_y = -0.7
				dir_x *= 0.7
			}

			new_projs := create_projectiles(p.active_weapon, p.x + (dir_x * 20.0), p.y - 5.0 + (dir_y * 20.0), dir_x, dir_y, p.overdrive_timer > 0, false)
			for proj in new_projs {
				mutable_ge.projectiles << proj
			}

			// Play weapon sound
			match p.active_weapon {
				.pulse { sound_mgr.play_laser() }
				.spread { sound_mgr.play_spread() }
				.plasma { sound_mgr.play_plasma() }
				.missile { sound_mgr.play_missile() }
				.flame { sound_mgr.play_flame() }
				.grenade { sound_mgr.play_grenade() }
				.hyper_laser { sound_mgr.play_hyper_laser() }
				.tesla { sound_mgr.play_tesla() }
			}

			mutable_ge.camera_shake = math.max(mutable_ge.camera_shake, info.damage * 0.1)
		}
	}

	// Spawning Stage Enemies / Bosses
	if !mutable_ge.boss_active {
		if mutable_ge.stage_distance >= mutable_ge.max_stage_distance {
			mutable_ge.boss_active = true
			mutable_ge.boss_warning_timer = 2.5
			sound_mgr.play_boss_siren()
			mutable_ge.spawn_stage_boss()
		} else {
			mutable_ge.spawn_timer += dt
			spawn_interval := 2.2 - (f64(mutable_ge.stage) * 0.3)
			if mutable_ge.spawn_timer >= spawn_interval {
				mutable_ge.spawn_timer = 0
				mutable_ge.spawn_random_enemy()
			}
		}
	} else if mutable_ge.boss_warning_timer > 0 {
		mutable_ge.boss_warning_timer -= dt
	}

	// Update Projectiles
	mut keep_projs := []Projectile{}
	for mut pr in mutable_ge.projectiles {
		pr.life -= dt
		if pr.life <= 0 {
			continue
		}

		// Homing Missile AI
		if pr.weapon_type == .missile && !pr.is_enemy {
			mut nearest_dist := 99999.0
			mut target_x := pr.x + pr.vx
			mut target_y := pr.y + pr.vy

			for enemy in mutable_ge.enemies {
				if enemy.active {
					dist := math.hypot(enemy.x - pr.x, enemy.y - pr.y)
					if dist < nearest_dist {
						nearest_dist = dist
						target_x = enemy.x
						target_y = enemy.y
					}
				}
			}

			if nearest_dist < 600.0 {
				angle := math.atan2(target_y - pr.y, target_x - pr.x)
				pr.vx = math.cos(angle) * 550.0
				pr.vy = math.sin(angle) * 550.0
			}
		}

		pr.x += pr.vx * dt
		pr.y += pr.vy * dt

		// Particle trails for missiles/flame
		if pr.weapon_type == .missile {
			mutable_ge.add_spark_particles(pr.x - pr.vx * 0.02, pr.y - pr.vy * 0.02, 1)
		} else if pr.weapon_type == .flame {
			mutable_ge.add_jetpack_flame(pr.x, pr.y)
		}

		// Check bounds
		if pr.x < mutable_ge.camera_x - 50.0 || pr.x > mutable_ge.camera_x + 900.0 || pr.y < -100.0 || pr.y > 600.0 {
			continue
		}

		keep_projs << pr
	}
	mutable_ge.projectiles = keep_projs

	// Update Enemies
	for mut enemy in mutable_ge.enemies {
		if !enemy.active {
			continue
		}

		enemy.anim_time += dt

		match enemy.etype {
			.scout {
				enemy.x += enemy.vx * dt
				enemy.y = enemy.target_y + math.sin(enemy.anim_time * 4.0) * 40.0
				enemy.shoot_timer += dt
				if enemy.shoot_timer >= 2.0 {
					enemy.shoot_timer = 0
					mutable_ge.projectiles << Projectile{
						x:           enemy.x
						y:           enemy.y
						vx:          -300.0
						vy:          0
						weapon_type: .pulse
						damage:      10.0
						radius:      4.0
						life:        2.0
						max_life:    2.0
						is_enemy:    true
					}
				}
			}
			.mech {
				enemy.x += enemy.vx * dt
				enemy.shoot_timer += dt
				if enemy.shoot_timer >= 2.5 {
					enemy.shoot_timer = 0
					mutable_ge.projectiles << Projectile{
						x:           enemy.x - 15.0
						y:           enemy.y - 10.0
						vx:          -350.0
						vy:          -120.0
						weapon_type: .grenade
						damage:      20.0
						radius:      6.0
						life:        2.2
						max_life:    2.2
						is_enemy:    true
					}
				}
			}
			.turret {
				enemy.shoot_timer += dt
				if enemy.shoot_timer >= 1.8 {
					enemy.shoot_timer = 0
					angle := math.atan2(p.y - enemy.y, p.x - enemy.x)
					mutable_ge.projectiles << Projectile{
						x:           enemy.x
						y:           enemy.y
						vx:          math.cos(angle) * 320.0
						vy:          math.sin(angle) * 320.0
						weapon_type: .pulse
						damage:      12.0
						radius:      4.0
						life:        2.5
						max_life:    2.5
						is_enemy:    true
					}
				}
			}
			.kamikaze {
				dx := p.x - enemy.x
				dy := p.y - enemy.y
				dist := math.hypot(dx, dy)
				if dist > 0 {
					enemy.vx = (dx / dist) * 320.0
					enemy.vy = (dy / dist) * 320.0
				}
				enemy.x += enemy.vx * dt
				enemy.y += enemy.vy * dt
			}
			.sniper {
				enemy.shoot_timer += dt
				if enemy.shoot_timer >= 3.0 {
					enemy.shoot_timer = 0
					mutable_ge.projectiles << Projectile{
						x:           enemy.x
						y:           enemy.y
						vx:          -700.0
						vy:          0
						weapon_type: .hyper_laser
						damage:      28.0
						radius:      5.0
						life:        1.5
						max_life:    1.5
						is_enemy:    true
					}
				}
			}
			.boss_behemoth {
				enemy.shoot_timer += dt
				if enemy.x > mutable_ge.camera_x + 600.0 {
					enemy.x -= 80.0 * dt
				} else {
					enemy.y = 360.0 + math.sin(enemy.anim_time * 1.5) * 60.0
				}
				if enemy.shoot_timer >= 1.2 {
					enemy.shoot_timer = 0
					mutable_ge.projectiles << Projectile{
						x:           enemy.x - 30.0
						y:           enemy.y - 15.0
						vx:          -450.0
						vy:          (rand.f64() * 100.0 - 50.0)
						weapon_type: .spread
						damage:      15.0
						radius:      5.0
						life:        2.0
						max_life:    2.0
						is_enemy:    true
					}
					mutable_ge.projectiles << Projectile{
						x:           enemy.x - 30.0
						y:           enemy.y + 15.0
						vx:          -450.0
						vy:          (rand.f64() * 100.0 - 50.0)
						weapon_type: .spread
						damage:      15.0
						radius:      5.0
						life:        2.0
						max_life:    2.0
						is_enemy:    true
					}
				}
			}
			.boss_dreadnought {
				enemy.shoot_timer += dt
				enemy.x = mutable_ge.camera_x + 580.0 + math.sin(enemy.anim_time * 0.8) * 80.0
				enemy.y = 200.0 + math.cos(enemy.anim_time * 1.2) * 50.0
				if enemy.shoot_timer >= 1.0 {
					enemy.shoot_timer = 0
					for a in 0 .. 4 {
						angle := math.pi + (f64(a) - 1.5) * 0.25
						mutable_ge.projectiles << Projectile{
							x:           enemy.x - 40.0
							y:           enemy.y
							vx:          math.cos(angle) * 380.0
							vy:          math.sin(angle) * 380.0
							weapon_type: .pulse
							damage:      18.0
							radius:      5.0
							life:        2.2
							max_life:    2.2
							is_enemy:    true
						}
					}
				}
			}
			.boss_omega {
				enemy.shoot_timer += dt
				enemy.x = mutable_ge.camera_x + 550.0 + math.sin(enemy.anim_time * 2.0) * 100.0
				enemy.y = 280.0 + math.cos(enemy.anim_time * 2.5) * 80.0
				if enemy.shoot_timer >= 0.8 {
					enemy.shoot_timer = 0
					angle := math.atan2(p.y - enemy.y, p.x - enemy.x)
					mutable_ge.projectiles << Projectile{
						x:           enemy.x - 40.0
						y:           enemy.y
						vx:          math.cos(angle) * 500.0
						vy:          math.sin(angle) * 500.0
						weapon_type: .plasma
						damage:      25.0
						radius:      7.0
						life:        2.5
						max_life:    2.5
						is_enemy:    true
					}
				}
			}
		}
	}

	// Collisions: Player Projectiles vs Enemies
	for mut pr in mutable_ge.projectiles {
		if !pr.is_enemy && pr.life > 0 {
			for mut enemy in mutable_ge.enemies {
				if enemy.active {
					dist := math.hypot(pr.x - enemy.x, pr.y - enemy.y)
					if dist <= (pr.radius + enemy.radius) {
						pr.pierce--
						if pr.pierce <= 0 {
							pr.life = 0
						}

						enemy.hp -= pr.damage
						mutable_ge.add_text_particle(enemy.x + (rand.f64() * 20.0 - 10.0), enemy.y - 10.0, '${int(pr.damage)}', Color{
							r: 248
							g: 113
							b: 113
						})
						mutable_ge.add_spark_particles(pr.x, pr.y, 4)

						if enemy.hp <= 0 {
							enemy.active = false
							mutable_ge.score += enemy.score_val * p.multiplier
							if mutable_ge.score > mutable_ge.high_score {
								mutable_ge.high_score = mutable_ge.score
							}

							sound_mgr.play_explosion()
							mutable_ge.spawn_explosion(enemy.x, enemy.y, enemy.radius * 1.5)

							// Chance to drop power-up
							if rand.f64() < 0.45 || enemy.is_boss {
								mutable_ge.spawn_powerup(enemy.x, enemy.y)
							}

							// Stage Boss Defeated!
							if enemy.is_boss {
								mutable_ge.boss_active = false
								if mutable_ge.stage < 3 {
									mutable_ge.stage++
									mutable_ge.state = .stage_clear
								} else {
									mutable_ge.state = .victory
								}
							}
						}

						break
					}
				}
			}
		}
	}

	// Collisions: Enemy Projectiles & Enemy Bodies vs Player
	if p.invincible_timer <= 0 && p.dash_timer <= 0 {
		for mut pr in mutable_ge.projectiles {
			if pr.is_enemy && pr.life > 0 {
				dist := math.hypot(pr.x - p.x, pr.y - (p.y - 20.0))
				if dist <= (pr.radius + 18.0) {
					pr.life = 0
					mutable_ge.damage_player(pr.damage, sound_mgr)
					break
				}
			}
		}

		for enemy in mutable_ge.enemies {
			if enemy.active {
				dist := math.hypot(enemy.x - p.x, enemy.y - (p.y - 20.0))
				if dist <= (enemy.radius + 18.0) {
					mutable_ge.damage_player(25.0, sound_mgr)
					break
				}
			}
		}
	}

	// Power-up Collection
	mut keep_pu := []PowerUp{}
	for mut pu in mutable_ge.powerups {
		pu.life -= dt
		if pu.life <= 0 {
			continue
		}
		pu.x += pu.vx * dt
		pu.y += pu.vy * dt

		dist := math.hypot(pu.x - p.x, pu.y - (p.y - 20.0))
		if dist <= (pu.radius + 20.0) {
			sound_mgr.play_powerup()
			mutable_ge.apply_powerup(pu)
			mutable_ge.add_text_particle(p.x, p.y - 30.0, 'POWER UP!', Color{
				r: 52
				g: 211
				b: 153
			})
			continue
		}
		keep_pu << pu
	}
	mutable_ge.powerups = keep_pu

	// Update Particles
	mut keep_parts := []Particle{}
	for mut pt in mutable_ge.particles {
		pt.life -= dt
		if pt.life <= 0 {
			continue
		}
		pt.x += pt.vx * dt
		pt.y += pt.vy * dt
		keep_parts << pt
	}
	mutable_ge.particles = keep_parts
}

fn (ge &GameEngine) damage_player(amount f64, sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mut p := unsafe { &Player(&mutable_ge.player) }

	p.invincible_timer = 1.0
	mutable_ge.camera_shake = 15.0

	if p.shield > 0 {
		if p.shield >= amount {
			p.shield -= amount
		} else {
			rem := amount - p.shield
			p.shield = 0
			p.hp -= rem
		}
	} else {
		p.hp -= amount
	}

	mutable_ge.add_text_particle(p.x, p.y - 25.0, '-${int(amount)} HP', Color{
		r: 239
		g: 68
		b: 68
	})

	if p.hp <= 0 {
		p.hp = 0
		mutable_ge.state = .game_over
		sound_mgr.play_explosion()
	}
}

fn (ge &GameEngine) apply_powerup(pu PowerUp) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mut p := unsafe { &Player(&mutable_ge.player) }

	match pu.ptype {
		.weapon_drop {
			p.active_weapon = pu.wtype
			info := get_weapon_info(pu.wtype)
			cur := p.ammo[info.symbol] or { 0 }
			p.ammo[info.symbol] = cur + 50
		}
		.shield_core {
			p.shield = p.max_shield
			p.shield_timer = 8.0
		}
		.overdrive {
			p.overdrive_timer = 6.0
		}
		.combat_drone {
			p.drone_active = true
		}
		.repair_kit {
			p.hp = math.min(p.max_hp, p.hp + 50.0)
		}
		.emp_bomb {
			p.bombs = math.min(5, p.bombs + 1)
		}
		.multiplier_orb {
			p.multiplier = 2
			p.mult_timer = 10.0
		}
	}
}

fn (ge &GameEngine) spawn_random_enemy() {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	etypes := [EnemyType.scout, .mech, .turret, .kamikaze, .sniper]
	etype := etypes[rand.intn(etypes.len) or { 0 }]

	spawn_x := mutable_ge.camera_x + 850.0
	mut spawn_y := 100.0 + (rand.f64() * 300.0)

	mut hp := 30.0
	mut radius := 16.0
	mut score_val := 100

	match etype {
		.scout {
			hp = 25.0
			radius = 14.0
			score_val = 150
		}
		.mech {
			spawn_y = 440.0
			hp = 80.0
			radius = 22.0
			score_val = 300
		}
		.turret {
			spawn_y = 60.0
			hp = 45.0
			radius = 18.0
			score_val = 200
		}
		.kamikaze {
			hp = 15.0
			radius = 12.0
			score_val = 120
		}
		.sniper {
			spawn_y = 120.0 + (rand.f64() * 200.0)
			hp = 40.0
			radius = 16.0
			score_val = 250
		}
		else {}
	}

	id := mutable_ge.next_enemy_id
	mutable_ge.next_enemy_id++

	mutable_ge.enemies << Enemy{
		id:        id
		etype:     etype
		x:         spawn_x
		y:         spawn_y
		vx:        -120.0
		vy:        0
		hp:        hp
		max_hp:    hp
		radius:    radius
		target_y:  spawn_y
		score_val: score_val
		active:    true
	}
}

fn (ge &GameEngine) spawn_stage_boss() {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	btype := match mutable_ge.stage {
		1 { EnemyType.boss_behemoth }
		2 { EnemyType.boss_dreadnought }
		else { EnemyType.boss_omega }
	}

	spawn_x := mutable_ge.camera_x + 750.0
	spawn_y := 300.0

	mut hp := 600.0 * f64(mutable_ge.stage)
	mut radius := 45.0

	id := mutable_ge.next_enemy_id
	mutable_ge.next_enemy_id++

	mutable_ge.enemies << Enemy{
		id:        id
		etype:     btype
		x:         spawn_x
		y:         spawn_y
		hp:        hp
		max_hp:    hp
		radius:    radius
		score_val: 5000 * mutable_ge.stage
		is_boss:   true
		active:    true
	}
}

fn (ge &GameEngine) spawn_powerup(x f64, y f64) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	ptypes := [
		PowerUpType.weapon_drop,
		.shield_core,
		.overdrive,
		.combat_drone,
		.repair_kit,
		.emp_bomb,
		.multiplier_orb,
	]
	ptype := ptypes[rand.intn(ptypes.len) or { 0 }]

	wtypes := [
		WeaponType.spread,
		.plasma,
		.missile,
		.flame,
		.grenade,
		.hyper_laser,
		.tesla,
	]
	wtype := wtypes[rand.intn(wtypes.len) or { 0 }]

	mutable_ge.powerups << PowerUp{
		x:     x
		y:     y
		vx:    -30.0
		vy:    20.0
		ptype: ptype
		wtype: wtype
	}
}

fn (ge &GameEngine) spawn_explosion(x f64, y f64, size f64) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	for _ in 0 .. 20 {
		angle := rand.f64() * math.pi * 2.0
		spd := rand.f64() * size * 8.0
		mutable_ge.particles << Particle{
			x:        x
			y:        y
			vx:       math.cos(angle) * spd
			vy:       math.sin(angle) * spd
			color:    Color{
				r: u8(220 + rand.intn(35) or { 0 })
				g: u8(100 + rand.intn(100) or { 0 })
				b: 20
			}
			size:     4.0 + rand.f64() * 6.0
			life:     0.5 + rand.f64() * 0.4
			max_life: 0.8
		}
	}
}

fn (ge &GameEngine) add_spark_particles(x f64, y f64, count int) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	for _ in 0 .. count {
		mutable_ge.particles << Particle{
			x:        x
			y:        y
			vx:       (rand.f64() * 200.0 - 100.0)
			vy:       (rand.f64() * 200.0 - 100.0)
			color:    Color{
				r: 250
				g: 204
				b: 21
			}
			size:     3.0
			life:     0.3
			max_life: 0.3
		}
	}
}

fn (ge &GameEngine) add_jetpack_flame(x f64, y f64) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mutable_ge.particles << Particle{
		x:        x
		y:        y
		vx:       -150.0 + (rand.f64() * 40.0 - 20.0)
		vy:       100.0 + (rand.f64() * 40.0 - 20.0)
		color:    Color{
			r: 249
			g: 115
			b: 22
		}
		size:     5.0
		life:     0.2
		max_life: 0.2
	}
}

fn (ge &GameEngine) add_text_particle(x f64, y f64, text string, color Color) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mutable_ge.particles << Particle{
		x:        x
		y:        y
		vx:       0
		vy:       -40.0
		color:    color
		size:     1.0
		life:     0.9
		max_life: 0.9
		text:     text
		is_text:  true
	}
}
