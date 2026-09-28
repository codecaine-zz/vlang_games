module main

import math
import os
import rand



pub const tile_sz = 32.0
pub const map_cols = 64
pub const map_rows = 24
pub const world_w = f64(map_cols) * tile_sz
pub const world_h = f64(map_rows) * tile_sz

pub enum WeaponType {
	blaster
	dual_laser
	flamethrower
	missile
}

pub struct Bullet {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	rad      f64
	damage   int
	@type    WeaponType
	is_enemy bool
	active   bool = true
}

pub enum ItemKind {
	soda_can
	turkey
	red_key
	blue_key
	green_key
	floppy_disk
	circuit_board
	weapon_dual
	weapon_flame
	weapon_missile
}

pub struct PickupItem {
pub mut:
	x      f64
	y      f64
	rad    f64 = 12.0
	kind   ItemKind
	active bool = true
}

pub struct Destructible {
pub mut:
	x         f64
	y         f64
	w         f64 = 28.0
	h         f64 = 28.0
	hp        int = 1
	is_camera bool
	is_barrel bool
	active    bool = true
}

pub enum EnemyKind {
	robodroid
	turret
	mutant_slime
}

pub struct Enemy {
pub mut:
	x           f64
	y           f64
	vx          f64
	vy          f64
	w           f64 = 24.0
	h           f64 = 28.0
	hp          int = 3
	kind        EnemyKind
	dir         int = 1
	shoot_timer f64
	active      bool = true
}

pub struct Elevator {
pub mut:
	x     f64
	y     f64
	w     f64 = 48.0
	h     f64 = 12.0
	min_y f64
	max_y f64
	vy    f64 = 45.0
	dir   f64 = 1.0
}

pub struct BossMech {
pub mut:
	x            f64  = 1600.0
	y            f64  = 540.0
	w            f64  = 64.0
	h            f64  = 70.0
	hp           int  = 30
	max_hp       int  = 30
	dir          int  = -1
	attack_timer f64
	active       bool
}

pub struct DukePlayer {
pub mut:
	x              f64 = 64.0
	y              f64 = 520.0
	vx             f64
	vy             f64
	w              f64 = 20.0
	h              f64 = 30.0
	dir            int = 1 // -1 = left, +1 = right
	on_ground      bool
	is_crouching   bool
	is_aiming_up   bool
	is_climbing    bool
	is_hanging     bool
	walk_anim_t    f64
	somersault_rot f64
	hp             int = 8
	max_hp         int = 8
	lives          int = 3
	score          int
	weapon         WeaponType = .blaster
	ammo           int = 60
	has_red_key    bool
	has_blue_key   bool
	has_green_key  bool
	invuln_timer   f64
}

pub enum GameState {
	playing
	sector_debrief
	game_won
	game_over
}

pub struct DukeGame {
pub mut:
	tiles            [][]int // map_rows x map_cols
	player           DukePlayer
	bullets          []Bullet
	items            []PickupItem
	destructs        []Destructible
	enemies          []Enemy
	elevators        []Elevator
	boss             BossMech
	state            GameState = .playing
	level_num        int       = 1
	sector_name      string    = 'SECTOR 1: CYBER OUTPOST'
	sector_time      f64
	cameras_total    int = 3
	cameras_left     int = 3
	cameras_killed   int
	bonus_earned     int
	high_score       int = 65000
	sprite_texture   &Texture = unsafe { nil }
}

pub fn (mut g DukeGame) init_textures(renderer &Renderer) {
	paths := [
		'assets/sprites/duke.png',
		'./assets/sprites/duke.png',
		'../assets/sprites/duke.png',
		'duke/assets/sprites/duke.png',
	]
	for p in paths {
		if os.exists(p) {
			g.sprite_texture = load_texture(renderer.ctx, p)
			if g.sprite_texture != unsafe { nil } && g.sprite_texture.valid {
				println('duke Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn new_duke_game() DukeGame {
	mut g := DukeGame{}
	g.reset_game()
	return g
}

pub fn (mut g DukeGame) reset_game() {
	g.player.lives = 3
	g.player.score = 0
	g.player.hp = 8
	g.level_num = 1
	g.load_sector(1)
}

pub fn (mut g DukeGame) load_sector(level int) {
	g.level_num = level
	g.state = .playing
	g.sector_time = 0.0
	g.bonus_earned = 0
	g.cameras_killed = 0
	g.bullets.clear()
	g.items.clear()
	g.destructs.clear()
	g.enemies.clear()
	g.elevators.clear()

	g.player.x = 64.0
	g.player.y = 520.0
	g.player.vx = 0.0
	g.player.vy = 0.0
	g.player.hp = 8
	g.player.has_red_key = false
	g.player.has_blue_key = false
	g.player.has_green_key = false
	g.player.invuln_timer = 0.0
	g.boss.active = false

	// Build Level Map base grid
	g.tiles = [][]int{len: map_rows, init: []int{len: map_cols, init: 0}}

	// Border solids
	for c in 0 .. map_cols {
		g.tiles[0][c] = 1
		g.tiles[map_rows - 1][c] = 1
	}
	for r in 0 .. map_rows {
		g.tiles[r][0] = 1
		g.tiles[r][map_cols - 1] = 1
	}

	match level {
		1 {
			// SECTOR 1: CYBER OUTPOST (Night City Platforms, Red/Blue Doors)
			g.sector_name = 'SECTOR 1: CYBER OUTPOST'
			g.cameras_total = 3
			g.cameras_left = 3

			// Main ground
			for c in 1 .. map_cols - 1 {
				g.tiles[20][c] = 1
			}

			// Sector 1 Platforms & ladders
			for c in 4 .. 14 { g.tiles[15][c] = 1 }
			for r in 15 .. 20 { g.tiles[r][8] = 3 } // Ladder

			// Overhead climbing pipe across gap
			for c in 14 .. 24 { g.tiles[11][c] = 4 }

			// Sector 2 mid-tier
			for c in 22 .. 36 { g.tiles[14][c] = 1 }
			for r in 14 .. 20 { g.tiles[r][30] = 3 }

			// Red Security Blast Door
			g.tiles[14][35] = 5

			// Upper High-Tech Sector
			for c in 36 .. 54 { g.tiles[10][c] = 1 }
			for c in 40 .. 50 { g.tiles[5][c] = 1 }

			// Blue Security Blast Door
			g.tiles[10][52] = 6

			// Exit teleport pad
			g.tiles[19][60] = 9
			g.tiles[19][61] = 9

			// Acid pool at bottom gap
			for c in 15 .. 21 { g.tiles[20][c] = 8 }

			// Elevators
			g.elevators << Elevator{ x: 380.0, y: 440.0, min_y: 280.0, max_y: 520.0, vy: 50.0, dir: -1.0 }
			g.elevators << Elevator{ x: 1150.0, y: 350.0, min_y: 180.0, max_y: 420.0, vy: 55.0, dir: 1.0 }

			// Items
			g.items << PickupItem{ x: 280.0, y: 440.0, kind: .soda_can }
			g.items << PickupItem{ x: 320.0, y: 440.0, kind: .circuit_board }
			g.items << PickupItem{ x: 220.0, y: 300.0, kind: .red_key }
			g.items << PickupItem{ x: 350.0, y: 300.0, kind: .weapon_dual }
			g.items << PickupItem{ x: 800.0, y: 400.0, kind: .turkey }
			g.items << PickupItem{ x: 1050.0, y: 280.0, kind: .blue_key }
			g.items << PickupItem{ x: 1400.0, y: 130.0, kind: .weapon_flame }
			g.items << PickupItem{ x: 1450.0, y: 130.0, kind: .floppy_disk }

			// Cameras & Barrels
			g.destructs << Destructible{ x: 350.0, y: 140.0, is_camera: true }
			g.destructs << Destructible{ x: 920.0, y: 200.0, is_camera: true }
			g.destructs << Destructible{ x: 1480.0, y: 140.0, is_camera: true }
			g.destructs << Destructible{ x: 260.0, y: 450.0, hp: 2, is_barrel: true }
			g.destructs << Destructible{ x: 740.0, y: 418.0, hp: 2, is_barrel: true }
			g.destructs << Destructible{ x: 1200.0, y: 290.0, hp: 1 }

			// Enemies
			g.enemies << Enemy{ x: 400.0, y: 600.0, kind: .robodroid, hp: 4, dir: 1 }
			g.enemies << Enemy{ x: 850.0, y: 410.0, kind: .robodroid, hp: 4, dir: -1 }
			g.enemies << Enemy{ x: 1300.0, y: 280.0, kind: .robodroid, hp: 5, dir: 1 }
			g.enemies << Enemy{ x: 1550.0, y: 590.0, kind: .mutant_slime, hp: 3, dir: -1 }
			g.enemies << Enemy{ x: 650.0, y: 280.0, kind: .turret, hp: 3, dir: -1 }
		}
		2 {
			// SECTOR 2: SUBTERRANEAN REACTOR CORE (Acid Reservoirs, Green Keycard, Wall Turrets)
			g.sector_name = 'SECTOR 2: REACTOR CORE'
			g.cameras_total = 4
			g.cameras_left = 4

			// Segmented floors over toxic acid
			for c in 1 .. 12 { g.tiles[20][c] = 1 }
			for c in 12 .. 26 { g.tiles[20][c] = 8 } // Huge acid lake
			for c in 26 .. 44 { g.tiles[20][c] = 1 }
			for c in 44 .. 56 { g.tiles[20][c] = 8 } // Second acid reservoir
			for c in 56 .. map_cols - 1 { g.tiles[20][c] = 1 }

			// Overhead suspension scaffolding
			for c in 6 .. 18 { g.tiles[14][c] = 1 }
			for c in 14 .. 28 { g.tiles[9][c] = 4 } // Hand-over-hand pipe across acid lake
			for c in 26 .. 42 { g.tiles[14][c] = 1 }
			for r in 14 .. 20 { g.tiles[r][36] = 3 } // Ladder

			// Green Security Blast Door
			g.tiles[14][41] = 7

			// High Reactor Girders
			for c in 42 .. 58 { g.tiles[13][c] = 1 }
			for c in 46 .. 54 { g.tiles[7][c] = 1 }
			for r in 7 .. 13 { g.tiles[r][50] = 3 } // High ladder

			// Exit teleport pad
			g.tiles[19][60] = 9
			g.tiles[19][61] = 9

			// Moving Elevators
			g.elevators << Elevator{ x: 450.0, y: 380.0, min_y: 200.0, max_y: 480.0, vy: 65.0, dir: 1.0 }
			g.elevators << Elevator{ x: 1480.0, y: 400.0, min_y: 180.0, max_y: 460.0, vy: 60.0, dir: -1.0 }

			// Items
			g.items << PickupItem{ x: 260.0, y: 400.0, kind: .soda_can }
			g.items << PickupItem{ x: 340.0, y: 260.0, kind: .weapon_flame }
			g.items << PickupItem{ x: 750.0, y: 180.0, kind: .green_key }
			g.items << PickupItem{ x: 920.0, y: 400.0, kind: .turkey }
			g.items << PickupItem{ x: 1100.0, y: 400.0, kind: .circuit_board }
			g.items << PickupItem{ x: 1550.0, y: 180.0, kind: .weapon_missile }
			g.items << PickupItem{ x: 1650.0, y: 180.0, kind: .floppy_disk }

			// 4 Security Cameras & Barrels
			g.destructs << Destructible{ x: 220.0, y: 240.0, is_camera: true }
			g.destructs << Destructible{ x: 720.0, y: 120.0, is_camera: true }
			g.destructs << Destructible{ x: 1180.0, y: 240.0, is_camera: true }
			g.destructs << Destructible{ x: 1720.0, y: 240.0, is_camera: true }
			g.destructs << Destructible{ x: 960.0, y: 418.0, hp: 2, is_barrel: true }
			g.destructs << Destructible{ x: 1380.0, y: 388.0, hp: 2, is_barrel: true }

			// Enemies (Turrets & Slimes)
			g.enemies << Enemy{ x: 480.0, y: 250.0, kind: .turret, hp: 4, dir: -1 }
			g.enemies << Enemy{ x: 980.0, y: 410.0, kind: .robodroid, hp: 5, dir: 1 }
			g.enemies << Enemy{ x: 1250.0, y: 410.0, kind: .robodroid, hp: 5, dir: -1 }
			g.enemies << Enemy{ x: 1600.0, y: 380.0, kind: .mutant_slime, hp: 4, dir: -1 }
			g.enemies << Enemy{ x: 1420.0, y: 220.0, kind: .turret, hp: 4, dir: -1 }
		}
		else {
			// SECTOR 3: ORBITAL FORTRESS & MEGA MECH GOLIATH BOSS
			g.sector_name = 'SECTOR 3: ORBITAL FORTRESS (BOSS)'
			g.cameras_total = 2
			g.cameras_left = 2

			// Continuous Arena Floor
			for c in 1 .. map_cols - 1 {
				g.tiles[20][c] = 1
			}

			// Left Tactical Girders
			for c in 4 .. 16 { g.tiles[15][c] = 1 }
			for c in 8 .. 22 { g.tiles[10][c] = 1 }
			for r in 10 .. 20 { g.tiles[r][12] = 3 }

			// Center Overhead Pipe & Girders
			for c in 22 .. 38 { g.tiles[8][c] = 4 }
			for c in 32 .. 48 { g.tiles[14][c] = 1 }

			// Exit Escape Teleporter (active after boss defeated)
			g.tiles[19][60] = 9
			g.tiles[19][61] = 9

			// Heavy Missiles & Soda Stash for Boss Battle
			g.items << PickupItem{ x: 200.0, y: 280.0, kind: .weapon_missile }
			g.items << PickupItem{ x: 300.0, y: 280.0, kind: .turkey }
			g.items << PickupItem{ x: 450.0, y: 440.0, kind: .soda_can }
			g.items << PickupItem{ x: 800.0, y: 400.0, kind: .weapon_missile }
			g.items << PickupItem{ x: 1100.0, y: 400.0, kind: .soda_can }

			// Cameras
			g.destructs << Destructible{ x: 300.0, y: 150.0, is_camera: true }
			g.destructs << Destructible{ x: 1200.0, y: 200.0, is_camera: true }

			// Spawn Mega Mech Boss at right end of arena
			g.boss = BossMech{
				x:            1550.0
				y:            570.0
				w:            70.0
				h:            70.0
				hp:           35
				max_hp:       35
				dir:          -1
				attack_timer: 0.0
				active:       true
			}

			// Minion Guards
			g.enemies << Enemy{ x: 600.0, y: 600.0, kind: .robodroid, hp: 5, dir: 1 }
			g.enemies << Enemy{ x: 950.0, y: 410.0, kind: .turret, hp: 4, dir: -1 }
		}
	}
}

pub fn (g &DukeGame) get_tile(tx int, ty int) int {
	if tx < 0 || tx >= map_cols || ty < 0 || ty >= map_rows {
		return 1
	}
	return g.tiles[ty][tx]
}

pub fn (g &DukeGame) is_tile_solid(tx int, ty int) bool {
	tile := g.get_tile(tx, ty)
	if tile == 1 {
		return true
	}
	if tile == 5 && !g.player.has_red_key {
		return true
	}
	if tile == 6 && !g.player.has_blue_key {
		return true
	}
	if tile == 7 && !g.player.has_green_key {
		return true
	}
	return false
}

pub fn (g &DukeGame) is_solid(x f64, y f64) bool {
	tx := int(x / tile_sz)
	ty := int(y / tile_sz)
	return g.is_tile_solid(tx, ty)
}

pub fn (mut g DukeGame) player_jump() bool {
	if g.player.on_ground || g.player.is_climbing || g.player.is_hanging {
		g.player.vy = -400.0
		g.player.on_ground = false
		g.player.is_climbing = false
		g.player.is_hanging = false
		g.player.somersault_rot = 0.0
		return true
	}
	return false
}

pub fn (mut g DukeGame) player_shoot() bool {
	if g.player.weapon != .blaster && g.player.ammo <= 0 {
		g.player.weapon = .blaster
	}

	mut bx := g.player.x + if g.player.dir > 0 { g.player.w + 4.0 } else { -4.0 }
	mut by := g.player.y + 12.0
	mut bvx := f64(g.player.dir) * 480.0
	mut bvy := 0.0

	if g.player.is_aiming_up {
		bx = g.player.x + g.player.w / 2.0
		by = g.player.y - 4.0
		bvx = 0.0
		bvy = -480.0
	} else if g.player.is_crouching {
		by = g.player.y + 20.0
	}

	match g.player.weapon {
		.blaster {
			g.bullets << Bullet{ x: bx, y: by, vx: bvx, vy: bvy, rad: 4.0, damage: 1, @type: .blaster }
		}
		.dual_laser {
			g.player.ammo--
			g.bullets << Bullet{ x: bx, y: by - 4.0, vx: bvx, vy: bvy, rad: 5.0, damage: 2, @type: .dual_laser }
			g.bullets << Bullet{ x: bx, y: by + 4.0, vx: bvx, vy: bvy, rad: 5.0, damage: 2, @type: .dual_laser }
		}
		.flamethrower {
			g.player.ammo--
			for _ in 0 .. 3 {
				spread := (f64(rand.intn(20) or { 10 }) - 10.0) * 10.0
				g.bullets << Bullet{ x: bx, y: by, vx: bvx + spread, vy: bvy + spread, rad: 8.0, damage: 2, @type: .flamethrower }
			}
		}
		.missile {
			g.player.ammo -= 2
			g.bullets << Bullet{ x: bx, y: by, vx: bvx * 0.9, vy: bvy * 0.9, rad: 7.0, damage: 5, @type: .missile }
		}
	}
	return true
}

pub struct DukeEvents {
pub mut:
	shot_blaster     bool
	shot_dual        bool
	shot_flame       bool
	shot_missile     bool
	explosion        bool
	jumped           bool
	picked_item      bool
	unlocked_door    bool
	camera_destroyed bool
	boss_hit         bool
	boss_defeated    bool
	sector_cleared   bool
	game_won         bool
	game_over        bool
	player_hurt      bool
}

pub fn (mut g DukeGame) update(dt f64, move_dir int, climb_dir int, crouch bool, aim_up bool) DukeEvents {
	mut ev := DukeEvents{}
	if g.state != .playing {
		return ev
	}

	g.sector_time += dt

	if g.player.invuln_timer > 0.0 {
		g.player.invuln_timer -= dt
	}

	// Update Elevators
	for mut elev in g.elevators {
		elev.y += elev.vy * elev.dir * dt
		if elev.y >= elev.max_y {
			elev.y = elev.max_y
			elev.dir = -1.0
		} else if elev.y <= elev.min_y {
			elev.y = elev.min_y
			elev.dir = 1.0
		}
	}

	// Check if Duke is riding an elevator
	mut on_elev_idx := -1
	for ei, elev in g.elevators {
		if g.player.x + g.player.w > elev.x && g.player.x < elev.x + elev.w {
			if math.abs((g.player.y + g.player.h) - elev.y) <= 8.0 && g.player.vy >= 0.0 && !g.player.is_climbing {
				g.player.y = elev.y - g.player.h
				g.player.vy = 0.0
				g.player.on_ground = true
				on_elev_idx = ei
				break
			}
		}
	}

	// Player Horizontal Velocity Input
	g.player.is_crouching = crouch && g.player.on_ground
	g.player.is_aiming_up = aim_up

	if !g.player.is_crouching {
		if move_dir != 0 {
			g.player.dir = move_dir
			g.player.vx = f64(move_dir) * 160.0
			g.player.walk_anim_t += dt * 10.0
		} else {
			g.player.vx = 0.0
		}
	} else {
		g.player.vx = 0.0
	}

	// Ladder & Overhead Pipe Detection
	cx := g.player.x + g.player.w / 2.0
	cy := g.player.y + g.player.h / 2.0
	mid_tx := int(cx / tile_sz)
	mid_ty := int(cy / tile_sz)
	feet_ty := int((g.player.y + g.player.h - 1.0) / tile_sz)
	top_ty := int((g.player.y + 1.0) / tile_sz)

	ladder_overlap := g.get_tile(mid_tx, mid_ty) == 3 || g.get_tile(mid_tx, feet_ty) == 3 || g.get_tile(mid_tx, top_ty) == 3
	ladder_below := g.get_tile(mid_tx, feet_ty + 1) == 3

	if climb_dir < 0 { // UP
		if ladder_overlap || ladder_below {
			g.player.is_climbing = true
			g.player.on_ground = false
			g.player.is_hanging = false
			g.player.vy = -140.0

			// Top of ladder dismount check
			if g.get_tile(mid_tx, top_ty) != 3 && g.get_tile(mid_tx, mid_ty) != 3 {
				target_y := f64(feet_ty * int(tile_sz)) - g.player.h
				if g.player.y <= target_y + 6.0 {
					g.player.y = target_y
					g.player.vy = 0.0
					g.player.on_ground = true
					g.player.is_climbing = false
				}
			}
		} else if g.get_tile(mid_tx, top_ty) == 4 || g.get_tile(mid_tx, mid_ty) == 4 {
			// Grab overhead pipe
			g.player.is_hanging = true
			g.player.is_climbing = false
			g.player.on_ground = false
			g.player.vy = 0.0
			g.player.y = f64(top_ty * int(tile_sz)) + 6.0
		}
	} else if climb_dir > 0 { // DOWN
		if ladder_overlap || ladder_below {
			g.player.is_climbing = true
			g.player.on_ground = false
			g.player.is_hanging = false
			g.player.vy = 140.0
		} else if g.player.is_hanging {
			g.player.is_hanging = false
		}
	} else if g.player.is_climbing {
		if !ladder_overlap && !ladder_below {
			g.player.is_climbing = false
		} else {
			g.player.vy = 0.0
		}
	}

	if g.player.is_hanging && (g.get_tile(mid_tx, top_ty) != 4 && g.get_tile(mid_tx, mid_ty) != 4) {
		g.player.is_hanging = false
	}

	// Sub-stepped physics movement
	sub_steps := 4
	sub_dt := dt / f64(sub_steps)

	for _ in 0 .. sub_steps {
		if !g.player.is_climbing && !g.player.is_hanging && on_elev_idx == -1 {
			g.player.vy += 950.0 * sub_dt
			if g.player.vy > 550.0 {
				g.player.vy = 550.0
			}
		}

		// Horizontal movement & collision
		mut new_px := g.player.x + g.player.vx * sub_dt
		if g.player.vx < 0.0 {
			left_tx := int(new_px / tile_sz)
			top_r := int((g.player.y + 2.0) / tile_sz)
			mid_r := int((g.player.y + g.player.h / 2.0) / tile_sz)
			bot_r := int((g.player.y + g.player.h - 2.0) / tile_sz)
			if g.is_tile_solid(left_tx, top_r) || g.is_tile_solid(left_tx, mid_r) || g.is_tile_solid(left_tx, bot_r) {
				new_px = f64((left_tx + 1) * int(tile_sz))
				g.player.vx = 0.0
			}
			g.player.x = new_px
		} else if g.player.vx > 0.0 {
			right_tx := int((new_px + g.player.w) / tile_sz)
			top_r := int((g.player.y + 2.0) / tile_sz)
			mid_r := int((g.player.y + g.player.h / 2.0) / tile_sz)
			bot_r := int((g.player.y + g.player.h - 2.0) / tile_sz)
			if g.is_tile_solid(right_tx, top_r) || g.is_tile_solid(right_tx, mid_r) || g.is_tile_solid(right_tx, bot_r) {
				new_px = f64(right_tx * int(tile_sz)) - g.player.w
				g.player.vx = 0.0
			}
			g.player.x = new_px
		}

		// Vertical movement & collision
		if !g.player.is_climbing && !g.player.is_hanging {
			new_py := g.player.y + g.player.vy * sub_dt
			if g.player.vy >= 0.0 {
				feet_r := int((new_py + g.player.h) / tile_sz)
				left_c := int((g.player.x + 2.0) / tile_sz)
				mid_c := int((g.player.x + g.player.w / 2.0) / tile_sz)
				right_c := int((g.player.x + g.player.w - 2.0) / tile_sz)

				is_ladder_top := (g.get_tile(mid_c, feet_r) == 3 && g.get_tile(mid_c, feet_r - 1) != 3) && climb_dir <= 0

				if g.is_tile_solid(left_c, feet_r) || g.is_tile_solid(mid_c, feet_r) || g.is_tile_solid(right_c, feet_r) || is_ladder_top {
					g.player.y = f64(feet_r * int(tile_sz)) - g.player.h
					g.player.vy = 0.0
					g.player.on_ground = true
					g.player.is_climbing = false
				} else {
					mut landed_elev := false
					for elev in g.elevators {
						if g.player.x + g.player.w > elev.x && g.player.x < elev.x + elev.w {
							if (g.player.y + g.player.h) <= elev.y + 6.0 && (new_py + g.player.h) >= elev.y {
								g.player.y = elev.y - g.player.h
								g.player.vy = 0.0
								g.player.on_ground = true
								landed_elev = true
								break
							}
						}
					}
					if !landed_elev {
						g.player.y = new_py
						g.player.on_ground = false
					}
				}
			} else {
				// Moving Upwards
				head_r := int(new_py / tile_sz)
				left_c := int((g.player.x + 2.0) / tile_sz)
				mid_c := int((g.player.x + g.player.w / 2.0) / tile_sz)
				right_c := int((g.player.x + g.player.w - 2.0) / tile_sz)

				if g.is_tile_solid(left_c, head_r) || g.is_tile_solid(mid_c, head_r) || g.is_tile_solid(right_c, head_r) {
					g.player.y = f64((head_r + 1) * int(tile_sz))
					g.player.vy = 0.0
				} else {
					g.player.y = new_py
				}
			}
		} else if g.player.is_climbing {
			new_py := g.player.y + g.player.vy * sub_dt
			// Check if feet hit solid ground while climbing down
			feet_r := int((new_py + g.player.h) / tile_sz)
			mid_c := int((g.player.x + g.player.w / 2.0) / tile_sz)
			if g.is_tile_solid(mid_c, feet_r) {
				g.player.y = f64(feet_r * int(tile_sz)) - g.player.h
				g.player.vy = 0.0
				g.player.on_ground = true
				g.player.is_climbing = false
			} else {
				g.player.y = new_py
			}
		}
	}

	// Somersault Jump Animation
	if !g.player.on_ground && !g.player.is_climbing && !g.player.is_hanging {
		g.player.somersault_rot += f64(g.player.dir) * 12.0 * dt
	} else {
		g.player.somersault_rot = 0.0
	}

	// Check Door Unlocking
	for check_x in [g.player.x - 12.0, g.player.x + g.player.w / 2.0, g.player.x + g.player.w + 12.0] {
		for check_y in [g.player.y - 2.0, g.player.y + g.player.h / 2.0, g.player.y + g.player.h, g.player.y + g.player.h + 6.0] {
			dtx := int(check_x / tile_sz)
			dty := int(check_y / tile_sz)
			dtile := g.get_tile(dtx, dty)
			if dtile == 5 && g.player.has_red_key {
				g.tiles[dty][dtx] = 0
				ev.unlocked_door = true
				g.player.score += 500
			} else if dtile == 6 && g.player.has_blue_key {
				g.tiles[dty][dtx] = 0
				ev.unlocked_door = true
				g.player.score += 500
			} else if dtile == 7 && g.player.has_green_key {
				g.tiles[dty][dtx] = 0
				ev.unlocked_door = true
				g.player.score += 500
			}
		}
	}

	// Hazard check (Acid pool)
	h_feet_tx := int((g.player.x + g.player.w / 2.0) / tile_sz)
	h_feet_ty := int((g.player.y + g.player.h) / tile_sz)
	if g.get_tile(h_feet_tx, h_feet_ty) == 8 && g.player.invuln_timer <= 0.0 {
		g.player.hp -= 2
		g.player.invuln_timer = 1.2
		g.player.vy = -260.0
		ev.player_hurt = true
		if g.player.hp <= 0 {
			g.player.lives--
			if g.player.lives <= 0 {
				g.state = .game_over
				ev.game_over = true
			} else {
				g.player.x = 64.0
				g.player.y = 500.0
				g.player.hp = 8
			}
		}
	}

	// Exit teleport pad check
	if g.get_tile(h_feet_tx, h_feet_ty) == 9 {
		// If in Boss sector, must defeat boss first
		if g.level_num == 3 && g.boss.active {
			// Boss still alive
		} else {
			// Calculate Camera Perfection Bonus
			mut bonus := 0
			if g.cameras_killed == g.cameras_total {
				bonus += 10000 // All cameras destroyed bonus!
			}
			bonus += g.player.hp * 500
			g.bonus_earned = bonus
			g.player.score += bonus

			if g.player.score > g.high_score {
				g.high_score = g.player.score
			}

			if g.level_num < 3 {
				g.state = .sector_debrief
				ev.sector_cleared = true
			} else {
				g.state = .game_won
				ev.game_won = true
			}
		}
	}

	// Pickups collection
	for mut item in g.items {
		if item.active {
			dx := (g.player.x + g.player.w / 2.0) - item.x
			dy := (g.player.y + g.player.h / 2.0) - item.y
			if dx * dx + dy * dy <= (item.rad + 14.0) * (item.rad + 14.0) {
				item.active = false
				ev.picked_item = true
				match item.kind {
					.soda_can {
						g.player.hp = math.min(g.player.hp + 1, g.player.max_hp)
						g.player.score += 100
					}
					.turkey {
						g.player.hp = g.player.max_hp
						g.player.score += 500
					}
					.red_key {
						g.player.has_red_key = true
						g.player.score += 200
					}
					.blue_key {
						g.player.has_blue_key = true
						g.player.score += 200
					}
					.green_key {
						g.player.has_green_key = true
						g.player.score += 200
					}
					.weapon_dual {
						g.player.weapon = .dual_laser
						g.player.ammo += 40
						g.player.score += 300
					}
					.weapon_flame {
						g.player.weapon = .flamethrower
						g.player.ammo += 50
						g.player.score += 400
					}
					.weapon_missile {
						g.player.weapon = .missile
						g.player.ammo += 20
						g.player.score += 500
					}
					.floppy_disk {
						g.player.score += 1000
					}
					.circuit_board {
						g.player.score += 500
					}
				}
			}
		}
	}

	// Update Bullets
	for mut b in g.bullets {
		if b.active {
			b.x += b.vx * dt
			b.y += b.vy * dt

			if g.is_solid(b.x, b.y) {
				b.active = false
				if b.@type == .missile {
					ev.explosion = true
				}
			}

			// Player bullets hitting enemies, destructibles & Boss
			if !b.is_enemy {
				for mut d in g.destructs {
					if d.active {
						if b.x >= d.x && b.x <= d.x + d.w && b.y >= d.y && b.y <= d.y + d.h {
							b.active = false
							d.hp -= b.damage
							if d.hp <= 0 {
								d.active = false
								ev.explosion = true
								if d.is_camera {
									g.player.score += 250
									g.cameras_left--
									g.cameras_killed++
									ev.camera_destroyed = true
								} else if d.is_barrel {
									g.player.score += 150
								}
							}
							break
						}
					}
				}

				for mut e in g.enemies {
					if e.active {
						if b.x >= e.x && b.x <= e.x + e.w && b.y >= e.y && b.y <= e.y + e.h {
							b.active = false
							e.hp -= b.damage
							if e.hp <= 0 {
								e.active = false
								ev.explosion = true
								g.player.score += 300
							}
							break
						}
					}
				}

				// Check Boss hit
				if g.boss.active {
					if b.x >= g.boss.x && b.x <= g.boss.x + g.boss.w &&
					   b.y >= g.boss.y && b.y <= g.boss.y + g.boss.h {
						b.active = false
						g.boss.hp -= b.damage
						ev.boss_hit = true
						if g.boss.hp <= 0 {
							g.boss.active = false
							ev.boss_defeated = true
							ev.explosion = true
							g.player.score += 15000
						}
					}
				}
			} else {
				// Enemy bullets hitting Duke
				if b.x >= g.player.x && b.x <= g.player.x + g.player.w &&
				   b.y >= g.player.y && b.y <= g.player.y + g.player.h && g.player.invuln_timer <= 0.0 {
					b.active = false
					g.player.hp -= b.damage
					g.player.invuln_timer = 1.0
					ev.player_hurt = true
					if g.player.hp <= 0 {
						g.player.lives--
						if g.player.lives <= 0 {
							g.state = .game_over
							ev.game_over = true
						} else {
							g.player.hp = 8
						}
					}
				}
			}
		}
	}

	// Update Boss AI
	if g.boss.active {
		g.boss.x += f64(g.boss.dir) * 45.0 * dt
		if g.boss.x <= 1300.0 {
			g.boss.dir = 1
		} else if g.boss.x >= 1800.0 {
			g.boss.dir = -1
		}

		g.boss.attack_timer += dt
		if g.boss.attack_timer >= 1.8 {
			g.boss.attack_timer = 0.0
			s_dir := if g.player.x < g.boss.x { -1.0 } else { 1.0 }
			// Twin Rocket / Plasma Salvo
			g.bullets << Bullet{ x: g.boss.x + 10.0, y: g.boss.y + 20.0, vx: s_dir * 350.0, vy: -40.0, rad: 6.0, damage: 2, @type: .missile, is_enemy: true }
			g.bullets << Bullet{ x: g.boss.x + 10.0, y: g.boss.y + 40.0, vx: s_dir * 380.0, vy: 20.0, rad: 5.0, damage: 1, @type: .dual_laser, is_enemy: true }
		}

		// Boss contact damage
		if g.player.x + g.player.w >= g.boss.x && g.player.x <= g.boss.x + g.boss.w &&
		   g.player.y + g.player.h >= g.boss.y && g.player.y <= g.boss.y + g.boss.h && g.player.invuln_timer <= 0.0 {
			g.player.hp -= 2
			g.player.invuln_timer = 1.2
			ev.player_hurt = true
			if g.player.hp <= 0 {
				g.player.lives--
				if g.player.lives <= 0 {
					g.state = .game_over
					ev.game_over = true
				} else {
					g.player.hp = 8
				}
			}
		}
	}

	// Update Enemy AI
	for mut e in g.enemies {
		if e.active {
			match e.kind {
				.robodroid {
					e.x += f64(e.dir) * 60.0 * dt
					if g.is_solid(e.x + if e.dir > 0 { e.w + 4.0 } else { -4.0 }, e.y + e.h / 2.0) {
						e.dir = -e.dir
					}

					e.shoot_timer += dt
					if e.shoot_timer >= 2.0 {
						e.shoot_timer = 0.0
						dy := math.abs(e.y - g.player.y)
						if dy < 32.0 {
							s_dir := if g.player.x < e.x { -1.0 } else { 1.0 }
							g.bullets << Bullet{ x: e.x + e.w / 2.0, y: e.y + e.h / 2.0, vx: s_dir * 320.0, vy: 0.0, rad: 4.0, damage: 1, @type: .blaster, is_enemy: true }
						}
					}
				}
				.turret {
					e.shoot_timer += dt
					if e.shoot_timer >= 1.6 {
						e.shoot_timer = 0.0
						dx := g.player.x - e.x
						dy := g.player.y - e.y
						dist := math.sqrt(dx * dx + dy * dy)
						if dist < 400.0 && dist > 1.0 {
							g.bullets << Bullet{ x: e.x + e.w / 2.0, y: e.y + e.h / 2.0, vx: (dx / dist) * 280.0, vy: (dy / dist) * 280.0, rad: 4.0, damage: 1, @type: .blaster, is_enemy: true }
						}
					}
				}
				.mutant_slime {
					e.x += f64(e.dir) * 40.0 * dt
					if g.is_solid(e.x + if e.dir > 0 { e.w } else { 0.0 }, e.y + e.h / 2.0) {
						e.dir = -e.dir
					}
				}
			}

			// Touch damage
			if g.player.x + g.player.w >= e.x && g.player.x <= e.x + e.w &&
			   g.player.y + g.player.h >= e.y && g.player.y <= e.y + e.h && g.player.invuln_timer <= 0.0 {
				g.player.hp--
				g.player.invuln_timer = 1.0
				if g.player.hp <= 0 {
					g.player.lives--
					if g.player.lives <= 0 {
						g.state = .game_over
						ev.game_over = true
					} else {
						g.player.hp = 8
					}
				}
			}
		}
	}

	// Filter active bullets
	mut alive_bullets := []Bullet{cap: g.bullets.len}
	for b in g.bullets {
		if b.active { alive_bullets << b }
	}
	g.bullets = alive_bullets.clone()

	return ev
}
