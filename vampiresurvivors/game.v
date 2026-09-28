module main

import math
import os
import rand



pub struct Game {
pub mut:
	state             GameState
	difficulty        DifficultyLevel
	is_coop           bool
	hyper_mode        bool
	game_speed        f64
	players           []Player
	enemies           []Enemy
	projectiles       []Projectile
	enemy_projectiles []EnemyProjectile
	gems              []ExpGem
	floor_pickups     []FloorPickup
	breakables        []BreakableProp
	blood_stains      []BloodStain
	mist_particles    []MistParticle
	fireflies         []Firefly
	dmg_nums          []DamageNum
	particles         []Particle
	hazard_zones      []HazardZone
	dash_ghosts       []DashGhost
	stage             StageType = .mad_forest
	save_data         SaveData
	boss_hp_bar_name  string
	boss_hp_bar_pct   f64
	achievement_msg   string
	achievement_timer f64
	upgrade_cards     []UpgradeChoice
	selected_card     int
	chest_items       []string
	chest_timer       f64
	chest_tier        int
	game_time         f64
	spawn_timer       f64
	last_boss_spawn   f64 = -999.0
	hazard_timer      f64
	wave_title        string
	wave_title_t      f64
	stage_event_idx   int
	prop_timer        f64
	wave_idx          int
	total_kills       int
	combo_kills       int
	combo_timer       f64
	combo_title       string
	combo_title_t     f64
	cam_x             f64
	cam_y             f64
	frozen_timer      f64
	shake_timer       f64
	flash_nuke        f64
	show_radar        bool
	sound_mgr         SoundManager
	p1_up             bool
	p1_down           bool
	p1_left           bool
	p1_right          bool
	p2_up             bool
	p2_down           bool
	p2_left           bool
	p2_right          bool
	sprite_texture    &Texture = unsafe { nil }
}

pub fn (mut g Game) init_textures(renderer &Renderer) {
	paths := [
		'assets/sprites/vampiresurvivors.png',
		'./assets/sprites/vampiresurvivors.png',
		'../assets/sprites/vampiresurvivors.png',
		'vampiresurvivors/assets/sprites/vampiresurvivors.png',
	]
	for p in paths {
		if os.exists(p) {
			g.sprite_texture = load_texture(renderer.ctx, p)
			if g.sprite_texture != unsafe { nil } && g.sprite_texture.valid {
				println('vampiresurvivors Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn new_game() Game {
	sd := load_save_data()
	mut g := Game{
		state:       .character_select
		difficulty:  .hard // Default to Hard for thrilling action
		stage:       .mad_forest
		save_data:   sd
		is_coop:     false
		hyper_mode:  false
		game_speed:  1.0
		show_radar:  true
		sound_mgr:   new_sound_manager()
		cam_x:       world_width / 2.0 - win_width / 2.0
		cam_y:       world_height / 2.0 - win_height / 2.0
	}
	return g
}

pub fn (mut g Game) cycle_difficulty() {
	g.difficulty = match g.difficulty {
		.normal { DifficultyLevel.hard }
		.hard { DifficultyLevel.inferno }
		.inferno { DifficultyLevel.normal }
	}
}

pub fn (mut g Game) cycle_stage() {
	g.stage = match g.stage {
		.mad_forest { StageType.inlaid_library }
		.inlaid_library { StageType.castle_grounds }
		.castle_grounds { StageType.mad_forest }
	}
}

pub fn (mut g Game) cycle_speed() {
	g.game_speed = match g.game_speed {
		1.0 { 1.5 }
		1.5 { 2.0 }
		2.0 { 3.0 }
		else { 1.0 }
	}
}

pub fn (mut g Game) start_game(char1 CharacterClass, char2 CharacterClass, coop bool) {
	g.is_coop = coop
	g.players.clear()
	g.enemies.clear()
	g.projectiles.clear()
	g.enemy_projectiles.clear()
	g.gems.clear()
	g.floor_pickups.clear()
	g.breakables.clear()
	g.blood_stains.clear()
	g.mist_particles.clear()
	g.fireflies.clear()
	g.dmg_nums.clear()
	g.particles.clear()
	g.hazard_zones.clear()
	g.dash_ghosts.clear()
	g.game_time = 0.0
	g.spawn_timer = 0.0
	g.last_boss_spawn = 0.0
	g.hazard_timer = 0.0
	g.wave_title = ''
	g.wave_title_t = 0.0
	g.stage_event_idx = 0
	g.prop_timer = 0.0
	g.wave_idx = 0
	g.total_kills = 0
	g.combo_kills = 0
	g.combo_timer = 0.0
	g.combo_title = ''
	g.combo_title_t = 0.0
	g.frozen_timer = 0.0
	g.shake_timer = 0.0
	g.flash_nuke = 0.0

	// Player 1
	p1_x := world_width / 2.0 - if coop { 40.0 } else { 0.0 }
	p1_y := world_height / 2.0
	mut p1 := create_player(0, char1, p1_x, p1_y)
	g.players << p1

	if coop {
		p2_x := world_width / 2.0 + 40.0
		p2_y := world_height / 2.0
		mut p2 := create_player(1, char2, p2_x, p2_y)
		g.players << p2
	}

	// Apply Permanent Power-Up Shop bonuses
	for mut p in g.players {
		p.max_hp += f64(g.save_data.health_lvl) * 10.0
		p.hp = p.max_hp
		p.speed += f64(g.save_data.speed_lvl) * 11.0
		p.rerolls += g.save_data.rerolls_lvl
		p.banishes += g.save_data.banish_lvl
	}

	for _ in 0 .. 50 {
		bx := rand.f64() * (world_width - 200.0) + 100.0
		by := rand.f64() * (world_height - 200.0) + 100.0
		g.breakables << BreakableProp{
			x:      bx
			y:      by
			hp:     1.0
			is_urn: rand.f64() < 0.5
		}
	}

	for _ in 0 .. 30 {
		fx := rand.f64() * world_width
		fy := rand.f64() * world_height
		g.fireflies << Firefly{
			x:      fx
			y:      fy
			base_x: fx
			base_y: fy
			phase:  rand.f64() * math.pi * 2.0
			speed:  rand.f64() * 1.5 + 0.8
		}
	}

	g.state = .playing
}

pub fn (mut g Game) perform_dash(p_idx int) {
	if p_idx >= g.players.len {
		return
	}
	mut p := unsafe { &g.players[p_idx] }
	if p.dash_cooldown > 0 {
		return
	}
	p.dash_cooldown = 3.0
	p.dash_timer = 0.40
	p.is_dashing = true
	p.invuln_time = 0.40
	g.sound_mgr.play_whip_sound()

	dir_x := if p.vx != 0.0 { p.vx } else { (if p.facing_right { 1.0 } else { -1.0 }) }
	dir_y := p.vy
	ndx, ndy := normalize(dir_x, dir_y)

	p.x = math.clamp(p.x + ndx * 220.0, 30.0, world_width - 30.0)
	p.y = math.clamp(p.y + ndy * 220.0, 30.0, world_height - 30.0)

	g.dash_ghosts << DashGhost{x: p.x, y: p.y, life: 0.35}
}

pub fn (mut g Game) buy_powerup(kind string) {
	mut current_lvl := 0
	match kind {
		'might' { current_lvl = g.save_data.might_lvl }
		'health' { current_lvl = g.save_data.health_lvl }
		'speed' { current_lvl = g.save_data.speed_lvl }
		'greed' { current_lvl = g.save_data.greed_lvl }
		'growth' { current_lvl = g.save_data.growth_lvl }
		'rerolls' { current_lvl = g.save_data.rerolls_lvl }
		'banish' { current_lvl = g.save_data.banish_lvl }
		else { return }
	}
	if current_lvl >= 5 {
		return
	}
	cost := (current_lvl + 1) * 250
	if g.save_data.total_gold >= cost {
		g.save_data.total_gold -= cost
		match kind {
			'might' { g.save_data.might_lvl++ }
			'health' { g.save_data.health_lvl++ }
			'speed' { g.save_data.speed_lvl++ }
			'greed' { g.save_data.greed_lvl++ }
			'growth' { g.save_data.growth_lvl++ }
			'rerolls' { g.save_data.rerolls_lvl++ }
			'banish' { g.save_data.banish_lvl++ }
			else {}
		}
		save_data_to_file(&g.save_data)
		g.sound_mgr.play_gem_pickup_sound(100)
	}
}

pub fn create_player(id int, char_class CharacterClass, x f64, y f64) Player {
	name := match char_class {
		.antonio { 'Antonio' }
		.imelda { 'Imelda' }
		.pasqualina { 'Pasqualina' }
		.gennaro { 'Gennaro' }
		.mortaccio { 'Mortaccio' }
		.eleanor { 'Eleanor' }
	}

	mut p := Player{
		id:           id
		char_class:   char_class
		name:         name
		x:            x
		y:            y
		hp:           120.0
		max_hp:       120.0
		speed:        235.0
		magnet_rad:   130.0
		level:        1
		exp:          0
		exp_next:     3
		facing_right: true
	}

	start_weapon := match char_class {
		.antonio { WeaponType.whip }
		.imelda { WeaponType.magic_wand }
		.pasqualina { WeaponType.holy_bible }
		.gennaro { WeaponType.knife }
		.mortaccio { WeaponType.axe }
		.eleanor { WeaponType.prismatic_laser }
	}
	p.weapons << create_weapon(start_weapon)

	return p
}

pub fn create_weapon(kind WeaponType) Weapon {
	return match kind {
		.whip {
			Weapon{
				kind:     .whip
				level:    1
				cooldown: 0.85
				damage:   32.0
				count:    1
				area:     1.45
			}
		}
		.bloody_tear {
			Weapon{
				kind:       .bloody_tear
				level:      8
				cooldown:   0.75
				damage:     55.0
				count:      2
				area:       1.8
				is_evolved: true
			}
		}
		.magic_wand {
			Weapon{
				kind:     .magic_wand
				level:    1
				cooldown: 0.55
				damage:   22.0
				speed:    480.0
				count:    1
			}
		}
		.holy_wand {
			Weapon{
				kind:       .holy_wand
				level:      8
				cooldown:   0.10
				damage:     32.0
				speed:      550.0
				count:      1
				is_evolved: true
			}
		}
		.knife {
			Weapon{
				kind:     .knife
				level:    1
				cooldown: 0.45
				damage:   18.0
				speed:    520.0
				count:    2
			}
		}
		.thousand_edge {
			Weapon{
				kind:       .thousand_edge
				level:      8
				cooldown:   0.07
				damage:     26.0
				speed:      600.0
				count:      1
				is_evolved: true
			}
		}
		.axe {
			Weapon{
				kind:     .axe
				level:    1
				cooldown: 0.90
				damage:   42.0
				speed:    340.0
				count:    1
			}
		}
		.death_spiral {
			Weapon{
				kind:       .death_spiral
				level:      8
				cooldown:   1.20
				damage:     75.0
				speed:      380.0
				count:      16
				area:       1.8
				is_evolved: true
			}
		}
		.holy_bible {
			Weapon{
				kind:     .holy_bible
				level:    1
				cooldown: 1.80
				damage:   20.0
				speed:    4.2
				duration: 4.5
				count:    2
				area:     1.2
			}
		}
		.unholy_vespers {
			Weapon{
				kind:       .unholy_vespers
				level:      8
				cooldown:   0.30
				damage:     38.0
				speed:      4.5
				duration:   999.0
				count:      8
				area:       1.5
				is_evolved: true
			}
		}
		.garlic {
			Weapon{
				kind:     .garlic
				level:    1
				cooldown: 0.30
				damage:   16.0
				area:     95.0
			}
		}
		.soul_eater {
			Weapon{
				kind:       .soul_eater
				level:      8
				cooldown:   0.25
				damage:     35.0
				area:       160.0
				is_evolved: true
			}
		}
		.lightning_ring {
			Weapon{
				kind:     .lightning_ring
				level:    1
				cooldown: 1.80
				damage:   50.0
				count:    2
			}
		}
		.fire_wand {
			Weapon{
				kind:     .fire_wand
				level:    1
				cooldown: 1.40
				damage:   42.0
				speed:    360.0
				count:    2
			}
		}
		.cataclysm_nuke {
			Weapon{
				kind:     .cataclysm_nuke
				level:    1
				cooldown: 2.20
				damage:   120.0
				speed:    280.0
				count:    1
				area:     1.6
			}
		}
		.prismatic_laser {
			Weapon{
				kind:     .prismatic_laser
				level:    1
				cooldown: 1.50
				damage:   80.0
				speed:    650.0
				count:    1
				area:     1.5
			}
		}
		.thunder_loop {
			Weapon{
				kind:       .thunder_loop
				level:      8
				cooldown:   0.80
				damage:     95.0
				count:      6
				area:       1.5
				is_evolved: true
			}
		}
		.hellfire {
			Weapon{
				kind:       .hellfire
				level:      8
				cooldown:   0.85
				damage:     110.0
				speed:      480.0
				count:      5
				area:       1.8
				is_evolved: true
			}
		}
		.supernova {
			Weapon{
				kind:       .supernova
				level:      8
				cooldown:   1.30
				damage:     240.0
				speed:      320.0
				count:      3
				area:       2.2
				is_evolved: true
			}
		}
		.gamma_ray {
			Weapon{
				kind:       .gamma_ray
				level:      8
				cooldown:   0.90
				damage:     160.0
				speed:      750.0
				count:      3
				area:       2.0
				is_evolved: true
			}
		}
	}
}

pub fn (mut g Game) activate_ultimate(p_idx int) {
	if p_idx >= g.players.len {
		return
	}
	mut p := unsafe { &g.players[p_idx] }
	if p.ultimate_meter < p.ultimate_max {
		return
	}
	p.ultimate_meter = 0.0
	g.sound_mgr.play_ultimate_sound()
	g.shake_timer = 0.70
	g.flash_nuke = 0.40

	match p.char_class {
		.antonio {
			p.hp = math.min(p.max_hp, p.hp + 35.0)
			for i in 0 .. 20 {
				ang := f64(i) * (math.pi / 10.0)
				g.projectiles << Projectile{
					kind:        .bloody_tear
					x:           p.x + math.cos(ang) * 50.0
					y:           p.y + math.sin(ang) * 50.0
					vx:          math.cos(ang) * 500.0
					vy:          math.sin(ang) * 500.0
					damage:      120.0
					life:        0.80
					max_life:    0.80
					radius:      75.0
					pierce:      999
					owner_id:    p.id
					is_ultimate: true
				}
			}
		}
		.imelda {
			for i in 0 .. 20 {
				ang := f64(i) * (math.pi / 10.0)
				g.projectiles << Projectile{
					kind:        .cataclysm_nuke
					x:           p.x
					y:           p.y
					vx:          math.cos(ang) * 550.0
					vy:          math.sin(ang) * 550.0
					damage:      150.0
					life:        1.6
					max_life:    1.6
					radius:      50.0
					pierce:      999
					owner_id:    p.id
					is_ultimate: true
				}
			}
		}
		.pasqualina {
			for i in 0 .. 16 {
				ang := f64(i) * (math.pi / 8.0)
				g.projectiles << Projectile{
					kind:        .unholy_vespers
					x:           p.x
					y:           p.y
					damage:      80.0
					life:        7.0
					max_life:    7.0
					radius:      28.0
					pierce:      999
					angle:       ang
					orbit_dist:  200.0
					owner_id:    p.id
					is_ultimate: true
				}
			}
		}
		.gennaro {
			for i in 0 .. 40 {
				ang := f64(i) * (math.pi / 20.0)
				g.projectiles << Projectile{
					kind:        .thousand_edge
					x:           p.x
					y:           p.y
					vx:          math.cos(ang) * 750.0
					vy:          math.sin(ang) * 750.0
					damage:      65.0
					life:        2.2
					max_life:    2.2
					radius:      14.0
					pierce:      999
					angle:       ang
					owner_id:    p.id
					is_ultimate: true
				}
			}
		}
		.mortaccio {
			for i in 0 .. 30 {
				ang := f64(i) * (math.pi / 15.0)
				g.projectiles << Projectile{
					kind:        .death_spiral
					x:           p.x
					y:           p.y
					vx:          math.cos(ang) * 600.0
					vy:          math.sin(ang) * 600.0
					damage:      70.0
					life:        2.5
					max_life:    2.5
					radius:      16.0
					pierce:      999
					angle:       ang
					owner_id:    p.id
					is_ultimate: true
				}
			}
		}
		.eleanor {
			for i in 0 .. 16 {
				ang := f64(i) * (math.pi / 8.0)
				g.projectiles << Projectile{
					kind:        .gamma_ray
					x:           p.x
					y:           p.y
					vx:          math.cos(ang) * 900.0
					vy:          math.sin(ang) * 900.0
					damage:      90.0
					life:        3.0
					max_life:    3.0
					radius:      24.0
					pierce:      999
					angle:       ang
					owner_id:    p.id
					is_ultimate: true
				}
			}
		}
	}
}

pub fn (mut g Game) trigger_wave_event(title string) {
	g.wave_title = title
	g.wave_title_t = 4.2
	g.shake_timer = 0.50
	g.sound_mgr.play_nuke_sound()
}

pub fn (mut g Game) update(raw_dt f64) {
	if g.state != .playing {
		return
	}

	dt := raw_dt * g.game_speed
	g.game_time += dt

	if g.combo_timer > 0 {
		g.combo_timer -= dt
		if g.combo_timer <= 0 {
			g.combo_kills = 0
		}
	}

	if g.combo_title_t > 0 {
		g.combo_title_t -= dt
	}

	if g.wave_title_t > 0 {
		g.wave_title_t -= dt
		if g.wave_title_t < 0 {
			g.wave_title_t = 0
		}
	}

	if g.frozen_timer > 0 {
		g.frozen_timer -= dt
		if g.frozen_timer < 0 {
			g.frozen_timer = 0
		}
	}

	if g.shake_timer > 0 {
		g.shake_timer -= dt
		if g.shake_timer < 0 {
			g.shake_timer = 0
		}
	}

	if g.flash_nuke > 0 {
		g.flash_nuke -= dt
		if g.flash_nuke < 0 {
			g.flash_nuke = 0
		}
	}

	// Update Players
	mut all_dead := true
	for i in 0 .. g.players.len {
		mut p := unsafe { &g.players[i] }
		if p.hp > 0 {
			all_dead = false
		} else {
			continue
		}

		if p.invuln_time > 0 {
			p.invuln_time -= dt
		}

		if p.dash_cooldown > 0 {
			p.dash_cooldown -= dt
		}
		if p.dash_timer > 0 {
			p.dash_timer -= dt
			if p.dash_timer <= 0 {
				p.is_dashing = false
			}
		}

		if p.ultimate_meter < p.ultimate_max {
			p.ultimate_meter = math.min(p.ultimate_max, p.ultimate_meter + dt * 3.5)
		}

		p.x += p.vx * p.speed * dt
		p.y += p.vy * p.speed * dt

		p.x = math.clamp(p.x, 30.0, world_width - 30.0)
		p.y = math.clamp(p.y, 30.0, world_height - 30.0)

		if p.vx > 0.05 {
			p.facing_right = true
			p.moving = true
		} else if p.vx < -0.05 {
			p.facing_right = false
			p.moving = true
		} else if math.abs(p.vy) > 0.05 {
			p.moving = true
		} else {
			p.moving = false
		}

		if p.moving {
			p.walk_frame += dt * 8.0
		}

		g.update_player_weapons(i, dt)

		mag_rad := p.magnet_rad * (1.0 + f64(p.get_passive_level(.wings)) * 0.15)
		for mut gem in g.gems {
			d := dist(p.x, p.y, gem.x, gem.y)
			if d <= mag_rad {
				gem.magnetized = true
			}
		}

		for f_idx := g.floor_pickups.len - 1; f_idx >= 0; f_idx-- {
			f_item := g.floor_pickups[f_idx]
			if dist(p.x, p.y, f_item.x, f_item.y) < 36.0 {
				g.collect_floor_pickup(f_item.kind, p.id)
				g.floor_pickups.delete(f_idx)
			}
		}
	}

	for dg_i := g.dash_ghosts.len - 1; dg_i >= 0; dg_i-- {
		mut dg := unsafe { &g.dash_ghosts[dg_i] }
		dg.life -= dt
		if dg.life <= 0 {
			g.dash_ghosts.delete(dg_i)
		}
	}

	// Active Boss Health Bar Tracking
	g.boss_hp_bar_name = ''
	g.boss_hp_bar_pct = 0.0
	for e in g.enemies {
		if e.is_boss && e.hp > 0 {
			g.boss_hp_bar_name = if e.kind == .reaper_boss { 'LORD MORGOTH - REAPER KING' } else { 'ELITE HORDE BOSS' }
			g.boss_hp_bar_pct = math.clamp(e.hp / e.max_hp, 0.0, 1.0)
			break
		}
	}

	if g.achievement_timer > 0 {
		g.achievement_timer -= dt
	}

	if all_dead && g.players.len > 0 {
		g.save_data.total_gold += g.players[0].gold
		save_data_to_file(&g.save_data)
		g.state = .game_over
		return
	}

	// Update Camera Viewport
	mut avg_x := 0.0
	mut avg_y := 0.0
	mut alive_count := 0
	for p in g.players {
		if p.hp > 0 {
			avg_x += p.x
			avg_y += p.y
			alive_count++
		}
	}
	if alive_count > 0 {
		avg_x /= f64(alive_count)
		avg_y /= f64(alive_count)
		target_cam_x := avg_x - win_width / 2.0
		target_cam_y := avg_y - win_height / 2.0
		g.cam_x += (target_cam_x - g.cam_x) * dt * 6.0
		g.cam_y += (target_cam_y - g.cam_y) * dt * 6.0
		g.cam_x = math.clamp(g.cam_x, 0.0, world_width - win_width)
		g.cam_y = math.clamp(g.cam_y, 0.0, world_height - win_height)
	}

	for mut ff in g.fireflies {
		ff.phase += dt * ff.speed
		ff.x = ff.base_x + math.cos(ff.phase) * 35.0
		ff.y = ff.base_y + math.sin(ff.phase * 0.7) * 25.0
	}

	for i := g.blood_stains.len - 1; i >= 0; i-- {
		mut bs := unsafe { &g.blood_stains[i] }
		bs.life -= dt
		if bs.life <= 0 {
			g.blood_stains.delete(i)
		}
	}

	if g.game_time >= 1800.0 {
		g.state = .victory
		return
	}

	// Castle Grounds Volcanic Hazards
	if g.stage == .castle_grounds && g.game_time > 30.0 {
		g.hazard_timer += dt
		if g.hazard_timer >= 12.0 {
			g.hazard_timer = 0.0
			target_p := g.players[0]
			for _ in 0 .. 3 {
				hx := math.clamp(target_p.x + (rand.f64() * 260.0 - 130.0), 30.0, world_width - 30.0)
				hy := math.clamp(target_p.y + (rand.f64() * 260.0 - 130.0), 30.0, world_height - 30.0)
				g.hazard_zones << HazardZone{
					x:        hx
					y:        hy
					radius:   75.0
					timer:    1.0
					max_t:    1.0
					damage:   28.0
					target_x: hx
					target_y: hy
				}
			}
		}
	}

	g.update_spawner(dt)

	if g.frozen_timer <= 0 {
		g.update_enemies(dt)
	}

	g.update_hazard_zones(dt)
	g.update_projectiles(dt)
	g.update_enemy_projectiles(dt)
	g.update_gems(dt)

	g.prop_timer += dt
	if g.prop_timer >= 8.0 && g.breakables.len < 70 {
		g.prop_timer = 0.0
		target_p := g.players[0]
		ang := rand.f64() * math.pi * 2.0
		g.breakables << BreakableProp{
			x:      math.clamp(target_p.x + math.cos(ang) * 450.0, 50.0, world_width - 50.0)
			y:      math.clamp(target_p.y + math.sin(ang) * 450.0, 50.0, world_height - 50.0)
			hp:     1.0
			is_urn: rand.f64() < 0.5
		}
	}

	for i := g.dmg_nums.len - 1; i >= 0; i-- {
		mut dn := unsafe { &g.dmg_nums[i] }
		dn.y -= dt * 25.0
		dn.life -= dt * 1.5
		if dn.life <= 0 {
			g.dmg_nums.delete(i)
		}
	}

	for i := g.particles.len - 1; i >= 0; i-- {
		mut pt := unsafe { &g.particles[i] }
		pt.x += pt.vx * dt
		pt.y += pt.vy * dt
		pt.life -= dt * 2.0
		if pt.life <= 0 {
			g.particles.delete(i)
		}
	}
}

pub fn (mut g Game) update_enemy_projectiles(dt f64) {
	for i := g.enemy_projectiles.len - 1; i >= 0; i-- {
		mut ep := unsafe { &g.enemy_projectiles[i] }
		ep.life -= dt
		ep.x += ep.vx * dt
		ep.y += ep.vy * dt

		if ep.life <= 0 {
			g.enemy_projectiles.delete(i)
			continue
		}

		// Collide with player
		for p_idx in 0 .. g.players.len {
			mut p := unsafe { &g.players[p_idx] }
			if p.hp <= 0 || p.invuln_time > 0 {
				continue
			}
			if dist(p.x, p.y, ep.x, ep.y) < ep.radius + 14.0 {
				armor := f64(p.get_passive_level(.armor))
				dmg := math.max(2.0, ep.damage - armor)
				p.hp -= dmg
				p.invuln_time = 0.45
				g.sound_mgr.play_hit_sound()
				g.dmg_nums << DamageNum{
					x:       p.x
					y:       p.y - 15.0
					val:     int(dmg)
					life:    0.8
					is_crit: true
				}
				g.enemy_projectiles.delete(i)
				break
			}
		}
	}
}

pub fn (p &Player) get_passive_level(kind PassiveType) int {
	for pass in p.passives {
		if pass.kind == kind {
			return pass.level
		}
	}
	return 0
}

pub fn (mut g Game) collect_floor_pickup(kind FloorPickupType, p_idx int) {
	mut p := unsafe { &g.players[p_idx] }
	match kind {
		.vacuum_orb {
			g.sound_mgr.play_vacuum_sound()
			for mut gem in g.gems {
				gem.magnetized = true
			}
			g.dmg_nums << DamageNum{
				x:       p.x
				y:       p.y - 30.0
				val:     g.gems.len
				life:    1.2
				is_heal: true
			}
		}
		.rosary_bomb {
			g.sound_mgr.play_rosary_sound()
			g.flash_nuke = 0.45
			g.shake_timer = 0.50
			for mut e in g.enemies {
				if !e.is_boss {
					e.hp = 0.0
				}
			}
		}
		.freeze_watch {
			g.sound_mgr.play_freeze_sound()
			g.frozen_timer = 6.0
		}
		.floor_chicken {
			g.sound_mgr.play_heal_sound()
			p.hp = math.min(p.max_hp, p.hp + 45.0)
			g.dmg_nums << DamageNum{
				x:       p.x
				y:       p.y - 25.0
				val:     45
				life:    1.0
				is_heal: true
			}
		}
		.coin_bag {
			g.sound_mgr.play_gem_pickup_sound(25)
			p.gold += 100
		}
	}
}

pub fn (mut g Game) update_player_weapons(p_idx int, dt f64) {
	mut p := unsafe { &g.players[p_idx] }

	// Passive Stat Adjustments
	hollow_lvl := p.get_passive_level(.hollow_heart)
	target_max_hp := 120.0 + f64(hollow_lvl) * 20.0
	if p.max_hp != target_max_hp {
		diff := target_max_hp - p.max_hp
		p.max_hp = target_max_hp
		if diff > 0 {
			p.hp = math.min(p.max_hp, p.hp + diff)
		}
	}
	pum_lvl := p.get_passive_level(.pumarola)
	if pum_lvl > 0 && p.hp < p.max_hp {
		p.hp = math.min(p.max_hp, p.hp + dt * f64(pum_lvl) * 1.0)
	}

	cooldown_mult := math.max(0.25, 1.0 - f64(p.get_passive_level(.empty_tome)) * 0.10)
	extra_proj := p.get_passive_level(.duplicator) * 2 + if p.char_class == .gennaro { 2 } else { 0 }
	dmg_mult := 1.0 + f64(p.get_passive_level(.spinach)) * 0.15 + if p.char_class == .antonio { 0.15 } else { 0.0 }

	for w_i in 0 .. p.weapons.len {
		mut w := unsafe { &p.weapons[w_i] }
		w.timer += dt
		actual_cd := w.cooldown * cooldown_mult

		if w.timer >= actual_cd {
			w.timer = 0.0
			proj_count := w.count + extra_proj
			base_dmg := w.damage * dmg_mult

			match w.kind {
				.whip, .bloody_tear {
					g.sound_mgr.play_whip_sound()
					dir := if p.facing_right { 1.0 } else { -1.0 }
					g.projectiles << Projectile{
						kind:     w.kind
						x:        p.x + dir * 75.0
						y:        p.y
						damage:   base_dmg
						life:     0.25
						max_life: 0.25
						radius:   75.0 * w.area
						pierce:   999
						owner_id: p.id
					}
					if w.level >= 2 || proj_count > 1 || w.is_evolved {
						g.projectiles << Projectile{
							kind:     w.kind
							x:        p.x - dir * 75.0
							y:        p.y
							damage:   base_dmg
							life:     0.25
							max_life: 0.25
							radius:   75.0 * w.area
							pierce:   999
							owner_id: p.id
						}
					}
				}
				.magic_wand, .holy_wand {
					g.sound_mgr.play_magic_wand_sound()
					for c_i in 0 .. proj_count {
						closest_e := g.find_closest_enemy(p.x, p.y, c_i)
						mut vx, mut vy := if p.facing_right { 1.0 } else { -1.0 }, 0.0
						if closest_e.hp > 0 {
							dx, dy := normalize(closest_e.x - p.x, closest_e.y - p.y)
							vx = dx
							vy = dy
						}
						g.projectiles << Projectile{
							kind:     w.kind
							x:        p.x
							y:        p.y
							vx:       vx * w.speed
							vy:       vy * w.speed
							damage:   base_dmg
							life:     2.5
							max_life: 2.5
							radius:   12.0
							pierce:   if w.is_evolved { 6 } else { 2 + w.level / 2 }
							owner_id: p.id
						}
					}
				}
				.knife, .thousand_edge {
					g.sound_mgr.play_knife_sound()
					dir_x := if p.vx != 0.0 { (if p.vx > 0 { 1.0 } else { -1.0 }) } else { (if p.facing_right { 1.0 } else { -1.0 }) }
					dir_y := if p.vy != 0.0 { (if p.vy > 0 { 1.0 } else { -1.0 }) } else { 0.0 }
					ndx, ndy := normalize(dir_x, dir_y)

					for c_i in 0 .. proj_count {
						spread := f64(c_i - proj_count / 2) * 0.12
						ang := math.atan2(ndy, ndx) + spread
						g.projectiles << Projectile{
							kind:     w.kind
							x:        p.x
							y:        p.y
							vx:       math.cos(ang) * w.speed
							vy:       math.sin(ang) * w.speed
							damage:   base_dmg
							life:     1.8
							max_life: 1.8
							radius:   10.0
							pierce:   if w.is_evolved { 8 } else { 2 + w.level / 2 }
							angle:    ang
							owner_id: p.id
						}
					}
				}
				.axe {
					g.sound_mgr.play_axe_sound()
					for c_i in 0 .. proj_count {
						spread := (f64(c_i) - f64(proj_count - 1) / 2.0) * 85.0
						g.projectiles << Projectile{
							kind:     .axe
							x:        p.x
							y:        p.y
							vx:       spread
							vy:       -420.0
							damage:   base_dmg
							life:     2.2
							max_life: 2.2
							radius:   18.0
							pierce:   999
							owner_id: p.id
						}
					}
				}
				.death_spiral {
					g.sound_mgr.play_axe_sound()
					for c_i in 0 .. w.count {
						ang := f64(c_i) * (2.0 * math.pi / f64(w.count))
						g.projectiles << Projectile{
							kind:     .death_spiral
							x:        p.x
							y:        p.y
							vx:       math.cos(ang) * w.speed
							vy:       math.sin(ang) * w.speed
							damage:   base_dmg
							life:     2.8
							max_life: 2.8
							radius:   25.0
							pierce:   999
							owner_id: p.id
						}
					}
				}
				.holy_bible, .unholy_vespers {
					g.sound_mgr.play_bible_sound()
					for c_i in 0 .. proj_count {
						base_ang := f64(c_i) * (2.0 * math.pi / f64(proj_count))
						g.projectiles << Projectile{
							kind:       w.kind
							x:          p.x
							y:          p.y
							damage:     base_dmg
							life:       w.duration
							max_life:   w.duration
							radius:     18.0
							pierce:     999
							angle:      base_ang
							orbit_dist: 110.0 * w.area
							owner_id:   p.id
						}
					}
				}
				.garlic, .soul_eater {
					g.projectiles << Projectile{
						kind:     w.kind
						x:        p.x
						y:        p.y
						damage:   base_dmg
						life:     0.30
						max_life: 0.30
						radius:   w.area * (1.0 + f64(w.level) * 0.20)
						pierce:   999
						owner_id: p.id
					}
					if w.is_evolved {
						p.hp = math.min(p.max_hp, p.hp + 0.8)
					}
				}
				.lightning_ring {
					g.sound_mgr.play_lightning_sound()
					for _ in 0 .. proj_count {
						if g.enemies.len > 0 {
							target_idx := rand.int_in_range(0, g.enemies.len) or { 0 }
							mut te := unsafe { &g.enemies[target_idx] }
							g.projectiles << Projectile{
								kind:     .lightning_ring
								x:        te.x
								y:        te.y
								damage:   base_dmg
								life:     0.35
								max_life: 0.35
								radius:   45.0
								pierce:   999
								owner_id: p.id
							}
						}
					}
				}
				.thunder_loop {
					g.sound_mgr.play_lightning_sound()
					for _ in 0 .. proj_count {
						if g.enemies.len > 0 {
							target_idx := rand.int_in_range(0, g.enemies.len) or { 0 }
							mut te := unsafe { &g.enemies[target_idx] }
							g.projectiles << Projectile{
								kind:       .thunder_loop
								x:          te.x
								y:          te.y
								damage:     base_dmg
								life:       0.45
								max_life:   0.45
								radius:     65.0 * w.area
								pierce:     999
								owner_id:   p.id
								is_ultimate: true
							}
						}
					}
				}
				.fire_wand {
					g.sound_mgr.play_fire_sound()
					for _ in 0 .. proj_count {
						ang := rand.f64() * math.pi * 2.0
						g.projectiles << Projectile{
							kind:     .fire_wand
							x:        p.x
							y:        p.y
							vx:       math.cos(ang) * w.speed
							vy:       math.sin(ang) * w.speed
							damage:   base_dmg
							life:     2.2
							max_life: 2.2
							radius:   18.0
							pierce:   6
							owner_id: p.id
						}
					}
				}
				.hellfire {
					g.sound_mgr.play_fire_sound()
					for _ in 0 .. proj_count {
						ang := rand.f64() * math.pi * 2.0
						g.projectiles << Projectile{
							kind:     .hellfire
							x:        p.x
							y:        p.y
							vx:       math.cos(ang) * w.speed
							vy:       math.sin(ang) * w.speed
							damage:   base_dmg
							life:     3.0
							max_life: 3.0
							radius:   28.0 * w.area
							pierce:   999
							owner_id: p.id
						}
					}
				}
				.cataclysm_nuke {
					g.sound_mgr.play_nuke_sound()
					for _ in 0 .. proj_count {
						ang := rand.f64() * math.pi * 2.0
						g.projectiles << Projectile{
							kind:     .cataclysm_nuke
							x:        p.x
							y:        p.y
							vx:       math.cos(ang) * w.speed
							vy:       math.sin(ang) * w.speed
							damage:   base_dmg
							life:     1.8
							max_life: 1.8
							radius:   60.0 * w.area
							pierce:   999
							owner_id: p.id
						}
					}
				}
				.supernova {
					g.sound_mgr.play_nuke_sound()
					g.shake_timer = 0.40
					g.flash_nuke = 0.20
					for _ in 0 .. proj_count {
						ang := rand.f64() * math.pi * 2.0
						g.projectiles << Projectile{
							kind:       .supernova
							x:          p.x
							y:          p.y
							vx:         math.cos(ang) * w.speed
							vy:         math.sin(ang) * w.speed
							damage:     base_dmg
							life:       2.5
							max_life:   2.5
							radius:     95.0 * w.area
							pierce:     999
							owner_id:   p.id
							is_ultimate: true
						}
					}
				}
				.prismatic_laser {
					g.sound_mgr.play_laser_sound()
					for c_i in 0 .. proj_count {
						dir_x := if p.facing_right { 1.0 } else { -1.0 }
						ang := (if dir_x > 0 { 0.0 } else { math.pi }) + f64(c_i - proj_count / 2) * 0.15
						g.projectiles << Projectile{
							kind:     .prismatic_laser
							x:        p.x
							y:        p.y
							vx:       math.cos(ang) * w.speed
							vy:       math.sin(ang) * w.speed
							damage:   base_dmg
							life:     1.2
							max_life: 1.2
							radius:   25.0 * w.area
							pierce:   999
							angle:    ang
							owner_id: p.id
						}
					}
				}
				.gamma_ray {
					g.sound_mgr.play_laser_sound()
					for c_i in 0 .. proj_count {
						ang := f64(c_i) * (2.0 * math.pi / f64(proj_count)) + g.game_time * 2.0
						g.projectiles << Projectile{
							kind:       .gamma_ray
							x:          p.x
							y:          p.y
							vx:         math.cos(ang) * w.speed
							vy:         math.sin(ang) * w.speed
							damage:     base_dmg
							life:       1.5
							max_life:   1.5
							radius:     35.0 * w.area
							pierce:     999
							angle:      ang
							owner_id:   p.id
							is_ultimate: true
						}
					}
				}
			}
		}
	}
}

pub fn (g &Game) find_closest_enemy(x f64, y f64, nth int) Enemy {
	if g.enemies.len == 0 {
		return Enemy{hp: 0.0}
	}
	mut best_d := 999999.0
	mut best_idx := 0
	for i, e in g.enemies {
		if e.hp <= 0 {
			continue
		}
		d := dist(x, y, e.x, e.y)
		if d < best_d {
			best_d = d
			best_idx = i
		}
	}
	return g.enemies[best_idx]
}

pub fn (mut g Game) update_spawner(dt f64) {
	g.spawn_timer += dt

	stage_cap_mult := match g.stage {
		.mad_forest { 1.0 }
		.inlaid_library { 1.25 }
		.castle_grounds { 1.50 }
	}
	diff_cap_mult := match g.difficulty {
		.normal { 1.0 }
		.hard { 1.30 }
		.inferno { 1.70 }
	}

	base_cap := if g.game_time < 35.0 {
		18
	} else if g.game_time < 75.0 {
		40
	} else if g.game_time < 150.0 {
		90
	} else if g.game_time < 270.0 {
		190
	} else if g.game_time < 450.0 {
		300
	} else if g.game_time < 600.0 {
		420
	} else {
		560
	}
	max_enemies := int(f64(base_cap) * stage_cap_mult * diff_cap_mult)

	// Base spawn interval curve: gentle at start, hyper-fast later
	base_rate := if g.game_time < 45.0 {
		1.35 - g.game_time * 0.012
	} else if g.game_time < 120.0 {
		0.80 - (g.game_time - 45.0) * 0.005
	} else if g.game_time < 300.0 {
		0.42 - (g.game_time - 120.0) * 0.0013
	} else {
		math.max(0.06, 0.18 - (g.game_time - 300.0) * 0.00035)
	}

	diff_spd_rate := match g.difficulty {
		.normal { 1.0 }
		.hard { 1.25 }
		.inferno { 1.60 }
	}
	rate := (base_rate / (stage_cap_mult * diff_spd_rate)) * if g.hyper_mode { 0.65 } else { 1.0 }

	// Determine wave index for HUD
	g.wave_idx = if g.game_time < 75.0 {
		0
	} else if g.game_time < 150.0 {
		1
	} else if g.game_time < 240.0 {
		2
	} else if g.game_time < 360.0 {
		3
	} else if g.game_time < 480.0 {
		4
	} else if g.game_time < 600.0 {
		5
	} else {
		6
	}

	mut target_p := g.players[0]
	for p in g.players {
		if p.hp > 0 {
			target_p = p
			break
		}
	}

	// SCRIPTED PROGRESSION WAVE EVENTS (Surges, Minibosses, Bosses)
	if g.game_time >= 90.0 && g.stage_event_idx == 0 {
		g.stage_event_idx = 1
		g.trigger_wave_event('💀 SKELETON WARLORD RISES! 💀')
		mut warlord := g.create_scaled_enemy(.skeleton, target_p.x + 350.0, target_p.y + 350.0, false, true)
		warlord.hp *= 3.0
		warlord.max_hp = warlord.hp
		warlord.damage *= 1.4
		warlord.radius *= 1.6
		g.enemies << warlord
		for _ in 0 .. 8 {
			ang := rand.f64() * math.pi * 2.0
			g.enemies << g.create_scaled_enemy(.skeleton, target_p.x + math.cos(ang) * 450.0, target_p.y + math.sin(ang) * 450.0, false, false)
		}
	} else if g.game_time >= 180.0 && g.stage_event_idx == 1 {
		g.stage_event_idx = 2
		g.trigger_wave_event('🦇 SURGE: 360° BAT SWARM RING! 🦇')
		ring_count := 32
		for k in 0 .. ring_count {
			ang := f64(k) * (math.pi * 2.0 / f64(ring_count))
			sx := math.clamp(target_p.x + math.cos(ang) * 520.0, 20.0, world_width - 20.0)
			sy := math.clamp(target_p.y + math.sin(ang) * 520.0, 20.0, world_height - 20.0)
			mut bat := g.create_scaled_enemy(.bat, sx, sy, false, false)
			bat.speed *= 1.25
			g.enemies << bat
		}
	} else if g.game_time >= 300.0 && g.stage_event_idx == 2 {
		g.stage_event_idx = 3
		g.trigger_wave_event('👹 MID-STAGE OVERLORD: CRIMSON GARGANTUA! 👹')
		mut gargantua := g.create_scaled_enemy(.werewolf, target_p.x + 400.0, target_p.y + 400.0, true, true)
		gargantua.hp = 4200.0 * stage_cap_mult * diff_cap_mult
		gargantua.max_hp = gargantua.hp
		gargantua.radius = 28.0
		g.enemies << gargantua
	} else if g.game_time >= 450.0 && g.stage_event_idx == 3 {
		g.stage_event_idx = 4
		g.trigger_wave_event('👻 SURGE: PHANTOM SPECTRE HORDE! 👻')
		ring_count := 36
		for k in 0 .. ring_count {
			ang := f64(k) * (math.pi * 2.0 / f64(ring_count))
			sx := math.clamp(target_p.x + math.cos(ang) * 550.0, 20.0, world_width - 20.0)
			sy := math.clamp(target_p.y + math.sin(ang) * 550.0, 20.0, world_height - 20.0)
			mut ghost := g.create_scaled_enemy(if k % 2 == 0 { EnemyType.ghost } else { EnemyType.red_skull }, sx, sy, false, false)
			ghost.speed *= 1.2
			g.enemies << ghost
		}
	} else if g.game_time >= 600.0 && g.stage_event_idx == 4 {
		g.stage_event_idx = 5
		g.last_boss_spawn = g.game_time
		stg_title := match g.stage {
			.mad_forest { 'MAD FOREST' }
			.inlaid_library { 'INLAID LIBRARY' }
			.castle_grounds { 'CASTLE GROUNDS' }
		}
		g.trigger_wave_event('☠️ STAGE BOSS: THE DEATH REAPER OF ${stg_title}! ☠️')
		boss_base_hp := match g.stage {
			.mad_forest { 8000.0 }
			.inlaid_library { 12000.0 }
			.castle_grounds { 18000.0 }
		}
		mut reaper := g.create_scaled_enemy(.reaper_boss, target_p.x + 350.0, target_p.y + 350.0, true, true)
		reaper.hp = boss_base_hp * diff_cap_mult
		reaper.max_hp = reaper.hp
		g.enemies << reaper
	}

	// Regular Spawning Cycle
	if g.spawn_timer >= rate && g.enemies.len < max_enemies {
		g.spawn_timer = 0.0

		burst := if g.game_time < 35.0 {
			1
		} else if g.game_time < 90.0 {
			2
		} else if g.game_time < 180.0 {
			3
		} else if g.game_time < 360.0 {
			4
		} else if g.game_time < 600.0 {
			6
		} else {
			8
		}

		for _ in 0 .. burst {
			if g.enemies.len >= max_enemies {
				break
			}
			ang := rand.f64() * math.pi * 2.0
			spawn_d := 650.0
			sx := math.clamp(target_p.x + math.cos(ang) * spawn_d, 20.0, world_width - 20.0)
			sy := math.clamp(target_p.y + math.sin(ang) * spawn_d, 20.0, world_height - 20.0)

			m := g.game_time / 60.0
			mut e_kind := EnemyType.bat

			// Stage-Specific Enemy Pool
			match g.stage {
				.mad_forest {
					if m < 0.7 {
						e_kind = EnemyType.bat
					} else if m < 1.6 {
						e_kind = if rand.f64() < 0.65 { EnemyType.bat } else { EnemyType.skeleton }
					} else if m < 3.0 {
						r := rand.f64()
						e_kind = if r < 0.25 { EnemyType.skeleton } else if r < 0.65 { EnemyType.zombie } else { EnemyType.ghost }
					} else if m < 5.0 {
						r := rand.f64()
						e_kind = if r < 0.25 { EnemyType.zombie } else if r < 0.60 { EnemyType.mudman } else { EnemyType.werewolf }
					} else {
						r := rand.f64()
						e_kind = if r < 0.35 { EnemyType.werewolf } else if r < 0.70 { EnemyType.red_skull } else { EnemyType.ghost }
					}
				}
				.inlaid_library {
					if m < 0.7 {
						e_kind = if rand.f64() < 0.65 { EnemyType.bat } else { EnemyType.skeleton }
					} else if m < 1.6 {
						e_kind = if rand.f64() < 0.40 { EnemyType.skeleton } else { EnemyType.ghost }
					} else if m < 3.0 {
						r := rand.f64()
						e_kind = if r < 0.45 { EnemyType.ghost } else if r < 0.75 { EnemyType.zombie } else { EnemyType.werewolf }
					} else {
						r := rand.f64()
						e_kind = if r < 0.40 { EnemyType.red_skull } else if r < 0.75 { EnemyType.werewolf } else { EnemyType.ghost }
					}
				}
				.castle_grounds {
					if m < 0.7 {
						e_kind = if rand.f64() < 0.50 { EnemyType.bat } else { EnemyType.skeleton }
					} else if m < 1.6 {
						e_kind = if rand.f64() < 0.35 { EnemyType.skeleton } else { EnemyType.werewolf }
					} else if m < 3.0 {
						r := rand.f64()
						e_kind = if r < 0.35 { EnemyType.werewolf } else if r < 0.70 { EnemyType.mudman } else { EnemyType.red_skull }
					} else {
						r := rand.f64()
						e_kind = if r < 0.45 { EnemyType.red_skull } else if r < 0.80 { EnemyType.werewolf } else { EnemyType.mudman }
					}
				}
			}

			// Random Champions
			champ_chance := if m < 1.0 {
				0.0
			} else if m < 3.0 {
				if g.difficulty == .inferno { 0.12 } else if g.difficulty == .hard { 0.06 } else { 0.02 }
			} else if m < 6.0 {
				if g.difficulty == .inferno { 0.22 } else if g.difficulty == .hard { 0.14 } else { 0.06 }
			} else {
				if g.difficulty == .inferno { 0.30 } else if g.difficulty == .hard { 0.20 } else { 0.10 }
			}
			is_champ := rand.f64() < champ_chance
			g.enemies << g.create_scaled_enemy(e_kind, sx, sy, false, is_champ)
		}
	}

	// Post-10-minute periodic boss spawns
	boss_interval := if g.difficulty == .inferno { 75.0 } else if g.difficulty == .hard { 100.0 } else { 120.0 }
	if g.game_time > 660.0 && g.game_time - g.last_boss_spawn >= boss_interval && g.enemies.len < max_enemies {
		g.last_boss_spawn = g.game_time
		g.trigger_wave_event('☠️ ELITE REAPER INVASION! ☠️')
		g.enemies << g.create_scaled_enemy(.reaper_boss, target_p.x + 350.0, target_p.y + 350.0, true, false)
	}
}

pub fn create_enemy(kind EnemyType, x f64, y f64, is_boss bool) Enemy {
	mut g := new_game()
	return g.create_scaled_enemy(kind, x, y, is_boss, false)
}

pub fn (g &Game) create_scaled_enemy(kind EnemyType, x f64, y f64, is_boss bool, is_champ bool) Enemy {
	mut hp := 10.0
	mut speed := 75.0
	mut dmg := 10.0
	mut rad := 14.0
	mut xp := 1

	match kind {
		.bat {
			hp = 10.0
			speed = 95.0
			dmg = 5.0
			rad = 11.0
			xp = 1
		}
		.skeleton {
			hp = 18.0
			speed = 65.0
			dmg = 8.0
			rad = 13.0
			xp = 1
		}
		.zombie {
			hp = 45.0
			speed = 52.0
			dmg = 12.0
			rad = 15.0
			xp = 5
		}
		.ghost {
			hp = 30.0
			speed = 78.0
			dmg = 10.0
			rad = 14.0
			xp = 5
		}
		.mudman {
			hp = 100.0
			speed = 50.0
			dmg = 18.0
			rad = 17.0
			xp = 5
		}
		.werewolf {
			hp = 160.0
			speed = 115.0
			dmg = 24.0
			rad = 18.0
			xp = 25
		}
		.red_skull {
			hp = 260.0
			speed = 85.0
			dmg = 28.0
			rad = 20.0
			xp = 25
		}
		.reaper_boss {
			hp = 2400.0
			speed = 110.0
			dmg = 45.0
			rad = 32.0
			xp = 100
		}
	}

	// Stage-Specific Progression Multipliers
	stg_hp, stg_dmg, stg_spd := match g.stage {
		.mad_forest { 1.0, 1.0, 1.0 }
		.inlaid_library { 1.35, 1.25, 1.15 }
		.castle_grounds { 1.85, 1.60, 1.28 }
	}

	// Dynamic Time and Difficulty Scaling
	diff_hp, diff_dmg, diff_spd := match g.difficulty {
		.normal { 1.0, 1.0, 1.0 }
		.hard { 1.25, 1.20, 1.18 }
		.inferno { 3.2, 1.85, 1.35 }
	}

	time_hp := if g.game_time <= 45.0 {
		1.0 + g.game_time * 0.002
	} else {
		1.0 + (g.game_time - 45.0) * 0.0075 + math.pow((g.game_time - 45.0) / 140.0, 1.7) * 0.85
	}

	time_dmg := if g.game_time <= 45.0 {
		1.0 + g.game_time * 0.0015
	} else {
		1.0 + (g.game_time - 45.0) * 0.005
	}

	time_spd := if g.game_time <= 45.0 {
		1.0 + g.game_time * 0.001
	} else {
		1.0 + math.min(0.60, (g.game_time - 45.0) * 0.0016)
	}

	hp *= stg_hp * diff_hp * time_hp
	dmg *= stg_dmg * diff_dmg * time_dmg
	speed *= stg_spd * diff_spd * time_spd

	if is_champ {
		hp *= 2.5
		dmg *= 1.5
		rad *= 1.3
		xp *= 3
	}

	if is_boss {
		hp *= 2.5
		rad *= 1.4
	}

	return Enemy{
		kind:        kind
		x:           x
		y:           y
		hp:          hp
		max_hp:      hp
		speed:       speed
		damage:      dmg
		radius:      rad
		exp_val:     xp
		is_boss:     is_boss
		is_champion: is_champ
	}
}

pub fn (mut g Game) update_enemies(dt f64) {
	for i := g.enemies.len - 1; i >= 0; i-- {
		mut e := unsafe { &g.enemies[i] }
		if e.flash_time > 0 {
			e.flash_time -= dt
		}

		if e.hp <= 0 {
			g.total_kills++
			g.combo_kills++
			g.combo_timer = 2.8

			if g.combo_kills % 25 == 0 && g.combo_kills > 0 {
				g.sound_mgr.play_combo_sound()
				g.combo_title_t = 2.0
				g.combo_title = match true {
					g.combo_kills >= 100 { 'GODLIKE! ${g.combo_kills} KILLS!' }
					g.combo_kills >= 75 { 'UNSTOPPABLE! ${g.combo_kills} KILLS!' }
					g.combo_kills >= 50 { 'DOMINATING! ${g.combo_kills} KILLS!' }
					else { 'RAMPAGE! ${g.combo_kills} KILLS!' }
				}
			}

			for mut p in g.players {
				if p.hp > 0 && p.ultimate_meter < p.ultimate_max {
					p.ultimate_meter = math.min(p.ultimate_max, p.ultimate_meter + 0.8)
				}
			}

			if g.blood_stains.len < 120 {
				g.blood_stains << BloodStain{
					x:    e.x
					y:    e.y
					rad:  rand.f64() * 8.0 + 8.0
					life: 35.0
				}
			}

			g.spawn_death_particles(e.x, e.y, e.kind)
			g.sound_mgr.play_kill_sound()

			if e.is_boss {
				for mut p in g.players {
					p.gold += 1000
				}
				if g.stage == .mad_forest && 'inlaid_library' !in g.save_data.unlocked_stages {
					g.save_data.unlocked_stages << 'inlaid_library'
					save_data_to_file(&g.save_data)
					g.trigger_wave_event('🏆 STAGE 1 CONQUERED! INLAID LIBRARY UNLOCKED! 🏆')
				} else if g.stage == .inlaid_library && 'castle_grounds' !in g.save_data.unlocked_stages {
					g.save_data.unlocked_stages << 'castle_grounds'
					save_data_to_file(&g.save_data)
					g.trigger_wave_event('🏆 STAGE 2 CONQUERED! CASTLE GROUNDS UNLOCKED! 🏆')
				} else if g.stage == .castle_grounds {
					g.trigger_wave_event('👑 ALL STAGES CONQUERED! TRUE AAA SURVIVOR! 👑')
				}
			}

			gem_kind := if e.is_boss || (e.is_champion && rand.f64() < 0.40) {
				GemType.chest
			} else if e.exp_val >= 25 {
				GemType.red
			} else if e.exp_val >= 5 {
				GemType.green
			} else {
				GemType.blue
			}
			g.gems << ExpGem{
				kind:  gem_kind
				x:     e.x
				y:     e.y
				value: if g.hyper_mode { e.exp_val * 2 } else { e.exp_val }
			}
			g.enemies.delete(i)
			continue
		}

		// Move towards closest alive player
		mut closest_p := g.players[0]
		mut min_d := 999999.0
		for p in g.players {
			if p.hp > 0 {
				d := dist(e.x, e.y, p.x, p.y)
				if d < min_d {
					min_d = d
					closest_p = p
				}
			}
		}

		// Knockback dampening & movement
		if math.abs(e.kb_vx) > 0.05 || math.abs(e.kb_vy) > 0.05 {
			e.x += e.kb_vx * dt
			e.y += e.kb_vy * dt
			e.kb_vx *= 0.86
			e.kb_vy *= 0.86
		}

		if min_d > 0.001 {
			dx, dy := normalize(closest_p.x - e.x, closest_p.y - e.y)
			e.vx = dx * e.speed
			e.vy = dy * e.speed
			e.x += e.vx * dt
			e.y += e.vy * dt

			// Dynamic Enemy Ranged Shooting & Boss Telegraphed Hazards
			if min_d < 520.0 {
				e.shoot_timer += dt
				if e.is_boss {
					if e.shoot_timer >= 1.6 {
						e.shoot_timer = 0.0
						if rand.f64() < 0.35 {
							// Spawn Telegraphed Ground Warning Hazard
							g.hazard_zones << HazardZone{
								x:        closest_p.x + (rand.f64() * 60.0 - 30.0)
								y:        closest_p.y + (rand.f64() * 60.0 - 30.0)
								radius:   85.0
								timer:    0.85
								max_t:    0.85
								damage:   38.0
								target_x: closest_p.x
								target_y: closest_p.y
							}
						} else {
							// 3-way fan of scythe slash projectiles
							base_ang := math.atan2(dy, dx)
							for spread in [-0.25, 0.0, 0.25] {
								ang := base_ang + spread
								g.enemy_projectiles << EnemyProjectile{
									x:      e.x
									y:      e.y
									vx:     math.cos(ang) * 280.0
									vy:     math.sin(ang) * 280.0
									damage: 28.0
									life:   3.2
									radius: 12.0
								}
							}
						}
					}
				} else if e.kind == .red_skull {
					if e.shoot_timer >= 2.2 {
						e.shoot_timer = 0.0
						g.enemy_projectiles << EnemyProjectile{
							x:      e.x
							y:      e.y
							vx:     dx * 270.0
							vy:     dy * 270.0
							damage: 18.0
							life:   3.0
							radius: 9.0
						}
					}
				} else if e.kind == .skeleton && g.game_time > 75.0 {
					if e.shoot_timer >= 3.6 {
						e.shoot_timer = 0.0
						g.enemy_projectiles << EnemyProjectile{
							x:      e.x
							y:      e.y
							vx:     dx * 240.0
							vy:     dy * 240.0
							damage: 10.0
							life:   2.5
							radius: 8.0
						}
					}
				} else if e.kind == .ghost && (g.game_time > 120.0 || g.stage != .mad_forest) {
					if e.shoot_timer >= 3.2 {
						e.shoot_timer = 0.0
						g.enemy_projectiles << EnemyProjectile{
							x:      e.x
							y:      e.y
							vx:     dx * 260.0
							vy:     dy * 260.0
							damage: 14.0
							life:   2.8
							radius: 9.0
						}
					}
				}
			}
		}

		// Contact damage
		for p_idx in 0 .. g.players.len {
			mut p := unsafe { &g.players[p_idx] }
			if p.hp <= 0 || p.invuln_time > 0 {
				continue
			}
			if dist(p.x, p.y, e.x, e.y) < 14.0 + e.radius {
				armor := f64(p.get_passive_level(.armor))
				min_contact := if g.game_time < 60.0 { 3.0 } else if g.game_time < 240.0 { 6.0 } else { 12.0 }
				dmg := math.max(min_contact, e.damage - armor)
				p.hp -= dmg
				p.invuln_time = 0.50
				g.sound_mgr.play_hurt_sound()
				g.dmg_nums << DamageNum{
					x:       p.x
					y:       p.y - 15.0
					val:     int(dmg)
					life:    0.8
					is_crit: false
				}
			}
		}
	}
}

pub fn (mut g Game) update_projectiles(dt f64) {
	for i := g.projectiles.len - 1; i >= 0; i-- {
		mut pr := unsafe { &g.projectiles[i] }
		pr.life -= dt

		if pr.life <= 0 {
			g.projectiles.delete(i)
			continue
		}

		if pr.kind == .holy_bible || pr.kind == .unholy_vespers {
			if pr.owner_id < g.players.len {
				p := g.players[pr.owner_id]
				pr.angle += dt * 4.8
				pr.x = p.x + math.cos(pr.angle) * pr.orbit_dist
				pr.y = p.y + math.sin(pr.angle) * pr.orbit_dist
			}
		} else if pr.kind == .axe {
			pr.vy += 700.0 * dt
			pr.x += pr.vx * dt
			pr.y += pr.vy * dt
		} else if pr.kind == .garlic || pr.kind == .soul_eater || pr.kind == .whip || pr.kind == .bloody_tear {
			// Instant aura
		} else {
			pr.x += pr.vx * dt
			pr.y += pr.vy * dt
		}

		for b_idx := g.breakables.len - 1; b_idx >= 0; b_idx-- {
			mut br := unsafe { &g.breakables[b_idx] }
			if dist(pr.x, pr.y, br.x, br.y) < pr.radius + 18.0 {
				br.hp -= 1.0
				g.sound_mgr.play_smash_sound()
				r_val := rand.f64()
				f_type := if r_val < 0.15 {
					FloorPickupType.vacuum_orb
				} else if r_val < 0.28 {
					FloorPickupType.rosary_bomb
				} else if r_val < 0.42 {
					FloorPickupType.freeze_watch
				} else if r_val < 0.70 {
					FloorPickupType.floor_chicken
				} else {
					FloorPickupType.coin_bag
				}
				g.floor_pickups << FloorPickup{
					kind: f_type
					x:    br.x
					y:    br.y
				}
				g.breakables.delete(b_idx)
			}
		}

		for mut e in g.enemies {
			if e.hp <= 0 {
				continue
			}
			if dist(pr.x, pr.y, e.x, e.y) < pr.radius + e.radius {
				clover_bonus := if pr.owner_id < g.players.len { f64(g.players[pr.owner_id].get_passive_level(.clover)) * 0.10 } else { 0.0 }
				base_crit := if pr.kind == .bloody_tear { 0.35 } else { 0.15 }
				is_crit := pr.is_ultimate || rand.f64() < base_crit + clover_bonus
				dmg := if is_crit { pr.damage * 2.2 } else { pr.damage }
				e.hp -= dmg
				e.flash_time = 0.10

				// Knockback Impulse
				mut kx, mut ky := normalize(e.x - pr.x, e.y - pr.y)
				if kx == 0.0 && ky == 0.0 {
					kx = 1.0
				}
				kb_power := match pr.kind {
					.whip, .bloody_tear { 160.0 }
					.axe, .death_spiral { 180.0 }
					.cataclysm_nuke, .supernova { 250.0 }
					.holy_bible, .unholy_vespers { 120.0 }
					.garlic, .soul_eater { 80.0 }
					else { 90.0 }
				}
				if !e.is_boss {
					e.kb_vx += kx * kb_power
					e.kb_vy += ky * kb_power
				}

				if pr.kind == .bloody_tear && is_crit && pr.owner_id < g.players.len {
					mut p := unsafe { &g.players[pr.owner_id] }
					p.hp = math.min(p.max_hp, p.hp + 8.0)
					g.dmg_nums << DamageNum{
						x:       p.x
						y:       p.y - 20.0
						val:     8
						life:    0.8
						is_heal: true
					}
				}

				if pr.owner_id < g.players.len {
					for mut w in g.players[pr.owner_id].weapons {
						if w.kind == pr.kind {
							w.total_damage += dmg
							break
						}
					}
				}

				g.dmg_nums << DamageNum{
					x:       e.x + (rand.f64() * 12.0 - 6.0)
					y:       e.y - 10.0
					val:     int(dmg)
					life:    0.7
					is_crit: is_crit
				}

				pr.pierce--
				if pr.pierce <= 0 {
					g.projectiles.delete(i)
					break
				}
			}
		}
	}
}

pub fn (mut g Game) update_hazard_zones(dt f64) {
	for i := g.hazard_zones.len - 1; i >= 0; i-- {
		mut hz := unsafe { &g.hazard_zones[i] }
		hz.timer -= dt
		if hz.timer <= 0 && !hz.fired {
			hz.fired = true
			g.shake_timer = 0.35
			g.sound_mgr.play_nuke_sound()
			for p_idx in 0 .. g.players.len {
				mut p := unsafe { &g.players[p_idx] }
				if p.hp <= 0 || p.invuln_time > 0 {
					continue
				}
				if dist(p.x, p.y, hz.x, hz.y) < hz.radius {
					armor := f64(p.get_passive_level(.armor))
					dmg := math.max(5.0, hz.damage - armor)
					p.hp -= dmg
					p.invuln_time = 0.40
					g.sound_mgr.play_hurt_sound()
					g.dmg_nums << DamageNum{
						x:       p.x
						y:       p.y - 15.0
						val:     int(dmg)
						life:    0.8
						is_crit: true
					}
				}
			}
		}
		if hz.timer <= -0.40 {
			g.hazard_zones.delete(i)
		}
	}
}

pub fn (mut g Game) update_gems(dt f64) {
	for i := g.gems.len - 1; i >= 0; i-- {
		mut gem := unsafe { &g.gems[i] }
		if gem.magnetized {
			mut closest_idx := 0
			mut min_d := 999999.0
			for p_idx in 0 .. g.players.len {
				if g.players[p_idx].hp > 0 {
					d := dist(gem.x, gem.y, g.players[p_idx].x, g.players[p_idx].y)
					if d < min_d {
						min_d = d
						closest_idx = p_idx
					}
				}
			}

			gem.speed += dt * 850.0
			dx, dy := normalize(g.players[closest_idx].x - gem.x, g.players[closest_idx].y - gem.y)
			gem.x += dx * gem.speed * dt
			gem.y += dy * gem.speed * dt

			if min_d < 22.0 {
				if gem.kind == .chest {
					g.open_treasure_chest()
				} else {
					g.sound_mgr.play_gem_pickup_sound(gem.value)
					mut p := unsafe { &g.players[closest_idx] }
					crown_mult := 1.0 + f64(p.get_passive_level(.crown)) * 0.12 + if p.char_class == .imelda { 0.15 } else { 0.0 }
					g_val := int(f64(gem.value) * crown_mult)
					p.exp += g_val
					p.gold += gem.value

					if p.exp >= p.exp_next {
						p.exp -= p.exp_next
						p.level++
						p.exp_next = int(f64(p.exp_next) * 1.30) + 5
						g.sound_mgr.play_level_up_sound()
						g.trigger_level_up(p.id)
					}
				}

				g.gems.delete(i)
			}
		}
	}
}

pub fn (mut g Game) open_treasure_chest() {
	g.state = .chest_opened
	g.chest_timer = 2.5
	g.chest_items.clear()

	r := rand.f64()
	g.chest_tier = if r < 0.20 { 5 } else if r < 0.55 { 3 } else { 1 }

	if g.chest_tier == 5 {
		g.sound_mgr.play_jackpot_sound()
		g.shake_timer = 0.60
		g.chest_items << '⭐️⭐️⭐️⭐️⭐️ MEGA JACKPOT CHEST! ⭐️⭐️⭐️⭐️⭐️'
		g.chest_items << '+1,000 GOLD COINS'
		g.chest_items << 'MAX HEALTH FULLY RESTORED'
		for mut p in g.players {
			p.gold += 1000
			p.hp = p.max_hp
		}
	} else if g.chest_tier == 3 {
		g.sound_mgr.play_chest_sound()
		g.chest_items << '⭐️⭐️⭐️ SUPER TRIPLE CHEST!'
		g.chest_items << '+500 GOLD COINS'
		for mut p in g.players {
			p.gold += 500
			p.hp = math.min(p.max_hp, p.hp + 60.0)
		}
	} else {
		g.sound_mgr.play_chest_sound()
		g.chest_items << 'TREASURE CHEST: +250 GOLD'
		for mut p in g.players {
			p.gold += 250
			p.hp = math.min(p.max_hp, p.hp + 35.0)
		}
	}

	for p_idx in 0 .. g.players.len {
		mut p := unsafe { &g.players[p_idx] }
		for w_idx in 0 .. p.weapons.len {
			w := p.weapons[w_idx]
			if w.level >= 8 && !w.is_evolved {
				evolved_k, ok := get_weapon_evolution(w.kind, p)
				if ok {
					p.weapons[w_idx] = create_weapon(evolved_k)
					g.sound_mgr.play_evolution_sound()
					g.chest_items << '🔥 SUPER WEAPON EVOLVED: ${get_weapon_name(evolved_k)}!'
					break
				}
			}
		}
	}
}

pub fn get_weapon_evolution(kind WeaponType, p &Player) (WeaponType, bool) {
	match kind {
		.whip {
			if p.get_passive_level(.spinach) >= 1 {
				return WeaponType.bloody_tear, true
			}
		}
		.magic_wand {
			if p.get_passive_level(.empty_tome) >= 1 {
				return WeaponType.holy_wand, true
			}
		}
		.knife {
			if p.get_passive_level(.duplicator) >= 1 {
				return WeaponType.thousand_edge, true
			}
		}
		.axe {
			if p.get_passive_level(.wings) >= 1 {
				return WeaponType.death_spiral, true
			}
		}
		.holy_bible {
			if p.get_passive_level(.crown) >= 1 {
				return WeaponType.unholy_vespers, true
			}
		}
		.garlic {
			if p.get_passive_level(.armor) >= 1 {
				return WeaponType.soul_eater, true
			}
		}
		.lightning_ring {
			if p.get_passive_level(.duplicator) >= 1 {
				return WeaponType.thunder_loop, true
			}
		}
		.fire_wand {
			if p.get_passive_level(.spinach) >= 1 {
				return WeaponType.hellfire, true
			}
		}
		.cataclysm_nuke {
			if p.get_passive_level(.hollow_heart) >= 1 {
				return WeaponType.supernova, true
			}
		}
		.prismatic_laser {
			if p.get_passive_level(.clover) >= 1 {
				return WeaponType.gamma_ray, true
			}
		}
		else {}
	}
	return WeaponType.whip, false
}

pub fn (mut g Game) trigger_level_up(p_idx int) {
	g.state = .level_up
	g.selected_card = 0
	g.upgrade_cards.clear()

	p := g.players[p_idx]

	for w in p.weapons {
		if w.level >= 8 && !w.is_evolved {
			evolved_k, ok := get_weapon_evolution(w.kind, &p)
			if ok {
				e_name, e_desc := get_weapon_info(evolved_k)
				if e_name !in p.banished_items {
					g.upgrade_cards << UpgradeChoice{
						is_weapon:    true
						w_kind:       evolved_k
						name:         e_name
						desc:         e_desc
						level:        8
						is_evolution: true
					}
				}
			}
		}
	}

	mut available_weapons := [
		WeaponType.whip,
		WeaponType.magic_wand,
		WeaponType.knife,
		WeaponType.axe,
		WeaponType.holy_bible,
		WeaponType.garlic,
		WeaponType.lightning_ring,
		WeaponType.fire_wand,
		WeaponType.cataclysm_nuke,
		WeaponType.prismatic_laser,
	]
	mut available_passives := [
		PassiveType.spinach,
		PassiveType.armor,
		PassiveType.empty_tome,
		PassiveType.wings,
		PassiveType.crown,
		PassiveType.duplicator,
		PassiveType.clover,
		PassiveType.hollow_heart,
		PassiveType.pumarola,
	]

	// Slot & Banish Filtered Lists
	mut filtered_weapons := []WeaponType{}
	for w_k in available_weapons {
		w_name, _ := get_weapon_info(w_k)
		if w_name in p.banished_items {
			continue
		}
		mut owns := false
		mut maxed := false
		for w in p.weapons {
			if w.kind == w_k {
				owns = true
				if w.level >= 8 {
					maxed = true
				}
				break
			}
		}
		if maxed {
			continue
		}
		if owns || p.weapons.len < 6 {
			filtered_weapons << w_k
		}
	}

	mut filtered_passives := []PassiveType{}
	for p_k in available_passives {
		p_name, _ := get_passive_info(p_k)
		if p_name in p.banished_items {
			continue
		}
		mut owns := false
		mut maxed := false
		for pass in p.passives {
			if pass.kind == p_k {
				owns = true
				if pass.level >= 5 {
					maxed = true
				}
				break
			}
		}
		if maxed {
			continue
		}
		if owns || p.passives.len < 6 {
			filtered_passives << p_k
		}
	}

	for g.upgrade_cards.len < 3 {
		is_w := rand.f64() < 0.55
		if is_w && filtered_weapons.len > 0 {
			idx := rand.int_in_range(0, filtered_weapons.len) or { 0 }
			w_k := filtered_weapons[idx]
			filtered_weapons.delete(idx)

			mut lvl := 1
			for w in p.weapons {
				if w.kind == w_k {
					lvl = w.level + 1
				}
			}

			w_name, w_desc := get_weapon_info(w_k)
			g.upgrade_cards << UpgradeChoice{
				is_weapon: true
				w_kind:    w_k
				name:      w_name
				desc:      w_desc
				level:     lvl
			}
		} else if filtered_passives.len > 0 {
			idx := rand.int_in_range(0, filtered_passives.len) or { 0 }
			p_k := filtered_passives[idx]
			filtered_passives.delete(idx)

			mut lvl := 1
			for pass in p.passives {
				if pass.kind == p_k {
					lvl = pass.level + 1
				}
			}

			p_name, p_desc := get_passive_info(p_k)
			g.upgrade_cards << UpgradeChoice{
				is_weapon: false
				p_kind:    p_k
				name:      p_name
				desc:      p_desc
				level:     lvl
			}
		} else {
			break
		}
	}

	if g.upgrade_cards.len == 0 {
		g.upgrade_cards << UpgradeChoice{
			is_weapon: false
			p_kind:    .crown
			name:      'GOLD COIN BAG'
			desc:      'Full inventory bonus: Grants +350 Gold Coins'
			level:     1
		}
	}
}

pub fn (mut g Game) reroll_upgrades(p_idx int) {
	if p_idx >= g.players.len {
		return
	}
	mut p := unsafe { &g.players[p_idx] }
	if p.rerolls <= 0 {
		return
	}
	p.rerolls--
	g.sound_mgr.play_gem_pickup_sound(50)
	g.trigger_level_up(p_idx)
}

pub fn (mut g Game) skip_upgrade(p_idx int) {
	if p_idx >= g.players.len {
		return
	}
	mut p := unsafe { &g.players[p_idx] }
	if p.skips <= 0 {
		return
	}
	p.skips--
	p.exp += 50
	p.gold += 100
	g.sound_mgr.play_gem_pickup_sound(50)
	g.state = .playing
}

pub fn (mut g Game) banish_upgrade(p_idx int, card_idx int) {
	if p_idx >= g.players.len || card_idx < 0 || card_idx >= g.upgrade_cards.len {
		return
	}
	mut p := unsafe { &g.players[p_idx] }
	if p.banishes <= 0 {
		return
	}
	p.banishes--
	card := g.upgrade_cards[card_idx]
	if card.name !in p.banished_items {
		p.banished_items << card.name
	}
	g.sound_mgr.play_smash_sound()
	g.trigger_level_up(p_idx)
}

pub fn (mut g Game) select_upgrade(card_idx int) {
	if card_idx < 0 || card_idx >= g.upgrade_cards.len {
		return
	}
	card := g.upgrade_cards[card_idx]
	mut p := unsafe { &g.players[0] }

	if card.name == 'GOLD COIN BAG' {
		p.gold += 350
		g.sound_mgr.play_gem_pickup_sound(100)
		g.state = .playing
		return
	}

	if card.is_weapon {
		if card.is_evolution {
			g.sound_mgr.play_evolution_sound()
			for w_i in 0 .. p.weapons.len {
				base_match := match card.w_kind {
					.bloody_tear { WeaponType.whip }
					.holy_wand { WeaponType.magic_wand }
					.thousand_edge { WeaponType.knife }
					.death_spiral { WeaponType.axe }
					.unholy_vespers { WeaponType.holy_bible }
					.soul_eater { WeaponType.garlic }
					.thunder_loop { WeaponType.lightning_ring }
					.hellfire { WeaponType.fire_wand }
					.supernova { WeaponType.cataclysm_nuke }
					.gamma_ray { WeaponType.prismatic_laser }
					else { WeaponType.whip }
				}
				if p.weapons[w_i].kind == base_match {
					p.weapons[w_i] = create_weapon(card.w_kind)
					break
				}
			}
		} else {
			mut found := false
			for mut w in p.weapons {
				if w.kind == card.w_kind {
					w.level++
					w.damage *= 1.30
					w.count += if w.level % 2 == 0 { 1 } else { 0 }
					w.cooldown *= 0.90
					found = true
					break
				}
			}
			if !found && p.weapons.len < 6 {
				p.weapons << create_weapon(card.w_kind)
			}
		}
	} else {
		mut found := false
		for mut pass in p.passives {
			if pass.kind == card.p_kind {
				pass.level++
				found = true
				break
			}
		}
		if !found && p.passives.len < 6 {
			p.passives << Passive{kind: card.p_kind, level: 1}
		}
	}

	g.state = .playing
}

pub fn get_weapon_name(kind WeaponType) string {
	name, _ := get_weapon_info(kind)
	return name
}

pub fn get_weapon_info(kind WeaponType) (string, string) {
	return match kind {
		.whip { 'WHIP', 'Attacks horizontally in front & behind with high damage' }
		.bloody_tear { 'BLOODY TEAR', 'EVOLVED: Critical slashes leech life & heal +8 HP' }
		.magic_wand { 'MAGIC WAND', 'Fires homing mystic energy at the nearest enemy' }
		.holy_wand { 'HOLY WAND', 'EVOLVED: Fires a continuous stream with zero cooldown' }
		.knife { 'KNIFE', 'Rapidly shoots daggers in facing direction' }
		.thousand_edge { 'THOUSAND EDGE', 'EVOLVED: Machine-gun barrage of piercing blades' }
		.axe { 'AXE', 'Arcs upward and rains down in heavy parabolic curve' }
		.death_spiral { 'DEATH SPIRAL', 'EVOLVED: Fires 16 rotating scythes in full 360 circle' }
		.holy_bible { 'KING BIBLE', 'Orbits in a defensive halo ring around player' }
		.unholy_vespers { 'UNHOLY VESPERS', 'EVOLVED: Permanent invincible rotating barrier' }
		.garlic { 'GARLIC', 'Continuous damaging holy aura around the survivor' }
		.soul_eater { 'SOUL EATER', 'EVOLVED: Giant black hole aura that absorbs enemy life' }
		.lightning_ring { 'LIGHTNING RING', 'Strikes random enemies with thunderbolts' }
		.fire_wand { 'FIRE WAND', 'Launches high-damage fiery blasts' }
		.cataclysm_nuke { 'CATACLYSM NUKE', 'Massive holy cluster bomb with huge blast wave' }
		.prismatic_laser { 'PRISMATIC LASER', 'Colossal piercing death beam that melts swarms' }
		.thunder_loop { 'THUNDER LOOP', 'EVOLVED: Bouncing chain lightning strikes double target swarms' }
		.hellfire { 'HELLFIRE', 'EVOLVED: Giant fiery meteors that pierce all obstacles' }
		.supernova { 'SUPERNOVA', 'EVOLVED: Massive cosmic implosion leaves radioactive holy pools' }
		.gamma_ray { 'GAMMA RAY', 'EVOLVED: Continuous 360-degree orbital beam of total annihilation' }
	}
}

pub fn get_passive_info(kind PassiveType) (string, string) {
	return match kind {
		.spinach { 'SPINACH', '+15% Damage dealt per level' }
		.armor { 'ARMOR', 'Reduces incoming damage by 1 per level' }
		.empty_tome { 'EMPTY TOME', '-10% Weapon cooldown per level' }
		.wings { 'WINGS', '+15% Movement speed per level' }
		.crown { 'CROWN', '+15% EXP gained per level' }
		.duplicator { 'DUPLICATOR', '+2 Extra projectiles for all weapons' }
		.clover { 'CLOVER', '+10% Critical strike chance per level' }
		.hollow_heart { 'HOLLOW HEART', '+20 Max HP per level' }
		.pumarola { 'PUMAROLA', '+1.0 HP Regeneration per second per level' }
	}
}

pub fn (mut g Game) spawn_death_particles(x f64, y f64, kind EnemyType) {
	r, gr, b := match kind {
		.bat { u8(140), u8(70), u8(180) }
		.skeleton { u8(220), u8(220), u8(220) }
		.zombie { u8(80), u8(180), u8(90) }
		.ghost { u8(120), u8(220), u8(255) }
		.mudman { u8(150), u8(110), u8(70) }
		.werewolf { u8(180), u8(50), u8(40) }
		.red_skull { u8(255), u8(60), u8(60) }
		.reaper_boss { u8(255), u8(215), u8(0) }
	}
	for _ in 0 .. 8 {
		ang := rand.f64() * math.pi * 2.0
		spd := rand.f64() * 120.0 + 30.0
		g.particles << Particle{
			x:     x
			y:     y
			vx:    math.cos(ang) * spd
			vy:    math.sin(ang) * spd
			life:  0.45
			max_l: 0.45
			r:     r
			g:     gr
			b:     b
			size:  3.5
		}
	}
}
