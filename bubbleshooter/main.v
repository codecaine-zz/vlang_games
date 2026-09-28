module main

import gg
import math
import time

const win_w = 780
const win_h = 620

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      BubbleShooterGame
	sound_mgr SoundManager
	tex_mgr   BubbleShooterTextureManager
	particles []PopParticle
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_bubbleshooter_game()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.tex_mgr.init(&app.renderer)
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := math.min(raw_dt, 0.05)

	update_pop_particles(mut app.particles, dt)

	ev := app.game.update(dt)
	if ev.bounced {
		app.sound_mgr.play_bounce_sound()
	}
	if ev.popped_count > 0 {
		app.sound_mgr.play_pop_sound(ev.popped_count)
		main_col, _, _ := get_bubble_theme_colors(app.game.current_color)
		app.particles << create_pop_particles(app.game.projectile.x, app.game.projectile.y, main_col)
	}
	if ev.dropped_count > 0 {
		app.sound_mgr.play_drop_sound()
	}
	if ev.won {
		app.sound_mgr.play_win_sound()
	} else if ev.game_over {
		app.sound_mgr.play_game_over_sound()
	}

	app.sound_mgr.update()

	render_bubbleshooter_game(&app.renderer, &app.game, win_w, win_h, app.particles, app.tex_mgr.sprite_texture)
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
			if app.game.state == .aiming {
				launcher_x := app.game.arena_x + app.game.arena_w / 2.0
				launcher_y := app.game.arena_y + app.game.arena_h - 30.0
				dx := f64(e.mouse_x) - launcher_x
				dy := launcher_y - f64(e.mouse_y)
				if dy > 5.0 {
					angle := math.atan2(dy, dx)
					app.game.aim_angle = math.clamp(angle, 0.25, math.pi - 0.25)
				}
			}
		}
		.mouse_down {
			if e.mouse_button == .left {
				if app.game.state == .aiming {
					if app.game.shoot() {
						app.sound_mgr.play_shoot_sound()
					}
				} else if app.game.state == .won || app.game.state == .game_over {
					app.game.reset_game()
				}
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
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.escape {
					exit(0)
				}
				.r {
					app.game.reset_game()
				}
				.s {
					app.sound_mgr.toggle_sound()
				}
				.space {
					if app.game.state == .aiming {
						if app.game.shoot() {
							app.sound_mgr.play_shoot_sound()
						}
					} else if app.game.state == .won || app.game.state == .game_over {
						app.game.reset_game()
					}
				}
				.left, .a {
					app.game.aim_angle = math.min(math.pi - 0.25, app.game.aim_angle + 0.08)
				}
				.right, .d {
					app.game.aim_angle = math.max(0.25, app.game.aim_angle - 0.08)
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
		width:        win_w
		height:       win_h
		resizable:     true
		window_title: 'Bubble Shooter Pro - Puzzle Bobble Arcade'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
