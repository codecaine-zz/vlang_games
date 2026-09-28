module main

import math
import rand

pub enum Skill {
	climber
	floater
	bomber
	blocker
	builder
	basher
	miner
	digger
}

pub enum LemmingState {
	walking
	falling
	floating
	climbing
	blocking
	building
	bashing
	mining
	digging
	exploding
	exiting
	dead
}

pub struct Lemming {
pub mut:
	x           f64
	y           f64
	vx          f64 = 28.0 // Direction (+28 right, -28 left)
	state       LemmingState = .falling
	is_climber  bool
	is_floater  bool
	fall_dist   f64
	countdown   f64 = -1.0 // Bomber timer (5.0s)
	step_count  int // For builder (12 steps)
	action_time f64
	anim_frame  int
}

pub struct Level {
pub mut:
	name         string
	spawn_x      int
	spawn_y      int
	exit_x       int
	exit_y       int
	total_lems   int = 20
	target_save  int = 14 // Required to win
	time_limit   int = 180
	skills       map[string]int
}

pub const map_w = 460
pub const map_h = 280

pub struct LemmingsGame {
pub mut:
	level_idx       int
	levels          []Level
	terrain         [][]bool // true = solid ground, false = empty air

	lemmings        []Lemming
	spawned_count   int
	saved_count     int
	dead_count      int
	spawn_timer     f64
	spawn_rate      f64 = 1.6

	selected_skill  Skill = .digger
	game_speed      f64 = 1.0 // 1.0x, 2.0x, 4.0x
	is_paused       bool
	is_nuking       bool
	is_level_clear  bool
	is_game_over    bool
	time_remaining  f64

	sound_event     string
	banner_text     string
	banner_timer    f64
}

pub fn new_lemmings_game() LemmingsGame {
	mut g := LemmingsGame{
		terrain: [][]bool{len: map_w, init: []bool{len: map_h, init: false}}
	}
	g.init_levels()
	g.load_level(0)
	return g
}

pub fn (mut g LemmingsGame) init_levels() {
	g.levels.clear()

	// Level 1: Just Dig!
	mut l1 := Level{
		name: '1. Just Dig!'
		spawn_x: 60
		spawn_y: 40
		exit_x: 380
		exit_y: 220
		total_lems: 20
		target_save: 14
		time_limit: 180
		skills: map[string]int{}
	}
	l1.skills[Skill.digger.str()] = 15
	l1.skills[Skill.builder.str()] = 10
	l1.skills[Skill.blocker.str()] = 5
	l1.skills[Skill.bomber.str()] = 5
	g.levels << l1

	// Level 2: Bridge Over Abyss
	mut l2 := Level{
		name: '2. Bridge Over Abyss'
		spawn_x: 50
		spawn_y: 40
		exit_x: 400
		exit_y: 120
		total_lems: 25
		target_save: 20
		time_limit: 200
		skills: map[string]int{}
	}
	l2.skills[Skill.builder.str()] = 25
	l2.skills[Skill.blocker.str()] = 10
	l2.skills[Skill.basher.str()] = 10
	l2.skills[Skill.floater.str()] = 15
	g.levels << l2
}

pub fn (mut g LemmingsGame) load_level(idx int) {
	g.level_idx = idx % g.levels.len
	lvl := g.levels[g.level_idx]

	// Reset Terrain
	for x in 0 .. map_w {
		for y in 0 .. map_h {
			g.terrain[x][y] = false
		}
	}

	// Build Level Geography
	if g.level_idx == 0 {
		// Platform 1 (under hatch)
		for x in 30 .. 220 {
			for y in 90 .. 130 { g.terrain[x][y] = true }
		}
		// Platform 2 (middle pillar)
		for x in 220 .. 340 {
			for y in 140 .. 240 { g.terrain[x][y] = true }
		}
		// Bottom Floor
		for x in 0 .. map_w {
			for y in 250 .. map_h { g.terrain[x][y] = true }
		}
	} else {
		// High Left Ledge
		for x in 20 .. 160 {
			for y in 120 .. map_h { g.terrain[x][y] = true }
		}
		// Center Island
		for x in 230 .. 310 {
			for y in 160 .. map_h { g.terrain[x][y] = true }
		}
		// Right Exit Cliff
		for x in 360 .. map_w - 20 {
			for y in 140 .. map_h { g.terrain[x][y] = true }
		}
	}

	g.lemmings.clear()
	g.spawned_count = 0
	g.saved_count = 0
	g.dead_count = 0
	g.spawn_timer = 0.5
	g.is_nuking = false
	g.is_level_clear = false
	g.is_game_over = false
	g.time_remaining = f64(lvl.time_limit)
	g.sound_event = 'start'
	g.banner_text = 'LEVEL ${g.level_idx + 1}: ${lvl.name.to_upper()}'
	g.banner_timer = 3.0
}

pub fn (g LemmingsGame) is_solid(x int, y int) bool {
	if x < 0 || x >= map_w || y >= map_h {
		return true
	}
	if y < 0 {
		return false
	}
	return g.terrain[x][y]
}

pub fn (mut g LemmingsGame) carve_circle(cx int, cy int, r int) {
	for dx := -r; dx <= r; dx++ {
		for dy := -r; dy <= r; dy++ {
			if dx * dx + dy * dy <= r * r {
				tx := cx + dx
				ty := cy + dy
				if tx >= 0 && tx < map_w && ty >= 0 && ty < map_h {
					g.terrain[tx][ty] = false
				}
			}
		}
	}
}

pub fn (mut g LemmingsGame) trigger_nuke() {
	g.is_nuking = true
	g.sound_event = 'ohno'
	for mut lem in g.lemmings {
		if lem.state != .exiting && lem.state != .dead && lem.countdown < 0.0 {
			lem.countdown = 0.2 + rand.f64() * 2.5
		}
	}
}

pub fn (mut g LemmingsGame) assign_skill(lem_idx int) bool {
	if lem_idx < 0 || lem_idx >= g.lemmings.len {
		return false
	}
	mut lem := g.lemmings[lem_idx]
	lvl := g.levels[g.level_idx]
	s_name := g.selected_skill.str()

	if lvl.skills[s_name] <= 0 || lem.state == .dead || lem.state == .exiting {
		return false
	}

	g.levels[g.level_idx].skills[s_name]--

	match g.selected_skill {
		.climber {
			lem.is_climber = true
		}
		.floater {
			lem.is_floater = true
		}
		.bomber {
			if lem.countdown < 0.0 {
				lem.countdown = 5.0
				g.sound_event = 'ohno'
			}
		}
		.blocker {
			lem.state = .blocking
		}
		.builder {
			lem.state = .building
			lem.step_count = 0
			lem.action_time = 0.0
		}
		.basher {
			lem.state = .bashing
		}
		.miner {
			lem.state = .mining
		}
		.digger {
			lem.state = .digging
		}
	}

	g.lemmings[lem_idx] = lem
	return true
}

pub fn (mut g LemmingsGame) update(dt f64) {
	if g.is_paused {
		return
	}
	real_dt := dt * g.game_speed

	if g.banner_timer > 0.0 {
		g.banner_timer -= real_dt
	}
	g.time_remaining -= real_dt

	lvl := g.levels[g.level_idx]

	// 1. Hatch Spawning
	if g.spawned_count < lvl.total_lems {
		g.spawn_timer += real_dt
		if g.spawn_timer >= g.spawn_rate {
			g.spawn_timer = 0.0
			g.spawned_count++
			g.lemmings << Lemming{
				x: f64(lvl.spawn_x)
				y: f64(lvl.spawn_y)
				state: .falling
			}
		}
	}

	// 2. Lemming State Machine & Physics
	for i := 0; i < g.lemmings.len; i++ {
		mut lem := g.lemmings[i]
		if lem.state == .dead || lem.state == .exiting {
			continue
		}

		// Bomber Countdown
		if lem.countdown > 0.0 {
			lem.countdown -= real_dt
			if lem.countdown <= 0.0 {
				lem.state = .exploding
				g.carve_circle(int(lem.x), int(lem.y), 16)
				g.sound_event = 'explode'
				lem.state = .dead
				g.dead_count++
				g.lemmings[i] = lem
				continue
			}
		}

		// Check Exit Portal
		dx := math.abs(lem.x - f64(lvl.exit_x))
		dy := math.abs(lem.y - f64(lvl.exit_y))
		if dx <= 10.0 && dy <= 10.0 && lem.state != .falling {
			lem.state = .exiting
			g.saved_count++
			g.sound_event = 'yippee'
			g.lemmings[i] = lem
			continue
		}

		lx := int(lem.x)
		ly := int(lem.y)

		match lem.state {
			.falling {
				lem.fall_dist += 60.0 * real_dt
				// Floater parachute
				if lem.is_floater && lem.fall_dist > 25.0 {
					lem.state = .floating
				} else {
					lem.y += 65.0 * real_dt
					if g.is_solid(lx, int(lem.y + 1)) {
						if lem.fall_dist > 80.0 && !lem.is_floater {
							// Splat on ground
							lem.state = .dead
							g.dead_count++
							g.sound_event = 'explode'
						} else {
							lem.state = .walking
							lem.fall_dist = 0.0
						}
					}
				}
			}
			.floating {
				lem.y += 30.0 * real_dt
				if g.is_solid(lx, int(lem.y + 1)) {
					lem.state = .walking
					lem.fall_dist = 0.0
				}
			}
			.walking {
				// Check for floor below
				if !g.is_solid(lx, ly + 1) {
					lem.state = .falling
					lem.fall_dist = 0.0
				} else {
					// Step forward
					next_x := int(lem.x + (if lem.vx > 0 { 1.0 } else { -1.0 }))
					if g.is_solid(next_x, ly) {
						// Check if can step up 1-3 pixels (slope)
						if !g.is_solid(next_x, ly - 2) {
							lem.y -= 2.0
							lem.x += (lem.vx * real_dt)
						} else if lem.is_climber {
							lem.state = .climbing
						} else {
							// Turn around
							lem.vx = -lem.vx
						}
					} else {
						lem.x += (lem.vx * real_dt)
					}
				}
			}
			.climbing {
				lem.y -= 25.0 * real_dt
				climb_x := int(lem.x + (if lem.vx > 0 { 1.0 } else { -1.0 }))
				if !g.is_solid(climb_x, int(lem.y)) {
					// Climbed over top ledge
					lem.x += (if lem.vx > 0 { 2.0 } else { -2.0 })
					lem.state = .walking
				}
			}
			.blocking {
				// Turn around other nearby walking lemmings
				for j in 0 .. g.lemmings.len {
					if j != i && g.lemmings[j].state == .walking {
						mut other := g.lemmings[j]
						if math.abs(other.x - lem.x) <= 6.0 && math.abs(other.y - lem.y) <= 6.0 {
							if (other.vx > 0 && other.x < lem.x) || (other.vx < 0 && other.x > lem.x) {
								other.vx = -other.vx
								g.lemmings[j] = other
							}
						}
					}
				}
			}
			.building {
				lem.action_time += real_dt
				if lem.action_time >= 0.35 {
					lem.action_time = 0.0
					bx := int(lem.x + (if lem.vx > 0 { 2.0 } else { -2.0 }))
					by := int(lem.y)

					// Place brick
					for ox in 0 .. 4 {
						tx := bx + ox
						if tx >= 0 && tx < map_w && by >= 0 && by < map_h {
							g.terrain[tx][by] = true
						}
					}
					g.sound_event = 'brick'

					lem.x = f64(bx)
					lem.y -= 1.0
					lem.step_count++

					if lem.step_count >= 12 {
						lem.state = .walking
					}
				}
			}
			.digging {
				lem.action_time += real_dt
				if lem.action_time >= 0.2 {
					lem.action_time = 0.0
					g.carve_circle(int(lem.x), int(lem.y + 3), 4)
					lem.y += 2.0
					if !g.is_solid(int(lem.x), int(lem.y + 3)) {
						lem.state = .falling
					}
				}
			}
			.bashing {
				lem.action_time += real_dt
				if lem.action_time >= 0.2 {
					lem.action_time = 0.0
					bx := int(lem.x + (if lem.vx > 0 { 3.0 } else { -3.0 }))
					g.carve_circle(bx, int(lem.y - 2), 6)
					lem.x += (if lem.vx > 0 { 2.0 } else { -2.0 })
					if !g.is_solid(bx, int(lem.y)) {
						lem.state = .walking
					}
				}
			}
			.mining {
				lem.action_time += real_dt
				if lem.action_time >= 0.2 {
					lem.action_time = 0.0
					mx := int(lem.x + (if lem.vx > 0 { 2.0 } else { -2.0 }))
					g.carve_circle(mx, int(lem.y + 2), 5)
					lem.x += (if lem.vx > 0 { 2.0 } else { -2.0 })
					lem.y += 2.0
					if !g.is_solid(mx, int(lem.y + 1)) {
						lem.state = .falling
					}
				}
			}
			else {}
		}

		g.lemmings[i] = lem
	}

	// Check Level Win / Loss Conditions
	if g.saved_count + g.dead_count >= lvl.total_lems || g.time_remaining <= 0.0 {
		if g.saved_count >= lvl.target_save {
			g.is_level_clear = true
			g.banner_text = 'LEVEL COMPLETE! SAVED: ${g.saved_count}/${lvl.total_lems}'
			g.banner_timer = 5.0
		} else {
			g.is_game_over = true
			g.banner_text = 'LEVEL FAILED! REQUIRED: ${lvl.target_save} SAVED'
			g.banner_timer = 5.0
		}
	}
}
