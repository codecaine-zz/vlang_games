module main



const lcd_bg = Color{
	r: 135
	g: 154
	b: 117
	a: 255
}
const lcd_dark = Color{
	r: 27
	g: 40
	b: 27
	a: 255
}
const lcd_mid = Color{
	r: 85
	g: 105
	b: 75
	a: 255
}
const lcd_hilight = Color{
	r: 155
	g: 175
	b: 135
	a: 255
}

pub fn draw_rect(renderer &Renderer, x int, y int, w int, h int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	rect := Rect{
		x: x
		y: y
		w: w
		h: h
	}
	render_draw_rect(renderer, &rect)
}

pub fn fill_rect(renderer &Renderer, x int, y int, w int, h int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	rect := Rect{
		x: x
		y: y
		w: w
		h: h
	}
	render_fill_rect(renderer, &rect)
}

pub fn draw_blockdude_game(renderer &Renderer, game &BlockDudeGame) {
	// 1. Calculator Screen Frame & Background
	fill_rect(renderer, 0, 0, 800, 600, Color{
		r: 40
		g: 45
		b: 42
	}) // Outer plastic casing
	fill_rect(renderer, 20, 20, 760, 560, lcd_bg) // LCD Matrix Area
	draw_rect(renderer, 18, 18, 764, 564, lcd_dark)
	draw_rect(renderer, 19, 19, 762, 562, lcd_mid)

	// Screen Header Bar
	fill_rect(renderer, 20, 20, 760, 36, lcd_mid)
	draw_text(renderer, 35, 30, 'TI-83+ BLOCK DUDE', 2, lcd_bg)
	draw_text(renderer, 360, 32, 'LVL: ${game.current_level + 1}/8', 2, lcd_dark)
	draw_text(renderer, 580, 32, 'MOVES: ${game.moves_count}', 2, lcd_dark)

	// Tile grid area
	tile_size := 36
	grid_offset_x := (760 - game.width * tile_size) / 2 + 20
	grid_offset_y := 70

	// Draw Background LCD pixel mesh
	for y in 0 .. game.height {
		for x in 0 .. game.width {
			px := grid_offset_x + x * tile_size
			py := grid_offset_y + y * tile_size
			draw_rect(renderer, px, py, tile_size, tile_size, lcd_hilight)
		}
	}

	// Draw Grid Elements
	for y in 0 .. game.height {
		for x in 0 .. game.width {
			px := grid_offset_x + x * tile_size
			py := grid_offset_y + y * tile_size
			tile := game.grid[y][x]

			match tile {
				.wall {
					// Solid Wall with brick texture
					fill_rect(renderer, px, py, tile_size, tile_size, lcd_dark)
					fill_rect(renderer, px + 2, py + 2, tile_size - 4, tile_size / 2 - 3, lcd_mid)
					fill_rect(renderer, px + 2, py + tile_size / 2 + 1, tile_size - 4,
						tile_size / 2 - 3, lcd_mid)
					draw_rect(renderer, px, py, tile_size, tile_size, lcd_bg)
				}
				.block {
					// Movable Block with inset border and cross
					fill_rect(renderer, px + 1, py + 1, tile_size - 2, tile_size - 2,
						lcd_dark)
					fill_rect(renderer, px + 4, py + 4, tile_size - 8, tile_size - 8,
						lcd_bg)
					fill_rect(renderer, px + 7, py + 7, tile_size - 14, tile_size - 14,
						lcd_dark)
					// Handle grips
					fill_rect(renderer, px + 12, py + 12, tile_size - 24, tile_size - 24,
						lcd_bg)
				}
				.door {
					// Exit Doorway
					fill_rect(renderer, px + 4, py + 2, tile_size - 8, tile_size - 2,
						lcd_dark)
					fill_rect(renderer, px + 8, py + 6, tile_size - 16, tile_size - 6,
						lcd_bg)
					// Arch top & Keyhole
					fill_rect(renderer, px + 15, py + 16, 6, 8, lcd_dark)
					fill_rect(renderer, px + 16, py + 24, 4, 6, lcd_dark)
				}
				.empty {}
			}
		}
	}

	// Draw Player Dude
	dude_px := grid_offset_x + game.player_x * tile_size
	dude_py := grid_offset_y + game.player_y * tile_size

	// Body & Head
	fill_rect(renderer, dude_px + 8, dude_py + 4, 20, 16, lcd_dark) // Head
	fill_rect(renderer, dude_px + 6, dude_py + 16, 24, 14, lcd_dark) // Torso
	fill_rect(renderer, dude_px + 10, dude_py + 30, 6, 6, lcd_dark) // Left leg
	fill_rect(renderer, dude_px + 20, dude_py + 30, 6, 6, lcd_dark) // Right leg

	// Eyes & Direction indicator
	if game.facing == .right {
		fill_rect(renderer, dude_px + 20, dude_py + 8, 4, 6, lcd_bg) // Right eye
		fill_rect(renderer, dude_px + 4, dude_py + 18, 5, 10, lcd_mid) // Backpack on left
	} else {
		fill_rect(renderer, dude_px + 12, dude_py + 8, 4, 6, lcd_bg) // Left eye
		fill_rect(renderer, dude_px + 27, dude_py + 18, 5, 10, lcd_mid) // Backpack on right
	}

	// Carried block above head
	if game.carrying_block {
		cb_x := dude_px
		cb_y := dude_py - tile_size
		fill_rect(renderer, cb_x + 1, cb_y + 1, tile_size - 2, tile_size - 2, lcd_dark)
		fill_rect(renderer, cb_x + 4, cb_y + 4, tile_size - 8, tile_size - 8, lcd_bg)
		fill_rect(renderer, cb_x + 7, cb_y + 7, tile_size - 14, tile_size - 14, lcd_dark)
		fill_rect(renderer, cb_x + 12, cb_y + 12, tile_size - 24, tile_size - 24,
			lcd_bg)
	}

	// Bottom Instructions & Status Panel
	fill_rect(renderer, 20, 480, 760, 100, lcd_mid)
	draw_rect(renderer, 20, 480, 760, 100, lcd_dark)

	match game.state {
		.playing {
			draw_text_centered(renderer, 400, 492, '[A]/[D] Move & Turn  |  [W]/[S]/[Space] Pick Up / Drop Block',
				1, lcd_bg)
			draw_text_centered(renderer, 400, 514, '[U] Undo  |  [F5] Save  |  [F9] Load  |  [R] Restart  |  [N]/[P] Next/Prev',
				1, lcd_bg)
			draw_text_centered(renderer, 400, 545, 'Tip: Stack blocks to climb 1-step ledges and reach the Door!',
				1, lcd_dark)
		}
		.level_complete {
			fill_rect(renderer, 150, 200, 500, 160, lcd_bg)
			draw_rect(renderer, 150, 200, 500, 160, lcd_dark)
			draw_rect(renderer, 154, 204, 492, 152, lcd_mid)
			draw_text_centered(renderer, 400, 230, 'LEVEL COMPLETED!', 3, lcd_dark)
			draw_text_centered(renderer, 400, 280, 'Total Moves: ${game.moves_count}',
				2, lcd_mid)
			draw_text_centered(renderer, 400, 315, 'Press [SPACE] or [ENTER] for Next Level',
				1, lcd_dark)
		}
		.game_won {
			fill_rect(renderer, 150, 180, 500, 200, lcd_bg)
			draw_rect(renderer, 150, 180, 500, 200, lcd_dark)
			draw_rect(renderer, 154, 184, 492, 192, lcd_mid)
			draw_text_centered(renderer, 400, 210, 'CONGRATULATIONS!', 3, lcd_dark)
			draw_text_centered(renderer, 400, 255, 'YOU MASTERED BLOCK DUDE!', 2, lcd_mid)
			draw_text_centered(renderer, 400, 300, 'All 8 levels conquered.', 1, lcd_dark)
			draw_text_centered(renderer, 400, 335, 'Press [R] to Play Again', 2, lcd_dark)
		}
	}

	if game.toast_timer > 0 {
		fill_rect(renderer, 270, 110, 260, 36, lcd_dark)
		draw_rect(renderer, 270, 110, 260, 36, lcd_bg)
		draw_text_centered(renderer, 400, 120, game.toast_msg, 2, lcd_bg)
	}
}
