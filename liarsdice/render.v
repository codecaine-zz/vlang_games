module main

import time

import math

const col_felt = Color{ r: 24, g: 68, b: 42, a: 255 }
const col_felt_dark = Color{ r: 16, g: 45, b: 28, a: 255 }
const col_gold = Color{ r: 240, g: 196, b: 32, a: 255 }
const col_gold_dark = Color{ r: 160, g: 120, b: 16, a: 255 }
const col_wood = Color{ r: 78, g: 42, b: 20, a: 255 }
const col_wood_border = Color{ r: 120, g: 70, b: 35, a: 255 }

const col_pip_red = Color{ r: 220, g: 40, b: 40, a: 255 }
const col_pip_black = Color{ r: 30, g: 30, b: 30, a: 255 }

pub fn render_die_face(renderer &Renderer, x int, y int, size int, face int, is_wild bool) {
	// Drop Shadow
	set_render_draw_color(renderer, 0, 0, 0, 90)
	shadow := Rect{ x: x + 2, y: y + 3, w: size, h: size }
	render_fill_rect(renderer, &shadow)

	// 16-Bit Ivory Bone Die Body
	body := Rect{ x: x, y: y, w: size, h: size }
	set_render_draw_color(renderer, 248, 246, 240, 255)
	render_fill_rect(renderer, &body)

	// Highlight & Shadow Bevel Edges
	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_draw_line(renderer, x, y, x + size - 1, y)
	render_draw_line(renderer, x, y, x, y + size - 1)

	set_render_draw_color(renderer, 175, 175, 180, 255)
	render_draw_line(renderer, x, y + size - 1, x + size - 1, y + size - 1)
	render_draw_line(renderer, x + size - 1, y, x + size - 1, y + size - 1)

	pip_col := if face == 1 || is_wild { col_pip_red } else { col_pip_black }
	pip_r := math.max(2, size / 10)

	cx := x + size / 2
	cy := y + size / 2
	p_off := size / 4

	match face {
		1 {
			draw_die_pip(renderer, cx, cy, pip_r + 2, pip_col)
		}
		2 {
			draw_die_pip(renderer, cx - p_off, cy - p_off, pip_r, pip_col)
			draw_die_pip(renderer, cx + p_off, cy + p_off, pip_r, pip_col)
		}
		3 {
			draw_die_pip(renderer, cx - p_off, cy - p_off, pip_r, pip_col)
			draw_die_pip(renderer, cx, cy, pip_r, pip_col)
			draw_die_pip(renderer, cx + p_off, cy + p_off, pip_r, pip_col)
		}
		4 {
			draw_die_pip(renderer, cx - p_off, cy - p_off, pip_r, pip_col)
			draw_die_pip(renderer, cx + p_off, cy - p_off, pip_r, pip_col)
			draw_die_pip(renderer, cx - p_off, cy + p_off, pip_r, pip_col)
			draw_die_pip(renderer, cx + p_off, cy + p_off, pip_r, pip_col)
		}
		5 {
			draw_die_pip(renderer, cx - p_off, cy - p_off, pip_r, pip_col)
			draw_die_pip(renderer, cx + p_off, cy - p_off, pip_r, pip_col)
			draw_die_pip(renderer, cx, cy, pip_r, pip_col)
			draw_die_pip(renderer, cx - p_off, cy + p_off, pip_r, pip_col)
			draw_die_pip(renderer, cx + p_off, cy + p_off, pip_r, pip_col)
		}
		6 {
			draw_die_pip(renderer, cx - p_off, cy - p_off, pip_r, pip_col)
			draw_die_pip(renderer, cx + p_off, cy - p_off, pip_r, pip_col)
			draw_die_pip(renderer, cx - p_off, cy, pip_r, pip_col)
			draw_die_pip(renderer, cx + p_off, cy, pip_r, pip_col)
			draw_die_pip(renderer, cx - p_off, cy + p_off, pip_r, pip_col)
			draw_die_pip(renderer, cx + p_off, cy + p_off, pip_r, pip_col)
		}
		else {}
	}
}

fn draw_die_pip(renderer &Renderer, cx int, cy int, r int, col Color) {
	draw_filled_circle(renderer, cx, cy, r, col)
	// Inset 3D specular reflection in pip
	if r >= 3 {
		set_render_draw_color(renderer, 255, 255, 255, 180)
		render_draw_point(renderer, cx - 1, cy - 1)
	}
}

pub fn render_dice_cup(renderer &Renderer, x int, y int, w int, h int, is_shaking bool, label string) {
	mut shake_x := 0
	if is_shaking {
		shake_x = int(math.sin(f64(time.ticks()) * 0.05) * 6.0)
	}

	bx := x + shake_x

	// Drop shadow
	set_render_draw_color(renderer, 0, 0, 0, 100)
	shadow := Rect{ x: bx + 3, y: y + 4, w: w, h: h }
	render_fill_rect(renderer, &shadow)

	// 16-Bit Handcrafted Stitched Leather Dice Cup
	draw_beveled_box(renderer, bx, y, w, h, Color{ r: 130, g: 58, b: 24 }, Color{ r: 185, g: 90, b: 42 }, Color{ r: 75, g: 28, b: 12 })

	// Gold Rivet & Stitched Leather Bands
	draw_beveled_box(renderer, bx, y + 8, w, 8, col_gold, Color{ r: 255, g: 235, b: 120 }, col_gold_dark)
	draw_beveled_box(renderer, bx, y + h - 16, w, 8, col_gold, Color{ r: 255, g: 235, b: 120 }, col_gold_dark)

	// Gold Rivets
	for rx := bx + 12; rx < bx + w - 10; rx += 28 {
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_draw_point(renderer, rx, y + 11)
		render_draw_point(renderer, rx, y + h - 13)
	}

	draw_text_centered(renderer, bx + w / 2 + 1, y + h / 2 - 3, label, 1, Color{ r: 25, g: 12, b: 4 })
	draw_text_centered(renderer, bx + w / 2, y + h / 2 - 4, label, 1, Color{ r: 255, g: 245, b: 190 })
}

pub fn render_liarsdice_game(renderer &Renderer, mut g LiarsDiceGame, w int, h int, mx int, my int) {
	// Background wood rim & velvet felt
	draw_beveled_box(renderer, 0, 0, w, h, col_wood, col_wood_border, Color{r:40,g:20,b:10})
	draw_beveled_box(renderer, 16, 16, w - 32, h - 32, col_felt, col_felt_dark, Color{r:8,g:24,b:14})

	// Header
	draw_beveled_box(renderer, 24, 24, w - 48, 50, Color{r:20,g:30,b:25}, col_gold, col_gold_dark)
	draw_text_centered(renderer, w / 2, 34, 'LIAR\'S DICE (PERUDO / DUDO)', 2, col_gold)
	mode_str := if g.is_two_player { '2-PLAYER PASS & PLAY' } else { '1P VS 3 PIRATE BOTS' }
	draw_text(renderer, 36, 44, mode_str, 1, Color{r:180,g:220,b:190})
	draw_text(renderer, w - 240, 44, 'TOTAL DICE: ${g.total_active_dice()}', 1, Color{r:255,g:255,b:255})

	// Active players table positions
	// P1: Bottom, P2: Left, P3: Top, P4: Right
	p_coords := [
		[w / 2 - 130, h - 190], // P1 (You)
		[40, h / 2 - 70],       // P2 (Left)
		[w / 2 - 130, 90],      // P3 (Top)
		[w - 240, h / 2 - 70]   // P4 (Right)
	]

	for i, p in g.players {
		pos := p_coords[i]
		px := pos[0]
		py := pos[1]

		is_active := (g.current_player == i && g.phase == .bidding)
		border_col := if is_active { col_gold } else { Color{r:60,g:90,b:70} }
		bg_col := if p.eliminated { Color{r:40,g:40,b:40} } else { Color{r:20,g:40,b:30} }

		draw_beveled_box(renderer, px, py, 200, 100, bg_col, border_col, Color{r:10,g:20,b:15})

		// Player name & dice count
		name_col := if is_active { col_gold } else { Color{r:230,g:230,b:230} }
		draw_text(renderer, px + 8, py + 8, p.name, 1, name_col)
		draw_text(renderer, px + 120, py + 8, '${p.dice_count} DICE', 1, if p.dice_count == 1 { Color{r:255,g:80,b:80} } else { Color{r:200,g:200,b:200} })

		if p.eliminated {
			draw_text_centered(renderer, px + 100, py + 50, 'OUT OF DICE', 1, Color{r:150,g:60,b:60})
			continue
		}

		// Dice rendering (hidden under cup or visible)
		show_dice := (p.peek_dice || g.phase == .challenge_reveal || g.phase == .round_over || g.phase == .game_over)

		if show_dice {
			for d_idx, val in p.dice {
				dx := px + 10 + d_idx * 36
				dy := py + 36
				is_wild_match := (g.last_bid.face != 0 && (val == g.last_bid.face || (g.wild_ones && g.last_bid.face != 1 && val == 1)))
				render_die_face(renderer, dx, dy, 32, val, val == 1 && g.wild_ones)
				if is_wild_match && (g.phase == .challenge_reveal || g.phase == .round_over) {
					draw_circle_outline(renderer, dx + 16, dy + 16, 18, col_gold)
				}
			}
		} else {
			render_dice_cup(renderer, px + 10, py + 28, 180, 60, g.phase == .rolling, '${p.dice_count} DICE IN CUP')
		}
	}

	// Center Arena (Current Bid / Challenge Spotlight)
	arena_x := w / 2 - 160
	arena_y := h / 2 - 75
	draw_beveled_box(renderer, arena_x, arena_y, 320, 150, Color{r:15,g:30,b:22}, col_gold, Color{r:10,g:15,b:10})

	if g.last_bid.qty > 0 {
		draw_text_centered(renderer, w / 2, arena_y + 12, 'CURRENT BID', 1, Color{r:180,g:220,b:200})
		draw_text_centered(renderer, w / 2, arena_y + 35, '${g.last_bid.qty} x', 3, col_gold)
		render_die_face(renderer, w / 2 + 60, arena_y + 28, 44, g.last_bid.face, g.last_bid.face == 1 && g.wild_ones)
		bidder_name := g.players[g.last_bidder].name
		draw_text_centered(renderer, w / 2, arena_y + 85, 'BID BY: ${bidder_name}', 1, Color{r:255,g:255,b:255})
	} else {
		draw_text_centered(renderer, w / 2, arena_y + 35, 'NO BIDS YET', 2, Color{r:160,g:180,b:170})
		draw_text_centered(renderer, w / 2, arena_y + 75, 'AWAITING OPENING BID', 1, col_gold)
	}

	if g.wild_ones {
		draw_text_centered(renderer, w / 2, arena_y + 120, '★ ONES (1s) ARE WILD! ★', 1, Color{r:255,g:100,b:100})
	}

	// Interactive Human Control Panel (when it's P1 turn and in bidding phase)
	cur_p := g.players[g.current_player]
	if !cur_p.is_ai && g.phase == .bidding {
		panel_y := h - 85
		draw_beveled_box(renderer, 24, panel_y, w - 48, 55, Color{r:25,g:35,b:30}, col_gold, Color{r:10,g:15,b:12})

		// Qty adjust
		draw_text(renderer, 40, panel_y + 18, 'QTY:', 1, Color{r:255,g:255,b:255})
		draw_beveled_box(renderer, 80, panel_y + 10, 30, 32, Color{r:40,g:50,b:45}, col_gold, col_gold_dark)
		draw_text_centered(renderer, 95, panel_y + 18, '-', 2, Color{r:255,g:255,b:255})

		draw_text_centered(renderer, 135, panel_y + 18, '${g.selected_qty}', 2, col_gold)

		draw_beveled_box(renderer, 160, panel_y + 10, 30, 32, Color{r:40,g:50,b:45}, col_gold, col_gold_dark)
		draw_text_centered(renderer, 175, panel_y + 18, '+', 2, Color{r:255,g:255,b:255})

		// Face adjust
		draw_text(renderer, 210, panel_y + 18, 'FACE:', 1, Color{r:255,g:255,b:255})
		for f := 1; f <= 6; f++ {
			fx := 260 + (f - 1) * 44
			is_sel := (g.selected_face == f)
			border := if is_sel { col_gold } else { Color{r:80,g:80,b:80} }
			draw_beveled_box(renderer, fx - 2, panel_y + 8, 36, 36, Color{r:30,g:30,b:30}, border, Color{r:10,g:10,b:10})
			render_die_face(renderer, fx, panel_y + 10, 32, f, f == 1 && g.wild_ones)
		}

		// Action Buttons
		// BID Button
		is_valid := Bid{ qty: g.selected_qty, face: g.selected_face }.is_valid_higher(g.last_bid, g.total_active_dice())
		bid_bg := if is_valid { Color{r:30,g:120,b:45} } else { Color{r:60,g:60,b:60} }
		draw_beveled_box(renderer, 540, panel_y + 10, 100, 34, bid_bg, col_gold, col_gold_dark)
		draw_text_centered(renderer, 590, panel_y + 20, 'BID [SPACE]', 1, Color{r:255,g:255,b:255})

		// LIAR! Button
		can_challenge := (g.last_bidder != -1)
		liar_bg := if can_challenge { Color{r:180,g:40,b:40} } else { Color{r:60,g:60,b:60} }
		draw_beveled_box(renderer, 655, panel_y + 10, 110, 34, liar_bg, Color{r:255,g:100,b:100}, Color{r:100,g:20,b:20})
		draw_text_centered(renderer, 710, panel_y + 20, 'LIAR! [L]', 1, Color{r:255,g:255,b:255})

		// SPOT ON! Button
		spot_bg := if can_challenge { Color{r:30,g:100,b:180} } else { Color{r:60,g:60,b:60} }
		draw_beveled_box(renderer, 780, panel_y + 10, 110, 34, spot_bg, Color{r:100,g:180,b:255}, Color{r:20,g:60,b:100})
		draw_text_centered(renderer, 835, panel_y + 20, 'SPOT ON! [C]', 1, Color{r:255,g:255,b:255})
	}

	// Status Banner & Round Over Controls
	if g.phase == .round_over {
		draw_beveled_box(renderer, w / 2 - 200, h - 85, 400, 48, Color{r:30,g:40,b:60}, col_gold, col_gold_dark)
		draw_text_centered(renderer, w / 2, h - 68, 'ROUND COMPLETE - PRESS SPACE FOR NEXT ROUND', 1, col_gold)
	} else if g.phase == .game_over {
		draw_beveled_box(renderer, w / 2 - 220, h - 85, 440, 48, Color{r:50,g:20,b:20}, col_gold, col_gold_dark)
		draw_text_centered(renderer, w / 2, h - 68, 'GAME OVER - PRESS R TO PLAY AGAIN', 1, col_gold)
	}

	// Bottom Status ticker
	draw_text_centered(renderer, w / 2, h - 22, g.status_message, 1, Color{r:220,g:240,b:220})
}
