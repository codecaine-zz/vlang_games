module main



pub fn render_dopewars_game(renderer &Renderer, mut g DopeWarsGame, win_w int, win_h int, mouse_x int, mouse_y int, sound_enabled bool) {
	// 1. Classic Charcoal DOS Terminal Background
	set_render_draw_color(renderer, 18, 20, 24, 255)
	clear_rect := Rect{0, 0, win_w, win_h}
	render_fill_rect(renderer, &clear_rect)

	// Amber border frame
	set_render_draw_color(renderer, 220, 160, 40, 255)
	for i in 0 .. 3 {
		r := Rect{i, i, win_w - i * 2, win_h - i * 2}
		render_draw_rect(renderer, &r)
	}

	// 2. Top Header Bar
	render_header(renderer, g, win_w, sound_enabled)

	match g.ui_state {
		.market {
			render_market_view(renderer, g, win_w, win_h, mouse_x, mouse_y)
		}
		.subway {
			render_subway_view(renderer, g, win_w, win_h, mouse_x, mouse_y)
		}
		.bank {
			render_bank_view(renderer, g, win_w, win_h, mouse_x, mouse_y)
		}
		.loan_shark {
			render_shark_view(renderer, g, win_w, win_h, mouse_x, mouse_y)
		}
		.police_encounter {
			render_police_view(renderer, g, win_w, win_h)
		}
		.game_over_screen {
			render_game_over(renderer, g, win_w, win_h)
		}
	}

	// Announcement Banner
	if g.banner_timer > 0.0 && g.banner_text != '' {
		bw := g.banner_text.len * 8 * 2 + 40
		bx := win_w / 2 - bw / 2
		by := 250

		set_render_draw_color(renderer, 10, 15, 22, 240)
		bg := Rect{bx, by, bw, 44}
		render_fill_rect(renderer, &bg)
		set_render_draw_color(renderer, 255, 215, 0, 255)
		render_draw_rect(renderer, &bg)

		draw_text_centered(renderer, win_w / 2, by + 14, g.banner_text, 2, Color{255, 230, 80, 255})
	}

	// CRT Phosphor Scanline Overlay
	set_render_draw_color(renderer, 0, 0, 0, 30)
	for y := 0; y < win_h; y += 3 {
		render_draw_line(renderer, 0, y, win_w, y)
	}
}

fn render_header(renderer &Renderer, g DopeWarsGame, win_w int, sound_enabled bool) {
	set_render_draw_color(renderer, 30, 35, 42, 255)
	bar := Rect{0, 0, win_w, 48}
	render_fill_rect(renderer, &bar)

	set_render_draw_color(renderer, 220, 160, 40, 255)
	render_draw_line(renderer, 0, 47, win_w, 47)

	draw_text(renderer, 20, 16, '★ DOPE WARS 1990 ★', 2, Color{255, 220, 80, 255})
	draw_text(renderer, 290, 18, 'DAY: ${g.day}/30', 1, Color{240, 240, 240, 255})
	draw_text(renderer, 400, 18, 'LOCATION: ${g.get_loc_name(g.current_loc).to_upper()}', 1, Color{100, 230, 255, 255})

	// Sound toggle badge
	sound_x := win_w - 140
	if sound_enabled {
		set_render_draw_color(renderer, 40, 120, 60, 255)
		btn := Rect{sound_x, 10, 120, 26}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 60, 16, 'SOUND: ON [M]', 1, Color{255, 255, 255, 255})
	} else {
		set_render_draw_color(renderer, 120, 35, 40, 255)
		btn := Rect{sound_x, 10, 120, 26}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 60, 16, 'MUTED [M]', 1, Color{255, 180, 180, 255})
	}
}

fn render_market_view(renderer &Renderer, g DopeWarsGame, _ int, _ int, _ int, _ int) {
	// Left Table: Market Prices & Inventory
	table_x := 30
	table_y := 65
	table_w := 540
	table_h := 520

	set_render_draw_color(renderer, 24, 28, 34, 255)
	t_rect := Rect{table_x, table_y, table_w, table_h}
	render_fill_rect(renderer, &t_rect)

	set_render_draw_color(renderer, 80, 90, 105, 255)
	render_draw_rect(renderer, &t_rect)

	// Table Header
	draw_text(renderer, table_x + 16, table_y + 14, 'COMMODITY', 1, Color{255, 215, 0, 255})
	draw_text(renderer, table_x + 170, table_y + 14, 'STREET PRICE', 1, Color{255, 215, 0, 255})
	draw_text(renderer, table_x + 310, table_y + 14, 'HELD (COAT)', 1, Color{255, 215, 0, 255})
	draw_text(renderer, table_x + 440, table_y + 14, 'ACTION', 1, Color{255, 215, 0, 255})

	mut row_y := table_y + 44
	for i, d in drug_catalogue {
		is_avail := d.name in g.market_prices
		price := if is_avail { '$${g.market_prices[d.name]}' } else { '---' }
		held := g.inventory[d.name]

		if i == g.selected_drug {
			set_render_draw_color(renderer, 45, 55, 75, 255)
			r := Rect{table_x + 4, row_y - 4, table_w - 8, 36}
			render_fill_rect(renderer, &r)
		}

		draw_text(renderer, table_x + 16, row_y + 6, '${i + 1}. ${d.name}', 1, Color{240, 240, 240, 255})
		draw_text(renderer, table_x + 170, row_y + 6, price, 1, Color{100, 255, 140, 255})
		draw_text(renderer, table_x + 310, row_y + 6, '${held} units', 1, Color{200, 220, 255, 255})

		// Buy / Sell buttons
		if is_avail {
			set_render_draw_color(renderer, 40, 120, 60, 255)
			b_btn := Rect{table_x + 430, row_y + 2, 45, 22}
			render_fill_rect(renderer, &b_btn)
			draw_text_centered(renderer, table_x + 452, row_y + 7, 'BUY', 1, Color{255, 255, 255, 255})

			if held > 0 {
				set_render_draw_color(renderer, 160, 50, 40, 255)
				s_btn := Rect{table_x + 480, row_y + 2, 45, 22}
				render_fill_rect(renderer, &s_btn)
				draw_text_centered(renderer, table_x + 502, row_y + 7, 'SELL', 1, Color{255, 255, 255, 255})
			}
		}

		row_y += 42
	}

	// Instructions
	draw_text(renderer, table_x + 16, table_y + table_h - 30, 'KEYS: [1-8] SELECT  |  [B] BUY MAX  |  [S] SELL ALL', 1, Color{200, 180, 120, 255})

	// Right Panel: Financial Ledger & Navigation
	ledger_x := 590
	ledger_y := 65
	ledger_w := 300
	ledger_h := 520

	set_render_draw_color(renderer, 24, 28, 34, 255)
	l_rect := Rect{ledger_x, ledger_y, ledger_w, ledger_h}
	render_fill_rect(renderer, &l_rect)

	set_render_draw_color(renderer, 80, 90, 105, 255)
	render_draw_rect(renderer, &l_rect)

	draw_text_centered(renderer, ledger_x + ledger_w / 2, ledger_y + 14, 'FINANCIAL LEDGER', 1, Color{255, 215, 0, 255})

	draw_text(renderer, ledger_x + 20, ledger_y + 45, 'CASH ON HAND:', 1, Color{180, 180, 180, 255})
	draw_text(renderer, ledger_x + 20, ledger_y + 65, '$${g.cash}', 2, Color{100, 255, 120, 255})

	draw_text(renderer, ledger_x + 20, ledger_y + 100, 'BANK DEPOSITS (5%):', 1, Color{180, 180, 180, 255})
	draw_text(renderer, ledger_x + 20, ledger_y + 120, '$${g.bank}', 2, Color{100, 220, 255, 255})

	draw_text(renderer, ledger_x + 20, ledger_y + 155, 'LOAN SHARK DEBT (10%):', 1, Color{180, 180, 180, 255})
	draw_text(renderer, ledger_x + 20, ledger_y + 175, '$${g.debt}', 2, Color{255, 80, 80, 255})

	draw_text(renderer, ledger_x + 20, ledger_y + 210, 'TRENCHCOAT CAPACITY:', 1, Color{180, 180, 180, 255})
	draw_text(renderer, ledger_x + 20, ledger_y + 230, '${g.get_used_pockets()} / ${g.max_pockets} UNITS', 1, Color{255, 220, 100, 255})

	draw_text(renderer, ledger_x + 20, ledger_y + 265, 'HEALTH STATUS:', 1, Color{180, 180, 180, 255})
	draw_text(renderer, ledger_x + 20, ledger_y + 285, '${g.health}% HP', 1, Color{50, 230, 100, 255})

	// Navigation Buttons
	nav_y := ledger_y + 330
	nav_btns := ['SUBWAY TRANSIT [T]', 'VISIT BANK [K]', 'LOAN SHARK [L]']
	for i, nb in nav_btns {
		set_render_draw_color(renderer, 45, 60, 85, 255)
		b := Rect{ledger_x + 20, nav_y + i * 50, ledger_w - 40, 38}
		render_fill_rect(renderer, &b)
		set_render_draw_color(renderer, 100, 140, 190, 255)
		render_draw_rect(renderer, &b)
		draw_text_centered(renderer, ledger_x + ledger_w / 2, nav_y + i * 50 + 12, nb, 1, Color{255, 255, 255, 255})
	}
}

fn render_subway_view(renderer &Renderer, g DopeWarsGame, win_w int, win_h int, _ int, _ int) {
	// Modal Subways
	set_render_draw_color(renderer, 12, 16, 24, 245)
	modal := Rect{140, 80, win_w - 280, win_h - 160}
	render_fill_rect(renderer, &modal)

	set_render_draw_color(renderer, 220, 160, 40, 255)
	render_draw_rect(renderer, &modal)

	draw_text_centered(renderer, win_w / 2, 110, '★ NYC SUBWAY SYSTEM ★', 2, Color{255, 220, 80, 255})
	draw_text_centered(renderer, win_w / 2, 145, 'SELECT DESTINATION BOROUGH (ADVANCES 1 DAY):', 1, Color{200, 220, 240, 255})

	locs := [
		Borough.manhattan,
		Borough.bronx,
		Borough.brooklyn,
		Borough.queens,
		Borough.staten_island,
		Borough.coney_island,
	]
	mut by := 190
	for i, l in locs {
		is_cur := l == g.current_loc
		btn_col := if is_cur { Color{50, 60, 75, 255} } else { Color{40, 70, 110, 255} }

		set_render_draw_color(renderer, btn_col.r, btn_col.g, btn_col.b, 255)
		r := Rect{win_w / 2 - 160, by, 320, 36}
		render_fill_rect(renderer, &r)

		name := '${i + 1}. ${g.get_loc_name(l).to_upper()}' + (if is_cur { ' (CURRENT)' } else { '' })
		draw_text_centered(renderer, win_w / 2, by + 12, name, 1, Color{255, 255, 255, 255})
		by += 48
	}

	draw_text_centered(renderer, win_w / 2, win_h - 120, 'PRESS [ESC] TO CANCEL', 1, Color{180, 180, 180, 255})
}

fn render_bank_view(renderer &Renderer, g DopeWarsGame, win_w int, win_h int, _ int, _ int) {
	set_render_draw_color(renderer, 12, 16, 24, 245)
	modal := Rect{140, 100, win_w - 280, win_h - 200}
	render_fill_rect(renderer, &modal)

	set_render_draw_color(renderer, 100, 220, 255, 255)
	render_draw_rect(renderer, &modal)

	draw_text_centered(renderer, win_w / 2, 130, '★ 1ST NATIONAL BANK OF NYC ★', 2, Color{100, 220, 255, 255})
	draw_text_centered(renderer, win_w / 2, 175, 'ACCOUNT BALANCE: $${g.bank}  |  CASH IN WALLET: $${g.cash}', 1, Color{240, 240, 240, 255})

	// Deposit / Withdraw actions
	draw_text_centered(renderer, win_w / 2, 230, '[D] DEPOSIT ALL CASH ($${g.cash})', 1, Color{100, 255, 120, 255})
	draw_text_centered(renderer, win_w / 2, 270, '[W] WITHDRAW ALL BANK FUNDS ($${g.bank})', 1, Color{255, 200, 100, 255})
	draw_text_centered(renderer, win_w / 2, 330, 'PRESS [ESC] TO RETURN TO MARKET', 1, Color{180, 180, 180, 255})
}

fn render_shark_view(renderer &Renderer, g DopeWarsGame, win_w int, win_h int, _ int, _ int) {
	set_render_draw_color(renderer, 24, 12, 14, 245)
	modal := Rect{140, 100, win_w - 280, win_h - 200}
	render_fill_rect(renderer, &modal)

	set_render_draw_color(renderer, 255, 60, 60, 255)
	render_draw_rect(renderer, &modal)

	draw_text_centered(renderer, win_w / 2, 130, '★ LOAN SHARK HEADQUARTERS ★', 2, Color{255, 60, 60, 255})
	draw_text_centered(renderer, win_w / 2, 175, 'OUTSTANDING DEBT: $${g.debt} (10% DAILY INTEREST)', 1, Color{255, 180, 180, 255})

	draw_text_centered(renderer, win_w / 2, 230, '[P] PAY OFF FULL DEBT (OR MAXIMUM CASH)', 1, Color{255, 230, 80, 255})
	draw_text_centered(renderer, win_w / 2, 300, 'PRESS [ESC] TO RETURN TO MARKET', 1, Color{180, 180, 180, 255})
}

fn render_police_view(renderer &Renderer, g DopeWarsGame, win_w int, win_h int) {
	set_render_draw_color(renderer, 35, 10, 10, 250)
	modal := Rect{100, 80, win_w - 200, win_h - 160}
	render_fill_rect(renderer, &modal)

	set_render_draw_color(renderer, 255, 40, 40, 255)
	render_draw_rect(renderer, &modal)

	draw_text_centered(renderer, win_w / 2, 120, '🚨 POLICE CHASE! 🚨', 2, Color{255, 60, 60, 255})
	draw_text_centered(renderer, win_w / 2, 170, 'OFFICER BOB AND ${g.police_count} DEPUTIES CORNERED YOU!', 1, Color{255, 240, 240, 255})
	draw_text_centered(renderer, win_w / 2, 200, 'YOUR HEALTH: ${g.health}% HP', 1, Color{100, 255, 140, 255})

	// Options
	draw_text_centered(renderer, win_w / 2, 270, '[R] RUN FOR IT (65% ESCAPE CHANCE / RISK BULLET DAMAGE)', 1, Color{255, 220, 80, 255})
	bribe_cost := g.police_count * 1000
	draw_text_centered(renderer, win_w / 2, 310, '[B] BRIBE OFFICERS ($${bribe_cost})', 1, Color{100, 230, 255, 255})
}

fn render_game_over(renderer &Renderer, g DopeWarsGame, win_w int, win_h int) {
	set_render_draw_color(renderer, 10, 12, 18, 255)
	clear_rect := Rect{0, 0, win_w, win_h}
	render_fill_rect(renderer, &clear_rect)

	net_worth := g.get_net_worth()
	draw_text_centered(renderer, win_w / 2, 120, '★ RETIREMENT SCORECARD ★', 2, Color{255, 215, 0, 255})

	draw_text_centered(renderer, win_w / 2, 180, 'FINAL CASH: $${g.cash}', 1, Color{100, 255, 120, 255})
	draw_text_centered(renderer, win_w / 2, 210, 'FINAL BANK: $${g.bank}', 1, Color{100, 220, 255, 255})
	draw_text_centered(renderer, win_w / 2, 240, 'UNPAID DEBT: $${g.debt}', 1, Color{255, 80, 80, 255})

	draw_text_centered(renderer, win_w / 2, 290, 'TOTAL NET WORTH: $${net_worth}', 2, Color{255, 235, 100, 255})

	rank := if net_worth >= 1000000 {
		'KINGPIN OF NEW YORK CITY'
	} else if net_worth >= 250000 {
		'SYNDICATE BOSS'
	} else if net_worth >= 50000 {
		'HUSTLER'
	} else {
		'SMALL-TIME PEDDLER'
	}
	draw_text_centered(renderer, win_w / 2, 350, 'HONORARY TITLE: ${rank}', 1, Color{240, 240, 240, 255})
	draw_text_centered(renderer, win_w / 2, 420, 'PRESS [R] TO PLAY AGAIN', 1, Color{200, 180, 120, 255})
}
