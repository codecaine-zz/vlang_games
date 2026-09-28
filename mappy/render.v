import math
import os

pub struct MappyTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm MappyTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/mappy.png',
		'./assets/sprites/mappy.png',
		'../assets/sprites/mappy.png',
		'mappy/assets/sprites/mappy.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('mappy Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn draw_game(renderer &Renderer, g &GameEngine, tex &Texture) {
	// Background clear
	set_render_draw_color(renderer, g.current_theme.bg_color.r, g.current_theme.bg_color.g, g.current_theme.bg_color.b, 255)
	render_clear(renderer)

	match g.state {
		.title {
			draw_title_screen(renderer, g)
		}
		.playing, .stage_clear, .bonus_stage, .bonus_clear, .life_lost, .paused, .game_over {
			draw_mansion(renderer, g)
			draw_trampolines(renderer, g)
			draw_doors(renderer, g)
			draw_items(renderer, g, tex)
			draw_balloons(renderer, g)
			draw_waves(renderer, g)
			draw_enemies(renderer, g, tex)
			draw_gosenzo(renderer, g)
			draw_mappy(renderer, g, tex)
			draw_scores(renderer, g)
			draw_hud(renderer, g)

			if g.state == .paused {
				draw_pause_screen(renderer)
			} else if g.state == .game_over {
				draw_game_over_screen(renderer, g)
			} else if g.state == .stage_clear {
				draw_stage_clear_banner(renderer, g)
			} else if g.state == .bonus_clear {
				draw_bonus_clear_banner(renderer, g)
			}
		}
	}
}

fn draw_mansion(renderer &Renderer, g &GameEngine) {
	theme := g.current_theme

	// Outer Mansion Walls
	set_render_draw_color(renderer, theme.wall_color.r, theme.wall_color.g, theme.wall_color.b, 255)
	left_wall := Rect{ x: int(g.mansion_left) - 16, y: 70, w: 16, h: 440 }
	right_wall := Rect{ x: int(g.mansion_right), y: 70, w: 16, h: 440 }
	render_fill_rect(renderer, &left_wall)
	render_fill_rect(renderer, &right_wall)

	// Roof / Attic Trim
	set_render_draw_color(renderer, theme.accent_color.r, theme.accent_color.g, theme.accent_color.b, 255)
	roof_rect := Rect{ x: int(g.mansion_left) - 24, y: 62, w: int(g.mansion_right - g.mansion_left) + 48, h: 10 }
	render_fill_rect(renderer, &roof_rect)

	// Interior Wallpapers / Pillars (Subtle vertical stripes)
	set_render_draw_color(renderer, u8(math.max(0, int(theme.bg_color.r) + 15)),
		u8(math.max(0, int(theme.bg_color.g) + 15)), u8(math.max(0, int(theme.bg_color.b) + 15)), 255)
	for px in [220, 400, 580] {
		pillar := Rect{ x: px - 4, y: 72, w: 8, h: 416 }
		render_fill_rect(renderer, &pillar)
	}

	// Floor Platforms
	for fl in g.floors {
		// Floorboard surface
		set_render_draw_color(renderer, theme.floor_color.r, theme.floor_color.g, theme.floor_color.b, 255)
		fl_rect := Rect{
			x: int(fl.x_start)
			y: int(fl.y)
			w: int(fl.x_end - fl.x_start)
			h: int(floor_thickness)
		}
		render_fill_rect(renderer, &fl_rect)

		// Floor underside shadow
		set_render_draw_color(renderer, u8(math.max(0, int(theme.floor_color.r) - 60)),
			u8(math.max(0, int(theme.floor_color.g) - 60)), u8(math.max(0, int(theme.floor_color.b) - 60)), 255)
		shadow_rect := Rect{
			x: int(fl.x_start)
			y: int(fl.y) + int(floor_thickness) - 2
			w: int(fl.x_end - fl.x_start)
			h: 2
		}
		render_fill_rect(renderer, &shadow_rect)
	}
}

fn draw_trampolines(renderer &Renderer, g &GameEngine) {
	for tr in g.trampolines {
		if tr.is_broken {
			// Broken ripped cloth fibers
			set_render_draw_color(renderer, 220, 50, 50, 255)
			render_draw_line(renderer, int(tr.x - 18), int(tr.y), int(tr.x - 8), int(tr.y + 12))
			render_draw_line(renderer, int(tr.x + 18), int(tr.y), int(tr.x + 8), int(tr.y + 12))
			continue
		}

		// Trampoline color based on consecutive wear bounces:
		// 0: Green (Safe), 1: Blue, 2: Yellow, 3: Red (Danger!)
		cloth_color := match tr.bounces {
			0 { Color{ r: 50, g: 230, b: 80 } }
			1 { Color{ r: 50, g: 150, b: 255 } }
			2 { Color{ r: 255, g: 220, b: 40 } }
			else { Color{ r: 255, g: 50, b: 50 } }
		}

		// Side Springs & Stand
		set_render_draw_color(renderer, 160, 160, 170, 255)
		render_draw_line(renderer, int(tr.x - 18), int(tr.y), int(tr.x - 18), int(tr.y + 14))
		render_draw_line(renderer, int(tr.x + 18), int(tr.y), int(tr.x + 18), int(tr.y + 14))
		render_draw_line(renderer, int(tr.x - 22), int(tr.y + 14), int(tr.x + 22), int(tr.y + 14))

		// Elastic curved cloth
		set_render_draw_color(renderer, cloth_color.r, cloth_color.g, cloth_color.b, 255)
		disp := int(tr.tension * 8.0)
		for off := -16; off <= 16; off += 2 {
			y_curve := int(tr.y) + disp * (16 - int(math.abs(f64(off)))) / 16
			render_draw_point(renderer, int(tr.x) + off, y_curve)
			render_draw_point(renderer, int(tr.x) + off, y_curve + 1)
		}
	}
}

fn draw_doors(renderer &Renderer, g &GameEngine) {
	for d in g.doors {
		hx := int(d.x)
		hy := int(d.y)

		match d.state {
			.closed {
				// Door Frame & Panel
				if d.door_type == .microwave && !d.is_used {
					// Glowing Microwave door (cyan / electric blue)
					set_render_draw_color(renderer, 0, 220, 255, 255)
					d_rect := Rect{ x: hx - 5, y: hy, w: 10, h: 32 }
					render_fill_rect(renderer, &d_rect)
					// Core coil
					set_render_draw_color(renderer, 255, 255, 255, 255)
					coil := Rect{ x: hx - 2, y: hy + 6, w: 4, h: 20 }
					render_fill_rect(renderer, &coil)
				} else {
					// Classic wooden brown door
					set_render_draw_color(renderer, 150, 80, 40, 255)
					d_rect := Rect{ x: hx - 5, y: hy, w: 10, h: 32 }
					render_fill_rect(renderer, &d_rect)
					// Handle knob
					set_render_draw_color(renderer, 255, 215, 0, 255)
					knob_x := if d.facing == .right { hx + 2 } else { hx - 4 }
					knob := Rect{ x: knob_x, y: hy + 14, w: 3, h: 4 }
					render_fill_rect(renderer, &knob)
				}
			}
			.opening, .open {
				// Open door swing angle
				swing_x := if d.facing == .right { hx + 18 } else { hx - 18 }
				set_render_draw_color(renderer, 120, 60, 30, 255)
				render_draw_line(renderer, hx, hy, swing_x, hy + 8)
				render_draw_line(renderer, hx, hy + 32, swing_x, hy + 24)
				render_draw_line(renderer, swing_x, hy + 8, swing_x, hy + 24)
			}
		}
	}
}

fn draw_items(renderer &Renderer, g &GameEngine, tex &Texture) {
	for it in g.items {
		if it.collected {
			continue
		}
		ix := int(it.x)
		iy := int(it.y)

		// Goro tail/ears peeking out behind item if hidden
		if it.has_goro {
			set_render_draw_color(renderer, 240, 60, 80, 255)
			// Small ears peeking
			ear_left := Rect{ x: ix - 10, y: iy - 6, w: 4, h: 6 }
			ear_right := Rect{ x: ix + 6, y: iy - 6, w: 4, h: 6 }
			render_fill_rect(renderer, &ear_left)
			render_fill_rect(renderer, &ear_right)
		}

		if tex != unsafe { nil } {
			col_x := match it.item_type {
				.radio { 0 }
				.tv { 64 }
				.microwave { 128 }
				.painting { 192 }
				.safe { 256 }
			}
			src := Rect{ x: col_x, y: 192, w: 64, h: 64 }
			dst := Rect{ x: ix - 14, y: iy - 12, w: 28, h: 28 }
			render_copy(renderer, tex, &src, &dst)
			continue
		}

		match it.item_type {
			.radio {
				// Retro Radio (Brown box with dial and antenna)
				set_render_draw_color(renderer, 170, 90, 40, 255)
				body := Rect{ x: ix - 8, y: iy, w: 16, h: 14 }
				render_fill_rect(renderer, &body)
				// Speaker grille & dial
				set_render_draw_color(renderer, 240, 220, 180, 255)
				dial := Rect{ x: ix + 1, y: iy + 3, w: 5, h: 5 }
				render_fill_rect(renderer, &dial)
				// Antenna
				set_render_draw_color(renderer, 200, 200, 210, 255)
				render_draw_line(renderer, ix - 5, iy, ix - 10, iy - 8)
			}
			.tv {
				// CRT Television (Cyan screen in wood cabinet)
				set_render_draw_color(renderer, 100, 50, 20, 255)
				cabinet := Rect{ x: ix - 10, y: iy - 2, w: 20, h: 16 }
				render_fill_rect(renderer, &cabinet)
				// Glowing screen
				set_render_draw_color(renderer, 80, 200, 240, 255)
				screen := Rect{ x: ix - 7, y: iy + 1, w: 11, h: 10 }
				render_fill_rect(renderer, &screen)
				// Knobs
				set_render_draw_color(renderer, 220, 220, 220, 255)
				knob := Rect{ x: ix + 5, y: iy + 3, w: 3, h: 3 }
				render_fill_rect(renderer, &knob)
			}
			.microwave {
				// Tech Microwave / Computer
				set_render_draw_color(renderer, 220, 220, 230, 255)
				m_body := Rect{ x: ix - 9, y: iy - 1, w: 18, h: 15 }
				render_fill_rect(renderer, &m_body)
				// Glass door
				set_render_draw_color(renderer, 50, 70, 90, 255)
				glass := Rect{ x: ix - 7, y: iy + 2, w: 10, h: 9 }
				render_fill_rect(renderer, &glass)
				// Digital keypad
				set_render_draw_color(renderer, 30, 180, 80, 255)
				keypad := Rect{ x: ix + 4, y: iy + 3, w: 3, h: 7 }
				render_fill_rect(renderer, &keypad)
			}
			.painting {
				// Mona Lisa in Golden Ornate Frame
				set_render_draw_color(renderer, 255, 215, 0, 255)
				frame := Rect{ x: ix - 9, y: iy - 3, w: 18, h: 18 }
				render_fill_rect(renderer, &frame)
				// Canvas artwork
				set_render_draw_color(renderer, 40, 80, 60, 255)
				canvas := Rect{ x: ix - 6, y: iy, w: 12, h: 12 }
				render_fill_rect(renderer, &canvas)
				// Portrait face
				set_render_draw_color(renderer, 240, 190, 150, 255)
				face := Rect{ x: ix - 2, y: iy + 2, w: 4, h: 5 }
				render_fill_rect(renderer, &face)
			}
			.safe {
				// Heavy Iron Steel Safe Box with Dial Lock
				set_render_draw_color(renderer, 90, 100, 110, 255)
				safe_body := Rect{ x: ix - 10, y: iy - 3, w: 20, h: 18 }
				render_fill_rect(renderer, &safe_body)
				// Inset door & rivets
				set_render_draw_color(renderer, 60, 70, 80, 255)
				inner := Rect{ x: ix - 8, y: iy - 1, w: 16, h: 14 }
				render_fill_rect(renderer, &inner)
				// Golden Combination Dial
				set_render_draw_color(renderer, 255, 215, 0, 255)
				dial := Rect{ x: ix - 2, y: iy + 3, w: 5, h: 5 }
				render_fill_rect(renderer, &dial)
			}
		}
	}
}

fn draw_balloons(renderer &Renderer, g &GameEngine) {
	for b in g.balloons {
		if b.collected {
			continue
		}
		bx := int(b.x)
		by := int(b.y)

		if b.is_goro {
			// Large Goro Boss Cat Balloon (2000 pts)
			set_render_draw_color(renderer, 255, 60, 90, 255)
			g_balloon := Rect{ x: bx - 14, y: by - 14, w: 28, h: 26 }
			render_fill_rect(renderer, &g_balloon)
			// Ears
			ear_l := Rect{ x: bx - 12, y: by - 20, w: 6, h: 8 }
			ear_r := Rect{ x: bx + 6, y: by - 20, w: 6, h: 8 }
			render_fill_rect(renderer, &ear_l)
			render_fill_rect(renderer, &ear_r)
			// Eyes & Whiskers
			set_render_draw_color(renderer, 255, 255, 255, 255)
			eye_l := Rect{ x: bx - 7, y: by - 6, w: 4, h: 5 }
			eye_r := Rect{ x: bx + 3, y: by - 6, w: 4, h: 5 }
			render_fill_rect(renderer, &eye_l)
			render_fill_rect(renderer, &eye_r)
		} else {
			// Red round balloon
			set_render_draw_color(renderer, 255, 50, 60, 255)
			balloon := Rect{ x: bx - 8, y: by - 8, w: 16, h: 16 }
			render_fill_rect(renderer, &balloon)
			// Highlight
			set_render_draw_color(renderer, 255, 180, 190, 255)
			shine := Rect{ x: bx - 5, y: by - 6, w: 4, h: 4 }
			render_fill_rect(renderer, &shine)
			// Knot string
			set_render_draw_color(renderer, 200, 200, 200, 255)
			render_draw_line(renderer, bx, by + 8, bx, by + 16)
		}
	}
}

fn draw_waves(renderer &Renderer, g &GameEngine) {
	for w in g.waves {
		if !w.active {
			continue
		}
		wx := int(w.x)
		wy := int(w.y)

		// Glowing expanding microwave arcs
		set_render_draw_color(renderer, 80, 220, 255, 255)
		for off := -8; off <= 8; off += 4 {
			ring_x := wx + off
			render_draw_line(renderer, ring_x, wy - 14, ring_x + 6, wy)
			render_draw_line(renderer, ring_x + 6, wy, ring_x, wy + 14)
		}
	}
}

fn draw_mappy(renderer &Renderer, g &GameEngine, tex &Texture) {
	mx := int(g.player.x)
	my := int(g.player.y)

	// Blink when invulnerable
	if g.player.invulnerable > 0 && int(g.player.invulnerable * 12.0) % 2 == 0 {
		return
	}

	if tex != unsafe { nil } {
		col_x := if g.player.state == .bouncing { 128 } else if int(g.player.anim_timer * 6.0) % 2 == 0 { 0 } else { 64 }
		src := Rect{ x: col_x, y: 0, w: 64, h: 64 }
		dst := Rect{ x: mx - 16, y: my - 24, w: 32, h: 32 }
		flip := if g.player.facing == .left { RendererFlip.horizontal } else { RendererFlip.none }
		render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
		return
	}

	// Police Blue Uniform Body
	set_render_draw_color(renderer, 30, 80, 220, 255)
	body := Rect{ x: mx - 6, y: my - 8, w: 12, h: 14 }
	render_fill_rect(renderer, &body)

	// White Mouse Head & Face
	set_render_draw_color(renderer, 245, 245, 250, 255)
	head := Rect{ x: mx - 6, y: my - 16, w: 12, h: 10 }
	render_fill_rect(renderer, &head)

	// Big Pink Mouse Ears
	set_render_draw_color(renderer, 255, 140, 170, 255)
	ear_l := Rect{ x: mx - 10, y: my - 20, w: 5, h: 6 }
	ear_r := Rect{ x: mx + 5, y: my - 20, w: 5, h: 6 }
	render_fill_rect(renderer, &ear_l)
	render_fill_rect(renderer, &ear_r)

	// Police Hat with Gold Badge
	set_render_draw_color(renderer, 20, 50, 160, 255)
	hat := Rect{ x: mx - 5, y: my - 18, w: 10, h: 4 }
	render_fill_rect(renderer, &hat)
	set_render_draw_color(renderer, 255, 215, 0, 255)
	badge := Rect{ x: mx - 1, y: my - 17, w: 3, h: 3 }
	render_fill_rect(renderer, &badge)

	// Eyes & Nose
	set_render_draw_color(renderer, 20, 20, 20, 255)
	eye_x := if g.player.facing == .right { mx + 1 } else { mx - 4 }
	eye := Rect{ x: eye_x, y: my - 13, w: 3, h: 3 }
	render_fill_rect(renderer, &eye)

	// Police Baton
	set_render_draw_color(renderer, 240, 200, 80, 255)
	baton_x := if g.player.facing == .right { mx + 7 } else { mx - 9 }
	baton := Rect{ x: baton_x, y: my - 6, w: 3, h: 8 }
	render_fill_rect(renderer, &baton)

	// Legs / Walking feet
	set_render_draw_color(renderer, 20, 40, 120, 255)
	leg_off := int(math.sin(g.player.anim_timer) * 3.0)
	foot_l := Rect{ x: mx - 5 + leg_off, y: my + 6, w: 4, h: 4 }
	foot_r := Rect{ x: mx + 1 - leg_off, y: my + 6, w: 4, h: 4 }
	render_fill_rect(renderer, &foot_l)
	render_fill_rect(renderer, &foot_r)
}

fn draw_enemies(renderer &Renderer, g &GameEngine, tex &Texture) {
	for en in g.enemies {
		ex := int(en.x)
		ey := int(en.y)

		if tex != unsafe { nil } {
			row_y := if en.is_goro { 64 } else { 128 }
			col_x := if en.state == .bouncing { 128 } else if int(en.anim_timer * 6.0) % 2 == 0 { 0 } else { 64 }
			src := Rect{ x: col_x, y: row_y, w: 64, h: 64 }
			dst := Rect{ x: ex - 16, y: ey - 24, w: 32, h: 32 }
			flip := if en.facing == .left { RendererFlip.horizontal } else { RendererFlip.none }
			render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
			continue
		}

		if en.is_goro {
			// Nyamco Boss Cat (Larger reddish body, yellow eyes)
			set_render_draw_color(renderer, 230, 40, 60, 255)
			body := Rect{ x: ex - 9, y: ey - 10, w: 18, h: 16 }
			render_fill_rect(renderer, &body)
			// Ears
			ear_l := Rect{ x: ex - 9, y: ey - 18, w: 5, h: 8 }
			ear_r := Rect{ x: ex + 4, y: ey - 18, w: 5, h: 8 }
			render_fill_rect(renderer, &ear_l)
			render_fill_rect(renderer, &ear_r)
			// White Belly & Whiskers
			set_render_draw_color(renderer, 255, 240, 220, 255)
			belly := Rect{ x: ex - 5, y: ey - 4, w: 10, h: 9 }
			render_fill_rect(renderer, &belly)
			// Yellow Eyes
			set_render_draw_color(renderer, 255, 230, 40, 255)
			eye_off := if en.facing == .right { 1 } else { -5 }
			eye := Rect{ x: ex + eye_off, y: ey - 12, w: 4, h: 4 }
			render_fill_rect(renderer, &eye)
		} else {
			// Mewkies (Pink kitten henchmen)
			set_render_draw_color(renderer, 245, 120, 140, 255)
			body := Rect{ x: ex - 6, y: ey - 8, w: 12, h: 13 }
			render_fill_rect(renderer, &body)
			// Pointy Ears
			ear_l := Rect{ x: ex - 6, y: ey - 14, w: 4, h: 6 }
			ear_r := Rect{ x: ex + 2, y: ey - 14, w: 4, h: 6 }
			render_fill_rect(renderer, &ear_l)
			render_fill_rect(renderer, &ear_r)
			// White Face & Eyes
			set_render_draw_color(renderer, 255, 255, 255, 255)
			face := Rect{ x: ex - 4, y: ey - 9, w: 8, h: 7 }
			render_fill_rect(renderer, &face)
			set_render_draw_color(renderer, 20, 20, 20, 255)
			eye_off := if en.facing == .right { 1 } else { -3 }
			eye := Rect{ x: ex + eye_off, y: ey - 8, w: 2, h: 3 }
			render_fill_rect(renderer, &eye)
		}

		// Dizzy Stars when stunned
		if en.state == .stunned {
			set_render_draw_color(renderer, 255, 230, 0, 255)
			star_phase := en.stun_timer * 10.0
			s1_x := ex + int(math.cos(star_phase) * 12.0)
			s1_y := ey - 22 + int(math.sin(star_phase) * 5.0)
			s2_x := ex + int(math.cos(star_phase + math.pi) * 12.0)
			s2_y := ey - 22 + int(math.sin(star_phase + math.pi) * 5.0)
			star1 := Rect{ x: s1_x - 2, y: s1_y - 2, w: 4, h: 4 }
			star2 := Rect{ x: s2_x - 2, y: s2_y - 2, w: 4, h: 4 }
			render_fill_rect(renderer, &star1)
			render_fill_rect(renderer, &star2)
		}
	}
}

fn draw_gosenzo(renderer &Renderer, g &GameEngine) {
	if !g.gosenzo.active {
		return
	}
	gx := int(g.gosenzo.x)
	gy := int(g.gosenzo.y)

	// Giant Gold Ancestor Coin with glowing eyes
	set_render_draw_color(renderer, 255, 215, 0, 255)
	coin := Rect{ x: gx - 16, y: gy - 16, w: 32, h: 32 }
	render_fill_rect(renderer, &coin)
	// Darker beveled rim
	set_render_draw_color(renderer, 200, 160, 0, 255)
	rim := Rect{ x: gx - 13, y: gy - 13, w: 26, h: 26 }
	render_fill_rect(renderer, &rim)
	// Cat face embossing with Red Glowing Eyes
	set_render_draw_color(renderer, 255, 30, 30, 255)
	eye_l := Rect{ x: gx - 8, y: gy - 6, w: 5, h: 5 }
	eye_r := Rect{ x: gx + 3, y: gy - 6, w: 5, h: 5 }
	render_fill_rect(renderer, &eye_l)
	render_fill_rect(renderer, &eye_r)
}

fn draw_scores(renderer &Renderer, g &GameEngine) {
	for sc in g.scores {
		draw_text_centered(renderer, int(sc.x), int(sc.y), sc.text, 2, sc.color)
	}
}

fn draw_hud(renderer &Renderer, g &GameEngine) {
	// Top Header Bar
	set_render_draw_color(renderer, 10, 10, 20, 255)
	header := Rect{ x: 0, y: 0, w: 800, h: 55 }
	render_fill_rect(renderer, &header)

	// 1UP & SCORE
	draw_text(renderer, 30, 10, '1UP', 2, Color{ r: 255, g: 80, b: 80 })
	draw_text(renderer, 30, 28, '${g.score:06d}', 2, Color{ r: 255, g: 255, b: 255 })

	// DIFFICULTY BADGE
	diff_color := match g.difficulty {
		.easy { Color{ r: 80, g: 240, b: 120 } }
		.normal { Color{ r: 80, g: 220, b: 255 } }
		.hard { Color{ r: 255, g: 160, b: 40 } }
		.expert { Color{ r: 255, g: 50, b: 50 } }
	}
	draw_text_centered(renderer, 240, 12, 'DIFF', 1, Color{ r: 180, g: 180, b: 190 })
	draw_text_centered(renderer, 240, 26, g.difficulty.name(), 2, diff_color)

	// HIGH SCORE
	draw_text(renderer, 360, 10, 'HIGH SCORE', 2, Color{ r: 80, g: 220, b: 255 })
	draw_text(renderer, 380, 28, '${g.high_score:06d}', 2, Color{ r: 255, g: 255, b: 255 })

	// ROUND / STAGE
	round_title := if g.is_bonus_round { 'BONUS' } else { 'ROUND' }
	draw_text(renderer, 660, 10, round_title, 2, Color{ r: 255, g: 215, b: 0 })
	draw_text(renderer, 680, 28, '${g.round}', 2, Color{ r: 255, g: 255, b: 255 })

	// Bottom Footer Bar
	set_render_draw_color(renderer, 10, 10, 20, 255)
	footer := Rect{ x: 0, y: 545, w: 800, h: 55 }
	render_fill_rect(renderer, &footer)

	// Remaining Lives (Mouse icons)
	draw_text(renderer, 30, 560, 'LIVES:', 2, Color{ r: 200, g: 200, b: 200 })
	for i in 0 .. g.lives {
		lx := 120 + i * 22
		ly := 562
		// Mini Mappy head icon
		set_render_draw_color(renderer, 30, 80, 220, 255)
		m_icon := Rect{ x: lx, y: ly, w: 12, h: 10 }
		render_fill_rect(renderer, &m_icon)
		set_render_draw_color(renderer, 255, 140, 170, 255)
		e1 := Rect{ x: lx - 2, y: ly - 3, w: 4, h: 4 }
		e2 := Rect{ x: lx + 10, y: ly - 3, w: 4, h: 4 }
		render_fill_rect(renderer, &e1)
		render_fill_rect(renderer, &e2)
	}

	// Multiplier Streak Info or Bonus Timer
	if g.is_bonus_round {
		t_color := if g.bonus_timer < 5.0 { Color{ r: 255, g: 50, b: 50 } } else { Color{ r: 255, g: 220, b: 40 } }
		draw_text(renderer, 300, 560, 'BONUS TIME: ${int(g.bonus_timer + 0.9)}s', 2, t_color)
	} else if g.consecutive_count > 1 {
		draw_text(renderer, 300, 560, 'PAIR MULTIPLIER: ${g.consecutive_count}x', 2, Color{ r: 255, g: 220, b: 40 })
	} else {
		draw_text(renderer, 300, 560, 'THEME: ${g.current_theme.name}', 1, Color{ r: 160, g: 170, b: 190 })
	}

	// Controls reminder
	draw_text(renderer, 600, 562, '[SPACE] DOOR  [P] PAUSE  [F11] Fullscreen', 1, Color{ r: 150, g: 150, b: 150 })
}

fn draw_title_screen(renderer &Renderer, g &GameEngine) {
	// Arcade Marquee Background
	set_render_draw_color(renderer, 15, 10, 30, 255)
	render_clear(renderer)

	// Giant MAPPY Logo
	draw_text_centered(renderer, 400, 45, 'M A P P Y', 6, Color{ r: 255, g: 215, b: 0 })
	draw_text_centered(renderer, 400, 100, 'POLICE MOUSE ARCADE ADVENTURE', 2, Color{ r: 80, g: 220, b: 255 })

	// Difficulty Selection Box
	set_render_draw_color(renderer, 25, 20, 45, 255)
	diff_box := Rect{ x: 100, y: 135, w: 600, h: 105 }
	render_fill_rect(renderer, &diff_box)
	set_render_draw_color(renderer, 90, 70, 140, 255)
	render_draw_rect(renderer, &diff_box)

	draw_text_centered(renderer, 400, 145, 'SELECT DIFFICULTY LEVEL [PRESS 1-4 OR D]', 2, Color{ r: 255, g: 220, b: 80 })

	// 4 Difficulty Buttons
	diff_list := [Difficulty.easy, Difficulty.normal, Difficulty.hard, Difficulty.expert]
	diff_labels := ['1: EASY', '2: NORMAL', '3: HARD', '4: EXPERT']
	diff_colors := [
		Color{ r: 80, g: 240, b: 120 },
		Color{ r: 80, g: 220, b: 255 },
		Color{ r: 255, g: 170, b: 40 },
		Color{ r: 255, g: 60, b: 60 },
	]

	for i in 0 .. 4 {
		bx := 120 + i * 140
		by := 170
		is_sel := (g.difficulty == diff_list[i])

		if is_sel {
			set_render_draw_color(renderer, diff_colors[i].r, diff_colors[i].g, diff_colors[i].b, 255)
			btn_r := Rect{ x: bx, y: by, w: 125, h: 30 }
			render_draw_rect(renderer, &btn_r)
			draw_text(renderer, bx + 12, by + 8, '> ' + diff_labels[i], 1, diff_colors[i])
		} else {
			set_render_draw_color(renderer, 50, 40, 70, 255)
			btn_r := Rect{ x: bx, y: by, w: 125, h: 30 }
			render_draw_rect(renderer, &btn_r)
			draw_text(renderer, bx + 18, by + 8, diff_labels[i], 1, Color{ r: 170, g: 170, b: 180 })
		}
	}

	// Current difficulty description
	diff_desc := match g.difficulty {
		.easy { 'Cadet Mode: 5 Lives, Slower Cats, 5 Trampoline Bounces, 6s Door Stun' }
		.normal { 'Officer Mode: 3 Lives, Standard Speed, 4 Trampoline Bounces, 4.5s Stun' }
		.hard { 'Chief Detective: 2 Lives, Fast Cats, 3 Trampoline Bounces, 3s Stun' }
		.expert { 'Arcade Mania: 1 Life, Extreme Speed, 2 Goro Cats, 2 Trampoline Bounces (+50% Score!)' }
	}
	draw_text_centered(renderer, 400, 215, diff_desc, 1, Color{ r: 240, g: 240, b: 240 })

	// Animated Character Showcase Box
	set_render_draw_color(renderer, 30, 20, 50, 255)
	box := Rect{ x: 100, y: 255, w: 600, h: 175 }
	render_fill_rect(renderer, &box)
	set_render_draw_color(renderer, 100, 80, 160, 255)
	render_draw_rect(renderer, &box)

	draw_text(renderer, 130, 270, 'GAMEPLAY RULES & SCORING:', 2, Color{ r: 255, g: 220, b: 80 })
	draw_text(renderer, 130, 305, 'MAPPY (MOUSE)  - RECOVER STOLEN LOOT WITH BATON', 1, Color{ r: 255, g: 255, b: 255 })
	draw_text(renderer, 130, 328, 'NYAMCO (GORO)  - 1000 PTS BONUS WHEN FOUND HIDING', 1, Color{ r: 255, g: 100, b: 120 })
	draw_text(renderer, 130, 351, 'MICROWAVE DOOR - SUPER SHOCKWAVE SWEEPS FLOORS', 1, Color{ r: 80, g: 220, b: 255 })
	draw_text(renderer, 130, 374, 'TRAMPOLINES    - SAFE IN AIR, DISMOUNT WITH LEFT/RIGHT', 1, Color{ r: 80, g: 240, b: 120 })
	draw_text(renderer, 130, 397, 'PAIR MATCHING  - 2x 3x 4x 5x 6x CONSECUTIVE MULTIPLIERS!', 1, Color{ r: 255, g: 215, b: 0 })

	// Start Prompts
	draw_text_centered(renderer, 400, 450, 'PRESS [SPACE] OR [ENTER] TO START GAME', 2, Color{ r: 50, g: 255, b: 100 })
	draw_text_centered(renderer, 400, 485, 'PRESS [5] OR [B] FOR BALLOON BONUS STAGE', 2, Color{ r: 255, g: 220, b: 50 })
	draw_text_centered(renderer, 400, 525, 'CONTROLS: [A]/[D] OR ARROWS TO MOVE  |  [SPACE]/[W] OPEN DOOR | F11: Fullscreen', 1, Color{ r: 180, g: 180, b: 190 })
	draw_text_centered(renderer, 400, 550, '[D] CYCLE DIFFICULTY  |  [M] SOUND  |  [P] PAUSE  |  [R] RESTART | F11: Fullscreen', 1, Color{ r: 140, g: 140, b: 150 })
}

fn draw_pause_screen(renderer &Renderer) {
	set_render_draw_color(renderer, 0, 0, 0, 180)
	overlay := Rect{ x: 0, y: 0, w: 800, h: 600 }
	render_fill_rect(renderer, &overlay)
	draw_text_centered(renderer, 400, 270, 'GAME PAUSED', 4, Color{ r: 255, g: 220, b: 40 })
	draw_text_centered(renderer, 400, 330, 'PRESS [P] TO RESUME', 2, Color{ r: 255, g: 255, b: 255 })
}

fn draw_game_over_screen(renderer &Renderer, g &GameEngine) {
	set_render_draw_color(renderer, 0, 0, 0, 200)
	overlay := Rect{ x: 0, y: 0, w: 800, h: 600 }
	render_fill_rect(renderer, &overlay)
	draw_text_centered(renderer, 400, 240, 'GAME OVER', 5, Color{ r: 255, g: 50, b: 50 })
	draw_text_centered(renderer, 400, 310, 'FINAL SCORE: ${g.score}', 3, Color{ r: 255, g: 215, b: 0 })
	draw_text_centered(renderer, 400, 360, 'PRESS [SPACE] OR [R] TO PLAY AGAIN', 2, Color{ r: 255, g: 255, b: 255 })
}

fn draw_stage_clear_banner(renderer &Renderer, g &GameEngine) {
	draw_text_centered(renderer, 400, 240, 'STAGE CLEAR!', 4, Color{ r: 50, g: 255, b: 100 })
	draw_text_centered(renderer, 400, 290, 'ROUND ${g.round} COMPLETE', 2, Color{ r: 255, g: 255, b: 255 })
}

fn draw_bonus_clear_banner(renderer &Renderer, g &GameEngine) {
	draw_text_centered(renderer, 400, 230, 'BONUS ROUND COMPLETE!', 3, Color{ r: 255, g: 220, b: 40 })
	draw_text_centered(renderer, 400, 280, 'PREPARE FOR ROUND ${g.round + 1}', 2, Color{ r: 255, g: 255, b: 255 })
}
