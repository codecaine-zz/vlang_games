module main

import math
import os
import time

pub struct YahtzeeTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm YahtzeeTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/yahtzee.png',
		'./assets/sprites/yahtzee.png',
		'../assets/sprites/yahtzee.png',
		'yahtzee/assets/sprites/yahtzee.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('yahtzee Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn render_yahtzee_game(renderer &Renderer, mut g YahtzeeGame, win_w int, win_h int, mouse_x int, mouse_y int, sound_enabled bool, tex &Texture) {
	// 1. Rich Casino Green Felt Background
	set_render_draw_color(renderer, 20, 75, 45, 255)
	clear_rect := Rect{0, 0, win_w, win_h}
	render_fill_rect(renderer, &clear_rect)

	// Mahogany Wood Border
	set_render_draw_color(renderer, 95, 45, 20, 255)
	for i in 0 .. 6 {
		r := Rect{i, i, win_w - i * 2, win_h - i * 2}
		render_draw_rect(renderer, &r)
	}

	// 2. Top Header Navigation Bar
	render_header_bar(renderer, g, win_w, sound_enabled)

	// 3. Left Side: Dice Tray & Rolling Area
	tray_x := 30
	tray_y := 70
	tray_w := 460
	tray_h := 570
	render_dice_tray(renderer, g, tray_x, tray_y, tray_w, tray_h, mouse_x, mouse_y, tex)

	// 4. Right Side: Master Scorecard Table
	score_x := 510
	score_y := 70
	score_w := 380
	score_h := 570
	render_scorecard(renderer, g, score_x, score_y, score_w, score_h, mouse_x, mouse_y)

	// 5. Draw Confetti Particles
	for p in g.confetti {
		set_render_draw_color(renderer, p.col.r, p.col.g, p.col.b, 255)
		c_rect := Rect{int(p.x), int(p.y), p.w, p.h}
		render_fill_rect(renderer, &c_rect)
	}

	// 6. Center Announcement Banner
	if g.banner_timer > 0.0 && g.banner_text != '' {
		banner_w := g.banner_text.len * 8 * 2 + 40
		bx := win_w / 2 - banner_w / 2
		by := 280

		set_render_draw_color(renderer, 15, 20, 30, 240)
		bg_rect := Rect{bx, by, banner_w, 44}
		render_fill_rect(renderer, &bg_rect)

		set_render_draw_color(renderer, 255, 215, 0, 255)
		render_draw_rect(renderer, &bg_rect)

		draw_text_centered(renderer, win_w / 2, by + 14, g.banner_text, 2, Color{255, 235, 100, 255})
	}
}

fn render_header_bar(renderer &Renderer, g YahtzeeGame, win_w int, sound_enabled bool) {
	set_render_draw_color(renderer, 15, 30, 22, 255)
	bar := Rect{0, 0, win_w, 50}
	render_fill_rect(renderer, &bar)

	set_render_draw_color(renderer, 200, 160, 40, 255)
	render_draw_line(renderer, 0, 49, win_w, 49)

	// Title
	draw_text(renderer, 24, 16, '★ YAHTZEE DELUXE ★', 2, Color{255, 220, 80, 255})

	// Round indicator
	draw_text(renderer, 310, 18, 'ROUND: ${g.round}/13', 1, Color{240, 240, 240, 255})

	// Mode selector tabs
	modes := ['1: SOLO', '2: VS AI', '3: 2P']
	g_modes := [GameMode.solo, GameMode.vs_ai, GameMode.two_player]
	for i, m_label in modes {
		mx := 460 + i * 90
		is_active := g.mode == g_modes[i]
		if is_active {
			set_render_draw_color(renderer, 255, 215, 0, 255)
			btn := Rect{mx, 12, 80, 26}
			render_fill_rect(renderer, &btn)
			draw_text_centered(renderer, mx + 40, 18, m_label, 1, Color{30, 30, 30, 255})
		} else {
			set_render_draw_color(renderer, 35, 60, 45, 255)
			btn := Rect{mx, 12, 80, 26}
			render_fill_rect(renderer, &btn)
			draw_text_centered(renderer, mx + 40, 18, m_label, 1, Color{200, 200, 200, 200})
		}
	}

	// Sound / Mute toggle badge
	sound_x := win_w - 145
	if sound_enabled {
		set_render_draw_color(renderer, 45, 120, 60, 255)
		btn := Rect{sound_x, 12, 125, 26}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 62, 18, 'SOUND: ON [M]', 1, Color{255, 255, 255, 255})
	} else {
		set_render_draw_color(renderer, 120, 35, 40, 255)
		btn := Rect{sound_x, 12, 125, 26}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 62, 18, 'MUTED [M]', 1, Color{255, 180, 180, 255})
	}
}

fn render_dice_tray(renderer &Renderer, g YahtzeeGame, x int, y int, w int, h int, mouse_x int, mouse_y int, tex &Texture) {
	// Wood Tray Inset
	set_render_draw_color(renderer, 15, 55, 32, 255)
	tray_bg := Rect{x, y, w, h}
	render_fill_rect(renderer, &tray_bg)

	set_render_draw_color(renderer, 130, 75, 30, 255)
	for i in 0 .. 4 {
		r := Rect{x + i, y + i, w - i * 2, h - i * 2}
		render_draw_rect(renderer, &r)
	}

	// Turn Indicator
	cur_player := g.players[g.current_player]
	p_color := if cur_player.is_ai { Color{255, 130, 100, 255} } else { Color{100, 230, 255, 255} }
	draw_text(renderer, x + 20, y + 24, "CURRENT TURN: ${cur_player.name.to_upper()}", 2, p_color)

	// Rolls Remaining Indicator
	mut roll_dots := ''
	for _ in 0 .. g.rolls_left {
		roll_dots += '● '
	}
	draw_text(renderer, x + 20, y + 54, 'ROLLS LEFT: ${roll_dots}', 1, Color{255, 230, 100, 255})

	// Instructions text
	draw_text(renderer, x + 20, y + 76, 'CLICK DICE (OR KEYS 1-5) TO HOLD / KEEP', 1, Color{200, 225, 210, 220})

	// Draw Shaker Cup Graphic
	cup_x := x + w / 2
	cup_y := y + 160
	render_shaker_cup(renderer, cup_x, cup_y, g.is_rolling(), tex)

	// Draw 5 Dice
	for i, d in g.dice {
		dx := int(d.x)
		dy := int(d.y)
		render_single_die(renderer, dx, dy, d.value, d.held, i + 1, tex)
	}

	// Big ROLL DICE Button
	btn_x := x + 50
	btn_y := y + h - 85
	btn_w := w - 100
	btn_h := 55

	is_btn_hover := mouse_x >= btn_x && mouse_x <= btn_x + btn_w && mouse_y >= btn_y && mouse_y <= btn_y + btn_h

	if g.rolls_left > 0 && !g.is_rolling() && !g.is_game_over {
		btn_col := if is_btn_hover { Color{255, 230, 50, 255} } else { Color{235, 195, 30, 255} }
		set_render_draw_color(renderer, btn_col.r, btn_col.g, btn_col.b, 255)
		b_rect := Rect{btn_x, btn_y, btn_w, btn_h}
		render_fill_rect(renderer, &b_rect)

		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_draw_rect(renderer, &b_rect)

		roll_title := if g.rolls_left == 3 { 'ROLL DICE [SPACE]' } else { 'ROLL AGAIN [SPACE] (${g.rolls_left} LEFT)' }
		draw_text_centered(renderer, btn_x + btn_w / 2, btn_y + 18, roll_title, 2, Color{40, 25, 5, 255})
	} else {
		// Disabled button
		set_render_draw_color(renderer, 50, 70, 60, 255)
		b_rect := Rect{btn_x, btn_y, btn_w, btn_h}
		render_fill_rect(renderer, &b_rect)

		draw_text_centered(renderer, btn_x + btn_w / 2, btn_y + 18, 'SELECT A CATEGORY TO SCORE', 2, Color{160, 180, 170, 255})
	}
}

fn render_shaker_cup(renderer &Renderer, cx int, cy int, is_shaking bool, tex &Texture) {
	mut shake_ox := 0
	if is_shaking {
		shake_ox = int(math.sin(f64(u32(time.ticks())) * 0.05) * 8.0)
	}

	if tex != unsafe { nil } {
		src := Rect{x: 0, y: 192, w: 64, h: 64}
		dst := Rect{x: cx - 40 + shake_ox, y: cy - 40, w: 80, h: 80}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	x := cx - 45 + shake_ox
	y := cy - 40

	// Leather dice cup
	set_render_draw_color(renderer, 110, 50, 20, 255)
	cup_body := Rect{x, y, 90, 75}
	render_fill_rect(renderer, &cup_body)

	// Cup gold stitching
	set_render_draw_color(renderer, 220, 180, 60, 255)
	render_draw_line(renderer, x + 5, y + 10, x + 85, y + 10)
	render_draw_line(renderer, x + 5, y + 65, x + 85, y + 65)

	// Cup Rim
	set_render_draw_color(renderer, 150, 75, 30, 255)
	rim := Rect{x - 4, y - 6, 98, 12}
	render_fill_rect(renderer, &rim)
}

fn render_single_die(renderer &Renderer, x int, y int, value int, held bool, num int, tex &Texture) {
	d_size := 64
	half := d_size / 2

	if tex != unsafe { nil } && value >= 1 && value <= 6 {
		src := Rect{x: (value - 1) * 64, y: 0, w: 64, h: 64}
		dst := Rect{x: x - half, y: y - half, w: d_size, h: d_size}
		render_copy(renderer, tex, &src, &dst)

		if held {
			set_render_draw_color(renderer, 255, 215, 0, 255)
			for i in 0 .. 3 {
				r := Rect{ x: x - half - i, y: y - half - i, w: d_size + i * 2, h: d_size + i * 2 }
				render_draw_rect(renderer, &r)
			}
			badge := Rect{ x: x - 24, y: y - half - 16, w: 48, h: 14 }
			render_fill_rect(renderer, &badge)
			draw_text_centered(renderer, x, y - half - 13, 'HELD', 1, Color{ 30, 20, 0, 255 })
		}

		draw_text_centered(renderer, x, y + half + 6, '[${num}]', 1, Color{ 180, 220, 200, 255 })
		return
	}

	// Multi-layer Soft Drop Shadow
	set_render_draw_color(renderer, 0, 0, 0, 80)
	sh_rect := Rect{ x: x - half + 3, y: y - half + 5, w: d_size, h: d_size }
	render_fill_rect(renderer, &sh_rect)

	// 16-Bit Ivory Bone Die Body
	set_render_draw_color(renderer, 252, 250, 244, 255)
	d_rect := Rect{ x: x - half, y: y - half, w: d_size, h: d_size }
	render_fill_rect(renderer, &d_rect)

	// Highlight & Shadow 3D Bevels
	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_draw_line(renderer, x - half, y - half, x + half - 1, y - half)
	render_draw_line(renderer, x - half, y - half, x - half, y + half - 1)

	set_render_draw_color(renderer, 185, 188, 198, 255)
	render_draw_line(renderer, x - half, y + half - 1, x + half - 1, y + half - 1)
	render_draw_line(renderer, x + half - 1, y - half, x + half - 1, y + half - 1)

	// Pips Rendering
	pip_col := if value == 1 { Color{ 220, 30, 40, 255 } } else { Color{ 24, 26, 32, 255 } }
	pip_r := if value == 1 { 8 } else { 5 }
	offset := 16

	match value {
		1 {
			draw_yahtzee_pip(renderer, x, y, pip_r, pip_col)
		}
		2 {
			draw_yahtzee_pip(renderer, x - offset, y - offset, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x + offset, y + offset, pip_r, pip_col)
		}
		3 {
			draw_yahtzee_pip(renderer, x - offset, y - offset, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x, y, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x + offset, y + offset, pip_r, pip_col)
		}
		4 {
			draw_yahtzee_pip(renderer, x - offset, y - offset, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x + offset, y - offset, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x - offset, y + offset, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x + offset, y + offset, pip_r, pip_col)
		}
		5 {
			draw_yahtzee_pip(renderer, x - offset, y - offset, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x + offset, y - offset, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x, y, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x - offset, y + offset, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x + offset, y + offset, pip_r, pip_col)
		}
		6 {
			draw_yahtzee_pip(renderer, x - offset, y - offset, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x + offset, y - offset, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x - offset, y, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x + offset, y, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x - offset, y + offset, pip_r, pip_col)
			draw_yahtzee_pip(renderer, x + offset, y + offset, pip_r, pip_col)
		}
		else {}
	}

	// Held Lock Frame & Golden Badge
	if held {
		set_render_draw_color(renderer, 255, 215, 0, 255)
		for i in 0 .. 3 {
			r := Rect{ x: x - half - i, y: y - half - i, w: d_size + i * 2, h: d_size + i * 2 }
			render_draw_rect(renderer, &r)
		}

		// "HELD" badge
		badge := Rect{ x: x - 24, y: y - half - 16, w: 48, h: 14 }
		render_fill_rect(renderer, &badge)
		draw_text_centered(renderer, x, y - half - 13, 'HELD', 1, Color{ 30, 20, 0, 255 })
	}

	// Key indicator below die
	draw_text_centered(renderer, x, y + half + 6, '[${num}]', 1, Color{ 180, 220, 200, 255 })
}

fn draw_yahtzee_pip(renderer &Renderer, cx int, cy int, r int, col Color) {
	draw_filled_circle(renderer, cx, cy, r, col)
	// Specular pip reflection
	if r >= 4 {
		set_render_draw_color(renderer, 255, 255, 255, 200)
		render_draw_point(renderer, cx - 1, cy - 1)
	}
}

fn render_scorecard(renderer &Renderer, g YahtzeeGame, x int, y int, w int, h int, mouse_x int, mouse_y int) {
	// Scorecard Background (Crisp Ivory Paper)
	set_render_draw_color(renderer, 245, 245, 240, 255)
	card_bg := Rect{x, y, w, h}
	render_fill_rect(renderer, &card_bg)

	// Border
	set_render_draw_color(renderer, 100, 80, 50, 255)
	for i in 0 .. 2 {
		r := Rect{x + i, y + i, w - i * 2, h - i * 2}
		render_draw_rect(renderer, &r)
	}

	// Header Row
	set_render_draw_color(renderer, 60, 45, 30, 255)
	h_rect := Rect{x, y, w, 28}
	render_fill_rect(renderer, &h_rect)
	draw_text(renderer, x + 12, y + 8, 'YAHTZEE SCORECARD', 1, Color{255, 230, 120, 255})

	for pi, pl in g.players {
		px := x + w - 120 + pi * 55
		p_color := if pi == g.current_player { Color{255, 230, 80, 255} } else { Color{200, 200, 200, 255} }
		draw_text_centered(renderer, px, y + 8, pl.name, 1, p_color)
	}

	// Categories List
	row_h := 24
	mut cur_y := y + 30

	upper_cats := [
		Category.ones,
		.twos,
		.threes,
		.fours,
		.fives,
		.sixes,
	]
	upper_names := ['Aces (Ones)', 'Twos', 'Threes', 'Fours', 'Fives', 'Sixes']

	// Section 1: Upper Section
	draw_text(renderer, x + 8, cur_y + 4, 'UPPER SECTION', 1, Color{100, 40, 20, 255})
	cur_y += 18

	for i, cat in upper_cats {
		render_score_row(renderer, g, cat, upper_names[i], x, cur_y, w, row_h, mouse_x, mouse_y)
		cur_y += row_h
	}

	// Upper Subtotal & Bonus
	p0 := g.players[g.current_player]
	upper_sub := p0.get_upper_subtotal()
	bonus_pts := if upper_sub >= 63 { 35 } else { 0 }

	set_render_draw_color(renderer, 230, 230, 220, 255)
	sub_rect := Rect{x, cur_y, w, row_h * 2}
	render_fill_rect(renderer, &sub_rect)

	draw_text(renderer, x + 12, cur_y + 4, 'Upper Subtotal (Target 63):', 1, Color{60, 60, 60, 255})
	draw_text_centered(renderer, x + w - 70, cur_y + 4, '${upper_sub} / 63', 1, Color{0, 100, 40, 255})
	cur_y += row_h

	bonus_str := if upper_sub >= 63 { '+35 BONUS!' } else { '+35 if >=63' }
	draw_text(renderer, x + 12, cur_y + 4, 'Bonus (Score >= 63):', 1, Color{60, 60, 60, 255})
	draw_text_centered(renderer, x + w - 70, cur_y + 4, '${bonus_pts} (${bonus_str})', 1, Color{180, 40, 20, 255})
	cur_y += row_h + 4

	// Section 2: Lower Section
	draw_text(renderer, x + 8, cur_y + 4, 'LOWER SECTION', 1, Color{100, 40, 20, 255})
	cur_y += 18

	lower_cats := [
		Category.three_of_kind,
		.four_of_kind,
		.full_house,
		.small_straight,
		.large_straight,
		.yahtzee,
		.chance,
	]
	lower_names := [
		'3 of a Kind',
		'4 of a Kind',
		'Full House (25)',
		'Small Straight (30)',
		'Large Straight (40)',
		'YAHTZEE (50)',
		'Chance',
	]

	for i, cat in lower_cats {
		render_score_row(renderer, g, cat, lower_names[i], x, cur_y, w, row_h, mouse_x, mouse_y)
		cur_y += row_h
	}

	// Yahtzee Bonus Row
	draw_text(renderer, x + 12, cur_y + 4, 'Yahtzee Bonus (+100 ea):', 1, Color{60, 60, 60, 255})
	draw_text_centered(renderer, x + w - 70, cur_y + 4, '+${p0.yahtzee_bonus}', 1, Color{200, 120, 0, 255})
	cur_y += row_h

	// Grand Total Bar
	set_render_draw_color(renderer, 40, 30, 20, 255)
	gt_rect := Rect{x, cur_y, w, 34}
	render_fill_rect(renderer, &gt_rect)

	draw_text(renderer, x + 12, cur_y + 10, 'GRAND TOTAL:', 2, Color{255, 215, 0, 255})
	draw_text_centered(renderer, x + w - 70, cur_y + 10, '${p0.get_grand_total()}', 2, Color{255, 235, 120, 255})
}

fn render_score_row(renderer &Renderer, g YahtzeeGame, cat Category, label string, x int, y int, w int, h int, mouse_x int, mouse_y int) {
	is_hover := mouse_x >= x && mouse_x <= x + w && mouse_y >= y && mouse_y <= y + h
	cur_pl := g.players[g.current_player]
	is_filled := cur_pl.is_filled(cat)

	if is_hover && !is_filled && g.rolls_left < 3 {
		set_render_draw_color(renderer, 255, 245, 180, 255)
		r := Rect{x + 2, y, w - 4, h}
		render_fill_rect(renderer, &r)
		set_render_draw_color(renderer, 220, 160, 30, 255)
		render_draw_rect(renderer, &r)
	} else if (y / h) % 2 == 0 {
		set_render_draw_color(renderer, 238, 238, 232, 255)
		r := Rect{x + 2, y, w - 4, h}
		render_fill_rect(renderer, &r)
	}

	// Category Label
	lbl_col := if is_filled { Color{100, 100, 100, 255} } else { Color{20, 20, 25, 255} }
	draw_text(renderer, x + 12, y + 6, label, 1, lbl_col)

	// Scores for all players
	for pi, pl in g.players {
		px := x + w - 120 + pi * 55
		if pl.is_filled(cat) {
			score_val := pl.scores[cat.str()]
			draw_text_centered(renderer, px, y + 6, '${score_val}', 1, Color{20, 30, 60, 255})
		} else if pi == g.current_player && g.rolls_left < 3 && !g.is_rolling() {
			potential := g.calculate_score(cat)
			draw_text_centered(renderer, px, y + 6, '(${potential})', 1, Color{190, 140, 0, 255})
		} else {
			draw_text_centered(renderer, px, y + 6, '-', 1, Color{160, 160, 160, 255})
		}
	}
}
