module main

import math
import os
import rand



pub enum WeaponType {
	standard
	baby_nuke
	mirv
	mountain_mover
	napalm
	digger
}

pub struct WeaponInfo {
pub:
	name   string
	cost   int
	radius int
	damage int
	desc   string
}

pub fn get_weapon_info(w WeaponType) WeaponInfo {
	return match w {
		.standard { WeaponInfo{'Standard Shell', 0, 26, 100, 'Unlimited supply basic artillery shell (100 Direct Damage)'} }
		.baby_nuke { WeaponInfo{'Baby Nuke', 350, 65, 160, 'High-yield explosive carving giant craters (160 Direct Damage)'} }
		.mirv { WeaponInfo{'MIRV Death Head', 450, 30, 60, 'Splits into 5 cluster warheads at apex (60 Damage each)'} }
		.mountain_mover { WeaponInfo{'Mountain Mover', 200, 35, 30, 'Creates a massive dirt mound barrier'} }
		.napalm { WeaponInfo{'Napalm Roller', 300, 35, 110, 'Liquid fire cascading down hillside (110 Damage)'} }
		.digger { WeaponInfo{'Digger Drill', 250, 22, 100, 'Tunnels straight through underground dirt (100 Damage)'} }
	}
}

pub struct Tank {
pub mut:
	name         string
	is_ai        bool
	x            int
	y            int
	angle        f64 = 45.0
	power        f64 = 500.0
	health       int = 100
	max_health   int = 100
	cash         int = 1000
	color        Color
	inventory    map[string]int
	active_wep   WeaponType = .standard
	has_shield   bool
	shield_hp    int
	kills        int
	is_dead      bool
	fall_dist    int
}

pub struct Projectile {
pub mut:
	wtype       WeaponType
	x           f64
	y           f64
	vx          f64
	vy          f64
	owner_id    int
	active      bool
	split_done  bool
	is_drilling bool
	drill_dist  f64
	is_napalm   bool
	life_time   f64
	trail       []f64
}

pub struct Explosion {
pub mut:
	x       f64
	y       f64
	radius  f64
	max_r   f64
	life    f64
	max_l   f64
	is_nuke bool
	col     Color
}

pub struct DamageText {
pub mut:
	x    f64
	y    f64
	text string
	col  Color
	life f64
}

pub struct ScorchedGame {
pub mut:
	width           int = 920
	height          int = 640
	terrain_y       []int
	tanks           []Tank
	current_turn    int
	wind            f64
	round           int = 1
	max_rounds      int = 5
	in_shop         bool
	is_game_over    bool

	projectiles     []Projectile
	explosions      []Explosion
	damage_texts    []DamageText

	sound_event     string
	banner_text     string
	banner_timer    f64
	ai_think_timer  f64
	round_end_timer f64
	sprite_texture  &Texture = unsafe { nil }
}

pub fn (mut g ScorchedGame) init_textures(renderer &Renderer) {
	paths := [
		'assets/sprites/scorchedearth.png',
		'./assets/sprites/scorchedearth.png',
		'../assets/sprites/scorchedearth.png',
		'scorchedearth/assets/sprites/scorchedearth.png',
	]
	for p in paths {
		if os.exists(p) {
			g.sprite_texture = load_texture(renderer.ctx, p)
			if g.sprite_texture != unsafe { nil } && g.sprite_texture.valid {
				println('scorchedearth Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn new_scorched_game() ScorchedGame {
	mut g := ScorchedGame{
		terrain_y: []int{len: 920, init: 400}
	}
	g.init_match()
	return g
}

pub fn (mut g ScorchedGame) init_match() {
	g.round = 1
	g.is_game_over = false
	g.in_shop = false
	g.round_end_timer = 0.0

	g.tanks.clear()
	mut t1 := Tank{
		name: 'Player 1'
		is_ai: false
		color: Color{40, 220, 100, 255}
	}
	t1.inventory[WeaponType.baby_nuke.str()] = 2
	t1.inventory[WeaponType.mirv.str()] = 2
	t1.inventory[WeaponType.mountain_mover.str()] = 1
	t1.inventory[WeaponType.napalm.str()] = 2
	t1.inventory[WeaponType.digger.str()] = 2
	g.tanks << t1

	mut t2 := Tank{
		name: 'Cyborg Bot'
		is_ai: true
		color: Color{240, 60, 60, 255}
		angle: 135.0
	}
	t2.inventory[WeaponType.baby_nuke.str()] = 2
	t2.inventory[WeaponType.mirv.str()] = 2
	t2.inventory[WeaponType.napalm.str()] = 1
	g.tanks << t2

	g.generate_terrain()
	g.place_tanks()
	g.randomize_wind()
	g.current_turn = 0
	g.banner_text = 'ROUND 1 - FIRE AT WILL!'
	g.banner_timer = 2.5
}

pub fn (mut g ScorchedGame) generate_terrain() {
	h1 := 0.005 + rand.f64() * 0.005
	h2 := 0.015 + rand.f64() * 0.01
	amp1 := 70.0 + rand.f64() * 50.0
	amp2 := 30.0 + rand.f64() * 30.0
	base_y := 440.0

	for x in 0 .. g.width {
		y := base_y + math.sin(f64(x) * h1) * amp1 + math.sin(f64(x) * h2) * amp2
		g.terrain_y[x] = int(math.clamp(y, 220.0, 580.0))
	}
}

pub fn (mut g ScorchedGame) place_tanks() {
	margin := 100
	spacing := (g.width - margin * 2) / (g.tanks.len)

	for i in 0 .. g.tanks.len {
		tx := margin + i * spacing + rand.int_in_range(0, 40) or { 0 }
		g.tanks[i].x = int(math.clamp(f64(tx), 40.0, f64(g.width - 40)))
		g.tanks[i].y = g.terrain_y[g.tanks[i].x]
		g.tanks[i].health = 100
		g.tanks[i].is_dead = false
	}
}

pub fn (mut g ScorchedGame) randomize_wind() {
	g.wind = (rand.f64() * 2.0 - 1.0) * 75.0
}

pub fn (mut g ScorchedGame) select_weapon(w WeaponType) {
	mut cur_t := g.tanks[g.current_turn]
	if cur_t.is_ai {
		return
	}
	info := get_weapon_info(w)
	if w != .standard && cur_t.inventory[w.str()] <= 0 {
		g.banner_text = 'NO AMMO LEFT FOR ${info.name.to_upper()}!'
		g.banner_timer = 2.0
		return
	}
	cur_t.active_wep = w
	g.tanks[g.current_turn] = cur_t
	ammo_str := if w == .standard { 'INF' } else { '${cur_t.inventory[w.str()]}' }
	g.banner_text = 'ARMED: ${info.name.to_upper()} (AMMO: ${ammo_str})'
	g.banner_timer = 1.5
	g.sound_event = 'select'
}

pub fn (mut g ScorchedGame) cycle_weapon(forward bool) {
	mut cur_t := g.tanks[g.current_turn]
	if cur_t.is_ai {
		return
	}
	all_weps := [
		WeaponType.standard,
		WeaponType.baby_nuke,
		WeaponType.mirv,
		WeaponType.mountain_mover,
		WeaponType.napalm,
		WeaponType.digger,
	]
	mut cur_idx := 0
	for i, w in all_weps {
		if w == cur_t.active_wep {
			cur_idx = i
			break
		}
	}
	step := if forward { 1 } else { all_weps.len - 1 }
	for i in 1 .. all_weps.len + 1 {
		next_idx := (cur_idx + i * step) % all_weps.len
		target_wep := all_weps[next_idx]
		if target_wep == .standard || cur_t.inventory[target_wep.str()] > 0 {
			cur_t.active_wep = target_wep
			g.tanks[g.current_turn] = cur_t
			info := get_weapon_info(target_wep)
			ammo_str := if target_wep == .standard { 'INF' } else { '${cur_t.inventory[target_wep.str()]}' }
			g.banner_text = 'SELECTED: ${info.name.to_upper()} (AMMO: ${ammo_str})'
			g.banner_timer = 1.5
			g.sound_event = 'select'
			return
		}
	}
}

pub fn (mut g ScorchedGame) fire_shot() bool {
	if g.projectiles.len > 0 || g.in_shop || g.is_game_over || g.round_end_timer > 0.0 {
		return false
	}

	mut cur_tank := g.tanks[g.current_turn]
	if cur_tank.is_dead {
		g.advance_turn()
		return false
	}

	fired_wep := cur_tank.active_wep
	if fired_wep != .standard {
		w_name := fired_wep.str()
		if cur_tank.inventory[w_name] <= 0 {
			cur_tank.active_wep = .standard
		} else {
			cur_tank.inventory[w_name]--
		}
	}

	rad := cur_tank.angle * math.pi / 180.0
	spd := cur_tank.power * 0.9
	barrel_len := 22.0
	start_x := f64(cur_tank.x) + math.cos(rad) * barrel_len
	start_y := f64(cur_tank.y - 12) - math.sin(rad) * barrel_len

	g.projectiles << Projectile{
		wtype: fired_wep
		x: start_x
		y: start_y
		vx: math.cos(rad) * spd
		vy: -math.sin(rad) * spd
		owner_id: g.current_turn
		active: true
		split_done: false
		is_drilling: false
		drill_dist: 0.0
		is_napalm: false
		life_time: 0.0
	}

	g.sound_event = match fired_wep {
		.baby_nuke { 'nuke_launch' }
		.digger { 'drill' }
		.napalm { 'napalm' }
		else { 'shot' }
	}
	return true
}

pub fn (mut g ScorchedGame) update(dt f64) {
	if g.banner_timer > 0.0 {
		g.banner_timer -= dt
	}

	// 0. Update Damage Texts
	for i := g.damage_texts.len - 1; i >= 0; i-- {
		mut dt_item := g.damage_texts[i]
		dt_item.life += dt
		dt_item.y -= 25.0 * dt
		if dt_item.life >= 1.5 {
			g.damage_texts.delete(i)
		} else {
			g.damage_texts[i] = dt_item
		}
	}

	// 1. Check Round End Delay
	if g.round_end_timer > 0.0 {
		g.round_end_timer -= dt
		if g.round_end_timer <= 0.0 {
			mut winner_idx := 0
			for i, t in g.tanks {
				if !t.is_dead {
					winner_idx = i
					break
				}
			}

			g.round++
			if g.round > g.max_rounds {
				g.is_game_over = true
				g.banner_text = 'MATCH OVER! ${g.tanks[winner_idx].name.to_upper()} WINS THE WAR!'
				g.banner_timer = 6.0
			} else {
				g.in_shop = true
				g.banner_text = 'ROUND ${g.round - 1} OVER! WEAPONS SHOP OPEN'
				g.banner_timer = 3.5
			}
		}
	}

	// 2. Update Projectiles
	mut any_active_proj := false
	for i := 0; i < g.projectiles.len; i++ {
		if !g.projectiles[i].active {
			continue
		}
		any_active_proj = true
		mut p := g.projectiles[i]
		p.life_time += dt

		if p.is_napalm {
			// Napalm droplet rolling down hill
			px := int(p.x)
			if px >= 1 && px < g.width - 1 {
				slope := f64(g.terrain_y[px + 1] - g.terrain_y[px - 1])
				p.vx += slope * 18.0 * dt
				p.x += p.vx * dt
				p.x = math.clamp(p.x, 2.0, f64(g.width - 2))
				p.y = f64(g.terrain_y[int(p.x)] - 2)

				// Burn ground crater gradually
				cur_px := int(p.x)
				g.terrain_y[cur_px] = int(math.min(f64(g.height - 20), f64(g.terrain_y[cur_px] + 1)))

				// Damage nearby tanks continuously
				for mut t in g.tanks {
					if !t.is_dead && math.abs(f64(t.x) - p.x) <= 20.0 {
						t.health = int(math.max(0.0, f64(t.health) - 35.0 * dt))
						if t.health <= 0 {
							t.is_dead = true
						}
					}
				}
			}
			if p.life_time >= 2.0 {
				p.active = false
			}
			g.projectiles[i] = p
			continue
		}

		if p.is_drilling {
			// Digger Drilling underground
			p.drill_dist += 160.0 * dt
			p.y += 160.0 * dt
			if p.drill_dist >= 75.0 || p.y >= f64(g.height - 30) {
				p.active = false
				g.detonate_projectile(p)
			}
			g.projectiles[i] = p
			continue
		}

		// Standard / Rocket Physics (Wind & Gravity)
		p.vx += g.wind * 1.8 * dt
		p.vy += 380.0 * dt

		p.x += p.vx * dt
		p.y += p.vy * dt

		p.trail << p.x
		p.trail << p.y

		// Check Direct Tank Collision
		mut hit_tank := false
		for ti in 0 .. g.tanks.len {
			if !g.tanks[ti].is_dead && (p.life_time > 0.05 || p.owner_id != ti) {
				dist_t := math.sqrt(f64((g.tanks[ti].x - int(p.x)) * (g.tanks[ti].x - int(p.x)) + (g.tanks[ti].y - 8 - int(p.y)) * (g.tanks[ti].y - 8 - int(p.y))))
				if dist_t <= 20.0 {
					p.active = false
					hit_tank = true
					g.detonate_projectile(p)
					break
				}
			}
		}
		if hit_tank {
			g.projectiles[i] = p
			continue
		}

		// MIRV Split Logic at apex
		if p.wtype == .mirv && !p.split_done && p.vy > 0.0 && p.y < 380.0 {
			p.split_done = true
			g.sound_event = 'mirv_split'
			for sub_i in -2 .. 3 {
				if sub_i != 0 {
					g.projectiles << Projectile{
						wtype: .standard
						x: p.x
						y: p.y
						vx: p.vx + f64(sub_i) * 60.0
						vy: p.vy + rand.f64() * 25.0
						owner_id: p.owner_id
						active: true
						split_done: true
					}
				}
			}
		}

		// Check Terrain Collision
		px := int(p.x)
		py := int(p.y)

		if px >= 0 && px < g.width && py >= g.terrain_y[px] {
			if p.wtype == .digger && !p.is_drilling {
				p.is_drilling = true
				p.vx = 0.0
				p.vy = 160.0
				g.sound_event = 'drill'
			} else {
				p.active = false
				g.detonate_projectile(p)
			}
		} else if px < -100 || px > g.width + 100 || py > g.height + 50 {
			p.active = false
		}

		g.projectiles[i] = p
	}

	// Remove inactive projectiles
	for i := g.projectiles.len - 1; i >= 0; i-- {
		if !g.projectiles[i].active {
			g.projectiles.delete(i)
		}
	}

	// 3. Update Explosions
	for i := g.explosions.len - 1; i >= 0; i-- {
		mut expl := g.explosions[i]
		expl.life += dt
		expl.radius = expl.max_r * math.sin(math.pi * (expl.life / expl.max_l))
		if expl.life >= expl.max_l {
			g.explosions.delete(i)
		} else {
			g.explosions[i] = expl
		}
	}

	// 4. Tank Gravity & Settlement
	for mut t in g.tanks {
		if !t.is_dead {
			ground_y := g.terrain_y[t.x]
			if t.y < ground_y {
				t.y += int(math.min(f64(ground_y - t.y), 300.0 * dt))
			} else if t.y > ground_y {
				t.y = ground_y
			}
		}
	}

	// 5. AI Turn Decision
	if !any_active_proj && g.explosions.len == 0 && !g.is_game_over && !g.in_shop && g.round_end_timer <= 0.0 {
		cur_tank := g.tanks[g.current_turn]
		if cur_tank.is_ai && !cur_tank.is_dead {
			g.ai_think_timer += dt
			if g.ai_think_timer >= 1.0 {
				g.ai_think_timer = 0.0
				g.execute_ai_turn()
			}
		}
	}
}

fn (mut g ScorchedGame) detonate_projectile(p Projectile) {
	info := get_weapon_info(p.wtype)
	cx := int(p.x)
	cy := int(p.y)

	g.sound_event = if p.wtype == .baby_nuke { 'nuke_detonate' } else { 'explosion' }

	// Spawn Visual Explosion
	g.explosions << Explosion{
		x: p.x
		y: p.y
		radius: 0.0
		max_r: f64(info.radius)
		life: 0.0
		max_l: if p.wtype == .baby_nuke { 0.70 } else { 0.45 }
		is_nuke: p.wtype == .baby_nuke
		col: if p.wtype == .baby_nuke { Color{255, 220, 50, 255} } else { Color{255, 110, 30, 255} }
	}

	// Unique Weapon Mechanics
	if p.wtype == .mountain_mover {
		g.sound_event = 'dirt'
		for dx := -info.radius; dx <= info.radius; dx++ {
			tx := cx + dx
			if tx >= 0 && tx < g.width {
				lift := int(math.sqrt(f64(info.radius * info.radius - dx * dx)))
				g.terrain_y[tx] = int(math.max(100.0, f64(g.terrain_y[tx] - lift)))
			}
		}
	} else if p.wtype == .napalm {
		g.sound_event = 'napalm'
		for _ in 0 .. 8 {
			offset_x := (rand.f64() * 2.0 - 1.0) * 20.0
			g.projectiles << Projectile{
				wtype: .napalm
				x: f64(cx) + offset_x
				y: f64(cy)
				vx: (rand.f64() * 2.0 - 1.0) * 40.0
				vy: 0.0
				owner_id: p.owner_id
				active: true
				is_napalm: true
				life_time: 0.0
			}
		}
	} else {
		// Excavation Crater
		for dx := -info.radius; dx <= info.radius; dx++ {
			tx := cx + dx
			if tx >= 0 && tx < g.width {
				depth := int(math.sqrt(f64(info.radius * info.radius - dx * dx)))
				if cy + depth > g.terrain_y[tx] {
					g.terrain_y[tx] = int(math.min(f64(g.height - 20), f64(g.terrain_y[tx] + depth)))
				}
			}
		}
	}

	// Apply Damage to Nearby Tanks
	for ti := 0; ti < g.tanks.len; ti++ {
		if g.tanks[ti].is_dead {
			continue
		}
		dist := math.sqrt(f64((g.tanks[ti].x - cx) * (g.tanks[ti].x - cx) + (g.tanks[ti].y - 8 - cy) * (g.tanks[ti].y - 8 - cy)))
		max_dist := f64(info.radius + 24)
		if dist <= max_dist {
			factor := math.max(0.3, 1.0 - (dist / max_dist))
			dmg := if dist <= 20.0 { info.damage } else { int(f64(info.damage) * factor) }

			g.tanks[ti].health -= dmg
			if p.owner_id < g.tanks.len {
				g.tanks[p.owner_id].cash += dmg * 10
			}

			is_direct := dist <= 20.0
			dmg_str := if is_direct { 'DIRECT HIT! -${dmg} HP' } else { '-${dmg} HP' }
			g.damage_texts << DamageText{
				x: f64(g.tanks[ti].x)
				y: f64(g.tanks[ti].y - 30)
				text: dmg_str
				col: if is_direct { Color{255, 220, 0, 255} } else { Color{255, 100, 80, 255} }
				life: 0.0
			}

			if g.tanks[ti].health <= 0 {
				g.tanks[ti].health = 0
				g.tanks[ti].is_dead = true
				if p.owner_id < g.tanks.len {
					g.tanks[p.owner_id].kills++
					g.tanks[p.owner_id].cash += 500
				}
				g.banner_text = '${g.tanks[ti].name.to_upper()} WAS DESTROYED!'
				g.banner_timer = 3.0

				g.explosions << Explosion{
					x: f64(g.tanks[ti].x)
					y: f64(g.tanks[ti].y - 8)
					radius: 0.0
					max_r: 55.0
					life: 0.0
					max_l: 0.65
					is_nuke: true
					col: Color{255, 50, 30, 255}
				}
			}
		}
	}

	g.advance_turn()
}

fn (mut g ScorchedGame) advance_turn() {
	mut alive_count := 0
	for _, t in g.tanks {
		if !t.is_dead {
			alive_count++
		}
	}

	if alive_count <= 1 {
		if g.round_end_timer <= 0.0 {
			g.round_end_timer = 2.0
		}
		return
	}

	for _ in 0 .. g.tanks.len {
		g.current_turn = (g.current_turn + 1) % g.tanks.len
		if !g.tanks[g.current_turn].is_dead {
			break
		}
	}

	g.randomize_wind()
	p_name := g.tanks[g.current_turn].name
	g.banner_text = "${p_name.to_upper()}'S TURN"
	g.banner_timer = 1.8
}

fn (mut g ScorchedGame) execute_ai_turn() {
	mut me := g.tanks[g.current_turn]
	mut target_x := 0
	for i, t in g.tanks {
		if i != g.current_turn && !t.is_dead {
			target_x = t.x
			break
		}
	}

	dx := f64(target_x - me.x)
	if dx > 0 {
		me.angle = 45.0 - (g.wind * 0.15)
	} else {
		me.angle = 135.0 - (g.wind * 0.15)
	}
	me.angle = math.clamp(me.angle, 10.0, 170.0)

	dist := math.abs(dx)
	me.power = math.clamp(dist * 1.2 + rand.f64() * 40.0 - 20.0, 200.0, 950.0)

	if me.inventory[WeaponType.baby_nuke.str()] > 0 {
		me.active_wep = .baby_nuke
	} else if me.inventory[WeaponType.mirv.str()] > 0 {
		me.active_wep = .mirv
	} else if me.inventory[WeaponType.napalm.str()] > 0 {
		me.active_wep = .napalm
	} else {
		me.active_wep = .standard
	}

	g.tanks[g.current_turn] = me
	g.fire_shot()
}

pub fn (mut g ScorchedGame) buy_weapon(w WeaponType) bool {
	info := get_weapon_info(w)
	if g.tanks[0].cash >= info.cost {
		g.tanks[0].cash -= info.cost
		g.tanks[0].inventory[w.str()]++
		g.sound_event = 'cash'
		g.banner_text = 'BOUGHT ${info.name.to_upper()}! (OWNED: ${g.tanks[0].inventory[w.str()]})'
		g.banner_timer = 2.0
		return true
	} else {
		g.banner_text = 'NOT ENOUGH CASH TO BUY ${info.name.to_upper()} (COST: $${info.cost})'
		g.banner_timer = 2.0
		return false
	}
}

pub fn (mut g ScorchedGame) start_next_round() {
	g.in_shop = false
	g.generate_terrain()
	g.place_tanks()
	g.randomize_wind()
	g.current_turn = 0
	g.banner_text = 'ROUND ${g.round} - COMMENCE FIRING!'
	g.banner_timer = 2.5
}
