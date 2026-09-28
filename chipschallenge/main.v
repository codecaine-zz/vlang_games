module main

import gg
import math
import time

const win_w = 920
const win_h = 640

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      ChipsGame
	sound_mgr SoundManager
	tex_mgr   TextureManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_chips_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_texture_manager()
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

	app.game.update(dt)

	if app.game.sound_event != '' {
		ev := app.game.sound_event
		app.game.sound_event = ''
		match ev {
			'step' { app.sound_mgr.play_step() }
			'chip' { app.sound_mgr.play_chip() }
			'key' { app.sound_mgr.play_key() }
			'door' { app.sound_mgr.play_door() }
			'socket' { app.sound_mgr.play_socket() }
			'win' { app.sound_mgr.play_win() }
			'death' { app.sound_mgr.play_death() }
			'push' { app.sound_mgr.play_push() }
			'boot' { app.sound_mgr.play_boot() }
			'splash' { app.sound_mgr.play_splash() }
			'burn' { app.sound_mgr.play_burn() }
			else {}
		}
	}

	app.sound_mgr.update()
	app.sound_mgr.update_bgm(true)

	render_chips_game(&app.renderer, mut app.game, win_w, win_h, app.sound_mgr.sound_enabled, app.tex_mgr.sprite_texture)
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
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)

				// 1. Sound toggle badge
				tile_size := 36
				board_x := 30
				board_y := 30
				board_w := grid_size * tile_size
				hud_x := board_x + board_w + 25
				hud_w := win_w - hud_x - 30
				sound_x := hud_x + 20
				sound_y := 30 + board_w - 50
				if mx >= sound_x && mx <= sound_x + (hud_w - 40) && my >= sound_y && my <= sound_y + 28 {
					app.sound_mgr.toggle_sound()
					return
				}

				// 2. Mouse Click Navigation on Maze Board
				if mx >= board_x && mx < board_x + board_w && my >= board_y && my < board_y + board_w {
					target_gx := (mx - board_x) / tile_size
					target_gy := (my - board_y) / tile_size
					dx := target_gx - app.game.player_x
					dy := target_gy - app.game.player_y
					if math.abs(dx) > math.abs(dy) {
						app.game.move_player(if dx > 0 { 1 } else { -1 }, 0)
					} else if dy != 0 {
						app.game.move_player(0, if dy > 0 { 1 } else { -1 })
					}
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
				.escape {
					exit(0)
				}
				.f5 {
					app.game.save_state()
				}
				.f9 {
					app.game.load_state()
				}
				.left, .a {
					app.game.move_player(-1, 0)
				}
				.right, .d {
					app.game.move_player(1, 0)
				}
				.up, .w {
					app.game.move_player(0, -1)
				}
				.down, .s {
					app.game.move_player(0, 1)
				}
				.r {
					app.game.load_level(app.game.level_idx)
				}
				.n {
					app.game.load_level(app.game.level_idx + 1)
					app.game.save_progress()
				}
				.m, .o {
					app.sound_mgr.toggle_sound()
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
		window_title: "Chip's Challenge Deluxe - 1989 Windows Classic"
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
