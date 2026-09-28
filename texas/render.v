module main

import math

fn draw_texas_game(renderer &Renderer, g &TexasGame) {
	// Screen shake calculation
	mut shake_x := 0
	mut shake_y := 0
	if g.shake_timer > 0.0 && g.shake_intensity > 0.0 {
		decay := g.shake_timer / 0.45
		s := g.shake_intensity * decay
		shake_x = int(math.sin(g.anim_timer * 45.0) * s)
		shake_y = int(math.cos(g.anim_timer * 40.0) * s)
	}

	// Deep Walnut outer floor
	set_render_draw_color(renderer, 14, 16, 24, 255)
	render_clear(renderer)

	draw_casino_room_background(renderer)
	draw_poker_table(renderer, shake_x, shake_y, g)
	draw_community_cards(renderer, shake_x, shake_y, g)
	draw_player_seats(renderer, shake_x, shake_y, g)
	draw_flying_cards(renderer, shake_x, shake_y, g)
	draw_special_effects(renderer, shake_x, shake_y, g)
	draw_control_panel(renderer, shake_x, shake_y, g)

	if g.celebration != '' {
		draw_celebration_banner(renderer, shake_x, shake_y, g)
	}
}

fn draw_casino_room_background(renderer &Renderer) {
	// Deep navy casino floor with carpet diamond motifs
	for y := 0; y < 600; y += 4 {
		shade := u8(10 + (y * 8) / 600)
		set_render_draw_color(renderer, shade + 2, shade, shade + 12, 255)
		rect := Rect{ x: 0, y: y, w: 800, h: 4 }
		render_fill_rect(renderer, &rect)
	}

	// Outer polished mahogany border
	for i := 0; i < 6; i++ {
		shade := u8(36 + i * 4)
		set_render_draw_color(renderer, shade, shade / 2, shade / 4, 255)
		rect := Rect{ x: i, y: i, w: 800 - i * 2, h: 600 - i * 2 }
		render_draw_rect(renderer, &rect)
	}
}

fn draw_poker_table(renderer &Renderer, sx int, sy int, g &TexasGame) {
	rx := 45 + sx
	ry := 45 + sy
	rw := 710
	rh := 470

	// 1. Padded Mahogany Leather Armrest
	set_render_draw_color(renderer, 48, 22, 14, 255)
	rail := Rect{ x: rx, y: ry, w: rw, h: rh }
	render_fill_rect(renderer, &rail)

	// Gold Inlay Rail Trim & Corner Rivets
	set_render_draw_color(renderer, 215, 175, 45, 255)
	render_draw_rect(renderer, &rail)

	set_render_draw_color(renderer, 75, 38, 22, 255)
	inner_rail := Rect{ x: rx + 4, y: ry + 4, w: rw - 8, h: rh - 8 }
	render_draw_rect(renderer, &inner_rail)

	// 2. Tournament Wool Baize Felt (Emerald Green with Center Spotlight)
	fx := rx + 16
	fy := ry + 16
	fw := rw - 32
	fh := rh - 32

	for y := 0; y < fh; y += 3 {
		norm_y := f64(y - fh / 2) / f64(fh / 2)
		vignette := math.max(0.0, 1.0 - (norm_y * norm_y * 1.3))

		r := u8(10.0 + vignette * 8.0)
		gr := u8(55.0 + vignette * 28.0)
		b := u8(28.0 + vignette * 16.0)

		set_render_draw_color(renderer, r, gr, b, 255)
		strip := Rect{ x: fx, y: fy + y, w: fw, h: 3 }
		render_fill_rect(renderer, &strip)
	}

	// Inner Felt Betting Line Ring
	set_render_draw_color(renderer, 230, 190, 50, 120)
	bet_line := Rect{ x: fx + 40, y: fy + 30, w: fw - 80, h: fh - 60 }
	render_draw_rect(renderer, &bet_line)

	// Main Pot Golden Chip Box
	draw_pot_display(renderer, 400 + sx, 205 + sy, g.pot)
}

fn draw_pot_display(renderer &Renderer, cx int, cy int, pot int) {
	pot_w := 190
	pot_h := 24
	px := cx - pot_w / 2
	py := cy - pot_h / 2

	set_render_draw_color(renderer, 10, 28, 16, 230)
	box := Rect{ x: px, y: py, w: pot_w, h: pot_h }
	render_fill_rect(renderer, &box)

	set_render_draw_color(renderer, 235, 195, 50, 255)
	render_draw_rect(renderer, &box)

	// Gold chip icon
	draw_filled_circle(renderer, px + 16, cy, 7, Color{ r: 250, g: 210, b: 40 })
	draw_circle_ring(renderer, px + 16, cy, 5, 1, Color{ r: 255, g: 255, b: 255 })

	draw_text_centered(renderer, cx + 6, cy - 4, '\$${pot} POT', 1, Color{ r: 255, g: 255, b: 255 })
}

fn draw_community_cards(renderer &Renderer, sx int, sy int, g &TexasGame) {
	card_w := 54
	card_h := 76
	cy := 236 + sy
	start_x := 400 + sx - (5 * 62 - 8) / 2

	for i := 0; i < 5; i++ {
		cx := start_x + i * 62
		if i < g.community_cards.len {
			draw_poker_card(renderer, cx, cy, card_w, card_h, g.community_cards[i])
		} else {
			// Empty Card Placeholder with Felt Shadow Slot
			set_render_draw_color(renderer, 8, 38, 20, 255)
			bg := Rect{ x: cx, y: cy, w: card_w, h: card_h }
			render_fill_rect(renderer, &bg)

			set_render_draw_color(renderer, 30, 95, 50, 255)
			render_draw_rect(renderer, &bg)

			draw_text_centered(renderer, cx + card_w / 2, cy + card_h / 2 - 4, '?', 1, Color{ r: 35, g: 110, b: 60 })
		}
	}
}

fn draw_player_seats(renderer &Renderer, sx int, sy int, g &TexasGame) {
	// 0: Bottom (Human), 1: Left, 2: Top, 3: Right
	seat_pos := [
		[400 + sx, 428 + sy],
		[125 + sx, 255 + sy],
		[400 + sx, 76 + sy],
		[675 + sx, 255 + sy],
	]

	for i, p in g.players {
		px := seat_pos[i][0]
		py := seat_pos[i][1]
		is_turn := i == g.current_turn_idx && g.stage != .showdown && g.stage != .round_over
		is_dealer := i == g.dealer_idx

		draw_player_pod(renderer, px, py, p, is_turn, is_dealer, g.stage == .showdown || g.stage == .round_over)
	}
}

fn draw_player_pod(renderer &Renderer, cx int, cy int, p PokerPlayer, is_turn bool, is_dealer bool, is_showdown bool) {
	w := 154
	h := 76
	x := cx - w / 2
	y := cy - h / 2

	// Pod Background with 3D Bevel
	bg_col := if is_turn { Color{ r: 25, g: 45, b: 75 } } else { Color{ r: 16, g: 20, b: 30 } }
	set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, 245)
	pod := Rect{ x: x, y: y, w: w, h: h }
	render_fill_rect(renderer, &pod)

	border_col := if is_turn { Color{ r: 255, g: 215, b: 0 } } else { Color{ r: 85, g: 95, b: 120 } }
	set_render_draw_color(renderer, border_col.r, border_col.g, border_col.b, 255)
	render_draw_rect(renderer, &pod)

	// Name & Chip Count
	name_col := if p.is_folded { Color{ r: 110, g: 110, b: 110 } } else { Color{ r: 255, g: 255, b: 255 } }
	draw_text_centered(renderer, cx, y + 4, p.name, 1, name_col)

	// Action status badge or chip count
	if p.last_action != '' {
		draw_status_pill(renderer, cx, y + 22, p.last_action, Color{ r: 20, g: 30, b: 45 }, Color{ r: 80, g: 220, b: 255 })
	} else {
		draw_text_centered(renderer, cx, y + 18, '\$${p.chips}', 1, Color{ r: 255, g: 215, b: 50 })
	}

	// Hole Cards
	card_w := 34
	card_h := 46
	if p.hole_cards.len == 2 {
		c1_x := cx - card_w - 2
		c2_x := cx + 2
		cards_y := y + 36

		if !p.is_ai || is_showdown {
			draw_poker_card(renderer, c1_x, cards_y, card_w, card_h, p.hole_cards[0])
			draw_poker_card(renderer, c2_x, cards_y, card_w, card_h, p.hole_cards[1])
		} else {
			draw_poker_card_back(renderer, c1_x, cards_y, card_w, card_h)
			draw_poker_card_back(renderer, c2_x, cards_y, card_w, card_h)
		}
	}

	// Dealer Button Token
	if is_dealer {
		db_x := x + w - 12
		db_y := y + 12
		draw_filled_circle(renderer, db_x, db_y, 10, Color{ r: 250, g: 250, b: 255 })
		draw_circle_ring(renderer, db_x, db_y, 10, 1, Color{ r: 20, g: 20, b: 30 })
		draw_text_centered(renderer, db_x, db_y - 4, 'D', 1, Color{ r: 200, g: 20, b: 30 })
	}
}

// -------------------------------------------------------------
// Flying Cards, VFX, and Particles
// -------------------------------------------------------------

fn draw_flying_cards(renderer &Renderer, sx int, sy int, g &TexasGame) {
	card_w := 56
	card_h := 80
	for fc in g.flying_cards {
		fx := int(fc.x) + sx
		fy := int(fc.y) + sy

		if fc.is_face_up {
			flip_factor := math.abs(math.cos(fc.flip_progress * math.pi))
			cur_w := int(f64(card_w) * (0.2 + flip_factor * 0.8))
			cur_x := fx + (card_w - cur_w) / 2
			draw_poker_card(renderer, cur_x, fy, cur_w, card_h, fc.card)
		} else {
			draw_poker_card_back(renderer, fx, fy, card_w, card_h)
		}
	}
}

fn draw_special_effects(renderer &Renderer, sx int, sy int, g &TexasGame) {
	for sw in g.shockwaves {
		alpha := u8(255.0 * (1.0 - sw.life / sw.max_life))
		c := Color{ r: sw.color.r, g: sw.color.g, b: sw.color.b, a: alpha }
		draw_circle_ring(renderer, int(sw.cx) + sx, int(sw.cy) + sy, int(sw.radius), int(sw.thickness), c)
	}

	for p in g.particles {
		alpha := u8(255.0 * (1.0 - p.life / p.max_life))
		col := Color{ r: p.color.r, g: p.color.g, b: p.color.b, a: alpha }
		px := int(p.x) + sx
		py := int(p.y) + sy
		sz := int(p.size)

		if p.shape_type == 0 {
			set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
			render_draw_line(renderer, px, py, px + int(p.vx * 0.04), py + int(p.vy * 0.04))
			draw_filled_circle(renderer, px, py, sz, col)
		} else if p.shape_type == 2 {
			c_rect := Rect{ x: px - sz, y: py - sz / 2, w: sz * 2, h: sz }
			set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
			render_fill_rect(renderer, &c_rect)
		} else {
			draw_filled_circle(renderer, px, py, sz, col)
		}
	}

	for ft in g.floating_texts {
		alpha := u8(255.0 * (1.0 - ft.life / ft.max_life))
		col := Color{ r: ft.color.r, g: ft.color.g, b: ft.color.b, a: alpha }
		tx := int(ft.x) + sx
		ty := int(ft.y) + sy

		draw_status_pill(renderer, tx, ty, ft.text, Color{ r: 10, g: 15, b: 25 }, col)
	}
}

// -------------------------------------------------------------
// High-Definition Poker Card Graphics
// -------------------------------------------------------------

fn draw_poker_card(renderer &Renderer, x int, y int, w int, h int, c Card) {
	if w <= 4 { return }

	// Drop Shadow
	set_render_draw_color(renderer, 0, 0, 0, 110)
	shadow := Rect{ x: x + 2, y: y + 3, w: w, h: h }
	render_fill_rect(renderer, &shadow)

	// Ivory Card Body
	bg := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, 252, 250, 244, 255)
	render_fill_rect(renderer, &bg)

	set_render_draw_color(renderer, 35, 38, 45, 255)
	render_draw_rect(renderer, &bg)

	// Inner Margin
	if w > 20 {
		inner := Rect{ x: x + 2, y: y + 2, w: w - 4, h: h - 4 }
		set_render_draw_color(renderer, 220, 205, 175, 255)
		render_draw_rect(renderer, &inner)
	}

	is_red := c.suit == .hearts || c.suit == .diamonds
	suit_col := if is_red { Color{ r: 215, g: 30, b: 40 } } else { Color{ r: 24, g: 28, b: 36 } }

	rank_s := match c.rank {
		14 { 'A' }
		13 { 'K' }
		12 { 'Q' }
		11 { 'J' }
		10 { '10' }
		else { '${c.rank}' }
	}

	// Corner Index
	draw_text(renderer, x + 3, y + 3, rank_s, 1, suit_col)

	if w >= 50 {
		draw_suit_pip(renderer, c.suit, x + 8, y + 16, 4)
		draw_text(renderer, x + w - 11, y + h - 12, rank_s, 1, suit_col)
		draw_suit_pip(renderer, c.suit, x + w - 8, y + h - 20, 4)

		cx := x + w / 2
		cy := y + h / 2

		if c.rank == 14 {
			draw_circle_ring(renderer, cx, cy, 18, 1, Color{ r: suit_col.r, g: suit_col.g, b: suit_col.b, a: 60 })
			draw_suit_pip(renderer, c.suit, cx, cy, 13)
			draw_circle_ring(renderer, cx, cy, 22, 1, Color{ r: 212, g: 175, b: 55, a: 160 })
		} else if c.rank >= 11 && c.rank <= 13 {
			draw_court_portrait_hd(renderer, x + 10, y + 16, w - 20, h - 32, c.rank, suit_col)
		} else {
			draw_suit_pip(renderer, c.suit, cx, cy, 10)
		}
	} else {
		// Hole card mini pip
		draw_suit_pip(renderer, c.suit, x + w - 10, y + h - 12, 4)
	}
}

fn draw_court_portrait_hd(renderer &Renderer, px int, py int, pw int, ph int, rank int, col Color) {
	if pw <= 8 || ph <= 8 { return }

	p_rect := Rect{ x: px, y: py, w: pw, h: ph }
	set_render_draw_color(renderer, 248, 244, 230, 255)
	render_fill_rect(renderer, &p_rect)

	set_render_draw_color(renderer, 212, 175, 55, 255)
	render_draw_rect(renderer, &p_rect)

	cx := px + pw / 2
	cy := py + ph / 2

	if rank == 11 {
		helm := Rect{ x: cx - 8, y: cy - 12, w: 16, h: 10 }
		set_render_draw_color(renderer, 150, 160, 180, 255)
		render_fill_rect(renderer, &helm)
		draw_text_centered(renderer, cx, cy + 6, 'J', 1, col)
	} else if rank == 12 {
		tiara := Rect{ x: cx - 10, y: cy - 14, w: 20, h: 6 }
		set_render_draw_color(renderer, 245, 210, 45, 255)
		render_fill_rect(renderer, &tiara)
		draw_text_centered(renderer, cx, cy + 6, 'Q', 1, col)
	} else if rank == 13 {
		crown := Rect{ x: cx - 12, y: cy - 16, w: 24, h: 8 }
		set_render_draw_color(renderer, 245, 205, 40, 255)
		render_fill_rect(renderer, &crown)
		draw_text_centered(renderer, cx, cy + 6, 'K', 1, col)
	}
}

fn draw_suit_pip(renderer &Renderer, suit CardSuit, cx int, cy int, size int) {
	match suit {
		.hearts {
			set_render_draw_color(renderer, 215, 30, 40, 255)
			for dy := -size; dy <= size; dy++ {
				for dx := -size; dx <= size; dx++ {
					if dy < 0 {
						lx := dx + size / 2
						rx := dx - size / 2
						if (lx * lx + (dy + size / 2) * (dy + size / 2) <= (size / 2) * (size / 2) + 1) ||
						   (rx * rx + (dy + size / 2) * (dy + size / 2) <= (size / 2) * (size / 2) + 1) {
							render_draw_point(renderer, cx + dx, cy + dy)
						}
					} else {
						span := (size - dy)
						if dx >= -span && dx <= span {
							render_draw_point(renderer, cx + dx, cy + dy)
						}
					}
				}
			}
		}
		.diamonds {
			set_render_draw_color(renderer, 215, 30, 40, 255)
			for dy := -size; dy <= size; dy++ {
				span := int(f64(size - int(math.abs(f64(dy)))) * 0.85)
				for dx := -span; dx <= span; dx++ {
					render_draw_point(renderer, cx + dx, cy + dy)
				}
			}
		}
		.clubs {
			set_render_draw_color(renderer, 24, 28, 36, 255)
			r_lobe := size / 2
			draw_filled_circle(renderer, cx, cy - r_lobe, r_lobe, Color{ r: 24, g: 28, b: 36 })
			draw_filled_circle(renderer, cx - r_lobe, cy + r_lobe / 2, r_lobe, Color{ r: 24, g: 28, b: 36 })
			draw_filled_circle(renderer, cx + r_lobe, cy + r_lobe / 2, r_lobe, Color{ r: 24, g: 28, b: 36 })
			stem := Rect{ x: cx - 1, y: cy + r_lobe / 2, w: 3, h: size - r_lobe / 2 + 1 }
			render_fill_rect(renderer, &stem)
		}
		.spades {
			set_render_draw_color(renderer, 24, 28, 36, 255)
			for dy := -size; dy <= size / 2; dy++ {
				mut span := int(f64(dy + size) * 0.75)
				if span > size { span = size }
				for dx := -span; dx <= span; dx++ {
					render_draw_point(renderer, cx + dx, cy + dy)
				}
			}
			r_lobe := size / 2
			draw_filled_circle(renderer, cx - r_lobe / 2, cy + r_lobe / 2, r_lobe, Color{ r: 24, g: 28, b: 36 })
			draw_filled_circle(renderer, cx + r_lobe / 2, cy + r_lobe / 2, r_lobe, Color{ r: 24, g: 28, b: 36 })
			stem := Rect{ x: cx - 1, y: cy + r_lobe / 2, w: 3, h: size - r_lobe / 2 + 2 }
			render_fill_rect(renderer, &stem)
		}
	}
}

fn draw_poker_card_back(renderer &Renderer, x int, y int, w int, h int) {
	// Shadow
	set_render_draw_color(renderer, 0, 0, 0, 100)
	shadow := Rect{ x: x + 2, y: y + 3, w: w, h: h }
	render_fill_rect(renderer, &shadow)

	// White Base
	bg := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, 248, 246, 240, 255)
	render_fill_rect(renderer, &bg)
	set_render_draw_color(renderer, 30, 32, 40, 255)
	render_draw_rect(renderer, &bg)

	// Inner Crimson Pattern
	inner := Rect{ x: x + 3, y: y + 3, w: w - 6, h: h - 6 }
	set_render_draw_color(renderer, 155, 25, 35, 255)
	render_fill_rect(renderer, &inner)

	// Diamond lattice
	set_render_draw_color(renderer, 255, 255, 255, 100)
	for ly := y + 5; ly < y + h - 5; ly += 6 {
		for lx := x + 5; lx < x + w - 5; lx += 6 {
			render_draw_point(renderer, lx, ly)
		}
	}
}

fn draw_status_pill(renderer &Renderer, cx int, cy int, text string, bg_col Color, txt_col Color) {
	tw := text.len * 8 + 18
	pill := Rect{ x: cx - tw / 2, y: cy - 9, w: tw, h: 18 }
	set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, 240)
	render_fill_rect(renderer, &pill)
	set_render_draw_color(renderer, txt_col.r, txt_col.g, txt_col.b, 255)
	render_draw_rect(renderer, &pill)
	draw_text_centered(renderer, cx, cy - 4, text, 1, txt_col)
}

fn draw_control_panel(renderer &Renderer, sx int, sy int, g &TexasGame) {
	bar_rect := Rect{ x: 20 + sx, y: 562 + sy, w: 760, h: 32 }
	set_render_draw_color(renderer, 10, 15, 25, 245)
	render_fill_rect(renderer, &bar_rect)
	set_render_draw_color(renderer, 220, 180, 50, 255)
	render_draw_rect(renderer, &bar_rect)

	p1 := g.players[0]
	is_my_turn := g.current_turn_idx == 0 && !p1.is_folded && !p1.is_all_in && g.stage != .showdown && g.stage != .round_over

	to_call := g.current_bet - p1.current_bet

	prompt_str := if is_my_turn {
		call_label := if to_call == 0 { 'CHECK' } else { 'CALL ($$${to_call})' }
		'[C] ${call_label} | [R] RAISE ($$${g.raise_amount}) | [UP/DN] ADJ BET | [F] FOLD | [A] ALL-IN'
	} else if g.stage == .round_over {
		'[SPACE/ENTER] DEAL NEXT HAND | [M] SOUND'
	} else {
		'OPPONENT IS THINKING... | [M] SOUND'
	}

	draw_text_centered(renderer, 400 + sx, 572 + sy, prompt_str, 1, Color{ r: 255, g: 235, b: 120 })
}

fn draw_celebration_banner(renderer &Renderer, sx int, sy int, g &TexasGame) {
	box_w := 580
	box_h := 36
	bx := (800 - box_w) / 2 + sx
	by := 158 + sy

	set_render_draw_color(renderer, 12, 18, 30, 250)
	b_rect := Rect{ x: bx, y: by, w: box_w, h: box_h }
	render_fill_rect(renderer, &b_rect)

	set_render_draw_color(renderer, 255, 215, 50, 255)
	render_draw_rect(renderer, &b_rect)

	draw_text_centered(renderer, 400 + sx, by + 12, g.celebration, 1, Color{ r: 255, g: 230, b: 70 })
}

fn draw_filled_circle(renderer &Renderer, cx int, cy int, r int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	for dy := -r; dy <= r; dy++ {
		for dx := -r; dx <= r; dx++ {
			if dx * dx + dy * dy <= r * r {
				render_draw_point(renderer, cx + dx, cy + dy)
			}
		}
	}
}

fn draw_circle_ring(renderer &Renderer, cx int, cy int, r int, thickness int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	r_outer := r + thickness / 2
	r_inner := r - thickness / 2
	for dy := -r_outer; dy <= r_outer; dy++ {
		for dx := -r_outer; dx <= r_outer; dx++ {
			d2 := dx * dx + dy * dy
			if d2 <= r_outer * r_outer && d2 >= r_inner * r_inner {
				render_draw_point(renderer, cx + dx, cy + dy)
			}
		}
	}
}
