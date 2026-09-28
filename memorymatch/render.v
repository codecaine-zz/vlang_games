module main

import math

pub fn render_memory_match(renderer &Renderer, game &MemoryGame, screen_w int, screen_h int, hover_idx int) {
	// Screen shake calculation
	mut shake_x := 0
	mut shake_y := 0
	if game.shake_timer > 0.0 && game.shake_intensity > 0.0 {
		decay := game.shake_timer / 0.45
		s := game.shake_intensity * decay
		shake_x = int(math.sin(game.anim_timer * 45.0) * s)
		shake_y = int(math.cos(game.anim_timer * 40.0) * s)
	}

	// 1. Background: Deep royal navy with subtle ambient vignette
	set_render_draw_color(renderer, 12, 16, 28, 255)
	render_clear(renderer)

	// Luxury grid background with ambient dots
	set_render_draw_color(renderer, 20, 26, 44, 255)
	for y := 60; y < screen_h; y += 32 {
		render_draw_line(renderer, 0, y, screen_w, y)
	}
	for x := 0; x < screen_w; x += 32 {
		render_draw_line(renderer, x, 60, x, screen_h)
	}

	// 2. Top Header HUD
	hud_h := 54
	set_render_draw_color(renderer, 10, 14, 24, 250)
	render_fill_rect(renderer, &Rect{x: 0, y: 0, w: screen_w, h: hud_h})
	set_render_draw_color(renderer, 215, 175, 45, 255)
	render_draw_line(renderer, 0, hud_h, screen_w, hud_h)

	draw_text(renderer, 20, 18, 'MEMORY MATCH', 2, Color{r: 255, g: 215, b: 0})

	mode_name := match game.grid_mode {
		.grid_4x4 { '4X4 (8 PAIRS)' }
		.grid_6x4 { '6X4 (12 PAIRS)' }
		.grid_6x6 { '6X6 (18 PAIRS)' }
	}
	draw_text(renderer, 225, 22, '[G] ${mode_name}', 1, Color{r: 140, g: 200, b: 255})

	draw_text(renderer, 380, 18, 'TURNS: ${game.turns}', 2, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, 530, 18, 'PAIRS: ${game.matches}/${game.total_pairs}', 2, Color{r: 100, g: 255, b: 150})

	sec := int(game.timer)
	time_str := '${sec / 60:02d}:${sec % 60:02d}'
	draw_text(renderer, 710, 18, 'TIME: ${time_str}', 2, Color{r: 255, g: 220, b: 60})

	// 3. Calculate Dynamic Card Layout Grid
	board_y := 70
	avail_w := screen_w - 60
	avail_h := screen_h - board_y - 45

	card_w := math.min(int(avail_w / game.cols) - 12, 100)
	card_h := math.min(int(avail_h / game.rows) - 12, 110)

	total_grid_w := game.cols * (card_w + 12) - 12
	total_grid_h := game.rows * (card_h + 12) - 12
	start_x := (screen_w - total_grid_w) / 2 + shake_x
	start_y := board_y + (avail_h - total_grid_h) / 2 + shake_y

	for row in 0 .. game.rows {
		for col in 0 .. game.cols {
			idx := row * game.cols + col
			if idx >= game.cards.len { continue }

			card := game.cards[idx]
			mut cx := start_x + col * (card_w + 12)
			cy := start_y + row * (card_h + 12)

			// Shake offset on mismatch
			if card.shake_timer > 0.0 {
				cx += int(math.sin(card.shake_timer * 40.0) * 5.0)
			}

			is_hover := hover_idx == idx && !card.is_face_up && !card.is_matched

			draw_card_3d(renderer, &card, cx, cy, card_w, card_h, is_hover, game.sprite_texture)
		}
	}

	// 4. Special Effects (Shockwaves, Particles, Floating Badges)
	draw_special_effects(renderer, shake_x, shake_y, game)

	// 5. Footer Controls Hint
	draw_text_centered(renderer, screen_w / 2, screen_h - 22, '[LEFT CLICK] FLIP CARD  [G] GRID MODE  [R] NEW GAME  [S] SOUND', 1, Color{r: 160, g: 180, b: 220})

	// 6. Victory Modal Overlay
	if game.state == .game_won {
		draw_victory_modal(renderer, game, screen_w, screen_h, time_str)
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}

fn draw_special_effects(renderer &Renderer, sx int, sy int, g &MemoryGame) {
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
			fill_circ(renderer, px, py, sz)
		} else if p.shape_type == 2 {
			c_rect := Rect{ x: px - sz, y: py - sz / 2, w: sz * 2, h: sz }
			set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
			render_fill_rect(renderer, &c_rect)
		} else {
			fill_circ(renderer, px, py, sz)
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

fn draw_status_pill(renderer &Renderer, cx int, cy int, text string, bg_col Color, txt_col Color) {
	tw := text.len * 8 + 18
	pill := Rect{ x: cx - tw / 2, y: cy - 9, w: tw, h: 18 }
	set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, 240)
	render_fill_rect(renderer, &pill)
	set_render_draw_color(renderer, txt_col.r, txt_col.g, txt_col.b, 255)
	render_draw_rect(renderer, &pill)
	draw_text_centered(renderer, cx, cy - 4, text, 1, txt_col)
}

fn draw_victory_modal(renderer &Renderer, game &MemoryGame, screen_w int, screen_h int, time_str string) {
	set_render_draw_color(renderer, 0, 0, 0, 190)
	render_fill_rect(renderer, &Rect{x: 0, y: 0, w: screen_w, h: screen_h})

	mw := 500
	mh := 280
	mx := (screen_w - mw) / 2
	my := (screen_h - mh) / 2
	m_rect := Rect{x: mx, y: my, w: mw, h: mh}

	set_render_draw_color(renderer, 20, 26, 48, 255)
	render_fill_rect(renderer, &m_rect)
	set_render_draw_color(renderer, 255, 215, 45, 255)
	render_draw_rect(renderer, &m_rect)

	draw_text_centered(renderer, screen_w / 2, my + 24, '★ GRID CLEARED! ★', 3, Color{r: 255, g: 215, b: 0})

	// Render Star Rating
	for s in 0 .. 3 {
		star_x := screen_w / 2 - 40 + s * 40
		star_col := if s < game.stars { Color{r: 255, g: 215, b: 0} } else { Color{r: 60, g: 65, b: 80} }
		draw_star_icon(renderer, star_x, my + 80, 14, star_col)
	}

	draw_text_centered(renderer, screen_w / 2, my + 120, 'TOTAL TURNS: ${game.turns}', 2, Color{r: 255, g: 255, b: 255})
	draw_text_centered(renderer, screen_w / 2, my + 150, 'CLEAR TIME: ${time_str}', 2, Color{r: 100, g: 255, b: 180})
	draw_text_centered(renderer, screen_w / 2, my + 180, 'MAX COMBO: ${game.max_combo}X', 2, Color{r: 255, g: 200, b: 60})

	draw_text_centered(renderer, screen_w / 2, my + 230, 'PRESS [SPACE] OR [R] TO PLAY AGAIN', 1, Color{r: 140, g: 200, b: 255})
}

fn get_card_icon_rect(icon CardIcon) Rect {
	return match icon {
		.gem { Rect{x: 0, y: 0, w: 64, h: 64} }
		.crown { Rect{x: 64, y: 0, w: 64, h: 64} }
		.star { Rect{x: 128, y: 0, w: 64, h: 64} }
		.key { Rect{x: 192, y: 0, w: 64, h: 64} }
		.potion { Rect{x: 256, y: 0, w: 64, h: 64} }
		.fire { Rect{x: 320, y: 0, w: 64, h: 64} }
		.lightning { Rect{x: 384, y: 0, w: 64, h: 64} }
		.heart { Rect{x: 448, y: 0, w: 64, h: 64} }
		.crescent { Rect{x: 0, y: 64, w: 64, h: 64} }
		.atom { Rect{x: 64, y: 64, w: 64, h: 64} }
		.rocket { Rect{x: 128, y: 64, w: 64, h: 64} }
		.shield { Rect{x: 192, y: 64, w: 64, h: 64} }
		.diamond { Rect{x: 256, y: 64, w: 64, h: 64} }
		.coin { Rect{x: 320, y: 64, w: 64, h: 64} }
		.music { Rect{x: 384, y: 64, w: 64, h: 64} }
		.clover { Rect{x: 448, y: 64, w: 64, h: 64} }
		.bell { Rect{x: 0, y: 128, w: 64, h: 64} }
		.skull { Rect{x: 64, y: 128, w: 64, h: 64} }
	}
}

fn draw_card_3d(renderer &Renderer, card &Card, cx int, cy int, w int, h int, is_hover bool, tex &Texture) {
	angle := card.flip_progress * math.pi
	scale_x := math.abs(math.cos(angle))
	is_front := math.cos(angle) < 0.0 || card.flip_progress >= 0.5

	cur_w := math.max(int(f64(w) * scale_x), 4)
	offset_x := (w - cur_w) / 2
	rx := cx + offset_x

	// Drop shadow
	set_render_draw_color(renderer, 0, 0, 0, 110)
	shadow := Rect{x: rx + 2, y: cy + 3, w: cur_w, h: h}
	render_fill_rect(renderer, &shadow)

	card_rect := Rect{x: rx, y: cy, w: cur_w, h: h}

	if card.is_matched {
		// Matched card: Soft cyan glow tile
		set_render_draw_color(renderer, 22, 36, 52, 255)
		render_fill_rect(renderer, &card_rect)
		set_render_draw_color(renderer, 80, 220, 140, 255)
		render_draw_rect(renderer, &card_rect)
		if cur_w > 20 {
			if tex != unsafe { nil } {
				src := get_card_icon_rect(card.icon)
				icon_sz := int(math.min(f64(cur_w) * 0.75, f64(h) * 0.7))
				dst := Rect{
					x: rx + (cur_w - icon_sz) / 2
					y: cy + (h - icon_sz) / 2
					w: icon_sz
					h: icon_sz
				}
				render_copy(renderer, tex, &src, &dst)
			} else {
				draw_card_icon(renderer, card.icon, rx + cur_w / 2, cy + h / 2, cur_w)
			}
		}
		return
	}

	if is_front {
		// Front of card (Ivory / Platinum tile with glowing icon)
		set_render_draw_color(renderer, 252, 250, 244, 255)
		render_fill_rect(renderer, &card_rect)

		// Border & Inner Inlay
		set_render_draw_color(renderer, 35, 38, 45, 255)
		render_draw_rect(renderer, &card_rect)

		if cur_w > 12 {
			inner_rect := Rect{x: rx + 3, y: cy + 3, w: cur_w - 6, h: h - 6}
			set_render_draw_color(renderer, 220, 205, 175, 255)
			render_draw_rect(renderer, &inner_rect)
		}

		if cur_w > 20 {
			if tex != unsafe { nil } {
				src := get_card_icon_rect(card.icon)
				icon_sz := int(math.min(f64(cur_w) * 0.75, f64(h) * 0.7))
				dst := Rect{
					x: rx + (cur_w - icon_sz) / 2
					y: cy + (h - icon_sz) / 2
					w: icon_sz
					h: icon_sz
				}
				render_copy(renderer, tex, &src, &dst)
			} else {
				draw_card_icon(renderer, card.icon, rx + cur_w / 2, cy + h / 2, cur_w)
			}
		}
	} else {
		// Back of card (Deep sapphire metallic with gold diamond lattice)
		if tex != unsafe { nil } && cur_w > 10 {
			src := Rect{x: 128, y: 128, w: 64, h: 64}
			dst := Rect{x: rx, y: cy, w: cur_w, h: h}
			render_copy(renderer, tex, &src, &dst)
			border_col := if is_hover { Color{r: 255, g: 220, b: 50} } else { Color{r: 215, g: 175, b: 45} }
			set_render_draw_color(renderer, border_col.r, border_col.g, border_col.b, 255)
			render_draw_rect(renderer, &card_rect)
			return
		}

		set_render_draw_color(renderer, 20, 32, 58, 255)
		render_fill_rect(renderer, &card_rect)

		border_col := if is_hover { Color{r: 255, g: 220, b: 50} } else { Color{r: 215, g: 175, b: 45} }
		set_render_draw_color(renderer, border_col.r, border_col.g, border_col.b, 255)
		render_draw_rect(renderer, &card_rect)

		if cur_w > 20 {
			inner := Rect{x: rx + 3, y: cy + 3, w: cur_w - 6, h: h - 6}
			set_render_draw_color(renderer, 30, 48, 85, 255)
			render_fill_rect(renderer, &inner)

			mid_x := rx + cur_w / 2
			mid_y := cy + h / 2

			// Gold Star Medallion Center
			draw_star_icon(renderer, mid_x, mid_y, 8, Color{ r: 245, g: 205, b: 40 })
			draw_circle_ring(renderer, mid_x, mid_y, 11, 1, Color{ r: 255, g: 255, b: 255, a: 140 })
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

fn draw_card_icon(renderer &Renderer, icon CardIcon, icx int, icy int, cw int) {
	scale := math.min(f64(cw) / 70.0, 1.0)
	rad := int(16.0 * scale)

	match icon {
		.gem {
			// Cyan Crystal Gem
			set_render_draw_color(renderer, 40, 210, 240, 255)
			render_fill_rect(renderer, &Rect{x: icx - rad, y: icy - rad / 2, w: rad * 2, h: rad})
			set_render_draw_color(renderer, 180, 250, 255, 255)
			render_fill_rect(renderer, &Rect{x: icx - rad / 2, y: icy - rad, w: rad, h: rad * 2})
		}
		.crown {
			// Gold Crown
			set_render_draw_color(renderer, 255, 200, 30, 255)
			render_fill_rect(renderer, &Rect{x: icx - rad, y: icy + rad / 4, w: rad * 2, h: rad / 2})
			render_fill_rect(renderer, &Rect{x: icx - rad, y: icy - rad / 2, w: rad / 3, h: rad})
			render_fill_rect(renderer, &Rect{x: icx - rad / 6, y: icy - rad / 2 - 4, w: rad / 3, h: rad + 4})
			render_fill_rect(renderer, &Rect{x: icx + rad * 2 / 3, y: icy - rad / 2, w: rad / 3, h: rad})
		}
		.star {
			draw_star_icon(renderer, icx, icy, rad, Color{r: 255, g: 215, b: 0})
		}
		.key {
			// Gold Key
			set_render_draw_color(renderer, 240, 190, 40, 255)
			fill_circ(renderer, icx - rad / 2, icy, rad / 2)
			render_fill_rect(renderer, &Rect{x: icx - rad / 2, y: icy - 2, w: rad + 6, h: 4})
			render_fill_rect(renderer, &Rect{x: icx + rad / 2, y: icy - 2, w: 4, h: 8})
		}
		.potion {
			// Ruby Potion Flask
			set_render_draw_color(renderer, 230, 40, 60, 255)
			fill_circ(renderer, icx, icy + 4, rad * 3 / 4)
			set_render_draw_color(renderer, 200, 150, 70, 255)
			render_fill_rect(renderer, &Rect{x: icx - 3, y: icy - rad, w: 6, h: 8})
		}
		.fire {
			// Flame
			set_render_draw_color(renderer, 255, 120, 20, 255)
			fill_circ(renderer, icx, icy + 4, rad * 3 / 4)
			set_render_draw_color(renderer, 255, 220, 40, 255)
			fill_circ(renderer, icx, icy + 4, rad / 2)
		}
		.lightning {
			// Lightning Bolt
			set_render_draw_color(renderer, 255, 235, 40, 255)
			render_fill_rect(renderer, &Rect{x: icx - 3, y: icy - rad, w: 6, h: rad})
			render_fill_rect(renderer, &Rect{x: icx - 8, y: icy - 2, w: 16, h: 4})
			render_fill_rect(renderer, &Rect{x: icx - 3, y: icy, w: 6, h: rad})
		}
		.heart {
			// Crimson Heart
			set_render_draw_color(renderer, 235, 40, 60, 255)
			fill_circ(renderer, icx - rad / 3, icy - rad / 4, rad / 2)
			fill_circ(renderer, icx + rad / 3, icy - rad / 4, rad / 2)
			render_fill_rect(renderer, &Rect{x: icx - rad / 2, y: icy, w: rad, h: rad / 2})
		}
		.crescent {
			// Silver Glowing Moon
			set_render_draw_color(renderer, 220, 230, 255, 255)
			fill_circ(renderer, icx, icy, rad)
			set_render_draw_color(renderer, 235, 240, 250, 255)
			fill_circ(renderer, icx + rad / 3, icy - rad / 4, rad * 3 / 4)
		}
		.atom {
			// Cyan Atomic Rings
			set_render_draw_color(renderer, 40, 220, 240, 255)
			fill_circ(renderer, icx, icy, 4)
			draw_circ(renderer, icx, icy, rad)
		}
		.rocket {
			// Silver Rocket
			set_render_draw_color(renderer, 200, 210, 225, 255)
			render_fill_rect(renderer, &Rect{x: icx - 4, y: icy - rad, w: 8, h: rad * 2})
			set_render_draw_color(renderer, 240, 40, 40, 255)
			render_fill_rect(renderer, &Rect{x: icx - 8, y: icy + rad / 2, w: 16, h: 4})
		}
		.shield {
			// Knight Shield
			set_render_draw_color(renderer, 70, 130, 220, 255)
			render_fill_rect(renderer, &Rect{x: icx - rad * 3 / 4, y: icy - rad, w: rad * 3 / 2, h: rad * 3 / 2})
			set_render_draw_color(renderer, 255, 215, 0, 255)
			render_draw_line(renderer, icx, icy - rad, icx, icy + rad / 2)
		}
		.diamond {
			set_render_draw_color(renderer, 60, 180, 255, 255)
			render_fill_rect(renderer, &Rect{x: icx - rad / 2, y: icy - rad / 2, w: rad, h: rad})
		}
		.coin {
			set_render_draw_color(renderer, 255, 210, 30, 255)
			fill_circ(renderer, icx, icy, rad * 3 / 4)
			set_render_draw_color(renderer, 180, 130, 20, 255)
			draw_circ(renderer, icx, icy, rad / 2)
		}
		.music {
			set_render_draw_color(renderer, 200, 60, 220, 255)
			fill_circ(renderer, icx - 6, icy + 6, 4)
			fill_circ(renderer, icx + 6, icy + 4, 4)
			render_fill_rect(renderer, &Rect{x: icx - 4, y: icy - 8, w: 3, h: 14})
			render_fill_rect(renderer, &Rect{x: icx + 8, y: icy - 10, w: 3, h: 14})
			render_fill_rect(renderer, &Rect{x: icx - 4, y: icy - 10, w: 15, h: 4})
		}
		.clover {
			set_render_draw_color(renderer, 40, 200, 60, 255)
			fill_circ(renderer, icx - 4, icy - 4, 5)
			fill_circ(renderer, icx + 4, icy - 4, 5)
			fill_circ(renderer, icx - 4, icy + 4, 5)
			fill_circ(renderer, icx + 4, icy + 4, 5)
		}
		.bell {
			set_render_draw_color(renderer, 255, 200, 40, 255)
			fill_circ(renderer, icx, icy, rad * 2 / 3)
			render_fill_rect(renderer, &Rect{x: icx - rad * 3 / 4, y: icy + 2, w: rad * 3 / 2, h: 4})
		}
		.skull {
			set_render_draw_color(renderer, 220, 225, 235, 255)
			fill_circ(renderer, icx, icy - 2, rad * 2 / 3)
			render_fill_rect(renderer, &Rect{x: icx - 4, y: icy + 4, w: 8, h: 6})
			set_render_draw_color(renderer, 20, 20, 25, 255)
			fill_circ(renderer, icx - 3, icy - 2, 2)
			fill_circ(renderer, icx + 3, icy - 2, 2)
		}
	}
}

fn draw_star_icon(renderer &Renderer, cx int, cy int, radius int, col Color) {
	set_render_draw_color(renderer, col.r, col.g, col.b, 255)
	fill_circ(renderer, cx, cy, radius / 2)
	render_fill_rect(renderer, &Rect{x: cx - radius, y: cy - 2, w: radius * 2, h: 4})
	render_fill_rect(renderer, &Rect{x: cx - 2, y: cy - radius, w: 4, h: radius * 2})
}

fn fill_circ(renderer &Renderer, cx int, cy int, radius int) {
	for y := -radius; y <= radius; y++ {
		for x := -radius; x <= radius; x++ {
			if x * x + y * y <= radius * radius {
				render_draw_point(renderer, cx + x, cy + y)
			}
		}
	}
}

fn draw_circ(renderer &Renderer, cx int, cy int, radius int) {
	for deg := 0.0; deg < 360.0; deg += 3.0 {
		rad := (deg * math.pi) / 180.0
		x := cx + int(f64(radius) * math.cos(rad))
		y := cy + int(f64(radius) * math.sin(rad))
		render_draw_point(renderer, x, y)
	}
}

pub fn get_card_index_at(mx int, my int, game &MemoryGame, screen_w int, screen_h int) int {
	board_y := 70
	avail_w := screen_w - 60
	avail_h := screen_h - board_y - 45

	card_w := math.min(int(avail_w / game.cols) - 12, 100)
	card_h := math.min(int(avail_h / game.rows) - 12, 110)

	total_grid_w := game.cols * (card_w + 12) - 12
	total_grid_h := game.rows * (card_h + 12) - 12
	start_x := (screen_w - total_grid_w) / 2
	start_y := board_y + (avail_h - total_grid_h) / 2

	for row in 0 .. game.rows {
		for col in 0 .. game.cols {
			idx := row * game.cols + col
			if idx >= game.cards.len { continue }

			cx := start_x + col * (card_w + 12)
			cy := start_y + row * (card_h + 12)

			if mx >= cx && mx <= cx + card_w && my >= cy && my <= cy + card_h {
				return idx
			}
		}
	}
	return -1
}
