module main

import math

fn draw_war_game(renderer &Renderer, g &WarGame) {
	// Calculate screen shake offset
	mut shake_x := 0
	mut shake_y := 0
	if g.shake_timer > 0.0 && g.shake_intensity > 0.0 {
		decay := g.shake_timer / 0.5
		s := g.shake_intensity * decay
		shake_x = int(math.sin(g.anim_timer * 45.0) * s)
		shake_y = int(math.cos(g.anim_timer * 40.0) * s)
	}

	// Deep Walnut table outer frame
	set_render_draw_color(renderer, 20, 14, 10, 255)
	render_clear(renderer)

	draw_table_wood_rim(renderer)
	draw_battlefield_felt(renderer, shake_x, shake_y)
	draw_center_crests_and_demarcation(renderer, shake_x, shake_y)
	draw_commander_profiles(renderer, shake_x, shake_y, g)
	draw_war_frontline_meter(renderer, shake_x, shake_y, g)
	draw_battlefield_duel(renderer, shake_x, shake_y, g)
	draw_flying_cards_and_pot(renderer, shake_x, shake_y, g)
	draw_special_effects(renderer, shake_x, shake_y, g)
	draw_hud_and_announcements(renderer, shake_x, shake_y, g)

	if g.phase == .game_over {
		draw_game_over_modal(renderer, g)
	}
}

// -------------------------------------------------------------
// 1. Table & Background Felt Aesthetics
// -------------------------------------------------------------

fn draw_table_wood_rim(renderer &Renderer) {
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

fn draw_battlefield_felt(renderer &Renderer, sx int, sy int) {
	// Top General Territory (Imperial Crimson Felt with vertical gradient)
	for y := 12; y < 290; y += 2 {
		ratio := f64(y - 12) / 278.0
		r := u8(42.0 + ratio * 20.0)
		g := u8(12.0 + ratio * 8.0)
		b := u8(18.0 + ratio * 10.0)
		set_render_draw_color(renderer, r, g, b, 255)
		rect := Rect{ x: 12 + sx, y: y + sy, w: 776, h: 2 }
		render_fill_rect(renderer, &rect)
	}

	// Bottom Commander Territory (Royal Navy Blue Felt with vertical gradient)
	for y := 290; y < 588; y += 2 {
		ratio := f64(y - 290) / 298.0
		r := u8(12.0 + (1.0 - ratio) * 16.0)
		g := u8(24.0 + (1.0 - ratio) * 22.0)
		b := u8(55.0 + (1.0 - ratio) * 35.0)
		set_render_draw_color(renderer, r, g, b, 255)
		rect := Rect{ x: 12 + sx, y: y + sy, w: 776, h: 2 }
		render_fill_rect(renderer, &rect)
	}

	// Inner Stitched Border
	top_box := Rect{ x: 18 + sx, y: 18 + sy, w: 764, h: 266 }
	set_render_draw_color(renderer, 160, 45, 55, 140)
	render_draw_rect(renderer, &top_box)

	bot_box := Rect{ x: 18 + sx, y: 296 + sy, w: 764, h: 284 }
	set_render_draw_color(renderer, 45, 95, 185, 140)
	render_draw_rect(renderer, &bot_box)
}

fn draw_center_crests_and_demarcation(renderer &Renderer, sx int, sy int) {
	cy := 290 + sy

	// Dual Gold Frontline Ribbons
	set_render_draw_color(renderer, 180, 140, 30, 255)
	render_draw_line(renderer, 18 + sx, cy - 2, 782 + sx, cy - 2)
	set_render_draw_color(renderer, 245, 215, 75, 255)
	render_draw_line(renderer, 18 + sx, cy - 1, 782 + sx, cy - 1)
	render_draw_line(renderer, 18 + sx, cy, 782 + sx, cy)
	set_render_draw_color(renderer, 180, 140, 30, 255)
	render_draw_line(renderer, 18 + sx, cy + 1, 782 + sx, cy + 1)

	// Center Crest Medallion
	mx := 460 + sx
	draw_filled_circle(renderer, mx, cy, 26, Color{ r: 24, g: 20, b: 30 })
	draw_circle_ring(renderer, mx, cy, 26, 3, Color{ r: 235, g: 195, b: 50 })
	draw_circle_ring(renderer, mx, cy, 22, 1, Color{ r: 255, g: 235, b: 120 })

	// Crossed Sabers in Medallion
	set_render_draw_color(renderer, 255, 255, 255, 240)
	render_draw_line(renderer, mx - 12, cy - 12, mx + 12, cy + 12)
	render_draw_line(renderer, mx + 12, cy - 12, mx - 12, cy + 12)
	// Saber guards
	set_render_draw_color(renderer, 240, 200, 50, 255)
	render_draw_line(renderer, mx - 15, cy - 8, mx - 8, cy - 15)
	render_draw_line(renderer, mx + 15, cy - 8, mx + 8, cy - 15)
	render_draw_line(renderer, mx - 15, cy + 8, mx - 8, cy + 15)
	render_draw_line(renderer, mx + 15, cy + 8, mx + 8, cy + 15)

	// Faint Watermark Emblem on Battlefield Background
	draw_circle_ring(renderer, mx, cy, 70, 1, Color{ r: 255, g: 255, b: 255, a: 18 })
	draw_circle_ring(renderer, mx, cy, 100, 1, Color{ r: 255, g: 215, b: 0, a: 12 })
}

// -------------------------------------------------------------
// 2. Commander Profiles & Tactical Status
// -------------------------------------------------------------

fn draw_commander_profiles(renderer &Renderer, sx int, sy int, g &WarGame) {
	// Top Left: General Bob
	bob_x := 30 + sx
	bob_y := 28 + sy

	// Portrait Frame
	frame_rect := Rect{ x: bob_x, y: bob_y, w: 56, h: 56 }
	set_render_draw_color(renderer, 20, 15, 22, 255)
	render_fill_rect(renderer, &frame_rect)
	set_render_draw_color(renderer, 215, 60, 70, 255)
	render_draw_rect(renderer, &frame_rect)

	draw_bob_avatar(renderer, bob_x + 6, bob_y + 6, g.bob_mood)

	// Bob Info Text
	draw_text(renderer, bob_x + 66, bob_y + 4, 'GENERAL BOB', 1, Color{ r: 255, g: 140, b: 140 })
	draw_text(renderer, bob_x + 66, bob_y + 18, 'SUPREME OPPONENT', 1, Color{ r: 200, g: 170, b: 170 })

	ai_tot := g.get_ai_total_cards()
	draw_text(renderer, bob_x + 66, bob_y + 36, 'FORCES: ${ai_tot} / 52 CARDS', 1, Color{ r: 255, g: 220, b: 220 })

	// AI Deck & Win Pile
	if g.ai_draw_pile.len > 0 {
		draw_stacked_deck_back(renderer, 95 + sx, 95 + sy, 68, 96, g.ai_draw_pile.len, Color{ r: 170, g: 25, b: 35 }, 'DRAW')
	}
	if g.ai_win_pile.len > 0 {
		draw_stacked_deck_back(renderer, 185 + sx, 95 + sy, 68, 96, g.ai_win_pile.len, Color{ r: 110, g: 15, b: 25 }, 'CAPTURED')
	}

	// Bottom Left: Player Commander
	p_x := 30 + sx
	p_y := 510 + sy

	p_frame := Rect{ x: p_x, y: p_y, w: 56, h: 56 }
	set_render_draw_color(renderer, 15, 20, 32, 255)
	render_fill_rect(renderer, &p_frame)
	set_render_draw_color(renderer, 65, 140, 245, 255)
	render_draw_rect(renderer, &p_frame)

	draw_player_avatar(renderer, p_x + 6, p_y + 6)

	draw_text(renderer, p_x + 66, p_y + 6, 'COMMANDER (YOU)', 1, Color{ r: 140, g: 195, b: 255 })
	draw_text(renderer, p_x + 66, p_y + 20, 'HERO OF THE REALM', 1, Color{ r: 170, g: 195, b: 230 })

	p_tot := g.get_player_total_cards()
	draw_text(renderer, p_x + 66, p_y + 38, 'FORCES: ${p_tot} / 52 CARDS', 1, Color{ r: 220, g: 240, b: 255 })

	// Player Deck & Win Pile
	if g.player_draw_pile.len > 0 {
		draw_stacked_deck_back(renderer, 95 + sx, 385 + sy, 68, 96, g.player_draw_pile.len, Color{ r: 25, g: 70, b: 180 }, 'DRAW')
	}
	if g.player_win_pile.len > 0 {
		draw_stacked_deck_back(renderer, 185 + sx, 385 + sy, 68, 96, g.player_win_pile.len, Color{ r: 15, g: 40, b: 120 }, 'CAPTURED')
	}
}

fn draw_bob_avatar(renderer &Renderer, ax int, ay int, mood int) {
	// Face Background
	face := Rect{ x: ax + 8, y: ay + 14, w: 28, h: 26 }
	set_render_draw_color(renderer, 235, 185, 150, 255)
	render_fill_rect(renderer, &face)

	// General Peaked Cap (Military Red & Gold Band)
	cap_top := Rect{ x: ax + 4, y: ay + 2, w: 36, h: 10 }
	set_render_draw_color(renderer, 140, 20, 25, 255)
	render_fill_rect(renderer, &cap_top)

	gold_band := Rect{ x: ax + 4, y: ay + 11, w: 36, h: 4 }
	set_render_draw_color(renderer, 245, 205, 45, 255)
	render_fill_rect(renderer, &gold_band)

	visor := Rect{ x: ax + 6, y: ay + 14, w: 32, h: 3 }
	set_render_draw_color(renderer, 25, 25, 30, 255)
	render_fill_rect(renderer, &visor)

	// Eyes & Eyebrows depending on mood
	match mood {
		1 {
			// Smug / Confident
			set_render_draw_color(renderer, 30, 25, 30, 255)
			render_draw_line(renderer, ax + 12, ay + 20, ax + 18, ay + 21)
			render_draw_line(renderer, ax + 26, ay + 21, ax + 32, ay + 20)
			// Smug smile
			render_draw_line(renderer, ax + 16, ay + 34, ax + 28, ay + 31)
		}
		2 {
			// Worried / Shocked
			set_render_draw_color(renderer, 30, 25, 30, 255)
			draw_filled_circle(renderer, ax + 15, ay + 21, 3, Color{ r: 255, g: 255, b: 255 })
			draw_filled_circle(renderer, ax + 29, ay + 21, 3, Color{ r: 255, g: 255, b: 255 })
			draw_filled_circle(renderer, ax + 15, ay + 21, 1, Color{ r: 10, g: 10, b: 10 })
			draw_filled_circle(renderer, ax + 29, ay + 21, 1, Color{ r: 10, g: 10, b: 10 })
			// O-mouth
			draw_circle_ring(renderer, ax + 22, ay + 34, 3, 1, Color{ r: 30, g: 20, b: 20 })
			// Sweat drop
			draw_filled_circle(renderer, ax + 36, ay + 18, 2, Color{ r: 100, g: 200, b: 255 })
		}
		3 {
			// Furious / War Mode
			set_render_draw_color(renderer, 180, 20, 20, 255)
			render_draw_line(renderer, ax + 10, ay + 18, ax + 18, ay + 23)
			render_draw_line(renderer, ax + 34, ay + 18, ax + 26, ay + 23)
			set_render_draw_color(renderer, 255, 50, 50, 255)
			render_draw_point(renderer, ax + 15, ay + 23)
			render_draw_point(renderer, ax + 29, ay + 23)
		}
		else {
			// Neutral Stern Commander
			set_render_draw_color(renderer, 30, 25, 30, 255)
			render_draw_line(renderer, ax + 13, ay + 21, ax + 17, ay + 21)
			render_draw_line(renderer, ax + 27, ay + 21, ax + 31, ay + 21)
			render_draw_line(renderer, ax + 17, ay + 33, ax + 27, ay + 33)
		}
	}

	// Grand Mustache
	set_render_draw_color(renderer, 100, 95, 90, 255)
	for mx := ax + 12; mx <= ax + 32; mx++ {
		render_draw_line(renderer, mx, ay + 27, mx, ay + 30)
	}

	// Collar with Gold Medals
	collar := Rect{ x: ax + 6, y: ay + 38, w: 32, h: 6 }
	set_render_draw_color(renderer, 120, 18, 22, 255)
	render_fill_rect(renderer, &collar)
	draw_filled_circle(renderer, ax + 14, ay + 41, 2, Color{ r: 245, g: 215, b: 50 })
	draw_filled_circle(renderer, ax + 22, ay + 41, 2, Color{ r: 245, g: 215, b: 50 })
	draw_filled_circle(renderer, ax + 30, ay + 41, 2, Color{ r: 245, g: 215, b: 50 })
}

fn draw_player_avatar(renderer &Renderer, ax int, ay int) {
	// Commander Insignia & Laurel Star
	draw_filled_circle(renderer, ax + 22, ay + 22, 18, Color{ r: 20, g: 45, b: 90 })
	draw_circle_ring(renderer, ax + 22, ay + 22, 18, 2, Color{ r: 240, g: 200, b: 60 })

	// Gold Commander Star in Center
	cx := ax + 22
	cy := ay + 22
	set_render_draw_color(renderer, 255, 235, 100, 255)
	star_pts := [
		[cx, cy - 10], [cx + 3, cy - 3], [cx + 10, cy - 3],
		[cx + 5, cy + 2], [cx + 7, cy + 9], [cx, cy + 5],
		[cx - 7, cy + 9], [cx - 5, cy + 2], [cx - 10, cy - 3],
		[cx - 3, cy - 3]
	]
	for i := 0; i < star_pts.len; i++ {
		next := (i + 1) % star_pts.len
		render_draw_line(renderer, star_pts[i][0], star_pts[i][1], star_pts[next][0], star_pts[next][1])
	}
	draw_filled_circle(renderer, cx, cy, 3, Color{ r: 255, g: 255, b: 200 })

	// Ribbon beneath
	rib_l := Rect{ x: ax + 10, y: ay + 38, w: 10, h: 5 }
	rib_r := Rect{ x: ax + 24, y: ay + 38, w: 10, h: 5 }
	set_render_draw_color(renderer, 30, 90, 220, 255)
	render_fill_rect(renderer, &rib_l)
	render_fill_rect(renderer, &rib_r)
}

// -------------------------------------------------------------
// 3. Tug-of-War "War Frontline" Gauge
// -------------------------------------------------------------

fn draw_war_frontline_meter(renderer &Renderer, sx int, sy int, g &WarGame) {
	bx := 732 + sx
	by := 75 + sy
	bw := 26
	bh := 420

	// Beveled metallic housing
	set_render_draw_color(renderer, 10, 12, 18, 255)
	bg := Rect{ x: bx, y: by, w: bw, h: bh }
	render_fill_rect(renderer, &bg)

	set_render_draw_color(renderer, 180, 190, 215, 255)
	render_draw_rect(renderer, &bg)

	p_tot := g.get_player_total_cards()
	p_pct := f64(p_tot) / 52.0
	p_h := int(p_pct * f64(bh))
	ai_h := bh - p_h

	// Red Forces (Top)
	ai_bar := Rect{ x: bx + 3, y: by + 3, w: bw - 6, h: ai_h - 3 }
	set_render_draw_color(renderer, 215, 35, 45, 255)
	render_fill_rect(renderer, &ai_bar)
	// Dark inner shade
	set_render_draw_color(renderer, 140, 20, 30, 255)
	ai_inner := Rect{ x: bx + 5, y: by + 5, w: bw - 10, h: ai_h - 7 }
	if ai_inner.h > 0 { render_fill_rect(renderer, &ai_inner) }

	// Blue Forces (Bottom)
	p_bar := Rect{ x: bx + 3, y: by + bh - p_h, w: bw - 6, h: p_h - 3 }
	set_render_draw_color(renderer, 35, 115, 245, 255)
	render_fill_rect(renderer, &p_bar)
	// Dark inner shade
	set_render_draw_color(renderer, 20, 70, 160, 255)
	p_inner := Rect{ x: bx + 5, y: by + bh - p_h + 2, w: bw - 10, h: p_h - 7 }
	if p_inner.h > 0 { render_fill_rect(renderer, &p_inner) }

	// Frontline Active Clash Indicator (Sparks / Gold Line)
	clash_y := by + ai_h
	pulse := (math.sin(g.pulse_time * 8.0) + 1.0) * 0.5

	clash_line := Rect{ x: bx - 2, y: clash_y - 2, w: bw + 4, h: 4 }
	set_render_draw_color(renderer, 255, u8(200.0 + pulse * 55.0), 50, 255)
	render_fill_rect(renderer, &clash_line)

	// Percentage Labels on Top/Bottom
	draw_text_centered(renderer, bx + bw / 2, by - 14, '${52 - p_tot}', 1, Color{ r: 255, g: 150, b: 150 })
	draw_text_centered(renderer, bx + bw / 2, by + bh + 4, '${p_tot}', 1, Color{ r: 150, g: 200, b: 255 })
}

// -------------------------------------------------------------
// 4. Battlefield Duel & Card Graphics
// -------------------------------------------------------------

fn draw_battlefield_duel(renderer &Renderer, sx int, sy int, g &WarGame) {
	cx := 460 + sx
	card_w := 84
	card_h := 120

	if g.has_battle_card {
		// AI Active Card
		ai_card_y := 128 + sy
		ai_is_winner := g.phase == .comparing && g.round_winner == 2
		draw_card_with_effects(renderer, cx - card_w / 2, ai_card_y, card_w, card_h, g.battle_ai, ai_is_winner, g.pulse_time)
		draw_text_centered(renderer, cx, ai_card_y - 18, 'GENERAL BOB: [ ${get_rank_str(g.battle_ai.rank)} ]', 1, Color{ r: 255, g: 190, b: 190 })

		// Player Active Card
		p_card_y := 332 + sy
		p_is_winner := g.phase == .comparing && g.round_winner == 1
		draw_card_with_effects(renderer, cx - card_w / 2, p_card_y, card_w, card_h, g.battle_player, p_is_winner, g.pulse_time)
		draw_text_centered(renderer, cx, p_card_y + card_h + 8, 'YOUR FORCES: [ ${get_rank_str(g.battle_player.rank)} ]', 1, Color{ r: 190, g: 225, b: 255 })

		// Duel Result Badge (Centered cleanly on the frontline)
		if g.phase == .comparing {
			match g.round_winner {
				1 {
					draw_status_pill(renderer, cx, 290 + sy, '>> PLAYER WINS ROUND <<', Color{ r: 25, g: 130, b: 60 }, Color{ r: 140, g: 255, b: 170 })
				}
				2 {
					draw_status_pill(renderer, cx, 290 + sy, '>> BOB WINS ROUND <<', Color{ r: 150, g: 25, b: 35 }, Color{ r: 255, g: 150, b: 150 })
				}
				3 {
					draw_status_pill(renderer, cx, 290 + sy, '⚔️ TIE! WAR DECLARED! ⚔️', Color{ r: 170, g: 130, b: 15 }, Color{ r: 255, g: 240, b: 80 })
				}
				else {}
			}
		}
	} else {
		// Ready prompt when waiting
		draw_text_centered(renderer, cx, 278 + sy, '⚔️ BATTLE ARENA ⚔️', 1, Color{ r: 245, g: 215, b: 70 })
		if g.phase == .ready {
			draw_text_centered(renderer, cx, 296 + sy, 'PRESS [SPACE] OR CLICK TO ENGAGE', 1, Color{ r: 210, g: 235, b: 255 })
		}
	}
}

fn draw_flying_cards_and_pot(renderer &Renderer, sx int, sy int, g &WarGame) {
	// War Loot Pot Stack (Right of Arena)
	if g.war_pot.len > 0 {
		pot_x := 610 + sx
		pot_y := 242 + sy
		draw_stacked_deck_back(renderer, pot_x, pot_y, 65, 92, g.war_pot.len, Color{ r: 190, g: 155, b: 35 }, 'WAR POT')
	}

	// Flying animated cards
	card_w := 84
	card_h := 120
	for fc in g.flying_cards {
		fx := int(fc.x) + sx
		fy := int(fc.y) + sy

		if fc.is_face_up {
			// 3D Flip scale effect: Card width shrinks to edge and flips
			flip_factor := math.abs(math.cos(fc.flip_progress * math.pi))
			cur_w := int(f64(card_w) * (0.2 + flip_factor * 0.8))
			cur_x := fx + (card_w - cur_w) / 2
			draw_playing_card(renderer, cur_x, fy, cur_w, card_h, fc.card)
		} else {
			col := if fc.is_player { Color{ r: 25, g: 70, b: 180 } } else { Color{ r: 170, g: 25, b: 35 } }
			draw_playing_card_back(renderer, fx, fy, card_w, card_h, col)
		}
	}
}

// -------------------------------------------------------------
// 5. Special Effects, Particles, and Shockwaves
// -------------------------------------------------------------

fn draw_special_effects(renderer &Renderer, sx int, sy int, g &WarGame) {
	// Shockwaves
	for sw in g.shockwaves {
		alpha := u8(255.0 * (1.0 - sw.life / sw.max_life))
		c := Color{ r: sw.color.r, g: sw.color.g, b: sw.color.b, a: alpha }
		draw_circle_ring(renderer, int(sw.cx) + sx, int(sw.cy) + sy, int(sw.radius), int(sw.thickness), c)
	}

	// Particles
	for p in g.particles {
		alpha := u8(255.0 * (1.0 - p.life / p.max_life))
		col := Color{ r: p.color.r, g: p.color.g, b: p.color.b, a: alpha }
		px := int(p.x) + sx
		py := int(p.y) + sy
		sz := int(p.size)

		if p.shape_type == 0 {
			// Spark streak
			set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
			render_draw_line(renderer, px, py, px + int(p.vx * 0.04), py + int(p.vy * 0.04))
			draw_filled_circle(renderer, px, py, sz, col)
		} else if p.shape_type == 2 {
			// Confetti Rect
			c_rect := Rect{ x: px - sz, y: py - sz / 2, w: sz * 2, h: sz }
			set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
			render_fill_rect(renderer, &c_rect)
		} else {
			draw_filled_circle(renderer, px, py, sz, col)
		}
	}

	// Floating Combat Text
	for ft in g.floating_texts {
		alpha := u8(255.0 * (1.0 - ft.life / ft.max_life))
		col := Color{ r: ft.color.r, g: ft.color.g, b: ft.color.b, a: alpha }
		tx := int(ft.x) + sx
		ty := int(ft.y) + sy

		// Background Pill for Floating Text
		tw := ft.text.len * 8 * ft.scale + 16
		pill := Rect{ x: tx - tw / 2, y: ty - 3, w: tw, h: 14 * ft.scale }
		set_render_draw_color(renderer, 10, 12, 20, alpha / 2)
		render_fill_rect(renderer, &pill)

		// Shadow & Text
		draw_text_centered(renderer, tx + 1, ty + 1, ft.text, ft.scale, Color{ r: 0, g: 0, b: 0, a: alpha })
		draw_text_centered(renderer, tx, ty, ft.text, ft.scale, col)
	}
}

// -------------------------------------------------------------
// 6. High-Definition Playing Card Renderer
// -------------------------------------------------------------

fn draw_card_with_effects(renderer &Renderer, x int, y int, w int, h int, c Card, is_winner bool, pulse_time f64) {
	// Golden Winner Aura Halo
	if is_winner {
		glow_size := int((math.sin(pulse_time * 10.0) + 1.0) * 3.0) + 3
		for g_i := glow_size; g_i >= 1; g_i-- {
			glow_rect := Rect{
				x: x - g_i
				y: y - g_i
				w: w + g_i * 2
				h: h + g_i * 2
			}
			set_render_draw_color(renderer, 255, 215, 0, u8(30 + g_i * 12))
			render_draw_rect(renderer, &glow_rect)
		}
	}

	draw_playing_card(renderer, x, y, w, h, c)
}

fn draw_playing_card(renderer &Renderer, x int, y int, w int, h int, c Card) {
	if w <= 4 {
		return
	}

	// Card Drop Shadow
	set_render_draw_color(renderer, 0, 0, 0, 120)
	shadow := Rect{ x: x + 4, y: y + 5, w: w, h: h }
	render_fill_rect(renderer, &shadow)

	// Ivory Card Body
	card_rect := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, 252, 250, 244, 255)
	render_fill_rect(renderer, &card_rect)

	// Outer Beveled Card Border
	set_render_draw_color(renderer, 30, 32, 40, 255)
	render_draw_rect(renderer, &card_rect)

	// Inner Gold / Silver Filigree Margin
	if w > 20 {
		inner_b := Rect{ x: x + 3, y: y + 3, w: w - 6, h: h - 6 }
		set_render_draw_color(renderer, 220, 205, 175, 255)
		render_draw_rect(renderer, &inner_b)
	}

	is_red := c.suit == .hearts || c.suit == .diamonds
	col := if is_red { Color{ r: 215, g: 30, b: 40 } } else { Color{ r: 24, g: 28, b: 36 } }
	rank_s := get_rank_str(c.rank)

	// Corner indicators (Top-Left and Bottom-Right)
	if w >= 50 {
		draw_text(renderer, x + 6, y + 6, rank_s, 1, col)
		draw_suit_pip(renderer, c.suit, x + 11, y + 21, 5)

		// Bottom Right Inverted Pip & Rank
		draw_text(renderer, x + w - 14, y + h - 16, rank_s, 1, col)
		draw_suit_pip(renderer, c.suit, x + w - 10, y + h - 25, 5)
	}

	// Center Artwork & Court Portraits
	cx := x + w / 2
	cy := y + h / 2

	if c.rank == 14 {
		// Ace: Majestic Centerpiece Emblem with Laurels & Starburst
		draw_circle_ring(renderer, cx, cy, 26, 2, Color{ r: col.r, g: col.g, b: col.b, a: 60 })
		draw_suit_pip(renderer, c.suit, cx, cy, 18)
		draw_circle_ring(renderer, cx, cy, 32, 1, Color{ r: 212, g: 175, b: 55, a: 160 })
	} else if c.rank >= 11 && c.rank <= 13 {
		// High Court Royalty Portraits
		draw_court_portrait_hd(renderer, x + 14, y + 22, w - 28, h - 44, c.rank, col)
	} else {
		// Number Cards: Multi-Pip Arrangements
		draw_numbered_card_pips(renderer, x, y, w, h, c.rank, c.suit)
	}
}

fn draw_court_portrait_hd(renderer &Renderer, px int, py int, pw int, ph int, rank int, col Color) {
	if pw <= 10 || ph <= 10 { return }

	p_rect := Rect{ x: px, y: py, w: pw, h: ph }
	set_render_draw_color(renderer, 248, 244, 230, 255)
	render_fill_rect(renderer, &p_rect)

	// Gold Border Box
	set_render_draw_color(renderer, 212, 175, 55, 255)
	render_draw_rect(renderer, &p_rect)

	cx := px + pw / 2
	cy := py + ph / 2

	if rank == 11 {
		// Jack: Valiant Knight with Plumed Helmet & Halberd
		helm := Rect{ x: cx - 12, y: cy - 18, w: 24, h: 16 }
		set_render_draw_color(renderer, 150, 160, 180, 255)
		render_fill_rect(renderer, &helm)
		// Visor slit
		set_render_draw_color(renderer, 30, 35, 45, 255)
		render_draw_line(renderer, cx - 8, cy - 10, cx + 8, cy - 10)
		// Feather Plume
		set_render_draw_color(renderer, col.r, col.g, col.b, 255)
		render_draw_line(renderer, cx - 4, cy - 18, cx - 10, cy - 24)
		render_draw_line(renderer, cx, cy - 18, cx - 6, cy - 26)
		draw_text_centered(renderer, cx, cy + 12, 'JACK', 1, col)
	} else if rank == 12 {
		// Queen: Regal Tiara & Royal Scepter
		tiara := Rect{ x: cx - 14, y: cy - 20, w: 28, h: 10 }
		set_render_draw_color(renderer, 245, 210, 45, 255)
		render_fill_rect(renderer, &tiara)
		// Jewels
		draw_filled_circle(renderer, cx - 7, cy - 20, 2, Color{ r: 215, g: 30, b: 40 })
		draw_filled_circle(renderer, cx, cy - 22, 2, Color{ r: 50, g: 150, b: 255 })
		draw_filled_circle(renderer, cx + 7, cy - 20, 2, Color{ r: 215, g: 30, b: 40 })
		draw_text_centered(renderer, cx, cy + 12, 'QUEEN', 1, col)
	} else if rank == 13 {
		// King: Imperial Crown with Ermine Trim
		crown := Rect{ x: cx - 16, y: cy - 22, w: 32, h: 12 }
		set_render_draw_color(renderer, 245, 205, 40, 255)
		render_fill_rect(renderer, &crown)
		// Crown points
		set_render_draw_color(renderer, 255, 235, 120, 255)
		render_draw_line(renderer, cx - 16, cy - 22, cx - 10, cy - 27)
		render_draw_line(renderer, cx, cy - 22, cx, cy - 28)
		render_draw_line(renderer, cx + 16, cy - 22, cx + 10, cy - 27)
		// Ermine Robe collar
		robe := Rect{ x: cx - 14, y: cy - 4, w: 28, h: 6 }
		set_render_draw_color(renderer, 230, 230, 235, 255)
		render_fill_rect(renderer, &robe)
		draw_text_centered(renderer, cx, cy + 12, 'KING', 1, col)
	}
}

fn draw_numbered_card_pips(renderer &Renderer, x int, y int, w int, h int, rank int, suit CardSuit) {
	cx := x + w / 2
	cy := y + h / 2

	if rank == 2 {
		draw_suit_pip(renderer, suit, cx, cy - 26, 8)
		draw_suit_pip(renderer, suit, cx, cy + 26, 8)
	} else if rank == 3 {
		draw_suit_pip(renderer, suit, cx, cy - 28, 7)
		draw_suit_pip(renderer, suit, cx, cy, 7)
		draw_suit_pip(renderer, suit, cx, cy + 28, 7)
	} else if rank == 4 {
		draw_suit_pip(renderer, suit, cx - 16, cy - 26, 7)
		draw_suit_pip(renderer, suit, cx + 16, cy - 26, 7)
		draw_suit_pip(renderer, suit, cx - 16, cy + 26, 7)
		draw_suit_pip(renderer, suit, cx + 16, cy + 26, 7)
	} else if rank == 5 {
		draw_suit_pip(renderer, suit, cx - 16, cy - 26, 7)
		draw_suit_pip(renderer, suit, cx + 16, cy - 26, 7)
		draw_suit_pip(renderer, suit, cx, cy, 8)
		draw_suit_pip(renderer, suit, cx - 16, cy + 26, 7)
		draw_suit_pip(renderer, suit, cx + 16, cy + 26, 7)
	} else {
		// Large Center Pip for 6-10
		draw_suit_pip(renderer, suit, cx, cy, 15)
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

fn draw_playing_card_back(renderer &Renderer, x int, y int, w int, h int, c Color) {
	// Shadow
	set_render_draw_color(renderer, 0, 0, 0, 100)
	shadow := Rect{ x: x + 3, y: y + 4, w: w, h: h }
	render_fill_rect(renderer, &shadow)

	// Outer card
	card_rect := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, c.r, c.g, c.b, 255)
	render_fill_rect(renderer, &card_rect)

	// Gold Rim
	set_render_draw_color(renderer, 240, 215, 75, 220)
	render_draw_rect(renderer, &card_rect)

	// Inner Margin
	inner := Rect{ x: x + 4, y: y + 4, w: w - 8, h: h - 8 }
	set_render_draw_color(renderer, 255, 255, 255, 140)
	render_draw_rect(renderer, &inner)

	// Diamond Crosshatch pattern
	set_render_draw_color(renderer, 255, 255, 255, 60)
	for ly := y + 10; ly < y + h - 10; ly += 12 {
		for lx := x + 10; lx < x + w - 10; lx += 12 {
			render_draw_point(renderer, lx, ly)
		}
	}
	// Center Star Medallion
	draw_filled_circle(renderer, x + w / 2, y + h / 2, 8, Color{ r: 245, g: 215, b: 60 })
}

fn draw_stacked_deck_back(renderer &Renderer, x int, y int, w int, h int, count int, c Color, label string) {
	layers := int(math.min(count / 4 + 1, 7))
	for i := 0; i < layers; i++ {
		sx := x + i * 2
		sy := y - i * 2
		draw_playing_card_back(renderer, sx, sy, w, h, c)
	}
	draw_text_centered(renderer, x + w / 2 + layers, y + h + 8, '${label} (${count})', 1, Color{ r: 240, g: 240, b: 240 })
}

// -------------------------------------------------------------
// 7. HUD, Announce Banners, and Modals
// -------------------------------------------------------------

fn draw_status_pill(renderer &Renderer, cx int, cy int, text string, bg_col Color, txt_col Color) {
	tw := text.len * 8 + 24
	pill := Rect{ x: cx - tw / 2, y: cy - 10, w: tw, h: 20 }
	set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, 240)
	render_fill_rect(renderer, &pill)
	set_render_draw_color(renderer, txt_col.r, txt_col.g, txt_col.b, 255)
	render_draw_rect(renderer, &pill)
	draw_text_centered(renderer, cx, cy - 4, text, 1, txt_col)
}

fn draw_hud_and_announcements(renderer &Renderer, sx int, sy int, g &WarGame) {
	// Top Stats Ribbon
	draw_text(renderer, 300 + sx, 24 + sy, 'WARS: ${g.wars_fought} | ROUND: ${g.round_count} | AUTO: ${if g.auto_play { 'ON [A]' } else { 'OFF [A]' }}', 1, Color{ r: 245, g: 230, b: 180 })

	// Bottom Controls Bar
	bar_rect := Rect{ x: 20 + sx, y: 568 + sy, w: 760, h: 24 }
	set_render_draw_color(renderer, 14, 18, 28, 245)
	render_fill_rect(renderer, &bar_rect)
	set_render_draw_color(renderer, 60, 85, 140, 255)
	render_draw_rect(renderer, &bar_rect)

	draw_text_centered(renderer, 400 + sx, 574 + sy, '[SPACE/CLICK] BATTLE | [A] AUTO-PLAY | [R] RESTART | [M] SOUND | F11: Fullscreen', 1, Color{ r: 215, g: 235, b: 255 })

	// War Celebration Banner
	if g.celebration != '' && g.phase != .game_over {
		bw := 560
		bh := 46
		bx := 400 - bw / 2 + sx
		by := 210 + sy

		b_rect := Rect{ x: bx, y: by, w: bw, h: bh }
		set_render_draw_color(renderer, 15, 18, 30, 245)
		render_fill_rect(renderer, &b_rect)

		set_render_draw_color(renderer, 255, 215, 50, 255)
		render_draw_rect(renderer, &b_rect)

		draw_text_centered(renderer, 400 + sx, by + 16, g.celebration, 1, Color{ r: 255, g: 235, b: 70 })
	}
}

fn draw_game_over_modal(renderer &Renderer, g &WarGame) {
	// Darkened Backdrop Overlay
	overlay := Rect{ x: 0, y: 0, w: 800, h: 600 }
	set_render_draw_color(renderer, 0, 0, 0, 180)
	render_fill_rect(renderer, &overlay)

	mw := 520
	mh := 280
	mx := (800 - mw) / 2
	my := (600 - mh) / 2

	modal := Rect{ x: mx, y: my, w: mw, h: mh }
	set_render_draw_color(renderer, 18, 22, 36, 250)
	render_fill_rect(renderer, &modal)

	is_player_win := g.match_winner == 1
	border_col := if is_player_win { Color{ r: 255, g: 215, b: 0 } } else { Color{ r: 235, g: 60, b: 60 } }

	set_render_draw_color(renderer, border_col.r, border_col.g, border_col.b, 255)
	render_draw_rect(renderer, &modal)

	title := if is_player_win { '★ SUPREME VICTORY ★' } else { '★ DEFEAT IN BATTLE ★' }
	draw_text_centered(renderer, 400, my + 26, title, 2, border_col)

	sub := if is_player_win { 'YOU CONQUERED ALL 52 CARDS!' } else { 'GENERAL BOB TOOK THE ENTIRE DECK' }
	draw_text_centered(renderer, 400, my + 64, sub, 1, Color{ r: 240, g: 240, b: 240 })

	// Battle Report Stats
	draw_text_centered(renderer, 400, my + 110, 'TOTAL ROUNDS FOUGHT: ${g.round_count}', 1, Color{ r: 200, g: 220, b: 255 })
	draw_text_centered(renderer, 400, my + 135, 'TOTAL WARS DECLARED: ${g.wars_fought}', 1, Color{ r: 255, g: 220, b: 100 })
	draw_text_centered(renderer, 400, my + 160, 'LARGEST WAR POT WON: ${g.highest_pot} CARDS', 1, Color{ r: 120, g: 255, b: 150 })

	draw_status_pill(renderer, 400, my + 225, 'PRESS [SPACE] OR [R] TO PLAY AGAIN', Color{ r: 40, g: 80, b: 160 }, Color{ r: 255, g: 255, b: 255 })
}

// -------------------------------------------------------------
// 8. Geometry Drawing Helpers
// -------------------------------------------------------------

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
