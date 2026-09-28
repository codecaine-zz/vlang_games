module main



pub fn render_chimp_test(renderer &Renderer, game &ChimpGame, screen_w int, screen_h int, hover_gx int, hover_gy int) {
	// 1. Background: Deep Slate Titanium Matrix
	set_render_draw_color(renderer, 18, 22, 32, 255)
	render_clear(renderer)

	// 2. Top Header HUD
	hud_h := 56
	set_render_draw_color(renderer, 12, 16, 25, 255)
	render_fill_rect(renderer, &Rect{x: 0, y: 0, w: screen_w, h: hud_h})
	set_render_draw_color(renderer, 45, 55, 80, 255)
	render_draw_line(renderer, 0, hud_h, screen_w, hud_h)

	draw_text(renderer, 24, 18, 'CHIMP TEST', 2, Color{r: 255, g: 215, b: 0})
	draw_text(renderer, 195, 22, 'SPATIAL WORKING MEMORY', 1, Color{r: 160, g: 190, b: 240})

	draw_text(renderer, 420, 18, 'NUMBERS: ${game.level}', 2, Color{r: 255, g: 255, b: 255})

	// Strikes Display [X X X]
	draw_text(renderer, 640, 18, 'STRIKES:', 2, Color{r: 200, g: 210, b: 230})
	for s in 0 .. game.max_strikes {
		sx := 775 + s * 22
		s_col := if s < game.strikes { Color{r: 255, g: 40, b: 50} } else { Color{r: 45, g: 55, b: 75} }
		set_render_draw_color(renderer, s_col.r, s_col.g, s_col.b, 255)
		render_fill_rect(renderer, &Rect{x: sx, y: 18, w: 16, h: 16})
		set_render_draw_color(renderer, 20, 20, 25, 255)
		render_draw_rect(renderer, &Rect{x: sx, y: 18, w: 16, h: 16})
	}

	// 3. Render 8x5 Test Matrix Grid
	board_y := 75
	avail_w := screen_w - 60
	avail_h := screen_h - board_y - 45

	cell_w := int(avail_w / grid_cols) - 8
	cell_h := int(avail_h / grid_rows) - 8

	total_grid_w := grid_cols * (cell_w + 8) - 8
	total_grid_h := grid_rows * (cell_h + 8) - 8
	start_x := (screen_w - total_grid_w) / 2
	start_y := board_y + (avail_h - total_grid_h) / 2

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			idx := r * grid_cols + c
			if idx >= game.cells.len { continue }

			cell := game.cells[idx]
			cx := start_x + c * (cell_w + 8)
			cy := start_y + r * (cell_h + 8)

			is_hover := hover_gx == c && hover_gy == r

			draw_chimp_cell(renderer, &cell, cx, cy, cell_w, cell_h, game.state, is_hover)
		}
	}

	// 4. Instructions Footer
	status_hint := match game.state {
		.ready { 'CLICK NUMBER [1] TO BEGIN' }
		.active_hidden { 'CLICK REMAINING SQUARES IN ASCENDING ORDER' }
		.level_failed { 'STRIKE! CLICK ANYWHERE TO CONTINUE' }
		.benchmark_over { 'BENCHMARK COMPLETE - CLICK TO RETRY' }
	}
	draw_text_centered(renderer, screen_w / 2, screen_h - 22, status_hint, 1, Color{r: 160, g: 180, b: 220})

	// 5. Final Benchmark Modal Overlay
	if game.state == .benchmark_over {
		set_render_draw_color(renderer, 0, 0, 0, 205)
		render_fill_rect(renderer, &Rect{x: 0, y: 0, w: screen_w, h: screen_h})

		mw := 520
		mh := 320
		mx := (screen_w - mw) / 2
		my := (screen_h - mh) / 2
		m_rect := Rect{x: mx, y: my, w: mw, h: mh}

		set_render_draw_color(renderer, 22, 28, 48, 255)
		render_fill_rect(renderer, &m_rect)
		set_render_draw_color(renderer, 60, 120, 240, 255)
		render_draw_rect(renderer, &m_rect)

		draw_text_centered(renderer, screen_w / 2, my + 24, 'BENCHMARK REPORT', 3, Color{r: 255, g: 215, b: 0})

		score_num := game.max_level - 1
		draw_text_centered(renderer, screen_w / 2, my + 75, 'WORKING MEMORY CAPACITY: ${score_num} DIGITS', 2, Color{r: 255, g: 255, b: 255})
		draw_text_centered(renderer, screen_w / 2, my + 115, 'PERCENTILE RANK: TOP ${(100.0 - game.percentile):.1f}%', 2, Color{r: 80, g: 255, b: 140})

		tier_desc := match true {
			score_num >= 14 { 'CHIMPANZEE AYUMU SUPERHUMAN TIER' }
			score_num >= 11 { 'EXCEPTIONAL MEMORY MASTERY' }
			score_num >= 9 { 'ABOVE AVERAGE COGNITIVE WORKING MEMORY' }
			else { 'STANDARD WORKING MEMORY CAPACITY' }
		}
		draw_text_centered(renderer, screen_w / 2, my + 155, tier_desc, 1, Color{r: 200, g: 220, b: 255})

		draw_text_centered(renderer, screen_w / 2, my + 200, 'BEST SCORE: ${game.high_score} NUMBERS', 2, Color{r: 255, g: 215, b: 0})
		draw_text_centered(renderer, screen_w / 2, my + 270, 'PRESS [SPACE] OR CLICK TO RETRY BENCHMARK', 1, Color{r: 140, g: 190, b: 240})
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}

fn draw_chimp_cell(renderer &Renderer, cell &ChimpCell, cx int, cy int, w int, h int, state ChimpState, is_hover bool) {
	rect := Rect{x: cx, y: cy, w: w, h: h}

	if cell.number == 0 {
		// Empty background slot
		set_render_draw_color(renderer, 24, 30, 44, 255)
		render_fill_rect(renderer, &rect)
		set_render_draw_color(renderer, 32, 40, 58, 255)
		render_draw_rect(renderer, &rect)
		return
	}

	if cell.is_clicked {
		// Correctly clicked tile -> disappears into dark slot
		set_render_draw_color(renderer, 20, 26, 38, 255)
		render_fill_rect(renderer, &rect)
		set_render_draw_color(renderer, 40, 80, 50, 255)
		render_draw_rect(renderer, &rect)
		return
	}

	if cell.is_error {
		// Mistaken click -> Red error tile
		set_render_draw_color(renderer, 240, 40, 50, 255)
		render_fill_rect(renderer, &rect)
		draw_text_centered(renderer, cx + w / 2, cy + h / 2 - 12, '${cell.number}', 3, Color{r: 255, g: 255, b: 255})
		return
	}

	// Active Tile
	match state {
		.ready, .level_failed {
			// Numbers are visible! (White tile with bold black number)
			set_render_draw_color(renderer, 245, 248, 255, 255)
			render_fill_rect(renderer, &rect)

			border_col := if is_hover { Color{r: 255, g: 215, b: 0} } else { Color{r: 180, g: 190, b: 215} }
			set_render_draw_color(renderer, border_col.r, border_col.g, border_col.b, 255)
			render_draw_rect(renderer, &rect)

			num_str := '${cell.number}'
			draw_text_centered(renderer, cx + w / 2, cy + h / 2 - 12, num_str, 3, Color{r: 15, g: 20, b: 30})
		}
		.active_hidden {
			// Masked hidden state! (Blank white tile)
			bg_b := if is_hover { 255 } else { 235 }
			set_render_draw_color(renderer, u8(bg_b), u8(bg_b), 250, 255)
			render_fill_rect(renderer, &rect)

			border_col := if is_hover { Color{r: 255, g: 215, b: 0} } else { Color{r: 170, g: 180, b: 205} }
			set_render_draw_color(renderer, border_col.r, border_col.g, border_col.b, 255)
			render_draw_rect(renderer, &rect)
		}
		.benchmark_over {}
	}
}

pub fn get_chimp_grid_coords_at(mx int, my int, screen_w int, screen_h int) (int, int) {
	board_y := 75
	avail_w := screen_w - 60
	avail_h := screen_h - board_y - 45

	cell_w := int(avail_w / grid_cols) - 8
	cell_h := int(avail_h / grid_rows) - 8

	total_grid_w := grid_cols * (cell_w + 8) - 8
	total_grid_h := grid_rows * (cell_h + 8) - 8
	start_x := (screen_w - total_grid_w) / 2
	start_y := board_y + (avail_h - total_grid_h) / 2

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			cx := start_x + c * (cell_w + 8)
			cy := start_y + r * (cell_h + 8)

			if mx >= cx && mx <= cx + cell_w && my >= cy && my <= cy + cell_h {
				return c, r
			}
		}
	}
	return -1, -1
}
