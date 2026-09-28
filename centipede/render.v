module main

import rand
import time

struct Button {
pub mut:
	x            int
	y            int
	w            int
	h            int
	text         string
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
}

fn (b Button) contains(x int, y int) bool {
	return x >= b.x && x <= b.x + b.w && y >= b.y && y <= b.y + b.h
}

fn (b Button) draw(renderer &Renderer, mouse_x int, mouse_y int) {
	is_hover := b.contains(mouse_x, mouse_y)
	bg := if is_hover { b.hover_color } else { b.bg_color }

	rect := Rect{
		x: b.x
		y: b.y
		w: b.w
		h: b.h
	}
	set_render_draw_color(renderer, bg.r, bg.g, bg.b, bg.a)
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, b.border_color.a)
	render_draw_rect(renderer, &rect)

	draw_text_centered(renderer, b.x + b.w / 2, b.y + (b.h - 16) / 2, b.text, 2, b.text_color)
}

fn render_game(renderer &Renderer, game &CentipedeGame, mouse_x int, mouse_y int, btn_restart Button, btn_sound Button, btn_pause Button) {
	shake_mag := game.shake_trauma * game.shake_trauma * 16.0
	sx := if shake_mag > 0.01 { f32((rand.f64() * 2.0 - 1.0) * shake_mag) } else { f32(0.0) }
	sy := if shake_mag > 0.01 { f32((rand.f64() * 2.0 - 1.0) * shake_mag) } else { f32(0.0) }
	unsafe {
		mut ren := &Renderer(renderer)
		ren.offset_x += sx
		ren.offset_y += sy
	}
	defer {
		unsafe {
			mut ren := &Renderer(renderer)
			ren.offset_x -= sx
			ren.offset_y -= sy
		}
	}

	// Clear window with dark background
	set_render_draw_color(renderer, 10, 12, 22, 255)
	render_clear(renderer)

	// Draw Playfield Frame & Grid
	draw_playfield(renderer)

	// Draw Mushrooms
	draw_mushrooms(renderer, game)

	// Draw Centipedes
	draw_centipedes(renderer, game)

	// Draw Fleas
	draw_fleas(renderer, game)

	// Draw Spiders
	draw_spiders(renderer, game)

	// Draw Scorpions
	draw_scorpions(renderer, game)

	// Draw Lasers
	draw_lasers(renderer, game)

	// Draw Power-ups
	draw_powerups(renderer, game)

	// Draw Player
	if game.player.is_alive {
		draw_player(renderer, game)
	}

	// Draw Particles
	draw_particles(renderer, game)

	// Draw Score Popups
	draw_popups(renderer, game)

	// Draw Top HUD Bar
	draw_hud(renderer, game)

	// Draw Active Powerup Badges
	draw_powerup_badges(renderer, game)

	// Draw Bottom Buttons
	btn_restart.draw(renderer, mouse_x, mouse_y)
	btn_sound.draw(renderer, mouse_x, mouse_y)
	btn_pause.draw(renderer, mouse_x, mouse_y)

	// Draw Overlays
	if game.paused {
		draw_overlay_text(renderer, 'GAME PAUSED', 'PRESS [P] TO RESUME')
	} else if game.game_over {
		draw_overlay_text(renderer, 'GAME OVER', 'PRESS [R] OR CLICK RESTART')
	} else if game.wave_cleared {
		draw_overlay_text(renderer, 'WAVE ${game.wave} CLEARED!', 'REGENERATING MUSHROOMS...')
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}

fn draw_playfield(renderer &Renderer) {
	// Playfield Background (darker green/cyber grid)
	pf_rect := Rect{
		x: int(playfield_offset_x)
		y: int(playfield_offset_y)
		w: int(playfield_width)
		h: int(playfield_height)
	}
	set_render_draw_color(renderer, 15, 20, 30, 255)
	render_fill_rect(renderer, &pf_rect)

	// Outer Neon Border
	set_render_draw_color(renderer, 0, 220, 180, 255)
	render_draw_rect(renderer, &pf_rect)

	// Player Zone Line (Row 24 boundary)
	pz_y := int(playfield_offset_y + 24.0 * tile_size)
	set_render_draw_color(renderer, 255, 100, 100, 100)
	render_draw_line(renderer, int(playfield_offset_x), pz_y, int(playfield_offset_x + playfield_width), pz_y)
}

fn draw_mushrooms(renderer &Renderer, game &CentipedeGame) {
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			mush := game.grid[r][c]
			if !mush.exists {
				continue
			}

			mx := int(playfield_offset_x + f64(c) * tile_size)
			my := int(playfield_offset_y + f64(r) * tile_size)

			if game.sprite_texture != unsafe { nil } {
				mut sx := 0
				if mush.is_poison {
					sx = 128
				} else if mush.has_powerup {
					sx = 160
				} else {
					sx = match mush.hp {
						4 { 0 }
						3 { 32 }
						2 { 64 }
						else { 96 }
					}
				}
				src := Rect{ x: sx, y: 32, w: 32, h: 32 }
				dst := Rect{ x: mx, y: my, w: 20, h: 20 }
				render_copy(renderer, game.sprite_texture, &src, &dst)
				continue
			}

			// Mushroom Colors based on poison & hp
			mut cap_color := Color{r: 80, g: 220, b: 120} // normal green
			if mush.is_poison {
				cap_color = Color{r: 230, g: 60, b: 230} // poison purple
			} else if mush.has_powerup {
				cap_color = Color{r: 255, g: 220, b: 50} // gold powerup
			} else if mush.hp < 4 {
				// Damaged fade
				factor := u8(140 + mush.hp * 25)
				cap_color = Color{r: 40, g: factor, b: 90}
			}

			// Draw Stem
			stem_rect := Rect{
				x: mx + 7
				y: my + 10
				w: 6
				h: 8
			}
			set_render_draw_color(renderer, 200, 200, 180, 255)
			render_fill_rect(renderer, &stem_rect)

			// Draw Mushroom Cap (Semi-dome)
			cap_rect := Rect{
				x: mx + 3
				y: my + 3
				w: 14
				h: 9
			}
			set_render_draw_color(renderer, cap_color.r, cap_color.g, cap_color.b, cap_color.a)
			render_fill_rect(renderer, &cap_rect)

			// Dots on Cap
			set_render_draw_color(renderer, 255, 255, 255, 200)
			dot1 := Rect{x: mx + 5, y: my + 5, w: 3, h: 3}
			dot2 := Rect{x: mx + 12, y: my + 5, w: 3, h: 3}
			render_fill_rect(renderer, &dot1)
			render_fill_rect(renderer, &dot2)
		}
	}
}

fn draw_centipedes(renderer &Renderer, game &CentipedeGame) {
	ticks := time.ticks()
	frame := if (ticks / 200) % 2 == 0 { 0 } else { 1 }

	for chain in game.chains {
		for seg in chain.segments {
			sx := int(playfield_offset_x + (f64(seg.col) + seg.sub_x) * tile_size)
			sy := int(playfield_offset_y + (f64(seg.row) + seg.sub_y) * tile_size)

			if game.sprite_texture != unsafe { nil } {
				mut src_x := 0
				if seg.is_head {
					src_x = if seg.is_poisoned { 128 } else { 64 + frame * 32 }
				} else {
					src_x = if seg.is_poisoned { 224 } else { 160 + frame * 32 }
				}
				src := Rect{ x: src_x, y: 0, w: 32, h: 32 }
				dst := Rect{ x: sx - 10, y: sy - 10, w: 20, h: 20 }
				render_copy(renderer, game.sprite_texture, &src, &dst)
				continue
			}

			if seg.is_head {
				// Head drawing (glowing red/cyan with antennae)
				radius := 9
				if game.is_boss_wave {
					// Boss Mega Head
					set_render_draw_color(renderer, 255, 215, 0, 255)
				} else if seg.is_poisoned {
					set_render_draw_color(renderer, 255, 0, 255, 255)
				} else {
					set_render_draw_color(renderer, 255, 60, 60, 255)
				}

				head_rect := Rect{
					x: sx - radius
					y: sy - radius
					w: radius * 2
					h: radius * 2
				}
				render_fill_rect(renderer, &head_rect)

				// Eyes
				set_render_draw_color(renderer, 255, 255, 255, 255)
				e1 := Rect{x: sx - 5, y: sy - 4, w: 4, h: 4}
				e2 := Rect{x: sx + 1, y: sy - 4, w: 4, h: 4}
				render_fill_rect(renderer, &e1)
				render_fill_rect(renderer, &e2)
			} else {
				// Body Segment (glowing green/yellow circle)
				radius := 7
				if seg.is_poisoned {
					set_render_draw_color(renderer, 200, 50, 200, 255)
				} else {
					set_render_draw_color(renderer, 60, 220, 100, 255)
				}

				body_rect := Rect{
					x: sx - radius
					y: sy - radius
					w: radius * 2
					h: radius * 2
				}
				render_fill_rect(renderer, &body_rect)

				// Legs (small side pixels)
				set_render_draw_color(renderer, 255, 255, 100, 255)
				l1 := Rect{x: sx - 10, y: sy - 2, w: 3, h: 4}
				l2 := Rect{x: sx + 7, y: sy - 2, w: 3, h: 4}
				render_fill_rect(renderer, &l1)
				render_fill_rect(renderer, &l2)
			}
		}
	}
}

fn draw_fleas(renderer &Renderer, game &CentipedeGame) {
	ticks := time.ticks()
	frame := if (ticks / 150) % 2 == 0 { 0 } else { 1 }

	for flea in game.fleas {
		fx := int(playfield_offset_x + f64(flea.col) * tile_size + 10.0)
		fy := int(flea.y)

		if game.sprite_texture != unsafe { nil } {
			src := Rect{ x: frame * 32, y: 64, w: 32, h: 32 }
			dst := Rect{ x: fx - 10, y: fy - 10, w: 20, h: 20 }
			render_copy(renderer, game.sprite_texture, &src, &dst)
			continue
		}

		set_render_draw_color(renderer, 100, 255, 150, 255)
		f_rect := Rect{
			x: fx - 6
			y: fy - 8
			w: 12
			h: 16
		}
		render_fill_rect(renderer, &f_rect)

		// Flea detail
		set_render_draw_color(renderer, 255, 255, 255, 255)
		f_eye := Rect{x: fx - 3, y: fy - 5, w: 6, h: 4}
		render_fill_rect(renderer, &f_eye)
	}
}

fn draw_spiders(renderer &Renderer, game &CentipedeGame) {
	ticks := time.ticks()
	frame := if (ticks / 180) % 2 == 0 { 0 } else { 1 }

	for spider in game.spiders {
		sx := int(spider.x)
		sy := int(spider.y)

		if game.sprite_texture != unsafe { nil } {
			src := Rect{ x: 64 + frame * 32, y: 64, w: 32, h: 32 }
			dst := Rect{ x: sx - 12, y: sy - 12, w: 24, h: 24 }
			render_copy(renderer, game.sprite_texture, &src, &dst)
			continue
		}

		// Gold 8-Legged Spider
		set_render_draw_color(renderer, 255, 210, 40, 255)
		body := Rect{x: sx - 8, y: sy - 8, w: 16, h: 16}
		render_fill_rect(renderer, &body)

		// Legs
		set_render_draw_color(renderer, 255, 160, 20, 255)
		l1 := Rect{x: sx - 14, y: sy - 6, w: 6, h: 3}
		l2 := Rect{x: sx + 8, y: sy - 6, w: 6, h: 3}
		l3 := Rect{x: sx - 14, y: sy + 3, w: 6, h: 3}
		l4 := Rect{x: sx + 8, y: sy + 3, w: 6, h: 3}
		render_fill_rect(renderer, &l1)
		render_fill_rect(renderer, &l2)
		render_fill_rect(renderer, &l3)
		render_fill_rect(renderer, &l4)
	}
}

fn draw_scorpions(renderer &Renderer, game &CentipedeGame) {
	ticks := time.ticks()
	frame := if (ticks / 200) % 2 == 0 { 0 } else { 1 }

	for scorp in game.scorpions {
		sx := int(scorp.x)
		sy := int(playfield_offset_y + f64(scorp.row) * tile_size + 10.0)

		if game.sprite_texture != unsafe { nil } {
			src := Rect{ x: 128 + frame * 32, y: 64, w: 32, h: 32 }
			dst := Rect{ x: sx - 12, y: sy - 10, w: 24, h: 20 }
			render_copy(renderer, game.sprite_texture, &src, &dst)
			continue
		}

		// Bright Magenta Scorpion
		set_render_draw_color(renderer, 255, 40, 180, 255)
		body := Rect{x: sx - 10, y: sy - 6, w: 20, h: 12}
		render_fill_rect(renderer, &body)

		// Claws
		claw_x := if scorp.dir_x > 0 { sx + 8 } else { sx - 14 }
		claw := Rect{x: claw_x, y: sy - 8, w: 6, h: 16}
		render_fill_rect(renderer, &claw)
	}
}

fn draw_lasers(renderer &Renderer, game &CentipedeGame) {
	for laser in game.lasers {
		lx := int(laser.x)
		ly := int(laser.y)

		if laser.is_plasma {
			set_render_draw_color(renderer, 220, 80, 255, 255)
			l_rect := Rect{x: lx - 4, y: ly, w: 8, h: 18}
			render_fill_rect(renderer, &l_rect)
		} else {
			set_render_draw_color(renderer, 0, 255, 255, 255)
			l_rect := Rect{x: lx - 2, y: ly, w: 4, h: 12}
			render_fill_rect(renderer, &l_rect)
		}
	}
}

fn draw_powerups(renderer &Renderer, game &CentipedeGame) {
	for pow in game.powerups {
		px := int(pow.x)
		py := int(pow.y)

		if game.sprite_texture != unsafe { nil } {
			sx := match pow.ptype {
				.rapid_fire { 0 }
				.triple_spread { 32 }
				.plasma_beam { 64 }
				.emp_nuke { 96 }
				.shield { 128 }
				.speed_dash { 160 }
				else { 0 }
			}
			src := Rect{ x: sx, y: 96, w: 32, h: 32 }
			dst := Rect{ x: px - 10, y: py - 10, w: 20, h: 20 }
			render_copy(renderer, game.sprite_texture, &src, &dst)
			continue
		}

		mut col := Color{r: 255, g: 255, b: 255}
		mut label := 'P'
		match pow.ptype {
			.rapid_fire { col = Color{r: 80, g: 255, b: 120}; label = 'R' }
			.triple_spread { col = Color{r: 255, g: 150, b: 50}; label = '3' }
			.plasma_beam { col = Color{r: 200, g: 80, b: 255}; label = 'P' }
			.emp_nuke { col = Color{r: 255, g: 50, b: 80}; label = 'E' }
			.shield { col = Color{r: 50, g: 200, b: 255}; label = 'S' }
			.speed_dash { col = Color{r: 255, g: 255, b: 100}; label = 'V' }
			else {}
		}

		// Draw Glowing Pill
		rect := Rect{x: px - 8, y: py - 8, w: 16, h: 16}
		set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
		render_fill_rect(renderer, &rect)

		draw_text_centered(renderer, px, py - 4, label, 1, Color{r: 0, g: 0, b: 0})
	}
}

fn draw_player(renderer &Renderer, game &CentipedeGame) {
	px := int(game.player.x)
	py := int(game.player.y)

	if game.sprite_texture != unsafe { nil } {
		src_x := if game.timer_shield > 0.0 || game.timer_plasma_beam > 0.0 { 32 } else { 0 }
		src := Rect{ x: src_x, y: 0, w: 32, h: 32 }
		dst := Rect{ x: px - 12, y: py - 12, w: 24, h: 24 }
		render_copy(renderer, game.sprite_texture, &src, &dst)

		if game.timer_shield > 0.0 {
			set_render_draw_color(renderer, 80, 220, 255, 180)
			s_rect := Rect{x: px - 16, y: py - 16, w: 32, h: 32}
			render_draw_rect(renderer, &s_rect)
		}
		return
	}

	// Draw Bugblaster Cannon
	set_render_draw_color(renderer, 255, 255, 255, 255)

	// Cannon Nozzle
	n_rect := Rect{x: px - 3, y: py - 14, w: 6, h: 8}
	render_fill_rect(renderer, &n_rect)

	// Base Triangle / Ship
	ship_rect := Rect{x: px - 10, y: py - 6, w: 20, h: 12}
	set_render_draw_color(renderer, 0, 200, 255, 255)
	render_fill_rect(renderer, &ship_rect)

	// Shield Halo
	if game.timer_shield > 0.0 {
		set_render_draw_color(renderer, 50, 200, 255, 180)
		s_rect := Rect{x: px - 16, y: py - 18, w: 32, h: 32}
		render_draw_rect(renderer, &s_rect)
	}
}

fn draw_particles(renderer &Renderer, game &CentipedeGame) {
	for p in game.particles {
		px := int(p.x)
		py := int(p.y)
		alpha := u8(f64(p.color.a) * (p.life / p.max_life))
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		p_rect := Rect{x: px - 1, y: py - 1, w: 3, h: 3}
		render_fill_rect(renderer, &p_rect)
	}
}

fn draw_popups(renderer &Renderer, game &CentipedeGame) {
	for pop in game.popups {
		px := int(pop.x)
		py := int(pop.y)
		draw_text_centered(renderer, px, py, pop.text, 1, pop.color)
	}
}

fn draw_hud(renderer &Renderer, game &CentipedeGame) {
	// Score
	draw_text(renderer, 20, 10, 'SCORE: ${game.score}', 2, Color{r: 255, g: 255, b: 255})

	// High Score
	draw_text_centered(renderer, 400, 10, 'HIGH: ${game.high_score}', 2, Color{r: 255, g: 215, b: 0})

	// Wave
	draw_text(renderer, 670, 10, 'WAVE: ${game.wave}', 2, Color{r: 80, g: 220, b: 255})

	// Lives Icons
	for i in 0 .. game.lives {
		lx := 20 + i * 22
		ly := 36
		set_render_draw_color(renderer, 0, 200, 255, 255)
		l_rect := Rect{x: lx, y: ly, w: 14, h: 10}
		render_fill_rect(renderer, &l_rect)
	}
}

fn draw_powerup_badges(renderer &Renderer, game &CentipedeGame) {
	mut start_x := 110
	by := 645

	if game.timer_rapid_fire > 0.0 {
		draw_badge(renderer, start_x, by, 'RAPID', game.timer_rapid_fire, Color{r: 80, g: 255, b: 120})
		start_x += 95
	}
	if game.timer_triple_shot > 0.0 {
		draw_badge(renderer, start_x, by, 'TRIPLE', game.timer_triple_shot, Color{r: 255, g: 150, b: 50})
		start_x += 95
	}
	if game.timer_plasma_beam > 0.0 {
		draw_badge(renderer, start_x, by, 'PLASMA', game.timer_plasma_beam, Color{r: 200, g: 80, b: 255})
		start_x += 95
	}
	if game.timer_shield > 0.0 {
		draw_badge(renderer, start_x, by, 'SHIELD', game.timer_shield, Color{r: 50, g: 200, b: 255})
		start_x += 95
	}
	if game.timer_speed_dash > 0.0 {
		draw_badge(renderer, start_x, by, 'SPEED', game.timer_speed_dash, Color{r: 255, g: 255, b: 100})
		start_x += 95
	}
}

fn draw_badge(renderer &Renderer, x int, y int, label string, time_left f64, color Color) {
	rect := Rect{x: x, y: y, w: 85, h: 22}
	set_render_draw_color(renderer, color.r, color.g, color.b, 100)
	render_fill_rect(renderer, &rect)
	set_render_draw_color(renderer, color.r, color.g, color.b, 255)
	render_draw_rect(renderer, &rect)

	draw_text(renderer, x + 5, y + 4, '${label} ${int(time_left + 0.9)}s', 1, Color{r: 255, g: 255, b: 255})
}

fn draw_overlay_text(renderer &Renderer, title string, subtitle string) {
	// Semi-transparent backdrop
	rect := Rect{x: 150, y: 240, w: 500, h: 160}
	set_render_draw_color(renderer, 10, 15, 25, 230)
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, 0, 220, 180, 255)
	render_draw_rect(renderer, &rect)

	draw_text_centered(renderer, 400, 270, title, 3, Color{r: 255, g: 230, b: 80})
	draw_text_centered(renderer, 400, 330, subtitle, 2, Color{r: 200, g: 200, b: 200})
}
