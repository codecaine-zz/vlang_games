#!/usr/bin/env python3
import os
import re

DST = '/Users/codecaine/vlang_games'
SRC = '/tmp/vlang_sdl2_games'

def write_file(game, code):
    p = os.path.join(DST, game, 'main.v')
    with open(p, 'w') as fp:
        fp.write(code)
    print(f"Wrote {game}/main.v")

def gen_peggle():
    code = '''module main

import gg
import math
import time

const win_w = 920
const win_h = 640

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      PeggleGame
	sound_mgr SoundManager
	key_left  bool
	key_right bool
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_peggle_game()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	if app.key_left {
		app.game.cannon_angle = math.max(0.2, app.game.cannon_angle - 1.5 * f64(dt))
	}
	if app.key_right {
		app.game.cannon_angle = math.min(math.pi - 0.2, app.game.cannon_angle + 1.5 * f64(dt))
	}

	app.game.update(f64(dt))
	app.sound_mgr.update()

	render_peggle_game(&app.renderer, mut app.game, win_w, win_h, app.sound_mgr.enabled, unsafe { nil })
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_move {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			if my > 45 {
				cx := f64(win_w) / 2.0
				cy := 45.0
				app.game.cannon_angle = math.atan2(f64(my) - cy, f64(mx) - cx)
				app.game.cannon_angle = math.clamp(app.game.cannon_angle, 0.2, math.pi - 0.2)
			}
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				sound_x := win_w - 140
				if mx >= sound_x && mx <= sound_x + 120 && my >= 8 && my <= 32 {
					app.sound_mgr.toggle_sound()
				} else {
					app.game.shoot_ball()
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.left, .a { app.key_left = true }
				.right, .d { app.key_right = true }
				.space { app.game.shoot_ball() }
				.r { app.game.init_level() }
				.m, .o { app.sound_mgr.toggle_sound() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.left, .a { app.key_left = false }
				.right, .d { app.key_right = false }
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
		window_title: 'Peggle Arcade - Extreme Fever Odyssey'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 10, g: 15, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
'''
    write_file('peggle', code)

def gen_pinball():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        GameEngine
	sound_mgr   SoundManager
	tex_mgr     PinballTextureManager
	p1_left     bool
	p1_right    bool
	mario_left  bool
	mario_right bool
	plunge_hold bool
	last_tick   i64
}

fn new_app() App {
	return App{
		game:      new_game_engine()
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
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(f64(dt), app.p1_left, app.p1_right, app.mario_left, app.mario_right, app.plunge_hold)

	for sound_name in app.game.sound_queue {
		match sound_name {
			'flick' { app.sound_mgr.play_flick() }
			'bumper' { app.sound_mgr.play_bumper() }
			'slingshot' { app.sound_mgr.play_slingshot() }
			'target' { app.sound_mgr.play_target() }
			'spinner' { app.sound_mgr.play_spinner() }
			'mario_bounce' { app.sound_mgr.play_mario_bounce() }
			'damsel_rescue' { app.sound_mgr.play_damsel_rescue() }
			'drain' { app.sound_mgr.play_drain() }
			'plunger_release' { app.sound_mgr.play_plunger_release() }
			'tilt' { app.sound_mgr.play_tilt() }
			else {}
		}
	}
	app.game.sound_queue.clear()
	app.sound_mgr.update()

	render_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.z, .left, .a {
					app.p1_left = true
					app.mario_left = true
				}
				.slash, .right, .d {
					app.p1_right = true
					app.mario_right = true
				}
				.space, .down, .s {
					app.plunge_hold = true
				}
				.r { app.game.reset_game() }
				.m { app.sound_mgr.toggle_sound() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.z, .left, .a {
					app.p1_left = false
					app.mario_left = false
				}
				.slash, .right, .d {
					app.p1_right = false
					app.mario_right = false
				}
				.space, .down, .s {
					app.plunge_hold = false
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
		width:        800
		height:       900
		window_title: 'NES Pinball - 1984 Nintendo Arcade Recreation'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  800
		height: 900
	}
	ctx.run()
}
'''
    write_file('pinball', code)

def gen_pool():
    code = '''module main

import gg
import math
import time

struct App {
mut:
	ctx          &gg.Context = unsafe { nil }
	renderer     Renderer
	game         PoolGame
	sound_mgr    SoundManager
	tex_mgr      PoolTextureManager
	mouse_down   bool
	drag_start_x f64
	drag_start_y f64
	last_tick    i64
}

fn new_app() App {
	return App{
		game:      new_pool_game()
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
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(f64(dt), mut app.sound_mgr)
	app.sound_mgr.update()

	draw_pool_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_move {
			mx := f64(e.mouse_x)
			my := f64(e.mouse_y)
			if app.game.state == .aiming {
				app.game.cue_angle = math.atan2(my - app.game.balls[0].y, mx - app.game.balls[0].x)
			}
			if app.mouse_down && app.game.state == .power_pull {
				dy := my - app.drag_start_y
				app.game.cue_power = math.min(1.0, math.max(0.0, dy / 120.0))
			}
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := f64(e.mouse_x)
				my := f64(e.mouse_y)
				if app.game.state == .ball_in_hand {
					inner_min_x := app.game.table_x + app.game.cushion_thick + 12.0
					inner_max_x := app.game.table_x + app.game.table_w - app.game.cushion_thick - 12.0
					inner_min_y := app.game.table_y + app.game.cushion_thick + 12.0
					inner_max_y := app.game.table_y + app.game.table_h - app.game.cushion_thick - 12.0

					if mx >= inner_min_x && mx <= inner_max_x && my >= inner_min_y && my <= inner_max_y {
						app.game.balls[0].x = mx
						app.game.balls[0].y = my
						app.game.balls[0].potted = false
						app.game.state = .aiming
					}
				} else if app.game.state == .aiming {
					app.mouse_down = true
					app.drag_start_x = mx
					app.drag_start_y = my
					app.game.state = .power_pull
					app.game.cue_power = 0.1
				}
			}
		}
		.mouse_up {
			if e.mouse_button == .left && app.game.state == .power_pull {
				app.mouse_down = false
				if app.game.cue_power > 0.05 {
					app.game.strike_cue_ball(app.game.cue_power, mut app.sound_mgr)
				} else {
					app.game.state = .aiming
				}
				app.game.cue_power = 0.0
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.r {
					if app.game.typ == .nine_ball {
						app.game.rack_9ball()
					} else {
						app.game.rack_8ball()
					}
					app.game.state = .aiming
				}
				.m { app.sound_mgr.toggle_sound() }
				._1 { app.game.set_mode(.eight_ball, false, false) }
				._2 { app.game.set_mode(.nine_ball, false, false) }
				._3 { app.game.set_mode(.practice, false, false) }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:        800
		height:       600
		window_title: 'Billiards Pro - 8-Ball & 9-Ball Pool'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 10, g: 25, b: 15, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  800
		height: 600
	}
	ctx.run()
}
'''
    write_file('pool', code)

def gen_puyopuyo():
    code = '''module main

import gg
import time

const win_w = 720
const win_h = 600

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      PuyoGame
	sound_mgr SoundManager
	tex_mgr   PuyoTextureManager
	particles []PuyoParticle
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_puyo_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_puyo_texture_manager()
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
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	update_puyo_particles(mut app.particles, f64(dt))
	app.sound_mgr.update_bgm(app.game.state != .game_over)
	app.sound_mgr.update()

	res := app.game.update(f64(dt))
	if res.popped {
		app.sound_mgr.play_chain_pop_sound(res.chain_level)
	}

	render_puyo_game(&app.renderer, &app.game, win_w, win_h, app.particles, app.tex_mgr.sprite_texture)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.r { app.game.reset_game() }
				.m { app.sound_mgr.toggle_sound() }
				.left, .a {
					if app.game.move_horiz(-1) { app.sound_mgr.play_move_sound() }
				}
				.right, .d {
					if app.game.move_horiz(1) { app.sound_mgr.play_move_sound() }
				}
				.w, .up, .z {
					if app.game.rotate(1) { app.sound_mgr.play_rotate_sound() }
				}
				.x {
					if app.game.rotate(-1) { app.sound_mgr.play_rotate_sound() }
				}
				.s, .down { app.game.fall_speed = 0.08 }
				.space {
					if app.game.state == .game_over {
						app.game.reset_game()
					} else {
						app.game.drop_instant()
						app.sound_mgr.play_drop_sound()
					}
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.s, .down { app.game.fall_speed = 0.65 }
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
		window_title: 'Puyo Puyo - Tsu Arcade Classic'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 15, g: 15, b: 25, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
'''
    write_file('puyopuyo', code)

def gen_qbert():
    code = '''module main

import gg
import time

const win_w = 840
const win_h = 680

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      QbertGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_qbert_game()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn (mut app App) do_hop(dir HopDir) {
	valid, on_disc := app.game.try_hop(dir)
	if valid {
		if on_disc {
			app.sound_mgr.play_disc_sound()
		} else if app.game.state == .cursing {
			app.sound_mgr.play_curse_sound()
		} else {
			app.sound_mgr.play_hop_sound()
		}

		if app.game.state == .level_cleared {
			app.sound_mgr.play_win_sound()
		}
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	ev := app.game.update(f64(dt))
	if ev.hit_enemy {
		app.sound_mgr.play_curse_sound()
	}
	if ev.cleared {
		app.sound_mgr.play_win_sound()
	}
	app.sound_mgr.update()

	render_qbert_game(&app.renderer, &app.game, win_w, win_h)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.r { app.game.reset_game() }
				.s, .m { app.sound_mgr.toggle_sound() }
				.space {
					if app.game.state == .level_cleared {
						app.game.round_num++
						app.game.reset_round()
					} else if app.game.state == .game_over {
						app.game.reset_game()
					}
				}
				.q, .w { app.do_hop(.up_left) }
				.e, .up { app.do_hop(.up_right) }
				.a, .left { app.do_hop(.down_left) }
				.d, .right, .down { app.do_hop(.down_right) }
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
		window_title: 'Q*bert 2.5D Isometric - Arcade Classic'
		user_data:    &app
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
'''
    write_file('qbert', code)

def gen_racer():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx           &gg.Context = unsafe { nil }
	renderer      Renderer
	game          RacerGame
	sound_mgr     SoundManager
	key_accel     bool
	key_brake     bool
	key_left      bool
	key_right     bool
	key_handbrake bool
	paused        bool
	mouse_x       int
	mouse_y       int
	btn_restart   Button
	btn_sound     Button
	last_tick     i64
}

fn new_app() App {
	return App{
		game:        new_racer_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{ x: 10, y: 10, w: 90, h: 32, text: 'RESTART', bg_color: Color{r: 200, g: 50, b: 50}, hover_color: Color{r: 240, g: 70, b: 70}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 255, g: 255, b: 255} }
		btn_sound:   Button{ x: 110, y: 10, w: 90, h: 32, text: 'AUDIO', bg_color: Color{r: 50, g: 150, b: 50}, hover_color: Color{r: 70, g: 190, b: 70}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 255, g: 255, b: 255} }
		last_tick:   time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	if !app.paused {
		app.game.update(f64(dt), app.key_accel, app.key_brake, app.key_left, app.key_right, app.key_handbrake)

		if app.game.sound_event_engine {
			speed_ratio := app.game.player.speed / app.game.player.max_speed
			app.sound_mgr.play_engine_sound(speed_ratio)
		}
		if app.game.sound_event_skid { app.sound_mgr.play_skid_sound() }
		if app.game.sound_event_crash { app.sound_mgr.play_crash_sound() }
		if app.game.sound_event_boost { app.sound_mgr.play_boost_sound() }
		if app.game.sound_event_gate { app.sound_mgr.play_gate_sound() }
	}
	app.sound_mgr.update()

	app.game.render(&app.renderer)
	app.btn_restart.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.draw(&app.renderer, app.mouse_x, app.mouse_y)

	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.btn_restart.contains(mx, my) {
					app.game = new_racer_game()
				} else if app.btn_sound.contains(mx, my) {
					app.sound_mgr.toggle_sound()
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.up, .w { app.key_accel = true }
				.down, .s { app.key_brake = true }
				.left, .a { app.key_left = true }
				.right, .d { app.key_right = true }
				.space, .k { app.key_handbrake = true }
				.r { app.game = new_racer_game() }
				.p { app.paused = !app.paused }
				.m { app.sound_mgr.toggle_sound() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.up, .w { app.key_accel = false }
				.down, .s { app.key_brake = false }
				.left, .a { app.key_left = false }
				.right, .d { app.key_right = false }
				.space, .k { app.key_handbrake = false }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:        960
		height:       640
		window_title: 'Outrun / Ridge Racer 2.5D Retro Arcade'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 20, g: 20, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  960
		height: 640
	}
	ctx.run()
}
'''
    write_file('racer', code)

def gen_ragdoll():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx           &gg.Context = unsafe { nil }
	renderer      Renderer
	game          RagdollGame
	sound_mgr     SoundManager
	mouse_x       int
	mouse_y       int
	mouse_down    bool
	mouse_clicked bool
	paused        bool
	btn_restart   Button
	btn_sound     Button
	last_tick     i64
}

fn new_app() App {
	return App{
		game:        new_ragdoll_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{ x: 10, y: 10, w: 90, h: 32, text: 'RESET', bg_color: Color{r: 200, g: 50, b: 50}, hover_color: Color{r: 240, g: 70, b: 70}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 255, g: 255, b: 255} }
		btn_sound:   Button{ x: 110, y: 10, w: 90, h: 32, text: 'AUDIO', bg_color: Color{r: 50, g: 150, b: 50}, hover_color: Color{r: 70, g: 190, b: 70}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 255, g: 255, b: 255} }
		last_tick:   time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	if !app.paused {
		app.game.update(f64(dt), app.mouse_x, app.mouse_y, app.mouse_down, app.mouse_clicked)
		app.mouse_clicked = false

		if app.game.sound_event_thud { app.sound_mgr.play_thud_sound(app.game.thud_intensity) }
		if app.game.sound_event_crunch { app.sound_mgr.play_crunch_sound() }
		if app.game.sound_event_explosion { app.sound_mgr.play_explosion_sound() }
		if app.game.sound_event_zap { app.sound_mgr.play_gravgun_zap() }
		if app.game.sound_event_boing { app.sound_mgr.play_boing_sound() }
		if app.game.sound_event_bumper { app.sound_mgr.play_bumper_chime() }
		if app.game.sound_event_tether { app.sound_mgr.play_tether_snap() }
	}
	app.sound_mgr.update()

	app.game.render(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_restart.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.draw(&app.renderer, app.mouse_x, app.mouse_y)

	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			if e.mouse_button == .left {
				app.mouse_down = true
				app.mouse_clicked = true
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.btn_restart.contains(mx, my) {
					app.game.load_arena(app.game.active_arena)
				} else if app.btn_sound.contains(mx, my) {
					app.sound_mgr.toggle_sound()
				}
			}
		}
		.mouse_up {
			if e.mouse_button == .left {
				app.mouse_down = false
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				._1 { app.game.load_arena(0) }
				._2 { app.game.load_arena(1) }
				._3 { app.game.load_arena(2) }
				.g { app.game.active_tool = .grab }
				.t { app.game.active_tool = .tether }
				.b { app.game.active_tool = .bomb }
				.r { app.game.load_arena(app.game.active_arena) }
				.p { app.paused = !app.paused }
				.m { app.sound_mgr.toggle_sound() }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:        800
		height:       600
		window_title: 'Ragdoll Sandbox Physics Playground'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 15, g: 20, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  800
		height: 600
	}
	ctx.run()
}
'''
    write_file('ragdoll', code)

def gen_rain():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx        &gg.Context = unsafe { nil }
	renderer   Renderer
	game       RainGame
	sound_mgr  SoundManager
	mouse_x    int
	mouse_y    int
	btn_theme  Button
	btn_mode   Button
	btn_preset Button
	btn_sound  Button
	last_tick  i64
}

fn new_app() App {
	return App{
		game:       new_rain_game()
		sound_mgr:  new_sound_manager()
		btn_theme:  Button{ x: 10, y: 60, w: 110, h: 28, text: 'THEME [TAB]', bg_color: Color{r: 25, g: 35, b: 55}, hover_color: Color{r: 45, g: 65, b: 100}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 0, g: 180, b: 255} }
		btn_mode:   Button{ x: 130, y: 60, w: 110, h: 28, text: 'MODE [B]', bg_color: Color{r: 25, g: 35, b: 55}, hover_color: Color{r: 45, g: 65, b: 100}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 0, g: 180, b: 255} }
		btn_preset: Button{ x: 250, y: 60, w: 110, h: 28, text: 'STRESS [5]', bg_color: Color{r: 45, g: 25, b: 55}, hover_color: Color{r: 85, g: 45, b: 110}, text_color: Color{r: 255, g: 220, b: 100}, border_color: Color{r: 255, g: 0, b: 180} }
		btn_sound:  Button{ x: 370, y: 60, w: 110, h: 28, text: 'SOUND [M]', bg_color: Color{r: 25, g: 35, b: 55}, hover_color: Color{r: 45, g: 65, b: 100}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 0, g: 180, b: 255} }
		last_tick:  time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(f64(dt))
	app.sound_mgr.update()

	render_rain_game(&app.renderer, mut app.game)
	app.btn_theme.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_mode.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_preset.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.draw(&app.renderer, app.mouse_x, app.mouse_y)

	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
			app.game.mouse_x = app.mouse_x
			app.game.mouse_y = app.mouse_y
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.btn_theme.contains(mx, my) {
					app.game.cycle_theme()
				} else if app.btn_mode.contains(mx, my) {
					app.game.cycle_mode()
				} else if app.btn_preset.contains(mx, my) {
					app.game.apply_stress_test()
				} else if app.btn_sound.contains(mx, my) {
					app.sound_mgr.toggle_sound()
				} else {
					app.game.mouse_down = true
				}
			}
		}
		.mouse_up {
			if e.mouse_button == .left {
				app.game.mouse_down = false
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.tab { app.game.cycle_theme() }
				.b { app.game.cycle_mode() }
				._5 { app.game.apply_stress_test() }
				.m { app.sound_mgr.toggle_sound() }
				.r { app.game.reset() }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:        960
		height:       640
		window_title: 'Monsoon Overdrive - Realistic Rain Simulator & M4 Hardware Benchmark'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 5, g: 8, b: 15, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  960
		height: 640
	}
	ctx.run()
}
'''
    write_file('rain', code)

def gen_rodentsrevenge():
    code = '''module main

import gg
import time

const win_w = 920
const win_h = 660

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      RodentGame
	sound_mgr SoundManager
	tex_mgr   TextureManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_rodent_game()
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
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(f64(dt))
	app.sound_mgr.update()

	render_rodent_game(&app.renderer, mut app.game, win_w, win_h, app.sound_mgr.enabled, app.tex_mgr.sprite_texture)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				sound_x := win_w - 135
				if mx >= sound_x && mx <= sound_x + 115 && my >= 10 && my <= 36 {
					app.sound_mgr.toggle_sound()
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.left, .a { app.game.move_player(-1, 0) }
				.right, .d { app.game.move_player(1, 0) }
				.up, .w { app.game.move_player(0, -1) }
				.down, .s { app.game.move_player(0, 1) }
				.r { app.game.init_level(app.game.level) }
				.n { app.game.init_level(app.game.level + 1) }
				.m { app.sound_mgr.toggle_sound() }
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
		window_title: "Rodent's Revenge Deluxe - Windows 1991 Classic Remaster"
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 10, g: 15, b: 25, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
'''
    write_file('rodentsrevenge', code)

def gen_scorchedearth():
    code = '''module main

import gg
import time

const win_w = 920
const win_h = 640

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      ScorchedGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_scorched_game()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(f64(dt))
	app.sound_mgr.update()

	render_scorched_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.sound_mgr.enabled)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				app.game.handle_click(mx, my, mut app.sound_mgr)
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.left, .a { app.game.adjust_angle(-1.0) }
				.right, .d { app.game.adjust_angle(1.0) }
				.up, .w { app.game.adjust_power(1.0) }
				.down, .s { app.game.adjust_power(-1.0) }
				.space { app.game.fire_weapon(mut app.sound_mgr) }
				.tab { app.game.cycle_weapon() }
				.m { app.sound_mgr.toggle_sound() }
				.r { app.game.init_round() }
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
		window_title: 'Scorched Earth 1991 - The Mother of All Games'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 5, g: 10, b: 20, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
'''
    write_file('scorchedearth', code)

def gen_shinobi():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      ShinobiGame
	tex_mgr   ShinobiTextureManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_shinobi_game()
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
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(dt)
	app.game.sound_mgr.update_bgm(app.game.state == .playing)
	app.game.sound_mgr.update()

	render_shinobi_game(&app.renderer, mut app.game, app.tex_mgr.sprite_texture)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.left, .a { app.game.key_left = true }
				.right, .d { app.game.key_right = true }
				.w, .up { app.game.jump() }
				.j, .z { app.game.slash() }
				.k, .x { app.game.throw_shuriken() }
				.space {
					if app.game.state == .menu || app.game.state == .game_over {
						app.game.reset_game()
					} else {
						app.game.jump()
					}
				}
				.p {
					if app.game.state == .playing { app.game.state = .paused }
					else if app.game.state == .paused { app.game.state = .playing }
				}
				.r { app.game.reset_game() }
				.m { app.game.sound_mgr.toggle_sound() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.left, .a { app.game.key_left = false }
				.right, .d { app.game.key_right = false }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:        800
		height:       600
		window_title: 'Shinobi Arcade Remaster (1987 SEGA Tribute)'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  800
		height: 600
	}
	ctx.run()
}
'''
    write_file('shinobi', code)

gen_peggle()
gen_pinball()
gen_pool()
gen_puyopuyo()
gen_qbert()
gen_racer()
gen_ragdoll()
gen_rain()
gen_rodentsrevenge()
gen_scorchedearth()
gen_shinobi()
print("Generated 11 Batch 4 games.")
