import math
import os



pub struct BowlingTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm BowlingTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/bowling.png',
		'./assets/sprites/bowling.png',
		'../assets/sprites/bowling.png',
		'bowling/assets/sprites/bowling.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('bowling Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn draw_bowling_game(renderer &Renderer, g &BowlingGame, tex &Texture) {
	// Deep retro bowling alley lounge atmosphere
	draw_room_background(renderer)

	draw_lane(renderer, g)
	draw_gutters(renderer, g)
	draw_pin_deck(renderer, g)
	draw_pins(renderer, g, tex)
	draw_ball(renderer, g, tex)
	draw_particles(renderer, g)
	draw_aim_hud(renderer, g)
	draw_pinsetter_sweep(renderer, g)
	draw_overhead_scoreboard(renderer, g)
	draw_celebration_banner(renderer, g)
}

fn draw_room_background(renderer &Renderer) {
	// Retro 90s Bowling Lounge: Dark midnight purple-blue with subtle floor gradient
	for y := 0; y < 680; y += 4 {
		shade := u8(14 + (y * 12) / 680)
		set_render_draw_color(renderer, shade, shade - 2, shade + 8, 255)
		rect := Rect{ x: 0, y: y, w: 800, h: 4 }
		render_fill_rect(renderer, &rect)
	}

	// Side wall carpets with classic arcade geometric pattern
	draw_arcade_carpet(renderer, 0, 100, 130, 580)
	draw_arcade_carpet(renderer, 670, 100, 130, 580)
}

fn draw_arcade_carpet(renderer &Renderer, x int, y int, w int, h int) {
	bg := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, 22, 18, 38, 255)
	render_fill_rect(renderer, &bg)

	// Retro carpet neon triangles and squiggles
	for cy := y + 10; cy < y + h; cy += 40 {
		for cx := x + 15; cx < x + w - 15; cx += 45 {
			// Cyan diamond
			set_render_draw_color(renderer, 45, 180, 220, 120)
			render_draw_line(renderer, cx, cy - 6, cx + 6, cy)
			render_draw_line(renderer, cx + 6, cy, cx, cy + 6)
			render_draw_line(renderer, cx, cy + 6, cx - 6, cy)
			render_draw_line(renderer, cx - 6, cy, cx, cy - 6)

			// Magenta dot
			set_render_draw_color(renderer, 230, 60, 160, 140)
			dot := Rect{ x: cx + 18, y: cy - 2, w: 3, h: 3 }
			render_fill_rect(renderer, &dot)
		}
	}

	// Bevel divider rail
	set_render_draw_color(renderer, 50, 45, 75, 255)
	if x == 0 {
		render_draw_line(renderer, x + w - 1, y, x + w - 1, y + h)
	} else {
		render_draw_line(renderer, x, y, x, y + h)
	}
}

fn draw_lane(renderer &Renderer, g &BowlingGame) {
	lane_w := int(g.lane_right - g.lane_left)
	lane_h := int(g.lane_bottom - g.lane_top)

	// 39 High-Gloss Maple Wood Planks
	plank_count := 39
	plank_w := f64(lane_w) / f64(plank_count)

	for i := 0; i < plank_count; i++ {
		// Alternating rich golden maple wood tones
		is_darker := (i % 3 == 0)
		is_lighter := (i % 3 == 1)

		mut r := if is_lighter { u8(235) } else if is_darker { u8(200) } else { u8(218) }
		mut gr := if is_lighter { u8(185) } else if is_darker { u8(150) } else { u8(168) }
		mut b := if is_lighter { u8(115) } else if is_darker { u8(85) } else { u8(100) }

		px := int(g.lane_left + f64(i) * plank_w)
		pw := int(plank_w) + 1

		// Plank body
		set_render_draw_color(renderer, r, gr, b, 255)
		rect := Rect{
			x: px
			y: int(g.lane_top)
			w: pw
			h: lane_h
		}
		render_fill_rect(renderer, &rect)

		// Plank vertical grain seam highlight & shadow
		set_render_draw_color(renderer, u8(math.max(0, int(r) - 35)), u8(math.max(0, int(gr) - 30)), u8(math.max(0, int(b) - 20)), 200)
		render_draw_line(renderer, px, int(g.lane_top), px, int(g.lane_bottom))

		// Subtle plank wood knots and grain variation
		if i % 4 == 0 {
			set_render_draw_color(renderer, r - 15, gr - 15, b - 10, 80)
			for knot_y := int(g.lane_top) + (i * 37) % 150; knot_y < int(g.lane_bottom); knot_y += 180 {
				render_draw_line(renderer, px + 1, knot_y, px + pw - 2, knot_y + 12)
			}
		}
	}

	// Varnished Oil Pattern Sheen (Translucent gloss with light gradient)
	oil_y := int(g.oil_end_y)
	oil_h := int(g.lane_bottom - g.oil_end_y)

	// Gloss sheen gradient
	for y := oil_y; y < int(g.lane_bottom); y += 6 {
		progress := f64(y - oil_y) / f64(oil_h)
		alpha := u8(20.0 + progress * 25.0)
		set_render_draw_color(renderer, 255, 255, 255, alpha)
		sheen_rect := Rect{
			x: int(g.lane_left)
			y: y
			w: lane_w
			h: 6
		}
		render_fill_rect(renderer, &sheen_rect)
	}

	// Oil Pattern Transition Line with subtle highlight
	set_render_draw_color(renderer, 255, 240, 200, 90)
	render_draw_line(renderer, int(g.lane_left), oil_y, int(g.lane_right), oil_y)
	set_render_draw_color(renderer, 140, 90, 40, 150)
	render_draw_line(renderer, int(g.lane_left), oil_y + 1, int(g.lane_right), oil_y + 1)

	// Aiming Guide Locator Dots (Row of 7 Dots before arrows)
	dots_y := int(g.lane_bottom - 130.0)
	for i := 1; i <= 7; i++ {
		dx := int(g.lane_left + f64(i) * (f64(lane_w) / 8.0))
		set_render_draw_color(renderer, 60, 30, 10, 255)
		dot_rect := Rect{ x: dx - 2, y: dots_y - 2, w: 4, h: 4 }
		render_fill_rect(renderer, &dot_rect)
		set_render_draw_color(renderer, 120, 70, 30, 255)
		render_draw_point(renderer, dx - 1, dots_y - 1)
	}

	// 16-Bit Aiming Guide Arrows (Row of 7 Chevron Arrows)
	arrow_y := int(g.lane_bottom - 220.0)
	for i := 1; i <= 7; i++ {
		ax := int(g.lane_left + f64(i) * (f64(lane_w) / 8.0))
		// Outer arrow dark mahogany border
		for dy := 0; dy < 14; dy++ {
			span := dy / 2
			set_render_draw_color(renderer, 55, 28, 12, 255)
			line := Rect{
				x: ax - span - 1
				y: arrow_y + dy
				w: (span * 2) + 3
				h: 1
			}
			render_fill_rect(renderer, &line)
		}
		// Inner arrow warm amber inlay
		for dy := 2; dy < 12; dy++ {
			span := (dy - 2) / 2
			set_render_draw_color(renderer, 160, 85, 30, 255)
			line := Rect{
				x: ax - span
				y: arrow_y + dy
				w: span * 2 + 1
				h: 1
			}
			render_fill_rect(renderer, &line)
		}
	}

	// Strike Pocket Target Indicators (1-3 and 1-2 pocket guide crosshairs)
	pocket_y := int(240.0)
	// Righty 1-3 Pocket (407px)
	set_render_draw_color(renderer, 255, 200, 50, 220)
	render_draw_line(renderer, 407, pocket_y - 8, 407, pocket_y + 8)
	render_draw_line(renderer, 403, pocket_y, 411, pocket_y)
	// Lefty 1-2 Pocket (393px)
	set_render_draw_color(renderer, 255, 200, 50, 140)
	render_draw_line(renderer, 393, pocket_y - 8, 393, pocket_y + 8)
	render_draw_line(renderer, 389, pocket_y, 397, pocket_y)

	// Foul Line with Beveled Edge
	foul_y := int(g.lane_bottom - 10.0)
	set_render_draw_color(renderer, 220, 30, 30, 255)
	foul_rect := Rect{
		x: int(g.lane_left)
		y: foul_y
		w: lane_w
		h: 5
	}
	render_fill_rect(renderer, &foul_rect)
	// Foul line gold border
	set_render_draw_color(renderer, 255, 215, 0, 255)
	render_draw_line(renderer, int(g.lane_left), foul_y, int(g.lane_right), foul_y)
	set_render_draw_color(renderer, 140, 10, 10, 255)
	render_draw_line(renderer, int(g.lane_left), foul_y + 5, int(g.lane_right), foul_y + 5)
}

fn draw_gutters(renderer &Renderer, g &BowlingGame) {
	gw := 35

	// Left Gutter - Deep curved channel with shadow gradient
	for x := 0; x < gw; x++ {
		// Curved drop depth: darker in center, highlighted outer edge
		norm := f64(x) / f64(gw)
		depth := math.sin(norm * math.pi)
		base_gray := u8(22.0 - depth * 14.0)

		set_render_draw_color(renderer, base_gray, base_gray + 2, base_gray + 6, 255)
		render_draw_line(renderer, int(g.lane_left - f64(gw) + f64(x)), int(g.lane_top), int(g.lane_left - f64(gw) + f64(x)), int(g.lane_bottom))
	}
	// Left Gutter outer rail highlight
	set_render_draw_color(renderer, 70, 75, 95, 255)
	render_draw_line(renderer, int(g.lane_left - f64(gw)), int(g.lane_top), int(g.lane_left - f64(gw)), int(g.lane_bottom))
	// Left Gutter lane seam shadow
	set_render_draw_color(renderer, 10, 10, 14, 255)
	render_draw_line(renderer, int(g.lane_left - 1), int(g.lane_top), int(g.lane_left - 1), int(g.lane_bottom))

	// Right Gutter - Deep curved channel with shadow gradient
	for x := 0; x < gw; x++ {
		norm := f64(x) / f64(gw)
		depth := math.sin(norm * math.pi)
		base_gray := u8(22.0 - depth * 14.0)

		set_render_draw_color(renderer, base_gray, base_gray + 2, base_gray + 6, 255)
		render_draw_line(renderer, int(g.lane_right + f64(x)), int(g.lane_top), int(g.lane_right + f64(x)), int(g.lane_bottom))
	}
	// Right Gutter outer rail highlight
	set_render_draw_color(renderer, 70, 75, 95, 255)
	render_draw_line(renderer, int(g.lane_right + f64(gw) - 1), int(g.lane_top), int(g.lane_right + f64(gw) - 1), int(g.lane_bottom))
	// Right Gutter lane seam shadow
	set_render_draw_color(renderer, 10, 10, 14, 255)
	render_draw_line(renderer, int(g.lane_right), int(g.lane_top), int(g.lane_right), int(g.lane_bottom))
}

fn draw_pin_deck(renderer &Renderer, g &BowlingGame) {
	// Pin Deck Dark Back Pit & LED backlight
	pit_w := int(g.lane_right - g.lane_left + 70.0)
	pit_x := int(g.lane_left - 35.0)
	pit_y := int(g.lane_top - 30.0)
	pit_h := 30

	// Dark pit drop hole
	set_render_draw_color(renderer, 8, 8, 12, 255)
	pit_rect := Rect{ x: pit_x, y: pit_y, w: pit_w, h: pit_h }
	render_fill_rect(renderer, &pit_rect)

	// LED Backlight strip illuminating pin deck from behind
	set_render_draw_color(renderer, 0, 230, 255, 180)
	led_rect := Rect{ x: int(g.lane_left), y: int(g.lane_top) - 3, w: int(g.lane_right - g.lane_left), h: 3 }
	render_fill_rect(renderer, &led_rect)

	// Pit cushion back wall with rubber texture
	set_render_draw_color(renderer, 28, 30, 36, 255)
	cushion_rect := Rect{ x: pit_x, y: pit_y, w: pit_w, h: 10 }
	render_fill_rect(renderer, &cushion_rect)
}

fn draw_pins(renderer &Renderer, g &BowlingGame, tex &Texture) {
	for pin in g.pins {
		if pin.x < 0.0 { continue }

		px := int(pin.x)
		py := int(pin.y)

		if tex != unsafe { nil } {
			if pin.standing {
				col_x := if math.abs(pin.tilt) > 0.3 { 128 } else if math.abs(pin.tilt) > 0.08 { 64 } else { 0 }
				src := Rect{ x: col_x, y: 64, w: 64, h: 64 }
				dst := Rect{ x: px - 12, y: py - 20, w: 24, h: 40 }
				render_copy(renderer, tex, &src, &dst)
			} else {
				src := Rect{ x: 192, y: 64, w: 64, h: 64 }
				dst := Rect{ x: px - 20, y: py - 10, w: 40, h: 20 }
				render_copy(renderer, tex, &src, &dst)
			}
			continue
		}

		if pin.standing {
			// Wobble displacement
			tilt_offset_x := int(math.sin(pin.tilt) * 12.0)
			cx := px + tilt_offset_x

			// 16-Bit Standing Bowling Pin (Contoured with Neck, Belly & Twin Stripes)

			// Drop shadow on pin deck
			set_render_draw_color(renderer, 0, 0, 0, 110)
			shadow_rect := Rect{ x: cx - 9, y: py + 12, w: 18, h: 6 }
			render_fill_rect(renderer, &shadow_rect)

			// Pin layers (Top-down 16-bit contour slices)
			// Head
			draw_pin_slice(renderer, cx, py - 18, 6, 4, Color{ r: 250, g: 250, b: 255 })
			// Neck
			draw_pin_slice(renderer, cx, py - 14, 4, 3, Color{ r: 245, g: 245, b: 250 })
			// Red Stripe 1
			draw_pin_slice(renderer, cx, py - 11, 6, 3, Color{ r: 225, g: 30, b: 40 })
			// White spacer
			draw_pin_slice(renderer, cx, py - 8, 8, 2, Color{ r: 245, g: 245, b: 250 })
			// Red Stripe 2
			draw_pin_slice(renderer, cx, py - 6, 10, 3, Color{ r: 225, g: 30, b: 40 })
			// Belly (widest part)
			draw_pin_slice(renderer, cx, py - 3, 14, 8, Color{ r: 255, g: 255, b: 255 })
			// Base taper
			draw_pin_slice(renderer, cx, py + 5, 11, 8, Color{ r: 235, g: 235, b: 245 })
			// Base rim
			draw_pin_slice(renderer, cx, py + 13, 9, 3, Color{ r: 200, g: 205, b: 215 })

			// Specular glossy highlight along left side
			set_render_draw_color(renderer, 255, 255, 255, 220)
			render_draw_line(renderer, cx - 4, py - 2, cx - 3, py + 6)
			render_draw_point(renderer, cx - 1, py - 17)

			// Right side 3D shading contour
			set_render_draw_color(renderer, 160, 165, 185, 180)
			render_draw_line(renderer, cx + 6, py - 1, cx + 5, py + 7)
		} else {
			// Knocked/Fallen Tilted Pin on Deck
			// Shadow
			set_render_draw_color(renderer, 0, 0, 0, 90)
			f_shadow := Rect{ x: px - 14, y: py - 5, w: 28, h: 14 }
			render_fill_rect(renderer, &f_shadow)

			// Fallen horizontal body
			set_render_draw_color(renderer, 220, 225, 235, 255)
			body := Rect{ x: px - 15, y: py - 6, w: 30, h: 12 }
			render_fill_rect(renderer, &body)

			// Red Stripes
			set_render_draw_color(renderer, 210, 35, 45, 255)
			s1 := Rect{ x: px - 8, y: py - 6, w: 3, h: 12 }
			s2 := Rect{ x: px - 3, y: py - 6, w: 3, h: 12 }
			render_fill_rect(renderer, &s1)
			render_fill_rect(renderer, &s2)

			// Shading highlight
			set_render_draw_color(renderer, 255, 255, 255, 200)
			render_draw_line(renderer, px - 13, py - 5, px + 13, py - 5)
			set_render_draw_color(renderer, 150, 155, 170, 255)
			render_draw_line(renderer, px - 15, py + 5, px + 14, py + 5)
		}
	}
}

fn draw_pin_slice(renderer &Renderer, cx int, y int, w int, h int, c Color) {
	rect := Rect{
		x: cx - w / 2
		y: y
		w: w
		h: h
	}
	set_render_draw_color(renderer, c.r, c.g, c.b, 255)
	render_fill_rect(renderer, &rect)
}

fn draw_ball(renderer &Renderer, g &BowlingGame, tex &Texture) {
	bx := int(g.ball.x)
	by := int(g.ball.y)
	r := int(g.ball.radius)

	if tex != unsafe { nil } {
		col_x := if g.current_player == 0 { 64 } else { 0 }
		src := Rect{ x: col_x, y: 0, w: 64, h: 64 }
		dst := Rect{ x: bx - r, y: by - r, w: r * 2, h: r * 2 }
		render_copy(renderer, tex, &src, &dst)
		return
	}

	// Dynamic Contact Drop Shadow (Soft multi-layer)
	set_render_draw_color(renderer, 0, 0, 0, 70)
	shadow_outer := Rect{ x: bx - r + 3, y: by - r + 6, w: r * 2, h: r * 2 }
	render_fill_rect(renderer, &shadow_outer)
	set_render_draw_color(renderer, 0, 0, 0, 120)
	shadow_inner := Rect{ x: bx - r + 4, y: by - r + 7, w: r * 2 - 4, h: r * 2 - 4 }
	render_fill_rect(renderer, &shadow_inner)

	// 16-Bit Radial Spherical Bowling Ball Shading
	// Player 1: Deep Sapphire Cobalt, Player 2: Crimson Ruby / Flame
	base_r := if g.current_player == 0 { 20.0 } else { 190.0 }
	base_g := if g.current_player == 0 { 60.0 } else { 30.0 }
	base_b := if g.current_player == 0 { 210.0 } else { 45.0 }

	for dy := -r; dy <= r; dy++ {
		for dx := -r; dx <= r; dx++ {
			dist_sq := dx * dx + dy * dy
			if dist_sq <= r * r {
				// Distance to light source (top-left offset)
				lx := dx + (r / 3)
				ly := dy + (r / 3)
				light_dist := math.sqrt(f64(lx * lx + ly * ly))
				norm_light := math.max(0.0, 1.0 - (light_dist / f64(r * 2)))

				// 16-bit stepped palette shading
				shade_step := int(norm_light * 6.0) // 0..6 bands
				factor := 0.4 + (f64(shade_step) / 6.0) * 0.9

				mut pr := u8(math.min(255.0, base_r * factor))
				mut pg := u8(math.min(255.0, base_g * factor))
				mut pb := u8(math.min(255.0, base_b * factor))

				// Specular hotspot glint
				if lx * lx + ly * ly <= (r * r) / 10 {
					pr = 255
					pg = 255
					pb = 255
				}

				set_render_draw_color(renderer, pr, pg, pb, 255)
				render_draw_point(renderer, bx + dx, by + dy)
			}
		}
	}

	// 16-Bit 3 Finger Grip Holes (with inner shadow depth)
	// Rotate slightly based on ball travel
	spin_angle := (g.ball.y * 0.08) + (g.hook * 2.0)
	cos_s := math.cos(spin_angle)
	sin_s := math.sin(spin_angle)

	h1_rx := -4.0 * cos_s - (-7.0) * sin_s
	h1_ry := -4.0 * sin_s + (-7.0) * cos_s

	h2_rx := 4.0 * cos_s - (-7.0) * sin_s
	h2_ry := 4.0 * sin_s + (-7.0) * cos_s

	h3_rx := 0.0 * cos_s - (1.0) * sin_s
	h3_ry := 0.0 * sin_s + (1.0) * cos_s

	draw_finger_hole(renderer, bx + int(h1_rx), by + int(h1_ry), 2)
	draw_finger_hole(renderer, bx + int(h2_rx), by + int(h2_ry), 2)
	draw_finger_hole(renderer, bx + int(h3_rx), by + int(h3_ry), 3)
}

fn draw_finger_hole(renderer &Renderer, x int, y int, radius int) {
	// Deep hole interior
	set_render_draw_color(renderer, 8, 10, 15, 255)
	for dy := -radius; dy <= radius; dy++ {
		for dx := -radius; dx <= radius; dx++ {
			if dx * dx + dy * dy <= radius * radius {
				render_draw_point(renderer, x + dx, y + dy)
			}
		}
	}
	// Hole rim bevel highlight
	set_render_draw_color(renderer, 90, 110, 150, 180)
	render_draw_point(renderer, x - 1, y - radius)
}

fn draw_particles(renderer &Renderer, g &BowlingGame) {
	for p in g.particles {
		alpha := u8(255.0 * (p.life / p.max_life))
		// Sparkle core
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		rect := Rect{
			x: int(p.x) - p.size / 2
			y: int(p.y) - p.size / 2
			w: p.size
			h: p.size
		}
		render_fill_rect(renderer, &rect)

		// 16-bit star cross sparkle on large particles
		if p.size >= 4 && alpha > 150 {
			set_render_draw_color(renderer, 255, 255, 255, alpha)
			render_draw_line(renderer, int(p.x) - 2, int(p.y), int(p.x) + 2, int(p.y))
			render_draw_line(renderer, int(p.x), int(p.y) - 2, int(p.x), int(p.y) + 2)
		}
	}
}

fn draw_aim_hud(renderer &Renderer, g &BowlingGame) {
	if g.phase == .position || g.phase == .angle || g.phase == .power {
		bx := int(g.aim_x)
		by := int(g.lane_bottom - 40.0)

		// 16-Bit Neon Dotted Trajectory Line
		arrow_len := 150.0
		end_x := f64(bx) + math.sin(g.aim_angle) * arrow_len
		end_y := f64(by) - math.cos(g.aim_angle) * arrow_len

		// Glowing trajectory guide
		dots := 12
		for i := 0; i <= dots; i++ {
			t := f64(i) / f64(dots)
			tx := int(f64(bx) + (end_x - f64(bx)) * t)
			ty := int(f64(by) + (end_y - f64(by)) * t)

			// Glow dot
			set_render_draw_color(renderer, 255, 220, 50, 240)
			dot := Rect{ x: tx - 1, y: ty - 1, w: 3, h: 3 }
			render_fill_rect(renderer, &dot)
		}

		// Arcade Controls & Power Gauges Panel (Bottom Right)
		panel_x := 560
		panel_y := 410
		panel_w := 220
		panel_h := 170

		// Beveled Arcade Metal HUD Box
		draw_arcade_box(renderer, panel_x, panel_y, panel_w, panel_h, 'LAUNCH CONTROLS')

		// Power Meter
		bar_x := panel_x + 15
		bar_y := panel_y + 40
		bar_w := 190
		bar_h := 18

		draw_text(renderer, bar_x, bar_y - 14, 'POWER (SPACE)', 1, Color{ r: 240, g: 245, b: 255 })
		bg_rect := Rect{ x: bar_x, y: bar_y, w: bar_w, h: bar_h }
		set_render_draw_color(renderer, 20, 22, 32, 255)
		render_fill_rect(renderer, &bg_rect)

		// Multi-tone Power Bar
		fill_w := int(f64(bar_w) * g.power)
		for px := 0; px < fill_w; px++ {
			progress := f64(px) / f64(bar_w)
			col := if progress > 0.8 {
				Color{ r: 255, g: 50, b: 60 }
			} else if progress > 0.5 {
				Color{ r: 255, g: 210, b: 30 }
			} else {
				Color{ r: 40, g: 220, b: 120 }
			}
			set_render_draw_color(renderer, col.r, col.g, col.b, 255)
			render_draw_line(renderer, bar_x + px, bar_y + 1, bar_x + px, bar_y + bar_h - 2)
		}
		// Meter frame
		set_render_draw_color(renderer, 120, 130, 160, 255)
		render_draw_rect(renderer, &bg_rect)

		// Hook / Spin Meter
		hook_y := bar_y + 44
		draw_text(renderer, bar_x, hook_y - 14, 'HOOK SPIN (Z / X)', 1, Color{ r: 240, g: 245, b: 255 })
		hook_bg := Rect{ x: bar_x, y: hook_y, w: bar_w, h: bar_h }
		set_render_draw_color(renderer, 20, 22, 32, 255)
		render_fill_rect(renderer, &hook_bg)

		hook_mid := bar_x + bar_w / 2
		hook_fill_w := int(g.hook * f64(bar_w / 2))
		hook_rect := if hook_fill_w >= 0 {
			Rect{ x: hook_mid, y: hook_y, w: hook_fill_w, h: bar_h }
		} else {
			Rect{ x: hook_mid + hook_fill_w, y: hook_y, w: -hook_fill_w, h: bar_h }
		}
		set_render_draw_color(renderer, 0, 200, 255, 255)
		render_fill_rect(renderer, &hook_rect)

		// Center zero line
		set_render_draw_color(renderer, 255, 255, 255, 220)
		render_draw_line(renderer, hook_mid, hook_y, hook_mid, hook_y + bar_h)
		set_render_draw_color(renderer, 120, 130, 160, 255)
		render_draw_rect(renderer, &hook_bg)

		// Step Instructions
		status_text := match g.phase {
			.position { 'STEP 1: [A/D] STANCE -> [SPACE]' }
			.angle    { 'STEP 2: [SPACE] LOCK ANGLE' }
			.power    { 'STEP 3: [SPACE] BOWL / [Z,X] HOOK' }
			else      { '' }
		}
		draw_text_centered(renderer, panel_x + panel_w / 2, panel_y + panel_h - 22, status_text, 1, Color{ r: 255, g: 220, b: 80 })
	}
}

fn draw_pinsetter_sweep(renderer &Renderer, g &BowlingGame) {
	if g.phase == .sweep {
		sy := int(g.sweep_y)
		lane_w := int(g.lane_right - g.lane_left)
		lx := int(g.lane_left)

		// 16-Bit Mechanical Sweeper Arm
		sweep_rect := Rect{
			x: lx
			y: sy
			w: lane_w
			h: 18
		}
		// Dark metallic arm body
		set_render_draw_color(renderer, 45, 50, 65, 255)
		render_fill_rect(renderer, &sweep_rect)

		// Yellow & Black Industrial Hazard Caution Stripes
		stripe_w := 14
		for st := 0; st < lane_w; st += stripe_w * 2 {
			set_render_draw_color(renderer, 255, 210, 0, 255)
			hazard := Rect{ x: lx + st, y: sy + 2, w: stripe_w, h: 14 }
			render_fill_rect(renderer, &hazard)
		}

		// Top & Bottom metallic highlights
		set_render_draw_color(renderer, 200, 210, 235, 255)
		render_draw_line(renderer, lx, sy, lx + lane_w, sy)
		set_render_draw_color(renderer, 20, 25, 35, 255)
		render_draw_line(renderer, lx, sy + 17, lx + lane_w, sy + 17)

		draw_text_centered(renderer, 400, sy + 4, 'PINSETTER SWEEP', 1, Color{ r: 0, g: 0, b: 0 })
	}
}

fn draw_overhead_scoreboard(renderer &Renderer, g &BowlingGame) {
	// Neo-Geo Arcade Overhead CRT Scoreboard Panel
	panel_w := 780
	panel_h := 84
	px := (800 - panel_w) / 2
	py := 6

	// CRT Monitor Bevelled Casing
	draw_arcade_box(renderer, px, py, panel_w, panel_h, '')

	p := g.players[g.current_player]

	// Player Name & Mode Header with neon glow
	mode_name := match g.mode {
		.solo  { 'SOLO ARCADE BOWLING' }
		.vs_ai { 'VS CPU MASTER' }
		.vs_2p { '2P LOCAL SHOWDOWN' }
	}
	draw_text(renderer, px + 14, py + 8, '${p.name.to_upper()}', 1, Color{ r: 255, g: 215, b: 0 })
	draw_text(renderer, px + 120, py + 8, '| ${mode_name}', 1, Color{ r: 160, g: 190, b: 230 })
	draw_text(renderer, px + panel_w - 190, py + 8, 'TOTAL SCORE: ${p.total_score}', 1, Color{ r: 0, g: 255, b: 180 })

	// Frame Scorecards 1-10
	frame_w := 54
	frame_h := 46
	start_x := px + 120

	for i := 0; i < 10; i++ {
		fx := start_x + i * frame_w
		fy := py + 26
		is_cur := (i == p.current_frame)

		// Frame box background
		bg_color := if is_cur { Color{ r: 35, g: 45, b: 70 } } else { Color{ r: 16, g: 20, b: 32 } }
		f_bg := Rect{ x: fx, y: fy, w: frame_w - 2, h: frame_h }
		set_render_draw_color(renderer, bg_color.r, bg_color.g, bg_color.b, 255)
		render_fill_rect(renderer, &f_bg)

		// Frame border (glowing gold for current frame)
		cr := if is_cur { u8(255) } else { u8(60) }
		cg := if is_cur { u8(215) } else { u8(75) }
		cb := if is_cur { u8(40) } else { u8(110) }
		set_render_draw_color(renderer, cr, cg, cb, 255)
		render_draw_rect(renderer, &f_bg)

		// Frame Number Header
		draw_text_centered(renderer, fx + (frame_w - 2) / 2, fy + 2, '${i + 1}', 1, Color{ r: 160, g: 180, b: 210 })

		// Roll Marks
		f_score := p.frames[i]
		if i < 9 {
			// Sub-box for roll 2
			sub_rect := Rect{ x: fx + frame_w - 20, y: fy + 12, w: 18, h: 16 }
			set_render_draw_color(renderer, 30, 36, 52, 255)
			render_fill_rect(renderer, &sub_rect)
			set_render_draw_color(renderer, 70, 80, 110, 255)
			render_draw_rect(renderer, &sub_rect)

			if f_score.is_strike {
				draw_text_centered(renderer, fx + frame_w - 11, fy + 15, 'X', 1, Color{ r: 255, g: 60, b: 60 })
			} else {
				if f_score.roll1 != -1 {
					r1_str := if f_score.roll1 == 0 { '-' } else { '${f_score.roll1}' }
					draw_text(renderer, fx + 8, fy + 15, r1_str, 1, Color{ r: 250, g: 250, b: 255 })
				}
				if f_score.is_spare {
					draw_text_centered(renderer, fx + frame_w - 11, fy + 15, '/', 1, Color{ r: 0, g: 255, b: 180 })
				} else if f_score.roll2 != -1 {
					r2_str := if f_score.roll2 == 0 { '-' } else { '${f_score.roll2}' }
					draw_text_centered(renderer, fx + frame_w - 11, fy + 15, r2_str, 1, Color{ r: 250, g: 250, b: 255 })
				}
			}
		} else {
			// 10th frame (3 sub-boxes)
			if f_score.roll1 != -1 {
				r1_str := if f_score.is_strike { 'X' } else if f_score.roll1 == 0 { '-' } else { '${f_score.roll1}' }
				draw_text(renderer, fx + 4, fy + 15, r1_str, 1, Color{ r: 250, g: 250, b: 255 })
			}
			if f_score.roll2 != -1 {
				r2_str := if f_score.roll2 == 10 { 'X' } else if f_score.is_spare { '/' } else if f_score.roll2 == 0 { '-' } else { '${f_score.roll2}' }
				draw_text(renderer, fx + 20, fy + 15, r2_str, 1, Color{ r: 250, g: 250, b: 255 })
			}
			if f_score.roll3 != -1 {
				r3_str := if f_score.roll3 == 10 { 'X' } else if f_score.roll3 == 0 { '-' } else { '${f_score.roll3}' }
				draw_text(renderer, fx + 36, fy + 15, r3_str, 1, Color{ r: 250, g: 250, b: 255 })
			}
		}

		// Cumulative Score with Glowing Mint Digits
		if f_score.cumulative != -1 {
			cum_str := '${f_score.cumulative}'
			draw_text_centered(renderer, fx + (frame_w - 2) / 2, fy + 31, cum_str, 1, Color{ r: 0, g: 255, b: 210 })
		}
	}
}

fn draw_celebration_banner(renderer &Renderer, g &BowlingGame) {
	if g.celebration != '' {
		box_w := 460
		box_h := 64
		bx := (800 - box_w) / 2
		by := 270

		// Glowing Arcade Pop Banner
		draw_arcade_box(renderer, bx, by, box_w, box_h, '')

		// Gold inner border
		set_render_draw_color(renderer, 255, 215, 0, 255)
		inner := Rect{ x: bx + 4, y: by + 4, w: box_w - 8, h: box_h - 8 }
		render_draw_rect(renderer, &inner)

		// Text Shadow + Glowing Text
		draw_text_centered(renderer, 402, by + 24, g.celebration, 2, Color{ r: 40, g: 20, b: 0 })
		draw_text_centered(renderer, 400, by + 22, g.celebration, 2, Color{ r: 255, g: 230, b: 60 })
	}
}

fn draw_arcade_box(renderer &Renderer, x int, y int, w int, h int, title string) {
	// Deep arcade chassis background
	bg := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, 12, 15, 26, 245)
	render_fill_rect(renderer, &bg)

	// Metallic bevel highlights
	set_render_draw_color(renderer, 80, 95, 130, 255)
	render_draw_line(renderer, x, y, x + w, y)
	render_draw_line(renderer, x, y, x, y + h)

	set_render_draw_color(renderer, 10, 12, 18, 255)
	render_draw_line(renderer, x, y + h - 1, x + w, y + h - 1)
	render_draw_line(renderer, x + w - 1, y, x + w - 1, y + h)

	// Cyan neon accent rim
	set_render_draw_color(renderer, 0, 180, 255, 200)
	inner_rim := Rect{ x: x + 2, y: y + 2, w: w - 4, h: h - 4 }
	render_draw_rect(renderer, &inner_rim)

	// Title header
	if title != '' {
		draw_text(renderer, x + 12, y + 8, title, 1, Color{ r: 0, g: 220, b: 255 })
	}
}
