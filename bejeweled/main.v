module main

import math
import os
import rand
import gg
import time




fn (mut app App) init_textures() {
	candidates := [
		'assets/sprites/gems.png',
		'./assets/sprites/gems.png',
		'../assets/sprites/gems.png',
		'bejeweled/assets/sprites/gems.png',
		'gems.png',
	]
	for p in candidates {
		if os.exists(p) {
			tex := load_texture(app.renderer.ctx, p)
			if tex != unsafe { nil } && tex.valid {
				app.gem_texture = tex
				app.has_gem_texture = true
				return
			}
		}
	}
}

const win_width = 1000
const win_height = 840

const cell_size = 64
const grid_w = 8 * cell_size
const grid_h = 8 * cell_size
const board_x = 60
const board_y = 150

enum GameMode {
	classic
	zen
	lightning
	butterflies
	diamond_mine
	poker
	ice_storm
}

struct GemParticle {
mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	color Color
	size  int
}

struct FloatText {
mut:
	x     f64
	y     f64
	text  string
	life  f64
	color Color
}

struct LaserBeam {
mut:
	r1    int
	c1    int
	r2    int
	c2    int
	life  f64
	color Color
}

struct HyperZap {
mut:
	fx    f64
	fy    f64
	tx    f64
	ty    f64
	life  f64
	color Color
}

struct SwapAnim {
mut:
	r1       int
	c1       int
	r2       int
	c2       int
	progress f64
	revert   bool
	active   bool
}

struct App {
mut:
	ctx           &gg.Context = unsafe { nil }
	renderer      Renderer
	last_tick     i64
	mouse_x       int
	mouse_y       int
	gem_texture        &Texture  = unsafe { nil }
	has_gem_texture    bool
	sound_mgr          SoundManager
	grid               Grid
	mode               GameMode = .classic
	score              int
	high_score         int
	level              int = 1
	level_progress     int
	time_left          f64 = 60.0
	combo              int
	selected_r         int = -1
	selected_c         int = -1
	cursor_r           int = 3
	cursor_c           int = 3
	hover_r            int = -1
	hover_c            int = -1
	swap_anim          SwapAnim
	falling            bool
	particles          []GemParticle
	float_texts        []FloatText
	laser_beams        []LaserBeam
	hyper_zaps         []HyperZap
	undo_grid          Grid
	has_undo           bool
	hint_p1            Point = Point{r: -1, c: -1}
	hint_p2            Point = Point{r: -1, c: -1}
	show_hint          bool
	hint_timer         f64
	shake_timer        f64
	game_over          bool
	// Butterflies Mode
	butterflies_freed  int
	butterflies_target int = 10
	butterfly_moves    int
	// Diamond Mine Mode
	mine_depth         int = 10
	dirt_grid          [8][8]int // 0 = air, 1 = dirt, 2 = rock, 3 = gold chest
	// Poker Mode
	poker_hand         []int
	poker_skulls       []string
	poker_streak       int
	poker_last_hand    string
	// Ice Storm Mode
	ice_columns        [8]f64
	ice_critical_timer f64
	// Zen Mode
	zen_breath         f64
	btn_reset          Button
	btn_hint           Button
	btn_mode           Button
	btn_sound          Button
}

fn new_app() App {
	btn_y := 765

	mut app := App{
		sound_mgr: new_sound_manager()
		grid:      new_grid()
		btn_reset: Button{
			x: 64, y: btn_y, w: 200, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 35, g: 40, b: 60},
			hover_color: Color{r: 55, g: 65, b: 95},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 95, b: 140},
		}
		btn_hint:  Button{
			x: 288, y: btn_y, w: 200, h: 42, text: 'HINT [H]',
			bg_color: Color{r: 35, g: 60, b: 50},
			hover_color: Color{r: 55, g: 90, b: 75},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 135, b: 110},
		}
		btn_mode:  Button{
			x: 512, y: btn_y, w: 200, h: 42, text: 'CLASSIC [M]',
			bg_color: Color{r: 50, g: 40, b: 75},
			hover_color: Color{r: 75, g: 60, b: 115},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 110, g: 90, b: 165},
		}
		btn_sound: Button{
			x: 736, y: btn_y, w: 200, h: 42, text: 'SOUND: ON [S]',
			bg_color: Color{r: 35, g: 50, b: 70},
			hover_color: Color{r: 55, g: 80, b: 110},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 115, b: 160},
		}
	}
	app.init_mode_state()
	return app
}

fn (mut app App) init_mode_state() {
	match app.mode {
		.classic {
			app.time_left = 0.0
		}
		.zen {
			app.time_left = 0.0
			app.zen_breath = 0.0
		}
		.lightning {
			app.time_left = 60.0
		}
		.butterflies {
			app.butterflies_freed = 0
			app.butterflies_target = 10
			app.butterfly_moves = 0
			app.grid.cells[7][2].special = .butterfly
			app.grid.cells[7][5].special = .butterfly
		}
		.diamond_mine {
			app.mine_depth = 10
			app.time_left = 60.0
			for r in 0 .. 8 {
				for c in 0 .. 8 {
					app.dirt_grid[r][c] = if r == 6 {
						1
					} else if r == 7 {
						if (c + 1) % 3 == 0 { 3 } else { 2 }
					} else {
						0
					}
				}
			}
		}
		.poker {
			app.poker_hand = []int{}
			app.poker_skulls = ['PAIR']
			app.poker_streak = 0
			app.poker_last_hand = ''
		}
		.ice_storm {
			for c in 0 .. 8 {
				app.ice_columns[c] = 0.0
			}
			app.ice_critical_timer = 0.0
		}
	}
}

fn (mut app App) cycle_mode() {
	app.mode = match app.mode {
		.classic { GameMode.zen }
		.zen { GameMode.lightning }
		.lightning { GameMode.butterflies }
		.butterflies { GameMode.diamond_mine }
		.diamond_mine { GameMode.poker }
		.poker { GameMode.ice_storm }
		.ice_storm { GameMode.classic }
	}
	app.sound_mgr.set_bgm(match app.mode {
		.classic { BejeweledBgmType.cosmic_trance }
		.zen { BejeweledBgmType.zen_ambient }
		.lightning { BejeweledBgmType.electro_rush }
		.butterflies { BejeweledBgmType.zen_ambient }
		.diamond_mine { BejeweledBgmType.electro_rush }
		.poker { BejeweledBgmType.cosmic_trance }
		.ice_storm { BejeweledBgmType.electro_rush }
	})
	app.grid = new_grid()
	app.score = 0
	app.level = 1
	app.level_progress = 0
	app.game_over = false
	app.selected_r = -1
	app.selected_c = -1
	app.show_hint = false
	app.init_mode_state()
	app.sound_mgr.play_swap_sound()
}

fn (mut app App) on_turn_end() {
	if app.game_over {
		return
	}
	match app.mode {
		.butterflies {
			// Check if any butterfly is on row 0: Spider grabs it!
			for c in 0 .. grid_size {
				if app.grid.cells[0][c].special == .butterfly {
					app.game_over = true
					app.sound_mgr.play_invalid_sound()
					app.float_texts << FloatText{
						x: f64(board_x + c * cell_size)
						y: f64(board_y + 10)
						text: 'BUTTERFLY CAUGHT IN WEB!'
						life: 2.0
						color: Color{r: 255, g: 60, b: 60}
					}
					return
				}
			}
			// Move all butterflies UP 1 row
			for r in 1 .. grid_size {
				for c in 0 .. grid_size {
					if app.grid.cells[r][c].special == .butterfly {
						app.grid.cells[r - 1][c] = app.grid.cells[r][c]
						app.grid.cells[r][c].special = .none
					}
				}
			}
			app.butterfly_moves++
			if app.butterfly_moves % 2 == 0 {
				sc := rand.int_in_range(0, 8) or { 3 }
				app.grid.cells[7][sc].special = .butterfly
			}
			if app.butterflies_freed >= app.butterflies_target {
				app.level++
				app.butterflies_freed = 0
				app.butterflies_target += 5
				app.sound_mgr.play_level_up_sound()
			}
		}
		.diamond_mine {
			// Check if all dirt is cleared in bottom rows
			mut has_dirt := false
			for r in 6 .. 8 {
				for c in 0 .. grid_size {
					if app.dirt_grid[r][c] > 0 {
						has_dirt = true
						break
					}
				}
			}
			if !has_dirt {
				app.mine_depth += 10
				app.score += 5000 * app.level
				app.time_left = math.min(99.0, app.time_left + 30.0)
				app.shake_timer = 0.6
				app.sound_mgr.play_level_up_sound()
				app.float_texts << FloatText{
					x: f64(board_x + 2 * cell_size)
					y: f64(board_y + 3 * cell_size)
					text: 'DEPTH ${app.mine_depth}m REACHED! +30s DIG TIME!'
					life: 2.5
					color: Color{r: 255, g: 215, b: 60}
				}
				for r in 6 .. 8 {
					for c in 0 .. grid_size {
						app.dirt_grid[r][c] = if r == 6 { 1 } else { if (c + app.mine_depth) % 3 == 0 { 3 } else { 2 } }
					}
				}
			}
		}
		.poker {
			if app.poker_hand.len >= 5 {
				app.evaluate_poker_hand()
			}
		}
		else {}
	}
}

fn (mut app App) evaluate_poker_hand() {
	if app.poker_hand.len < 5 {
		return
	}
	hand := app.poker_hand[0..5].clone()
	app.poker_hand = []int{}

	// Count color frequencies
	mut counts := map[int]int{}
	for k in hand {
		counts[k] = counts[k] + 1
	}

	mut freq_list := []int{}
	for _, cnt in counts {
		freq_list << cnt
	}
	freq_list.sort() // ascending

	mut hand_name := 'PAIR'
	mut pts := 500

	if freq_list.len == 5 {
		hand_name = 'SPECTRUM'
		pts = 5000
	} else if freq_list == [5] {
		hand_name = 'FLUSH'
		pts = 4000
	} else if freq_list == [1, 4] {
		hand_name = 'FOUR OF A KIND'
		pts = 3000
	} else if freq_list == [2, 3] {
		hand_name = 'FULL HOUSE'
		pts = 2500
	} else if freq_list == [1, 1, 3] {
		hand_name = 'THREE OF A KIND'
		pts = 1500
	} else if freq_list == [1, 2, 2] {
		hand_name = 'TWO PAIR'
		pts = 1000
	} else {
		hand_name = 'PAIR'
		pts = 500
	}

	app.poker_last_hand = hand_name
	app.score += pts * app.level

	// Check skull curse
	if hand_name in app.poker_skulls {
		if rand.int_in_range(0, 2) or { 0 } == 0 {
			app.sound_mgr.play_invalid_sound()
			app.game_over = true
			app.float_texts << FloatText{
				x: f64(board_x + cell_size)
				y: f64(board_y + 3 * cell_size)
				text: 'SKULL LANDED! GAME OVER!'
				life: 2.5
				color: Color{r: 255, g: 50, b: 50}
			}
			return
		} else {
			app.score += 2000
			app.float_texts << FloatText{
				x: f64(board_x + cell_size)
				y: f64(board_y + 3 * cell_size)
				text: '${hand_name}! SKULL SURVIVED! +${pts + 2000}'
				life: 2.0
				color: Color{r: 80, g: 255, b: 120}
			}
		}
	} else {
		app.float_texts << FloatText{
			x: f64(board_x + cell_size)
			y: f64(board_y + 3 * cell_size)
			text: '${hand_name}! +${pts}'
			life: 2.0
			color: Color{r: 255, g: 220, b: 80}
		}
	}

	app.poker_streak++
	if app.poker_streak % 3 == 0 {
		if !('TWO PAIR' in app.poker_skulls) {
			app.poker_skulls << 'TWO PAIR'
		} else if !('THREE OF A KIND' in app.poker_skulls) {
			app.poker_skulls << 'THREE OF A KIND'
		}
	}
}

fn get_gem_color(kind int) Color {
	return match kind {
		1 { Color{r: 245, g: 50, b: 60} }   // Ruby (Red)
		2 { Color{r: 50, g: 120, b: 255} }  // Sapphire (Blue)
		3 { Color{r: 50, g: 225, b: 100} }  // Emerald (Green)
		4 { Color{r: 255, g: 215, b: 40} }  // Topaz (Yellow)
		5 { Color{r: 180, g: 70, b: 245} }  // Amethyst (Purple)
		6 { Color{r: 240, g: 245, b: 255} } // Diamond (White)
		7 { Color{r: 255, g: 140, b: 35} }  // Amber (Orange)
		else { Color{r: 100, g: 100, b: 100} }
	}
}

fn (mut app App) trigger_swap(r1 int, c1 int, r2 int, c2 int) {
	if app.swap_anim.active || app.falling || app.game_over {
		return
	}
	app.show_hint = false
	app.hint_timer = 0.0
	app.undo_grid = app.grid
	app.has_undo = true

	app.swap_anim = SwapAnim{
		r1:       r1
		c1:       c1
		r2:       r2
		c2:       c2
		progress: 0.0
		revert:   false
		active:   true
	}
	app.sound_mgr.play_swap_sound()
}

fn (mut app App) handle_gem_click(r int, c int) {
	if app.swap_anim.active || app.falling || app.game_over {
		return
	}
	app.cursor_r = r
	app.cursor_c = c

	if app.selected_r == -1 {
		app.selected_r = r
		app.selected_c = c
		app.sound_mgr.play_select_sound()
	} else if app.selected_r == r && app.selected_c == c {
		app.selected_r = -1
		app.selected_c = -1
	} else if is_adjacent(app.selected_r, app.selected_c, r, c) {
		app.trigger_swap(app.selected_r, app.selected_c, r, c)
		app.selected_r = -1
		app.selected_c = -1
	} else {
		app.selected_r = r
		app.selected_c = c
		app.sound_mgr.play_select_sound()
	}
}

fn (mut app App) move_cursor(dr int, dc int) {
	nr := app.cursor_r + dr
	nc := app.cursor_c + dc
	if nr >= 0 && nr < grid_size {
		app.cursor_r = nr
	}
	if nc >= 0 && nc < grid_size {
		app.cursor_c = nc
	}
}

fn (mut app App) handle_cursor_action() {
	app.handle_gem_click(app.cursor_r, app.cursor_c)
}

fn (mut app App) spawn_match_particles(r int, c int, color Color) {
	cx := f64(board_x + c * cell_size + cell_size / 2)
	cy := f64(board_y + r * cell_size + cell_size / 2)

	for _ in 0 .. 16 {
		angle := rand.f64() * 2.0 * math.pi
		spd := 60.0 + rand.f64() * 180.0
		app.particles << GemParticle{
			x:     cx
			y:     cy
			vx:    math.cos(angle) * spd
			vy:    math.sin(angle) * spd
			life:  0.8
			color: color
			size:  2 + rand.int_in_range(1, 4) or { 2 }
		}
	}
}

fn (mut app App) spawn_flame_blast(r int, c int) {
	app.sound_mgr.play_flame_explosion_sound()
	app.shake_timer = 0.25

	for dr := -1; dr <= 1; dr++ {
		for dc := -1; dc <= 1; dc++ {
			nr := r + dr
			nc := c + dc
			if nr >= 0 && nr < grid_size && nc >= 0 && nc < grid_size {
				col := if app.grid.cells[nr][nc].kind > 0 { get_gem_color(app.grid.cells[nr][nc].kind) } else { Color{r: 255, g: 150, b: 30} }
				app.spawn_match_particles(nr, nc, col)
				app.grid.cells[nr][nc].kind = 0
				app.grid.cells[nr][nc].special = .none
			}
		}
	}
	pts := 500 * app.level
	app.score += pts
	if app.mode == .lightning {
		app.time_left = math.min(99.0, app.time_left + 2.0)
	}
	app.float_texts << FloatText{
		x: f64(board_x + c * cell_size)
		y: f64(board_y + r * cell_size)
		text: 'FLAME BLAST! +${pts}'
		life: 1.2
		color: Color{r: 255, g: 180, b: 40}
	}
}

fn (mut app App) spawn_star_laser(r int, c int) {
	app.sound_mgr.play_star_laser_sound()
	app.shake_timer = 0.35

	// Horizontal laser beam
	app.laser_beams << LaserBeam{
		r1: r, c1: 0, r2: r, c2: grid_size - 1, life: 0.45, color: Color{r: 80, g: 240, b: 255}
	}
	// Vertical laser beam
	app.laser_beams << LaserBeam{
		r1: 0, c1: c, r2: grid_size - 1, c2: c, life: 0.45, color: Color{r: 80, g: 240, b: 255}
	}

	for col_i in 0 .. grid_size {
		col := if app.grid.cells[r][col_i].kind > 0 { get_gem_color(app.grid.cells[r][col_i].kind) } else { Color{r: 80, g: 240, b: 255} }
		app.spawn_match_particles(r, col_i, col)
		app.grid.cells[r][col_i].kind = 0
		app.grid.cells[r][col_i].special = .none
	}
	for row_i in 0 .. grid_size {
		col := if app.grid.cells[row_i][c].kind > 0 { get_gem_color(app.grid.cells[row_i][c].kind) } else { Color{r: 80, g: 240, b: 255} }
		app.spawn_match_particles(row_i, c, col)
		app.grid.cells[row_i][c].kind = 0
		app.grid.cells[row_i][c].special = .none
	}

	pts := 1200 * app.level
	app.score += pts
	if app.mode == .lightning {
		app.time_left = math.min(99.0, app.time_left + 4.0)
	}
	app.float_texts << FloatText{
		x: f64(board_x + c * cell_size)
		y: f64(board_y + r * cell_size)
		text: 'STAR LASER! +${pts}'
		life: 1.4
		color: Color{r: 100, g: 240, b: 255}
	}
}

fn (mut app App) spawn_supernova_blast(r int, c int) {
	app.sound_mgr.play_supernova_sound()
	app.shake_timer = 0.50

	// 3x3 blast
	for dr := -1; dr <= 1; dr++ {
		for dc := -1; dc <= 1; dc++ {
			nr := r + dr
			nc := c + dc
			if nr >= 0 && nr < grid_size && nc >= 0 && nc < grid_size {
				col := if app.grid.cells[nr][nc].kind > 0 { get_gem_color(app.grid.cells[nr][nc].kind) } else { Color{r: 255, g: 220, b: 60} }
				app.spawn_match_particles(nr, nc, col)
				app.grid.cells[nr][nc].kind = 0
				app.grid.cells[nr][nc].special = .none
			}
		}
	}

	// Full cross laser
	app.laser_beams << LaserBeam{
		r1: r, c1: 0, r2: r, c2: grid_size - 1, life: 0.60, color: Color{r: 255, g: 220, b: 80}
	}
	app.laser_beams << LaserBeam{
		r1: 0, c1: c, r2: grid_size - 1, c2: c, life: 0.60, color: Color{r: 255, g: 220, b: 80}
	}

	for col_i in 0 .. grid_size {
		col := if app.grid.cells[r][col_i].kind > 0 { get_gem_color(app.grid.cells[r][col_i].kind) } else { Color{r: 255, g: 220, b: 80} }
		app.spawn_match_particles(r, col_i, col)
		app.grid.cells[r][col_i].kind = 0
		app.grid.cells[r][col_i].special = .none
	}
	for row_i in 0 .. grid_size {
		col := if app.grid.cells[row_i][c].kind > 0 { get_gem_color(app.grid.cells[row_i][c].kind) } else { Color{r: 255, g: 220, b: 80} }
		app.spawn_match_particles(row_i, c, col)
		app.grid.cells[row_i][c].kind = 0
		app.grid.cells[row_i][c].special = .none
	}

	pts := 3000 * app.level
	app.score += pts
	if app.mode == .lightning {
		app.time_left = math.min(99.0, app.time_left + 8.0)
	}
	app.float_texts << FloatText{
		x: f64(board_x + c * cell_size)
		y: f64(board_y + r * cell_size)
		text: 'SUPERNOVA! +${pts}'
		life: 1.6
		color: Color{r: 255, g: 235, b: 60}
	}
}

fn (mut app App) trigger_hypercube_zap(r1 int, c1 int, r2 int, c2 int) {
	app.sound_mgr.play_hypercube_zap_sound()
	app.shake_timer = 0.40

	g1 := app.grid.cells[r1][c1]
	g2 := app.grid.cells[r2][c2]

	// Double Hypercube Swap: Board-Clearing Cosmic Singularity!
	if g1.special == .hypercube && g2.special == .hypercube {
		for r in 0 .. grid_size {
			for c in 0 .. grid_size {
				col := if app.grid.cells[r][c].kind > 0 { get_gem_color(app.grid.cells[r][c].kind) } else { Color{r: 255, g: 255, b: 255} }
				app.spawn_match_particles(r, c, col)
				app.grid.cells[r][c].kind = 0
				app.grid.cells[r][c].special = .none
			}
		}
		pts := 10000 * app.level
		app.score += pts
		app.float_texts << FloatText{
			x: f64(board_x + 2 * cell_size)
			y: f64(board_y + 3 * cell_size)
			text: 'COSMIC SINGULARITY! +${pts}'
			life: 2.0
			color: Color{r: 255, g: 235, b: 80}
		}
		app.falling = true
		return
	}

	// Single Hypercube: Zap all gems of the target color
	target_kind := if g1.special == .hypercube { g2.kind } else { g1.kind }
	hc_r := if g1.special == .hypercube { r1 } else { r2 }
	hc_c := if g1.special == .hypercube { c1 } else { c2 }

	h_fx := f64(board_x + hc_c * cell_size + cell_size / 2)
	h_fy := f64(board_y + hc_r * cell_size + cell_size / 2)

	app.grid.cells[hc_r][hc_c].kind = 0
	app.grid.cells[hc_r][hc_c].special = .none

	mut zapped := 0
	for r in 0 .. grid_size {
		for c in 0 .. grid_size {
			if app.grid.cells[r][c].kind == target_kind {
				t_x := f64(board_x + c * cell_size + cell_size / 2)
				t_y := f64(board_y + r * cell_size + cell_size / 2)
				app.hyper_zaps << HyperZap{
					fx: h_fx, fy: h_fy, tx: t_x, ty: t_y, life: 0.50, color: get_gem_color(target_kind)
				}
				app.spawn_match_particles(r, c, get_gem_color(target_kind))
				app.grid.cells[r][c].kind = 0
				app.grid.cells[r][c].special = .none
				zapped++
			}
		}
	}

	pts := zapped * 200 * app.level
	app.score += pts
	if app.mode == .lightning {
		app.time_left = math.min(99.0, app.time_left + f64(zapped))
	}
	app.float_texts << FloatText{
		x: h_fx - 40.0
		y: h_fy - 20.0
		text: 'HYPER ZAP! +${pts}'
		life: 1.5
		color: Color{r: 255, g: 240, b: 120}
	}
	app.falling = true
}

fn (mut app App) process_matches() bool {
	groups := app.grid.find_matches()
	if groups.len == 0 {
		return false
	}

	app.combo++
	app.sound_mgr.play_match_sound(app.combo)

	mut pts_to_clear := []Point{}
	mut special_triggers := []Point{}

	for group in groups {
		base_pts := group.points.len * 50 * app.combo * app.level
		app.score += base_pts
		app.level_progress += base_pts
		if app.score > app.high_score {
			app.high_score = app.score
		}

		if group.points.len > 0 {
			mid_pt := group.points[group.points.len / 2]
			fx := f64(board_x + mid_pt.c * cell_size + 10)
			fy := f64(board_y + mid_pt.r * cell_size)
			txt := if app.combo > 1 { '+${base_pts} x${app.combo}!' } else { '+${base_pts}' }
			app.float_texts << FloatText{
				x:     fx
				y:     fy
				text:  txt
				life:  1.0
				color: get_gem_color(group.kind)
			}
		}

		for pt in group.points {
			pts_to_clear << pt
			app.spawn_match_particles(pt.r, pt.c, get_gem_color(group.kind))

			// Check if already a special gem
			sp := app.grid.cells[pt.r][pt.c].special
			if sp != .none {
				special_triggers << pt
			}
		}

		// Generate new Special Gems
		spawn_pt := group.points[group.points.len / 2]
		if group.points.len == 4 {
			app.grid.cells[spawn_pt.r][spawn_pt.c].special = .flame
		} else if group.points.len == 5 {
			app.grid.cells[spawn_pt.r][spawn_pt.c].special = .hypercube
		} else if group.points.len >= 6 {
			app.grid.cells[spawn_pt.r][spawn_pt.c].special = .supernova
		}
	}

	// Clear matched standard gems
	for pt in pts_to_clear {
		if app.grid.cells[pt.r][pt.c].special == .none {
			app.grid.cells[pt.r][pt.c].kind = 0
		}
	}

	// Trigger special gem explosions
	for pt in special_triggers {
		sp := app.grid.cells[pt.r][pt.c].special
		if sp == .flame {
			app.spawn_flame_blast(pt.r, pt.c)
		} else if sp == .star {
			app.spawn_star_laser(pt.r, pt.c)
		} else if sp == .supernova {
			app.spawn_supernova_blast(pt.r, pt.c)
		}
	}

	// Level up check (Classic mode)
	if app.mode == .classic && app.level_progress >= app.level * 2500 {
		app.level++
		app.level_progress = 0
		app.sound_mgr.play_level_up_sound()
	}

	return true
}

fn (mut app App) update(dt f64) {
	if app.shake_timer > 0 {
		app.shake_timer -= dt
		if app.shake_timer < 0 {
			app.shake_timer = 0
		}
	}

	// Update particles
	for i := app.particles.len - 1; i >= 0; i-- {
		mut p := unsafe { &app.particles[i] }
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.life -= dt * 1.5
		if p.life <= 0 {
			app.particles.delete(i)
		}
	}

	// Update floating score texts
	for i := app.float_texts.len - 1; i >= 0; i-- {
		mut ft := unsafe { &app.float_texts[i] }
		ft.y -= dt * 35.0
		ft.life -= dt * 1.2
		if ft.life <= 0 {
			app.float_texts.delete(i)
		}
	}

	// Update laser beams
	for i := app.laser_beams.len - 1; i >= 0; i-- {
		mut lb := unsafe { &app.laser_beams[i] }
		lb.life -= dt * 2.0
		if lb.life <= 0 {
			app.laser_beams.delete(i)
		}
	}

	// Update hyper zaps
	for i := app.hyper_zaps.len - 1; i >= 0; i-- {
		mut hz := unsafe { &app.hyper_zaps[i] }
		hz.life -= dt * 2.2
		if hz.life <= 0 {
			app.hyper_zaps.delete(i)
		}
	}

	// Time Attack / Lightning countdown
	if app.mode == .lightning && !app.game_over {
		app.time_left -= dt
		if app.time_left <= 0.0 {
			app.time_left = 0.0
			app.game_over = true
			app.sound_mgr.play_invalid_sound()
		}
	}

	// Idle Hint timer
	if !app.swap_anim.active && !app.falling && !app.game_over {
		app.hint_timer += dt
		if app.hint_timer >= 6.0 && !app.show_hint {
			p1, p2, ok := app.grid.find_hint_move()
			if ok {
				app.hint_p1 = p1
				app.hint_p2 = p2
				app.show_hint = true
			}
		}
	}

	// Handle Swap Animation
	if app.swap_anim.active {
		app.swap_anim.progress += dt * 6.0
		if app.swap_anim.progress >= 1.0 {
			app.swap_anim.progress = 1.0

			// Check if Hypercube is involved
			c1_sp := app.grid.cells[app.swap_anim.r1][app.swap_anim.c1].special
			c2_sp := app.grid.cells[app.swap_anim.r2][app.swap_anim.c2].special
			if c1_sp == .hypercube || c2_sp == .hypercube {
				app.trigger_hypercube_zap(app.swap_anim.r1, app.swap_anim.c1, app.swap_anim.r2, app.swap_anim.c2)
				app.swap_anim.active = false
				return
			}

			// Swap in actual grid
			app.grid.swap(app.swap_anim.r1, app.swap_anim.c1, app.swap_anim.r2, app.swap_anim.c2)

			// Check if swap gave matches or hypercube
			has_match := app.process_matches()
			if !has_match {
				if !app.swap_anim.revert {
					// Swap back
					app.sound_mgr.play_invalid_sound()
					app.swap_anim.revert = true
					app.swap_anim.progress = 0.0
				} else {
					app.swap_anim.active = false
				}
			} else {
				app.swap_anim.active = false
				app.falling = true
			}
		}
		return
	}

	// Handle Falling Gems Animation
	mut any_falling := false
	fall_speed := dt * 12.0

	for r in 0 .. grid_size {
		for c in 0 .. grid_size {
			mut gem := unsafe { &app.grid.cells[r][c] }
			target_y := f64(r)
			target_x := f64(c)

			if gem.curr_y < target_y {
				gem.curr_y += fall_speed
				if gem.curr_y >= target_y {
					gem.curr_y = target_y
				} else {
					any_falling = true
				}
			}
			gem.curr_x = target_x
		}
	}

	if any_falling {
		app.falling = true
	} else if app.falling {
		// All gems finished falling, apply gravity/refill or check next matches
		if app.grid.apply_gravity_and_refill() {
			app.falling = true
		} else {
			// Check cascade matches
			if app.process_matches() {
				app.falling = true
			} else {
				app.falling = false
				app.combo = 0

				// Check if any moves remain
				if !app.grid.has_valid_moves() {
					app.grid.reshuffle()
					app.sound_mgr.play_swap_sound()
				}
			}
		}
	}
}

fn (app &App) draw_gem_shape(cx int, cy int, size int, kind int, special SpecialType) {
	renderer := &app.renderer
	ticks := u32(time.ticks())
	r := size / 2

	if app.gem_texture != unsafe { nil } {
		// Map gem kind (1..7) and special type to 128x128 sprite sheet tile coordinates
		base_col := if kind - 1 < 0 { 0 } else if kind - 1 > 6 { 6 } else { kind - 1 }
		mut col := base_col
		mut row := 0

		match special {
			.hypercube {
				col = 7
				row = 0
			}
			.flame {
				col = base_col
				row = 1
			}
			.supernova {
				col = 7
				row = 1
			}
			.star {
				col = base_col
				row = 2
			}
			.time_bonus {
				col = 7
				row = 2
			}
			else {
				col = base_col
				row = 0
			}
		}

		src := Rect{x: col * 128, y: row * 128, w: 128, h: 128}
		dst := Rect{x: cx - size / 2, y: cy - size / 2, w: size, h: size}
		render_copy(renderer, app.gem_texture, &src, &dst)

		// Dynamic animated overlays on top of sprites
		if special == .flame {
			pulse := math.sin(f64(ticks) * 0.012) * 0.5 + 0.5
			glow_size := r + 2 + int(pulse * 3.0)
			
			set_render_draw_color(renderer, 255, u8(120 + pulse * 80.0), 30, 180)
			g1 := Rect{x: cx - glow_size, y: cy - glow_size, w: glow_size * 2, h: glow_size * 2}
			render_draw_rect(renderer, &g1)

			for spark_i in 0 .. 4 {
				ang := f64(ticks) * 0.008 + f64(spark_i) * math.pi / 2.0
				sx := cx + int(f64(r + 3) * math.cos(ang))
				sy := cy + int(f64(r + 3) * math.sin(ang))
				set_render_draw_color(renderer, 255, 235, 80, 240)
				render_draw_point(renderer, sx, sy)
				render_draw_point(renderer, sx + 1, sy)
			}
		} else if special == .star {
			pulse := math.sin(f64(ticks) * 0.015) * 0.5 + 0.5
			
			set_render_draw_color(renderer, 80, 240, 255, 200)
			sp_len := r + 4 + int(pulse * 4.0)
			render_draw_line(renderer, cx - sp_len, cy, cx + sp_len, cy)
			render_draw_line(renderer, cx, cy - sp_len, cx, cy + sp_len)
		} else if special == .hypercube {
			t_shift := f64(ticks) * 0.006
			rr := u8((math.sin(t_shift) * 0.5 + 0.5) * 255.0)
			rg := u8((math.sin(t_shift + 2.09) * 0.5 + 0.5) * 255.0)
			rb := u8((math.sin(t_shift + 4.18) * 0.5 + 0.5) * 255.0)
			
			set_render_draw_color(renderer, rr, rg, rb, 180)
			cube := Rect{x: cx - r - 1, y: cy - r - 1, w: (r + 1) * 2, h: (r + 1) * 2}
			render_draw_rect(renderer, &cube)
		} else if special == .supernova {
			pulse := math.sin(f64(ticks) * 0.01) * 0.5 + 0.5
			flare_r := r + 3 + int(pulse * 4.0)
			
			set_render_draw_color(renderer, 255, 220, 60, 190)
			r_box := Rect{x: cx - flare_r, y: cy - flare_r, w: flare_r * 2, h: flare_r * 2}
			render_draw_rect(renderer, &r_box)
		} else if special == .butterfly {
			pulse := math.sin(f64(ticks) * 0.015) * 0.5 + 0.5
			wing_w := int(8.0 * pulse) + 4
			
			set_render_draw_color(renderer, 255, 130, 220, 230)
			render_draw_line(renderer, cx - r, cy - 4, cx - r - wing_w, cy - 10)
			render_draw_line(renderer, cx - r - wing_w, cy - 10, cx - r - 2, cy + 4)
			render_draw_line(renderer, cx + r, cy - 4, cx + r + wing_w, cy - 10)
			render_draw_line(renderer, cx + r + wing_w, cy - 10, cx + r + 2, cy + 4)
		}

		// Ambient specular star glint
		sparkle := math.sin(f64(ticks) * 0.006 + f64(cx + cy) * 0.05) * 0.5 + 0.5
		if sparkle > 0.6 {
			alpha := u8(sparkle * 240.0)
			set_render_draw_color(renderer, 255, 255, 255, alpha)
			gx := cx - r / 3
			gy := cy - r / 2
			render_draw_point(renderer, gx, gy)
			render_draw_point(renderer, gx - 1, gy)
			render_draw_point(renderer, gx + 1, gy)
			render_draw_point(renderer, gx, gy - 1)
			render_draw_point(renderer, gx, gy + 1)
		}
		return
	}

	color := get_gem_color(kind)

	// High & Shadow colors for 3D facets
	hi_r := u8(math.min(255, int(color.r) + 85))
	hi_g := u8(math.min(255, int(color.g) + 85))
	hi_b := u8(math.min(255, int(color.b) + 85))

	sh_r := u8(math.max(0, int(color.r) - 75))
	sh_g := u8(math.max(0, int(color.g) - 75))
	sh_b := u8(math.max(0, int(color.b) - 75))

	match kind {
		1 { // Ruby: Octagon with 3D Beveled facets
			pad := r / 3
			// Outer dark drop shadow
			set_render_draw_color(renderer, sh_r, sh_g, sh_b, 255)
			rect_shadow := Rect{x: cx - r + 1, y: cy - r + 1, w: r * 2, h: r * 2}
			render_fill_rect(renderer, &rect_shadow)

			// Base fill
			rect := Rect{x: cx - r, y: cy - r, w: r * 2, h: r * 2}
			set_render_draw_color(renderer, color.r, color.g, color.b, 255)
			render_fill_rect(renderer, &rect)

			// 3D Highlight top/left
			set_render_draw_color(renderer, hi_r, hi_g, hi_b, 255)
			render_draw_line(renderer, cx - r, cy, cx, cy - r)
			render_draw_line(renderer, cx, cy - r, cx + r, cy)
			render_draw_line(renderer, cx - r + 1, cy, cx, cy - r + 1)

			// 3D Shadow bottom/right
			set_render_draw_color(renderer, sh_r, sh_g, sh_b, 255)
			render_draw_line(renderer, cx + r, cy, cx, cy + r)
			render_draw_line(renderer, cx, cy + r, cx - r, cy)

			// Raised Center Table Facet
			inner := Rect{x: cx - r + pad, y: cy - r + pad, w: (r - pad) * 2, h: (r - pad) * 2}
			set_render_draw_color(renderer, hi_r, hi_g, hi_b, 200)
			render_fill_rect(renderer, &inner)
			set_render_draw_color(renderer, color.r, color.g, color.b, 255)
			inner_core := Rect{x: inner.x + 2, y: inner.y + 2, w: inner.w - 4, h: inner.h - 4}
			render_fill_rect(renderer, &inner_core)
		}
		2 { // Sapphire: Hexagon Brilliant Cut
			// Base fill with horizontal scanlines
			for i := -r; i <= r; i++ {
				w := int(f64(r) * (1.0 - math.abs(f64(i)) / (f64(r) * 2.2)))
				shade := if i < 0 { 40 } else { -40 }
				cr := u8(math.clamp(int(color.r) + shade, 0, 255))
				cg := u8(math.clamp(int(color.g) + shade, 0, 255))
				cb := u8(math.clamp(int(color.b) + shade, 0, 255))
				set_render_draw_color(renderer, cr, cg, cb, 255)
				rect := Rect{x: cx - w, y: cy + i, w: w * 2, h: 1}
				render_fill_rect(renderer, &rect)
			}
			// Hexagonal inner facet lines
			set_render_draw_color(renderer, hi_r, hi_g, hi_b, 230)
			render_draw_line(renderer, cx - r / 2, cy - r / 2, cx + r / 2, cy - r / 2)
			render_draw_line(renderer, cx - r / 2, cy - r / 2, cx - r / 2, cy + r / 2)
			set_render_draw_color(renderer, sh_r, sh_g, sh_b, 230)
			render_draw_line(renderer, cx + r / 2, cy - r / 2, cx + r / 2, cy + r / 2)
			render_draw_line(renderer, cx - r / 2, cy + r / 2, cx + r / 2, cy + r / 2)
		}
		3 { // Emerald: Classic Step Cut Beveled Square
			rect := Rect{x: cx - r, y: cy - r, w: r * 2, h: r * 2}
			set_render_draw_color(renderer, color.r, color.g, color.b, 255)
			render_fill_rect(renderer, &rect)

			// Step 1: Outer Chamfer
			set_render_draw_color(renderer, hi_r, hi_g, hi_b, 255)
			for t in 0 .. 3 {
				render_draw_line(renderer, cx - r + t, cy - r + t, cx + r - t, cy - r + t)
				render_draw_line(renderer, cx - r + t, cy - r + t, cx - r + t, cy + r - t)
			}
			set_render_draw_color(renderer, sh_r, sh_g, sh_b, 255)
			for t in 0 .. 3 {
				render_draw_line(renderer, cx - r + t, cy + r - t, cx + r - t, cy + r - t)
				render_draw_line(renderer, cx + r - t, cy - r + t, cx + r - t, cy + r - t)
			}

			// Step 2: Inner Emerald Table
			inner := Rect{x: cx - r / 2, y: cy - r / 2, w: r, h: r}
			set_render_draw_color(renderer, hi_r, hi_g, hi_b, 180)
			render_draw_rect(renderer, &inner)
			set_render_draw_color(renderer, 160, 255, 200, 240)
			core := Rect{x: inner.x + 2, y: inner.y + 2, w: inner.w - 4, h: inner.h - 4}
			render_fill_rect(renderer, &core)
		}
		4 { // Topaz: Triangular Brilliant Pyramid
			for y := -r; y <= r; y++ {
				prog := f64(y + r) / f64(r * 2)
				w := int(f64(r) * prog)
				shade := if y < 0 { 50 } else { -30 }
				cr := u8(math.clamp(int(color.r) + shade, 0, 255))
				cg := u8(math.clamp(int(color.g) + shade, 0, 255))
				cb := u8(math.clamp(int(color.b) + shade, 0, 255))
				set_render_draw_color(renderer, cr, cg, cb, 255)
				rect := Rect{x: cx - w, y: cy + y, w: w * 2, h: 1}
				render_fill_rect(renderer, &rect)
			}
			// Pyramid facet ridge lines meeting at center
			set_render_draw_color(renderer, 255, 255, 200, 240)
			render_draw_line(renderer, cx, cy - r, cx, cy + r / 3)
			render_draw_line(renderer, cx - r, cy + r, cx, cy + r / 3)
			set_render_draw_color(renderer, sh_r, sh_g, sh_b, 240)
			render_draw_line(renderer, cx + r, cy + r, cx, cy + r / 3)
		}
		5 { // Amethyst: Radiant Circular Jewel
			for y := -r; y <= r; y++ {
				norm_y := f64(y) / f64(r)
				w := int(f64(r) * math.sqrt(math.max(0.0, 1.0 - norm_y * norm_y)))
				shade := if y < 0 { 40 } else { -40 }
				cr := u8(math.clamp(int(color.r) + shade, 0, 255))
				cg := u8(math.clamp(int(color.g) + shade, 0, 255))
				cb := u8(math.clamp(int(color.b) + shade, 0, 255))
				set_render_draw_color(renderer, cr, cg, cb, 255)
				rect := Rect{x: cx - w, y: cy + y, w: w * 2, h: 1}
				render_fill_rect(renderer, &rect)
			}
			// Star-cut facet ring
			set_render_draw_color(renderer, hi_r, hi_g, hi_b, 200)
			for rad_i in 0 .. 8 {
				ang := f64(rad_i) * math.pi / 4.0
				x1 := cx + int(f64(r / 3) * math.cos(ang))
				y1 := cy + int(f64(r / 3) * math.sin(ang))
				x2 := cx + int(f64(r - 2) * math.cos(ang))
				y2 := cy + int(f64(r - 2) * math.sin(ang))
				render_draw_line(renderer, x1, y1, x2, y2)
			}
		}
		6 { // Diamond: Kite Rhombus Brilliant
			for y := -r; y <= r; y++ {
				prog := 1.0 - math.abs(f64(y)) / f64(r)
				w := int(f64(r) * prog)
				shade := if y < 0 { 60 } else { -40 }
				cr := u8(math.clamp(int(color.r) + shade, 0, 255))
				cg := u8(math.clamp(int(color.g) + shade, 0, 255))
				cb := u8(math.clamp(int(color.b) + shade, 0, 255))
				set_render_draw_color(renderer, cr, cg, cb, 255)
				rect := Rect{x: cx - w, y: cy + y, w: w * 2, h: 1}
				render_fill_rect(renderer, &rect)
			}
			// Diamond cross-facet star
			set_render_draw_color(renderer, 255, 255, 255, 240)
			render_draw_line(renderer, cx, cy - r, cx, cy + r)
			render_draw_line(renderer, cx - r, cy, cx + r, cy)
			set_render_draw_color(renderer, 180, 230, 255, 200)
			inner_d := Rect{x: cx - r / 3, y: cy - r / 3, w: (r / 3) * 2, h: (r / 3) * 2}
			render_draw_rect(renderer, &inner_d)
		}
		7 { // Amber: Star Pentagon Cut
			rect := Rect{x: cx - r + 3, y: cy - r / 2, w: (r - 3) * 2, h: r + r / 2}
			set_render_draw_color(renderer, color.r, color.g, color.b, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, hi_r, hi_g, hi_b, 255)
			render_draw_line(renderer, cx, cy - r, cx - r, cy)
			render_draw_line(renderer, cx, cy - r, cx + r, cy)
			set_render_draw_color(renderer, sh_r, sh_g, sh_b, 255)
			render_draw_line(renderer, cx - r, cy, cx - r / 2, cy + r)
			render_draw_line(renderer, cx + r, cy, cx + r / 2, cy + r)
			render_draw_line(renderer, cx - r / 2, cy + r, cx + r / 2, cy + r)
		}
		else {}
	}

	// Dynamic Specular Star Glint (sparkles periodically)
	sparkle := math.sin(f64(ticks) * 0.006 + f64(cx + cy) * 0.05) * 0.5 + 0.5
	if sparkle > 0.4 {
		alpha := u8(sparkle * 240.0)
		set_render_draw_color(renderer, 255, 255, 255, alpha)
		gx := cx - r / 3
		gy := cy - r / 2
		// 4-point cross starburst glint
		render_draw_point(renderer, gx, gy)
		render_draw_point(renderer, gx - 1, gy)
		render_draw_point(renderer, gx + 1, gy)
		render_draw_point(renderer, gx, gy - 1)
		render_draw_point(renderer, gx, gy + 1)
		if sparkle > 0.8 {
			render_draw_point(renderer, gx - 2, gy)
			render_draw_point(renderer, gx + 2, gy)
			render_draw_point(renderer, gx, gy - 2)
			render_draw_point(renderer, gx, gy + 2)
		}
	}

	// Special Gem Visual Overlays
	if special == .flame {
		// Multi-layered pulsating flame aura with orbiting embers
		pulse := math.sin(f64(ticks) * 0.012) * 0.5 + 0.5
		glow_size := r + 2 + int(pulse * 3.0)

		set_render_draw_color(renderer, 255, u8(100 + pulse * 100.0), 30, 200)
		g1 := Rect{x: cx - glow_size, y: cy - glow_size, w: glow_size * 2, h: glow_size * 2}
		render_draw_rect(renderer, &g1)

		set_render_draw_color(renderer, 255, 220, 60, 240)
		g2 := Rect{x: cx - glow_size + 1, y: cy - glow_size + 1, w: (glow_size - 1) * 2, h: (glow_size - 1) * 2}
		render_draw_rect(renderer, &g2)

		// Orbiting flame sparks
		for spark_i in 0 .. 4 {
			ang := f64(ticks) * 0.008 + f64(spark_i) * math.pi / 2.0
			sx := cx + int(f64(r + 4) * math.cos(ang))
			sy := cy + int(f64(r + 4) * math.sin(ang))
			set_render_draw_color(renderer, 255, 230, 70, 255)
			render_draw_point(renderer, sx, sy)
			render_draw_point(renderer, sx + 1, sy)
		}
	} else if special == .star {
		// Electric Pulsating Star Gem with energy spikes
		pulse := math.sin(f64(ticks) * 0.015) * 0.5 + 0.5
		set_render_draw_color(renderer, 80, 240, 255, 255)
		sp_len := r + 4 + int(pulse * 4.0)

		render_draw_line(renderer, cx - sp_len, cy, cx + sp_len, cy)
		render_draw_line(renderer, cx, cy - sp_len, cx, cy + sp_len)

		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_draw_line(renderer, cx - sp_len / 2, cy, cx + sp_len / 2, cy)
		render_draw_line(renderer, cx, cy - sp_len / 2, cx, cy + sp_len / 2)
	} else if special == .supernova {
		// Solar Corona Flare
		for ring in 0 .. 4 {
			t_ang := f64(ticks) * 0.01 + f64(ring) * 1.57
			flare_r := r + 4 + int(math.sin(t_ang) * 4.0)
			set_render_draw_color(renderer, 255, 220, 60, 220)
			r_box := Rect{x: cx - flare_r, y: cy - flare_r, w: flare_r * 2, h: flare_r * 2}
			render_draw_rect(renderer, &r_box)
		}
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_fill_rect(renderer, &Rect{x: cx - 3, y: cy - 3, w: 6, h: 6})
	} else if special == .hypercube {
		// Prismatic Rotating Rainbow Vortex
		for ring in 0 .. 3 {
			t_shift := f64(ticks) * 0.006 + f64(ring) * 1.8
			rr := u8((math.sin(t_shift) * 0.5 + 0.5) * 255.0)
			rg := u8((math.sin(t_shift + 2.09) * 0.5 + 0.5) * 255.0)
			rb := u8((math.sin(t_shift + 4.18) * 0.5 + 0.5) * 255.0)
			set_render_draw_color(renderer, rr, rg, rb, 255)

			offset := ring * 2
			cube := Rect{x: cx - r - 2 + offset, y: cy - r - 2 + offset, w: (r + 2 - offset) * 2, h: (r + 2 - offset) * 2}
			render_draw_rect(renderer, &cube)
		}
		// Bright center crystal star
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_draw_line(renderer, cx - 4, cy, cx + 4, cy)
		render_draw_line(renderer, cx, cy - 4, cx, cy + 4)
	}
}

fn (mut app App) render() {
	renderer := &app.renderer

	// Starry deep midnight blue background
	set_render_draw_color(renderer, 14, 18, 30, 255)
	render_clear(renderer)

	// Top Title
	draw_text_centered(renderer, win_width / 2, 25, 'BEJEWELED // GEM MATCH-3', 3, Color{r: 90, g: 190, b: 255})
	draw_text_centered(renderer, win_width / 2, 65, 'CASCADING GEMS & SPECIAL COMBOS', 2, Color{r: 170, g: 190, b: 230})

	// Screen Shake on Flame / Hypercube explosions
	mut bx := board_x
	mut by := board_y
	if app.shake_timer > 0 {
		shake_mag := app.shake_timer * 20.0
		bx += int((rand.f64() * 2.0 - 1.0) * shake_mag)
		by += int((rand.f64() * 2.0 - 1.0) * shake_mag)
	}

	// Outer Board Bevel
	pad := 14
	board_rect := Rect{
		x: bx - pad
		y: by - pad
		w: grid_w + pad * 2
		h: grid_h + pad * 2
	}
	set_render_draw_color(renderer, 30, 36, 56, 255)
	render_fill_rect(renderer, &board_rect)
	set_render_draw_color(renderer, 60, 75, 115, 255)
	render_draw_rect(renderer, &board_rect)

	// Inner Grid Cells
	for r in 0 .. grid_size {
		for c in 0 .. grid_size {
			cell_rect := Rect{
				x: bx + c * cell_size
				y: by + r * cell_size
				w: cell_size
				h: cell_size
			}
			is_dark := (r + c) % 2 == 0
			set_render_draw_color(renderer, if is_dark { u8(18) } else { u8(24) }, if is_dark { u8(22) } else { u8(30) }, if is_dark { u8(38) } else { u8(48) }, 255)
			render_fill_rect(renderer, &cell_rect)
			if app.gem_texture != unsafe { nil } {
				src_sock := Rect{x: 0, y: 384, w: 128, h: 128}
				render_copy(renderer, app.gem_texture, &src_sock, &cell_rect)
			}
			set_render_draw_color(renderer, 40, 50, 75, 255)
			render_draw_rect(renderer, &cell_rect)
		}
	}

	// Hint Highlight Pulses
	if app.show_hint && app.hint_p1.r >= 0 && app.hint_p2.r >= 0 {
		pulse := u8((math.sin(f64(u32(time.ticks())) * 0.008) * 0.5 + 0.5) * 150.0 + 105.0)
		set_render_draw_color(renderer, pulse, pulse, 60, 255)

		h1 := Rect{x: bx + app.hint_p1.c * cell_size + 2, y: by + app.hint_p1.r * cell_size + 2, w: cell_size - 4, h: cell_size - 4}
		h2 := Rect{x: bx + app.hint_p2.c * cell_size + 2, y: by + app.hint_p2.r * cell_size + 2, w: cell_size - 4, h: cell_size - 4}
		render_draw_rect(renderer, &h1)
		render_draw_rect(renderer, &h2)
	}

	// Selected Cell Highlight
	if app.selected_r >= 0 && app.selected_c >= 0 {
		sel_rect := Rect{
			x: bx + app.selected_c * cell_size + 2
			y: by + app.selected_r * cell_size + 2
			w: cell_size - 4
			h: cell_size - 4
		}
		set_render_draw_color(renderer, 255, 230, 80, 255)
		render_draw_rect(renderer, &sel_rect)
		inner := Rect{x: sel_rect.x + 1, y: sel_rect.y + 1, w: sel_rect.w - 2, h: sel_rect.h - 2}
		render_draw_rect(renderer, &inner)
	}

	// Render Gems
	for r in 0 .. grid_size {
		for c in 0 .. grid_size {
			gem := app.grid.cells[r][c]
			if gem.kind == 0 {
				continue
			}

			mut cx := bx + int(gem.curr_x * f64(cell_size)) + cell_size / 2
			mut cy := by + int(gem.curr_y * f64(cell_size)) + cell_size / 2

			// Handle Swap Interpolation
			if app.swap_anim.active {
				if r == app.swap_anim.r1 && c == app.swap_anim.c1 {
					prog := if app.swap_anim.revert { 1.0 - app.swap_anim.progress } else { app.swap_anim.progress }
					dx := f64(app.swap_anim.c2 - app.swap_anim.c1) * f64(cell_size) * prog
					dy := f64(app.swap_anim.r2 - app.swap_anim.r1) * f64(cell_size) * prog
					cx = bx + c * cell_size + cell_size / 2 + int(dx)
					cy = by + r * cell_size + cell_size / 2 + int(dy)
				} else if r == app.swap_anim.r2 && c == app.swap_anim.c2 {
					prog := if app.swap_anim.revert { 1.0 - app.swap_anim.progress } else { app.swap_anim.progress }
					dx := f64(app.swap_anim.c1 - app.swap_anim.c2) * f64(cell_size) * prog
					dy := f64(app.swap_anim.r1 - app.swap_anim.r2) * f64(cell_size) * prog
					cx = bx + c * cell_size + cell_size / 2 + int(dx)
					cy = by + r * cell_size + cell_size / 2 + int(dy)
				}
			}

			// Don't render above board during refill spawn
			if cy < by {
				continue
			}

			app.draw_gem_shape(cx, cy, cell_size - 10, gem.kind, gem.special)
		}
	}

	// Render Laser Beams
	for lb in app.laser_beams {
		x1 := bx + lb.c1 * cell_size + cell_size / 2
		y1 := by + lb.r1 * cell_size + cell_size / 2
		x2 := bx + lb.c2 * cell_size + cell_size / 2
		y2 := by + lb.r2 * cell_size + cell_size / 2
		alpha := u8(math.min(255.0, lb.life * 550.0))
		
		set_render_draw_color(renderer, lb.color.r, lb.color.g, lb.color.b, alpha)
		for w_i in -3 .. 4 {
			if lb.r1 == lb.r2 {
				render_draw_line(renderer, x1, y1 + w_i, x2, y2 + w_i)
			} else {
				render_draw_line(renderer, x1 + w_i, y1, x2 + w_i, y2)
			}
		}
	}

	// Render Diamond Mine Dirt & Treasure Grid
	if app.mode == .diamond_mine {
		for r in 0 .. grid_size {
			for c in 0 .. grid_size {
				d_val := app.dirt_grid[r][c]
				if d_val > 0 {
					d_rect := Rect{x: bx + c * cell_size + 2, y: by + r * cell_size + 2, w: cell_size - 4, h: cell_size - 4}
					
					if d_val == 1 {
						set_render_draw_color(renderer, 120, 75, 40, 220)
						render_fill_rect(renderer, &d_rect)
						draw_text_centered(renderer, d_rect.x + d_rect.w / 2, d_rect.y + d_rect.h / 2 - 6, 'DIRT', 1, Color{r: 220, g: 190, b: 150})
					} else if d_val == 2 {
						set_render_draw_color(renderer, 70, 75, 90, 240)
						render_fill_rect(renderer, &d_rect)
						draw_text_centered(renderer, d_rect.x + d_rect.w / 2, d_rect.y + d_rect.h / 2 - 6, 'ROCK', 1, Color{r: 200, g: 210, b: 230})
					} else {
						set_render_draw_color(renderer, 240, 180, 20, 240)
						render_fill_rect(renderer, &d_rect)
						draw_text_centered(renderer, d_rect.x + d_rect.w / 2, d_rect.y + d_rect.h / 2 - 6, 'GOLD', 1, Color{r: 255, g: 255, b: 255})
					}
				}
			}
		}
	}

	// Render Ice Storm Rising Frost Columns
	if app.mode == .ice_storm {
		for c in 0 .. grid_size {
			col_h := app.ice_columns[c]
			if col_h > 0.0 {
				pixel_h := int(col_h * f64(grid_h))
				ice_rect := Rect{x: bx + c * cell_size + 1, y: by + grid_h - pixel_h, w: cell_size - 2, h: pixel_h}
				
				alpha := if col_h > 0.8 { u8(220) } else { u8(160) }
				set_render_draw_color(renderer, 130, 220, 255, alpha)
				render_fill_rect(renderer, &ice_rect)
				set_render_draw_color(renderer, 220, 245, 255, 255)
				render_draw_rect(renderer, &ice_rect)
			}
		}
	}

	// Top Spider Web Hazard Warning for Butterflies Mode
	if app.mode == .butterflies {
		web_rect := Rect{x: bx, y: by - 12, w: grid_w, h: 12}
		
		set_render_draw_color(renderer, 200, 30, 40, 220)
		render_fill_rect(renderer, &web_rect)
		draw_text_centered(renderer, bx + grid_w / 2, by - 10, 'SPIDER WEB HAZARD', 1, Color{r: 255, g: 240, b: 240})
	}

	// Render Hyper Zaps
	for hz in app.hyper_zaps {
		alpha := u8(math.min(255.0, hz.life * 500.0))
		
		set_render_draw_color(renderer, hz.color.r, hz.color.g, hz.color.b, alpha)
		mid_x := (hz.fx + hz.tx) / 2.0 + (rand.f64() * 2.0 - 1.0) * 12.0
		mid_y := (hz.fy + hz.ty) / 2.0 + (rand.f64() * 2.0 - 1.0) * 12.0
		render_draw_line(renderer, int(hz.fx), int(hz.fy), int(mid_x), int(mid_y))
		render_draw_line(renderer, int(mid_x), int(mid_y), int(hz.tx), int(hz.ty))
	}

	// Keyboard Cursor Bracket
	if app.cursor_r >= 0 && app.cursor_c >= 0 {
		cur_x := bx + app.cursor_c * cell_size
		cur_y := by + app.cursor_r * cell_size
		set_render_draw_color(renderer, 80, 230, 255, 255)
		render_draw_line(renderer, cur_x + 4, cur_y + 4, cur_x + 14, cur_y + 4)
		render_draw_line(renderer, cur_x + 4, cur_y + 4, cur_x + 4, cur_y + 14)
		render_draw_line(renderer, cur_x + cell_size - 4, cur_y + 4, cur_x + cell_size - 14, cur_y + 4)
		render_draw_line(renderer, cur_x + cell_size - 4, cur_y + 4, cur_x + cell_size - 4, cur_y + 14)
		render_draw_line(renderer, cur_x + 4, cur_y + cell_size - 4, cur_x + 14, cur_y + cell_size - 4)
		render_draw_line(renderer, cur_x + 4, cur_y + cell_size - 4, cur_x + 4, cur_y + cell_size - 14)
		render_draw_line(renderer, cur_x + cell_size - 4, cur_y + cell_size - 4, cur_x + cell_size - 14, cur_y + cell_size - 4)
		render_draw_line(renderer, cur_x + cell_size - 4, cur_y + cell_size - 4, cur_x + cell_size - 4, cur_y + cell_size - 14)
	}

	// Render Floating Texts
	for ft in app.float_texts {
		draw_text(renderer, int(ft.x), int(ft.y), ft.text, 2, ft.color)
	}

	// Render Particles
	for part in app.particles {
		rect := Rect{
			x: int(part.x)
			y: int(part.y)
			w: part.size
			h: part.size
		}
		set_render_draw_color(renderer, part.color.r, part.color.g, part.color.b, u8(part.life * 255.0))
		render_fill_rect(renderer, &rect)
	}

	// Right HUD Panel (Scores & Stats)
	hud_x := 620
	hud_y := 150

	// Score Box
	score_box := Rect{x: hud_x, y: hud_y, w: 320, h: 105}
	set_render_draw_color(renderer, 24, 30, 48, 255)
	render_fill_rect(renderer, &score_box)
	set_render_draw_color(renderer, 60, 75, 120, 255)
	render_draw_rect(renderer, &score_box)

	draw_text(renderer, hud_x + 20, hud_y + 18, 'SCORE', 2, Color{r: 160, g: 190, b: 230})
	draw_text(renderer, hud_x + 20, hud_y + 46, '${app.score}', 3, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, hud_x + 20, hud_y + 80, 'BEST: ${app.high_score}', 1, Color{r: 140, g: 160, b: 190})

	// Level / Timer / Mode Stats Box
	prog_box := Rect{x: hud_x, y: hud_y + 120, w: 320, h: 110}
	set_render_draw_color(renderer, 24, 30, 48, 255)
	render_fill_rect(renderer, &prog_box)
	set_render_draw_color(renderer, 60, 75, 120, 255)
	render_draw_rect(renderer, &prog_box)

	match app.mode {
		.classic {
			draw_text(renderer, hud_x + 20, hud_y + 138, 'CLASSIC // LEVEL ${app.level}', 2, Color{r: 100, g: 220, b: 255})
			target := app.level * 2500
			pct := math.min(1.0, f64(app.level_progress) / f64(target))
			bar_bg := Rect{x: hud_x + 20, y: hud_y + 175, w: 280, h: 22}
			set_render_draw_color(renderer, 15, 20, 32, 255)
			render_fill_rect(renderer, &bar_bg)
			bar_fill := Rect{x: hud_x + 20, y: hud_y + 175, w: int(280.0 * pct), h: 22}
			set_render_draw_color(renderer, 70, 180, 255, 255)
			render_fill_rect(renderer, &bar_fill)
			draw_text_centered(renderer, hud_x + 160, hud_y + 204, '${app.level_progress} / ${target}', 1, Color{r: 200, g: 220, b: 255})
		}
		.lightning {
			draw_text(renderer, hud_x + 20, hud_y + 138, 'LIGHTNING // BLITZ', 2, Color{r: 255, g: 100, b: 100})
			time_pct := math.min(1.0, app.time_left / 60.0)
			bar_bg := Rect{x: hud_x + 20, y: hud_y + 175, w: 280, h: 22}
			set_render_draw_color(renderer, 15, 20, 32, 255)
			render_fill_rect(renderer, &bar_bg)
			bar_fill := Rect{x: hud_x + 20, y: hud_y + 175, w: int(280.0 * time_pct), h: 22}
			bar_col := if app.time_left < 15.0 { Color{r: 255, g: 45, b: 45} } else { Color{r: 255, g: 140, b: 50} }
			set_render_draw_color(renderer, bar_col.r, bar_col.g, bar_col.b, 255)
			render_fill_rect(renderer, &bar_fill)
			draw_text_centered(renderer, hud_x + 160, hud_y + 204, '${int(app.time_left)}s REMAINING (+5s SPECIAL)', 1, Color{r: 255, g: 220, b: 200})
		}
		.zen {
			draw_text(renderer, hud_x + 20, hud_y + 138, 'ZEN // TRANQUILITY', 2, Color{r: 120, g: 255, b: 150})
			draw_text(renderer, hud_x + 20, hud_y + 170, 'BREATHING & AMBIENT SOUNDS', 1, Color{r: 180, g: 235, b: 200})
			draw_text(renderer, hud_x + 20, hud_y + 195, 'NO TIMERS // NO GAME OVER', 1, Color{r: 140, g: 200, b: 170})
		}
		.butterflies {
			draw_text(renderer, hud_x + 20, hud_y + 138, 'BUTTERFLIES // WEB DEFENSE', 2, Color{r: 255, g: 140, b: 220})
			draw_text(renderer, hud_x + 20, hud_y + 170, 'SAVED: ${app.butterflies_freed} / ${app.butterflies_target}', 2, Color{r: 255, g: 240, b: 100})
			draw_text(renderer, hud_x + 20, hud_y + 195, 'MATCH TO FREE BEFORE ROW 0!', 1, Color{r: 255, g: 180, b: 180})
		}
		.diamond_mine {
			draw_text(renderer, hud_x + 20, hud_y + 138, 'DIAMOND MINE // DEPTH ${app.mine_depth}m', 2, Color{r: 255, g: 215, b: 60})
			time_pct := math.min(1.0, app.time_left / 60.0)
			bar_bg := Rect{x: hud_x + 20, y: hud_y + 175, w: 280, h: 22}
			set_render_draw_color(renderer, 15, 20, 32, 255)
			render_fill_rect(renderer, &bar_bg)
			bar_fill := Rect{x: hud_x + 20, y: hud_y + 175, w: int(280.0 * time_pct), h: 22}
			set_render_draw_color(renderer, 240, 160, 40, 255)
			render_fill_rect(renderer, &bar_fill)
			draw_text_centered(renderer, hud_x + 160, hud_y + 204, 'DIG DIRT TO DELVE DEEPER', 1, Color{r: 255, g: 235, b: 180})
		}
		.poker {
			draw_text(renderer, hud_x + 20, hud_y + 138, 'POKER // HAND BUILDER', 2, Color{r: 100, g: 220, b: 255})
			draw_text(renderer, hud_x + 20, hud_y + 170, 'CARDS: ${app.poker_hand.len} / 5', 2, Color{r: 255, g: 255, b: 255})
			hand_str := if app.poker_last_hand != '' { app.poker_last_hand } else { 'MATCH GEMS TO DEAL' }
			draw_text(renderer, hud_x + 20, hud_y + 195, hand_str, 1, Color{r: 255, g: 215, b: 80})
		}
		.ice_storm {
			draw_text(renderer, hud_x + 20, hud_y + 138, 'ICE STORM // FROST CRUSH', 2, Color{r: 100, g: 230, b: 255})
			draw_text(renderer, hud_x + 20, hud_y + 170, 'SHATTER RISING FROST COLUMNS', 1, Color{r: 200, g: 240, b: 255})
			draw_text(renderer, hud_x + 20, hud_y + 195, 'VERTICAL MATCHES SHATTER ICE', 1, Color{r: 140, g: 210, b: 255})
		}
	}

	// Instructions / Powers Box
	inst_card := Rect{x: hud_x, y: hud_y + 245, w: 320, h: 285}
	set_render_draw_color(renderer, 20, 24, 38, 255)
	render_fill_rect(renderer, &inst_card)
	set_render_draw_color(renderer, 50, 65, 100, 255)
	render_draw_rect(renderer, &inst_card)

	draw_text_centered(renderer, hud_x + 160, hud_y + 258, 'SPECIAL GEM POWERS', 2, Color{r: 255, g: 215, b: 70})
	draw_text(renderer, hud_x + 16, hud_y + 288, '- Match 4 : Flame Gem (3x3 Blast)', 1, Color{r: 255, g: 140, b: 60})
	draw_text(renderer, hud_x + 16, hud_y + 310, '- Match 5 L/T : Star Gem (Cross Laser)', 1, Color{r: 80, g: 240, b: 255})
	draw_text(renderer, hud_x + 16, hud_y + 332, '- Match 5 Line : Hypercube (Color Zap)', 1, Color{r: 255, g: 180, b: 245})
	draw_text(renderer, hud_x + 16, hud_y + 354, '- Match 6+ : Supernova (Mega Blast)', 1, Color{r: 255, g: 225, b: 70})

	bgm_name := match app.sound_mgr.bgm_type {
		.cosmic_trance { 'COSMIC TRANCE' }
		.electro_rush { 'ELECTRO RUSH' }
		.zen_ambient { 'ZEN AMBIENT' }
		.off { 'OFF' }
	}
	draw_text(renderer, hud_x + 16, hud_y + 386, 'MUSIC : ${bgm_name} [T/B]', 1, Color{r: 100, g: 230, b: 255})
	draw_text(renderer, hud_x + 16, hud_y + 408, 'CONTROLS : WASD / ARROWS / MOUSE', 1, Color{r: 200, g: 220, b: 240})
	draw_text(renderer, hud_x + 16, hud_y + 430, '[SPACE/ENTER] SWAP  [U] UNDO', 1, Color{r: 220, g: 220, b: 230})
	draw_text(renderer, hud_x + 16, hud_y + 452, '[H] HINT  [M] MODE  [S] SOUND  [R] RESET  [F11] Fullscreen', 1, Color{r: 180, g: 200, b: 230})

	// Game Over Banner
	if app.game_over {
		banner := Rect{x: 0, y: 690, w: win_width, h: 55}
		set_render_draw_color(renderer, 70, 20, 25, 230)
		render_fill_rect(renderer, &banner)
		draw_text_centered(renderer, win_width / 2, 706, 'TIME OVER! FINAL SCORE: ${app.score} - PRESS [R] TO PLAY AGAIN', 2, Color{r: 255, g: 220, b: 80})
	}

	// Render Buttons
	mx := app.mouse_x
	my := app.mouse_y

	app.btn_reset.render(renderer, mx, my)
	app.btn_hint.render(renderer, mx, my)

	app.btn_mode.text = match app.mode {
		.classic { 'CLASSIC [M]' }
		.zen { 'ZEN [M]' }
		.lightning { 'LIGHTNING [M]' }
		.butterflies { 'BUTTERFLIES [M]' }
		.diamond_mine { 'DIAMOND MINE [M]' }
		.poker { 'POKER [M]' }
		.ice_storm { 'ICE STORM [M]' }
	}
	app.btn_mode.render(renderer, mx, my)

	app.btn_sound.text = if app.sound_mgr.sound_enabled { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
	app.btn_sound.render(renderer, mx, my)

	
	
}

fn (mut app App) get_cell_under_mouse(mx int, my int) (int, int) {
	if mx >= board_x && mx < board_x + grid_w && my >= board_y && my < board_y + grid_h {
		c := (mx - board_x) / cell_size
		r := (my - board_y) / cell_size
		return r, c
	}
	return -1, -1
}


fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.update(f64(dt))
	app.sound_mgr.update()

	app.render()
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	if e.typ in [.mouse_move, .mouse_down, .mouse_up, .mouse_scroll] && app.renderer.scale > 0.001 {
		mut me := unsafe { &gg.Event(e) }
		me.mouse_x = (e.mouse_x - app.renderer.offset_x) / app.renderer.scale
		me.mouse_y = (e.mouse_y - app.renderer.offset_y) / app.renderer.scale
	}
	match e.typ {
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
			app.hover_r, app.hover_c = app.get_cell_under_mouse(app.mouse_x, app.mouse_y)
		}
		.mouse_down {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			if app.btn_reset.is_hovered(mx, my) {
				app.grid = new_grid()
				app.score = 0
				app.level = 1
				app.level_progress = 0
				app.time_left = 60.0
				app.game_over = false
				app.selected_r = -1
				app.selected_c = -1
				app.show_hint = false
				app.sound_mgr.play_swap_sound()
			} else if app.btn_hint.is_hovered(mx, my) {
				p1, p2, ok := app.grid.find_hint_move()
				if ok {
					app.hint_p1 = p1
					app.hint_p2 = p2
					app.show_hint = true
					app.sound_mgr.play_select_sound()
				}
			} else if app.btn_mode.is_hovered(mx, my) {
				app.cycle_mode()
			} else if app.btn_sound.is_hovered(mx, my) {
				app.sound_mgr.toggle_sound()
			} else {
				r, c := app.get_cell_under_mouse(mx, my)
				if r >= 0 && c >= 0 {
					app.handle_gem_click(r, c)
				}
			}
		}
		.key_down {
			match e.key_code {
				.f11, .grave_accent {
					gg.toggle_fullscreen()
				}
				.f10 {
					prod_fx_cycle_mode()
				}
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.escape {
					exit(0)
				}
				.w, .up {
					app.move_cursor(-1, 0)
				}
				.s, .down {
					app.move_cursor(1, 0)
				}
				.a, .left {
					app.move_cursor(0, -1)
				}
				.d, .right {
					app.move_cursor(0, 1)
				}
				.space, .enter, .j, .z {
					app.handle_cursor_action()
				}
				.u {
					if app.has_undo && !app.swap_anim.active && !app.falling {
						app.grid = app.undo_grid
						app.has_undo = false
						app.sound_mgr.play_swap_sound()
					}
				}
				.t, .b {
					app.sound_mgr.cycle_bgm()
				}
				.r {
					app.grid = new_grid()
					app.score = 0
					app.level = 1
					app.level_progress = 0
					app.time_left = 60.0
					app.game_over = false
					app.selected_r = -1
					app.selected_c = -1
					app.show_hint = false
					app.sound_mgr.play_swap_sound()
				}
				.m {
					app.cycle_mode()
				}
				.h {
					p1, p2, ok := app.grid.find_hint_move()
					if ok {
						app.hint_p1 = p1
						app.hint_p2 = p2
						app.show_hint = true
						app.sound_mgr.play_select_sound()
					}
				}
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width: win_width
		height: win_height
		resizable:     true
		window_title: 'Bejeweled // Gem Match-3'
		user_data: &app
		frame_fn: on_frame
		event_fn: on_event
		bg_color: gg.Color{15, 12, 28, 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{ctx: ctx}
	app.init_textures()
	ctx.run()
}
