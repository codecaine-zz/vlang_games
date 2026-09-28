module main

import math


pub fn draw_gold_chunk(renderer &Renderer, cx f64, cy f64, rad f64) {
	int_rad := int(rad)
	icx := int(cx)
	icy := int(cy)

	// Gold Base (Warm Amber-Gold)
	set_render_draw_color(renderer, 245, 195, 30, 255)
	for dy := -int_rad; dy <= int_rad; dy++ {
		dx_max := int(math.sqrt(f64(int_rad * int_rad - dy * dy)) * 1.1)
		render_draw_line(renderer, icx - dx_max, icy + dy, icx + dx_max, icy + dy)
	}

	// Dark Gold Shadow
	set_render_draw_color(renderer, 180, 130, 15, 255)
	for dy := 2; dy <= int_rad; dy++ {
		dx_max := int(math.sqrt(f64(int_rad * int_rad - dy * dy)) * 1.1)
		if dx_max > 3 {
			render_draw_line(renderer, icx - dx_max + 3, icy + dy, icx + dx_max - 2, icy + dy)
		}
	}

	// Bright Gold Glitter Specular
	set_render_draw_color(renderer, 255, 245, 150, 255)
	hl_rad := int(rad * 0.4)
	for dy := -hl_rad; dy <= hl_rad; dy++ {
		dx_max := int(math.sqrt(f64(hl_rad * hl_rad - dy * dy)))
		render_draw_line(renderer, icx - int_rad / 3 - dx_max, icy - int_rad / 3 + dy, icx - int_rad / 3 + dx_max, icy - int_rad / 3 + dy)
	}
}

pub fn draw_diamond(renderer &Renderer, cx f64, cy f64, rad f64) {
	icx := int(cx)
	icy := int(cy)
	ir := int(rad)

	// Cyan Diamond shape
	set_render_draw_color(renderer, 60, 220, 255, 255)
	for dy := -ir; dy <= ir; dy++ {
		dx_max := ir - int(math.abs(f64(dy)))
		render_draw_line(renderer, icx - dx_max, icy + dy, icx + dx_max, icy + dy)
	}
	// Diamond Sparkle White
	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_draw_line(renderer, icx - ir / 2, icy, icx + ir / 2, icy)
	render_draw_line(renderer, icx, icy - ir / 2, icx, icy + ir / 2)
}

pub fn draw_rock(renderer &Renderer, cx f64, cy f64, rad f64) {
	int_rad := int(rad)
	icx := int(cx)
	icy := int(cy)

	set_render_draw_color(renderer, 130, 125, 120, 255)
	for dy := -int_rad; dy <= int_rad; dy++ {
		dx_max := int(math.sqrt(f64(int_rad * int_rad - dy * dy)))
		render_draw_line(renderer, icx - dx_max, icy + dy, icx + dx_max, icy + dy)
	}
	set_render_draw_color(renderer, 80, 75, 70, 255)
	for dy := 3; dy <= int_rad; dy++ {
		dx_max := int(math.sqrt(f64(int_rad * int_rad - dy * dy)))
		if dx_max > 2 {
			render_draw_line(renderer, icx - dx_max + 2, icy + dy, icx + dx_max, icy + dy)
		}
	}
}

pub fn draw_tnt_barrel(renderer &Renderer, cx f64, cy f64, rad f64) {
	icx := int(cx)
	icy := int(cy)
	ir := int(rad)

	set_render_draw_color(renderer, 220, 40, 40, 255)
	render_fill_rect(renderer, &Rect{x: icx - ir, y: icy - ir, w: ir * 2, h: ir * 2})
	set_render_draw_color(renderer, 30, 30, 30, 255)
	render_draw_line(renderer, icx - ir, icy - ir / 2, icx + ir, icy - ir / 2)
	render_draw_line(renderer, icx - ir, icy + ir / 2, icx + ir, icy + ir / 2)
	draw_text_centered(renderer, icx, icy - 4, 'TNT', 1, Color{r: 255, g: 255, b: 255})
}

pub fn draw_mystery_bag(renderer &Renderer, cx f64, cy f64, rad f64) {
	icx := int(cx)
	icy := int(cy)
	ir := int(rad)

	set_render_draw_color(renderer, 175, 140, 95, 255)
	render_fill_rect(renderer, &Rect{x: icx - ir, y: icy - ir + 4, w: ir * 2, h: ir * 2 - 4})
	// Bag knot
	set_render_draw_color(renderer, 220, 50, 40, 255)
	render_fill_rect(renderer, &Rect{x: icx - 4, y: icy - ir, w: 8, h: 4})
	draw_text_centered(renderer, icx, icy - 4, '?', 1, Color{r: 40, g: 30, b: 20})
}

pub fn render_goldminer_game(renderer &Renderer, game &GoldMinerGame, win_w int, win_h int) {
	// Top Surface Sky
	set_render_draw_color(renderer, 100, 160, 220, 255)
	render_fill_rect(renderer, &Rect{x: 0, y: 0, w: win_w, h: int(surface_y)})

	// Underground Dirt Bed
	set_render_draw_color(renderer, 45, 30, 18, 255)
	render_fill_rect(renderer, &Rect{x: 0, y: int(surface_y), w: win_w, h: win_h - int(surface_y)})

	// Ground Surface Grass Line
	set_render_draw_color(renderer, 80, 160, 45, 255)
	render_fill_rect(renderer, &Rect{x: 0, y: int(surface_y) - 6, w: win_w, h: 6})

	// Dirt Texture flecks
	set_render_draw_color(renderer, 65, 45, 28, 255)
	for i := 0; i < 40; i++ {
		fx := (i * 97) % win_w
		fy := int(surface_y) + 20 + (i * 73) % (win_h - int(surface_y) - 40)
		render_fill_rect(renderer, &Rect{x: fx, y: fy, w: 6, h: 4})
	}

	// Draw Mine Items
	for item in game.items {
		if item.active {
			match item.@type {
				.gold_small, .gold_med, .gold_large {
					draw_gold_chunk(renderer, item.x, item.y, item.rad)
				}
				.diamond {
					draw_diamond(renderer, item.x, item.y, item.rad)
				}
				.rock_small, .rock_large {
					draw_rock(renderer, item.x, item.y, item.rad)
				}
				.tnt {
					draw_tnt_barrel(renderer, item.x, item.y, item.rad)
				}
				.mystery {
					draw_mystery_bag(renderer, item.x, item.y, item.rad)
				}
			}
		}
	}

	// Draw Miner in Cart
	miner_x := f64(win_w) / 2.0
	miner_y := surface_y - 20.0

	// Wooden Mine Cart
	set_render_draw_color(renderer, 110, 70, 35, 255)
	render_fill_rect(renderer, &Rect{x: int(miner_x) - 25, y: int(miner_y) - 10, w: 50, h: 22})
	set_render_draw_color(renderer, 60, 40, 20, 255)
	render_draw_rect(renderer, &Rect{x: int(miner_x) - 25, y: int(miner_y) - 10, w: 50, h: 22})

	// Miner Head & Straw Hat
	set_render_draw_color(renderer, 245, 215, 70, 255)
	render_fill_rect(renderer, &Rect{x: int(miner_x) - 14, y: int(miner_y) - 26, w: 28, h: 6})
	set_render_draw_color(renderer, 240, 180, 130, 255)
	render_fill_rect(renderer, &Rect{x: int(miner_x) - 8, y: int(miner_y) - 20, w: 16, h: 10})
	// White Miner Beard
	set_render_draw_color(renderer, 240, 240, 245, 255)
	render_fill_rect(renderer, &Rect{x: int(miner_x) - 6, y: int(miner_y) - 13, w: 12, h: 6})

	// Draw Claw Line and Hook Head
	tip_x := miner_x + math.sin(game.claw.angle) * game.claw.len
	tip_y := surface_y + math.cos(game.claw.angle) * game.claw.len

	// Taut Steel Cable
	set_render_draw_color(renderer, 200, 200, 210, 255)
	render_draw_line(renderer, int(miner_x), int(surface_y), int(tip_x), int(tip_y))

	// Mechanical Steel Claw Head
	set_render_draw_color(renderer, 180, 185, 195, 255)
	render_fill_rect(renderer, &Rect{x: int(tip_x) - 6, y: int(tip_y) - 6, w: 12, h: 12})
	// Pincer jaws
	render_draw_line(renderer, int(tip_x) - 6, int(tip_y) + 6, int(tip_x) - 10, int(tip_y) + 14)
	render_draw_line(renderer, int(tip_x) + 6, int(tip_y) + 6, int(tip_x) + 10, int(tip_y) + 14)

	// Top HUD
	// Money & Goal (Top Left)
	draw_text(renderer, 25, 16, 'MONEY: $${game.money}', 2, Color{r: 255, g: 215, b: 0})
	draw_text(renderer, 25, 42, 'GOAL:  $${game.target_money}', 2, Color{r: 255, g: 255, b: 255})

	// Title in Center
	draw_text_centered(renderer, win_w / 2, 16, 'GOLD MINER PRO', 2, Color{r: 255, g: 215, b: 0})
	draw_text_centered(renderer, win_w / 2, 42, 'LEVEL ${game.level}', 2, Color{r: 200, g: 230, b: 255})

	// Time & Dynamite (Top Right)
	time_col := if game.time_left <= 10.0 { Color{r: 255, g: 60, b: 60} } else { Color{r: 255, g: 255, b: 255} }
	draw_text(renderer, win_w - 210, 16, 'TIME: ${int(game.time_left)}s', 2, time_col)
	draw_text(renderer, win_w - 210, 42, 'DYNAMITE: ${game.dynamite_count}', 2, Color{r: 255, g: 110, b: 60})

	// Controls at bottom of screen
	draw_text_centered(renderer, win_w / 2, win_h - 22, '[DOWN/SPACE/CLICK] DROP CLAW  [UP/W] USE DYNAMITE  [R] RESTART  [F11] Fullscreen', 1, Color{r: 200, g: 180, b: 150})

	// Won Level / Game Over Modal
	if game.state == .won_level || game.state == .game_over {
		set_render_draw_color(renderer, 0, 0, 0, 190)
		render_fill_rect(renderer, &Rect{x: 0, y: 0, w: win_w, h: win_h})

		mx := (win_w - 440) / 2
		my := (win_h - 220) / 2
		modal_rect := Rect{x: mx, y: my, w: 440, h: 220}
		set_render_draw_color(renderer, 45, 30, 20, 255)
		render_fill_rect(renderer, &modal_rect)
		set_render_draw_color(renderer, 200, 150, 60, 255)
		render_draw_rect(renderer, &modal_rect)

		if game.state == .won_level {
			draw_text_centered(renderer, win_w / 2, my + 30, 'LEVEL COMPLETE!', 3, Color{r: 255, g: 215, b: 0})
			draw_text_centered(renderer, win_w / 2, my + 75, 'TARGET QUOTA ACHIEVED!', 2, Color{r: 80, g: 255, b: 120})
			draw_text_centered(renderer, win_w / 2, my + 120, 'TOTAL MONEY: $${game.money}', 2, Color{r: 255, g: 255, b: 255})
			draw_text_centered(renderer, win_w / 2, my + 165, 'PRESS [SPACE] FOR NEXT LEVEL', 2, Color{r: 140, g: 200, b: 255})
		} else {
			draw_text_centered(renderer, win_w / 2, my + 30, 'TIME EXPIRED!', 3, Color{r: 240, g: 60, b: 60})
			draw_text_centered(renderer, win_w / 2, my + 75, 'FAILED TO REACH $${game.target_money}', 2, Color{r: 220, g: 140, b: 140})
			draw_text_centered(renderer, win_w / 2, my + 120, 'FINAL HAUL: $${game.money}', 2, Color{r: 255, g: 255, b: 255})
			draw_text_centered(renderer, win_w / 2, my + 165, 'PRESS [SPACE] OR [R] TO RETRY', 2, Color{r: 140, g: 200, b: 255})
		}
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}
