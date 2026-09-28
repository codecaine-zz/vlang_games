module main

import math

pub fn render_scorched_game(renderer &Renderer, mut g ScorchedGame, win_w int, win_h int, mouse_x int, mouse_y int, sound_enabled bool) {
	tex := g.sprite_texture

	// 1. Dynamic Sky with Atmosphere & Sun
	set_render_draw_color(renderer, 20, 25, 45, 255)
	clear_rect := Rect{0, 0, win_w, win_h}
	render_fill_rect(renderer, &clear_rect)

	// Glowing Warm Sun
	draw_filled_circle(renderer, win_w - 120, 90, 32, Color{255, 215, 80, 255})
	draw_filled_circle(renderer, win_w - 120, 90, 42, Color{255, 180, 40, 70})

	// 2. Destructible Mountain & Dirt Terrain
	for x in 0 .. g.width {
		gy := g.terrain_y[x]
		// Grass top rim
		set_render_draw_color(renderer, 75, 175, 60, 255)
		render_draw_line(renderer, x, gy, x, gy + 3)

		// Soil / Dirt body
		set_render_draw_color(renderer, 130, 80, 45, 255)
		render_draw_line(renderer, x, gy + 4, x, gy + 30)

		// Deep bedrock
		set_render_draw_color(renderer, 85, 50, 30, 255)
		render_draw_line(renderer, x, gy + 31, x, win_h)
	}

	// 3. Draw Tanks (Live and Dead Wreckage)
	for i, t in g.tanks {
		render_tank(renderer, t, i == g.current_turn && !t.is_dead, tex)
	}

	// 4. Draw Projectiles & Vapor Trails
	for p in g.projectiles {
		// Vapor trail
		trail_col := if p.wtype == .baby_nuke { Color{255, 230, 80, 200} } else if p.is_napalm { Color{255, 100, 30, 220} } else { Color{220, 225, 235, 160} }
		set_render_draw_color(renderer, trail_col.r, trail_col.g, trail_col.b, 160)
		for t_i := 0; t_i < p.trail.len; t_i += 2 {
			tx := int(p.trail[t_i])
			ty := int(p.trail[t_i + 1])
			render_draw_point(renderer, tx, ty)
		}

		px := int(p.x)
		py := int(p.y)

		if tex != unsafe { nil } {
			mut src_x := 0
			mut src_y := 64
			mut src_sz := 32
			if p.is_napalm {
				src_x = 288
			} else if p.is_drilling {
				src_x = 336
			} else {
				src_x = match p.wtype {
					.standard { 0 }
					.baby_nuke { 48 }
					.mirv { if p.split_done { 144 } else { 96 } }
					.mountain_mover { 192 }
					.napalm { 240 }
					.digger { 336 }
				}
			}

			src := Rect{x: src_x, y: src_y, w: src_sz, h: src_sz}
			dst := Rect{x: px - 16, y: py - 16, w: 32, h: 32}
			angle_deg := if p.is_drilling { 90.0 } else { math.atan2(p.vy, p.vx) * 180.0 / math.pi }
			render_copy_ex(renderer, tex, &src, &dst, angle_deg, unsafe { nil }, RendererFlip.none)
		} else {
			head_col := if p.wtype == .baby_nuke { Color{255, 220, 50, 255} } else if p.is_napalm { Color{255, 100, 30, 255} } else { Color{255, 80, 40, 255} }
			draw_filled_circle(renderer, px, py, if p.wtype == .baby_nuke { 5 } else { 3 }, head_col)
		}
	}

	// 5. Draw Explosions
	for exp in g.explosions {
		cx := int(exp.x)
		cy := int(exp.y)
		r := int(exp.radius)
		prog := math.clamp(exp.life / exp.max_l, 0.0, 0.99)
		frame := int(prog * 4.0)

		if tex != unsafe { nil } && r > 2 {
			if exp.is_nuke {
				src := Rect{x: frame * 72, y: 192, w: 64, h: 64}
				dst := Rect{x: cx - r, y: cy - r, w: r * 2, h: r * 2}
				render_copy(renderer, tex, &src, &dst)
			} else {
				src := Rect{x: frame * 56, y: 128, w: 48, h: 48}
				dst := Rect{x: cx - r, y: cy - r, w: r * 2, h: r * 2}
				render_copy(renderer, tex, &src, &dst)
			}
		} else {
			draw_filled_circle(renderer, cx, cy, r, exp.col)
			draw_filled_circle(renderer, cx, cy, r / 2, Color{255, 255, 200, 255})
		}
	}

	// 6. Draw Floating Damage Numbers
	for dt_item in g.damage_texts {
		draw_text_centered(renderer, int(dt_item.x), int(dt_item.y), dt_item.text, 1, dt_item.col)
	}

	// 7. Top HUD & Wind Gauge
	render_top_hud(renderer, g, win_w, sound_enabled, tex)

	// 8. Bottom Artillery Dashboard
	if !g.in_shop {
		render_artillery_dashboard(renderer, g, win_w, win_h, tex)
	}

	// 9. Weapons Shop Overlay if active
	if g.in_shop {
		render_weapons_shop(renderer, g, win_w, win_h, mouse_x, mouse_y, tex)
	}

	// 10. Announcement Banner
	if g.banner_timer > 0.0 && g.banner_text != '' {
		bw := g.banner_text.len * 8 * 2 + 40
		bx := win_w / 2 - bw / 2
		by := 200

		set_render_draw_color(renderer, 20, 25, 35, 240)
		bg := Rect{bx, by, bw, 44}
		render_fill_rect(renderer, &bg)
		set_render_draw_color(renderer, 255, 215, 0, 255)
		render_draw_rect(renderer, &bg)

		draw_text_centered(renderer, win_w / 2, by + 14, g.banner_text, 2, Color{255, 230, 80, 255})
	}
}

fn render_tank(renderer &Renderer, t Tank, is_active bool, tex &Texture) {
	x := t.x
	y := t.y

	if tex != unsafe { nil } {
		if t.is_dead {
			src := Rect{x: 128, y: 0, w: 48, h: 32}
			dst := Rect{x: x - 24, y: y - 24, w: 48, h: 32}
			render_copy(renderer, tex, &src, &dst)
			draw_text_centered(renderer, x, y - 28, 'DESTROYED', 1, Color{255, 70, 50, 255})
			return
		}

		// Draw Barrel
		barrel_src := Rect{x: 192, y: 0, w: 24, h: 8}
		barrel_dst := Rect{x: x - 2, y: y - 16, w: 24, h: 8}
		pivot := Point{x: 2, y: 4}
		render_copy_ex(renderer, tex, &barrel_src, &barrel_dst, -t.angle, &pivot, RendererFlip.none)

		// Draw Tank Chassis
		chassis_src_x := if t.is_ai { 64 } else { 0 }
		src := Rect{x: chassis_src_x, y: 0, w: 48, h: 32}
		dst := Rect{x: x - 24, y: y - 24, w: 48, h: 32}
		render_copy(renderer, tex, &src, &dst)

		// Draw Shield Dome if active
		if t.has_shield {
			shield_src := Rect{x: 224, y: 0, w: 48, h: 48}
			shield_dst := Rect{x: x - 24, y: y - 32, w: 48, h: 48}
			render_copy(renderer, tex, &shield_src, &shield_dst)
		}
	} else {
		if t.is_dead {
			set_render_draw_color(renderer, 30, 30, 30, 255)
			wreck := Rect{x - 12, y - 4, 24, 5}
			render_fill_rect(renderer, &wreck)
			draw_text_centered(renderer, x, y - 18, 'DESTROYED', 1, Color{255, 70, 50, 255})
			return
		}

		// Treads
		set_render_draw_color(renderer, 40, 45, 50, 255)
		treads := Rect{x - 14, y - 5, 28, 6}
		render_fill_rect(renderer, &treads)

		// Hull
		set_render_draw_color(renderer, t.color.r, t.color.g, t.color.b, 255)
		hull := Rect{x - 10, y - 11, 20, 7}
		render_fill_rect(renderer, &hull)

		// Turret Dome
		draw_filled_circle(renderer, x, y - 11, 6, t.color)

		// Cannon Barrel
		rad := t.angle * math.pi / 180.0
		barrel_len := 16.0
		bx := x + int(math.cos(rad) * barrel_len)
		by := (y - 11) - int(math.sin(rad) * barrel_len)

		set_render_draw_color(renderer, 230, 230, 235, 255)
		for i in -1 .. 2 {
			render_draw_line(renderer, x + i, y - 11, bx + i, by)
		}
	}

	// Active turn indicator pointer
	if is_active {
		set_render_draw_color(renderer, 255, 220, 0, 255)
		draw_filled_circle(renderer, x, y - 42, 4, Color{255, 220, 0, 255})
	}

	// Tank Name & Numeric Health Bar
	draw_text_centered(renderer, x, y - 52, t.name, 1, Color{240, 240, 240, 255})
	draw_text_centered(renderer, x, y - 36, '${t.health}/100 HP', 1, if t.health > 50 { Color{100, 255, 120, 255} } else { Color{255, 120, 60, 255} })

	set_render_draw_color(renderer, 180, 30, 30, 255)
	hp_bg := Rect{x - 16, y - 26, 32, 4}
	render_fill_rect(renderer, &hp_bg)

	hp_w := int(32.0 * (f64(t.health) / 100.0))
	if hp_w > 0 {
		set_render_draw_color(renderer, if t.health > 50 { u8(50) } else { u8(240) }, if t.health > 50 { u8(220) } else { u8(180) }, 60, 255)
		hp_bar := Rect{x - 16, y - 26, hp_w, 4}
		render_fill_rect(renderer, &hp_bar)
	}
}

fn render_top_hud(renderer &Renderer, g ScorchedGame, win_w int, sound_enabled bool, tex &Texture) {
	set_render_draw_color(renderer, 15, 20, 30, 220)
	bar := Rect{0, 0, win_w, 42}
	render_fill_rect(renderer, &bar)

	set_render_draw_color(renderer, 180, 140, 30, 255)
	render_draw_line(renderer, 0, 41, win_w, 41)

	// Title & Round
	draw_text(renderer, 20, 14, '★ SCORCHED EARTH DELUXE ★', 1, Color{255, 215, 0, 255})
	draw_text(renderer, 240, 14, 'ROUND: ${g.round}/${g.max_rounds}', 1, Color{240, 240, 240, 255})

	// Wind Indicator
	wind_str := if g.wind >= 0 { 'WIND: +${int(g.wind)} MPH >>' } else { 'WIND: << ${int(g.wind)} MPH' }
	wind_col := if g.wind >= 0 { Color{100, 220, 255, 255} } else { Color{255, 140, 100, 255} }
	draw_text(renderer, 380, 14, wind_str, 1, wind_col)

	// Player Cash & Kills
	if tex != unsafe { nil } {
		cash_src := Rect{x: 336, y: 256, w: 32, h: 32}
		cash_dst := Rect{x: 575, y: 10, w: 20, h: 20}
		render_copy(renderer, tex, &cash_src, &cash_dst)
	}
	draw_text(renderer, 600, 14, '$${g.tanks[0].cash}', 1, Color{100, 255, 140, 255})
	draw_text(renderer, 710, 14, 'KILLS: ${g.tanks[0].kills}', 1, Color{255, 200, 80, 255})

	// Sound toggle badge
	sound_x := win_w - 110
	if sound_enabled {
		set_render_draw_color(renderer, 40, 120, 60, 255)
		btn := Rect{sound_x, 8, 95, 24}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 47, 13, 'SOUND: ON', 1, Color{255, 255, 255, 255})
	} else {
		set_render_draw_color(renderer, 120, 35, 40, 255)
		btn := Rect{sound_x, 8, 95, 24}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 47, 13, 'MUTED [M]', 1, Color{255, 180, 180, 255})
	}
}

fn render_artillery_dashboard(renderer &Renderer, g ScorchedGame, win_w int, win_h int, tex &Texture) {
	cur := g.tanks[g.current_turn]
	info := get_weapon_info(cur.active_wep)

	set_render_draw_color(renderer, 15, 20, 32, 230)
	dash := Rect{0, win_h - 55, win_w, 55}
	render_fill_rect(renderer, &dash)

	set_render_draw_color(renderer, 180, 140, 30, 255)
	render_draw_line(renderer, 0, win_h - 55, win_w, win_h - 55)

	// Angle & Power Controls
	draw_text(renderer, 20, win_h - 40, 'ANGLE: ${int(cur.angle)}° [A/D]', 1, Color{255, 220, 80, 255})
	draw_text(renderer, 180, win_h - 40, 'POWER: ${int(cur.power)} [W/S]', 1, Color{255, 220, 80, 255})

	// Weapon Icon Badge & Info
	if tex != unsafe { nil } {
		badge_idx := match cur.active_wep {
			.standard { 0 }
			.baby_nuke { 1 }
			.mirv { 2 }
			.mountain_mover { 3 }
			.napalm { 4 }
			.digger { 5 }
		}
		badge_src := Rect{x: badge_idx * 56, y: 256, w: 48, h: 48}
		badge_dst := Rect{x: 340, y: win_h - 50, w: 42, h: 42}
		render_copy(renderer, tex, &badge_src, &badge_dst)
	}

	ammo := if cur.active_wep == .standard { 'INF' } else { '${cur.inventory[cur.active_wep.str()]}' }
	draw_text(renderer, 395, win_h - 40, 'WEAPON [TAB/1-6]: ${info.name.to_upper()} (AMMO: ${ammo})', 1, Color{100, 240, 255, 255})

	// Fire Action
	if !cur.is_ai {
		draw_text(renderer, win_w - 200, win_h - 40, '[SPACE] FIRE CANNON', 1, Color{50, 255, 120, 255})
	} else {
		draw_text(renderer, win_w - 200, win_h - 40, 'BOT IS AIMING...', 1, Color{255, 160, 80, 255})
	}
}

fn render_weapons_shop(renderer &Renderer, g ScorchedGame, win_w int, win_h int, _ int, _ int, tex &Texture) {
	// Dark modal overlay
	set_render_draw_color(renderer, 5, 10, 18, 230)
	modal := Rect{80, 60, win_w - 160, win_h - 120}
	render_fill_rect(renderer, &modal)

	set_render_draw_color(renderer, 255, 215, 0, 255)
	render_draw_rect(renderer, &modal)

	draw_text_centered(renderer, win_w / 2, 85, '★ ARSENAL WEAPONS SHOP ★', 2, Color{255, 215, 0, 255})
	draw_text_centered(renderer, win_w / 2, 120, 'YOUR CASH: $${g.tanks[0].cash}  |  PREPARE FOR ROUND ${g.round}', 1, Color{100, 255, 140, 255})

	w_list := [
		WeaponType.baby_nuke,
		WeaponType.mirv,
		WeaponType.mountain_mover,
		WeaponType.napalm,
		WeaponType.digger,
	]

	mut row_y := 160
	for i, w in w_list {
		info := get_weapon_info(w)
		owned := g.tanks[0].inventory[w.str()]

		set_render_draw_color(renderer, 25, 35, 50, 255)
		item_r := Rect{110, row_y, win_w - 220, 48}
		render_fill_rect(renderer, &item_r)
		set_render_draw_color(renderer, 60, 80, 110, 255)
		render_draw_rect(renderer, &item_r)

		if tex != unsafe { nil } {
			badge_idx := i + 1 // nuke..digger
			badge_src := Rect{x: badge_idx * 56, y: 256, w: 48, h: 48}
			badge_dst := Rect{x: 115, y: row_y + 4, w: 40, h: 40}
			render_copy(renderer, tex, &badge_src, &badge_dst)
		}

		draw_text(renderer, 165, row_y + 10, '${i + 1}. ${info.name}', 1, Color{255, 230, 80, 255})
		draw_text(renderer, 165, row_y + 26, info.desc, 1, Color{180, 190, 200, 255})
		draw_text(renderer, 500, row_y + 18, 'COST: $${info.cost}', 1, Color{100, 255, 140, 255})
		draw_text(renderer, 620, row_y + 18, 'OWNED: ${owned}', 1, Color{200, 220, 255, 255})

		// Buy button
		set_render_draw_color(renderer, 40, 120, 60, 255)
		buy_btn := Rect{win_w - 200, row_y + 10, 75, 28}
		render_fill_rect(renderer, &buy_btn)
		draw_text_centered(renderer, win_w - 162, row_y + 18, 'BUY [${i + 1}]', 1, Color{255, 255, 255, 255})

		row_y += 58
	}

	draw_text_centered(renderer, win_w / 2, win_h - 100, 'PRESS [SPACE] TO COMMENCE NEXT ROUND', 1, Color{255, 255, 255, 255})
}
