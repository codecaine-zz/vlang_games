module main

import math

pub fn render_tamagotchi(renderer &Renderer, game &TamagotchiGame, screen_w int, screen_h int) {
	// 1. Cozy Retro Desktop Background
	set_render_draw_color(renderer, 32, 38, 54, 255)
	render_clear(renderer)

	// Wood desk lines
	set_render_draw_color(renderer, 24, 28, 42, 255)
	for y := 0; y < screen_h; y += 40 {
		render_draw_line(renderer, 0, y, screen_w, y)
	}

	// 2. Keychain Egg Shell
	cx := screen_w / 2
	cy := screen_h / 2 - 20
	draw_keychain_shell(renderer, cx, cy)

	// 3. LCD Screen
	lcd_w := 340
	lcd_h := 220
	lcd_x := cx - lcd_w / 2
	lcd_y := cy - lcd_h / 2 - 25

	draw_lcd_screen(renderer, game, lcd_x, lcd_y, lcd_w, lcd_h)

	// 4. Physical Rubber Buttons
	draw_physical_buttons(renderer, cx, cy + 130)

	// 5. Controls Overlay Bar
	draw_controls_bar(renderer, screen_w, screen_h, game)
}

fn draw_keychain_shell(renderer &Renderer, cx int, cy int) {
	// Keychain metal loop at top
	draw_filled_circle(renderer, cx, cy - 220, 24, Color{ r: 180, g: 190, b: 205 })
	draw_filled_circle(renderer, cx, cy - 220, 14, Color{ r: 32, g: 38, b: 54 })

	// Egg Shell Outer Drop Shadow
	draw_filled_ellipse(renderer, cx + 8, cy + 10, 230, 260, Color{ r: 10, g: 12, b: 20, a: 160 })

	// Primary Coral/Teal Plastic Shell Body
	draw_filled_ellipse(renderer, cx, cy, 225, 255, Color{ r: 255, g: 110, b: 140 })
	draw_filled_ellipse(renderer, cx, cy - 5, 215, 245, Color{ r: 255, g: 130, b: 155 })

	// Front Plastic Bezel
	draw_filled_ellipse(renderer, cx, cy - 25, 195, 160, Color{ r: 245, g: 235, b: 220 })
	draw_filled_ellipse(renderer, cx, cy - 25, 185, 150, Color{ r: 225, g: 215, b: 200 })

	// 1996 Tamagotchi Brand Logo
	draw_text_centered(renderer, cx, cy - 165, 'TAMAGOTCHI', 2, Color{ r: 255, g: 245, b: 220 })
}

fn draw_lcd_screen(renderer &Renderer, game &TamagotchiGame, x int, y int, w int, h int) {
	// LCD Plastic Bezel with Inset Shadow
	set_render_draw_color(renderer, 50, 55, 65, 255)
	bezel := Rect{ x: x - 8, y: y - 8, w: w + 16, h: h + 16 }
	render_fill_rect(renderer, &bezel)

	// Authentic Grey-Green Dot Matrix LCD Background
	set_render_draw_color(renderer, 155, 175, 140, 255)
	screen_rect := Rect{ x: x, y: y, w: w, h: h }
	render_fill_rect(renderer, &screen_rect)

	// Faint LCD Pixel Grid
	set_render_draw_color(renderer, 145, 165, 130, 255)
	for gy := y + 4; gy < y + h - 4; gy += 10 {
		render_draw_line(renderer, x + 4, gy, x + w - 4, gy)
	}
	for gx := x + 4; gx < x + w - 4; gx += 10 {
		render_draw_line(renderer, gx, y + 4, gx, y + h - 4)
	}

	// 1. Top Icons Bar (Food, Light, Game, Medicine)
	draw_top_icon_bar(renderer, game, x + 10, y + 8, w - 20)

	// 2. Center Screen: Pet or Stats or Action
	if game.active_action == .view_stats {
		draw_stats_screen(renderer, game, x + 16, y + 44)
	} else {
		draw_main_pet_display(renderer, game, x, y + 36, w, h - 72)
	}

	// 3. Bottom Icons Bar (Bath, Stats, Discipline, Alert)
	draw_bottom_icon_bar(renderer, game, x + 10, y + h - 30, w - 20)

	// 4. In-Game Dialog Message Ribbon
	if game.dialog_msg != '' {
		box_w := w - 24
		box_h := 22
		bx := x + 12
		by := y + h - 56
		b_rect := Rect{ x: bx, y: by, w: box_w, h: box_h }
		set_render_draw_color(renderer, 45, 52, 40, 240)
		render_fill_rect(renderer, &b_rect)
		draw_text_centered(renderer, x + w / 2, by + 7, game.dialog_msg, 1, Color{ r: 165, g: 190, b: 150 })
	}
}

fn draw_top_icon_bar(renderer &Renderer, game &TamagotchiGame, x int, y int, w int) {
	icon_spacing := w / 4
	icons := ['[MEAL]', '[LIGHT]', '[GAME]', '[MEDICINE]']

	for i := 0; i < 4; i++ {
		ix := x + i * icon_spacing + icon_spacing / 2
		is_sel := game.selected_icon == i

		if is_sel {
			// Inverted highlight
			box := Rect{ x: ix - 32, y: y, w: 64, h: 20 }
			set_render_draw_color(renderer, 35, 42, 30, 255)
			render_fill_rect(renderer, &box)
			draw_text_centered(renderer, ix, y + 6, icons[i], 1, Color{ r: 165, g: 185, b: 150 })
		} else {
			draw_text_centered(renderer, ix, y + 6, icons[i], 1, Color{ r: 35, g: 42, b: 30 })
		}
	}
}

fn draw_bottom_icon_bar(renderer &Renderer, game &TamagotchiGame, x int, y int, w int) {
	icon_spacing := w / 4
	icons := ['[BATH]', '[STATS]', '[DISC]', '[ALERT]']

	for i := 0; i < 4; i++ {
		ix := x + i * icon_spacing + icon_spacing / 2
		icon_idx := i + 4
		is_sel := game.selected_icon == icon_idx
		is_alert := icon_idx == 7 && game.attention_needed

		if is_sel || is_alert {
			box := Rect{ x: ix - 32, y: y, w: 64, h: 20 }
			set_render_draw_color(renderer, 35, 42, 30, 255)
			render_fill_rect(renderer, &box)
			draw_text_centered(renderer, ix, y + 6, icons[i], 1, Color{ r: 165, g: 185, b: 150 })
		} else {
			draw_text_centered(renderer, ix, y + 6, icons[i], 1, Color{ r: 35, g: 42, b: 30 })
		}
	}
}

fn draw_main_pet_display(renderer &Renderer, game &TamagotchiGame, x int, y int, w int, h int) {
	cx := x + w / 2
	cy := y + h / 2

	if game.is_sleeping {
		// Sleeping Zzz animation
		draw_pet_sprite(renderer, game.stage, cx, cy + 10, game.frame_idx)
		draw_text(renderer, cx + 40, cy - 25, 'Z z z . .', 2, Color{ r: 35, g: 42, b: 30 })
		return
	}

	// Active Pet sprite
	px := x + 60 + game.pet_x * 8
	draw_pet_sprite(renderer, game.stage, px, cy, game.frame_idx)

	// Poop piles on the right
	for p := 0; p < game.poop_count; p++ {
		poop_x := x + w - 50 - p * 30
		draw_poop_sprite(renderer, poop_x, cy + 20)
	}

	// Sick skull icon
	if game.is_sick {
		draw_text(renderer, px + 35, cy - 30, '☠ SICK', 1, Color{ r: 35, g: 42, b: 30 })
	}
}

fn draw_stats_screen(renderer &Renderer, game &TamagotchiGame, x int, y int) {
	col := Color{ r: 35, g: 42, b: 30 }

	draw_text(renderer, x, y, 'NAME: ${game.name}', 1, col)
	draw_text(renderer, x + 160, y, 'AGE: ${game.age_days} DAYS', 1, col)
	draw_text(renderer, x, y + 20, 'WEIGHT: ${game.weight_oz} OZ', 1, col)

	// Hunger hearts
	draw_text(renderer, x, y + 42, 'HUNGER:', 1, col)
	for h := 0; h < 4; h++ {
		heart_str := if h < game.hunger { '♥' } else { '♡' }
		draw_text(renderer, x + 85 + h * 22, y + 42, heart_str, 1, col)
	}

	// Happiness hearts
	draw_text(renderer, x, y + 64, 'HAPPY: ', 1, col)
	for h := 0; h < 4; h++ {
		heart_str := if h < game.happiness { '♥' } else { '♡' }
		draw_text(renderer, x + 85 + h * 22, y + 64, heart_str, 1, col)
	}

	// Discipline bar
	draw_text(renderer, x, y + 86, 'DISCIPLINE: ${game.discipline}%', 1, col)
}

fn draw_pet_sprite(renderer &Renderer, stage PetStage, cx int, cy int, frame int) {
	bounce := int(math.sin(f64(frame) * math.pi * 0.5) * 3.0)
	py := cy + bounce

	match stage {
		.egg {
			draw_filled_ellipse(renderer, cx, py, 20, 26, Color{ r: 35, g: 42, b: 30 })
		}
		.baby {
			// Round blob with animated feet
			draw_filled_ellipse(renderer, cx, py, 18, 16, Color{ r: 35, g: 42, b: 30 })
			// Eyes
			draw_filled_circle(renderer, cx - 6, py - 4, 3, Color{ r: 155, g: 175, b: 140 })
			draw_filled_circle(renderer, cx + 6, py - 4, 3, Color{ r: 155, g: 175, b: 140 })
			// Feet
			f_off := if frame % 2 == 0 { 2 } else { -2 }
			draw_filled_circle(renderer, cx - 10 + f_off, py + 16, 4, Color{ r: 35, g: 42, b: 30 })
			draw_filled_circle(renderer, cx + 10 - f_off, py + 16, 4, Color{ r: 35, g: 42, b: 30 })
		}
		.child {
			// Taller creature with ears
			draw_filled_ellipse(renderer, cx, py, 22, 20, Color{ r: 35, g: 42, b: 30 })
			draw_filled_circle(renderer, cx - 12, py - 18, 6, Color{ r: 35, g: 42, b: 30 })
			draw_filled_circle(renderer, cx + 12, py - 18, 6, Color{ r: 35, g: 42, b: 30 })
			// Eyes
			draw_filled_circle(renderer, cx - 7, py - 4, 3, Color{ r: 155, g: 175, b: 140 })
			draw_filled_circle(renderer, cx + 7, py - 4, 3, Color{ r: 155, g: 175, b: 140 })
		}
		.teen, .adult {
			// Mametchi iconic rounded cap with ears
			draw_filled_ellipse(renderer, cx, py, 26, 24, Color{ r: 35, g: 42, b: 30 })
			draw_filled_circle(renderer, cx - 14, py - 22, 8, Color{ r: 35, g: 42, b: 30 })
			draw_filled_circle(renderer, cx + 14, py - 22, 8, Color{ r: 35, g: 42, b: 30 })
			// White face mask
			draw_filled_ellipse(renderer, cx, py + 2, 18, 14, Color{ r: 155, g: 175, b: 140 })
			// Dark pupils
			draw_filled_circle(renderer, cx - 7, py, 3, Color{ r: 35, g: 42, b: 30 })
			draw_filled_circle(renderer, cx + 7, py, 3, Color{ r: 35, g: 42, b: 30 })
			// Smile
			set_render_draw_color(renderer, 35, 42, 30, 255)
			render_draw_line(renderer, cx - 4, py + 8, cx + 4, py + 8)
		}
	}
}

fn draw_poop_sprite(renderer &Renderer, x int, y int) {
	draw_filled_ellipse(renderer, x, y, 10, 6, Color{ r: 35, g: 42, b: 30 })
	draw_filled_ellipse(renderer, x, y - 6, 6, 4, Color{ r: 35, g: 42, b: 30 })
	draw_filled_circle(renderer, x, y - 10, 2, Color{ r: 35, g: 42, b: 30 })
}

fn draw_physical_buttons(renderer &Renderer, cx int, cy int) {
	btn_spacing := 65
	btn_labels := ['A', 'B', 'C']

	for i := 0; i < 3; i++ {
		bx := cx + (i - 1) * btn_spacing
		by := cy

		// 3D Drop Shadow
		draw_filled_circle(renderer, bx + 2, by + 3, 16, Color{ r: 150, g: 60, b: 80 })
		// Rubber Button Base
		draw_filled_circle(renderer, bx, by, 16, Color{ r: 245, g: 220, b: 90 })
		draw_filled_circle(renderer, bx, by - 2, 14, Color{ r: 255, g: 235, b: 120 })

		draw_text_centered(renderer, bx, by - 4, btn_labels[i], 1, Color{ r: 140, g: 90, b: 20 })
	}
}

fn draw_controls_bar(renderer &Renderer, screen_w int, screen_h int, _game &TamagotchiGame) {
	bar_rect := Rect{ x: 20, y: screen_h - 32, w: screen_w - 40, h: 26 }
	set_render_draw_color(renderer, 15, 20, 32, 240)
	render_fill_rect(renderer, &bar_rect)
	set_render_draw_color(renderer, 220, 180, 50, 255)
	render_draw_rect(renderer, &bar_rect)

	prompt := '[A/LEFT] SELECT ICON   [B/SPACE/ENTER] CONFIRM   [C/ESC] CANCEL   [M] SOUND'
	draw_text_centered(renderer, screen_w / 2, screen_h - 24, prompt, 1, Color{ r: 245, g: 230, b: 140 })
}

fn draw_filled_ellipse(renderer &Renderer, cx int, cy int, rx int, ry int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	render_fill_ellipse(renderer, f32(cx), f32(cy), f32(rx), f32(ry))
}

fn draw_filled_circle(renderer &Renderer, cx int, cy int, r int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	render_fill_circle(renderer, f32(cx), f32(cy), f32(r))
}
