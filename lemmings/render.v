module main

import math


pub fn render_lemmings_game(renderer &Renderer, g LemmingsGame, win_w int, win_h int, mouse_x int, mouse_y int, sound_enabled bool) {
	// Background Sky / Underground
	set_render_draw_color(renderer, 10, 15, 25, 255)
	render_clear(renderer)

	scale := 2
	play_y_offset := 40

	// 1. Render Destructible Terrain (Batched vertical spans)
	for x in 0 .. map_w {
		mut y := 0
		for y < map_h {
			if g.terrain[x][y] {
				start_y := y
				for y < map_h && g.terrain[x][y] {
					y++
				}
				// Grass edge on top if exposed
				if start_y == 0 || !g.terrain[x][start_y - 1] {
					set_render_draw_color(renderer, 60, 180, 70, 255) // Grass edge
					grass_r := Rect{x * scale, play_y_offset + start_y * scale, scale, scale}
					render_fill_rect(renderer, &grass_r)

					if y > start_y + 1 {
						dirt_h := (y - (start_y + 1)) * scale
						set_render_draw_color(renderer, 130, 85, 45, 255) // Dirt
						dirt_r := Rect{x * scale, play_y_offset + (start_y + 1) * scale, scale, dirt_h}
						render_fill_rect(renderer, &dirt_r)
					}
				} else {
					dirt_h := (y - start_y) * scale
					set_render_draw_color(renderer, 130, 85, 45, 255) // Dirt
					dirt_r := Rect{x * scale, play_y_offset + start_y * scale, scale, dirt_h}
					render_fill_rect(renderer, &dirt_r)
				}
			} else {
				y++
			}
		}
	}

	// 2. Render Spawn Hatch
	lvl := g.levels[g.level_idx]
	hx := lvl.spawn_x * scale
	hy := play_y_offset + lvl.spawn_y * scale
	set_render_draw_color(renderer, 90, 95, 110, 255)
	hatch_r := Rect{hx - 14, hy - 14, 28, 14}
	render_fill_rect(renderer, &hatch_r)
	set_render_draw_color(renderer, 240, 200, 50, 255)
	render_draw_rect(renderer, &hatch_r)
	draw_text_centered(renderer, hx, hy - 8, 'HATCH', 1, Color{255, 255, 255, 255})

	// 3. Render Exit Portal
	ex := lvl.exit_x * scale
	ey := play_y_offset + lvl.exit_y * scale
	set_render_draw_color(renderer, 60, 30, 120, 255)
	exit_base := Rect{ex - 16, ey - 28, 32, 28}
	render_fill_rect(renderer, &exit_base)
	set_render_draw_color(renderer, 180, 80, 255, 255)
	render_draw_rect(renderer, &exit_base)
	draw_text_centered(renderer, ex, ey - 16, 'EXIT', 1, Color{240, 220, 255, 255})

	// 4. Find closest lemming for mouse hover targeting
	mut closest_lem_idx := -1
	mut min_dist := 35.0
	if mouse_y >= 40 && mouse_y < win_h - 70 {
		for i, lem in g.lemmings {
			if lem.state != .dead && lem.state != .exiting {
				lx := f64(int(lem.x) * scale)
				ly := f64(play_y_offset + int(lem.y) * scale)
				dist := math.sqrt(f64((mouse_x - int(lx)) * (mouse_x - int(lx)) + (mouse_y - int(ly)) * (mouse_y - int(ly))))
				if dist < min_dist {
					min_dist = dist
					closest_lem_idx = i
				}
			}
		}
	}

	// 5. Render Lemmings
	for i, lem in g.lemmings {
		if lem.state == .dead || lem.state == .exiting {
			continue
		}

		lx := int(lem.x) * scale
		ly := play_y_offset + int(lem.y) * scale

		// Highlight hovered target lemming
		if i == closest_lem_idx {
			set_render_draw_color(renderer, 255, 255, 0, 180)
			ring := Rect{lx - 12, ly - 20, 24, 26}
			render_draw_rect(renderer, &ring)
			draw_text_centered(renderer, lx, ly - 28, g.selected_skill.str().to_upper(), 1, Color{255, 255, 50, 255})
		}

		// Blue Tunic Body
		set_render_draw_color(renderer, 40, 70, 220, 255)
		body := Rect{lx - 3, ly - 10, 6, 10}
		render_fill_rect(renderer, &body)

		// Bright Green Hair
		set_render_draw_color(renderer, 60, 240, 60, 255)
		hair := Rect{lx - 3, ly - 14, 6, 5}
		render_fill_rect(renderer, &hair)

		// Floater Umbrella Sprite
		if lem.state == .floating {
			set_render_draw_color(renderer, 255, 220, 50, 255)
			umb := Rect{lx - 7, ly - 22, 14, 6}
			render_fill_rect(renderer, &umb)
		}

		// Bomber Countdown text
		if lem.countdown > 0.0 {
			num_str := '${int(lem.countdown) + 1}'
			draw_text_centered(renderer, lx, ly - 20, num_str, 1, Color{255, 220, 0, 255})
		}
	}

	// 6. Top Header Status Bar
	render_top_bar(renderer, g, win_w, mouse_x, mouse_y, sound_enabled)

	// 7. Bottom Skill Selector Panel
	render_skill_panel(renderer, g, win_w, win_h, mouse_x, mouse_y)

	// 8. Center Announcement Banner
	if g.banner_timer > 0.0 && g.banner_text != '' {
		bw := g.banner_text.len * 8 * 2 + 40
		bx := win_w / 2 - bw / 2
		by := 240

		set_render_draw_color(renderer, 15, 20, 30, 240)
		bg := Rect{bx, by, bw, 44}
		render_fill_rect(renderer, &bg)
		set_render_draw_color(renderer, 80, 240, 100, 255)
		render_draw_rect(renderer, &bg)

		draw_text_centered(renderer, win_w / 2, by + 14, g.banner_text, 2, Color{255, 240, 100, 255})
	}
}

fn render_top_bar(renderer &Renderer, g LemmingsGame, win_w int, mouse_x int, mouse_y int, sound_enabled bool) {
	set_render_draw_color(renderer, 15, 22, 35, 255)
	bar := Rect{0, 0, win_w, 40}
	render_fill_rect(renderer, &bar)

	set_render_draw_color(renderer, 70, 120, 160, 255)
	render_draw_line(renderer, 0, 39, win_w, 39)

	lvl := g.levels[g.level_idx]
	draw_text(renderer, 16, 14, lvl.name.to_upper(), 1, Color{255, 220, 80, 255})

	// Stats
	draw_text(renderer, 200, 14, 'OUT: ${g.spawned_count}/${lvl.total_lems}', 1, Color{200, 230, 255, 255})
	draw_text(renderer, 330, 14, 'SAVED: ${g.saved_count} (NEED ${lvl.target_save})', 1, Color{100, 255, 140, 255})
	draw_text(renderer, 480, 14, 'TIME: ${int(math.max(0.0, g.time_remaining))}S', 1, Color{255, 200, 120, 255})

	// Top Action Buttons
	// Restart Button
	rst_x := win_w - 330
	rst_hover := mouse_x >= rst_x && mouse_x <= rst_x + 80 && mouse_y >= 8 && mouse_y <= 32
	set_render_draw_color(renderer, if rst_hover { u8(70) } else { u8(45) }, 55, 80, 255)
	rst_btn := Rect{rst_x, 8, 80, 24}
	render_fill_rect(renderer, &rst_btn)
	draw_text_centered(renderer, rst_x + 40, 13, 'RESET [R]', 1, Color{230, 230, 230, 255})

	// Next Level Button
	nxt_x := win_w - 240
	nxt_hover := mouse_x >= nxt_x && mouse_x <= nxt_x + 85 && mouse_y >= 8 && mouse_y <= 32
	set_render_draw_color(renderer, if nxt_hover { u8(60) } else { u8(40) }, 75, 110, 255)
	nxt_btn := Rect{nxt_x, 8, 85, 24}
	render_fill_rect(renderer, &nxt_btn)
	draw_text_centered(renderer, nxt_x + 42, 13, 'NEXT [N]', 1, Color{230, 230, 230, 255})

	// Sound toggle badge
	sound_x := win_w - 145
	snd_hover := mouse_x >= sound_x && mouse_x <= sound_x + 130 && mouse_y >= 8 && mouse_y <= 32
	if sound_enabled {
		set_render_draw_color(renderer, if snd_hover { u8(55) } else { u8(40) }, 130, 65, 255)
		btn := Rect{sound_x, 8, 130, 24}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 65, 13, 'SOUND: ON [M]', 1, Color{255, 255, 255, 255})
	} else {
		set_render_draw_color(renderer, if snd_hover { u8(145) } else { u8(120) }, 40, 45, 255)
		btn := Rect{sound_x, 8, 130, 24}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 65, 13, 'MUTED [M]', 1, Color{255, 180, 180, 255})
	}
}

fn render_skill_panel(renderer &Renderer, g LemmingsGame, win_w int, win_h int, mouse_x int, mouse_y int) {
	panel_h := 70
	panel_y := win_h - panel_h

	set_render_draw_color(renderer, 20, 25, 38, 255)
	bar := Rect{0, panel_y, win_w, panel_h}
	render_fill_rect(renderer, &bar)

	set_render_draw_color(renderer, 60, 80, 110, 255)
	render_draw_line(renderer, 0, panel_y, win_w, panel_y)

	skills := [
		Skill.climber,
		Skill.floater,
		Skill.bomber,
		Skill.blocker,
		Skill.builder,
		Skill.basher,
		Skill.miner,
		Skill.digger,
	]
	skill_names := ['1:CLIMB', '2:FLOAT', '3:BOMB', '4:BLOCK', '5:BUILD', '6:BASH', '7:MINE', '8:DIG']
	lvl := g.levels[g.level_idx]

	mut sx := 15
	for i, s in skills {
		is_selected := g.selected_skill == s
		qty := lvl.skills[s.str()]
		hover := mouse_x >= sx && mouse_x <= sx + 72 && mouse_y >= panel_y + 10 && mouse_y <= panel_y + 58

		if is_selected {
			set_render_draw_color(renderer, 255, 215, 0, 255)
			btn := Rect{sx, panel_y + 10, 72, 48}
			render_fill_rect(renderer, &btn)
			draw_text_centered(renderer, sx + 36, panel_y + 18, skill_names[i], 1, Color{30, 20, 10, 255})
			draw_text_centered(renderer, sx + 36, panel_y + 36, '${qty}', 1, Color{30, 20, 10, 255})
		} else {
			set_render_draw_color(renderer, if hover { u8(55) } else { u8(35) }, if hover { u8(70) } else { u8(45) }, if hover { u8(95) } else { u8(65) }, 255)
			btn := Rect{sx, panel_y + 10, 72, 48}
			render_fill_rect(renderer, &btn)
			draw_text_centered(renderer, sx + 36, panel_y + 18, skill_names[i], 1, Color{220, 220, 220, 255})
			draw_text_centered(renderer, sx + 36, panel_y + 36, '${qty}', 1, Color{100, 220, 255, 255})
		}
		sx += 76
	}

	// Speed & Armageddon Controls
	// Pause Button
	pause_col := if g.is_paused { Color{255, 220, 50, 255} } else { Color{40, 60, 80, 255} }
	p_hover := mouse_x >= sx + 8 && mouse_x <= sx + 78 && mouse_y >= panel_y + 10 && mouse_y <= panel_y + 58
	set_render_draw_color(renderer, if p_hover { u8(65) } else { pause_col.r }, if p_hover { u8(90) } else { pause_col.g }, if p_hover { u8(120) } else { pause_col.b }, 255)
	p_btn := Rect{sx + 8, panel_y + 10, 70, 48}
	render_fill_rect(renderer, &p_btn)
	draw_text_centered(renderer, sx + 43, panel_y + 26, if g.is_paused { 'RESUME [P]' } else { 'PAUSE [P]' }, 1, if g.is_paused { Color{30, 20, 10, 255} } else { Color{255, 255, 255, 255} })

	// Fast Forward Button
	spd_str := '${int(g.game_speed)}X [F]'
	f_hover := mouse_x >= sx + 84 && mouse_x <= sx + 149 && mouse_y >= panel_y + 10 && mouse_y <= panel_y + 58
	set_render_draw_color(renderer, if f_hover { u8(60) } else { u8(40) }, if f_hover { u8(100) } else { u8(70) }, if f_hover { u8(140) } else { u8(100) }, 255)
	f_btn := Rect{sx + 84, panel_y + 10, 65, 48}
	render_fill_rect(renderer, &f_btn)
	draw_text_centered(renderer, sx + 116, panel_y + 26, spd_str, 1, Color{255, 255, 255, 255})

	// NUKE / Armageddon Button
	n_hover := mouse_x >= sx + 155 && mouse_x <= sx + 235 && mouse_y >= panel_y + 10 && mouse_y <= panel_y + 58
	set_render_draw_color(renderer, if n_hover { u8(200) } else { u8(160) }, if n_hover { u8(50) } else { u8(35) }, if n_hover { u8(55) } else { u8(40) }, 255)
	n_btn := Rect{sx + 155, panel_y + 10, 80, 48}
	render_fill_rect(renderer, &n_btn)
	draw_text_centered(renderer, sx + 195, panel_y + 26, 'NUKE [X]', 1, Color{255, 255, 255, 255})
}
