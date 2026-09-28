module main

import math
import rand

fn draw_game(renderer &Renderer, g &GameEngine) {
	// Deep space background
	set_render_draw_color(renderer, 8, 8, 18, 255)
	render_clear(renderer)

	// Draw Animated Starfield
	draw_starfield(renderer, g)

	match g.state {
		.title {
			draw_title_screen(renderer, g)
		}
		.playing, .wave_clear, .game_over, .victory, .paused {
			draw_emp_shockwave(renderer, g)
			draw_lasers(renderer, g)
			draw_enemies(renderer, g)
			draw_particles(renderer, g)
			draw_player_ship(renderer, g)
			draw_floating_texts(renderer, g)
			draw_hud(renderer, g)

			if g.state == .paused {
				draw_pause_screen(renderer)
			} else if g.state == .wave_clear {
				draw_wave_clear_banner(renderer, g)
			} else if g.state == .game_over {
				draw_game_over_screen(renderer, g)
			} else if g.state == .victory {
				draw_victory_screen(renderer, g)
			}
		}
	}
}

fn draw_starfield(renderer &Renderer, g &GameEngine) {
	for s in g.stars {
		set_render_draw_color(renderer, s.color.r, s.color.g, s.color.b, 255)
		if s.size == 1 {
			render_draw_point(renderer, int(s.x), int(s.y))
		} else {
			star_rect := Rect{ x: int(s.x), y: int(s.y), w: s.size, h: s.size }
			render_fill_rect(renderer, &star_rect)
		}
	}
}

fn draw_emp_shockwave(renderer &Renderer, g &GameEngine) {
	if g.emp_flash_timer <= 0 {
		return
	}
	// Concentric cyan expanding shockwave
	r := int(g.emp_shock_radius)
	cx := 400
	cy := 300
	set_render_draw_color(renderer, 0, 240, 255, u8(math.min(255, int(g.emp_flash_timer * 255.0))))
	for off := -4; off <= 4; off += 2 {
		cur_r := math.max(1, r + off)
		for deg := 0; deg < 360; deg += 4 {
			rad := f64(deg) * math.pi / 180.0
			px := cx + int(f64(cur_r) * math.cos(rad))
			py := cy + int(f64(cur_r) * math.sin(rad))
			render_draw_point(renderer, px, py)
		}
	}
}

fn draw_lasers(renderer &Renderer, g &GameEngine) {
	for l in g.lasers {
		alpha := u8(math.min(255, int(l.timer * 255.0)))
		set_render_draw_color(renderer, l.color.r, l.color.g, l.color.b, alpha)
		render_draw_line(renderer, int(l.x1), int(l.y1), int(l.x2), int(l.y2))
		render_draw_line(renderer, int(l.x1) + 1, int(l.y1), int(l.x2) + 1, int(l.y2))
		render_draw_line(renderer, int(l.x1) - 1, int(l.y1), int(l.x2) - 1, int(l.y2))
	}
}

fn draw_player_ship(renderer &Renderer, g &GameEngine) {
	sx := int(g.ship_x)
	sy := int(g.ship_y)

	// Animated Engine Thruster Plumes
	thrust_len := 10 + int(rand.f64() * 12.0)
	set_render_draw_color(renderer, 0, 200, 255, 255)
	render_draw_line(renderer, sx - 8, sy + 18, sx - 8, sy + 18 + thrust_len)
	render_draw_line(renderer, sx + 8, sy + 18, sx + 8, sy + 18 + thrust_len)
	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_draw_line(renderer, sx - 8, sy + 18, sx - 8, sy + 18 + thrust_len / 2)
	render_draw_line(renderer, sx + 8, sy + 18, sx + 8, sy + 18 + thrust_len / 2)

	// Interceptor Hull (Delta Wing)
	set_render_draw_color(renderer, 30, 50, 90, 255)
	hull := Rect{ x: sx - 16, y: sy + 4, w: 32, h: 14 }
	render_fill_rect(renderer, &hull)

	// Wingtips
	set_render_draw_color(renderer, 0, 180, 255, 255)
	render_draw_line(renderer, sx, sy - 16, sx - 24, sy + 14)
	render_draw_line(renderer, sx, sy - 16, sx + 24, sy + 14)
	render_draw_line(renderer, sx - 24, sy + 14, sx + 24, sy + 14)

	// Cockpit Glow
	set_render_draw_color(renderer, 80, 240, 255, 255)
	cockpit := Rect{ x: sx - 4, y: sy - 8, w: 8, h: 12 }
	render_fill_rect(renderer, &cockpit)

	// Dual Cannons
	set_render_draw_color(renderer, 255, 215, 0, 255)
	canon_l := Rect{ x: sx - 18, y: sy - 4, w: 4, h: 10 }
	canon_r := Rect{ x: sx + 14, y: sy - 4, w: 4, h: 10 }
	render_fill_rect(renderer, &canon_l)
	render_fill_rect(renderer, &canon_r)
}

fn draw_enemies(renderer &Renderer, g &GameEngine) {
	for en in g.enemies {
		if !en.alive {
			continue
		}
		ex := int(en.x)
		ey := int(en.y)
		is_locked := (g.locked_enemy_id == en.id)

		// 1. Draw Enemy Craft Silhouette
		set_render_draw_color(renderer, en.color.r, en.color.g, en.color.b, 255)
		craft_cx := ex + int(en.width / 2.0)
		craft_cy := ey + 8

		match en.enemy_type {
			.scout {
				// Sleek Scout Drone Triangle
				render_draw_line(renderer, craft_cx, craft_cy + 8, craft_cx - 12, craft_cy - 8)
				render_draw_line(renderer, craft_cx, craft_cy + 8, craft_cx + 12, craft_cy - 8)
				render_draw_line(renderer, craft_cx - 12, craft_cy - 8, craft_cx + 12, craft_cy - 8)
			}
			.cruiser {
				// Hexagonal Cruiser Wings
				c_box := Rect{ x: craft_cx - 16, y: craft_cy - 6, w: 32, h: 12 }
				render_draw_rect(renderer, &c_box)
				render_draw_line(renderer, craft_cx - 22, craft_cy, craft_cx + 22, craft_cy)
			}
			.dreadnought {
				// Massive Boss Dreadnought Hull
				d_box := Rect{ x: craft_cx - 24, y: craft_cy - 8, w: 48, h: 16 }
				render_fill_rect(renderer, &d_box)
				set_render_draw_color(renderer, 255, 255, 255, 255)
				render_draw_line(renderer, craft_cx - 30, craft_cy, craft_cx + 30, craft_cy)
			}
			.emp_nuke {
				// Cyan EMP Diamond
				render_draw_line(renderer, craft_cx, craft_cy - 10, craft_cx + 10, craft_cy)
				render_draw_line(renderer, craft_cx + 10, craft_cy, craft_cx, craft_cy + 10)
				render_draw_line(renderer, craft_cx, craft_cy + 10, craft_cx - 10, craft_cy)
				render_draw_line(renderer, craft_cx - 10, craft_cy, craft_cx, craft_cy - 10)
			}
			.time_freeze {
				// Purple Time Crystal
				c_box := Rect{ x: craft_cx - 8, y: craft_cy - 8, w: 16, h: 16 }
				render_draw_rect(renderer, &c_box)
			}
			.shield_repair {
				// Green Healing Cross
				cross_v := Rect{ x: craft_cx - 3, y: craft_cy - 8, w: 6, h: 16 }
				cross_h := Rect{ x: craft_cx - 8, y: craft_cy - 3, w: 16, h: 6 }
				render_fill_rect(renderer, &cross_v)
				render_fill_rect(renderer, &cross_h)
			}
		}

		// 2. Draw Floating Word Box
		word_box_y := ey + 18
		word_box := Rect{
			x: ex
			y: word_box_y
			w: int(en.width)
			h: 22
		}

		// Box background
		set_render_draw_color(renderer, 15, 18, 30, 220)
		render_fill_rect(renderer, &word_box)

		// Border (Glow if target locked)
		if is_locked {
			set_render_draw_color(renderer, 0, 255, 128, 255)
			render_draw_rect(renderer, &word_box)
			// Target brackets [ ]
			draw_text(renderer, ex - 10, word_box_y + 3, '[', 2, Color{ r: 0, g: 255, b: 128 })
			draw_text(renderer, ex + int(en.width) + 2, word_box_y + 3, ']', 2, Color{ r: 0, g: 255, b: 128 })
		} else {
			set_render_draw_color(renderer, en.color.r / 2, en.color.g / 2, en.color.b / 2, 255)
			render_draw_rect(renderer, &word_box)
		}

		// 3. Render Characters with typed vs untyped color separation
		mut char_x := ex + 8
		for i, ch in en.word {
			if i < en.typed_count {
				// Typed letter (glowing green/cyan)
				draw_char(renderer, char_x, word_box_y + 3, ch, 2, Color{ r: 0, g: 255, b: 150 })
			} else if is_locked && i == en.typed_count {
				// Next required letter (bright yellow target)
				draw_char(renderer, char_x, word_box_y + 3, ch, 2, Color{ r: 255, g: 230, b: 0 })
			} else {
				// Untyped letter (bright white)
				draw_char(renderer, char_x, word_box_y + 3, ch, 2, Color{ r: 240, g: 240, b: 245 })
			}
			char_x += 14
		}
	}
}

fn draw_particles(renderer &Renderer, g &GameEngine) {
	for p in g.particles {
		alpha := u8(math.min(255, int((p.life / p.max_life) * 255.0)))
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		sz := int(p.size)
		p_rect := Rect{ x: int(p.x) - sz / 2, y: int(p.y) - sz / 2, w: sz, h: sz }
		render_fill_rect(renderer, &p_rect)
	}
}

fn draw_floating_texts(renderer &Renderer, g &GameEngine) {
	for ft in g.floating_texts {
		draw_text_centered(renderer, int(ft.x), int(ft.y), ft.text, 2, ft.color)
	}
}

fn draw_hud(renderer &Renderer, g &GameEngine) {
	// Top Header Bar
	set_render_draw_color(renderer, 12, 14, 28, 255)
	header := Rect{ x: 0, y: 0, w: 800, h: 48 }
	render_fill_rect(renderer, &header)
	set_render_draw_color(renderer, 40, 50, 90, 255)
	render_draw_line(renderer, 0, 48, 800, 48)

	// Score
	draw_text(renderer, 25, 8, 'SCORE', 1, Color{ r: 160, g: 170, b: 190 })
	draw_text(renderer, 25, 22, '${g.score:06d}', 2, Color{ r: 255, g: 255, b: 255 })

	// Mode / Sector
	if g.mode == .speed_blitz {
		t_col := if g.blitz_timer < 10.0 { Color{ r: 255, g: 60, b: 60 } } else { Color{ r: 255, g: 215, b: 0 } }
		draw_text_centered(renderer, 250, 8, 'TIME REMAINING', 1, Color{ r: 160, g: 170, b: 190 })
		draw_text_centered(renderer, 250, 22, '${int(g.blitz_timer + 0.9)}s', 2, t_col)
	} else {
		draw_text_centered(renderer, 250, 8, 'SECTOR WAVE', 1, Color{ r: 160, g: 170, b: 190 })
		draw_text_centered(renderer, 250, 22, 'WAVE ${g.wave}', 2, Color{ r: 80, g: 220, b: 255 })
	}

	// High Score
	draw_text_centered(renderer, 460, 8, 'HIGH SCORE', 1, Color{ r: 160, g: 170, b: 190 })
	draw_text_centered(renderer, 460, 22, '${g.high_score:06d}', 2, Color{ r: 255, g: 215, b: 0 })

	// Mode Badge
	draw_text(renderer, 620, 8, 'MODE', 1, Color{ r: 160, g: 170, b: 190 })
	draw_text(renderer, 620, 22, g.mode.name(), 1, Color{ r: 0, g: 240, b: 255 })

	// Bottom Footer Bar
	set_render_draw_color(renderer, 12, 14, 28, 255)
	footer := Rect{ x: 0, y: 555, w: 800, h: 45 }
	render_fill_rect(renderer, &footer)
	set_render_draw_color(renderer, 40, 50, 90, 255)
	render_draw_line(renderer, 0, 555, 800, 555)

	// Hull Shields (Energy Blocks)
	draw_text(renderer, 25, 568, 'SHIELDS:', 1, Color{ r: 180, g: 190, b: 210 })
	for i in 0 .. g.max_shields {
		bx := 95 + i * 22
		by := 568
		if i < g.shields {
			set_render_draw_color(renderer, 0, 220, 255, 255)
			b_rect := Rect{ x: bx, y: by, w: 16, h: 16 }
			render_fill_rect(renderer, &b_rect)
		} else {
			set_render_draw_color(renderer, 60, 40, 50, 255)
			b_rect := Rect{ x: bx, y: by, w: 16, h: 16 }
			render_draw_rect(renderer, &b_rect)
		}
	}

	// WPM (Words Per Minute) Real-time readout
	wpm := g.calculate_wpm()
	draw_text(renderer, 230, 568, 'WPM: ${wpm}', 2, Color{ r: 0, g: 255, b: 160 })

	// Accuracy %
	acc := g.calculate_accuracy()
	draw_text(renderer, 380, 568, 'ACC: ${acc}%', 2, Color{ r: 255, g: 215, b: 0 })

	// Combo Streak
	combo_txt := if g.combo_streak >= 10 { 'STREAK: ${g.combo_streak} 🔥' } else { 'STREAK: ${g.combo_streak}' }
	combo_col := if g.combo_streak >= 25 { Color{ r: 255, g: 60, b: 120 } } else { Color{ r: 255, g: 220, b: 80 } }
	draw_text(renderer, 540, 568, combo_txt, 2, combo_col)

	// Sound & Pause Hint
	draw_text(renderer, 690, 570, '[ESC] PAUSE  [F11] Fullscreen', 1, Color{ r: 130, g: 140, b: 160 })
}

fn draw_title_screen(renderer &Renderer, g &GameEngine) {
	// Giant Neon CYBERTYPE Title
	draw_text_centered(renderer, 400, 50, 'C Y B E R T Y P E', 5, Color{ r: 0, g: 240, b: 255 })
	draw_text_centered(renderer, 400, 100, 'ARCADE NEON SPACE TYPIST', 2, Color{ r: 255, g: 215, b: 0 })

	// Mode Selection Panel
	set_render_draw_color(renderer, 20, 25, 50, 255)
	mode_box := Rect{ x: 90, y: 135, w: 620, h: 105 }
	render_fill_rect(renderer, &mode_box)
	set_render_draw_color(renderer, 70, 90, 160, 255)
	render_draw_rect(renderer, &mode_box)

	draw_text_centered(renderer, 400, 145, 'SELECT GAME MODE [PRESS 1-4 OR TAB]', 2, Color{ r: 255, g: 220, b: 80 })

	modes := [GameMode.arcade, GameMode.speed_blitz, GameMode.code_words, GameMode.endless]
	labels := ['1: ARCADE', '2: SPEED 60s', '3: CODE SYNTAX', '4: ENDLESS']
	colors := [
		Color{ r: 0, g: 240, b: 255 },
		Color{ r: 255, g: 215, b: 0 },
		Color{ r: 80, g: 255, b: 120 },
		Color{ r: 255, g: 60, b: 120 },
	]

	for i in 0 .. 4 {
		bx := 105 + i * 148
		by := 170
		is_sel := (g.mode == modes[i])

		if is_sel {
			set_render_draw_color(renderer, colors[i].r, colors[i].g, colors[i].b, 255)
			btn_r := Rect{ x: bx, y: by, w: 138, h: 30 }
			render_draw_rect(renderer, &btn_r)
			draw_text(renderer, bx + 10, by + 8, '> ' + labels[i], 1, colors[i])
		} else {
			set_render_draw_color(renderer, 50, 60, 90, 255)
			btn_r := Rect{ x: bx, y: by, w: 138, h: 30 }
			render_draw_rect(renderer, &btn_r)
			draw_text(renderer, bx + 16, by + 8, labels[i], 1, Color{ r: 160, g: 170, b: 190 })
		}
	}

	mode_desc := match g.mode {
		.arcade { 'Arcade Campaign: 10 Progressive Sector Waves, Asteroids & Bosses' }
		.speed_blitz { '60s Blitz: Type as fast as possible to set your highest WPM record!' }
		.code_words { 'Developer Syntax: Falling keywords from V, C, Rust, Python, Go, and SQL' }
		.endless { 'Endless Survival: Continuous escalating speed until hull breach' }
	}
	draw_text_centered(renderer, 400, 215, mode_desc, 1, Color{ r: 230, g: 230, b: 240 })

	// Gameplay Guide Box
	set_render_draw_color(renderer, 25, 30, 55, 255)
	guide_box := Rect{ x: 90, y: 255, w: 620, h: 180 }
	render_fill_rect(renderer, &guide_box)
	set_render_draw_color(renderer, 70, 90, 160, 255)
	render_draw_rect(renderer, &guide_box)

	draw_text(renderer, 120, 270, 'TACTICAL TARGETING & POWER-UP WORDS:', 2, Color{ r: 255, g: 220, b: 80 })
	draw_text(renderer, 120, 302, 'TYPE 1ST LETTER    - LOCKS SHIP LASER CANNON ONTO ENEMY', 1, Color{ r: 255, g: 255, b: 255 })
	draw_text(renderer, 120, 324, 'EMP WORDS (CYAN)   - DESTROYS ALL HOSTILES ON SCREEN', 1, Color{ r: 0, g: 240, b: 255 })
	draw_text(renderer, 120, 346, 'FREEZE (PURPLE)    - STASIS WARP SLOWS TIME FOR 4 SECONDS', 1, Color{ r: 180, g: 120, b: 255 })
	draw_text(renderer, 120, 368, 'SHIELD (GREEN)     - REPAIRS HULL SHIELD HEALTH (+1)', 1, Color{ r: 80, g: 255, b: 120 })
	draw_text(renderer, 120, 390, 'COMBO STREAKS      - 10x 25x 50x 100x SCORE MULTIPLIERS!', 1, Color{ r: 255, g: 215, b: 0 })
	draw_text(renderer, 120, 412, 'BACKSPACE / ESC    - CANCEL CURRENT TARGET LOCK', 1, Color{ r: 180, g: 180, b: 190 })

	// Start Prompts
	draw_text_centered(renderer, 400, 455, 'PRESS [SPACE] OR [ENTER] TO LAUNCH SHIP', 2, Color{ r: 0, g: 255, b: 160 })
	draw_text_centered(renderer, 400, 495, 'SELECT MODE WITH [1-4] OR [TAB]', 2, Color{ r: 255, g: 215, b: 0 })
	draw_text_centered(renderer, 400, 540, '[M] SOUND  |  [ESC] PAUSE  |  [F5] RESTART | F11: Fullscreen', 1, Color{ r: 150, g: 160, b: 180 })
}

fn draw_pause_screen(renderer &Renderer) {
	set_render_draw_color(renderer, 0, 0, 0, 190)
	overlay := Rect{ x: 0, y: 0, w: 800, h: 600 }
	render_fill_rect(renderer, &overlay)
	draw_text_centered(renderer, 400, 260, 'MISSION PAUSED', 4, Color{ r: 0, g: 240, b: 255 })
	draw_text_centered(renderer, 400, 320, 'PRESS [ESC] OR [SPACE] TO RESUME', 2, Color{ r: 255, g: 255, b: 255 })
}

fn draw_wave_clear_banner(renderer &Renderer, g &GameEngine) {
	draw_text_centered(renderer, 400, 240, 'SECTOR CLEARED!', 4, Color{ r: 0, g: 255, b: 160 })
	draw_text_centered(renderer, 400, 290, 'PREPARING SECTOR ${g.wave + 1}...', 2, Color{ r: 255, g: 255, b: 255 })
}

fn draw_game_over_screen(renderer &Renderer, g &GameEngine) {
	set_render_draw_color(renderer, 10, 5, 15, 210)
	overlay := Rect{ x: 0, y: 0, w: 800, h: 600 }
	render_fill_rect(renderer, &overlay)

	draw_text_centered(renderer, 400, 160, 'MISSION TERMINATED', 4, Color{ r: 255, g: 50, b: 50 })

	// Stats Summary Box
	set_render_draw_color(renderer, 25, 30, 60, 255)
	box := Rect{ x: 200, y: 225, w: 400, h: 190 }
	render_fill_rect(renderer, &box)
	set_render_draw_color(renderer, 80, 100, 180, 255)
	render_draw_rect(renderer, &box)

	wpm := g.calculate_wpm()
	acc := g.calculate_accuracy()

	draw_text(renderer, 230, 245, 'FINAL SCORE:', 2, Color{ r: 255, g: 215, b: 0 })
	draw_text(renderer, 440, 245, '${g.score}', 2, Color{ r: 255, g: 255, b: 255 })

	draw_text(renderer, 230, 280, 'TYPING SPEED:', 2, Color{ r: 0, g: 240, b: 255 })
	draw_text(renderer, 440, 280, '${wpm} WPM', 2, Color{ r: 255, g: 255, b: 255 })

	draw_text(renderer, 230, 315, 'ACCURACY:', 2, Color{ r: 80, g: 255, b: 120 })
	draw_text(renderer, 440, 315, '${acc}%', 2, Color{ r: 255, g: 255, b: 255 })

	draw_text(renderer, 230, 350, 'WORDS DESTROYED:', 2, Color{ r: 255, g: 140, b: 200 })
	draw_text(renderer, 440, 350, '${g.words_typed}', 2, Color{ r: 255, g: 255, b: 255 })

	draw_text(renderer, 230, 385, 'MAX COMBO STREAK:', 2, Color{ r: 255, g: 220, b: 80 })
	draw_text(renderer, 440, 385, '${g.max_combo}x', 2, Color{ r: 255, g: 255, b: 255 })

	draw_text_centered(renderer, 400, 450, 'PRESS [SPACE] OR [R] TO PLAY AGAIN', 2, Color{ r: 0, g: 255, b: 160 })
}

fn draw_victory_screen(renderer &Renderer, g &GameEngine) {
	set_render_draw_color(renderer, 5, 15, 25, 210)
	overlay := Rect{ x: 0, y: 0, w: 800, h: 600 }
	render_fill_rect(renderer, &overlay)

	draw_text_centered(renderer, 400, 150, 'VICTORY! GALAXY SAVED!', 4, Color{ r: 255, g: 215, b: 0 })
	draw_text_centered(renderer, 400, 210, 'ALL 10 SECTORS CONQUERED', 2, Color{ r: 0, g: 240, b: 255 })

	wpm := g.calculate_wpm()
	acc := g.calculate_accuracy()

	draw_text_centered(renderer, 400, 270, 'FINAL SCORE: ${g.score}', 3, Color{ r: 255, g: 255, b: 255 })
	draw_text_centered(renderer, 400, 315, 'SPEED: ${wpm} WPM  |  ACCURACY: ${acc}%', 2, Color{ r: 80, g: 255, b: 120 })
	draw_text_centered(renderer, 400, 355, 'TOTAL WORDS DESTROYED: ${g.words_typed}', 2, Color{ r: 255, g: 140, b: 200 })

	draw_text_centered(renderer, 400, 440, 'PRESS [SPACE] OR [R] TO RESTART  [F11] Fullscreen', 2, Color{ r: 0, g: 255, b: 160 })
}
