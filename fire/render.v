module main

const g_bg_plastic = Color{
	r: 165
	g: 28
	b: 28
	a: 255
}
const g_plate_gold = Color{
	r: 215
	g: 195
	b: 155
	a: 255
}
const g_screen_lcd = Color{
	r: 205
	g: 216
	b: 195
	a: 255
}
const g_lcd_ink = Color{
	r: 25
	g: 28
	b: 25
	a: 255
}
const g_lcd_ghost = Color{
	r: 185
	g: 196
	b: 175
	a: 255
}
const g_accent_red = Color{
	r: 210
	g: 45
	b: 45
	a: 255
}
const g_accent_blue = Color{
	r: 45
	g: 90
	b: 180
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

// 14 Fixed LCD Trajectory Nodes for the Jumpers
struct StepNode {
	x int
	y int
}

const jumper_positions = [
	StepNode{ x: 130, y: 150 }, // 0: Top window
	StepNode{ x: 180, y: 210 }, // 1: Leap 1
	StepNode{ x: 230, y: 280 }, // 2: Fall 1
	StepNode{ x: 280, y: 350 }, // 3: Bounce Pos 0 (Left)
	StepNode{ x: 320, y: 270 }, // 4: Rise 1
	StepNode{ x: 370, y: 230 }, // 5: Peak 1
	StepNode{ x: 420, y: 290 }, // 6: Fall 2
	StepNode{ x: 470, y: 350 }, // 7: Bounce Pos 1 (Mid)
	StepNode{ x: 510, y: 270 }, // 8: Rise 2
	StepNode{ x: 550, y: 230 }, // 9: Peak 2
	StepNode{ x: 590, y: 290 }, // 10: Fall 3
	StepNode{ x: 630, y: 350 }, // 11: Bounce Pos 2 (Right)
	StepNode{ x: 670, y: 310 }, // 12: Hop into ambulance
	StepNode{ x: 710, y: 360 }, // 13: Inside Ambulance
]

fn draw_lcd_jumper(renderer &Renderer, x int, y int, is_active bool, crashed bool) {
	c := if is_active { g_lcd_ink } else { g_lcd_ghost }

	if crashed {
		// Crashed upside down on ground
		fill_rect(renderer, x, y + 10, 16, 6, g_accent_red)
		fill_rect(renderer, x + 4, y, 8, 10, g_accent_red)
		fill_rect(renderer, x - 2, y + 6, 20, 3, g_accent_red)
		return
	}

	// Classic Game & Watch stick figure jumper pose
	fill_rect(renderer, x + 4, y, 6, 6, c) // Head
	fill_rect(renderer, x + 6, y + 6, 3, 10, c) // Spine
	fill_rect(renderer, x, y + 7, 14, 3, c) // Arms spread
	fill_rect(renderer, x + 1, y + 15, 4, 7, c) // Left leg
	fill_rect(renderer, x + 9, y + 15, 4, 7, c) // Right leg
}

fn draw_lcd_paramedics(renderer &Renderer, pos int, is_active bool) {
	c := if is_active { g_lcd_ink } else { g_lcd_ghost }
	base_x := 250 + pos * 180
	base_y := 370

	// Left Paramedic
	fill_rect(renderer, base_x, base_y, 7, 7, c) // Head
	fill_rect(renderer, base_x - 1, base_y + 7, 9, 14, c) // Body
	fill_rect(renderer, base_x + 1, base_y + 21, 3, 12, c) // Legs
	fill_rect(renderer, base_x + 6, base_y + 10, 12, 4, c) // Arm holding trampoline

	// Trampoline Bed
	fill_rect(renderer, base_x + 14, base_y + 10, 34, 5, c)
	fill_rect(renderer, base_x + 20, base_y + 15, 22, 2, c)

	// Right Paramedic
	fill_rect(renderer, base_x + 55, base_y, 7, 7, c) // Head
	fill_rect(renderer, base_x + 54, base_y + 7, 9, 14, c) // Body
	fill_rect(renderer, base_x + 57, base_y + 21, 3, 12, c) // Legs
	fill_rect(renderer, base_x + 44, base_y + 10, 12, 4, c) // Arm holding trampoline
}

pub fn draw_fire_game(renderer &Renderer, game &FireGame) {
	// 1. Handheld Body (Game & Watch Silver & Burgundy Plastic)
	fill_rect(renderer, 0, 0, 800, 600, g_bg_plastic)
	fill_rect(renderer, 25, 25, 750, 550, g_plate_gold)
	draw_rect(renderer, 24, 24, 752, 552, Color{ r: 70, g: 50, b: 30 })

	// Screws in 4 corners
	for p in [[35, 35], [765, 35], [35, 565], [765, 565]] {
		fill_rect(renderer, p[0] - 4, p[1] - 4, 8, 8, Color{ r: 120, g: 120, b: 120 })
		draw_rect(renderer, p[0] - 4, p[1] - 4, 8, 8, Color{ r: 60, g: 60, b: 60 })
	}

	// Brand Header
	draw_text(renderer, 50, 42, 'Nintendo', 2, Color{ r: 130, g: 30, b: 30 })
	draw_text(renderer, 340, 40, 'F I R E', 3, g_lcd_ink)
	draw_text(renderer, 580, 42, 'WIDE SCREEN', 2, Color{ r: 80, g: 70, b: 50 })

	// 2. LCD Inner Bezel & Screen
	fill_rect(renderer, 50, 75, 700, 390, Color{ r: 50, g: 50, b: 50 }) // Black Bezel
	fill_rect(renderer, 55, 80, 690, 380, g_screen_lcd)                  // LCD Screen

	// Static Artwork: Burning Building on the Left
	fill_rect(renderer, 65, 120, 75, 280, Color{ r: 140, g: 150, b: 135 }) // Building body
	draw_rect(renderer, 65, 120, 75, 280, g_lcd_ink)
	// Windows
	for wy in 0 .. 4 {
		fill_rect(renderer, 80, 140 + wy * 60, 45, 35, g_screen_lcd)
		draw_rect(renderer, 80, 140 + wy * 60, 45, 35, g_lcd_ink)
	}
	// Flames on top 2 windows
	fill_rect(renderer, 70, 100, 65, 20, g_accent_red)
	draw_text(renderer, 75, 105, 'FLAME', 1, Color{ r: 255, g: 255, b: 255 })
	fill_rect(renderer, 105, 155, 26, 14, g_accent_red)
	fill_rect(renderer, 105, 215, 26, 14, g_accent_red)

	// Ambulance on the Right
	amb_x := 680
	amb_y := 335
	fill_rect(renderer, amb_x, amb_y, 60, 75, Color{ r: 255, g: 255, b: 255 })
	draw_rect(renderer, amb_x, amb_y, 60, 75, g_lcd_ink)
	fill_rect(renderer, amb_x + 10, amb_y + 10, 40, 25, g_accent_blue)
	// Red Cross
	fill_rect(renderer, amb_x + 24, amb_y + 44, 12, 22, g_accent_red)
	fill_rect(renderer, amb_x + 19, amb_y + 49, 22, 12, g_accent_red)
	fill_rect(renderer, amb_x + 5, amb_y + 65, 18, 12, g_lcd_ink) // Wheel 1
	fill_rect(renderer, amb_x + 37, amb_y + 65, 18, 12, g_lcd_ink) // Wheel 2

	// Ground Line
	fill_rect(renderer, 55, 410, 690, 4, g_lcd_ink)

	// Draw Misses (Top Right of LCD Screen)
	draw_text(renderer, 500, 95, 'MISS', 1, g_lcd_ink)
	for m in 0 .. 3 {
		mx := 540 + m * 22
		my := 93
		is_miss := m < game.misses
		draw_lcd_jumper(renderer, mx, my, is_miss, is_miss)
	}

	// Draw Score & High Score
	draw_text(renderer, 180, 95, if game.mode == .game_a { 'GAME A' } else { 'GAME B' }, 1, g_lcd_ink)
	draw_text(renderer, 270, 92, 'SCORE:', 2, g_lcd_ink)
	draw_text(renderer, 385, 88, '${game.score}', 3, g_lcd_ink)
	draw_text(renderer, 620, 95, 'HI:${game.high_score}', 1, g_lcd_ink)

	// Draw All 14 Jumper Nodes (Ghosts or Active)
	for step_idx in 0 .. jumper_positions.len {
		node := jumper_positions[step_idx]
		// Check if any jumper is currently at this step
		mut is_active := false
		mut crashed := false
		for j in game.jumpers {
			if j.active && j.step == step_idx {
				is_active = true
				if j.crashed {
					crashed = true
				}
				break
			}
		}
		draw_lcd_jumper(renderer, node.x, node.y, is_active, crashed)
	}

	// Draw Paramedics with Trampoline at all 3 positions (Only current pos is dark ink!)
	for pos := 0; pos <= 2; pos++ {
		draw_lcd_paramedics(renderer, pos, pos == game.trampoline_pos)
	}

	// 3. Lower Control Panel on Handheld Faceplate
	fill_rect(renderer, 60, 480, 200, 75, Color{ r: 200, g: 180, b: 140 })
	draw_rect(renderer, 60, 480, 200, 75, Color{ r: 100, g: 90, b: 70 })
	draw_text_centered(renderer, 160, 492, 'GAME A / B', 1, g_lcd_ink)
	draw_text_centered(renderer, 160, 510, '[1] Game A  [2] Game B', 1, g_lcd_ink)
	draw_text_centered(renderer, 160, 530, '[M] Sound', 1, g_lcd_ink)

	fill_rect(renderer, 280, 480, 240, 75, Color{ r: 200, g: 180, b: 140 })
	draw_rect(renderer, 280, 480, 240, 75, Color{ r: 100, g: 90, b: 70 })
	draw_text_centered(renderer, 400, 492, 'TRAMPOLINE CATCH', 1, g_lcd_ink)
	draw_text_centered(renderer, 400, 510, '[LEFT] / [RIGHT] / [A] / [D]', 1, g_lcd_ink)
	draw_text_centered(renderer, 400, 530, '[Z] Left   [X] Mid   [C] Right', 1, g_lcd_ink)

	fill_rect(renderer, 540, 480, 200, 75, Color{ r: 200, g: 180, b: 140 })
	draw_rect(renderer, 540, 480, 200, 75, Color{ r: 100, g: 90, b: 70 })
	draw_text_centered(renderer, 640, 492, 'STATUS', 1, g_lcd_ink)
	match game.state {
		.title {
			draw_text_centered(renderer, 640, 515, 'PRESS [SPACE] TO START', 1, g_accent_red)
		}
		.playing {
			draw_text_centered(renderer, 640, 515, 'RESCUING JUMPERS!', 1, g_lcd_ink)
		}
		.game_over {
			draw_text_centered(renderer, 640, 510, 'GAME OVER!', 2, g_accent_red)
			draw_text_centered(renderer, 640, 532, 'PRESS [SPACE] RESTART', 1, g_lcd_ink)
		}
	}
}
