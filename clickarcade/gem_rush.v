module main

import math
import rand

pub struct Building {
pub:
	id          int
	name        string
	base_cost   f64
	base_cps    f64
	desc        string
pub mut:
	count       int
}

pub struct Upgrade {
pub:
	id          int
	name        string
	cost        f64
	desc        string
	effect_type string // "click_mult", "cps_mult", "frenzy_boost"
	multiplier  f64
pub mut:
	purchased   bool
}

pub struct FloatingText {
pub mut:
	x        f64
	y        f64
	text     string
	color    Color
	life     f64
	max_life f64
	scale    int
	vy       f64
}

pub struct Particle {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	color    Color
	size     f64
	life     f64
	max_life f64
}

pub struct GoldenGem {
pub mut:
	active   bool
	x        f64
	y        f64
	vx       f64
	vy       f64
	radius   f64
	life     f64
	is_frenzy bool
}

pub struct GemRushGame {
pub mut:
	gems             f64
	total_gems_earned f64
	prestige_shards  int
	click_power_base f64 = 1.0

	// Combo system
	combo_meter      f64
	combo_multiplier f64 = 1.0
	combo_level      int = 1

	// Frenzy mode
	frenzy_timer     f64
	is_frenzy        bool

	// Gem animation
	gem_scale        f64 = 1.0
	gem_target_scale f64 = 1.0
	gem_rotation     f64

	// Golden spawns
	golden_gem       GoldenGem
	spawn_timer      f64

	// Buildings & Upgrades
	buildings        []Building
	upgrades         []Upgrade

	// Visuals
	floating_texts   []FloatingText
	particles        []Particle

	// Stats
	total_clicks     int
	golden_clicked   int
}

pub fn new_gem_rush_game() GemRushGame {
	mut b := []Building{}
	b << Building{ id: 0, name: 'Pickaxe', base_cost: 15.0, base_cps: 0.5, desc: '+0.5 gems/sec' }
	b << Building{ id: 1, name: 'Miner Dwarf', base_cost: 100.0, base_cps: 4.0, desc: '+4 gems/sec' }
	b << Building{ id: 2, name: 'Steam Drill', base_cost: 1100.0, base_cps: 32.0, desc: '+32 gems/sec' }
	b << Building{ id: 3, name: 'Laser Bore', base_cost: 12000.0, base_cps: 260.0, desc: '+260 gems/sec' }
	b << Building{ id: 4, name: 'Quantum Core', base_cost: 130000.0, base_cps: 1400.0, desc: '+1.4k gems/sec' }
	b << Building{ id: 5, name: 'Cosmic Forge', base_cost: 1400000.0, base_cps: 7800.0, desc: '+7.8k gems/sec' }

	mut u := []Upgrade{}
	u << Upgrade{ id: 0, name: 'Hardened Tips', cost: 100.0, desc: 'Clicking is 2x stronger', effect_type: 'click_mult', multiplier: 2.0 }
	u << Upgrade{ id: 1, name: 'Reinforced Drill', cost: 500.0, desc: 'All CPS +50%', effect_type: 'cps_mult', multiplier: 1.5 }
	u << Upgrade{ id: 2, name: 'Diamond Edge', cost: 2500.0, desc: 'Clicking is 2.5x stronger', effect_type: 'click_mult', multiplier: 2.5 }
	u << Upgrade{ id: 3, name: 'Overclocked Motors', cost: 15000.0, desc: 'All CPS x2.0', effect_type: 'cps_mult', multiplier: 2.0 }
	u << Upgrade{ id: 4, name: 'Lucky Sparkles', cost: 50000.0, desc: 'Golden Gems appear 2x more', effect_type: 'frenzy_boost', multiplier: 2.0 }
	u << Upgrade{ id: 5, name: 'Supernova Fusion', cost: 500000.0, desc: 'All yields x3.0', effect_type: 'cps_mult', multiplier: 3.0 }

	return GemRushGame{
		gems: 0.0
		buildings: b
		upgrades: u
		spawn_timer: 15.0
	}
}

pub fn (g &GemRushGame) get_building_cost(b &Building) f64 {
	return b.base_cost * math.pow(1.15, f64(b.count))
}

pub fn (g &GemRushGame) get_click_power() f64 {
	mut mult := 1.0
	for up in g.upgrades {
		if up.purchased && up.effect_type == 'click_mult' {
			mult *= up.multiplier
		}
	}
	frenzy_mult := if g.is_frenzy { 7.0 } else { 1.0 }
	prestige_mult := 1.0 + f64(g.prestige_shards) * 0.1
	return g.click_power_base * mult * g.combo_multiplier * frenzy_mult * prestige_mult
}

pub fn (g &GemRushGame) get_total_cps() f64 {
	mut cps := 0.0
	for b in g.buildings {
		cps += f64(b.count) * b.base_cps
	}
	mut mult := 1.0
	for up in g.upgrades {
		if up.purchased && up.effect_type == 'cps_mult' {
			mult *= up.multiplier
		}
	}
	frenzy_mult := if g.is_frenzy { 7.0 } else { 1.0 }
	prestige_mult := 1.0 + f64(g.prestige_shards) * 0.1
	return cps * mult * frenzy_mult * prestige_mult
}

pub fn (mut g GemRushGame) click_gem(x f64, y f64, mut sm SoundManager) {
	g.total_clicks++
	power := g.get_click_power()
	g.gems += power
	g.total_gems_earned += power

	// Squash effect
	g.gem_scale = 0.82
	g.gem_rotation += (rand.f64() - 0.5) * 0.15

	// Combo build
	g.combo_meter = math.min(g.combo_meter + 0.22, 1.0)
	if g.combo_meter >= 0.8 {
		g.combo_multiplier = 4.0
		g.combo_level = 4
	} else if g.combo_meter >= 0.5 {
		g.combo_multiplier = 3.0
		g.combo_level = 3
	} else if g.combo_meter >= 0.25 {
		g.combo_multiplier = 2.0
		g.combo_level = 2
	} else {
		g.combo_multiplier = 1.0
		g.combo_level = 1
	}

	sm.play_gem_tap(g.combo_level)

	// Floating text
	text := if power >= 1000.0 {
		'+${int(power)}'
	} else if power >= 10.0 {
		'+${power:.1f}'
	} else {
		'+${power:.0f}'
	}

	color := if g.is_frenzy {
		col_gold
	} else if g.combo_level >= 3 {
		col_cyan
	} else {
		col_yellow
	}

	g.floating_texts << FloatingText{
		x: x + (rand.f64() - 0.5) * 40.0
		y: y - 20.0
		text: text
		color: color
		life: 0.8
		max_life: 0.8
		scale: if g.combo_level >= 3 || g.is_frenzy { 2 } else { 1 }
		vy: -60.0 - rand.f64() * 30.0
	}

	// Sparkle particles
	p_count := if g.is_frenzy { 14 } else { 6 }
	for _ in 0 .. p_count {
		ang := rand.f64() * math.pi * 2.0
		spd := 60.0 + rand.f64() * 120.0
		p_col := if g.is_frenzy { col_gold } else if rand.f64() > 0.5 { col_cyan } else { col_pink }
		g.particles << Particle{
			x: x
			y: y
			vx: math.cos(ang) * spd
			vy: math.sin(ang) * spd
			color: p_col
			size: 3.0 + rand.f64() * 3.0
			life: 0.5 + rand.f64() * 0.3
			max_life: 0.8
		}
	}
}

pub fn (mut g GemRushGame) click_golden_gem(mut sm SoundManager) {
	if !g.golden_gem.active {
		return
	}
	g.golden_gem.active = false
	g.golden_clicked++

	if g.golden_gem.is_frenzy {
		g.is_frenzy = true
		g.frenzy_timer = 12.0
		sm.play_golden_frenzy()
		g.floating_texts << FloatingText{
			x: g.golden_gem.x
			y: g.golden_gem.y
			text: '7x FRENZY RUSH!'
			color: col_gold
			life: 1.5
			max_life: 1.5
			scale: 2
			vy: -80.0
		}
	} else {
		// Massive gem bounty: 15% of total or 60s of CPS
		reward := math.max(g.get_total_cps() * 60.0, 50.0) * (1.0 + f64(g.prestige_shards) * 0.2)
		g.gems += reward
		g.total_gems_earned += reward
		sm.play_upgrade_bought()
		g.floating_texts << FloatingText{
			x: g.golden_gem.x
			y: g.golden_gem.y
			text: '+${int(reward)} MEGA LOOT!'
			color: col_gold
			life: 1.5
			max_life: 1.5
			scale: 2
			vy: -80.0
		}
	}

	// Gold starburst particles
	for _ in 0 .. 25 {
		ang := rand.f64() * math.pi * 2.0
		spd := 100.0 + rand.f64() * 160.0
		g.particles << Particle{
			x: g.golden_gem.x
			y: g.golden_gem.y
			vx: math.cos(ang) * spd
			vy: math.sin(ang) * spd
			color: col_gold
			size: 4.0 + rand.f64() * 4.0
			life: 0.7 + rand.f64() * 0.4
			max_life: 1.1
		}
	}
}

pub fn (mut g GemRushGame) buy_building(idx int, mut sm SoundManager) bool {
	if idx < 0 || idx >= g.buildings.len {
		return false
	}
	cost := g.get_building_cost(&g.buildings[idx])
	if g.gems >= cost {
		g.gems -= cost
		g.buildings[idx].count++
		sm.play_upgrade_bought()
		return true
	}
	return false
}

pub fn (mut g GemRushGame) buy_upgrade(idx int, mut sm SoundManager) bool {
	if idx < 0 || idx >= g.upgrades.len {
		return false
	}
	if g.upgrades[idx].purchased {
		return false
	}
	cost := g.upgrades[idx].cost
	if g.gems >= cost {
		g.gems -= cost
		g.upgrades[idx].purchased = true
		sm.play_upgrade_bought()
		return true
	}
	return false
}

pub fn (g &GemRushGame) can_ascend() bool {
	return g.total_gems_earned >= 100000.0
}

pub fn (mut g GemRushGame) ascend(mut sm SoundManager) {
	if !g.can_ascend() {
		return
	}
	new_shards := int(math.sqrt(g.total_gems_earned / 10000.0))
	g.prestige_shards += new_shards
	g.gems = 0.0
	g.total_gems_earned = 0.0

	// Reset buildings
	for mut b in g.buildings {
		b.count = 0
	}
	// Reset upgrades
	for mut u in g.upgrades {
		u.purchased = false
	}

	sm.play_victory()
}

pub fn (mut g GemRushGame) update(dt f64) {
	// Add CPS
	cps := g.get_total_cps()
	earned := cps * dt
	g.gems += earned
	g.total_gems_earned += earned

	// Combo decay
	if g.combo_meter > 0.0 {
		g.combo_meter = math.max(0.0, g.combo_meter - dt * 0.35)
		if g.combo_meter < 0.25 {
			g.combo_multiplier = 1.0
			g.combo_level = 1
		} else if g.combo_meter < 0.5 {
			g.combo_multiplier = 2.0
			g.combo_level = 2
		} else if g.combo_meter < 0.8 {
			g.combo_multiplier = 3.0
			g.combo_level = 3
		}
	}

	// Frenzy timer
	if g.is_frenzy {
		g.frenzy_timer -= dt
		if g.frenzy_timer <= 0.0 {
			g.is_frenzy = false
			g.frenzy_timer = 0.0
		}
	}

	// Gem visual spring scale
	g.gem_scale += (g.gem_target_scale - g.gem_scale) * dt * 14.0
	g.gem_rotation += (0.0 - g.gem_rotation) * dt * 8.0

	// Golden Gem Spawning
	g.spawn_timer -= dt
	if g.spawn_timer <= 0.0 && !g.golden_gem.active {
		g.spawn_timer = 18.0 + rand.f64() * 12.0
		g.golden_gem = GoldenGem{
			active: true
			x: 60.0 + rand.f64() * 320.0
			y: 60.0 + rand.f64() * 400.0
			vx: (rand.f64() - 0.5) * 45.0
			vy: (rand.f64() - 0.5) * 45.0
			radius: 20.0
			life: 8.0
			is_frenzy: rand.f64() > 0.4
		}
	}

	if g.golden_gem.active {
		g.golden_gem.life -= dt
		g.golden_gem.x += g.golden_gem.vx * dt
		g.golden_gem.y += g.golden_gem.vy * dt
		if g.golden_gem.x < 50.0 || g.golden_gem.x > 450.0 {
			g.golden_gem.vx = -g.golden_gem.vx
		}
		if g.golden_gem.y < 50.0 || g.golden_gem.y > 520.0 {
			g.golden_gem.vy = -g.golden_gem.vy
		}
		if g.golden_gem.life <= 0.0 {
			g.golden_gem.active = false
		}
	}

	// Update floating texts
	mut keep_texts := []FloatingText{}
	for mut ft in g.floating_texts {
		ft.life -= dt
		ft.y += ft.vy * dt
		if ft.life > 0.0 {
			keep_texts << ft
		}
	}
	g.floating_texts = keep_texts

	// Update particles
	mut keep_p := []Particle{}
	for mut p in g.particles {
		p.life -= dt
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 60.0 * dt // subtle gravity
		if p.life > 0.0 {
			keep_p << p
		}
	}
	g.particles = keep_p
}
