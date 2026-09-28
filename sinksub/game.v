module main

import math
import rand
import os



const ocean_width = 1000
const ocean_height = 760
const water_level_y = 200

struct RankInfo {
pub:
	score int
	title string
	badge string
}

const navy_ranks = [
	RankInfo{
		score: 0
		title: 'SAILOR BOY'
		badge: '⚓'
	},
	RankInfo{
		score: 300
		title: 'CADET RECRUIT'
		badge: 'M'
	},
	RankInfo{
		score: 700
		title: 'PETTY OFFICER'
		badge: 'P'
	},
	RankInfo{
		score: 1200
		title: 'CHIEF CONSTABLE'
		badge: 'C'
	},
	RankInfo{
		score: 1800
		title: 'ENSIGN'
		badge: 'E'
	},
	RankInfo{
		score: 2500
		title: 'SUB-LIEUTENANT'
		badge: 'S'
	},
	RankInfo{
		score: 3500
		title: 'LIEUTENANT'
		badge: 'L'
	},
	RankInfo{
		score: 4800
		title: 'COMMANDER'
		badge: 'X'
	},
	RankInfo{
		score: 6200
		title: 'CAPTAIN'
		badge: 'K'
	},
	RankInfo{
		score: 8000
		title: 'COMMODORE'
		badge: 'O'
	},
	RankInfo{
		score: 10000
		title: 'REAR ADMIRAL'
		badge: 'R'
	},
	RankInfo{
		score: 12500
		title: 'VICE ADMIRAL'
		badge: 'V'
	},
	RankInfo{
		score: 15000
		title: 'ADMIRAL'
		badge: 'A'
	},
	RankInfo{
		score: 20000
		title: 'GRAND ADMIRAL'
		badge: 'G'
	},
]

enum SubType {
	standard
	fast
	heavy
	boss
}

struct SubSpecs {
pub:
	color     Color
	points    int
	min_speed f64
	max_speed f64
	max_hp    int
	fire_prob f64
	scale     f64
}

fn get_sub_specs(kind SubType) SubSpecs {
	match kind {
		.standard {
			return SubSpecs{
				color:     Color{
					r: 100
					g: 116
					b: 139
				}
				points:    100
				min_speed: 0.8
				max_speed: 1.5
				max_hp:    1
				fire_prob: 0.004
				scale:     0.85
			}
		}
		.fast {
			return SubSpecs{
				color:     Color{
					r: 6
					g: 182
					b: 212
				}
				points:    200
				min_speed: 1.6
				max_speed: 2.8
				max_hp:    1
				fire_prob: 0.007
				scale:     0.75
			}
		}
		.heavy {
			return SubSpecs{
				color:     Color{
					r: 245
					g: 158
					b: 11
				}
				points:    350
				min_speed: 0.6
				max_speed: 1.1
				max_hp:    2
				fire_prob: 0.006
				scale:     1.15
			}
		}
		.boss {
			return SubSpecs{
				color:     Color{
					r: 217
					g: 70
					b: 239
				}
				points:    600
				min_speed: 0.5
				max_speed: 0.9
				max_hp:    3
				fire_prob: 0.010
				scale:     1.35
			}
		}
	}
}

struct Ship {
pub mut:
	x         f64
	y         f64
	w         f64 = 84.0
	h         f64 = 28.0
	speed     f64
	max_speed f64 = 4.8
	accel     f64 = 0.3
	friction  f64 = 0.12
	dir       int = 1
}

struct DepthCharge {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	gravity  f64 = 0.06
	damage   int = 1
	is_stern bool
}

struct Submarine {
pub mut:
	kind      SubType
	x         f64
	y         f64
	w         f64
	h         f64
	speed     f64
	hp        int
	max_hp    int
	points    int
	fire_prob f64
	color     Color
}

struct Torpedo {
pub mut:
	x     f64
	y     f64
	vx    f64
	speed f64
}

struct Mine {
pub mut:
	x      f64
	y      f64
	speed  f64
	wobble f64
}

enum CrateType {
	shield
	triple
	hyper
	nuke
}

struct Crate {
pub mut:
	x    f64
	y    f64
	vy   f64 = 1.2
	kind CrateType
}

struct Upgrades {
pub mut:
	engine int = 1 // Speed multiplier
	loader int = 1 // Cooldown reduction
	hull   int = 3 // Max Lives
	blast  int = 1 // Blast radius
}

struct Perks {
pub mut:
	shield     int // frames remaining
	triple     int
	hyper_load int
	nuke       int = 1 // charges count
}

enum GameStateMode {
	menu
	playing
	shop
	game_over
}

pub struct DestroyedSubEvent {
pub:
	x      f64
	y      f64
	w      f64
	h      f64
	kind   SubType
	points int
}

pub struct SinkSubEvents {
pub mut:
	subs_destroyed []DestroyedSubEvent
	boat_hit       bool
	boat_hit_x     f64
	boat_hit_y     f64
	charge_hit     bool
	charge_hit_x   f64
	charge_hit_y   f64
	powerup_got    bool
	exploded       bool
}

struct GameEngine {
pub mut:
	mode          GameStateMode = .menu
	score         int
	high_score    int
	credits       int
	sector        int = 1
	target_killed int
	req_to_clear  int    = 3
	lives         int    = 3
	difficulty    string = 'normal'
	ship          Ship
	charges       []DepthCharge
	subs          []Submarine
	torpedoes     []Torpedo
	mines         []Mine
	crates        []Crate
	upgrades      Upgrades
	perks         Perks
	cd_stern      u32
	cd_bow        u32
	cd_duration   u32 = 800
	crate_timer   int = 300
	combo         int
	combo_timer   int
	current_rank  RankInfo
	last_events   SinkSubEvents
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut g GameEngine) init_textures(renderer &Renderer) {
	paths := [
		'assets/sprites/sinksub.png',
		'./assets/sprites/sinksub.png',
		'../assets/sprites/sinksub.png',
		'sinksub/assets/sprites/sinksub.png',
	]
	for p in paths {
		if os.exists(p) {
			g.sprite_texture = load_texture(renderer.ctx, p)
			if g.sprite_texture != unsafe { nil } && g.sprite_texture.valid {
				println('sinksub Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn new_game_engine() GameEngine {
	mut g := GameEngine{
		ship:         Ship{
			x: f64(ocean_width / 2)
			y: f64(water_level_y - 24)
		}
		current_rank: navy_ranks[0]
	}
	return g
}

fn (mut g GameEngine) update_rank() bool {
	mut active := navy_ranks[0]
	for r in navy_ranks {
		if g.score >= r.score {
			active = r
		}
	}
	if active.title != g.current_rank.title {
		g.current_rank = active
		return true // Promoted!
	}
	return false
}

fn (mut g GameEngine) start_new_game() {
	g.score = 0
	g.credits = 0
	g.sector = 1
	g.upgrades = Upgrades{}
	g.perks = Perks{
		nuke: 1
	}
	g.lives = g.upgrades.hull
	g.current_rank = navy_ranks[0]
	g.start_sector(1)
	g.mode = .playing
}

fn (mut g GameEngine) start_sector(sec int) {
	g.sector = sec
	g.target_killed = 0
	g.req_to_clear = 3 + (sec * 2)
	g.subs.clear()
	g.charges.clear()
	g.mines.clear()
	g.torpedoes.clear()
	g.crates.clear()

	count := math.min(6, 3 + (sec / 2))
	for _ in 0 .. count {
		g.spawn_sub()
	}
}

fn (mut g GameEngine) spawn_sub() {
	mut kind := SubType.standard
	r := rand.f64()
	if g.sector >= 2 && r > 0.55 {
		kind = .fast
	}
	if g.sector >= 4 && r > 0.78 {
		kind = .heavy
	}
	if g.sector >= 6 && r > 0.92 {
		kind = .boss
	}

	specs := get_sub_specs(kind)
	w := 64.0 * specs.scale
	h := 22.0 * specs.scale
	dir := if rand.f64() > 0.5 { 1.0 } else { -1.0 }

	min_y := f64(water_level_y + 60)
	max_y := f64(ocean_height - 90)
	target_y := min_y + rand.f64() * (max_y - min_y)

	speed := specs.min_speed + rand.f64() * (specs.max_speed - specs.min_speed)
	diff_mult := if g.difficulty == 'easy' {
		0.7
	} else if g.difficulty == 'hard' {
		1.35
	} else {
		1.0
	}

	g.subs << Submarine{
		kind:      kind
		x:         if dir == 1.0 { -w } else { f64(ocean_width) + w }
		y:         target_y
		w:         w
		h:         h
		speed:     speed * dir * diff_mult
		hp:        specs.max_hp
		max_hp:    specs.max_hp
		points:    specs.points
		fire_prob: specs.fire_prob * (f64(g.sector) * 0.12 + 1.0)
		color:     specs.color
	}
}

fn (mut g GameEngine) drop_stern_charge(now u32) bool {
	mut mod_cd := u32(f64(g.cd_duration) * math.pow(0.85, f64(g.upgrades.loader - 1)))
	if g.perks.hyper_load > 0 {
		mod_cd = 80
	}
	if now - g.cd_stern < mod_cd {
		return false
	}
	g.cd_stern = now

	sx := g.ship.x - g.ship.w / 2.0
	sy := g.ship.y + g.ship.h / 2.0

	if g.perks.triple > 0 {
		for offset in -1 .. 2 {
			g.charges << DepthCharge{
				x:        sx + f64(offset * 12)
				y:        sy
				vx:       (g.ship.speed * 0.25 - 0.4) + f64(offset) * 0.8
				vy:       1.0
				is_stern: true
			}
		}
	} else {
		g.charges << DepthCharge{
			x:        sx
			y:        sy
			vx:       g.ship.speed * 0.25 - 0.4
			vy:       1.0
			is_stern: true
		}
	}
	return true
}

fn (mut g GameEngine) throw_bow_charge(now u32) bool {
	mut mod_cd := u32(f64(g.cd_duration) * math.pow(0.85, f64(g.upgrades.loader - 1)))
	if g.perks.hyper_load > 0 {
		mod_cd = 80
	}
	if now - g.cd_bow < mod_cd {
		return false
	}
	g.cd_bow = now

	sx := g.ship.x + g.ship.w / 2.0
	sy := g.ship.y

	if g.perks.triple > 0 {
		for offset in -1 .. 2 {
			g.charges << DepthCharge{
				x:        sx
				y:        sy
				vx:       (3.8 + g.ship.speed * 0.55) + f64(offset) * 0.5
				vy:       -5.0 + f64(offset) * 0.6
				gravity:  0.19
				is_stern: false
			}
		}
	} else {
		g.charges << DepthCharge{
			x:        sx
			y:        sy
			vx:       3.8 + g.ship.speed * 0.55
			vy:       -5.0
			gravity:  0.19
			is_stern: false
		}
	}
	return true
}

fn (mut g GameEngine) trigger_nuke() bool {
	if g.perks.nuke <= 0 {
		return false
	}
	g.perks.nuke--

	// Clear mines & torpedoes
	g.mines.clear()
	g.torpedoes.clear()

	// Blast subs
	for i in 0 .. g.subs.len {
		g.subs[i].hp -= 3
	}

	mut surviving := []Submarine{}
	for sub in g.subs {
		if sub.hp <= 0 {
			g.score += sub.points
			g.credits += sub.points
			g.target_killed++
		} else {
			surviving << sub
		}
	}
	g.subs = surviving

	for g.subs.len < math.min(6, 3 + (g.sector / 2)) {
		g.spawn_sub()
	}

	if g.score > g.high_score {
		g.high_score = g.score
	}

	g.update_rank()

	if g.target_killed >= g.req_to_clear {
		g.mode = .shop
	}
	return true
}

fn (mut g GameEngine) update_step(move_left bool, move_right bool) (bool, bool, bool) { // returns (launched_sound, explosion_sound, powerup_sound)
	g.last_events = SinkSubEvents{}
	if g.mode != .playing {
		return false, false, false
	}

	mut exploded := false
	mut powerup_got := false

	// Ship Physics
	max_sp := g.ship.max_speed * (1.0 + f64(g.upgrades.engine - 1) * 0.15)
	acc := g.ship.accel * (1.0 + f64(g.upgrades.engine - 1) * 0.1)

	if move_left {
		g.ship.speed -= acc
		g.ship.dir = -1
	} else if move_right {
		g.ship.speed += acc
		g.ship.dir = 1
	} else {
		if g.ship.speed > 0 {
			g.ship.speed = math.max(0.0, g.ship.speed - g.ship.friction)
		}
		if g.ship.speed < 0 {
			g.ship.speed = math.min(0.0, g.ship.speed + g.ship.friction)
		}
	}

	g.ship.speed = math.max(-max_sp, math.min(max_sp, g.ship.speed))
	g.ship.x += g.ship.speed

	if g.ship.x < g.ship.w / 2.0 {
		g.ship.x = g.ship.w / 2.0
		g.ship.speed = 0
	}
	if g.ship.x > f64(ocean_width) - g.ship.w / 2.0 {
		g.ship.x = f64(ocean_width) - g.ship.w / 2.0
		g.ship.speed = 0
	}

	// Update Perks timers
	if g.perks.shield > 0 {
		g.perks.shield--
	}
	if g.perks.triple > 0 {
		g.perks.triple--
	}
	if g.perks.hyper_load > 0 {
		g.perks.hyper_load--
	}

	// Update Crates
	g.crate_timer--
	if g.crate_timer <= 0 {
		g.crate_timer = 300 + rand.intn(200) or { 200 }
		cr_types := [CrateType.shield, CrateType.triple, CrateType.hyper, CrateType.nuke]
		ch_type := cr_types[rand.intn(cr_types.len) or { 0 }]
		g.crates << Crate{
			x:    40.0 + rand.f64() * f64(ocean_width - 80)
			y:    -10.0
			kind: ch_type
		}
	}

	for i := g.crates.len - 1; i >= 0; i-- {
		g.crates[i].y += g.crates[i].vy
		if g.crates[i].y >= f64(water_level_y - 5) {
			g.crates[i].y = f64(water_level_y - 5)
		}
		// Collection check
		dist := math.abs(g.ship.x - g.crates[i].x)
		if g.crates[i].y >= f64(water_level_y - 15) && dist < g.ship.w / 2.0 + 15.0 {
			match g.crates[i].kind {
				.shield { g.perks.shield = 480 }
				.triple { g.perks.triple = 480 }
				.hyper { g.perks.hyper_load = 300 }
				.nuke { g.perks.nuke++ }
			}
			g.crates.delete(i)
			powerup_got = true
			g.last_events.powerup_got = true
		}
	}

	// Depth Charges update & collision
	for i := g.charges.len - 1; i >= 0; i-- {
		g.charges[i].x += g.charges[i].vx
		g.charges[i].y += g.charges[i].vy

		if g.charges[i].y >= f64(water_level_y) {
			g.charges[i].vy = math.min(2.8, g.charges[i].vy + g.charges[i].gravity)
		} else {
			g.charges[i].vy += g.charges[i].gravity
		}

		if g.charges[i].y > f64(ocean_height - 40) || g.charges[i].x < 0
			|| g.charges[i].x > f64(ocean_width) {
			g.charges.delete(i)
			continue
		}

		// Check collision against Subs
		if g.charges[i].y >= f64(water_level_y) {
			mut hit_sub := false
			for j := g.subs.len - 1; j >= 0; j-- {
				sub := g.subs[j]
				if g.charges[i].x >= sub.x && g.charges[i].x <= sub.x + sub.w {
					if g.charges[i].y >= sub.y && g.charges[i].y <= sub.y + sub.h {
						g.subs[j].hp -= g.charges[i].damage
						hit_sub = true
						exploded = true
						g.last_events.exploded = true
						g.last_events.charge_hit = true
						g.last_events.charge_hit_x = g.charges[i].x
						g.last_events.charge_hit_y = g.charges[i].y

						if g.subs[j].hp <= 0 {
							g.score += sub.points
							g.credits += sub.points
							g.target_killed++
							g.last_events.subs_destroyed << DestroyedSubEvent{
								x: sub.x
								y: sub.y
								w: sub.w
								h: sub.h
								kind: sub.kind
								points: sub.points
							}
							g.subs.delete(j)
							g.spawn_sub()
						}
						break
					}
				}
			}
			if hit_sub {
				g.charges.delete(i)
				continue
			}
		}
	}

	// Subs update & firing
	for i := 0; i < g.subs.len; i++ {
		g.subs[i].x += g.subs[i].speed
		if g.subs[i].speed > 0 && g.subs[i].x > f64(ocean_width + 100) {
			g.subs[i].x = -g.subs[i].w
		} else if g.subs[i].speed < 0 && g.subs[i].x < -g.subs[i].w - 100.0 {
			g.subs[i].x = f64(ocean_width + 100)
		}

		if rand.f64() < g.subs[i].fire_prob {
			if rand.f64() < 0.4 && g.sector >= 2 {
				g.torpedoes << Torpedo{
					x:     g.subs[i].x + g.subs[i].w / 2.0
					y:     g.subs[i].y
					speed: 1.5 + f64(g.sector) * 0.08
				}
			} else {
				g.mines << Mine{
					x:      g.subs[i].x + g.subs[i].w / 2.0
					y:      g.subs[i].y
					speed:  0.95 + f64(g.sector) * 0.09
					wobble: rand.f64() * 10.0
				}
			}
		}
	}

	// Torpedoes movement & ship hit
	for i := g.torpedoes.len - 1; i >= 0; i-- {
		dx := g.ship.x - g.torpedoes[i].x
		g.torpedoes[i].vx += math.sign(dx) * 0.06
		g.torpedoes[i].vx = math.max(-1.8, math.min(1.8, g.torpedoes[i].vx))

		g.torpedoes[i].x += g.torpedoes[i].vx
		g.torpedoes[i].y -= g.torpedoes[i].speed

		if g.torpedoes[i].y <= f64(water_level_y) {
			if math.abs(g.torpedoes[i].x - g.ship.x) < g.ship.w / 2.0 {
				if g.perks.shield <= 0 {
					g.lives--
					exploded = true
					g.last_events.exploded = true
					g.last_events.boat_hit = true
					g.last_events.boat_hit_x = g.torpedoes[i].x
					g.last_events.boat_hit_y = f64(water_level_y)
					if g.lives <= 0 {
						g.mode = .game_over
					}
				}
			}
			g.torpedoes.delete(i)
		}
	}

	// Mines movement & ship hit
	for i := g.mines.len - 1; i >= 0; i-- {
		g.mines[i].y -= g.mines[i].speed
		g.mines[i].wobble += 0.06
		g.mines[i].x += math.sin(g.mines[i].wobble) * 0.4

		if g.mines[i].y <= f64(water_level_y) {
			if math.abs(g.mines[i].x - g.ship.x) < g.ship.w / 2.0 {
				if g.perks.shield <= 0 {
					g.lives--
					exploded = true
					g.last_events.exploded = true
					g.last_events.boat_hit = true
					g.last_events.boat_hit_x = g.mines[i].x
					g.last_events.boat_hit_y = f64(water_level_y)
					if g.lives <= 0 {
						g.mode = .game_over
					}
				}
			}
			g.mines.delete(i)
		}
	}

	if g.score > g.high_score {
		g.high_score = g.score
	}

	g.update_rank()

	if g.target_killed >= g.req_to_clear {
		g.mode = .shop
	}

	return false, exploded, powerup_got
}

fn (mut g GameEngine) buy_upgrade(type_str string) bool {
	match type_str {
		'engine' {
			cost := 200
			if g.credits >= cost && g.upgrades.engine < 5 {
				g.credits -= cost
				g.upgrades.engine++
				return true
			}
		}
		'loader' {
			cost := 250
			if g.credits >= cost && g.upgrades.loader < 5 {
				g.credits -= cost
				g.upgrades.loader++
				return true
			}
		}
		'hull' {
			cost := 300
			if g.credits >= cost && g.upgrades.hull < 6 {
				g.credits -= cost
				g.upgrades.hull++
				g.lives = g.upgrades.hull
				return true
			}
		}
		'blast' {
			cost := 200
			if g.credits >= cost && g.upgrades.blast < 5 {
				g.credits -= cost
				g.upgrades.blast++
				return true
			}
		}
		else {}
	}
	return false
}
