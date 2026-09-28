module main

import math


pub fn render_etch_game(renderer &Renderer, mut g EtchGame, win_w int, win_h int, sound_enabled bool) {
	// Apply shake screen offset if active
	sox := int(g.shake_offset_x)
	soy := int(g.shake_offset_y)

	// 1. Clear background (Workspace table texture)
	set_render_draw_color(renderer, 24, 26, 32, 255)
	clear_rect := Rect{0, 0, win_w, win_h}
	render_fill_rect(renderer, &clear_rect)

	// Draw subtle tabletop grid
	set_render_draw_color(renderer, 32, 35, 44, 255)
	for x := 0; x < win_w; x += 40 {
		render_draw_line(renderer, x, 0, x, win_h)
	}
	for y := 0; y < win_h; y += 40 {
		render_draw_line(renderer, 0, y, win_w, y)
	}

	// 2. Red Plastic Outer Chassis Bezel
	chassis_x := 40 + sox
	chassis_y := 20 + soy
	chassis_w := win_w - 80
	chassis_h := win_h - 40

	// Chassis shadow
	set_render_draw_color(renderer, 10, 10, 14, 180)
	chassis_shadow := Rect{chassis_x + 8, chassis_y + 8, chassis_w, chassis_h}
	render_fill_rect(renderer, &chassis_shadow)

	// Outer Red Frame
	set_render_draw_color(renderer, 198, 32, 38, 255)
	frame_rect := Rect{chassis_x, chassis_y, chassis_w, chassis_h}
	render_fill_rect(renderer, &frame_rect)

	// Top/Left highlight bevel
	set_render_draw_color(renderer, 235, 60, 65, 255)
	for i in 0 .. 5 {
		render_draw_line(renderer, chassis_x + i, chassis_y + i, chassis_x + chassis_w - i, chassis_y + i)
		render_draw_line(renderer, chassis_x + i, chassis_y + i, chassis_x + i, chassis_y + chassis_h - i)
	}

	// Bottom/Right dark bevel
	set_render_draw_color(renderer, 138, 18, 22, 255)
	for i in 0 .. 5 {
		render_draw_line(renderer, chassis_x + i, chassis_y + chassis_h - i, chassis_x + chassis_w - i, chassis_y + chassis_h - i)
		render_draw_line(renderer, chassis_x + chassis_w - i, chassis_y + i, chassis_x + chassis_w - i, chassis_y + chassis_h - i)
	}

	// 3. Iconic Gold Embossed Header Logo
	gold_light := Color{255, 224, 102, 255}
	gold_shadow := Color{180, 130, 20, 255}
	draw_text_centered(renderer, win_w / 2 + 1 + sox, chassis_y + 19 + soy, 'MAGIC  Etch A Sketch  SCREEN', 2, gold_shadow)
	draw_text_centered(renderer, win_w / 2 + sox, chassis_y + 18 + soy, 'MAGIC  Etch A Sketch  SCREEN', 2, gold_light)

	// Sound / Mute Toggle Badge (Top Right)
	sound_btn_x := chassis_x + chassis_w - 150
	sound_btn_y := chassis_y + 12
	sound_btn_w := 135
	sound_btn_h := 24

	if sound_enabled {
		set_render_draw_color(renderer, 50, 140, 60, 220)
		btn_bg := Rect{sound_btn_x, sound_btn_y, sound_btn_w, sound_btn_h}
		render_fill_rect(renderer, &btn_bg)
		set_render_draw_color(renderer, 90, 200, 100, 255)
		render_draw_rect(renderer, &btn_bg)
		draw_text_centered(renderer, sound_btn_x + sound_btn_w / 2, sound_btn_y + 8, 'SOUND: ON [M]', 1, Color{255, 255, 255, 255})
	} else {
		set_render_draw_color(renderer, 90, 30, 35, 220)
		btn_bg := Rect{sound_btn_x, sound_btn_y, sound_btn_w, sound_btn_h}
		render_fill_rect(renderer, &btn_bg)
		set_render_draw_color(renderer, 180, 70, 75, 255)
		render_draw_rect(renderer, &btn_bg)
		draw_text_centered(renderer, sound_btn_x + sound_btn_w / 2, sound_btn_y + 8, 'MUTED [M]', 1, Color{240, 160, 160, 255})
	}

	// 4. Beveled Inner Screen Recess Rim
	sx := g.screen_x + sox
	sy := g.screen_y + soy
	sw := g.screen_w
	sh := g.screen_h

	// Dark recessed border
	set_render_draw_color(renderer, 70, 75, 85, 255)
	border_rect := Rect{sx - 8, sy - 8, sw + 16, sh + 16}
	render_fill_rect(renderer, &border_rect)

	set_render_draw_color(renderer, 40, 42, 50, 255)
	recess_rect := Rect{sx - 4, sy - 4, sw + 8, sh + 8}
	render_fill_rect(renderer, &recess_rect)

	// 5. Screen Glass Surface (Silver aluminum or Theme)
	bg_col := g.get_screen_bg_color()
	set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, bg_col.a)
	screen_rect := Rect{sx, sy, sw, sh}
	render_fill_rect(renderer, &screen_rect)

	// Screen powder texture sheen
	if g.theme == .classic_silver {
		set_render_draw_color(renderer, 220, 222, 226, 80)
		for dy in 0 .. sh {
			if dy % 4 == 0 {
				render_draw_line(renderer, sx, sy + dy, sx + sw, sy + dy)
			}
		}
	}

	// 6. Draw Stencil Blueprint Overlay if active
	if g.tool_mode == .stencil && g.stencils.len > 0 {
		st := g.stencils[g.current_stencil]
		stencil_col := Color{100, 140, 200, 160}
		mut last_x := 0
		mut last_y := 0

		for i, p in st.points {
			px := sx + int(p.x * f64(sw))
			py := sy + int(p.y * f64(sh))
			if p.start || i == 0 {
				last_x = px
				last_y = py
			} else {
				draw_thick_line(renderer, last_x, last_y, px, py, 2, stencil_col)
				last_x = px
				last_y = py
			}
		}
	}

	// 7. Draw User's Continuous Scratch Line Segments
	if g.points.len > 1 {
		mut last_x := sx + int(g.points[0].x)
		mut last_y := sy + int(g.points[0].y)

		for i in 1 .. g.points.len {
			pt := g.points[i]
			cur_x := sx + int(pt.x)
			cur_y := sy + int(pt.y)

			if pt.start {
				last_x = cur_x
				last_y = cur_y
				continue
			}

			// Draw solid scratch line
			draw_thick_line(renderer, last_x, last_y, cur_x, cur_y, 2, pt.col)

			last_x = cur_x
			last_y = cur_y
		}
	}

	// 8. Active Stylus Tip Cursor Indicator
	pen_px := sx + int(g.pen_x)
	pen_py := sy + int(g.pen_y)
	stylus_col := if g.theme == .classic_silver { Color{25, 25, 28, 255} } else { Color{255, 255, 255, 255} }
	draw_filled_circle(renderer, pen_px, pen_py, 3, stylus_col)
	draw_circle_outline(renderer, pen_px, pen_py, 5, Color{120, 120, 120, 200})

	// 9. Powder Shake Erase Swirling Particles
	if g.is_shaking {
		for p in g.particles {
			p_col := Color{185, 188, 192, p.alpha}
			set_render_draw_color(renderer, p_col.r, p_col.g, p_col.b, p_col.a)
			p_rect := Rect{sx + int(p.x), sy + int(p.y), p.size, p.size}
			render_fill_rect(renderer, &p_rect)
		}
	}

	// 10. Draw Dual Mechanical Rotary Knobs
	knob_l_cx := chassis_x + 72
	knob_l_cy := chassis_y + chassis_h - 60
	render_rotary_knob(renderer, knob_l_cx, knob_l_cy, 38, g.knob_l_angle, 'LEFT / RIGHT', 'X-AXIS (A / D)')

	knob_r_cx := chassis_x + chassis_w - 72
	knob_r_cy := chassis_y + chassis_h - 60
	render_rotary_knob(renderer, knob_r_cx, knob_r_cy, 38, g.knob_r_angle, 'UP / DOWN', 'Y-AXIS (W / S)')

	// 11. Bottom Dashboard / Control Status Bar
	dash_y := chassis_y + chassis_h - 95
	render_control_bar(renderer, g, chassis_x + 130, dash_y, chassis_w - 260)

	// 12. Top Mode Selection Banner
	render_mode_tabs(renderer, g, chassis_x + 60, chassis_y + 44)
}

fn render_rotary_knob(renderer &Renderer, cx int, cy int, r int, angle f64, label1 string, label2 string) {
	draw_filled_circle(renderer, cx + 4, cy + 5, r + 2, Color{60, 10, 12, 200})

	draw_filled_circle(renderer, cx, cy, r, Color{220, 222, 225, 255})
	draw_filled_circle(renderer, cx, cy, r - 3, Color{245, 246, 248, 255})

	notch_count := 12
	for i in 0 .. notch_count {
		a := angle + f64(i) * (2.0 * math.pi / f64(notch_count))
		nx1 := cx + int(f64(r - 5) * math.cos(a))
		ny1 := cy + int(f64(r - 5) * math.sin(a))
		nx2 := cx + int(f64(r - 1) * math.cos(a))
		ny2 := cy + int(f64(r - 1) * math.sin(a))
		set_render_draw_color(renderer, 175, 178, 182, 255)
		render_draw_line(renderer, nx1, ny1, nx2, ny2)
	}

	draw_filled_circle(renderer, cx, cy, r - 12, Color{235, 236, 240, 255})
	draw_filled_circle(renderer, cx, cy, r - 15, Color{215, 218, 222, 255})

	px := cx + int(f64(r - 7) * math.cos(angle))
	py := cy + int(f64(r - 7) * math.sin(angle))
	draw_thick_line(renderer, cx, cy, px, py, 3, Color{210, 30, 35, 255})
	draw_filled_circle(renderer, px, py, 3, Color{210, 30, 35, 255})

	draw_text_centered(renderer, cx, cy + r + 8, label1, 1, Color{255, 235, 130, 255})
	draw_text_centered(renderer, cx, cy + r + 20, label2, 1, Color{240, 240, 240, 230})
}

fn render_control_bar(renderer &Renderer, g EtchGame, x int, y int, w int) {
	set_render_draw_color(renderer, 145, 20, 25, 220)
	pill_rect := Rect{x, y, w, 70}
	render_fill_rect(renderer, &pill_rect)

	set_render_draw_color(renderer, 190, 45, 50, 255)
	for i in 0 .. 2 {
		r := Rect{x + i, y + i, w - i * 2, 70 - i * 2}
		render_draw_rect(renderer, &r)
	}

	match g.tool_mode {
		.freehand {
			draw_text(renderer, x + 16, y + 14, 'MODE: CLASSIC FREEHAND DRAWING', 1, Color{255, 255, 255, 255})
			draw_text(renderer, x + 16, y + 30, 'CONTROLS: ARROWS / WASD / DRAG MOUSE / SHAKE [SPACE]', 1, Color{255, 230, 110, 255})
			draw_text(renderer, x + 16, y + 46, 'THEME [C]  |  REPLAY [R]  |  CLEAR [SPACE]  |  MUTE [M]', 1, Color{220, 220, 220, 255})
		}
		.spirograph {
			status := if g.spiro.running { 'RUNNING (AUTO-GEAR)' } else { 'PAUSED [SPACE TO RUN]' }
			draw_text(renderer, x + 16, y + 12, 'SPIROGRAPH STUDIO - PRESET #${g.spiro.preset + 1} (${status})', 1, Color{255, 255, 255, 255})
			draw_text(renderer, x + 16, y + 28, 'PRESETS [TAB]  |  AUTO-DRAW [SPACE]  |  SPEED [UP/DN] | F11: Fullscreen', 1, Color{255, 230, 110, 255})
			draw_text(renderer, x + 16, y + 44, 'GEAR RATIO: R=${int(g.spiro.r_outer)} r=${int(g.spiro.r_inner)} d=${int(g.spiro.d_pen)}', 1, Color{200, 230, 255, 255})
		}
		.stencil {
			st := g.stencils[g.current_stencil]
			stars_str := match g.stencil_stars {
				3 { '★★★ EXCELLENT!' }
				2 { '★★☆ GREAT' }
				1 { '★☆☆ KEEP GOING' }
				else { '☆☆☆ TRACE LINES' }
			}
			draw_text(renderer, x + 16, y + 12, 'STENCIL: ${st.name} [TAB TO CYCLE]', 1, Color{255, 255, 255, 255})
			draw_text(renderer, x + 16, y + 28, 'ACCURACY: ${int(g.stencil_score)}%  ${stars_str}', 1, Color{255, 230, 110, 255})
			draw_text(renderer, x + 16, y + 44, st.desc, 1, Color{210, 230, 240, 255})
		}
		.symmetry {
			sym_name := match g.sym_mode {
				.mirror_h { '2-WAY HORIZONTAL MIRROR' }
				.mirror_v { '2-WAY VERTICAL MIRROR' }
				.quad { '4-WAY QUADRANT SYMMETRY' }
				.kaleidoscope { '8-WAY KALEIDOSCOPE MANDALA' }
			}
			draw_text(renderer, x + 16, y + 12, 'SYMMETRY CAD: ${sym_name}', 1, Color{255, 255, 255, 255})
			draw_text(renderer, x + 16, y + 28, 'CYCLE PATTERN [TAB]  |  MOVE: ARROWS / WASD', 1, Color{255, 230, 110, 255})
			draw_text(renderer, x + 16, y + 44, 'THEME [C]  |  REPLAY [R]  |  SHAKE [SPACE]  |  MUTE [M]', 1, Color{220, 220, 220, 255})
		}
	}

	if g.is_replaying {
		draw_text(renderer, x + w - 160, y + 14, '▶ REPLAYING...', 1, Color{100, 255, 120, 255})
	}
}

fn render_mode_tabs(renderer &Renderer, g EtchGame, x int, y int) {
	tabs := ['1: FREEHAND', '2: SPIROGRAPH', '3: STENCILS', '4: SYMMETRY']
	modes := [ToolMode.freehand, ToolMode.spirograph, ToolMode.stencil, ToolMode.symmetry]

	mut cur_x := x
	tab_w := 140
	tab_h := 20

	for i, title in tabs {
		is_active := g.tool_mode == modes[i]
		if is_active {
			set_render_draw_color(renderer, 255, 225, 100, 255)
			bg := Rect{cur_x, y, tab_w, tab_h}
			render_fill_rect(renderer, &bg)
			draw_text_centered(renderer, cur_x + tab_w / 2, y + 6, title, 1, Color{130, 15, 20, 255})
		} else {
			set_render_draw_color(renderer, 150, 22, 26, 200)
			bg := Rect{cur_x, y, tab_w, tab_h}
			render_fill_rect(renderer, &bg)
			draw_text_centered(renderer, cur_x + tab_w / 2, y + 6, title, 1, Color{240, 240, 240, 200})
		}
		cur_x += tab_w + 12
	}
}
