module main

import math
import rand
import gg
import time

const win_width = 880
const win_height = 820

const cell_px = 32
const matrix_start_x = (win_width - (grid_cols * cell_px)) / 2
const matrix_start_y = 120

struct App {
mut:
	ctx           &gg.Context = unsafe { nil }
	renderer      Renderer
	last_tick     i64
	game        TetrisGame
	sound_mgr   SoundManager
	particles   []Particle
	float_texts []FloatText
	shake_timer f64
	last_drop_t u32
	mouse_x     int
	mouse_y     int
	btn_restart Button
	btn_pause   Button
	btn_music   Button
	btn_sound   Button
}

fn new_app() App {
	mut app := App{
		game:        new_tetris_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{
			x:            30
			y:            760
			w:            180
			h:            44
			text:         'RESET [R]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
		btn_pause:   Button{
			x:            230
			y:            760
			w:            180
			h:            44
			text:         'PAUSE [P]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
		btn_music:   Button{
			x:            430
			y:            760
			w:            240
			h:            44
			text:         'MUSIC: TYPE A [M]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 80
				g: 240
				b: 140
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
		btn_sound:   Button{
			x:            690
			y:            760
			w:            160
			h:            44
			text:         'SFX: ON [S]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 80
				g: 240
				b: 140
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
	}
	return app
}

fn (mut app App) get_gravity_delay() u32 {
	level := u32(app.game.level)
	if level >= 15 {
		return 80
	}
	return 700 - (level - 1) * 45
}

fn (mut app App) spawn_line_particles(cleared_lines int) {
	for _ in 0 .. cleared_lines * 15 {
		angle := rand.f64() * math.pi * 2.0
		speed := 2.0 + rand.f64() * 6.0
		cx := f64(matrix_start_x + (grid_cols * cell_px) / 2)
		cy := f64(matrix_start_y + grid_rows * cell_px - 50)
		app.particles << Particle{
			x:     cx
			y:     cy
			vx:    math.cos(angle) * speed
			vy:    math.sin(angle) * speed
			life:  1.0
			color: Color{
				r: 255
				g: 220
				b: 40
			}
			size:  3 + rand.intn(3) or { 3 }
		}
	}
}

fn (mut app App) update_particles() {
	if app.shake_timer > 0 {
		app.shake_timer -= 0.016
		if app.shake_timer < 0 {
			app.shake_timer = 0
		}
	}

	for i := app.particles.len - 1; i >= 0; i-- {
		app.particles[i].x += app.particles[i].vx
		app.particles[i].y += app.particles[i].vy
		app.particles[i].life -= 0.03
		if app.particles[i].life <= 0 {
			app.particles.delete(i)
		}
	}

	for i := app.float_texts.len - 1; i >= 0; i-- {
		app.float_texts[i].y -= 0.6
		app.float_texts[i].life -= 0.02
		if app.float_texts[i].life <= 0 {
			app.float_texts.delete(i)
		}
	}
}

fn (mut app App) handle_piece_locked(prev_level int) {
	cleared := app.game.last_cleared
	cx := f64(matrix_start_x + (grid_cols * cell_px) / 2)
	cy := f64(matrix_start_y + 220)

	if cleared > 0 {
		app.spawn_line_particles(cleared)
		app.sound_mgr.play_clear_sound(cleared)

		match cleared {
			1 {
				app.shake_timer = 0.12
				app.float_texts << FloatText{
					x: cx, y: cy, text: '+100 SINGLE', life: 1.0, color: Color{r: 255, g: 230, b: 80}, scale: 2
				}
			}
			2 {
				app.shake_timer = 0.20
				app.float_texts << FloatText{
					x: cx, y: cy, text: '+300 DOUBLE!', life: 1.2, color: Color{r: 80, g: 240, b: 140}, scale: 2
				}
			}
			3 {
				app.shake_timer = 0.28
				app.float_texts << FloatText{
					x: cx, y: cy, text: '+500 TRIPLE!!', life: 1.4, color: Color{r: 70, g: 200, b: 255}, scale: 2
				}
			}
			else {
				app.shake_timer = 0.45
				app.float_texts << FloatText{
					x: cx, y: cy, text: '★ +800 TETRIS! ★', life: 1.8, color: Color{r: 255, g: 90, b: 240}, scale: 3
				}
			}
		}

		if app.game.level > prev_level {
			app.sound_mgr.play_level_up_sound()
			app.float_texts << FloatText{
				x: cx, y: cy - 40, text: 'LEVEL UP!', life: 1.6, color: Color{r: 255, g: 215, b: 0}, scale: 2
			}
		}
	} else {
		app.sound_mgr.play_drop_sound()
		app.shake_timer = 0.06
	}
	if app.game.game_over {
		app.sound_mgr.play_game_over_sound()
	}
}

fn (mut app App) update_game_step() {
	now := u32(time.ticks())
	delay := app.get_gravity_delay()
	if now - app.last_drop_t >= delay {
		app.last_drop_t = now

		prev_level := app.game.level
		locked := app.game.step_down()
		if locked {
			app.handle_piece_locked(prev_level)
		}
	}
}

fn (mut app App) toggle_sound() {
	is_on := app.sound_mgr.toggle_sound()
	app.btn_sound.text = if is_on { 'SFX: ON [S]' } else { 'SFX: OFF [S]' }
	app.btn_sound.text_color = if is_on {
		Color{
			r: 80
			g: 240
			b: 140
		}
	} else {
		Color{
			r: 240
			g: 90
			b: 90
		}
	}
	if is_on {
		app.sound_mgr.play_click_sound()
	}
}

fn (mut app App) cycle_music() {
	new_type := app.sound_mgr.cycle_bgm()
	app.sound_mgr.play_click_sound()
	app.btn_music.text = match new_type {
		.type_a { 'MUSIC: TYPE A [M]' }
		.type_b { 'MUSIC: TYPE B [M]' }
		.type_c { 'MUSIC: TYPE C [M]' }
		.off { 'MUSIC: OFF [M]' }
		else { 'MUSIC: OFF [M]' }
	}
	app.btn_music.text_color = if new_type != .off {
		Color{
			r: 80
			g: 240
			b: 140
		}
	} else {
		Color{
			r: 240
			g: 90
			b: 90
		}
	}
}

fn (mut app App) toggle_pause() {
	app.sound_mgr.play_click_sound()
	app.game.is_paused = !app.game.is_paused
	app.btn_pause.text = if app.game.is_paused { 'RESUME [P]' } else { 'PAUSE [P]' }
}

fn (mut app App) reset_game() {
	app.sound_mgr.play_click_sound()
	app.game.reset()
	app.particles.clear()
}

fn (mut app App) handle_mouse_click(x int, y int) {
	if app.btn_restart.is_hovered(x, y) {
		app.reset_game()
		return
	}
	if app.btn_pause.is_hovered(x, y) {
		app.toggle_pause()
		return
	}
	if app.btn_music.is_hovered(x, y) {
		app.cycle_music()
		return
	}
	if app.btn_sound.is_hovered(x, y) {
		app.toggle_sound()
		return
	}
}

fn (mut app App) render() {
	set_render_draw_color(&app.renderer, 15, 18, 30, 255)
	render_clear(&app.renderer)

	// Top Title Header
	draw_text_centered(&app.renderer, win_width / 2, 14, 'MODERN TETRIS', 3, Color{
		r: 255
		g: 255
		b: 255
	})

	// Glassmorphic Score Cards Header Row
	draw_glass_card(&app.renderer, 40, 50, 240, 44, Color{ r: 40, g: 220, b: 240 })
	draw_text_centered(&app.renderer, 160, 64, 'SCORE: ${app.game.score}', 2, Color{
		r: 100
		g: 240
		b: 255
	})

	draw_glass_card(&app.renderer, win_width - 280, 50, 240, 44, Color{ r: 245, g: 215, b: 40 })
	draw_text_centered(&app.renderer, win_width - 160, 64, 'LEVEL: ${app.game.level}',
		2, Color{ r: 255, g: 235, b: 120 })

	// Status Badge
	mut status_text := 'PLAYING'
	mut status_color := Color{
		r: 80
		g: 240
		b: 140
	}
	mut badge_border := Color{
		r: 50
		g: 200
		b: 120
	}

	if app.game.game_over {
		status_text = 'GAME OVER! PRESS [R]'
		status_color = Color{
			r: 255
			g: 80
			b: 90
		}
		badge_border = Color{
			r: 235
			g: 45
			b: 60
		}
	} else if app.game.is_paused {
		status_text = 'PAUSED'
		status_color = Color{
			r: 255
			g: 220
			b: 60
		}
		badge_border = Color{
			r: 255
			g: 200
			b: 25
		}
	}

	draw_glass_card(&app.renderer, win_width / 2 - 170, 50, 340, 44, badge_border)
	draw_text_centered(&app.renderer, win_width / 2, 64, status_text, 2, status_color)

	// Left Box: HOLD PIECE Card
	draw_glass_card(&app.renderer, 40, 120, 200, 180, Color{ r: 90, g: 110, b: 160 })
	draw_text_centered(&app.renderer, 140, 134, 'HOLD [C]', 2, Color{ r: 200, g: 215, b: 240 })
	if app.game.has_hold && app.game.hold_piece.kind > 0 {
		h_size := app.game.hold_piece.matrix.len
		ox := 140 - (h_size * 22) / 2
		oy := 200 - (h_size * 22) / 2
		for r in 0 .. h_size {
			for c in 0 .. h_size {
				k := app.game.hold_piece.matrix[r][c]
				if k != 0 {
					draw_block(&app.renderer, ox + c * 22, oy + r * 22, 20, k, false)
				}
			}
		}
	}

	// Right Box: NEXT PIECE Card
	draw_glass_card(&app.renderer, win_width - 240, 120, 200, 180, Color{ r: 90, g: 110, b: 160 })
	draw_text_centered(&app.renderer, win_width - 140, 134, 'NEXT', 2, Color{ r: 200, g: 215, b: 240 })
	if app.game.next_piece.kind > 0 {
		n_size := app.game.next_piece.matrix.len
		ox := win_width - 140 - (n_size * 22) / 2
		oy := 200 - (n_size * 22) / 2
		for r in 0 .. n_size {
			for c in 0 .. n_size {
				k := app.game.next_piece.matrix[r][c]
				if k != 0 {
					draw_block(&app.renderer, ox + c * 22, oy + r * 22, 20, k, false)
				}
			}
		}
	}

	// Stats Panel Card below Hold Box
	draw_glass_card(&app.renderer, 40, 320, 200, 160, Color{ r: 90, g: 110, b: 160 })
	draw_text_centered(&app.renderer, 140, 336, 'STATS', 2, Color{ r: 200, g: 215, b: 240 })
	draw_text(&app.renderer, 55, 380, 'LINES: ${app.game.lines}', 2, Color{ r: 255, g: 255, b: 255 })

	// Main 10x20 Matrix Grid Fill & Frame with Screen Shake
	mut mx := matrix_start_x
	mut my := matrix_start_y
	if app.shake_timer > 0 {
		shake_mag := app.shake_timer * 22.0
		mx += int((rand.f64() * 2.0 - 1.0) * shake_mag)
		my += int((rand.f64() * 2.0 - 1.0) * shake_mag)
	}

	matrix_rect := Rect{
		x: mx
		y: my
		w: grid_cols * cell_px
		h: grid_rows * cell_px
	}
	set_render_draw_color(&app.renderer, 20, 26, 42, 255)
	render_fill_rect(&app.renderer, &matrix_rect)

	// Outer Matrix Border
	set_render_draw_color(&app.renderer, 45, 60, 95, 255)
	render_draw_rect(&app.renderer, &matrix_rect)

	// Subtle Grid Background Lines
	set_render_draw_color(&app.renderer, 25, 33, 54, 255)
	for c in 1 .. grid_cols {
		gx := mx + c * cell_px
		render_draw_line(&app.renderer, gx, my, gx, my +
			grid_rows * cell_px)
	}
	for r in 1 .. grid_rows {
		gy := my + r * cell_px
		render_draw_line(&app.renderer, mx, gy, mx + grid_cols * cell_px,
			gy)
	}

	// Draw Locked Grid Blocks
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			k := app.game.grid[r][c]
			if k != 0 {
				draw_block(&app.renderer, mx + c * cell_px, my + r * cell_px,
					cell_px, k, false)
			}
		}
	}

	// Draw Ghost Piece Projection
	if !app.game.game_over && !app.game.is_paused {
		ghost_y := app.game.get_ghost_y()
		p := app.game.curr_piece
		size := p.matrix.len
		for r in 0 .. size {
			for c in 0 .. size {
				k := p.matrix[r][c]
				if k != 0 {
					bx := mx + (p.x + c) * cell_px
					by := my + (ghost_y + r) * cell_px
					draw_block(&app.renderer, bx, by, cell_px, k, true)
				}
			}
		}

		// Draw Active Falling Piece
		for r in 0 .. size {
			for c in 0 .. size {
				k := p.matrix[r][c]
				if k != 0 {
					bx := mx + (p.x + c) * cell_px
					by := my + (p.y + r) * cell_px
					draw_block(&app.renderer, bx, by, cell_px, k, false)
				}
			}
		}
	}

	// Render Particles
	for p in app.particles {
		draw_filled_circle(&app.renderer, int(p.x), int(p.y), p.size, Color{
			r: p.color.r
			g: p.color.g
			b: p.color.b
			a: u8(p.life * 255.0)
		})
	}

	// Render Floating Reward Texts
	for ft in app.float_texts {
		draw_text_centered(&app.renderer, int(ft.x), int(ft.y), ft.text, ft.scale, ft.color)
	}

	// Draw Control Buttons
	app.btn_restart.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_pause.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_music.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.draw(&app.renderer, app.mouse_x, app.mouse_y)

	
	
}


fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	if app.shake_timer > 0 {
		app.shake_timer -= dt
		if app.shake_timer < 0 { app.shake_timer = 0 }
	}

	app.update_game_step()
	app.update_particles()
	app.sound_mgr.update_bgm(!app.game.is_paused && !app.game.game_over)
	app.sound_mgr.update()

	app.render()
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	if e.typ in [.mouse_move, .mouse_down, .mouse_up, .mouse_scroll] && app.renderer.scale > 0.001 {
		mut me := unsafe { &gg.Event(e) }
		me.mouse_x = (e.mouse_x - app.renderer.offset_x) / app.renderer.scale
		me.mouse_y = (e.mouse_y - app.renderer.offset_y) / app.renderer.scale
	}
	match e.typ {
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			app.handle_mouse_click(mx, my)
		}
		.key_down {
			match e.key_code {
				.f11, .grave_accent {
					gg.toggle_fullscreen()
				}
				.f10 {
					prod_fx_cycle_mode()
				}
				.escape {
					exit(0)
				}
				.left, .a {
					if !app.game.is_paused && !app.game.game_over {
						if app.game.move_left() {
							app.sound_mgr.play_move_sound()
						}
					}
				}
				.right, .d {
					if !app.game.is_paused && !app.game.game_over {
						if app.game.move_right() {
							app.sound_mgr.play_move_sound()
						}
					}
				}
				.down {
					if !app.game.is_paused && !app.game.game_over {
						prev_level := app.game.level
						locked := app.game.step_down()
						if locked {
							app.handle_piece_locked(prev_level)
						}
					}
				}
				.up, .w {
					if !app.game.is_paused && !app.game.game_over {
						if app.game.rotate() {
							app.sound_mgr.play_rotate_sound()
						}
					}
				}
				.z {
					if !app.game.is_paused && !app.game.game_over {
						if app.game.rotate() {
							app.sound_mgr.play_rotate_sound()
						}
					}
				}
				.space {
					if !app.game.is_paused && !app.game.game_over {
						prev_level := app.game.level
						_ = app.game.hard_drop()
						app.handle_piece_locked(prev_level)
					}
				}
				.c {
					if !app.game.is_paused && !app.game.game_over {
						if app.game.hold() {
							app.sound_mgr.play_hold_sound()
						}
					}
				}
				.p {
					app.toggle_pause()
				}
				.r {
					app.reset_game()
				}
				.m {
					app.cycle_music()
				}
				.s, .n {
					app.toggle_sound()
				}
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width: win_width
		height: win_height
		resizable:     true
		window_title: 'Modern Tetris // Arcade Neon'
		user_data: &app
		frame_fn: on_frame
		event_fn: on_event
		bg_color: gg.Color{15, 18, 30, 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{ctx: ctx}
	ctx.run()
}
