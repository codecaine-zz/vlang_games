module main

import math
import os



pub struct AirHockeyTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm AirHockeyTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/airhockey.png',
		'./assets/sprites/airhockey.png',
		'../assets/sprites/airhockey.png',
		'airhockey/assets/sprites/airhockey.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('airhockey Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

const col_rink_surface = Color{ r: 235, g: 240, b: 245, a: 255 }
const col_rink_border = Color{ r: 25, g: 30, b: 40, a: 255 }
const col_rail_inner = Color{ r: 200, g: 30, b: 30, a: 255 }
const col_rail_metal = Color{ r: 160, g: 170, b: 180, a: 255 }
const col_red_line = Color{ r: 220, g: 40, b: 40, a: 255 }
const col_blue_line = Color{ r: 40, g: 100, b: 220, a: 255 }
const col_p1_mallet = Color{ r: 230, g: 45, b: 45, a: 255 }
const col_p2_mallet = Color{ r: 45, g: 120, b: 240, a: 255 }
const col_puck = Color{ r: 20, g: 20, b: 20, a: 255 }
const col_puck_rim = Color{ r: 255, g: 215, b: 0, a: 255 }

pub fn render_airhockey_game(renderer &Renderer, mut g AirHockeyGame, w int, h int, tex &Texture) {
	// Dark cyber floor backdrop
	draw_beveled_box(renderer, 0, 0, w, h, Color{r:12,g:15,b:20}, Color{r:30,g:40,b:50}, Color{r:5,g:8,b:10})

	// Top Score & Status Header
	draw_beveled_box(renderer, 24, 15, w - 48, 60, Color{r:20,g:25,b:35}, Color{r:60,g:80,b:110}, Color{r:10,g:12,b:18})

	// P1 Name & Score (Red)
	draw_text(renderer, 45, 28, 'PLAYER 1', 2, col_p1_mallet)
	draw_text_centered(renderer, w / 2 - 120, 26, '${g.score_p1}', 4, col_p1_mallet)

	// Center Title & VS
	draw_text_centered(renderer, w / 2, 28, 'HYPER AIR HOCKEY', 2, Color{r:255,g:255,b:255})
	mode_str := if g.is_two_player { '2P LOCAL VERSUS' } else { '1P VS AI (${g.difficulty})' }
	draw_text_centered(renderer, w / 2, 52, mode_str, 1, Color{r:160,g:200,b:240})

	// P2 / AI Name & Score (Blue)
	p2_label := if g.is_two_player { 'PLAYER 2' } else { 'AI BOT' }
	draw_text_centered(renderer, w / 2 + 120, 26, '${g.score_p2}', 4, col_p2_mallet)
	draw_text(renderer, w - 180, 28, p2_label, 2, col_p2_mallet)

	// Outer Table Rails
	tx := int(g.table_x)
	ty := int(g.table_y)
	tw := int(g.table_w)
	th := int(g.table_h)

	// Heavy metallic rail border
	draw_beveled_box(renderer, tx - 16, ty - 16, tw + 32, th + 32, col_rail_metal, Color{r:220,g:230,b:240}, Color{r:90,g:100,b:110})
	draw_beveled_box(renderer, tx - 8, ty - 8, tw + 16, th + 16, col_rink_border, Color{r:50,g:60,b:70}, Color{r:15,g:20,b:25})

	// Slick Rink Surface
	draw_beveled_box(renderer, tx, ty, tw, th, col_rink_surface, Color{r:255,g:255,b:255}, Color{r:180,g:190,b:200})

	// Perforation Air Holes pattern (subtle dots)
	set_render_draw_color(renderer, 210, 220, 230, 255)
	for hx := tx + 20; hx < tx + tw - 20; hx += 28 {
		for hy := ty + 20; hy < ty + th - 20; hy += 28 {
			render_draw_point(renderer, hx, hy)
		}
	}

	// Center Red Line & Face-off Circle
	cx := tx + tw / 2
	cy := ty + th / 2

	set_render_draw_color(renderer, col_red_line.r, col_red_line.g, col_red_line.b, col_red_line.a)
	center_rect := Rect{ x: cx - 3, y: ty, w: 6, h: th }
	render_fill_rect(renderer, &center_rect)

	draw_circle_outline(renderer, cx, cy, 70, col_blue_line)
	draw_circle_outline(renderer, cx, cy, 71, col_blue_line)
	draw_filled_circle(renderer, cx, cy, 8, col_red_line)

	// Goal Arcs (Crease)
	draw_circle_outline(renderer, tx, cy, 90, col_red_line)
	draw_circle_outline(renderer, tx, cy, 91, col_red_line)
	draw_circle_outline(renderer, tx + tw, cy, 90, col_red_line)
	draw_circle_outline(renderer, tx + tw, cy, 91, col_red_line)

	// Goal Net Openings (Left & Right)
	goal_top := ty + int((g.table_h - g.goal_h) / 2.0)
	goal_h := int(g.goal_h)

	// Left Goal Net
	draw_beveled_box(renderer, tx - 14, goal_top, 14, goal_h, Color{r:10,g:10,b:15}, col_p1_mallet, Color{r:60,g:10,b:10})
	// Right Goal Net
	draw_beveled_box(renderer, tx + tw, goal_top, 14, goal_h, Color{r:10,g:10,b:15}, col_p2_mallet, Color{r:10,g:20,b:60})

	// Puck Motion Trail
	for i, pt in g.puck.trail {
		alpha := u8(int(20 + (f64(i) / f64(g.puck.trail.len)) * 100.0))
		tr_r := int(g.puck.radius * (0.4 + 0.6 * (f64(i) / f64(g.puck.trail.len))))
		draw_filled_circle(renderer, int(pt[0]), int(pt[1]), tr_r, Color{r: 255, g: 215, b: 0, a: alpha})
	}

	// Render Puck
	px := int(g.puck.x)
	py := int(g.puck.y)
	pr := int(g.puck.radius)
	if tex != unsafe { nil } {
		src := Rect{ x: 0, y: 64, w: 64, h: 64 }
		dst := Rect{ x: px - pr, y: py - pr, w: pr * 2, h: pr * 2 }
		render_copy(renderer, tex, &src, &dst)
	} else {
		draw_filled_circle(renderer, px, py, pr, col_puck)
		draw_circle_outline(renderer, px, py, pr, col_puck_rim)
		draw_filled_circle(renderer, px, py, pr / 2, col_rail_inner)
	}

	// Render P1 Mallet (Red)
	m1x := int(g.p1_mallet.x)
	m1y := int(g.p1_mallet.y)
	m1r := int(g.p1_mallet.radius)
	if tex != unsafe { nil } {
		src := Rect{ x: 0, y: 0, w: 64, h: 64 }
		dst := Rect{ x: m1x - m1r, y: m1y - m1r, w: m1r * 2, h: m1r * 2 }
		render_copy(renderer, tex, &src, &dst)
	} else {
		draw_filled_circle(renderer, m1x, m1y, m1r, col_p1_mallet)
		draw_circle_outline(renderer, m1x, m1y, m1r, Color{r:255,g:160,b:160})
		draw_filled_circle(renderer, m1x, m1y, m1r / 2, Color{r:160,g:20,b:20})
		draw_filled_circle(renderer, m1x, m1y, m1r / 4, Color{r:255,g:255,b:255})
	}

	// Render P2 Mallet (Blue)
	m2x := int(g.p2_mallet.x)
	m2y := int(g.p2_mallet.y)
	m2r := int(g.p2_mallet.radius)
	if tex != unsafe { nil } {
		src_col := if g.is_two_player { 1 } else { 2 }
		src := Rect{ x: src_col * 64, y: 0, w: 64, h: 64 }
		dst := Rect{ x: m2x - m2r, y: m2y - m2r, w: m2r * 2, h: m2r * 2 }
		render_copy(renderer, tex, &src, &dst)
	} else {
		draw_filled_circle(renderer, m2x, m2y, m2r, col_p2_mallet)
		draw_circle_outline(renderer, m2x, m2y, m2r, Color{r:160,g:200,b:255})
		draw_filled_circle(renderer, m2x, m2y, m2r / 2, Color{r:20,g:60,b:160})
		draw_filled_circle(renderer, m2x, m2y, m2r / 4, Color{r:255,g:255,b:255})
	}

	// Render Particles / Collision Sparks
	for p in g.particles {
		alpha := u8(math.clamp(p.life / p.max_l * 255.0, 0.0, 255.0))
		draw_filled_circle(renderer, int(p.x), int(p.y), 2, Color{r: p.r, g: p.g, b: p.b, a: alpha})
	}

	// Goal Celebration Banner
	if g.state == .goal_celebration {
		banner_y := h / 2 - 45
		draw_beveled_box(renderer, w / 2 - 220, banner_y, 440, 90, Color{r:20,g:20,b:30}, col_puck_rim, Color{r:100,g:80,b:10})
		scorer_name := if g.goal_scorer == 1 { 'PLAYER 1 SCORES!' } else { if g.is_two_player { 'PLAYER 2 SCORES!' } else { 'AI BOT SCORES!' } }
		scorer_col := if g.goal_scorer == 1 { col_p1_mallet } else { col_p2_mallet }
		draw_text_centered(renderer, w / 2, banner_y + 16, '★ GOAL! ★', 3, col_puck_rim)
		draw_text_centered(renderer, w / 2, banner_y + 55, scorer_name, 2, scorer_col)
	}

	// Game Over Banner
	if g.state == .game_over {
		banner_y := h / 2 - 60
		draw_beveled_box(renderer, w / 2 - 260, banner_y, 520, 120, Color{r:15,g:20,b:30}, col_puck_rim, Color{r:80,g:60,b:10})
		winner_name := if g.score_p1 >= g.max_score { 'PLAYER 1 WINS THE MATCH!' } else { if g.is_two_player { 'PLAYER 2 WINS!' } else { 'AI BOT WINS!' } }
		draw_text_centered(renderer, w / 2, banner_y + 20, '🏆 CHAMPION! 🏆', 3, col_puck_rim)
		draw_text_centered(renderer, w / 2, banner_y + 58, winner_name, 2, Color{r:255,g:255,b:255})
		draw_text_centered(renderer, w / 2, banner_y + 92, 'PRESS SPACE OR R TO REMATCH', 1, Color{r:180,g:220,b:255})
	}

	// Bottom Controls Help
	draw_text_centered(renderer, w / 2, h - 22, 'P1: Mouse/WASD | P2: Arrows/IJKL | M: Mode | Tab: AI Diff | R: Reset | V: Sound | F11: Fullscreen', 1, Color{r:160,g:180,b:200})
}
