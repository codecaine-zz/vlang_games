module main

import math
import rand

enum GameState {
	title
	playing
	stage_clear
	bonus_stage
	bonus_clear
	life_lost
	game_over
	paused
}

enum Difficulty {
	easy
	normal
	hard
	expert
}

fn (d Difficulty) name() string {
	return match d {
		.easy { 'EASY' }
		.normal { 'NORMAL' }
		.hard { 'HARD' }
		.expert { 'EXPERT' }
	}
}

fn (d Difficulty) initial_lives() int {
	return match d {
		.easy { 5 }
		.normal { 3 }
		.hard { 2 }
		.expert { 1 }
	}
}

fn (d Difficulty) speed_multiplier() f64 {
	return match d {
		.easy { 0.80 }
		.normal { 1.00 }
		.hard { 1.25 }
		.expert { 1.45 }
	}
}

fn (d Difficulty) max_trampoline_bounces() int {
	return match d {
		.easy { 5 }
		.normal { 4 }
		.hard { 3 }
		.expert { 2 }
	}
}

fn (d Difficulty) hurry_seconds() f64 {
	return match d {
		.easy { 55.0 }
		.normal { 40.0 }
		.hard { 28.0 }
		.expert { 20.0 }
	}
}

fn (d Difficulty) gosenzo_seconds() f64 {
	return match d {
		.easy { 85.0 }
		.normal { 65.0 }
		.hard { 48.0 }
		.expert { 35.0 }
	}
}

fn (d Difficulty) door_stun_seconds() f64 {
	return match d {
		.easy { 6.0 }
		.normal { 4.5 }
		.hard { 3.0 }
		.expert { 2.0 }
	}
}

enum EntityState {
	walking
	bouncing
	falling
	stunned
	carried_by_wave
	hidden
}

enum Direction {
	left
	right
}

enum DoorType {
	regular
	microwave
}

enum DoorState {
	closed
	opening
	open
}

enum ItemType {
	radio
	tv
	microwave
	painting
	safe
}

struct Trampoline {
pub mut:
	x          f64
	y          f64
	width      f64 = 40.0
	bounces    int // 0: Green, 1: Blue, 2: Yellow, 3: Red, 4+: Broken
	is_broken  bool
	tension    f64 // Visual spring displacement (0..1)
	single_use bool // Used in bonus stages (pops after 1 bounce)
}

struct FloorPlatform {
pub mut:
	floor_idx int // 0 (top) to 5 (ground)
	x_start   f64
	x_end     f64
	y         f64
}

struct DoorConfig {
	floor_idx int
	x         f64
	door_type int
	facing    int
}

struct ItemLoc {
	item_type ItemType
	floor_idx int
	x         f64
}

struct Door {
pub mut:
	id         int
	floor_idx  int
	x          f64
	y          f64
	door_type  DoorType
	state      DoorState
	facing     Direction // Direction it opens towards
	open_timer f64
	is_used    bool // Microwave doors become regular/depleted once triggered
}

struct Item {
pub mut:
	id        int
	item_type ItemType
	floor_idx int
	x         f64
	y         f64
	collected bool
	has_goro  bool // Boss cat is hiding behind this item
}

struct Balloon {
pub mut:
	id        int
	x         f64
	y         f64
	is_goro   bool // Large Goro balloon (2000 pts)
	collected bool
}

struct MicrowaveWave {
pub mut:
	floor_idx  int
	x          f64
	y          f64
	dir        Direction
	speed      f64 = 520.0
	active     bool
	cats_hit   int
	traveled   f64
	max_travel f64 = 700.0
}

struct FloatingScore {
pub mut:
	x     f64
	y     f64
	text  string
	timer f64
	color Color
}

struct MappyPlayer {
pub mut:
	x                 f64
	y                 f64
	vx                f64
	vy                f64
	floor_idx         int
	state             EntityState
	facing            Direction
	bounce_phase      f64 // 0..2*pi in bounce cycle
	trampoline_idx    int
	anim_timer        f64
	invulnerable      f64
	dead_timer        f64
	dismount_cooldown f64
}

struct CatEnemy {
pub mut:
	id             int
	is_goro        bool // True = Boss Cat (Nyamco), False = Mewkie
	x              f64
	y              f64
	vx             f64
	vy             f64
	floor_idx      int
	state          EntityState
	facing         Direction
	bounce_phase   f64
	trampoline_idx int
	stun_timer     f64
	anim_timer     f64
	hide_item_id   int
	respawn_timer  f64
	decision_timer f64
}

struct GosenzoCoin {
pub mut:
	active     bool
	x          f64
	y          f64
	floor_idx  int
	speed      f64 = 110.0
	anim_timer f64
}

struct LevelTheme {
pub:
	name         string
	wall_color   Color
	floor_color  Color
	bg_color     Color
	accent_color Color
}

struct GameEngine {
pub mut:
	state             GameState
	difficulty        Difficulty = .normal
	score             int
	high_score        int = 20000
	round             int = 1
	lives             int = 3
	bonus_timer       f64
	stage_timer       f64
	hurry_active      bool
	hurry_alarm_timer f64
	consecutive_type  ItemType
	consecutive_count int
	last_pair_cleared bool
	player            MappyPlayer
	enemies           []CatEnemy
	trampolines       []Trampoline
	floors            []FloorPlatform
	doors             []Door
	items             []Item
	balloons          []Balloon
	waves             []MicrowaveWave
	scores            []FloatingScore
	gosenzo           GosenzoCoin
	current_theme     LevelTheme
	is_bonus_round    bool
	transition_timer  f64
	mansion_left      f64 = 50.0
	mansion_right     f64 = 750.0
	floor_ys          []f64
}

const floor_y_levels = [
	130.0, // Floor 0 (Top / Roof)
	200.0, // Floor 1
	270.0, // Floor 2
	340.0, // Floor 3
	410.0, // Floor 4
	480.0, // Floor 5 (Ground floor)
]

const floor_thickness = 8.0
const mappy_speed = 165.0
const bounce_cycle_duration = 1.22 // Comfortable, authentic arcade bounce timing
const goro_hide_bonus = 1000

fn get_theme_for_round(round int) LevelTheme {
	themes := [
		LevelTheme{
			name: 'Classic Manor'
			wall_color: Color{ r: 180, g: 30, b: 30 }
			floor_color: Color{ r: 210, g: 170, b: 100 }
			bg_color: Color{ r: 15, g: 15, b: 30 }
			accent_color: Color{ r: 255, g: 215, b: 0 }
		},
		LevelTheme{
			name: 'Emerald Estate'
			wall_color: Color{ r: 20, g: 130, b: 70 }
			floor_color: Color{ r: 200, g: 190, b: 140 }
			bg_color: Color{ r: 10, g: 25, b: 20 }
			accent_color: Color{ r: 100, g: 255, b: 180 }
		},
		LevelTheme{
			name: 'Bonus Carnival'
			wall_color: Color{ r: 70, g: 60, b: 160 }
			floor_color: Color{ r: 240, g: 220, b: 160 }
			bg_color: Color{ r: 20, g: 10, b: 40 }
			accent_color: Color{ r: 255, g: 100, b: 200 }
		},
		LevelTheme{
			name: 'Royal Palace'
			wall_color: Color{ r: 110, g: 30, b: 140 }
			floor_color: Color{ r: 230, g: 200, b: 130 }
			bg_color: Color{ r: 25, g: 10, b: 35 }
			accent_color: Color{ r: 255, g: 220, b: 50 }
		},
		LevelTheme{
			name: 'Cyber Outpost'
			wall_color: Color{ r: 20, g: 80, b: 160 }
			floor_color: Color{ r: 140, g: 180, b: 220 }
			bg_color: Color{ r: 5, g: 15, b: 35 }
			accent_color: Color{ r: 0, g: 240, b: 255 }
		},
		LevelTheme{
			name: 'Crimson Keep'
			wall_color: Color{ r: 160, g: 20, b: 50 }
			floor_color: Color{ r: 220, g: 160, b: 120 }
			bg_color: Color{ r: 30, g: 5, b: 15 }
			accent_color: Color{ r: 255, g: 180, b: 40 }
		},
	]
	idx := (round - 1) % themes.len
	return themes[idx]
}

fn new_game_engine() GameEngine {
	mut g := GameEngine{
		state: .title
		floor_ys: floor_y_levels.clone()
		current_theme: get_theme_for_round(1)
	}
	g.load_round(1)
	return g
}

fn (mut g GameEngine) cycle_difficulty() {
	g.difficulty = match g.difficulty {
		.easy { .normal }
		.normal { .hard }
		.hard { .expert }
		.expert { .easy }
	}
	g.lives = g.difficulty.initial_lives()
}

fn (mut g GameEngine) set_difficulty(d Difficulty) {
	g.difficulty = d
	g.lives = d.initial_lives()
}

fn (mut g GameEngine) start_game(start_round int) {
	g.score = 0
	g.round = start_round
	g.lives = g.difficulty.initial_lives()
	g.consecutive_count = 0
	g.last_pair_cleared = false
	g.load_round(start_round)
	g.state = if g.is_bonus_round { .bonus_stage } else { .playing }
}

fn (mut g GameEngine) load_round(round_num int) {
	g.round = round_num
	g.is_bonus_round = (round_num % 3 == 0) // Every 3rd round is a bonus balloon stage!
	g.current_theme = get_theme_for_round(round_num)
	g.stage_timer = 0.0
	g.hurry_active = false
	g.hurry_alarm_timer = 0.0
	g.gosenzo = GosenzoCoin{ active: false }
	g.waves.clear()
	g.scores.clear()
	g.consecutive_count = 0

	// Player initialization
	g.player = MappyPlayer{
		x: 400.0
		y: floor_y_levels[5] - 20.0
		floor_idx: 5
		state: .walking
		facing: .right
		bounce_phase: 0.0
		trampoline_idx: -1
		invulnerable: 2.0
	}

	if g.is_bonus_round {
		g.setup_bonus_stage()
	} else {
		g.setup_standard_stage(round_num)
	}
}

fn (mut g GameEngine) setup_standard_stage(round_num int) {
	g.trampolines.clear()
	g.floors.clear()
	g.doors.clear()
	g.items.clear()
	g.balloons.clear()
	g.enemies.clear()

	// Trampoline X positions (4 vertical shafts)
	trampoline_cols := [130.0, 310.0, 490.0, 670.0]
	for tx in trampoline_cols {
		g.trampolines << Trampoline{
			x: tx
			y: floor_y_levels[5] + 16.0
			width: 36.0
			bounces: 0
			is_broken: false
			single_use: false
		}
	}

	// Generate Floors spanning between trampolines
	// Mansion bounds: 50.0 to 750.0
	// 5 floor sections per floor level:
	for fl_idx in 0 .. 6 {
		fy := floor_y_levels[fl_idx]
		
		// Vary floor openings slightly based on round layout
		mut has_sec := [true, true, true, true, true]
		if round_num % 4 == 2 && fl_idx == 2 {
			has_sec[1] = false // Missing gap in 2nd floor on round 2
		} else if round_num % 4 == 3 && fl_idx == 3 {
			has_sec[3] = false // Missing gap in round 3
		}

		if has_sec[0] {
			g.floors << FloorPlatform{ floor_idx: fl_idx, x_start: 50.0, x_end: 112.0, y: fy }
		}
		if has_sec[1] {
			g.floors << FloorPlatform{ floor_idx: fl_idx, x_start: 148.0, x_end: 292.0, y: fy }
		}
		if has_sec[2] {
			g.floors << FloorPlatform{ floor_idx: fl_idx, x_start: 328.0, x_end: 472.0, y: fy }
		}
		if has_sec[3] {
			g.floors << FloorPlatform{ floor_idx: fl_idx, x_start: 508.0, x_end: 652.0, y: fy }
		}
		if has_sec[4] {
			g.floors << FloorPlatform{ floor_idx: fl_idx, x_start: 688.0, x_end: 750.0, y: fy }
		}
	}

	// Doors: 4 to 6 doors per stage, some Microwave doors
	mut door_id := 0
	door_configs := [
		DoorConfig{ floor_idx: 1, x: 220.0, door_type: 0, facing: 0 },
		DoorConfig{ floor_idx: 1, x: 580.0, door_type: 1, facing: 1 },
		DoorConfig{ floor_idx: 2, x: 400.0, door_type: 0, facing: 1 },
		DoorConfig{ floor_idx: 3, x: 220.0, door_type: 1, facing: 0 },
		DoorConfig{ floor_idx: 3, x: 580.0, door_type: 0, facing: 0 },
		DoorConfig{ floor_idx: 4, x: 400.0, door_type: 1, facing: 1 },
		DoorConfig{ floor_idx: 4, x: 220.0, door_type: 0, facing: 1 },
		DoorConfig{ floor_idx: 5, x: 400.0, door_type: 0, facing: 0 },
	]

	for cfg in door_configs {
		dtype := if cfg.door_type == 1 { DoorType.microwave } else { DoorType.regular }
		dir := if cfg.facing == 1 { Direction.right } else { Direction.left }
		g.doors << Door{
			id: door_id
			floor_idx: cfg.floor_idx
			x: cfg.x
			y: floor_y_levels[cfg.floor_idx] - 32.0
			door_type: dtype
			state: .closed
			facing: dir
			is_used: false
		}
		door_id++
	}

	// 10 Items: 2 of each of 5 types (Radio, TV, Microwave, Painting, Safe)
	item_locations := [
		ItemLoc{ item_type: .radio, floor_idx: 0, x: 80.0 },
		ItemLoc{ item_type: .radio, floor_idx: 0, x: 720.0 },
		ItemLoc{ item_type: .tv, floor_idx: 1, x: 175.0 },
		ItemLoc{ item_type: .tv, floor_idx: 1, x: 625.0 },
		ItemLoc{ item_type: .microwave, floor_idx: 2, x: 250.0 },
		ItemLoc{ item_type: .microwave, floor_idx: 2, x: 550.0 },
		ItemLoc{ item_type: .painting, floor_idx: 3, x: 175.0 },
		ItemLoc{ item_type: .painting, floor_idx: 3, x: 625.0 },
		ItemLoc{ item_type: .safe, floor_idx: 4, x: 360.0 },
		ItemLoc{ item_type: .safe, floor_idx: 4, x: 440.0 },
	]

	mut item_id := 0
	for loc in item_locations {
		g.items << Item{
			id: item_id
			item_type: loc.item_type
			floor_idx: loc.floor_idx
			x: loc.x
			y: floor_y_levels[loc.floor_idx] - 22.0
			collected: false
			has_goro: (item_id == 8) // Goro hides behind one of the Safes
		}
		item_id++
	}

	// Enemies: Mewkies + Goro Boss Cat(s)
	diff_cat_offset := match g.difficulty {
		.easy { -1 }
		.normal { 0 }
		.hard { 1 }
		.expert { 2 }
	}
	num_mewkies := math.max(2, math.min(3 + (round_num / 2) + diff_cat_offset, 6))
	base_speed := (100.0 + f64(round_num) * 6.0) * g.difficulty.speed_multiplier()

	// Goro Boss Cat
	g.enemies << CatEnemy{
		id: 0
		is_goro: true
		x: 200.0
		y: floor_y_levels[1] - 22.0
		vx: base_speed * 0.85
		floor_idx: 1
		state: .walking
		facing: .right
		bounce_phase: 0.0
		trampoline_idx: -1
		hide_item_id: 8
	}

	// Extra Goro on Expert mode
	if g.difficulty == .expert {
		g.enemies << CatEnemy{
			id: 99
			is_goro: true
			x: 600.0
			y: floor_y_levels[3] - 22.0
			vx: -base_speed * 0.85
			floor_idx: 3
			state: .walking
			facing: .left
			bounce_phase: 0.0
			trampoline_idx: -1
			hide_item_id: 6
		}
	}

	// Mewkies
	mewkie_start_floors := [2, 3, 4, 1, 0, 5]
	mewkie_start_xs := [360.0, 600.0, 200.0, 440.0, 100.0, 700.0]
	for i in 0 .. num_mewkies {
		fl := mewkie_start_floors[i % mewkie_start_floors.len]
		sx := mewkie_start_xs[i % mewkie_start_xs.len]
		g.enemies << CatEnemy{
			id: i + 1
			is_goro: false
			x: sx
			y: floor_y_levels[fl] - 20.0
			vx: if i % 2 == 0 { base_speed } else { -base_speed }
			floor_idx: fl
			state: .walking
			facing: if i % 2 == 0 { Direction.right } else { Direction.left }
			bounce_phase: 0.0
			trampoline_idx: -1
		}
	}
}

fn (mut g GameEngine) setup_bonus_stage() {
	g.trampolines.clear()
	g.floors.clear()
	g.doors.clear()
	g.items.clear()
	g.balloons.clear()
	g.enemies.clear()
	g.bonus_timer = 20.0 // 20-second countdown for bonus round

	// Bonus stage has 4 trampolines that break after 1 bounce
	trampoline_cols := [140.0, 320.0, 480.0, 660.0]
	for tx in trampoline_cols {
		g.trampolines << Trampoline{
			x: tx
			y: floor_y_levels[5] + 16.0
			width: 36.0
			bounces: 0
			is_broken: false
			single_use: true // Single-use in bonus stage!
		}
	}

	// Small floor perches to bounce between
	for fl_idx in 0 .. 6 {
		fy := floor_y_levels[fl_idx]
		g.floors << FloorPlatform{ floor_idx: fl_idx, x_start: 50.0, x_end: 120.0, y: fy }
		g.floors << FloorPlatform{ floor_idx: fl_idx, x_start: 380.0, x_end: 420.0, y: fy }
		g.floors << FloorPlatform{ floor_idx: fl_idx, x_start: 680.0, x_end: 750.0, y: fy }
	}

	// Balloons along bounce arcs
	mut b_id := 0
	for tx in trampoline_cols {
		for h in 0 .. 5 {
			by := floor_y_levels[h] + 35.0
			g.balloons << Balloon{
				id: b_id
				x: tx
				y: by
				is_goro: false
				collected: false
			}
			b_id++
		}
	}

	// Large Goro balloon at the top
	g.balloons << Balloon{
		id: b_id
		x: 400.0
		y: 85.0
		is_goro: true
		collected: false
	}
}

fn (mut g GameEngine) update(dt f64, left bool, right bool, action_open bool, mut sm SoundManager) {
	match g.state {
		.title {
			return
		}
		.paused {
			return
		}
		.playing {
			g.update_playing(dt, left, right, action_open, mut sm)
		}
		.bonus_stage {
			g.update_bonus_stage(dt, left, right, mut sm)
		}
		.stage_clear, .bonus_clear {
			g.transition_timer += dt
			if g.transition_timer >= 1.4 {
				g.transition_timer = 0.0
				g.load_round(g.round + 1)
				g.state = if g.is_bonus_round { .bonus_stage } else { .playing }
			}
		}
		.life_lost {
			g.player.dead_timer += dt
			if g.player.dead_timer >= 1.2 {
				g.player.dead_timer = 0.0
				if g.lives > 0 {
					g.load_round(g.round)
					g.state = .playing
				} else {
					g.state = .game_over
				}
			}
		}
		.game_over {
			g.transition_timer += dt
		}
	}
}

fn (mut g GameEngine) update_playing(dt f64, left bool, right bool, action_open bool, mut sm SoundManager) {
	g.stage_timer += dt

	// Hurry Up trigger based on difficulty
	if g.stage_timer >= g.difficulty.hurry_seconds() && !g.hurry_active {
		g.hurry_active = true
		sm.play_hurry_up()
		g.scores << FloatingScore{
			x: 400.0
			y: 200.0
			text: 'HURRY UP!'
			timer: 2.5
			color: Color{ r: 255, g: 50, b: 50 }
		}
	}

	// Gosenzo Coin trigger based on difficulty
	if g.stage_timer >= g.difficulty.gosenzo_seconds() && !g.gosenzo.active {
		g.gosenzo.active = true
		g.gosenzo.x = 400.0
		g.gosenzo.y = 80.0
		g.gosenzo.floor_idx = 0
		sm.play_gosenzo_appear()
		g.scores << FloatingScore{
			x: 400.0
			y: 120.0
			text: 'GOSENZO IS COMING!'
			timer: 3.0
			color: Color{ r: 255, g: 215, b: 0 }
		}
	}

	// Update Player
	g.update_player(dt, left, right, action_open, mut sm)

	// Update Enemies
	g.update_enemies(dt, mut sm)

	// Update Gosenzo Coin
	if g.gosenzo.active {
		g.update_gosenzo(dt)
	}

	// Update Microwave Shockwaves
	g.update_waves(dt)

	// Update Doors
	g.update_doors(dt)

	// Update Trampoline Tension Displacements
	for mut tr in g.trampolines {
		if tr.tension > 0 {
			tr.tension = math.max(0.0, tr.tension - dt * 3.5)
		}
	}

	// Update Floating Score Popups
	for mut sc in g.scores {
		sc.timer -= dt
		sc.y -= dt * 25.0
	}
	g.scores = g.scores.filter(it.timer > 0)

	// Check Stage Clear (all 10 items collected)
	all_collected := g.items.all(it.collected)
	if all_collected && g.items.len > 0 {
		g.state = .stage_clear
		g.transition_timer = 0.0
		sm.play_stage_clear()
		g.scores << FloatingScore{
			x: 400.0
			y: 260.0
			text: 'STAGE CLEAR!'
			timer: 2.5
			color: Color{ r: 50, g: 255, b: 100 }
		}
	}
}

fn (mut g GameEngine) update_player(dt f64, left bool, right bool, action_open bool, mut sm SoundManager) {
	if g.player.invulnerable > 0 {
		g.player.invulnerable -= dt
	}
	if g.player.dismount_cooldown > 0 {
		g.player.dismount_cooldown -= dt
	}

	match g.player.state {
		.walking {
			// Horizontal movement along current floor
			mut move_dir := 0.0
			if left {
				move_dir -= 1.0
				g.player.facing = .left
			}
			if right {
				move_dir += 1.0
				g.player.facing = .right
			}

			g.player.x += move_dir * mappy_speed * dt
			g.player.anim_timer += dt * 10.0

			// Constrain within mansion walls
			g.player.x = math.max(g.mansion_left + 10.0, math.min(g.mansion_right - 10.0, g.player.x))

			// Check closed doors blocking Mappy (Closed doors block passage until opened!)
			for d in g.doors {
				if d.state == .closed && d.floor_idx == g.player.floor_idx {
					if math.abs(g.player.x - d.x) < 18.0 {
						if move_dir > 0 && g.player.x <= d.x {
							g.player.x = d.x - 18.0
						} else if move_dir < 0 && g.player.x >= d.x {
							g.player.x = d.x + 18.0
						}
					}
				}
			}

			// Check if player stepped off a floor into a trampoline shaft
			current_fl_y := floor_y_levels[g.player.floor_idx]
			mut on_solid_floor := false
			for fl in g.floors {
				if fl.floor_idx == g.player.floor_idx {
					if g.player.x >= fl.x_start && g.player.x <= fl.x_end {
						on_solid_floor = true
						break
					}
				}
			}

			if !on_solid_floor {
				// Player stepped into a gap! Check if over a trampoline
				mut caught_trampoline := false
				for i, tr in g.trampolines {
					if math.abs(g.player.x - tr.x) < tr.width * 0.85 {
						if !tr.is_broken {
							g.player.state = .bouncing
							g.player.trampoline_idx = i
							g.player.x = tr.x
							g.player.dismount_cooldown = 0.22 // Grace period prevents immediate re-dismount

							if g.player.floor_idx == 5 {
								// Stepped onto trampoline at ground level: immediate rebound launch upwards!
								g.player.bounce_phase = math.pi
								mut mut_tr := &g.trampolines[i]
								mut_tr.bounces++
								mut_tr.tension = 1.0
								sm.play_bounce()
							} else {
								// Dropped into shaft from upper floor: fall towards trampoline bottom
								g.player.bounce_phase = g.calculate_bounce_phase(current_fl_y)
							}
							caught_trampoline = true
							break
						}
					}
				}
				if !caught_trampoline {
					g.player.state = .falling
					g.player.vy = 50.0
				}
			}

			// Open Door Action
			if action_open {
				g.try_open_door(mut sm)
			}

			// Check Item Pickup
			for mut item in g.items {
				if !item.collected && item.floor_idx == g.player.floor_idx {
					if math.abs(g.player.x - item.x) < 22.0 {
						item.collected = true
						g.handle_item_collected(item, mut sm)
					}
				}
			}
		}
		.bouncing {
			tr_idx := g.player.trampoline_idx
			if tr_idx < 0 || tr_idx >= g.trampolines.len {
				g.player.state = .falling
				return
			}

			// Continuous sinusoidal oscillation in the bounce shaft
			prev_phase := g.player.bounce_phase
			g.player.bounce_phase += (2.0 * math.pi / bounce_cycle_duration) * dt

			// Check trampoline bottom hit (at phase = pi)
			if prev_phase < math.pi && g.player.bounce_phase >= math.pi {
				mut tr := &g.trampolines[tr_idx]
				tr.bounces++
				tr.tension = 1.0
				sm.play_bounce()

				if tr.single_use || tr.bounces >= g.difficulty.max_trampoline_bounces() {
					// Trampoline breaks!
					tr.is_broken = true
					g.player.state = .falling
					g.player.vy = 80.0
					sm.play_death()
					return
				}
			}

			// Reset full cycle at peak (2*pi)
			if g.player.bounce_phase >= 2.0 * math.pi {
				g.player.bounce_phase -= 2.0 * math.pi
			}

			// Y position along sinusoidal bounce: peak at y=90, bottom at y=488
			min_y := 90.0
			max_y := floor_y_levels[5] + 8.0
			amplitude := (max_y - min_y) / 2.0
			mid_y := min_y + amplitude
			g.player.y = mid_y - amplitude * math.cos(g.player.bounce_phase)
			g.player.x = g.trampolines[tr_idx].x

			// Check Dismount onto any floor level:
			// If player is holding Left or Right near a floor level, dismount!
			if (left || right) && g.player.dismount_cooldown <= 0.0 {
				dismount_dir := if left { Direction.left } else { Direction.right }
				for fl_idx in 0 .. 6 {
					target_y := floor_y_levels[fl_idx] - 20.0
					if math.abs(g.player.y - target_y) < 22.0 {
						// Check if there is a floor platform in that direction
						check_x := if dismount_dir == .left { g.player.x - 24.0 } else { g.player.x + 24.0 }
						for fl in g.floors {
							if fl.floor_idx == fl_idx && check_x >= fl.x_start && check_x <= fl.x_end {
								// Dismount successful!
								g.player.state = .walking
								g.player.floor_idx = fl_idx
								g.player.y = target_y
								g.player.x = check_x
								g.player.facing = dismount_dir
								
								// Reset trampoline wear back to 0 on safe floor landing!
								g.trampolines[tr_idx].bounces = 0
								break
							}
						}
						if g.player.state == .walking {
							break
						}
					}
				}
			}
		}
		.falling {
			g.player.vy += 600.0 * dt
			g.player.y += g.player.vy * dt

			// Check trampoline catch while falling into shaft
			if g.player.y >= floor_y_levels[5] - 20.0 && g.player.y <= floor_y_levels[5] + 30.0 {
				for i, tr in g.trampolines {
					if math.abs(g.player.x - tr.x) < tr.width * 0.85 && !tr.is_broken {
						g.player.state = .bouncing
						g.player.trampoline_idx = i
						g.player.x = tr.x
						g.player.bounce_phase = math.pi
						g.player.dismount_cooldown = 0.22
						mut mut_tr := &g.trampolines[i]
						mut_tr.bounces++
						mut_tr.tension = 1.0
						sm.play_bounce()
						return
					}
				}
			}

			if g.player.y > 580.0 {
				// Fell out of mansion bounds: lose life!
				g.handle_player_death(mut sm)
			}
		}
		else {}
	}
}

fn (mut g GameEngine) handle_item_collected(item Item, mut sm SoundManager) {
	base_pts := match item.item_type {
		.radio { 100 }
		.tv { 200 }
		.microwave { 300 }
		.painting { 400 }
		.safe { 500 }
	}

	mut multiplier := 1
	if g.consecutive_count > 0 && g.consecutive_type == item.item_type {
		// Consecutive pair match! Multiplier increases
		g.consecutive_count++
		multiplier = g.consecutive_count
		g.last_pair_cleared = true
	} else {
		// New item type started
		g.consecutive_type = item.item_type
		g.consecutive_count = 1
		g.last_pair_cleared = false
	}

	mut pts := base_pts * multiplier
	if g.difficulty == .expert {
		pts = int(f64(pts) * 1.5) // 50% extra score on Expert!
	}

	g.score += pts
	if g.score > g.high_score {
		g.high_score = g.score
	}

	sm.play_item_pickup(multiplier)

	mut txt := '+${pts}'
	if multiplier > 1 {
		txt = '${multiplier}x +${pts}!'
	}
	g.scores << FloatingScore{
		x: item.x
		y: item.y - 12.0
		text: txt
		timer: 1.2
		color: Color{ r: 255, g: 230, b: 80 }
	}

	// Goro hiding behind item bonus!
	if item.has_goro {
		mut goro_pts := goro_hide_bonus
		if g.difficulty == .expert {
			goro_pts = 1500
		}
		g.score += goro_pts
		sm.play_goro_reveal()
		g.scores << FloatingScore{
			x: item.x
			y: item.y - 28.0
			text: 'NYAMCO BONUS! +${goro_pts}'
			timer: 2.0
			color: Color{ r: 255, g: 100, b: 220 }
		}

		// Reveal and stun Goro
		for mut en in g.enemies {
			if en.is_goro {
				en.state = .stunned
				en.stun_timer = g.difficulty.door_stun_seconds()
				en.x = item.x
				en.y = floor_y_levels[item.floor_idx] - 20.0
				en.floor_idx = item.floor_idx
			}
		}
	}
}

fn (mut g GameEngine) try_open_door(mut sm SoundManager) {
	for mut d in g.doors {
		if d.state == .closed && d.floor_idx == g.player.floor_idx {
			// Check proximity to door handle
			if math.abs(g.player.x - d.x) < 32.0 {
				d.state = .opening
				d.open_timer = 0.0
				sm.play_door_open()

				if d.door_type == .microwave && !d.is_used {
					// Fire microwave shockwave!
					d.is_used = true
					g.waves << MicrowaveWave{
						floor_idx: d.floor_idx
						x: d.x
						y: d.y + 16.0
						dir: d.facing
						active: true
						cats_hit: 0
						traveled: 0.0
					}
					sm.play_microwave_wave()
				} else {
					// Regular door swing stun check
					door_swing_dir := if d.facing == .right { 1.0 } else { -1.0 }
					for mut en in g.enemies {
						if en.state == .walking && en.floor_idx == d.floor_idx {
							dx := en.x - d.x
							if (door_swing_dir > 0 && dx > 0 && dx < 60.0) ||
								(door_swing_dir < 0 && dx < 0 && dx > -60.0) {
								en.state = .stunned
								en.stun_timer = g.difficulty.door_stun_seconds()
								en.x += door_swing_dir * 30.0
								g.score += 100
								sm.play_door_stun()
								g.scores << FloatingScore{
									x: en.x
									y: en.y - 15.0
									text: '+100 STUN'
									timer: 1.0
									color: Color{ r: 255, g: 180, b: 0 }
								}
							}
						}
					}
				}
				break
			}
		}
	}
}

fn (mut g GameEngine) update_doors(dt f64) {
	for mut d in g.doors {
		if d.state == .opening {
			d.open_timer += dt
			if d.open_timer >= 0.14 {
				d.state = .open
				d.open_timer = 0.0
			}
		} else if d.state == .open {
			d.open_timer += dt
			if d.open_timer >= 3.0 { // Stays open for 3 seconds, then closes
				d.state = .closed
				d.open_timer = 0.0
			}
		}
	}
}

fn (mut g GameEngine) update_waves(dt f64) {
	for mut w in g.waves {
		if !w.active {
			continue
		}
		dist := w.speed * dt
		w.traveled += dist
		if w.dir == .right {
			w.x += dist
		} else {
			w.x -= dist
		}

		if w.traveled >= w.max_travel || w.x < g.mansion_left || w.x > g.mansion_right {
			w.active = false
			continue
		}

		// Sweep cats in the wave's path
		for mut en in g.enemies {
			if en.state != .carried_by_wave && en.floor_idx == w.floor_idx {
				if math.abs(en.x - w.x) < 30.0 {
					en.state = .carried_by_wave
					w.cats_hit++
					pts := 200 * int(math.pow(2.0, f64(w.cats_hit - 1)))
					g.score += pts
					g.scores << FloatingScore{
						x: en.x
						y: en.y - 20.0
						text: 'MICROWAVE! +${pts}'
						timer: 1.5
						color: Color{ r: 100, g: 220, b: 255 }
					}
				}
			}
		}
	}
	g.waves = g.waves.filter(it.active)
}

fn (mut g GameEngine) update_enemies(dt f64, mut sm SoundManager) {
	hurry_speed_multiplier := if g.hurry_active { 1.35 } else { 1.0 }

	for mut en in g.enemies {
		en.anim_timer += dt * 8.0

		match en.state {
			.walking {
				// Horizontal patrol & chase AI
				speed := math.abs(en.vx) * hurry_speed_multiplier
				dir_mult := if en.facing == .right { 1.0 } else { -1.0 }
				en.x += dir_mult * speed * dt

				// Check closed doors in enemy's path
				for d in g.doors {
					if d.state == .closed && d.floor_idx == en.floor_idx {
						if math.abs(en.x - d.x) < 18.0 {
							// Blocked by closed door: turn around!
							en.facing = if en.facing == .right { Direction.left } else { Direction.right }
							en.x = if en.facing == .right { d.x + 20.0 } else { d.x - 20.0 }
							break
						}
					}
				}

				// Check floor ends / trampoline shafts
				mut on_floor := false
				for fl in g.floors {
					if fl.floor_idx == en.floor_idx && en.x >= fl.x_start && en.x <= fl.x_end {
						on_floor = true
						break
					}
				}

				if !on_floor {
					// Cat stepped into trampoline shaft!
					mut jumped := false
					for i, tr in g.trampolines {
						if math.abs(en.x - tr.x) < tr.width * 0.8 && !tr.is_broken {
							en.state = .bouncing
							en.trampoline_idx = i
							en.x = tr.x
							en.bounce_phase = g.calculate_bounce_phase(floor_y_levels[en.floor_idx])
							jumped = true
							break
						}
					}
					if !jumped {
						// Turn around at ledge
						en.facing = if en.facing == .right { Direction.left } else { Direction.right }
						en.x += if en.facing == .right { 8.0 } else { -8.0 }
					}
				}

				// Wall boundaries
				if en.x <= g.mansion_left + 15.0 {
					en.facing = .right
					en.x = g.mansion_left + 16.0
				} else if en.x >= g.mansion_right - 15.0 {
					en.facing = .left
					en.x = g.mansion_right - 16.0
				}

				// Check collision with Mappy while walking on same floor (NOT on trampolines!)
				if g.player.state == .walking && g.player.floor_idx == en.floor_idx {
					if math.abs(g.player.x - en.x) < 20.0 && g.player.invulnerable <= 0 {
						g.handle_player_death(mut sm)
					}
				}
			}
			.bouncing {
				tr_idx := en.trampoline_idx
				if tr_idx < 0 || tr_idx >= g.trampolines.len {
					en.state = .walking
					return
				}

				en.bounce_phase += (2.0 * math.pi / bounce_cycle_duration) * dt
				if en.bounce_phase >= 2.0 * math.pi {
					en.bounce_phase -= 2.0 * math.pi
				}

				min_y := 90.0
				max_y := floor_y_levels[5] + 8.0
				amplitude := (max_y - min_y) / 2.0
				mid_y := min_y + amplitude
				en.y = mid_y - amplitude * math.cos(en.bounce_phase)
				en.x = g.trampolines[tr_idx].x

				// Enemy AI decision to dismount onto player's floor
				en.decision_timer += dt
				if en.decision_timer >= 0.12 {
					en.decision_timer = 0.0
					target_fl := g.player.floor_idx
					target_y := floor_y_levels[target_fl] - 20.0
					if math.abs(en.y - target_y) < 20.0 {
						// Decide left or right towards Mappy
						dismount_dir := if g.player.x < en.x { Direction.left } else { Direction.right }
						check_x := if dismount_dir == .left { en.x - 22.0 } else { en.x + 22.0 }
						for fl in g.floors {
							if fl.floor_idx == target_fl && check_x >= fl.x_start && check_x <= fl.x_end {
								en.state = .walking
								en.floor_idx = target_fl
								en.y = target_y
								en.x = check_x
								en.facing = dismount_dir
								break
							}
						}
					}
				}
			}
			.stunned {
				en.stun_timer -= dt
				if en.stun_timer <= 0 {
					en.state = .walking
				}
			}
			.carried_by_wave {
				en.x += if en.facing == .right { 340.0 * dt } else { -340.0 * dt }
				if en.x < g.mansion_left - 30.0 || en.x > g.mansion_right + 30.0 {
					// Cat blown off screen: respawn after delay at top floor attic
					en.state = .walking
					en.floor_idx = 0
					en.y = floor_y_levels[0] - 20.0
					en.x = 400.0
					en.facing = if rand.f64() > 0.5 { Direction.right } else { Direction.left }
				}
			}
			else {}
		}
	}
}

fn (mut g GameEngine) update_gosenzo(dt f64) {
	g.gosenzo.anim_timer += dt * 6.0
	// Gosenzo Coin slowly glides towards Mappy across floors and trampolines
	dx := g.player.x - g.gosenzo.x
	dy := g.player.y - g.gosenzo.y
	dist := math.sqrt(dx * dx + dy * dy)
	if dist > 2.0 {
		g.gosenzo.x += (dx / dist) * g.gosenzo.speed * dt
		g.gosenzo.y += (dy / dist) * g.gosenzo.speed * dt
	}

	// Gosenzo kills Mappy regardless of trampoline state!
	if g.player.invulnerable <= 0 && dist < 24.0 {
		mut sm := new_sound_manager()
		g.handle_player_death(mut sm)
	}
}

fn (mut g GameEngine) update_bonus_stage(dt f64, left bool, right bool, mut sm SoundManager) {
	g.bonus_timer -= dt
	g.update_player(dt, left, right, false, mut sm)

	// Check Balloon Collection
	for mut b in g.balloons {
		if !b.collected {
			dx := g.player.x - b.x
			dy := g.player.y - b.y
			if (dx * dx + dy * dy) < (22.0 * 22.0) {
				b.collected = true
				sm.play_balloon_pop()
				pts := if b.is_goro { 2000 } else { 200 }
				g.score += pts
				g.scores << FloatingScore{
					x: b.x
					y: b.y - 10.0
					text: if b.is_goro { 'NYAMCO BALLOON! +2000' } else { '+200' }
					timer: 1.2
					color: if b.is_goro { Color{ r: 255, g: 100, b: 220 } } else { Color{ r: 255, g: 230, b: 80 } }
				}
			}
		}
	}

	// Check all balloons collected (Perfect Bonus!)
	all_balloons := g.balloons.all(it.collected)
	if all_balloons && g.balloons.len > 0 {
		g.score += 5000
		sm.play_bonus_perfect()
		g.state = .bonus_clear
		g.transition_timer = 0.0
		g.scores << FloatingScore{
			x: 400.0
			y: 240.0
			text: 'PERFECT BONUS! +5000'
			timer: 2.5
			color: Color{ r: 255, g: 215, b: 0 }
		}
		return
	}

	// Timer ran out or player fell
	if g.bonus_timer <= 0 || g.player.state == .falling {
		g.state = .bonus_clear
		g.transition_timer = 0.0
	}
}

fn (mut g GameEngine) handle_player_death(mut sm SoundManager) {
	if g.player.state == .falling && g.state == .life_lost {
		return
	}
	sm.play_death()
	g.lives--
	g.state = .life_lost
	g.player.dead_timer = 0.0
}

fn (g GameEngine) calculate_bounce_phase(target_y f64) f64 {
	min_y := 90.0
	max_y := floor_y_levels[5] + 8.0
	amplitude := (max_y - min_y) / 2.0
	mid_y := min_y + amplitude
	clamped_y := math.max(min_y, math.min(max_y, target_y))
	cos_val := (mid_y - clamped_y) / amplitude
	return math.acos(math.max(-1.0, math.min(1.0, cos_val)))
}
