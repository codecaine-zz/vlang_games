module main

import math

fn render_rain_game(renderer &Renderer, mut game RainGame) {
	theme := game.themes[game.theme_idx]

	// 1. Render Background
	set_render_draw_color(renderer, theme.bg_color.r, theme.bg_color.g, theme.bg_color.b, 255)
	render_clear(renderer)

	// 2. Lightning Screen Flash Effect
	if game.lightning_flash > 0.0 {
		flash_a := u8(game.lightning_flash * 180.0)
		set_render_draw_color(renderer, theme.lightning_color.r, theme.lightning_color.g, theme.lightning_color.b, flash_a)
		rect := Rect{x: 0, y: 0, w: game.screen_w, h: game.screen_h}
		render_fill_rect(renderer, &rect)

		// Lightning Bolt Line
		if game.lightning_flash > 0.4 {
			set_render_draw_color(renderer, 255, 255, 255, 255)
			mut bx := game.lightning_x
			mut by := 0.0
			for by < game.ground_y {
				next_x := bx + (f64((int(by * 13) % 41)) - 20.0)
				next_y := by + 30.0 + (f64((int(bx * 7) % 25)))
				render_draw_line(renderer, int(bx), int(by), int(next_x), int(next_y))
				render_draw_line(renderer, int(bx) + 1, int(by), int(next_x) + 1, int(next_y))
				bx = next_x
				by = next_y
			}
		}
	}

	// 3. Render Ground Puddles & Heightfield
	col_w := int(f64(game.screen_w) / f64(game.puddle_heights.len)) + 1
	ground_y_int := int(game.ground_y)

	// Base ground platform
	set_render_draw_color(renderer, 20, 25, 35, 255)
	ground_rect := Rect{x: 0, y: ground_y_int, w: game.screen_w, h: game.screen_h - ground_y_int}
	render_fill_rect(renderer, &ground_rect)

	// Puddle reflection water surface
	for col := 0; col < game.puddle_heights.len; col++ {
		h := game.puddle_heights[col]
		if h > 0.5 {
			px := col * col_w
			py := ground_y_int - int(h)
			p_rect := Rect{x: px, y: py, w: col_w, h: int(h) + (game.screen_h - ground_y_int)}
			set_render_draw_color(renderer, theme.puddle_color.r, theme.puddle_color.g, theme.puddle_color.b, theme.puddle_color.a)
			render_fill_rect(renderer, &p_rect)
		}
	}

	// 4. Render Ripples
	for i in 0 .. game.ripples.len {
		r := game.ripples[i]
		if !r.active { continue }
		set_render_draw_color(renderer, theme.splash_color.r, theme.splash_color.g, theme.splash_color.b, r.alpha)
		
		// Draw oval ring for 2D perspective wave
		cx := int(r.x)
		cy := int(r.y)
		rx := int(r.radius)
		ry := int(r.radius * 0.4)
		
		for ang := 0; ang < 360; ang += 30 {
			rad1 := f64(ang) * math.pi / 180.0
			rad2 := f64(ang + 30) * math.pi / 180.0
			x1 := cx + int(f64(rx) * math.cos(rad1))
			y1 := cy + int(f64(ry) * math.sin(rad1))
			x2 := cx + int(f64(rx) * math.cos(rad2))
			y2 := cy + int(f64(ry) * math.sin(rad2))
			render_draw_line(renderer, x1, y1, x2, y2)
		}
	}

	// 5. Render Target Zone / Shelter (Defense Mode)
	if game.mode == .defense {
		tz := game.target_zone
		tz_rect := Rect{x: int(tz.x), y: int(tz.y), w: int(tz.w), h: int(tz.h)}
		
		// Shelter roof & floor
		set_render_draw_color(renderer, 45, 55, 75, 255)
		render_fill_rect(renderer, &tz_rect)
		set_render_draw_color(renderer, 100, 140, 200, 255)
		render_draw_rect(renderer, &tz_rect)

		draw_text_centered(renderer, int(tz.x + tz.w * 0.5), int(tz.y + 10), tz.label, 1, Color{r: 255, g: 255, b: 255})

		// Wetness meter
		wet_color := if tz.wetness < 30.0 { Color{r: 80, g: 220, b: 100} } else if tz.wetness < 70.0 { Color{r: 240, g: 200, b: 60} } else { Color{r: 240, g: 60, b: 60} }
		draw_text_centered(renderer, int(tz.x + tz.w * 0.5), int(tz.y + 28), 'WET: ${int(tz.wetness)}%', 1, wet_color)
	}

	// 6. Render Umbrella Shield
	umb := game.umbrella
	ux := int(umb.x)
	uy := int(umb.y)
	half_w := int(umb.width * 0.5)

	// Canopy curve arc
	set_render_draw_color(renderer, 0, 220, 255, 255)
	for x_off := -half_w; x_off <= half_w; x_off++ {
		norm_x := f64(x_off) / f64(half_w)
		arch_y := math.sqrt(1.0 - norm_x * norm_x) * 22.0
		cur_y := uy - int(arch_y)
		render_draw_line(renderer, ux + x_off, cur_y, ux + x_off, cur_y + 4)
	}
	// Umbrella handle shaft
	set_render_draw_color(renderer, 200, 200, 200, 255)
	render_draw_line(renderer, ux, uy, ux, uy + 45)
	render_draw_line(renderer, ux + 1, uy, ux + 1, uy + 45)

	// 7. Render Rain Drops
	set_render_draw_color(renderer, theme.drop_color.r, theme.drop_color.g, theme.drop_color.b, theme.drop_color.a)
	
	// Adaptive rendering stride to maintain locked 60 FPS under heavy drop counts
	step := if game.drops.len > 50000 { game.drops.len / 6000 } else if game.drops.len > 12000 { 2 } else { 1 }

	for i := 0; i < game.drops.len; i += step {
		d := game.drops[i]
		if !d.active { continue }

		x1 := int(d.x)
		y1 := int(d.y)
		
		// Vector tail direction
		vx_norm := d.vx / (d.vy + 0.1)
		tail_x := x1 - int(vx_norm * d.length)
		tail_y := y1 - int(d.length)

		render_draw_line(renderer, x1, y1, tail_x, tail_y)
		if d.thickness > 1.5 && step < 3 {
			render_draw_line(renderer, x1 + 1, y1, tail_x + 1, tail_y)
		}
	}

	// 8. Render Splashes
	set_render_draw_color(renderer, theme.splash_color.r, theme.splash_color.g, theme.splash_color.b, theme.splash_color.a)
	for i in 0 .. game.splashes.len {
		s := game.splashes[i]
		if !s.active { continue }
		render_draw_line(renderer, int(s.x), int(s.y), int(s.x + s.vx * 0.04), int(s.y + s.vy * 0.04))
	}

	// 9. Cyberpunk Telemetry HUD Banner
	// Top Header
	hdr_rect := Rect{x: 10, y: 10, w: 480, h: 42}
	set_render_draw_color(renderer, 15, 22, 35, 230)
	render_fill_rect(renderer, &hdr_rect)
	set_render_draw_color(renderer, 0, 180, 255, 255)
	render_draw_rect(renderer, &hdr_rect)

	draw_text(renderer, 20, 18, 'MONSOON OVERDRIVE // BENCHMARK', 2, Color{r: 0, g: 240, b: 255})
	draw_text(renderer, 20, 36, 'THEME: ${theme.name.to_upper()} | MODE: ${game.mode}', 1, Color{r: 200, g: 220, b: 255})

	// Top Right Hardware Bench Telemetry Box
	bench_w := 420
	bench_rect := Rect{x: game.screen_w - bench_w - 10, y: 10, w: bench_w, h: 105}
	set_render_draw_color(renderer, 12, 18, 28, 230)
	render_fill_rect(renderer, &bench_rect)
	set_render_draw_color(renderer, 0, 255, 170, 255)
	render_draw_rect(renderer, &bench_rect)

	fps_color := if game.fps >= 55.0 { Color{r: 0, g: 255, b: 120} } else if game.fps >= 30.0 { Color{r: 255, g: 200, b: 0} } else { Color{r: 255, g: 60, b: 60} }
	draw_text(renderer, game.screen_w - bench_w, 18, 'M4 PERFORMANCE TELEMETRY', 1, Color{r: 0, g: 255, b: 170})
	draw_text(renderer, game.screen_w - bench_w, 34, 'FPS: ${int(game.fps)} (${game.frame_time_ms:.1f} ms)', 1, fps_color)
	draw_text(renderer, game.screen_w - bench_w, 48, 'ACTIVE PARTICLES : ${game.max_drops}', 1, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, game.screen_w - bench_w, 62, 'ALLOCATED RAM    : ${game.ram_allocated_mb} MB (${(f64(game.ram_allocated_mb)/1024.0):.1f} GB)', 1, Color{r: 255, g: 220, b: 100})
	draw_text(renderer, game.screen_w - bench_w, 76, 'THROUGHPUT       : ${(f64(game.total_processed)/1000000.0):.1f}M drops processed', 1, Color{r: 180, g: 200, b: 240})
	draw_text(renderer, game.screen_w - bench_w, 90, 'WIND FORCE       : ${game.wind_force:.1f} | INTENSITY: ${game.rain_intensity:.1f}x', 1, Color{r: 180, g: 200, b: 240})

	// Controls Panel (Bottom Left Overlay)
	ctrl_rect := Rect{x: 10, y: game.screen_h - 90, w: 580, h: 80}
	set_render_draw_color(renderer, 10, 15, 25, 220)
	render_fill_rect(renderer, &ctrl_rect)
	set_render_draw_color(renderer, 60, 90, 140, 255)
	render_draw_rect(renderer, &ctrl_rect)

	draw_text(renderer, 20, game.screen_h - 82, 'CONTROLS & SHORTCUTS:', 1, Color{r: 0, g: 220, b: 255})
	draw_text(renderer, 20, game.screen_h - 68, '[1-5] Rain Intensity Presets (Drizzle -> Typhoon -> M4 Armageddon)', 1, Color{r: 220, g: 230, b: 250})
	draw_text(renderer, 20, game.screen_h - 54, '[WASD/Arrows] Wind Force | [TAB] Weather Theme | [M] Sound | [B] Mode | F11: Fullscreen', 1, Color{r: 220, g: 230, b: 250})
	draw_text(renderer, 20, game.screen_h - 40, '[[] / []] or [- / +] Adjust Allocated RAM (64MB -> 32GB) | [Up/Dn] Drops', 1, Color{r: 255, g: 220, b: 100})
}
