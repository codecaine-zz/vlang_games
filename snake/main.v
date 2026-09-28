module main

import gg
import math
import rand
import time

const win_width = 880
const win_height = 740

const cell_px = 32
const grid_start_x = (win_width - (grid_cols * cell_px)) / 2
const grid_start_y = 110

struct Particle {
mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	color gg.Color
	size  int
}

struct App {
mut:
	ctx		&gg.Context = unsafe { nil }
	renderer	Renderer
	// ctx           &gg.Context = unsafe { nil }
	game          SnakeGame
	sound_mgr     SoundManager
	tex_mgr       SnakeTextureManager
	particles     []Particle
	shake_timer   f64
	last_step_t   i64
	step_interval i64 = 110
	mouse_x       int
	mouse_y       int
	btn_restart   Button
	btn_pause     Button
	btn_sound     Button
}

fn new_app() App {
	mut app := App{
		game:        new_snake_game()
		sound_mgr:   new_sound_manager()
		tex_mgr:     new_snake_texture_manager()
		btn_restart: Button{
			x:            100
			y:            680
			w:            200
			h:            44
			text:         'RESTART [R]'
			bg_color:     gg.Color{r: 35, g: 45, b: 70, a: 255}
			hover_color:  gg.Color{r: 55, g: 70, b: 105, a: 255}
			text_color:   gg.Color{r: 255, g: 255, b: 255, a: 255}
			border_color: gg.Color{r: 85, g: 105, b: 150, a: 255}
		}
		btn_pause:   Button{
			x:            340
			y:            680
			w:            200
			h:            44
			text:         'PAUSE [P]'
			bg_color:     gg.Color{r: 35, g: 45, b: 70, a: 255}
			hover_color:  gg.Color{r: 55, g: 70, b: 105, a: 255}
			text_color:   gg.Color{r: 255, g: 255, b: 255, a: 255}
			border_color: gg.Color{r: 85, g: 105, b: 150, a: 255}
		}
		btn_sound:   Button{
			x:            580
			y:            680
			w:            200
			h:            44
			text:         'SOUND: ON [S]'
			bg_color:     gg.Color{r: 35, g: 45, b: 70, a: 255}
			hover_color:  gg.Color{r: 55, g: 70, b: 105, a: 255}
			text_color:   gg.Color{r: 80, g: 240, b: 140, a: 255}
			border_color: gg.Color{r: 85, g: 105, b: 150, a: 255}
		}
		last_step_t: time.ticks()
	}
	return app
}

fn (mut app App) spawn_eat_particles(pt Point, is_gold bool) {
	cx := f64(grid_start_x + pt.x * cell_px + cell_px / 2)
	cy := f64(grid_start_y + pt.y * cell_px + cell_px / 2)
	p_color := if is_gold {
		gg.Color{r: 255, g: 220, b: 40, a: 255}
	} else {
		gg.Color{r: 255, g: 60, b: 80, a: 255}
	}

	count := if is_gold { 25 } else { 12 }
	for _ in 0 .. count {
		angle := rand.f64() * math.pi * 2.0
		speed := 1.5 + rand.f64() * 5.0
		app.particles << Particle{
			x:     cx
			y:     cy
			vx:    math.cos(angle) * speed
			vy:    math.sin(angle) * speed
			life:  1.0
			color: p_color
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
}

fn (mut app App) update_game_step() {
	now := time.ticks()
	if now - app.last_step_t >= app.step_interval {
		app.last_step_t = now

		ate_reg, ate_gold := app.game.step()
		if ate_reg {
			app.sound_mgr.play_eat_sound(app.game.body.len)
			app.spawn_eat_particles(app.game.body[0], false)
			app.shake_timer = 0.08
		} else if ate_gold {
			app.sound_mgr.play_gold_sound()
			app.spawn_eat_particles(app.game.body[0], true)
			app.shake_timer = 0.16
		} else if app.game.game_over {
			app.sound_mgr.play_die_sound()
			app.shake_timer = 0.35
			if app.game.body.len > 0 {
				app.spawn_eat_particles(app.game.body[0], false)
			}
		}
	}
}

fn (mut app App) toggle_sound() {
	is_on := app.sound_mgr.toggle_sound()
	app.btn_sound.text = if is_on { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
	app.btn_sound.text_color = if is_on {
		gg.Color{r: 80, g: 240, b: 140, a: 255}
	} else {
		gg.Color{r: 240, g: 90, b: 90, a: 255}
	}
	if is_on {
		app.sound_mgr.play_click_sound()
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
	if app.btn_sound.is_hovered(x, y) {
		app.toggle_sound()
		return
	}
}

fn (mut app App) render() {
	ctx := app.ctx

	app.renderer.draw_rect_filled(0, 0, win_width, win_height, gg.Color{r: 14, g: 18, b: 28, a: 255})

	// Top Title Header
	app.renderer.draw_text(win_width / 2, 28, 'CYBERPUNK SNAKE',
		size:          28
		color:         gg.white
		align:         .center
		vertical_align: .middle
	)

	// Glassmorphic Score Cards
	draw_glass_card(&app.renderer, 40, 50, 240, 42, gg.Color{r: 50, g: 220, b: 130, a: 255})
	app.renderer.draw_text(160, 71, 'SCORE: ${app.game.score}',
		size:          20
		color:         gg.Color{r: 100, g: 255, b: 160, a: 255}
		align:         .center
		vertical_align: .middle
	)

	draw_glass_card(&app.renderer, win_width - 280, 50, 240, 42, gg.Color{r: 255, g: 200, b: 40, a: 255})
	app.renderer.draw_text(win_width - 160, 71, 'HIGH: ${app.game.high_score}',
		size:          20
		color:         gg.Color{r: 255, g: 235, b: 120, a: 255}
		align:         .center
		vertical_align: .middle
	)

	// Status Badge
	mut status_text := 'PLAYING'
	mut status_color := gg.Color{r: 80, g: 240, b: 140, a: 255}
	mut badge_border := gg.Color{r: 50, g: 200, b: 120, a: 255}

	if app.game.game_over {
		status_text = 'GAME OVER! PRESS [R]'
		status_color = gg.Color{r: 255, g: 80, b: 90, a: 255}
		badge_border = gg.Color{r: 235, g: 45, b: 60, a: 255}
	} else if app.game.is_paused {
		status_text = 'PAUSED'
		status_color = gg.Color{r: 255, g: 220, b: 60, a: 255}
		badge_border = gg.Color{r: 255, g: 200, b: 25, a: 255}
	}

	draw_glass_card(&app.renderer, win_width / 2 - 170, 50, 340, 42, badge_border)
	app.renderer.draw_text(win_width / 2, 71, status_text,
		size:          20
		color:         status_color
		align:         .center
		vertical_align: .middle
	)

	// Main Grid Matrix Area with Screen Shake
	mut gx := grid_start_x
	mut gy := grid_start_y
	if app.shake_timer > 0 {
		shake_mag := app.shake_timer * 18.0
		gx += int((rand.f64() * 2.0 - 1.0) * shake_mag)
		gy += int((rand.f64() * 2.0 - 1.0) * shake_mag)
	}

	app.renderer.draw_rect_filled(f32(gx), f32(gy), f32(grid_cols * cell_px), f32(grid_rows * cell_px), gg.Color{r: 20, g: 26, b: 42, a: 255})
	app.renderer.draw_rect_empty(f32(gx), f32(gy), f32(grid_cols * cell_px), f32(grid_rows * cell_px), gg.Color{r: 45, g: 60, b: 95, a: 255})

	// Subtle Grid Lines
	grid_line_col := gg.Color{r: 25, g: 33, b: 54, a: 255}
	for c in 1 .. grid_cols {
		line_x := f32(gx + c * cell_px)
		app.renderer.draw_line(line_x, f32(gy), line_x, f32(gy + grid_rows * cell_px), grid_line_col)
	}
	for r in 1 .. grid_rows {
		line_y := f32(gy + r * cell_px)
		app.renderer.draw_line(f32(gx), line_y, f32(gx + grid_cols * cell_px), line_y, grid_line_col)
	}

	// Draw Food Sprite
	fx := gx + app.game.food.x * cell_px
	fy := gy + app.game.food.y * cell_px
	draw_food_sprite(&app.renderer, fx, fy, cell_px, false, &app.tex_mgr)

	// Draw Golden Star Apple (if active)
	if app.game.has_gold {
		gold_x := gx + app.game.gold_food.x * cell_px
		gold_y := gy + app.game.gold_food.y * cell_px
		draw_food_sprite(&app.renderer, gold_x, gold_y, cell_px, true, &app.tex_mgr)
	}

	// Draw Snake Body & Head Sprites
	for idx, pt in app.game.body {
		sx := gx + pt.x * cell_px
		sy := gy + pt.y * cell_px

		if idx == 0 {
			draw_snake_head_sprite(&app.renderer, sx, sy, cell_px, app.game.dir, &app.tex_mgr)
		} else {
			draw_snake_body_sprite(&app.renderer, sx, sy, cell_px, idx, app.game.body.len, &app.tex_mgr)
		}
	}

	// Render Particles
	for p in app.particles {
		draw_filled_circle(&app.renderer, int(p.x), int(p.y), p.size, gg.Color{
			r: p.color.r
			g: p.color.g
			b: p.color.b
			a: u8(p.life * 255.0)
		})
	}

	// Draw Control Buttons
	app.btn_restart.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_pause.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.draw(&app.renderer, app.mouse_x, app.mouse_y)

	prod_fx_render(ctx)
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	app.update_game_step()
	app.update_particles()
	app.sound_mgr.update()
	app.render()

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
			if e.mouse_button == .left {
				app.handle_mouse_click(int(e.mouse_x), int(e.mouse_y))
			}
		}
		.key_down {
			match e.key_code {
				.f11, .grave_accent {
					gg.toggle_fullscreen()
				}
				.f10 {
					prod_fx_cycle_mode()
				}
				.up, .w {
					if app.game.dir != .down {
						app.game.next_dir = .up
					}
				}
				.down, .s {
					if app.game.dir != .up {
						app.game.next_dir = .down
					}
				}
				.left, .a {
					if app.game.dir != .right {
						app.game.next_dir = .left
					}
				}
				.right, .d {
					if app.game.dir != .left {
						app.game.next_dir = .right
					}
				}
				.r {
					app.reset_game()
				}
				.m, .b {
					app.sound_mgr.toggle_music()
				}
				.n, .o {
					app.toggle_sound()
				}
				.p, .space {
					app.toggle_pause()
				}
				.f5 {
					data_save := SaveData{
						high_score:       app.game.high_score
						save_state_valid: true
						score:            app.game.score
					}
					save_data_to_file(&data_save)
				}
				.f9 {
					saved := load_save_data()
					if saved.save_state_valid {
						app.game.score = saved.score
					}
				}
				else {}
			}
		}
		else {}
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.tex_mgr.init(app.ctx)
}

fn main() {
	mut app := new_app()

	app.ctx = gg.new_context(
		width:         win_width
		height:        win_height
		window_title:  'Cyberpunk Snake [GG + Sokol]'
		user_data:     &app
		init_fn:       on_init
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 14, g: 18, b: 28, a: 255}
		resizable:     true
		create_window: true
	)

	app.renderer = Renderer{
		ctx: app.ctx
		width: win_width
		height: win_height
	}
	app.ctx.run()
	app.sound_mgr.cleanup()
}
