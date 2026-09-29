module main

import math

pub const win_w = 960
pub const win_h = 680

// --------------------------------------------------
// Enums & Types matching Web Cyberpunk Remaster
// --------------------------------------------------

pub enum GameMode {
	campaign
	daily
	random_lab
	designer
}

pub enum GameStatus {
	playing
	won
	lost
	stage_cleared
}

pub enum TileType {
	floor = 0
	wall = 1
	tree = 2
	water = 3
	grass = 4
	sand = 5
	heart = 6
	heart_ammo = 7
	chest_closed = 8
	chest_opened = 9
	door_closed = 10
	door_open = 11
	one_way_up = 12
	one_way_down = 13
	one_way_left = 14
	one_way_right = 15
	portal_a = 16
	portal_b = 17
	ice = 18
	cracked_wall = 19
	lava = 20
	slime = 21
	high_grass = 22
	pressure_plate_cyan = 23
	pressure_plate_magenta = 24
	laser_gate_cyan = 25
	laser_gate_magenta = 26
	blink_floor = 27
	shatter_glass = 28
	turret_socket = 29
}

pub enum BlockType {
	alloy
	heavy
	reflector
	holo
	bomb
	magnetic
	sticky
	fragile
	decoy
	ice
	cracked
	warp
}

pub fn block_type_from_string(s string) BlockType {
	return match s {
		'heavy' { .heavy }
		'reflector' { .reflector }
		'holo' { .holo }
		'bomb' { .bomb }
		'magnetic' { .magnetic }
		'sticky' { .sticky }
		'fragile' { .fragile }
		'decoy' { .decoy }
		'ice' { .ice }
		'cracked' { .cracked }
		'warp' { .warp }
		else { .alloy }
	}
}

pub fn (b BlockType) to_string() string {
	return match b {
		.alloy { 'alloy' }
		.heavy { 'heavy' }
		.reflector { 'reflector' }
		.holo { 'holo' }
		.bomb { 'bomb' }
		.magnetic { 'magnetic' }
		.sticky { 'sticky' }
		.fragile { 'fragile' }
		.decoy { 'decoy' }
		.ice { 'ice' }
		.cracked { 'cracked' }
		.warp { 'warp' }
	}
}

pub enum EnemyType {
	snake
	turret
	medusa
	medusa_diag
	medusa_omni
	don_medusa
	gol
	leeper
	skull
	alma
	rocky
	moby
	hopper
	tesla_sentinel
}

pub fn enemy_type_from_string(s string) EnemyType {
	return match s {
		'turret' { .turret }
		'medusa' { .medusa }
		'medusa_diag' { .medusa_diag }
		'medusa_omni' { .medusa_omni }
		'don_medusa' { .don_medusa }
		'gol' { .gol }
		'leeper' { .leeper }
		'skull' { .skull }
		'alma' { .alma }
		'rocky' { .rocky }
		'moby' { .moby }
		'hopper' { .hopper }
		'tesla_sentinel' { .tesla_sentinel }
		else { .snake }
	}
}

pub fn (e EnemyType) to_string() string {
	return match e {
		.snake { 'snake' }
		.turret { 'turret' }
		.medusa { 'medusa' }
		.medusa_diag { 'medusa_diag' }
		.medusa_omni { 'medusa_omni' }
		.don_medusa { 'don_medusa' }
		.gol { 'gol' }
		.leeper { 'leeper' }
		.skull { 'skull' }
		.alma { 'alma' }
		.rocky { 'rocky' }
		.moby { 'moby' }
		.hopper { 'hopper' }
		.tesla_sentinel { 'tesla_sentinel' }
	}
}

pub enum Direction {
	up
	down
	left
	right
	up_left
	up_right
	down_left
	down_right
}

pub fn dir_from_string(s string) Direction {
	return match s {
		'up' { .up }
		'left' { .left }
		'right' { .right }
		'up_left' { .up_left }
		'up_right' { .up_right }
		'down_left' { .down_left }
		'down_right' { .down_right }
		else { .down }
	}
}

pub fn (d Direction) to_offset() (int, int) {
	return match d {
		.up { 0, -1 }
		.down { 0, 1 }
		.left { -1, 0 }
		.right { 1, 0 }
		.up_left { -1, -1 }
		.up_right { 1, -1 }
		.down_left { -1, 1 }
		.down_right { 1, 1 }
	}
}

// --------------------------------------------------
// Core Game Entities
// --------------------------------------------------


pub struct Lolo {
pub mut:
	x        int
	y        int
	dir      Direction = .down
	ammo     int
	is_dead  bool
	render_x f32
	render_y f32
}

pub struct Block {
pub mut:
	x        int
	y        int
	typ      BlockType = .alloy
	dir      string
	render_x f32
	render_y f32
}

pub struct Enemy {
pub mut:
	typ          EnemyType = .snake
	x            int
	y            int
	dir          Direction = .down
	dirs         []Direction
	axis         string
	range_min    int
	range_max    int
	patrol_dir   int       = 1
	is_egg       bool
	egg_timer    f64
	is_asleep    bool
	is_vaporized bool
	render_x     f32
	render_y     f32
}

pub struct Projectile {
pub mut:
	curr_x f32
	curr_y f32
	dx     f32
	dy     f32
	dir    Direction
	active bool
}

pub struct LaserSegment {
pub mut:
	x1      int
	y1      int
	x2      int
	y2      int
	color_r u8
	color_g u8
	color_b u8
}

pub struct Particle {
pub mut:
	x        f32
	y        f32
	vx       f32
	vy       f32
	life     f32
	max_life f32
	size     f32
	r        u8
	g        u8
	b        u8
}

pub struct FloatingText {
pub mut:
	text string
	x    f32
	y    f32
	vy   f32
	life f32
	r    u8
	g    u8
	b    u8
}

pub struct HolographicGhost {
pub mut:
	active      bool
	waypoints   []Point
	current_idx int
	progress    f32
	speed       f32 = 4.0
	ghost_x     f32
	ghost_y     f32
}

pub struct PressurePlates {
pub mut:
	cyan    bool
	magenta bool
}

pub struct GameSnapshot {
pub:
	lolo_x        int
	lolo_y        int
	lolo_dir      Direction
	ammo          int
	moves_count   int
	chest_open    bool
	door_open     bool
	grid          [][]TileType
	blocks        []Block
	enemies       []Enemy
	pressure_cyan bool
	pressure_mag  bool
}

pub struct Level {
pub mut:
	id          int
	name        string
	grid_size   int
	grid        [][]TileType
	lolo        Point
	blocks      []Block
	enemies     []Enemy
	solver_path []string
}

pub fn level_from_def(def LevelDef) Level {
	mut g := [][]TileType{cap: def.grid.len}
	for row in def.grid {
		mut r := []TileType{cap: row.len}
		for cell in row {
			r << unsafe { TileType(cell) }
		}
		g << r
	}
	mut blks := []Block{cap: def.blocks.len}
	for b in def.blocks {
		blks << Block{
			x: b.x
			y: b.y
			typ: block_type_from_string(b.typ)
			dir: b.dir
			render_x: f32(b.x)
			render_y: f32(b.y)
		}
	}
	mut enms := []Enemy{cap: def.enemies.len}
	for e in def.enemies {
		mut dirs := []Direction{cap: e.dirs.len}
		for d in e.dirs {
			dirs << dir_from_string(d)
		}
		enms << Enemy{
			typ: enemy_type_from_string(e.typ)
			x: e.x
			y: e.y
			dir: dir_from_string(e.dir)
			dirs: dirs
			axis: e.axis
			range_min: e.range_min
			range_max: e.range_max
			patrol_dir: 1
			render_x: f32(e.x)
			render_y: f32(e.y)
		}
	}
	return Level{
		id: def.id
		name: def.name
		grid_size: def.grid_size
		grid: g
		lolo: Point{ x: def.lolo.x, y: def.lolo.y }
		blocks: blks
		enemies: enms
		solver_path: def.solver_path.clone()
	}
}

pub fn get_sector_for_stage(stage_id int) (int, string) {
	sector_num := (stage_id - 1) / 10 + 1
	sector_names := [
		'Infiltration Perimeter',
		'Laser Prism Deflection',
		'Patrol Corridor Sweeps',
		'Sub-Space Quantum Matrix',
		'Omni-Sentry Containment',
		'Hydraulic Vortex Systems',
		'High-Velocity Drone Core',
		'Labyrinthine Multi-Vault',
		'Mastermind Security Gauntlet',
		'Grand Cyber Citadel Apex',
	]
	idx := if sector_num >= 1 && sector_num <= 10 { sector_num - 1 } else { 0 }
	return sector_num, sector_names[idx]
}

// --------------------------------------------------
// Game Manager Struct
// --------------------------------------------------

pub struct Game {
pub mut:
	campaign_levels      []Level
	current_level_idx    int
	active_level         Level
	grid                 [][]TileType
	grid_size            int = 11
	lolo                 Lolo
	blocks               []Block
	enemies              []Enemy
	projectiles          []Projectile
	laser_segments       []LaserSegment
	particles            []Particle
	floating_texts       []FloatingText
	pressure_plates      PressurePlates
	blink_phase          bool = true
	blink_timer          f64
	shatter_steps        map[string]int
	electrified_water    map[string]bool
	undo_stack           []GameSnapshot
	ghost                HolographicGhost
	mode                 GameMode   = .campaign
	status               GameStatus = .playing
	moves_count          int
	time_elapsed         f64
	shots_fired          int
	undone_count         int
	score                int
	lives                int = 5
	screen_shake         f32
	trauma               f32
	save_data            LoloSaveData
	// Overlays & UI Navigation
	level_selector_open  bool
	level_selector_page  int
	sector_map_open      bool
	field_manual_open    bool
	manual_tab           int
	random_dialog_open   bool
	designer_open        bool
	designer_tool        int // 0: floor, 1: wall, 2: tree, 3: block, 4: heart, 5: snake, etc.
	status_msg           string
	status_msg_timer     f64
	// Animation & expression timers
	anim_tick            u32
	push_strain_timer    int
	last_move_tick       u32
	// Sound callbacks queue
	sound_event_queue    []string
}

pub fn new_game() Game {
	defs := get_campaign_level_defs()
	mut levels := []Level{cap: defs.len}
	for d in defs {
		levels << level_from_def(d)
	}

	save := load_lolo_save()

	mut g := Game{
		campaign_levels: levels
		current_level_idx: 0
		save_data: save
	}

	if levels.len > 0 {
		g.init_level(levels[0])
	}
	return g
}

pub fn (mut g Game) init_level(lvl Level) {
	g.active_level = lvl
	g.grid_size = lvl.grid_size
	g.grid = lvl.grid.clone()
	g.lolo = Lolo{
		x: lvl.lolo.x
		y: lvl.lolo.y
		dir: .down
		ammo: 0
		render_x: f32(lvl.lolo.x)
		render_y: f32(lvl.lolo.y)
	}

	g.blocks.clear()
	for b in lvl.blocks {
		g.blocks << Block{
			x: b.x
			y: b.y
			typ: b.typ
			dir: b.dir
			render_x: f32(b.x)
			render_y: f32(b.y)
		}
	}

	g.enemies.clear()
	for e in lvl.enemies {
		g.enemies << Enemy{
			typ: e.typ
			x: e.x
			y: e.y
			dir: e.dir
			dirs: e.dirs.clone()
			axis: e.axis
			range_min: e.range_min
			range_max: e.range_max
			patrol_dir: 1
			render_x: f32(e.x)
			render_y: f32(e.y)
		}
	}

	g.projectiles.clear()
	g.laser_segments.clear()
	g.particles.clear()
	g.floating_texts.clear()
	g.shatter_steps.clear()
	g.electrified_water.clear()
	g.undo_stack.clear()
	g.ghost.active = false
	g.ghost.waypoints.clear()

	g.pressure_plates.cyan = false
	g.pressure_plates.magenta = false
	g.blink_phase = true
	g.blink_timer = 0
	g.moves_count = 0
	g.time_elapsed = 0
	g.shots_fired = 0
	g.undone_count = 0
	g.status = .playing
	g.trauma = 0
	g.screen_shake = 0

	sector_num, sector_title := get_sector_for_stage(lvl.id)
	g.status_msg = 'SECTOR ${sector_num}: ${sector_title} // ${lvl.name}'
	g.status_msg_timer = 3.5

	g.save_snapshot()
	g.calculate_lasers()
}

pub fn (mut g Game) load_level(idx int) {
	if idx >= 0 && idx < g.campaign_levels.len {
		g.current_level_idx = idx
		g.save_data.current_level = idx
		save_lolo_data(&g.save_data)
		g.init_level(g.campaign_levels[idx])
	}
}

pub fn (mut g Game) restart_level() {
	if g.mode == .campaign && g.current_level_idx < g.campaign_levels.len {
		g.init_level(g.campaign_levels[g.current_level_idx])
	} else {
		g.init_level(g.active_level)
	}
	g.sound_event_queue << 'warp'
}

pub fn (mut g Game) next_level() {
	if g.current_level_idx + 1 < g.campaign_levels.len {
		g.load_level(g.current_level_idx + 1)
	} else {
		g.status = .won
	}
}

pub fn (mut g Game) prev_level() {
	if g.current_level_idx > 0 {
		g.load_level(g.current_level_idx - 1)
	}
}

// --------------------------------------------------
// Snapshot & Undo System
// --------------------------------------------------

pub fn (mut g Game) save_snapshot() {
	snap := GameSnapshot{
		lolo_x: g.lolo.x
		lolo_y: g.lolo.y
		lolo_dir: g.lolo.dir
		ammo: g.lolo.ammo
		moves_count: g.moves_count
		chest_open: g.is_chest_open()
		door_open: g.is_door_open()
		grid: g.grid.clone()
		blocks: g.blocks.clone()
		enemies: g.enemies.clone()
		pressure_cyan: g.pressure_plates.cyan
		pressure_mag: g.pressure_plates.magenta
	}
	g.undo_stack << snap
	if g.undo_stack.len > 100 {
		g.undo_stack.delete(0)
	}
}

pub fn (mut g Game) undo() bool {
	if g.undo_stack.len <= 1 {
		return false
	}
	// Pop current state
	g.undo_stack.pop()
	snap := g.undo_stack.last()

	g.lolo.x = snap.lolo_x
	g.lolo.y = snap.lolo_y
	g.lolo.dir = snap.lolo_dir
	g.lolo.render_x = f32(snap.lolo_x)
	g.lolo.render_y = f32(snap.lolo_y)
	g.lolo.ammo = snap.ammo
	g.moves_count = snap.moves_count
	g.grid = snap.grid.clone()
	g.blocks = snap.blocks.clone()
	g.enemies = snap.enemies.clone()
	g.pressure_plates.cyan = snap.pressure_cyan
	g.pressure_plates.magenta = snap.pressure_mag
	g.undone_count++
	g.status = .playing
	g.lolo.is_dead = false

	g.spawn_floating_text('TEMPORAL REWIND', f32(g.lolo.x), f32(g.lolo.y), 0, 240, 255)
	g.calculate_lasers()
	return true
}

// --------------------------------------------------
// Query Helpers
// --------------------------------------------------

pub fn (g &Game) count_remaining_hearts() int {
	mut count := 0
	for row in g.grid {
		for cell in row {
			if cell == .heart || cell == .heart_ammo {
				count++
			}
		}
	}
	return count
}

pub fn (g &Game) count_total_hearts() int {
	mut count := 0
	for row in g.active_level.grid {
		for cell in row {
			if cell == .heart || cell == .heart_ammo {
				count++
			}
		}
	}
	return count
}

pub fn (g &Game) is_chest_open() bool {
	for row in g.grid {
		for cell in row {
			if cell == .chest_opened {
				return true
			}
		}
	}
	return false
}

pub fn (g &Game) is_door_open() bool {
	for row in g.grid {
		for cell in row {
			if cell == .door_open {
				return true
			}
		}
	}
	return false
}

pub fn (g &Game) get_block_at(x int, y int) ?Block {
	for b in g.blocks {
		if b.x == x && b.y == y {
			return b
		}
	}
	return none
}

pub fn (g &Game) get_enemy_at(x int, y int) ?Enemy {
	for e in g.enemies {
		if !e.is_vaporized && e.x == x && e.y == y {
			return e
		}
	}
	return none
}

pub fn (g &Game) is_enemy_passable(x int, y int) bool {
	if x < 1 || x >= g.grid_size - 1 || y < 1 || y >= g.grid_size - 1 {
		return false
	}
	tile := g.grid[y][x]
	if tile in [.wall, .tree, .cracked_wall, .water, .lava, .door_closed, .door_open, .chest_closed, .chest_opened, .heart, .heart_ammo] {
		return false
	}
	if _ := g.get_block_at(x, y) {
		return false
	}
	if _ := g.get_enemy_at(x, y) {
		return false
	}
	return true
}

// --------------------------------------------------
// Lolo Movement & Interactions
// --------------------------------------------------

pub fn (mut g Game) move_lolo(dir Direction) bool {
	if g.status != .playing || g.lolo.is_dead {
		return false
	}
	dx, dy := dir.to_offset()
	if dx == 0 && dy == 0 {
		return false
	}

	g.lolo.dir = dir
	target_x := g.lolo.x + dx
	target_y := g.lolo.y + dy

	if target_x < 0 || target_x >= g.grid_size || target_y < 0 || target_y >= g.grid_size {
		return false
	}

	tile := g.grid[target_y][target_x]
	block_opt := g.get_block_at(target_x, target_y)
	enemy_opt := g.get_enemy_at(target_x, target_y)

	// Static obstructions
	if tile in [.wall, .tree, .cracked_wall, .water, .lava, .chest_closed, .door_closed] {
		return false
	}

	// Laser Gate Check
	if tile == .laser_gate_cyan && !g.pressure_plates.cyan {
		g.sound_event_queue << 'dry_fire'
		g.spawn_floating_text('GATE ARMED', f32(target_x), f32(target_y), 0, 240, 255)
		return false
	}
	if tile == .laser_gate_magenta && !g.pressure_plates.magenta {
		g.sound_event_queue << 'dry_fire'
		g.spawn_floating_text('GATE ARMED', f32(target_x), f32(target_y), 255, 0, 127)
		return false
	}

	// De-phased Blink Floor
	if tile == .blink_floor && !g.blink_phase {
		g.sound_event_queue << 'dry_fire'
		return false
	}

	// Force Floor Conveyors
	if tile == .one_way_up && dy > 0 { return false }
	if tile == .one_way_down && dy < 0 { return false }
	if tile == .one_way_left && dx > 0 { return false }
	if tile == .one_way_right && dx < 0 { return false }

	// Quantum Portals
	if tile == .portal_a || tile == .portal_b {
		target_portal_tile := if tile == .portal_a { TileType.portal_b } else { TileType.portal_a }
		mut dest_x := -1
		mut dest_y := -1
		for r in 0 .. g.grid_size {
			for c in 0 .. g.grid_size {
				if g.grid[r][c] == target_portal_tile {
					dest_x = c
					dest_y = r
					break
				}
			}
			if dest_x != -1 { break }
		}

		if dest_x != -1 && g.get_block_at(dest_x, dest_y) == none && g.get_enemy_at(dest_x, dest_y) == none {
			g.save_snapshot()
			g.lolo.x = dest_x
			g.lolo.y = dest_y
			g.lolo.render_x = f32(dest_x)
			g.lolo.render_y = f32(dest_y)
			g.moves_count++
			g.sound_event_queue << 'warp'
			g.spawn_burst(f32(dest_x), f32(dest_y), 0, 240, 255, 20)
			g.spawn_floating_text('QUANTUM WARP', f32(dest_x), f32(dest_y), 0, 240, 255)
			g.post_move_check()
			return true
		}
		return false
	}

	// Push Block
	if b := block_opt {
		if b.typ == .heavy || b.typ == .holo {
			return false
		}
		push_x := target_x + dx
		push_y := target_y + dy
		if push_x < 0 || push_x >= g.grid_size || push_y < 0 || push_y >= g.grid_size {
			return false
		}

		push_tile := g.grid[push_y][push_x]
		if g.get_block_at(push_x, push_y) != none || g.get_enemy_at(push_x, push_y) != none {
			return false
		}

		// Bomb pushing into cracked wall -> Nitro Detonation!
		if b.typ == .bomb && push_tile == .cracked_wall {
			g.save_snapshot()
			g.detonate_bomb(b)
			g.lolo.x = target_x
			g.lolo.y = target_y
			g.moves_count++
			g.post_move_check()
			return true
		}

		// Block pushing into Water or Lava -> Creates a Bridge!
		if push_tile == .water || push_tile == .lava {
			g.save_snapshot()
			bridge_tile := if push_tile == .lava { TileType.sand } else { TileType.grass }
			g.grid[push_y][push_x] = bridge_tile
			// Remove block
			for i, blk in g.blocks {
				if blk.x == b.x && blk.y == b.y {
					g.blocks.delete(i)
					break
				}
			}
			g.lolo.x = target_x
			g.lolo.y = target_y
			g.moves_count++
			g.push_strain_timer = 15
			g.sound_event_queue << 'push'
			g.spawn_burst(f32(push_x), f32(push_y), 0, 240, 255, 16)
			g.post_move_check()
			return true
		}

		// Block slide on Ice
		if push_tile == .ice {
			g.save_snapshot()
			mut final_x := push_x
			mut final_y := push_y
			for {
				nx := final_x + dx
				ny := final_y + dy
				if nx < 1 || nx >= g.grid_size - 1 || ny < 1 || ny >= g.grid_size - 1 {
					break
				}
				nt := g.grid[ny][nx]
				if nt in [.wall, .tree, .cracked_wall, .water, .lava] || g.get_block_at(nx, ny) != none || g.get_enemy_at(nx, ny) != none {
					break
				}
				final_x = nx
				final_y = ny
				if nt != .ice { break }
			}
			for mut blk in g.blocks {
				if blk.x == b.x && blk.y == b.y {
					blk.x = final_x
					blk.y = final_y
					break
				}
			}
			g.lolo.x = target_x
			g.lolo.y = target_y
			g.moves_count++
			g.push_strain_timer = 15
			g.sound_event_queue << 'slide'
			g.post_move_check()
			return true
		}

		// Free Floor push
		is_free := push_tile in [.floor, .grass, .sand, .slime, .high_grass, .pressure_plate_cyan, .pressure_plate_magenta, .turret_socket]
		if is_free {
			g.save_snapshot()
			for mut blk in g.blocks {
				if blk.x == b.x && blk.y == b.y {
					blk.x = push_x
					blk.y = push_y
					break
				}
			}
			g.lolo.x = target_x
			g.lolo.y = target_y
			g.moves_count++
			g.push_strain_timer = 15
			g.sound_event_queue << 'push'
			g.post_move_check()
			return true
		}
		return false
	}

	// Enemy Interaction / Egg Push
	if e := enemy_opt {
		if e.is_egg {
			push_x := target_x + dx
			push_y := target_y + dy
			if push_x < 0 || push_x >= g.grid_size || push_y < 0 || push_y >= g.grid_size {
				return false
			}
			push_tile := g.grid[push_y][push_x]
			if g.get_block_at(push_x, push_y) != none || g.get_enemy_at(push_x, push_y) != none {
				return false
			}

			// Push egg into Water or Lava -> Becomes Bridge / Floating Raft!
			if push_tile == .water || push_tile == .lava {
				g.save_snapshot()
				g.grid[push_y][push_x] = if push_tile == .lava { TileType.sand } else { TileType.grass }
				for mut enm in g.enemies {
					if enm.x == e.x && enm.y == e.y {
						enm.is_vaporized = true
						break
					}
				}
				g.lolo.x = target_x
				g.lolo.y = target_y
				g.moves_count++
				g.sound_event_queue << 'push'
				g.spawn_burst(f32(push_x), f32(push_y), 0, 240, 255, 16)
				g.post_move_check()
				return true
			}

			// Push egg onto Turret Socket -> Clamped into Defense Cannon!
			if push_tile == .turret_socket {
				g.save_snapshot()
				for mut enm in g.enemies {
					if enm.x == e.x && enm.y == e.y {
						enm.x = push_x
						enm.y = push_y
						enm.is_asleep = true
						break
					}
				}
				g.lolo.x = target_x
				g.lolo.y = target_y
				g.moves_count++
				g.sound_event_queue << 'push'
				g.spawn_floating_text('TURRET CLAMPED', f32(push_x), f32(push_y), 255, 215, 0)
				g.post_move_check()
				return true
			}

			// Push egg onto free floor
			is_free := push_tile in [.floor, .grass, .sand, .slime, .high_grass, .ice, .pressure_plate_cyan, .pressure_plate_magenta]
			if is_free {
				g.save_snapshot()
				for mut enm in g.enemies {
					if enm.x == e.x && enm.y == e.y {
						enm.x = push_x
						enm.y = push_y
						break
					}
				}
				g.lolo.x = target_x
				g.lolo.y = target_y
				g.moves_count++
				g.sound_event_queue << 'push'
				g.post_move_check()
				return true
			}
			return false
		} else {
			// Non-egg enemy: Leeper sleeps on contact
			if e.typ == .leeper && !e.is_asleep {
				g.save_snapshot()
				for mut enm in g.enemies {
					if enm.x == e.x && enm.y == e.y {
						enm.is_asleep = true
						enm.is_egg = true
						break
					}
				}
				g.sound_event_queue << 'egg'
				g.spawn_floating_text('LEEPER ASLEEP', f32(e.x), f32(e.y), 0, 240, 255)
				return false
			}
			return false
		}
	}

	// Move Lolo to free floor tile
	g.save_snapshot()
	g.lolo.x = target_x
	g.lolo.y = target_y
	g.moves_count++
	g.sound_event_queue << 'step'

	// Collect Heart Framer
	if tile == .heart || tile == .heart_ammo {
		if tile == .heart_ammo {
			g.lolo.ammo += 2
			g.sound_event_queue << 'powerup'
			g.spawn_floating_text('+2 AMMO', f32(target_x), f32(target_y), 255, 215, 0)
		} else {
			g.sound_event_queue << 'heart'
			g.spawn_floating_text('+MEMORY CORE', f32(target_x), f32(target_y), 0, 240, 255)
		}
		g.grid[target_y][target_x] = .floor
		g.score += 100
		g.spawn_burst(f32(target_x), f32(target_y), 255, 0, 127, 14)

		// Check if all hearts collected -> Unlock Key Vault Chest!
		if g.count_remaining_hearts() == 0 {
			for r in 0 .. g.grid_size {
				for c in 0 .. g.grid_size {
					if g.grid[r][c] == .chest_closed {
						g.grid[r][c] = .chest_opened
						g.sound_event_queue << 'chest'
						g.spawn_floating_text('QUANTUM CHEST UNLOCKED!', f32(c), f32(r), 255, 215, 0)
						g.spawn_burst(f32(c), f32(r), 255, 215, 0, 25)
					}
				}
			}
		}
	}

	// Step on Open Chest -> Secure Quantum Key!
	if tile == .chest_opened {
		g.grid[target_y][target_x] = .floor
		g.sound_event_queue << 'victory'
		g.spawn_floating_text('QUANTUM KEY SECURED!', f32(target_x), f32(target_y), 0, 240, 255)
		// Neutralize all active hostiles
		for mut enm in g.enemies {
			enm.is_asleep = true
		}
		// Open extraction door
		for r in 0 .. g.grid_size {
			for c in 0 .. g.grid_size {
				if g.grid[r][c] == .door_closed {
					g.grid[r][c] = .door_open
					g.spawn_floating_text('EXTRACTION GATE OPEN!', f32(c), f32(r), 0, 255, 127)
					g.spawn_burst(f32(c), f32(r), 0, 255, 127, 24)
				}
			}
		}
	}

	// Step through Open Door -> Stage Clear Orbital Teleport!
	if tile == .door_open {
		g.status = .stage_cleared
		g.sound_event_queue << 'warp'
		g.spawn_floating_text('STAGE COMPLETE // ORBITAL BEAM', f32(target_x), f32(target_y), 0, 240, 255)
		g.spawn_burst(f32(target_x), f32(target_y), 0, 240, 255, 30)
		if g.current_level_idx >= g.save_data.max_level_unlocked {
			g.save_data.max_level_unlocked = g.current_level_idx + 1
		}
		g.save_data.current_level = g.current_level_idx + 1
		save_lolo_data(&g.save_data)
		return true
	}

	// Mag-Lev Ice Slide
	if tile == .ice {
		g.sound_event_queue << 'slide'
		mut final_x := target_x
		mut final_y := target_y
		for {
			nx := final_x + dx
			ny := final_y + dy
			if nx < 1 || nx >= g.grid_size - 1 || ny < 1 || ny >= g.grid_size - 1 {
				break
			}
			nt := g.grid[ny][nx]
			if nt in [.wall, .tree, .cracked_wall, .water, .lava, .chest_closed, .door_closed] || g.get_block_at(nx, ny) != none || g.get_enemy_at(nx, ny) != none {
				break
			}
			final_x = nx
			final_y = ny
			if nt != .ice { break }
		}
		g.lolo.x = final_x
		g.lolo.y = final_y
	}

	// Shatter Glass Panel
	if tile == .shatter_glass {
		key := '${target_x},${target_y}'
		steps := g.shatter_steps[key] or { 0 } + 1
		g.shatter_steps[key] = steps
		if steps >= 2 {
			g.grid[target_y][target_x] = .water
			g.sound_event_queue << 'push'
			g.spawn_floating_text('GLASS COLLAPSED', f32(target_x), f32(target_y), 255, 100, 100)
		} else {
			g.spawn_floating_text('GLASS STRESSED', f32(target_x), f32(target_y), 255, 200, 100)
		}
	}

	g.post_move_check()
	return true
}

pub fn (mut g Game) post_move_check() {
	g.last_move_tick = g.anim_tick
	// Update Pressure Plates
	mut has_cyan := false
	mut has_magenta := false
	for b in g.blocks {
		tile := g.grid[b.y][b.x]
		if tile == .pressure_plate_cyan { has_cyan = true }
		if tile == .pressure_plate_magenta { has_magenta = true }
	}
	for e in g.enemies {
		if !e.is_vaporized {
			tile := g.grid[e.y][e.x]
			if tile == .pressure_plate_cyan { has_cyan = true }
			if tile == .pressure_plate_magenta { has_magenta = true }
		}
	}
	lolo_tile := g.grid[g.lolo.y][g.lolo.x]
	if lolo_tile == .pressure_plate_cyan { has_cyan = true }
	if lolo_tile == .pressure_plate_magenta { has_magenta = true }

	if has_cyan != g.pressure_plates.cyan {
		g.pressure_plates.cyan = has_cyan
		g.sound_event_queue << 'plate'
	}
	if has_magenta != g.pressure_plates.magenta {
		g.pressure_plates.magenta = has_magenta
		g.sound_event_queue << 'plate'
	}

	// Hostile AI update step
	g.update_hostiles_on_move()
	g.calculate_lasers()
}

// --------------------------------------------------
// Hostile AI & Laser Sightlines
// --------------------------------------------------

pub fn (mut g Game) update_hostiles_on_move() {
	if g.status != .playing { return }
	remaining_hearts := g.count_remaining_hearts()

	for mut e in g.enemies {
		if e.is_egg || e.is_vaporized || e.is_asleep { continue }

		// Don Medusa Patrol
		if e.typ == .don_medusa {
			if e.patrol_dir == 0 { e.patrol_dir = 1 }
			mut next_x := e.x
			mut next_y := e.y
			if e.axis == 'horizontal' {
				next_x += e.patrol_dir
				if next_x < e.range_min || next_x > e.range_max || !g.is_enemy_passable(next_x, e.y) {
					e.patrol_dir *= -1
					next_x = e.x + e.patrol_dir
				}
			} else {
				next_y += e.patrol_dir
				if next_y < e.range_min || next_y > e.range_max || !g.is_enemy_passable(e.x, next_y) {
					e.patrol_dir *= -1
					next_y = e.y + e.patrol_dir
				}
			}
			if g.is_enemy_passable(next_x, next_y) {
				e.x = next_x
				e.y = next_y
			}
		}

		// Leeper Chaser
		if e.typ == .leeper && !e.is_asleep {
			dx := if g.lolo.x > e.x { 1 } else if g.lolo.x < e.x { -1 } else { 0 }
			dy := if g.lolo.y > e.y { 1 } else if g.lolo.y < e.y { -1 } else { 0 }
			if dx != 0 && g.is_enemy_passable(e.x + dx, e.y) {
				e.x += dx
			} else if dy != 0 && g.is_enemy_passable(e.x, e.y + dy) {
				e.y += dy
			}
			if e.x == g.lolo.x && e.y == g.lolo.y {
				e.is_asleep = true
				e.is_egg = true
				g.sound_event_queue << 'egg'
			}
		}

		// Awakened Skull Chaser
		if e.typ == .skull && remaining_hearts == 0 {
			if e.x == g.lolo.x || e.y == g.lolo.y {
				dx := if g.lolo.x > e.x { 1 } else if g.lolo.x < e.x { -1 } else { 0 }
				dy := if g.lolo.y > e.y { 1 } else if g.lolo.y < e.y { -1 } else { 0 }
				if dx != 0 && (g.is_enemy_passable(e.x + dx, e.y) || (e.x + dx == g.lolo.x && e.y == g.lolo.y)) {
					e.x += dx
				} else if dy != 0 && (g.is_enemy_passable(e.x, e.y + dy) || (e.x == g.lolo.x && e.y + dy == g.lolo.y)) {
					e.y += dy
				}
				if e.x == g.lolo.x && e.y == g.lolo.y {
					g.kill_lolo('SKULL SENTRY IMPACT')
					return
				}
			}
		}

		// Alma Kinetic Juggernaut
		if e.typ == .alma {
			if e.x == g.lolo.x {
				step := if g.lolo.y > e.y { 1 } else { -1 }
				mut blocked := false
				for cy := e.y + step; cy != g.lolo.y; cy += step {
					if !g.is_enemy_passable(e.x, cy) { blocked = true; break }
				}
				if !blocked {
					e.y += step
					if e.x == g.lolo.x && e.y == g.lolo.y {
						g.kill_lolo('ALMA JUGGERNAUT CHARGE')
						return
					}
				}
			} else if e.y == g.lolo.y {
				step := if g.lolo.x > e.x { 1 } else { -1 }
				mut blocked := false
				for cx := e.x + step; cx != g.lolo.x; cx += step {
					if !g.is_enemy_passable(cx, e.y) { blocked = true; break }
				}
				if !blocked {
					e.x += step
					if e.x == g.lolo.x && e.y == g.lolo.y {
						g.kill_lolo('ALMA JUGGERNAUT CHARGE')
						return
					}
				}
			}
		}

		// Rocky Hydraulic Shover
		if e.typ == .rocky {
			dist := math.abs(g.lolo.x - e.x) + math.abs(g.lolo.y - e.y)
			if dist == 1 {
				dx := if g.lolo.x > e.x { 1 } else if g.lolo.x < e.x { -1 } else { 0 }
				dy := if g.lolo.y > e.y { 1 } else if g.lolo.y < e.y { -1 } else { 0 }
				shove_x := g.lolo.x + dx
				shove_y := g.lolo.y + dy
				if shove_x >= 1 && shove_x < g.grid_size - 1 && shove_y >= 1 && shove_y < g.grid_size - 1 {
					tile := g.grid[shove_y][shove_x]
					if tile in [.floor, .grass, .sand, .ice] && g.get_block_at(shove_x, shove_y) == none && g.get_enemy_at(shove_x, shove_y) == none {
						g.lolo.x = shove_x
						g.lolo.y = shove_y
						g.sound_event_queue << 'push'
						g.screen_shake = 6.0
					}
				}
			}
		}
	}
}

pub fn (mut g Game) calculate_lasers() {
	g.laser_segments.clear()
	if g.status == .won || g.status == .stage_cleared { return }
	remaining_hearts := g.count_remaining_hearts()

	for e in g.enemies {
		if e.is_egg || e.is_vaporized || e.is_asleep { continue }

		mut dirs := []Direction{}
		match e.typ {
			.medusa {
				dirs = [.up, .down, .left, .right]
			}
			.medusa_diag {
				dirs = [.up_left, .up_right, .down_left, .down_right]
			}
			.medusa_omni {
				dirs = [.up, .down, .left, .right, .up_left, .up_right, .down_left, .down_right]
			}
			.turret {
				dirs = e.dirs.clone()
			}
			.don_medusa {
				if e.axis == 'horizontal' {
					dirs = [.up, .down]
				} else {
					dirs = [.left, .right]
				}
			}
			.gol {
				if remaining_hearts == 0 {
					dirs = [.up, .down, .left, .right]
				}
			}
			.tesla_sentinel {
				dirs = [e.dir]
			}
			else {}
		}

		for init_dir in dirs {
			mut cur_x := e.x
			mut cur_y := e.y
			mut cur_dx, mut cur_dy := init_dir.to_offset()
			mut reflections := 4

			for reflections >= 0 {
				reflections--
				mut cx := cur_x + cur_dx
				mut cy := cur_y + cur_dy
				mut sx := cur_x
				mut sy := cur_y
				mut deflected := false

				for cx >= 0 && cx < g.grid_size && cy >= 0 && cy < g.grid_size {
					// Check Lolo hit!
					if cx == g.lolo.x && cy == g.lolo.y {
						g.laser_segments << LaserSegment{
							x1: sx
							y1: sy
							x2: cx
							y2: cy
							color_r: 255
							color_g: 0
							color_b: 60
						}
						g.kill_lolo('OPTICAL DISINTEGRATION BEAM')
						return
					}

					tile := g.grid[cy][cx]

					// Check Block collision
					if b := g.get_block_at(cx, cy) {
						if b.typ == .reflector {
							// Deflect 90 degrees
							g.laser_segments << LaserSegment{
								x1: sx
								y1: sy
								x2: cx
								y2: cy
								color_r: 0
								color_g: 240
								color_b: 255
							}
							cur_x = cx
							cur_y = cy
							// Simple 90-degree mirror deflection
							if cur_dx != 0 {
								cur_dy = if b.dir == 'up_right' { -cur_dx } else { cur_dx }
								cur_dx = 0
							} else if cur_dy != 0 {
								cur_dx = if b.dir == 'up_right' { -cur_dy } else { cur_dy }
								cur_dy = 0
							}
							deflected = true
							break
						} else {
							// Block stops laser
							g.laser_segments << LaserSegment{
								x1: sx
								y1: sy
								x2: cx
								y2: cy
								color_r: 255
								color_g: 50
								color_b: 100
							}
							break
						}
					}

					// Obstacles stopping laser
					if tile in [.wall, .tree, .cracked_wall] {
						g.laser_segments << LaserSegment{
							x1: sx
							y1: sy
							x2: cx
							y2: cy
							color_r: 255
							color_g: 50
							color_b: 100
						}
						break
					}

					// Encased egg stops laser
					if enm := g.get_enemy_at(cx, cy) {
						if enm.is_egg {
							g.laser_segments << LaserSegment{
								x1: sx
								y1: sy
								x2: cx
								y2: cy
								color_r: 255
								color_g: 50
								color_b: 100
							}
							break
						}
					}

					cx += cur_dx
					cy += cur_dy
				}

				if !deflected {
					if cx < 0 || cx >= g.grid_size || cy < 0 || cy >= g.grid_size {
						g.laser_segments << LaserSegment{
							x1: sx
							y1: sy
							x2: int(math.clamp(cx, 0, g.grid_size - 1))
							y2: int(math.clamp(cy, 0, g.grid_size - 1))
							color_r: 255
							color_g: 50
							color_b: 80
						}
					}
					break
				}
			}
		}
	}
}

pub fn (g &Game) is_lolo_in_danger() bool {
	if g.lolo.is_dead || g.status != .playing {
		return false
	}
	remaining_hearts := g.count_remaining_hearts()

	for e in g.enemies {
		if e.is_egg || e.is_vaporized || e.is_asleep {
			continue
		}
		// Proximity threats
		if e.typ in [.leeper, .skull, .alma, .rocky] {
			dist := math.hypot(f64(e.x - g.lolo.x), f64(e.y - g.lolo.y))
			if dist <= 2.2 {
				return true
			}
		}
		// Line of sight threats
		mut dirs := []Direction{}
		match e.typ {
			.medusa {
				dirs = [.up, .down, .left, .right]
			}
			.medusa_diag {
				dirs = [.up_left, .up_right, .down_left, .down_right]
			}
			.medusa_omni {
				dirs = [.up, .down, .left, .right, .up_left, .up_right, .down_left, .down_right]
			}
			.turret {
				dirs = e.dirs.clone()
			}
			.don_medusa {
				if e.axis == 'horizontal' {
					dirs = [.up, .down]
				} else {
					dirs = [.left, .right]
				}
			}
			.gol {
				if remaining_hearts == 0 {
					dirs = [.up, .down, .left, .right]
				}
			}
			.tesla_sentinel {
				dirs = [e.dir]
			}
			else {}
		}

		for init_dir in dirs {
			dx, dy := init_dir.to_offset()
			mut cx := e.x + dx
			mut cy := e.y + dy
			for cx >= 0 && cx < g.grid_size && cy >= 0 && cy < g.grid_size {
				if cx == g.lolo.x && cy == g.lolo.y {
					return true
				}
				tile := g.grid[cy][cx]
				if tile in [.wall, .tree, .cracked_wall, .door_closed, .chest_closed] {
					break
				}
				if tile == .laser_gate_cyan && !g.pressure_plates.cyan {
					break
				}
				if tile == .laser_gate_magenta && !g.pressure_plates.magenta {
					break
				}
				if g.get_block_at(cx, cy) != none {
					break
				}
				mut blocked_by_egg := false
				for other_e in g.enemies {
					if other_e.is_egg && other_e.x == cx && other_e.y == cy {
						blocked_by_egg = true
						break
					}
				}
				if blocked_by_egg {
					break
				}
				cx += dx
				cy += dy
			}
		}
	}
	return false
}

// --------------------------------------------------
// Combat & Weapon Systems
// --------------------------------------------------

pub fn (mut g Game) fire_magic_shot() bool {
	if g.status != .playing || g.lolo.is_dead { return false }
	if g.lolo.ammo <= 0 {
		g.sound_event_queue << 'dry_fire'
		g.spawn_floating_text('EMPTY CHAMBER', f32(g.lolo.x), f32(g.lolo.y), 255, 60, 60)
		return false
	}

	g.lolo.ammo--
	g.shots_fired++
	g.sound_event_queue << 'shot'

	dx, dy := g.lolo.dir.to_offset()
	mut cx := g.lolo.x + dx
	mut cy := g.lolo.y + dy

	for cx >= 0 && cx < g.grid_size && cy >= 0 && cy < g.grid_size {
		tile := g.grid[cy][cx]
		if tile in [.wall, .tree, .high_grass, .cracked_wall] || g.get_block_at(cx, cy) != none {
			g.spawn_burst(f32(cx), f32(cy), 0, 240, 255, 10)
			break
		}

		if mut enm := g.get_enemy_at(cx, cy) {
			if !enm.is_egg {
				// 1st Shot: Stasis Encased Egg
				for mut e in g.enemies {
					if e.x == enm.x && e.y == enm.y {
						e.is_egg = true
						e.egg_timer = 20.0
						break
					}
				}
				g.sound_event_queue << 'egg'
				g.spawn_burst(f32(cx), f32(cy), 0, 240, 255, 18)
				g.spawn_floating_text('STASIS ENCASED', f32(cx), f32(cy), 0, 240, 255)
			} else {
				// 2nd Shot: Disintegrate Egg
				for mut e in g.enemies {
					if e.x == enm.x && e.y == enm.y {
						e.is_vaporized = true
						break
					}
				}
				g.sound_event_queue << 'death'
				g.spawn_burst(f32(cx), f32(cy), 255, 0, 127, 24)
				g.spawn_floating_text('DISINTEGRATED', f32(cx), f32(cy), 255, 0, 127)
			}
			break
		}
		cx += dx
		cy += dy
	}
	return true
}

pub fn (mut g Game) detonate_bomb(bomb Block) {
	bx := bomb.x
	by := bomb.y
	g.sound_event_queue << 'bomb'
	g.trauma = 0.95
	g.screen_shake = 15.0
	g.spawn_burst(f32(bx), f32(by), 255, 120, 0, 36)
	g.spawn_floating_text('NITRO DETONATION', f32(bx), f32(by), 255, 80, 0)

	// Remove bomb block
	for i, b in g.blocks {
		if b.x == bx && b.y == by {
			g.blocks.delete(i)
			break
		}
	}

	// 3x3 blast radius
	for r in by - 1 .. by + 2 {
		for c in bx - 1 .. bx + 2 {
			if r < 0 || r >= g.grid_size || c < 0 || c >= g.grid_size { continue }
			if g.grid[r][c] == .cracked_wall {
				g.grid[r][c] = .floor
				g.spawn_burst(f32(c), f32(r), 0, 240, 255, 12)
			}
			if g.grid[r][c] == .slime {
				g.grid[r][c] = .floor
				g.spawn_burst(f32(c), f32(r), 0, 255, 100, 12)
			}
		}
	}
}

pub fn (mut g Game) kill_lolo(reason string) {
	g.status = .lost
	g.lolo.is_dead = true
	g.trauma = 1.0
	g.screen_shake = 16.0
	g.sound_event_queue << 'death'
	g.spawn_burst(f32(g.lolo.x), f32(g.lolo.y), 255, 0, 60, 30)
	g.spawn_floating_text('PURGED // ${reason}', f32(g.lolo.x), f32(g.lolo.y), 255, 0, 60)
}

// --------------------------------------------------
// Real-Time Solver & Ghost Guide
// --------------------------------------------------

pub fn (mut g Game) toggle_ghost_guide() {
	if g.ghost.active {
		g.ghost.active = false
		g.spawn_floating_text('GHOST GUIDE: OFF', f32(g.lolo.x), f32(g.lolo.y), 150, 150, 150)
		return
	}

	// Use level pre-computed solver path if available
	if g.active_level.solver_path.len > 0 && g.moves_count == 0 {
		mut pts := []Point{cap: g.active_level.solver_path.len + 1}
		mut cur_x := g.lolo.x
		mut cur_y := g.lolo.y
		pts << Point{ x: cur_x, y: cur_y }
		for step in g.active_level.solver_path {
			match step {
				'U' { cur_y-- }
				'D' { cur_y++ }
				'L' { cur_x-- }
				'R' { cur_x++ }
				else {}
			}
			pts << Point{ x: cur_x, y: cur_y }
		}
		g.ghost.waypoints = pts
		g.ghost.active = true
		g.ghost.current_idx = 0
		g.ghost.progress = 0
		g.ghost.ghost_x = f32(g.lolo.x)
		g.ghost.ghost_y = f32(g.lolo.y)
		g.spawn_floating_text('HOLOGRAPHIC GHOST: ENGAGED', f32(g.lolo.x), f32(g.lolo.y), 0, 240, 255)
		return
	}

	// Dynamic BFS solver from current position
	path := g.solve_bfs(g.lolo.x, g.lolo.y, 4000)
	if path.len > 0 {
		mut pts := []Point{cap: path.len + 1}
		mut cur_x := g.lolo.x
		mut cur_y := g.lolo.y
		pts << Point{ x: cur_x, y: cur_y }
		for step in path {
			match step {
				'U' { cur_y-- }
				'D' { cur_y++ }
				'L' { cur_x-- }
				'R' { cur_x++ }
				else {}
			}
			pts << Point{ x: cur_x, y: cur_y }
		}
		g.ghost.waypoints = pts
		g.ghost.active = true
		g.ghost.current_idx = 0
		g.ghost.progress = 0
		g.ghost.ghost_x = f32(g.lolo.x)
		g.ghost.ghost_y = f32(g.lolo.y)
		g.spawn_floating_text('HOLOGRAPHIC GHOST: COMPUTED', f32(g.lolo.x), f32(g.lolo.y), 0, 240, 255)
	} else {
		g.spawn_floating_text('SOLVER: PATH BLOCKED', f32(g.lolo.x), f32(g.lolo.y), 255, 100, 100)
	}
}

struct SolverNode {
	x    int
	y    int
	path []string
}

struct DirStep {
	name string
	dx   int
	dy   int
}

fn (g &Game) solve_bfs(start_x int, start_y int, max_states int) []string {
	mut queue := []SolverNode{}
	queue << SolverNode{ x: start_x, y: start_y, path: []string{} }
	mut visited := map[string]bool{}
	visited['${start_x},${start_y}'] = true

	dirs := [
		DirStep{ name: 'U', dx: 0, dy: -1 },
		DirStep{ name: 'D', dx: 0, dy: 1 },
		DirStep{ name: 'L', dx: -1, dy: 0 },
		DirStep{ name: 'R', dx: 1, dy: 0 },
	]

	mut q_head := 0
	for q_head < queue.len && q_head < max_states {
		node := queue[q_head]
		q_head++

		// Goal: reach opened chest or door
		tile := g.grid[node.y][node.x]
		if tile == .chest_opened || tile == .door_open {
			return node.path
		}

		for d in dirs {
			nx := node.x + d.dx
			ny := node.y + d.dy
			if nx < 1 || nx >= g.grid_size - 1 || ny < 1 || ny >= g.grid_size - 1 { continue }
			key := '${nx},${ny}'
			if visited[key] { continue }

			nt := g.grid[ny][nx]
			if nt in [.wall, .tree, .cracked_wall, .water, .lava, .chest_closed, .door_closed] { continue }
			if g.get_block_at(nx, ny) != none { continue }

			visited[key] = true
			mut new_path := node.path.clone()
			new_path << d.name
			queue << SolverNode{ x: nx, y: ny, path: new_path }
		}
	}
	return []string{}
}

// --------------------------------------------------
// FX & Particles
// --------------------------------------------------

pub fn (mut g Game) spawn_burst(x f32, y f32, r u8, gr u8, b u8, count int) {
	for i in 0 .. count {
		angle := f32(i) * (2.0 * f32(math.pi) / f32(count))
		speed := f32(2.0 + math.sin(f64(i) * 1.5) * 1.5)
		g.particles << Particle{
			x: x
			y: y
			vx: f32(math.cos(f64(angle))) * speed
			vy: f32(math.sin(f64(angle))) * speed
			life: 0.6
			max_life: 0.6
			size: 3.5
			r: r
			g: gr
			b: b
		}
	}
}

pub fn (mut g Game) spawn_floating_text(text string, x f32, y f32, r u8, gr u8, b u8) {
	g.floating_texts << FloatingText{
		text: text
		x: x
		y: y
		vy: -1.4
		life: 1.2
		r: r
		g: gr
		b: b
	}
}

// --------------------------------------------------
// Frame Update Loop
// --------------------------------------------------

pub fn (mut g Game) update(dt f64) {
	clamped_dt := if dt > 0.05 { 0.05 } else { dt }
	g.time_elapsed += clamped_dt
	g.anim_tick++
	if g.push_strain_timer > 0 {
		g.push_strain_timer--
	}

	if g.status_msg_timer > 0 {
		g.status_msg_timer -= clamped_dt
	}

	// Blink floor rhythm (2.2s solid, 1.4s abyss)
	g.blink_timer += clamped_dt
	if g.blink_timer >= 2.0 {
		g.blink_timer = 0
		g.blink_phase = !g.blink_phase
	}

	// Trauma and Screen shake decay
	if g.trauma > 0 {
		g.trauma = f32(math.max(0.0, f64(g.trauma) - clamped_dt * 2.0))
		g.screen_shake = g.trauma * g.trauma * 16.0
	} else {
		g.screen_shake = 0
	}

	// Smooth render positions for Lolo
	g.lolo.render_x += (f32(g.lolo.x) - g.lolo.render_x) * f32(clamped_dt * 15.0)
	g.lolo.render_y += (f32(g.lolo.y) - g.lolo.render_y) * f32(clamped_dt * 15.0)

	// Smooth render positions for blocks
	for mut b in g.blocks {
		b.render_x += (f32(b.x) - b.render_x) * f32(clamped_dt * 15.0)
		b.render_y += (f32(b.y) - b.render_y) * f32(clamped_dt * 15.0)
	}

	// Smooth render positions & timers for enemies
	for mut e in g.enemies {
		e.render_x += (f32(e.x) - e.render_x) * f32(clamped_dt * 15.0)
		e.render_y += (f32(e.y) - e.render_y) * f32(clamped_dt * 15.0)
		if e.is_egg && !e.is_asleep && !e.is_vaporized {
			e.egg_timer -= clamped_dt
			if e.egg_timer <= 0 {
				e.is_egg = false
				g.spawn_burst(f32(e.x), f32(e.y), 0, 240, 255, 12)
			}
		}
	}

	// Update Particles
	for mut p in g.particles {
		p.x += p.vx * f32(clamped_dt)
		p.y += p.vy * f32(clamped_dt)
		p.life -= f32(clamped_dt)
	}
	g.particles = g.particles.filter(it.life > 0)

	// Update Floating Texts
	for mut ft in g.floating_texts {
		ft.y += ft.vy * f32(clamped_dt)
		ft.life -= f32(clamped_dt)
	}
	g.floating_texts = g.floating_texts.filter(it.life > 0)

	// Update Ghost Guide Animation
	if g.ghost.active && g.ghost.waypoints.len > 1 {
		g.ghost.progress += f32(clamped_dt) * g.ghost.speed
		if int(g.ghost.progress) >= g.ghost.waypoints.len - 1 {
			g.ghost.progress = 0
		}
		idx := int(g.ghost.progress)
		if idx + 1 < g.ghost.waypoints.len {
			frac := g.ghost.progress - f32(idx)
			p1 := g.ghost.waypoints[idx]
			p2 := g.ghost.waypoints[idx + 1]
			g.ghost.ghost_x = f32(p1.x) + f32(p2.x - p1.x) * frac
			g.ghost.ghost_y = f32(p1.y) + f32(p2.y - p1.y) * frac
		}
	}
}

// --------------------------------------------------
// Overlay Toggles
// --------------------------------------------------

pub fn (mut g Game) toggle_level_selector() {
	g.level_selector_open = !g.level_selector_open
	if g.level_selector_open {
		g.sector_map_open = false
		g.field_manual_open = false
		g.random_dialog_open = false
		g.level_selector_page = g.current_level_idx / 25
	}
}

pub fn (mut g Game) toggle_sector_map() {
	g.sector_map_open = !g.sector_map_open
	if g.sector_map_open {
		g.level_selector_open = false
		g.field_manual_open = false
		g.random_dialog_open = false
	}
}

pub fn (mut g Game) toggle_field_manual() {
	g.field_manual_open = !g.field_manual_open
	if g.field_manual_open {
		g.level_selector_open = false
		g.sector_map_open = false
		g.random_dialog_open = false
	}
}

pub fn (mut g Game) toggle_editor_mode() {
	g.designer_open = !g.designer_open
	g.mode = if g.designer_open { GameMode.designer } else { GameMode.campaign }
}

pub fn (mut g Game) close_all_overlays() {
	g.level_selector_open = false
	g.sector_map_open = false
	g.field_manual_open = false
	g.random_dialog_open = false
}
