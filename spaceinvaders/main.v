module main

import gg
import math
import time

struct App {
mut:
	ctx          &gg.Context                 = unsafe { nil }
	renderer     Renderer
	game         SpaceInvadersGame
	sound_mgr    SoundManager
	tex_mgr      SpaceInvadersTextureManager
	key_left     bool
	key_right    bool
	wave_pause   f64
	shake_trauma f64
	last_tick    i64
}

fn new_app() App {
	return App{
		game:      new_space_invaders_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_spaceinvaders_texture_manager()
		last_tick: time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := math.min(raw_dt, 0.05)

	if app.game.state == .wave_clear {
		app.wave_pause += dt
		if app.wave_pause >= 2.0 {
			app.wave_pause = 0.0
			app.game.init_wave(app.game.wave + 1)
		}
	} else {
		ev := app.game.update(dt, app.key_left, app.key_right)
		if ev.march_beat {
			app.sound_mgr.play_march_beat(ev.beat_idx)
		}
		if ev.alien_exploded {
			app.sound_mgr.play_alien_explosion()
			app.shake_trauma = math.min(1.0, app.shake_trauma + 0.16)
		}
		if ev.player_exploded {
			app.sound_mgr.play_player_explosion()
			app.shake_trauma = 0.60
		}
		if ev.ufo_siren {
			app.sound_mgr.play_ufo_siren()
		}
		if ev.ufo_bonus {
			app.sound_mgr.play_ufo_bonus()
			app.shake_trauma = 0.40
		}
	}

	if app.shake_trauma > 0 {
		app.shake_trauma = math.max(0.0, app.shake_trauma - dt * 2.5)
	}
	mut sx := f32(0.0)
	mut sy := f32(0.0)
	if app.shake_trauma > 0 {
		mag := f32(app.shake_trauma * app.shake_trauma * 15.0)
		sx = (f32(math.sin(app.shake_trauma * 50.0))) * mag
		sy = (f32(math.cos(app.shake_trauma * 45.0))) * mag
	}
	app.renderer.offset_x += sx
	app.renderer.offset_y += sy

	app.sound_mgr.update_bgm(app.game.state == .playing)
	app.sound_mgr.update()
	render_space_invaders_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
	app.renderer.offset_x -= sx
	app.renderer.offset_y -= sy
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
				.r {
					app.game.init_game()
				}
				.m, .b {
					app.sound_mgr.toggle_music()
				}
				.s, .n, .o {
					app.sound_mgr.toggle_sfx()
				}
				.left, .a {
					app.key_left = true
				}
				.right, .d {
					app.key_right = true
				}
				.space, .j {
					if app.game.state == .game_over {
						app.game.init_game()
					} else {
						fired := app.game.fire_player_bullet()
						if fired {
							app.sound_mgr.play_player_laser()
						}
					}
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.left, .a {
					app.key_left = false
				}
				.right, .d {
					app.key_right = false
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
		width:         world_w
		height:        world_h
		resizable:     true
		window_title:  'Space Invaders 1978 Arcade Pro'
		user_data:     &app
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx: ctx
	}
	app.tex_mgr.init(&app.renderer)
	ctx.run()
}
