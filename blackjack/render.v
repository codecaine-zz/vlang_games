module main

import math


fn draw_blackjack_game(renderer &Renderer, g &BlackjackGame) {
	// Screen shake calculation
	mut shake_x := 0
	mut shake_y := 0
	if g.shake_timer > 0.0 && g.shake_intensity > 0.0 {
		decay := g.shake_timer / 0.45
		s := g.shake_intensity * decay
		shake_x = int(math.sin(g.anim_timer * 45.0) * s)
		shake_y = int(math.cos(g.anim_timer * 40.0) * s)
	}

	// Deep Walnut Outer Table
	set_render_draw_color(renderer, 18, 12, 8, 255)
	render_clear(renderer)

	draw_casino_wood_rim(renderer)
	draw_casino_table_felt(renderer, shake_x, shake_y)
	draw_table_felt_markings(renderer, shake_x, shake_y)
	draw_dealer_area(renderer, shake_x, shake_y, g)
	draw_player_hands_area(renderer, shake_x, shake_y, g)
	draw_betting_chips_area(renderer, shake_x, shake_y, g)
	draw_flying_cards(renderer, shake_x, shake_y, g)
	draw_special_effects(renderer, shake_x, shake_y, g)
	draw_hud_and_controls(renderer, shake_x, shake_y, g)
}

// -------------------------------------------------------------
// 1. Table Architecture & Baize Felt
// -------------------------------------------------------------

fn draw_casino_wood_rim(renderer &Renderer) {
	// Outer polished mahogany border
	for i := 0; i < 8; i++ {
		shade := u8(38 + i * 4)
		set_render_draw_color(renderer, shade, shade / 2, shade / 4, 255)
		rect := Rect{ x: i, y: i, w: 800 - i * 2, h: 600 - i * 2 }
		render_draw_rect(renderer, &rect)
	}

	// Gold Inlay Trims
	set_render_draw_color(renderer, 212, 175, 55, 200)
	gold_rim := Rect{ x: 9, y: 9, w: 782, h: 582 }
	render_draw_rect(renderer, &gold_rim)

	// Corner Rivet Accents
	corners := [[14, 14], [786, 14], [14, 586], [786, 586]]
	for c in corners {
		draw_filled_circle(renderer, c[0], c[1], 4, Color{ r: 230, g: 190, b: 60 })
		draw_filled_circle(renderer, c[0], c[1], 2, Color{ r: 70, g: 50, b: 20 })
	}
}

fn draw_casino_table_felt(renderer &Renderer, sx int, sy int) {
	// Emerald Wool Felt with Radial Center Vignette
	for y := 12; y < 588; y += 3 {
		norm_y := f64(y - 300) / 288.0
		vignette := math.max(0.0, 1.0 - (norm_y * norm_y * 1.4))
		r := u8(10.0 + vignette * 8.0)
		gr := u8(50.0 + vignette * 26.0)
		b := u8(22.0 + vignette * 12.0)
		set_render_draw_color(renderer, r, gr, b, 255)
		rect := Rect{ x: 12 + sx, y: y + sy, w: 776, h: 3 }
		render_fill_rect(renderer, &rect)
	}

	// Inner Stitched Gold Border
	felt_border := Rect{ x: 18 + sx, y: 18 + sy, w: 764, h: 564 }
	set_render_draw_color(renderer, 200, 165, 50, 120)
	render_draw_rect(renderer, &felt_border)
}

fn draw_table_felt_markings(renderer &Renderer, sx int, sy int) {
	// Gold Felt Arch
	set_render_draw_color(renderer, 220, 185, 50, 120)
	render_draw_line(renderer, 100 + sx, 250 + sy, 700 + sx, 250 + sy)
	render_draw_line(renderer, 100 + sx, 251 + sy, 700 + sx, 251 + sy)

	// Printed Rules in Arch
	draw_text_centered(renderer, 400 + sx, 195 + sy, '★ BLACKJACK PAYS 3 TO 2 ★', 2, Color{ r: 255, g: 215, b: 50 })
	draw_text_centered(renderer, 400 + sx, 225 + sy, 'Dealer Must Draw to 16 and Stand on all 17s', 1, Color{ r: 230, g: 240, b: 210 })
	draw_text_centered(renderer, 400 + sx, 258 + sy, '★ INSURANCE PAYS 2 TO 1 ★', 1, Color{ r: 255, g: 215, b: 50 })
}

// -------------------------------------------------------------
// 2. Dealer & Player Hand Areas
// -------------------------------------------------------------

fn draw_dealer_area(renderer &Renderer, sx int, sy int, g &BlackjackGame) {
	dx := 400 + sx
	dy := 55 + sy
	card_w := 68
	card_h := 98

	draw_text_centered(renderer, dx, dy - 20, 'DEALER', 1, Color{ r: 240, g: 220, b: 150 })

	if g.dealer_hand.len > 0 {
		start_x := dx - (g.dealer_hand.len * 38 + card_w - 38) / 2

		for i, c in g.dealer_hand {
			cx := start_x + i * 38
			if i == 1 && g.dealer_hidden {
				draw_playing_card_back(renderer, cx, dy, card_w, card_h, Color{ r: 165, g: 25, b: 35 })
			} else {
				draw_playing_card(renderer, cx, dy, card_w, card_h, c.rank, c.suit)
			}
		}

		// Dealer Value Badge
		if !g.dealer_hidden {
			val, is_soft := calculate_hand_value(g.dealer_hand)
			val_str := if is_soft && val < 21 { 'SOFT ${val}' } else if val > 21 { 'BUST (${val})' } else { '${val}' }
			col := if val > 21 { Color{ r: 255, g: 100, b: 100 } } else { Color{ r: 255, g: 240, b: 180 } }
			draw_status_pill(renderer, dx, dy + card_h + 12, 'DEALER: ${val_str}', Color{ r: 20, g: 45, b: 30 }, col)
		} else if g.dealer_hand.len > 0 {
			up_val, _ := calculate_hand_value([g.dealer_hand[0]])
			draw_status_pill(renderer, dx, dy + card_h + 12, 'SHOWING: ${up_val}', Color{ r: 20, g: 45, b: 30 }, Color{ r: 200, g: 225, b: 200 })
		}
	} else {
		// Empty Card placeholders
		draw_card_outline(renderer, dx - 40, dy, card_w, card_h)
		draw_card_outline(renderer, dx + 40 - card_w, dy, card_w, card_h)
	}
}

fn draw_player_hands_area(renderer &Renderer, sx int, sy int, g &BlackjackGame) {
	if g.player_hands.len == 0 {
		return
	}

	card_w := 68
	card_h := 98
	py := 305 + sy

	for h_idx, h in g.player_hands {
		hx := if g.player_hands.len == 1 { 400 + sx } else { 280 + h_idx * 240 + sx }
		start_x := hx - (h.cards.len * 35 + card_w - 35) / 2

		is_active := h_idx == g.active_hand_idx && g.state == .player_turn

		// Active Hand Spotlight Box
		if is_active {
			box := Rect{ x: hx - 85, y: py - 22, w: 170, h: card_h + 60 }
			set_render_draw_color(renderer, 255, 215, 0, 100)
			render_draw_rect(renderer, &box)
			draw_circle_ring(renderer, hx, py + card_h / 2, 60, 1, Color{ r: 255, g: 215, b: 0, a: 50 })
		}

		for i, c in h.cards {
			cx := start_x + i * 42
			draw_playing_card(renderer, cx, py, card_w, card_h, c.rank, c.suit)
		}

		// Hand Status / Value Badge
		val, is_soft := calculate_hand_value(h.cards)
		val_str := if h.is_bj { 'BLACKJACK! (21)' } else if h.is_busted { 'BUST! (${val})' } else if is_soft && val < 21 { 'SOFT ${val}' } else { '${val}' }

		pill_col := if is_active { Color{ r: 255, g: 220, b: 50 } } else { Color{ r: 220, g: 235, b: 255 } }
		bg_col := if h.is_busted { Color{ r: 140, g: 25, b: 35 } } else if h.is_bj { Color{ r: 180, g: 140, b: 20 } } else { Color{ r: 15, g: 35, b: 25 } }

		draw_status_pill(renderer, hx, py + card_h + 12, 'HAND: ${val_str} ($$${h.bet})', bg_col, pill_col)
	}
}

// -------------------------------------------------------------
// 3. Chips Tray & Betting Area
// -------------------------------------------------------------

fn draw_betting_chips_area(renderer &Renderer, sx int, sy int, g &BlackjackGame) {
	bx := 400 + sx
	by := 460 + sy

	draw_circle_ring(renderer, bx, by, 38, 3, Color{ r: 220, g: 185, b: 50 })
	draw_circle_ring(renderer, bx, by, 42, 1, Color{ r: 255, g: 255, b: 255, a: 100 })
	draw_text_centered(renderer, bx, by - 8, 'BET', 1, Color{ r: 240, g: 220, b: 150 })
	draw_text_centered(renderer, bx, by + 6, '$$${g.current_bet}', 1, Color{ r: 255, g: 255, b: 255 })

	// Chips Tray at bottom left
	chips_x := 80 + sx
	chips_y := 460 + sy
	chip_vals := [5, 25, 50, 100, 500]
	chip_cols := [
		Color{ r: 210, g: 30, b: 40 },   // Red $5
		Color{ r: 40, g: 160, b: 60 },   // Green $25
		Color{ r: 35, g: 90, b: 210 },   // Blue $50
		Color{ r: 30, g: 30, b: 40 },    // Black $100
		Color{ r: 160, g: 45, b: 180 },  // Purple $500
	]

	for i := 0; i < 5; i++ {
		cx := chips_x + i * 48
		draw_casino_chip(renderer, cx, chips_y, 18, chip_vals[i], chip_cols[i])
	}
}

fn draw_casino_chip(renderer &Renderer, cx int, cy int, r int, val int, c Color) {
	// Shadow
	set_render_draw_color(renderer, 0, 0, 0, 110)
	shadow := Rect{ x: cx - r + 2, y: cy - r + 3, w: r * 2, h: r * 2 }
	render_fill_rect(renderer, &shadow)

	// Base body
	draw_filled_circle(renderer, cx, cy, r, c)
	// Outer edge rim
	draw_circle_ring(renderer, cx, cy, r, 2, Color{ r: 240, g: 220, b: 150 })
	// Inner white dash ring
	draw_circle_ring(renderer, cx, cy, r - 4, 2, Color{ r: 255, g: 255, b: 255 })

	val_s := if val >= 500 { '500' } else if val >= 100 { '100' } else { '${val}' }
	draw_text_centered(renderer, cx, cy - 3, val_s, 1, Color{ r: 255, g: 255, b: 255 })
}

// -------------------------------------------------------------
// 4. Flying Cards, VFX, and Particles
// -------------------------------------------------------------

fn draw_flying_cards(renderer &Renderer, sx int, sy int, g &BlackjackGame) {
	card_w := 68
	card_h := 98
	for fc in g.flying_cards {
		fx := int(fc.x) + sx
		fy := int(fc.y) + sy

		if fc.is_face_up {
			flip_factor := math.abs(math.cos(fc.flip_progress * math.pi))
			cur_w := int(f64(card_w) * (0.2 + flip_factor * 0.8))
			cur_x := fx + (card_w - cur_w) / 2
			draw_playing_card(renderer, cur_x, fy, cur_w, card_h, fc.card.rank, fc.card.suit)
		} else {
			draw_playing_card_back(renderer, fx, fy, card_w, card_h, Color{ r: 165, g: 25, b: 35 })
		}
	}
}

fn draw_special_effects(renderer &Renderer, sx int, sy int, g &BlackjackGame) {
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

		tw := ft.text.len * 8 * ft.scale + 16
		pill := Rect{ x: tx - tw / 2, y: ty - 3, w: tw, h: 14 * ft.scale }
		set_render_draw_color(renderer, 10, 20, 15, alpha / 2)
		render_fill_rect(renderer, &pill)

		draw_text_centered(renderer, tx + 1, ty + 1, ft.text, ft.scale, Color{ r: 0, g: 0, b: 0, a: alpha })
		draw_text_centered(renderer, tx, ty, ft.text, ft.scale, col)
	}
}

// -------------------------------------------------------------
// 5. Playing Card Renderer & Court Portraits
// -------------------------------------------------------------

fn draw_playing_card(renderer &Renderer, x int, y int, w int, h int, rank int, suit CardSuit) {
	if w <= 4 {
		return
	}

	// Drop Shadow
	set_render_draw_color(renderer, 0, 0, 0, 120)
	shadow := Rect{ x: x + 4, y: y + 5, w: w, h: h }
	render_fill_rect(renderer, &shadow)

	// Ivory Card Body
	bg := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, 252, 250, 244, 255)
	render_fill_rect(renderer, &bg)

	// Card Outer Border
	set_render_draw_color(renderer, 30, 32, 40, 255)
	render_draw_rect(renderer, &bg)

	// Card Inner Subtle Margin
	if w > 20 {
		inner := Rect{ x: x + 3, y: y + 3, w: w - 6, h: h - 6 }
		set_render_draw_color(renderer, 220, 205, 175, 255)
		render_draw_rect(renderer, &inner)
	}

	is_red := suit == .hearts || suit == .diamonds
	suit_col := if is_red { Color{ r: 215, g: 30, b: 40 } } else { Color{ r: 24, g: 28, b: 36 } }

	rank_s := match rank {
		1  { 'A' }
		11 { 'J' }
		12 { 'Q' }
		13 { 'K' }
		10 { '10' }
		else { '${rank}' }
	}

	// Top-Left Index (Rank & Mini Suit Pip)
	if w >= 45 {
		draw_text(renderer, x + 5, y + 5, rank_s, 1, suit_col)
		draw_suit_pip(renderer, suit, x + 9, y + 19, 4)

		// Bottom-Right Index (Rank & Mini Suit Pip)
		draw_text(renderer, x + w - 12, y + h - 14, rank_s, 1, suit_col)
		draw_suit_pip(renderer, suit, x + w - 9, y + h - 22, 4)
	}

	// Center Card Artwork / Pip Layout
	cx := x + w / 2
	cy := y + h / 2

	if rank == 1 {
		// Ace: Large Ornate Centerpiece Suit Emblem
		draw_circle_ring(renderer, cx, cy, 22, 2, Color{ r: suit_col.r, g: suit_col.g, b: suit_col.b, a: 60 })
		draw_suit_pip(renderer, suit, cx, cy, 16)
		draw_circle_ring(renderer, cx, cy, 28, 1, Color{ r: 212, g: 175, b: 55, a: 160 })
	} else if rank >= 11 && rank <= 13 {
		// Court Cards: Jack, Queen, King 16-bit Royal Portrait
		draw_court_portrait_hd(renderer, x + 12, y + 20, w - 24, h - 40, rank, suit_col)
	} else {
		// Number Cards (2-10): Pip Layouts
		draw_pip_layout(renderer, x, y, w, h, rank, suit)
	}
}

fn draw_court_portrait_hd(renderer &Renderer, px int, py int, pw int, ph int, rank int, col Color) {
	if pw <= 10 || ph <= 10 { return }

	p_rect := Rect{ x: px, y: py, w: pw, h: ph }
	set_render_draw_color(renderer, 248, 244, 230, 255)
	render_fill_rect(renderer, &p_rect)

	set_render_draw_color(renderer, 212, 175, 55, 255)
	render_draw_rect(renderer, &p_rect)

	cx := px + pw / 2
	cy := py + ph / 2

	if rank == 11 {
		// Jack: Plumed Knight with Visor
		helm := Rect{ x: cx - 10, y: cy - 16, w: 20, h: 14 }
		set_render_draw_color(renderer, 150, 160, 180, 255)
		render_fill_rect(renderer, &helm)
		set_render_draw_color(renderer, 30, 35, 45, 255)
		render_draw_line(renderer, cx - 6, cy - 9, cx + 6, cy - 9)
		set_render_draw_color(renderer, col.r, col.g, col.b, 255)
		render_draw_line(renderer, cx - 3, cy - 16, cx - 8, cy - 22)
		draw_text_centered(renderer, cx, cy + 10, 'J', 1, col)
	} else if rank == 12 {
		// Queen: Tiara & Royal Gem
		tiara := Rect{ x: cx - 12, y: cy - 18, w: 24, h: 8 }
		set_render_draw_color(renderer, 245, 210, 45, 255)
		render_fill_rect(renderer, &tiara)
		draw_filled_circle(renderer, cx, cy - 18, 2, Color{ r: 215, g: 30, b: 40 })
		draw_text_centered(renderer, cx, cy + 10, 'Q', 1, col)
	} else if rank == 13 {
		// King: Imperial Crown & Ermine Collar
		crown := Rect{ x: cx - 14, y: cy - 20, w: 28, h: 10 }
		set_render_draw_color(renderer, 245, 205, 40, 255)
		render_fill_rect(renderer, &crown)
		set_render_draw_color(renderer, 255, 235, 120, 255)
		render_draw_line(renderer, cx - 14, cy - 20, cx - 8, cy - 25)
		render_draw_line(renderer, cx, cy - 20, cx, cy - 26)
		render_draw_line(renderer, cx + 14, cy - 20, cx + 8, cy - 25)
		robe := Rect{ x: cx - 12, y: cy - 4, w: 24, h: 5 }
		set_render_draw_color(renderer, 230, 230, 235, 255)
		render_fill_rect(renderer, &robe)
		draw_text_centered(renderer, cx, cy + 10, 'K', 1, col)
	}
}

fn draw_pip_layout(renderer &Renderer, x int, y int, w int, h int, rank int, suit CardSuit) {
	cx := x + w / 2
	cy := y + h / 2
	lx := x + 18
	rx := x + w - 18
	ty := y + 24
	by := y + h - 24
	my := y + h / 2

	match rank {
		2 {
			draw_suit_pip(renderer, suit, cx, ty, 6)
			draw_suit_pip(renderer, suit, cx, by, 6)
		}
		3 {
			draw_suit_pip(renderer, suit, cx, ty, 6)
			draw_suit_pip(renderer, suit, cx, cy, 6)
			draw_suit_pip(renderer, suit, cx, by, 6)
		}
		4 {
			draw_suit_pip(renderer, suit, lx, ty, 5)
			draw_suit_pip(renderer, suit, rx, ty, 5)
			draw_suit_pip(renderer, suit, lx, by, 5)
			draw_suit_pip(renderer, suit, rx, by, 5)
		}
		5 {
			draw_suit_pip(renderer, suit, lx, ty, 5)
			draw_suit_pip(renderer, suit, rx, ty, 5)
			draw_suit_pip(renderer, suit, cx, cy, 6)
			draw_suit_pip(renderer, suit, lx, by, 5)
			draw_suit_pip(renderer, suit, rx, by, 5)
		}
		6 {
			draw_suit_pip(renderer, suit, lx, ty, 5)
			draw_suit_pip(renderer, suit, rx, ty, 5)
			draw_suit_pip(renderer, suit, lx, my, 5)
			draw_suit_pip(renderer, suit, rx, my, 5)
			draw_suit_pip(renderer, suit, lx, by, 5)
			draw_suit_pip(renderer, suit, rx, by, 5)
		}
		7 {
			draw_suit_pip(renderer, suit, lx, ty, 5)
			draw_suit_pip(renderer, suit, rx, ty, 5)
			draw_suit_pip(renderer, suit, cx, ty + 10, 5)
			draw_suit_pip(renderer, suit, lx, my + 3, 5)
			draw_suit_pip(renderer, suit, rx, my + 3, 5)
			draw_suit_pip(renderer, suit, lx, by, 5)
			draw_suit_pip(renderer, suit, rx, by, 5)
		}
		8 {
			draw_suit_pip(renderer, suit, lx, ty, 5)
			draw_suit_pip(renderer, suit, rx, ty, 5)
			draw_suit_pip(renderer, suit, cx, ty + 10, 5)
			draw_suit_pip(renderer, suit, lx, my + 3, 5)
			draw_suit_pip(renderer, suit, rx, my + 3, 5)
			draw_suit_pip(renderer, suit, cx, by - 10, 5)
			draw_suit_pip(renderer, suit, lx, by, 5)
			draw_suit_pip(renderer, suit, rx, by, 5)
		}
		9 {
			draw_suit_pip(renderer, suit, lx, ty, 5)
			draw_suit_pip(renderer, suit, rx, ty, 5)
			draw_suit_pip(renderer, suit, lx, ty + 12, 5)
			draw_suit_pip(renderer, suit, rx, ty + 12, 5)
			draw_suit_pip(renderer, suit, cx, cy, 5)
			draw_suit_pip(renderer, suit, lx, by - 12, 5)
			draw_suit_pip(renderer, suit, rx, by - 12, 5)
			draw_suit_pip(renderer, suit, lx, by, 5)
			draw_suit_pip(renderer, suit, rx, by, 5)
		}
		10 {
			draw_suit_pip(renderer, suit, lx, ty, 5)
			draw_suit_pip(renderer, suit, rx, ty, 5)
			draw_suit_pip(renderer, suit, cx, ty + 8, 5)
			draw_suit_pip(renderer, suit, lx, ty + 14, 5)
			draw_suit_pip(renderer, suit, rx, ty + 14, 5)
			draw_suit_pip(renderer, suit, lx, by - 14, 5)
			draw_suit_pip(renderer, suit, rx, by - 14, 5)
			draw_suit_pip(renderer, suit, cx, by - 8, 5)
			draw_suit_pip(renderer, suit, lx, by, 5)
			draw_suit_pip(renderer, suit, rx, by, 5)
		}
		else {}
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

fn draw_playing_card_back(renderer &Renderer, x int, y int, w int, h int, pattern_col Color) {
	// Shadow
	set_render_draw_color(renderer, 0, 0, 0, 110)
	shadow := Rect{ x: x + 3, y: y + 4, w: w, h: h }
	render_fill_rect(renderer, &shadow)

	// White Base
	bg := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, 250, 248, 242, 255)
	render_fill_rect(renderer, &bg)
	set_render_draw_color(renderer, 30, 32, 40, 255)
	render_draw_rect(renderer, &bg)

	// Inner Pattern Area
	inner := Rect{ x: x + 4, y: y + 4, w: w - 8, h: h - 8 }
	set_render_draw_color(renderer, pattern_col.r, pattern_col.g, pattern_col.b, 255)
	render_fill_rect(renderer, &inner)

	// Diamond Filigree Lattice
	set_render_draw_color(renderer, 255, 255, 255, 120)
	for ly := y + 6; ly < y + h - 6; ly += 8 {
		for lx := x + 6; lx < x + w - 6; lx += 8 {
			render_draw_line(renderer, lx, ly - 3, lx + 3, ly)
			render_draw_line(renderer, lx + 3, ly, lx, ly + 3)
			render_draw_line(renderer, lx, ly + 3, lx - 3, ly)
			render_draw_line(renderer, lx - 3, ly, lx, ly - 3)
		}
	}

	// Center Gold Medallion
	draw_filled_circle(renderer, x + w / 2, y + h / 2, 10, Color{ r: 245, g: 215, b: 60 })
	draw_circle_ring(renderer, x + w / 2, y + h / 2, 10, 1, Color{ r: 255, g: 255, b: 255 })
}

fn draw_card_outline(renderer &Renderer, x int, y int, w int, h int) {
	rect := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, 30, 85, 48, 180)
	render_draw_rect(renderer, &rect)
}

fn draw_status_pill(renderer &Renderer, cx int, cy int, text string, bg_col Color, txt_col Color) {
	tw := text.len * 8 + 20
	pill := Rect{ x: cx - tw / 2, y: cy - 9, w: tw, h: 18 }
	set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, 240)
	render_fill_rect(renderer, &pill)
	set_render_draw_color(renderer, txt_col.r, txt_col.g, txt_col.b, 255)
	render_draw_rect(renderer, &pill)
	draw_text_centered(renderer, cx, cy - 4, text, 1, txt_col)
}

fn draw_hud_and_controls(renderer &Renderer, sx int, sy int, g &BlackjackGame) {
	// Top Header Balance & Stats
	draw_text(renderer, 30 + sx, 25 + sy, 'CHIPS: $$${g.chips} | WON: ${g.hands_won} | LOST: ${g.hands_lost} | BJ: ${g.blackjacks_hit}', 1, Color{ r: 240, g: 230, b: 180 })

	// Bottom Action Bar
	bar_rect := Rect{ x: 20 + sx, y: 566 + sy, w: 760, h: 28 }
	set_render_draw_color(renderer, 10, 35, 20, 240)
	render_fill_rect(renderer, &bar_rect)
	set_render_draw_color(renderer, 50, 140, 80, 255)
	render_draw_rect(renderer, &bar_rect)

	controls_str := match g.state {
		.betting     { '[SPACE/ENTER] DEAL | [1-5] CHIPS (+$$5..$$500) | [C] CLEAR | [M] SOUND' }
		.player_turn { '[H] HIT | [S] STAND | [D] DOUBLE | [P] SPLIT | [I] INSURANCE' }
		else         { '[SPACE/ENTER] NEXT HAND | [M] SOUND' }
	}
	draw_text_centered(renderer, 400 + sx, 574 + sy, controls_str, 1, Color{ r: 255, g: 235, b: 120 })

	// Center Announcement Banner
	if g.celebration != '' {
		box_w := 560
		box_h := 46
		bx := (800 - box_w) / 2 + sx
		by := 218 + sy

		b_rect := Rect{ x: bx, y: by, w: box_w, h: box_h }
		set_render_draw_color(renderer, 10, 16, 28, 250)
		render_fill_rect(renderer, &b_rect)

		set_render_draw_color(renderer, 255, 215, 50, 255)
		render_draw_rect(renderer, &b_rect)

		draw_text_centered(renderer, 400 + sx, by + 15, g.celebration, 2, Color{ r: 255, g: 225, b: 60 })
	}
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
