module main

import math
import rand

const win_width = 800
const win_height = 800

const wall_w = 40
const play_width = win_width - 2 * wall_w

// xjump-sdl tile sizing
const tile_s = 25

enum PlatformType {
	standard
	ice
	spring
	crumbly
}

struct Platform {
pub mut:
	x       f64
	y       f64
	w       f64
	h       f64 = 16.0
	floor   int
	kind    PlatformType
	broken  bool
	stepped bool
}

struct Jumper {
pub mut:
	x               f64
	y               f64
	w               f64 = 36.0
	h               f64 = 40.0
	vx              f64 // in half-pixels per frame [-32, 32]
	vy              f64
	jump_power      f64
	dir             int = 1
	angle           f64
	on_ground       bool = true
	is_facing_right bool = true
	is_idle_variant bool
	idle_count      int
	cur_floor       int
	prev_floor      int
	color           Color
	is_alive        bool = true
	lives           int  = 3
	combo           int
}

enum GameMode {
	solo // 1P Solo Survival
	pvp  // 2P Local Co-op/Versus
}

enum StateMode {
	menu
	playing
	game_over
}

struct GNUJumpEngine {
pub mut:
	mode            StateMode = .menu
	game_mode       GameMode  = .solo
	p1              Jumper
	p2              Jumper
	platforms       []Platform
	scroll_offset   f64
	scroll_speed    f64 = 200.0
	scroll_count    f64
	highest_floor   int
	fpos            int
	lava_y          f64 = f64(win_height)
	lava_speed      f64 = 1.2
	score_p1        int
	score_p2        int
	high_score      int
	best_score_ever int
	best_today      int
}

fn new_gnujump_engine() GNUJumpEngine {
	mut g := GNUJumpEngine{
		p1: Jumper{
			x:     f64(win_width / 2 - 18)
			y:     f64(win_height - 100)
			color: Color{
				r: 40
				g: 220
				b: 240
			}
			lives: 3
		}
		p2: Jumper{
			x:        f64(win_width / 2 + 18)
			y:        f64(win_height - 100)
			color:    Color{
				r: 245
				g: 158
				b: 11
			}
			lives:    3
			is_alive: false
		}
	}
	g.generate_initial_tower()
	return g
}

fn (mut g GNUJumpEngine) generate_floor_at(floor_idx int, y_pos f64) {
	g.highest_floor = floor_idx
	if floor_idx % 250 == 0 {
		// xjump-sdl milestone solid floor
		g.platforms << Platform{
			x:     f64(wall_w)
			y:     y_pos
			w:     f64(play_width)
			floor: floor_idx
			kind:  .standard
		}
		return
	}

	// xjump-sdl floor generator logic: fpos shifts by sign * magnitude
	sign := if rand.f64() > 0.5 { 1 } else { -1 }
	mag := 5 + rand.intn(5) or { 5 }
	g.fpos = (g.fpos + sign * mag) % 22
	if g.fpos < 0 {
		g.fpos += 22
	}

	tile_left := g.fpos + 5 - (2 + rand.intn(3) or { 2 })
	tile_right := g.fpos + 5 + (2 + rand.intn(3) or { 2 })

	px := f64(wall_w + tile_left * tile_s)
	pw := f64((tile_right - tile_left + 1) * tile_s)
	pw_clamped := math.max(60.0, math.min(f64(play_width - 20), pw))

	mut kind := PlatformType.standard
	r := rand.f64()
	if floor_idx > 2 {
		if r < 0.22 {
			kind = .ice
		} else if r < 0.40 {
			kind = .spring
		} else if r < 0.60 {
			kind = .crumbly
		}
	}

	g.platforms << Platform{
		x:     px
		y:     y_pos
		w:     pw_clamped
		floor: floor_idx
		kind:  kind
	}
}

fn (mut g GNUJumpEngine) generate_initial_tower() {
	g.platforms.clear()
	g.highest_floor = 0
	g.scroll_offset = 0
	g.fpos = rand.intn(22) or { 10 }

	// Base ground platform
	g.platforms << Platform{
		x:     f64(wall_w)
		y:     f64(win_height - 50)
		w:     f64(play_width)
		floor: 0
		kind:  .standard
	}

	mut cur_y := f64(win_height - 50 - 65)
	for f in 1 .. 25 {
		g.generate_floor_at(f, cur_y)
		cur_y -= 65.0
	}
}

fn (mut g GNUJumpEngine) add_higher_platforms() {
	mut top_y := f64(win_height)
	for p in g.platforms {
		if p.y < top_y {
			top_y = p.y
		}
	}

	for top_y > -400 {
		top_y -= 65.0
		g.generate_floor_at(g.highest_floor + 1, top_y)
	}
}

fn (mut g GNUJumpEngine) respawn_jumper(mut j Jumper) {
	if j.lives > 1 {
		j.lives--
		mut found := false
		for p in g.platforms {
			if !p.broken && p.y + p.h < g.lava_y - 20.0 && p.y > 100.0 {
				j.x = p.x + p.w / 2.0 - j.w / 2.0
				j.y = p.y - j.h
				j.vx = 0
				j.vy = 0
				j.on_ground = true
				j.cur_floor = p.floor
				found = true
				break
			}
		}
		if !found {
			j.lives = 0
			j.is_alive = false
		}
	} else {
		j.lives = 0
		j.is_alive = false
	}
}

fn (mut g GNUJumpEngine) start_game() {
	g.platforms.clear()
	g.generate_initial_tower()
	g.lava_y = f64(win_height + 250)
	g.lava_speed = 1.2
	g.scroll_speed = 200.0
	g.score_p1 = 0
	g.score_p2 = 0

	g.p1 = Jumper{
		x:         f64(win_width / 2 - 30)
		y:         f64(win_height - 90)
		color:     Color{
			r: 40
			g: 220
			b: 240
		}
		is_alive:  true
		lives:     3
		cur_floor: 0
	}

	if g.game_mode == .pvp {
		g.p2 = Jumper{
			x:         f64(win_width / 2 + 30)
			y:         f64(win_height - 90)
			color:     Color{
				r: 245
				g: 158
				b: 11
			}
			is_alive:  true
			lives:     3
			cur_floor: 0
		}
	} else {
		g.p2.is_alive = false
		g.p2.lives = 0
	}

	g.mode = .playing
}

fn update_jumper(mut j Jumper, move_l bool, move_r bool, jump_btn bool, mut platforms []Platform) (bool, bool, bool, bool, int) {
	if !j.is_alive {
		return false, false, false, false, 0
	}

	mut jumped := false
	mut landed := false
	mut springed := false
	mut broken := false
	mut combo_floors := 0

	// xjump-sdl Physics Accel & Friction
	accel_x := if j.on_ground { 3.0 } else { 2.0 }
	if move_l {
		j.vx = math.max(j.vx - accel_x, -32.0)
		j.dir = -1
		j.is_facing_right = false
	} else if move_r {
		j.vx = math.min(j.vx + accel_x, 32.0)
		j.dir = 1
		j.is_facing_right = true
	} else if j.on_ground {
		// xjump-sdl ground friction
		if j.vx < -2.0 {
			j.vx += 3.0
		} else if j.vx > 2.0 {
			j.vx -= 3.0
		} else {
			j.vx = 0
		}
	}

	// Update x position by half-pixels
	j.x += j.vx / 2.0

	// Wall Bounce with dampened reflection (-vx / 2)
	if j.x < f64(wall_w) && j.vx <= 0 {
		j.x = f64(wall_w)
		j.vx = -j.vx / 2.0
	} else if j.x + j.w > f64(win_width - wall_w) && j.vx >= 0 {
		j.x = f64(win_width - wall_w) - j.w
		j.vx = -j.vx / 2.0
	}

	// xjump-sdl Jump Power & Variable Jump Arc
	if j.on_ground {
		j.idle_count++
		if j.idle_count >= 5 {
			j.is_idle_variant = !j.is_idle_variant
			j.idle_count = 0
		}

		if jump_btn {
			j.jump_power = math.abs(j.vx) / 4.0 + 7.0
			j.vy = -j.jump_power / 2.0 - 12.0
			j.on_ground = false
			jumped = true
		}
	} else {
		if j.jump_power > 0 {
			j.vy = -j.jump_power / 2.0 - 12.0
			j.jump_power = if jump_btn { j.jump_power - 1.0 } else { 0 }
		} else {
			j.vy = math.min(j.vy + 2.0, 16.0)
			j.jump_power = 0
		}
		j.angle += f64(j.dir) * (math.abs(j.vx) * 1.2 + 4.0)
	}

	j.y += j.vy

	// Platform Collision Landing
	if j.vy > 0 {
		for i := 0; i < platforms.len; i++ {
			p := platforms[i]
			if p.broken {
				continue
			}

			if j.x + j.w >= p.x && j.x <= p.x + p.w {
				if j.y + j.h >= p.y && j.y + j.h - j.vy <= p.y + p.h + 4.0 {
					if p.kind == .spring {
						j.y = p.y - j.h
						j.vy = -19.5
						j.on_ground = false
						springed = true
					} else if p.kind == .crumbly {
						platforms[i].broken = true
						broken = true
						j.on_ground = false
						j.vy = 3.0
					} else {
						j.y = p.y - j.h
						j.vy = 0
						j.on_ground = true
					}

					landed = true

					if p.floor > j.cur_floor {
						diff := p.floor - j.cur_floor
						if diff > 1 {
							combo_floors = diff
						}
						j.prev_floor = j.cur_floor
						j.cur_floor = p.floor
					}
					break
				}
			}
		}
	}

	// Verify continuous ground support (handles walking off platform edges & broken floors)
	if j.on_ground {
		mut supported := false
		for p in platforms {
			if !p.broken && j.x + j.w >= p.x && j.x <= p.x + p.w {
				if math.abs((j.y + j.h) - p.y) <= 4.0 {
					supported = true
					break
				}
			}
		}
		if !supported {
			j.on_ground = false
		}
	}

	return jumped, landed, springed, broken, combo_floors
}

fn (mut g GNUJumpEngine) update_step(p1_l bool, p1_r bool, p1_up bool, p2_l bool, p2_r bool, p2_up bool) (bool, bool, bool, bool, bool) {
	if g.mode != .playing {
		return false, false, false, false, false
	}

	mut any_jumped := false
	mut any_landed := false
	mut any_springed := false
	mut any_broken := false
	mut any_combo := false

	// Update P1
	if g.p1.is_alive {
		j, l, sp, br, cb := update_jumper(mut g.p1, p1_l, p1_r, p1_up, mut g.platforms)
		if j {
			any_jumped = true
		}
		if l {
			any_landed = true
		}
		if sp {
			any_springed = true
		}
		if br {
			any_broken = true
		}
		if cb > 1 {
			any_combo = true
			g.p1.combo = cb
			g.score_p1 += cb * 50
		}
		if g.p1.cur_floor * 10 > g.score_p1 {
			g.score_p1 = g.p1.cur_floor * 10
		}
	}

	// Update P2 (if in PVP)
	if g.p2.is_alive {
		j, l, sp, br, cb := update_jumper(mut g.p2, p2_l, p2_r, p2_up, mut g.platforms)
		if j {
			any_jumped = true
		}
		if l {
			any_landed = true
		}
		if sp {
			any_springed = true
		}
		if br {
			any_broken = true
		}
		if cb > 1 {
			any_combo = true
			g.p2.combo = cb
			g.score_p2 += cb * 50
		}
		if g.p2.cur_floor * 10 > g.score_p2 {
			g.score_p2 = g.p2.cur_floor * 10
		}
	}

	// Camera Scroll Tracking (xjump-sdl forcedScroll above topLimit y < 350)
	mut target_y := f64(win_height)
	if g.p1.is_alive && g.p1.y < target_y {
		target_y = g.p1.y
	}
	if g.p2.is_alive && g.p2.y < target_y {
		target_y = g.p2.y
	}

	if target_y < 350.0 {
		scroll := 350.0 - target_y
		g.scroll_offset += scroll

		for i in 0 .. g.platforms.len {
			g.platforms[i].y += scroll
		}
		if g.p1.is_alive {
			g.p1.y += scroll
		}
		if g.p2.is_alive {
			g.p2.y += scroll
		}
		g.lava_y += scroll
	}

	// Add higher platforms as camera moves up
	g.add_higher_platforms()

	// Accelerated Rising Lava Hazard
	g.lava_speed = 1.2 + f64(g.highest_floor) * 0.035
	g.lava_y -= g.lava_speed

	// Check Fall-Off-Bottom & Lava Collision
	if g.p1.is_alive && (g.p1.y + g.p1.h >= g.lava_y || g.p1.y > f64(win_height)) {
		g.respawn_jumper(mut g.p1)
	}
	if g.p2.is_alive && (g.p2.y + g.p2.h >= g.lava_y || g.p2.y > f64(win_height)) {
		g.respawn_jumper(mut g.p2)
	}

	// Check Game Over condition
	if !g.p1.is_alive && !g.p2.is_alive {
		g.mode = .game_over
	}

	if g.score_p1 > g.best_score_ever {
		g.best_score_ever = g.score_p1
	}
	if g.score_p2 > g.best_score_ever {
		g.best_score_ever = g.score_p2
	}
	if g.score_p1 > g.high_score {
		g.high_score = g.score_p1
	}
	if g.score_p2 > g.high_score {
		g.high_score = g.score_p2
	}

	return any_jumped, any_landed, any_springed, any_broken, any_combo
}
