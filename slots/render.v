module main

import time

import math
import os

pub struct SlotsTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm SlotsTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/slots.png',
		'./assets/sprites/slots.png',
		'../assets/sprites/slots.png',
		'slots/assets/sprites/slots.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('slots Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn draw_slots_game(renderer &Renderer, g &SlotsGame, tex &Texture) {
	// Deep Casino Floor Carpet
	set_render_draw_color(renderer, 16, 12, 24, 255)
	render_clear(renderer)

	draw_casino_cabinet(renderer, g)
	draw_marquee_jackpot(renderer, g)
	draw_reels(renderer, g, tex)
	draw_winning_paylines(renderer, g)
	draw_pull_lever(renderer, g)
	draw_control_console(renderer, g)
	draw_coin_particles(renderer, g)
	draw_celebration_banner(renderer, g)

	if g.show_paytable {
		draw_paytable_modal(renderer, g)
	}
}

fn draw_casino_cabinet(renderer &Renderer, _ &SlotsGame) {
	// Machine Outer Chassis (Deep Burgundy / Gold Trim)
	cab_x := 100
	cab_y := 20
	cab_w := 600
	cab_h := 560

	// Chassis Body
	set_render_draw_color(renderer, 45, 15, 25, 255)
	cab_rect := Rect{ x: cab_x, y: cab_y, w: cab_w, h: cab_h }
	render_fill_rect(renderer, &cab_rect)

	// Gold Rim Bezel
	set_render_draw_color(renderer, 220, 175, 45, 255)
	render_draw_rect(renderer, &cab_rect)
	inner_bezel := Rect{ x: cab_x + 4, y: cab_y + 4, w: cab_w - 8, h: cab_h - 8 }
	render_draw_rect(renderer, &inner_bezel)

	// Side Chrome Pillars
	set_render_draw_color(renderer, 180, 190, 210, 255)
	pillar_l := Rect{ x: cab_x + 8, y: cab_y + 80, w: 16, h: 420 }
	pillar_r := Rect{ x: cab_x + cab_w - 24, y: cab_y + 80, w: 16, h: 420 }
	render_fill_rect(renderer, &pillar_l)
	render_fill_rect(renderer, &pillar_r)
}

fn draw_marquee_jackpot(renderer &Renderer, g &SlotsGame) {
	// Top Glowing Marquee Sign
	mx := 140
	my := 32
	mw := 520
	mh := 80

	set_render_draw_color(renderer, 15, 10, 30, 255)
	m_rect := Rect{ x: mx, y: my, w: mw, h: mh }
	render_fill_rect(renderer, &m_rect)

	set_render_draw_color(renderer, 255, 215, 0, 255)
	render_draw_rect(renderer, &m_rect)

	// Title text
	title_str := if g.theme == .vegas_classic { '★ VEGAS CLASSIC 777 ★' } else { '⚡ NEON CYBER SLOTS ⚡' }
	draw_text_centered(renderer, mx + mw / 2, my + 10, title_str, 2, Color{ r: 255, g: 220, b: 50 })

	// Progressive Jackpot Digital LED Meter
	jackpot_str := 'PROGRESSIVE JACKPOT: $${g.progressive_jackpot}'
	draw_text_centered(renderer, mx + mw / 2, my + 42, jackpot_str, 1, Color{ r: 255, g: 50, b: 50 })

	// Marquee Chaser Bulbs along perimeter
	bulb_time := u32(time.ticks()) / 150
	for i := 0; i < 20; i++ {
		bx := mx + 10 + i * 26
		is_lit := (i + int(bulb_time)) % 3 == 0
		col := if is_lit { Color{ r: 255, g: 255, b: 100 } } else { Color{ r: 120, g: 100, b: 30 } }
		b_rect := Rect{ x: bx, y: my + 64, w: 6, h: 6 }
		set_render_draw_color(renderer, col.r, col.g, col.b, 255)
		render_fill_rect(renderer, &b_rect)
	}
}

fn draw_reels(renderer &Renderer, g &SlotsGame, tex &Texture) {
	// Glass Reel Display Window
	rx := int(g.grid_x)
	ry := int(g.grid_y)
	rw := int(f64(g.num_reels) * g.reel_w)
	rh := int(f64(g.visible_rows) * g.row_h)

	// Glass background
	set_render_draw_color(renderer, 245, 245, 250, 255)
	glass_rect := Rect{ x: rx - 6, y: ry - 6, w: rw + 12, h: rh + 12 }
	render_fill_rect(renderer, &glass_rect)

	set_render_draw_color(renderer, 30, 30, 40, 255)
	render_draw_rect(renderer, &glass_rect)

	// Clip reel symbols to window
	clip_rect := Rect{ x: rx, y: ry, w: rw, h: rh }
	render_set_clip_rect(renderer, &clip_rect)

	for r := 0; r < g.num_reels; r++ {
		reel := g.reels[r]
		reel_x := rx + int(f64(r) * g.reel_w)

		// Reel separator lines
		set_render_draw_color(renderer, 200, 205, 215, 255)
		render_draw_line(renderer, reel_x, ry, reel_x, ry + rh)

		// Draw symbols currently rolling in this reel strip
		strip_count := reel.symbols.len
		base_idx := int(reel.offset_y / g.row_h)
		sub_offset := math.fmod(reel.offset_y, g.row_h)

		for i := -1; i <= g.visible_rows + 1; i++ {
			sym_idx := (base_idx + i + strip_count * 10) % strip_count
			sym := reel.symbols[sym_idx]
			sym_y := ry + int(f64(i) * g.row_h - sub_offset)

			draw_slot_symbol(renderer, reel_x + int(g.reel_w * 0.5), sym_y + int(g.row_h * 0.5), sym, tex)
		}

		// Hold Indicator
		if reel.hold {
			set_render_draw_color(renderer, 255, 50, 50, 160)
			hold_overlay := Rect{ x: reel_x, y: ry, w: int(g.reel_w), h: rh }
			render_fill_rect(renderer, &hold_overlay)
			draw_text_centered(renderer, reel_x + int(g.reel_w * 0.5), ry + rh / 2 - 8, 'HELD', 1, Color{ r: 255, g: 255, b: 255 })
		}
	}

	render_set_clip_rect(renderer, unsafe { nil })

	// Reel Grid Frame Border
	set_render_draw_color(renderer, 220, 175, 45, 255)
	grid_border := Rect{ x: rx - 2, y: ry - 2, w: rw + 4, h: rh + 4 }
	render_draw_rect(renderer, &grid_border)

	// Horizontal Payline Marks along row centers
	for row := 0; row < 3; row++ {
		py := ry + int((f64(row) + 0.5) * g.row_h)
		set_render_draw_color(renderer, 255, 50, 50, 120)
		render_draw_point(renderer, rx - 4, py)
		render_draw_point(renderer, rx + rw + 3, py)
	}
}

fn draw_slot_symbol(renderer &Renderer, cx int, cy int, sym SymbolType, tex &Texture) {
	if tex != unsafe { nil } {
		col_idx, row_idx := match sym {
			.cherry { 0, 0 }
			.lemon { 1, 0 }
			.orange { 2, 0 }
			.plum { 3, 0 }
			.bell { 4, 0 }
			.bar_single { 5, 0 }
			.bar_double { 6, 0 }
			.bar_triple { 7, 0 }
			.seven { 0, 1 }
			.diamond { 1, 1 }
			.wild { 2, 1 }
			.scatter { 3, 1 }
		}
		src := Rect{ x: col_idx * 64, y: row_idx * 64, w: 64, h: 64 }
		dst := Rect{ x: cx - 30, y: cy - 30, w: 60, h: 60 }
		render_copy(renderer, tex, &src, &dst)
		return
	}

	match sym {
		.cherry {
			// 16-Bit Twin Glossy Red Cherries with Stems and Leaf
			// Left Cherry with multi-step spherical shading
			draw_filled_circle(renderer, cx - 10, cy + 8, 9, Color{ r: 215, g: 22, b: 35 })
			draw_filled_circle(renderer, cx - 10, cy + 8, 7, Color{ r: 240, g: 45, b: 55 })
			set_render_draw_color(renderer, 255, 200, 210, 255)
			render_draw_point(renderer, cx - 13, cy + 5)
			render_draw_point(renderer, cx - 12, cy + 5)
			render_draw_point(renderer, cx - 13, cy + 6)

			// Right Cherry
			draw_filled_circle(renderer, cx + 8, cy + 10, 9, Color{ r: 215, g: 22, b: 35 })
			draw_filled_circle(renderer, cx + 8, cy + 10, 7, Color{ r: 240, g: 45, b: 55 })
			set_render_draw_color(renderer, 255, 200, 210, 255)
			render_draw_point(renderer, cx + 5, cy + 7)
			render_draw_point(renderer, cx + 6, cy + 7)

			// Green Stems converging at top
			set_render_draw_color(renderer, 50, 165, 45, 255)
			render_draw_line(renderer, cx - 10, cy, cx - 2, cy - 14)
			render_draw_line(renderer, cx + 8, cy + 2, cx - 2, cy - 14)

			// Emerald Leaf
			set_render_draw_color(renderer, 35, 190, 50, 255)
			leaf := Rect{ x: cx - 2, y: cy - 18, w: 10, h: 6 }
			render_fill_rect(renderer, &leaf)
			set_render_draw_color(renderer, 255, 255, 255, 180)
			render_draw_line(renderer, cx - 1, cy - 17, cx + 7, cy - 14)
		}
		.lemon {
			// 16-Bit Shaded Golden Lemon
			draw_filled_circle(renderer, cx, cy, 14, Color{ r: 235, g: 195, b: 20 })
			draw_filled_circle(renderer, cx, cy, 11, Color{ r: 255, g: 225, b: 40 })
			// Lemon Tips
			set_render_draw_color(renderer, 220, 180, 15, 255)
			render_draw_point(renderer, cx - 16, cy)
			render_draw_point(renderer, cx + 16, cy)
			// Specular gloss
			set_render_draw_color(renderer, 255, 255, 255, 220)
			render_draw_line(renderer, cx - 6, cy - 6, cx + 6, cy - 6)
			// Green leaf
			set_render_draw_color(renderer, 40, 160, 45, 255)
			render_draw_line(renderer, cx - 4, cy - 15, cx, cy - 12)
		}
		.orange {
			// 16-Bit Juicy Tangerine Orange
			draw_filled_circle(renderer, cx, cy, 15, Color{ r: 230, g: 105, b: 15 })
			draw_filled_circle(renderer, cx, cy, 12, Color{ r: 255, g: 140, b: 25 })
			set_render_draw_color(renderer, 255, 220, 150, 220)
			render_draw_point(renderer, cx - 5, cy - 5)
			render_draw_point(renderer, cx - 4, cy - 5)
			// Stem & Leaf
			set_render_draw_color(renderer, 35, 140, 40, 255)
			render_draw_line(renderer, cx, cy - 15, cx + 6, cy - 18)
		}
		.plum {
			// 16-Bit Royal Velvet Plum
			draw_filled_circle(renderer, cx, cy, 15, Color{ r: 110, g: 30, b: 145 })
			draw_filled_circle(renderer, cx, cy, 12, Color{ r: 155, g: 45, b: 195 })
			set_render_draw_color(renderer, 230, 170, 255, 220)
			render_draw_point(renderer, cx - 4, cy - 5)
			render_draw_point(renderer, cx - 5, cy - 4)
		}
		.bell {
			// 16-Bit Golden Liberty Bell
			// Upper dome
			draw_filled_circle(renderer, cx, cy - 2, 11, Color{ r: 250, g: 205, b: 35 })
			// Flared Skirt
			skirt := Rect{ x: cx - 15, y: cy + 4, w: 30, h: 7 }
			set_render_draw_color(renderer, 225, 175, 25, 255)
			render_fill_rect(renderer, &skirt)
			set_render_draw_color(renderer, 255, 235, 120, 255)
			render_draw_line(renderer, cx - 14, cy + 4, cx + 14, cy + 4)
			// Base clapper
			draw_filled_circle(renderer, cx, cy + 13, 4, Color{ r: 120, g: 85, b: 15 })
		}
		.bar_single {
			// 16-Bit Brushed Cobalt Single BAR Plaque
			b_rect := Rect{ x: cx - 24, y: cy - 11, w: 48, h: 22 }
			set_render_draw_color(renderer, 25, 70, 175, 255)
			render_fill_rect(renderer, &b_rect)
			set_render_draw_color(renderer, 100, 170, 255, 255)
			render_draw_line(renderer, cx - 24, cy - 11, cx + 23, cy - 11)
			set_render_draw_color(renderer, 10, 30, 80, 255)
			render_draw_line(renderer, cx - 24, cy + 10, cx + 23, cy + 10)
			draw_text_centered(renderer, cx + 1, cy - 3, 'BAR', 1, Color{ r: 10, g: 20, b: 40 })
			draw_text_centered(renderer, cx, cy - 4, 'BAR', 1, Color{ r: 255, g: 255, b: 255 })
		}
		.bar_double {
			// 16-Bit Crimson 2-BAR Plaque with Gold Bezel
			b_rect := Rect{ x: cx - 26, y: cy - 12, w: 52, h: 24 }
			set_render_draw_color(renderer, 195, 25, 35, 255)
			render_fill_rect(renderer, &b_rect)
			set_render_draw_color(renderer, 255, 215, 0, 255)
			render_draw_rect(renderer, &b_rect)
			draw_text_centered(renderer, cx + 1, cy - 3, '2-BAR', 1, Color{ r: 40, g: 10, b: 10 })
			draw_text_centered(renderer, cx, cy - 4, '2-BAR', 1, Color{ r: 255, g: 245, b: 200 })
		}
		.bar_triple {
			// 16-Bit Radiant Gold 3-BAR Plaque
			b_rect := Rect{ x: cx - 28, y: cy - 13, w: 56, h: 26 }
			set_render_draw_color(renderer, 245, 195, 30, 255)
			render_fill_rect(renderer, &b_rect)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_draw_line(renderer, cx - 28, cy - 13, cx + 27, cy - 13)
			set_render_draw_color(renderer, 140, 95, 10, 255)
			render_draw_rect(renderer, &b_rect)
			draw_text_centered(renderer, cx + 1, cy - 3, '3-BAR', 1, Color{ r: 20, g: 15, b: 5 })
			draw_text_centered(renderer, cx, cy - 4, '3-BAR', 1, Color{ r: 255, g: 255, b: 255 })
		}
		.seven {
			// 16-Bit Lucky Flame Red 777
			draw_text_centered(renderer, cx + 2, cy - 13, '7', 3, Color{ r: 60, g: 10, b: 10 })
			draw_text_centered(renderer, cx, cy - 15, '7', 3, Color{ r: 245, g: 30, b: 40 })
		}
		.diamond {
			// 16-Bit Brilliant Faceted Cyan Diamond
			d_size := 16
			set_render_draw_color(renderer, 0, 215, 255, 255)
			for dy := -d_size; dy <= d_size; dy++ {
				span := d_size - int(math.abs(f64(dy)))
				for dx := -span; dx <= span; dx++ {
					render_draw_point(renderer, cx + dx, cy + dy)
				}
			}
			// Facet Lines
			set_render_draw_color(renderer, 255, 255, 255, 240)
			render_draw_line(renderer, cx, cy - d_size, cx, cy + d_size)
			render_draw_line(renderer, cx - d_size, cy, cx + d_size, cy)
			render_draw_point(renderer, cx - 3, cy - 3)
		}
		.wild {
			// 16-Bit Radiant Rainbow Wild Badge
			w_rect := Rect{ x: cx - 26, y: cy - 13, w: 52, h: 26 }
			set_render_draw_color(renderer, 165, 35, 215, 255)
			render_fill_rect(renderer, &w_rect)
			set_render_draw_color(renderer, 255, 225, 40, 255)
			render_draw_rect(renderer, &w_rect)
			draw_text_centered(renderer, cx + 1, cy - 3, 'WILD', 1, Color{ r: 20, g: 5, b: 30 })
			draw_text_centered(renderer, cx, cy - 4, 'WILD', 1, Color{ r: 255, g: 255, b: 255 })
		}
		.scatter {
			// 16-Bit Golden Star Scatter Medallion
			draw_filled_circle(renderer, cx, cy, 16, Color{ r: 255, g: 205, b: 25 })
			draw_circle_ring(renderer, cx, cy, 16, 2, Color{ r: 255, g: 255, b: 255 })
			draw_text_centered(renderer, cx + 1, cy - 3, '★', 1, Color{ r: 40, g: 25, b: 5 })
			draw_text_centered(renderer, cx, cy - 4, '★', 1, Color{ r: 255, g: 255, b: 255 })
		}
	}
}

fn draw_winning_paylines(renderer &Renderer, g &SlotsGame) {
	if g.is_spinning || g.winning_lines.len == 0 {
		return
	}

	rx := g.grid_x
	ry := g.grid_y

	for w in g.winning_lines {
		set_render_draw_color(renderer, 255, 225, 0, 240)

		// Connect cell centers with glowing line
		for i := 0; i < w.positions.len - 1; i++ {
			p1 := w.positions[i]
			p2 := w.positions[i + 1]

			x1 := int(rx + (f64(p1.reel) + 0.5) * g.reel_w)
			y1 := int(ry + (f64(p1.row) + 0.5) * g.row_h)
			x2 := int(rx + (f64(p2.reel) + 0.5) * g.reel_w)
			y2 := int(ry + (f64(p2.row) + 0.5) * g.row_h)

			render_draw_line(renderer, x1, y1, x2, y2)
			render_draw_line(renderer, x1, y1 + 1, x2, y2 + 1)
			render_draw_line(renderer, x1, y1 - 1, x2, y2 - 1)
		}

		// Box highlight on winning cells
		for p in w.positions {
			cx := int(rx + f64(p.reel) * g.reel_w)
			cy := int(ry + f64(p.row) * g.row_h)
			box := Rect{ x: cx + 4, y: cy + 4, w: int(g.reel_w) - 8, h: int(g.row_h) - 8 }
			set_render_draw_color(renderer, 255, 215, 0, 255)
			render_draw_rect(renderer, &box)
		}
	}
}

fn draw_pull_lever(renderer &Renderer, g &SlotsGame) {
	// Mechanical Side Lever on right of machine
	base_x := 700
	pivot_y := 300

	// Housing Base
	set_render_draw_color(renderer, 80, 85, 95, 255)
	b_rect := Rect{ x: base_x, y: pivot_y - 20, w: 22, h: 40 }
	render_fill_rect(renderer, &b_rect)

	// Arm movement based on lever_pos (0.0 straight up, 1.0 down)
	arm_angle := -0.6 + g.lever_pos * 1.4
	arm_len := 90.0
	tip_x := f64(base_x + 10) + math.cos(arm_angle) * arm_len
	tip_y := f64(pivot_y) + math.sin(arm_angle) * arm_len

	// Chrome Shaft
	set_render_draw_color(renderer, 200, 210, 230, 255)
	render_draw_line(renderer, base_x + 10, pivot_y, int(tip_x), int(tip_y))
	render_draw_line(renderer, base_x + 11, pivot_y, int(tip_x) + 1, int(tip_y))

	// Red Grip Knob
	draw_filled_circle(renderer, int(tip_x), int(tip_y), 13, Color{ r: 230, g: 30, b: 40 })
	draw_filled_circle(renderer, int(tip_x) - 3, int(tip_y) - 3, 3, Color{ r: 255, g: 150, b: 160 })
}

fn draw_control_console(renderer &Renderer, g &SlotsGame) {
	panel_x := 120
	panel_y := 430
	panel_w := 560
	panel_h := 130

	// Lower Console Housing
	set_render_draw_color(renderer, 25, 10, 20, 255)
	con_rect := Rect{ x: panel_x, y: panel_y, w: panel_w, h: panel_h }
	render_fill_rect(renderer, &con_rect)

	set_render_draw_color(renderer, 220, 175, 45, 255)
	render_draw_rect(renderer, &con_rect)

	// Meters: Balance, Total Bet, Win
	total_bet := g.bet_per_line * g.active_lines

	// Balance LED Box
	draw_meter_box(renderer, panel_x + 15, panel_y + 12, 120, 36, 'CREDITS', '$${g.balance}', Color{ r: 0, g: 255, b: 180 })
	// Bet LED Box
	draw_meter_box(renderer, panel_x + 145, panel_y + 12, 120, 36, 'TOTAL BET', '$${total_bet}', Color{ r: 255, g: 215, b: 0 })
	// Win LED Box
	draw_meter_box(renderer, panel_x + 275, panel_y + 12, 120, 36, 'WIN PAID', '$${g.last_win}', Color{ r: 255, g: 50, b: 80 })
	// Free Spins Box
	if g.free_spins > 0 {
		draw_meter_box(renderer, panel_x + 405, panel_y + 12, 135, 36, 'FREE SPINS', '${g.free_spins} (3X)', Color{ r: 255, g: 120, b: 240 })
	} else {
		draw_meter_box(renderer, panel_x + 405, panel_y + 12, 135, 36, 'LINES', '${g.active_lines}', Color{ r: 100, g: 200, b: 255 })
	}

	// Buttons Row (Hold / Bet / Lines / Spin)
	btn_y := panel_y + 60
	draw_button(renderer, panel_x + 15, btn_y, 75, 30, 'BET +/-', Color{ r: 40, g: 60, b: 110 })
	draw_button(renderer, panel_x + 95, btn_y, 85, 30, 'LINES +/-', Color{ r: 40, g: 60, b: 110 })
	draw_button(renderer, panel_x + 185, btn_y, 70, 30, '[M] MAX', Color{ r: 160, g: 90, b: 20 })
	draw_button(renderer, panel_x + 260, btn_y, 75, 30, '[TAB] PAY', Color{ r: 70, g: 45, b: 95 })
	draw_button(renderer, panel_x + 340, btn_y, 75, 30, '[T] THEME', Color{ r: 35, g: 95, b: 65 })
	draw_button(renderer, panel_x + 420, btn_y, 125, 30, '[SPACE] SPIN', Color{ r: 200, g: 35, b: 45 })

	// Bottom Hotkeys Guide
	draw_text_centered(renderer, 400, panel_y + 105, '[SPACE] SPIN  |  [1-3] HOLD  |  [UP/DN] BET  |  [L/R] LINES  |  [C] +$$', 1, Color{ r: 180, g: 190, b: 210 })
}

fn draw_meter_box(renderer &Renderer, x int, y int, w int, h int, label string, val string, val_col Color) {
	bg := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, 10, 10, 15, 255)
	render_fill_rect(renderer, &bg)
	set_render_draw_color(renderer, 80, 85, 100, 255)
	render_draw_rect(renderer, &bg)

	draw_text_centered(renderer, x + w / 2, y + 3, label, 1, Color{ r: 160, g: 175, b: 195 })
	draw_text_centered(renderer, x + w / 2, y + 16, val, 1, val_col)
}

fn draw_button(renderer &Renderer, x int, y int, w int, h int, label string, c Color) {
	btn_rect := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, c.r, c.g, c.b, 255)
	render_fill_rect(renderer, &btn_rect)

	set_render_draw_color(renderer, 240, 245, 255, 200)
	render_draw_rect(renderer, &btn_rect)

	draw_text_centered(renderer, x + w / 2, y + 8, label, 1, Color{ r: 255, g: 255, b: 255 })
}

fn draw_coin_particles(renderer &Renderer, g &SlotsGame) {
	for p in g.particles {
		px := int(p.x)
		py := int(p.y)
		r := p.size

		// Rotating Gold Coin Oval
		set_render_draw_color(renderer, 255, 215, 0, 255)
		draw_filled_circle(renderer, px, py, r, Color{ r: 255, g: 215, b: 0 })

		set_render_draw_color(renderer, 220, 160, 20, 255)
		draw_circle_wire(renderer, px, py, r, Color{ r: 220, g: 160, b: 20 })
	}
}

fn draw_celebration_banner(renderer &Renderer, g &SlotsGame) {
	if g.celebration != '' {
		box_w := 500
		box_h := 60
		bx := (800 - box_w) / 2
		by := 250

		set_render_draw_color(renderer, 15, 18, 30, 245)
		b_rect := Rect{ x: bx, y: by, w: box_w, h: box_h }
		render_fill_rect(renderer, &b_rect)

		set_render_draw_color(renderer, 255, 215, 0, 255)
		render_draw_rect(renderer, &b_rect)

		draw_text_centered(renderer, 400, by + 20, g.celebration, 2, Color{ r: 255, g: 220, b: 50 })
	}
}

fn draw_paytable_modal(renderer &Renderer, _ &SlotsGame) {
	// Full Screen Paytable Overlay
	pw := 560
	ph := 440
	px := (800 - pw) / 2
	py := (600 - ph) / 2

	set_render_draw_color(renderer, 10, 14, 25, 250)
	bg_rect := Rect{ x: px, y: py, w: pw, h: ph }
	render_fill_rect(renderer, &bg_rect)

	set_render_draw_color(renderer, 255, 215, 0, 255)
	render_draw_rect(renderer, &bg_rect)

	draw_text_centered(renderer, 400, py + 16, '★ OFFICIAL PAYTABLE & MULTIPLIERS ★', 2, Color{ r: 255, g: 215, b: 0 })

	lines := [
		'DIAMOND ($$):  5x = 1000x  |  4x = 250x  |  3x = 60x  (3-REEL: 500x)',
		'LUCKY 7 (7):   5x = 500x   |  4x = 150x  |  3x = 40x  (3-REEL: 200x)',
		'TRIPLE BAR:    5x = 250x   |  4x = 80x   |  3x = 25x  (3-REEL: 100x)',
		'DOUBLE BAR:    5x = 150x   |  4x = 50x   |  3x = 15x  (3-REEL: 50x)',
		'SINGLE BAR:    5x = 100x   |  4x = 30x   |  3x = 10x  (3-REEL: 30x)',
		'ANY 3 BARS:    15x MULTIPLIER ON 3-REEL CLASSIC',
		'LIBERTY BELL:  5x = 80x    |  4x = 25x   |  3x = 8x   (3-REEL: 25x)',
		'PLUM / ORANGE: 5x = 60x/40x|  4x = 20x/15|  3x = 6x/5x',
		'CHERRY:        3x = 25x    |  2x = 5x    |  1x = 2x',
		'WILD:          SUBSTITUTES FOR ALL SYMBOLS EXCEPT SCATTER (5x = 1500x)',
		'SCATTER:       3+ ANYWHERE TRIGGERS 10-25 FREE SPINS (3X MULTIPLIER)',
	]

	for i, l in lines {
		draw_text(renderer, px + 20, py + 55 + i * 26, l, 1, Color{ r: 230, g: 240, b: 255 })
	}

	draw_text_centered(renderer, 400, py + ph - 25, 'PRESS [TAB] OR [P] TO CLOSE PAYTABLE', 1, Color{ r: 255, g: 220, b: 50 })
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

fn draw_circle_wire(renderer &Renderer, cx int, cy int, r int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	steps := 32
	for i := 0; i < steps; i++ {
		a1 := f64(i) * 2.0 * math.pi / f64(steps)
		a2 := f64(i + 1) * 2.0 * math.pi / f64(steps)
		x1 := int(f64(cx) + math.cos(a1) * f64(r))
		y1 := int(f64(cy) + math.sin(a1) * f64(r))
		x2 := int(f64(cx) + math.cos(a2) * f64(r))
		y2 := int(f64(cy) + math.sin(a2) * f64(r))
		render_draw_line(renderer, x1, y1, x2, y2)
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
