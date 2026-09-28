#!/usr/bin/env python3
import os
import re

DST_REPO = '/Users/codecaine/vlang_games'
SRC_REPO = '/tmp/vlang_sdl2_games'

def generate_drmario():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      DrMarioGame
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_dr_mario_game()
		last_tick: time.ticks()
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.game.init_textures(&app.renderer)
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(dt)
	app.game.sound_mgr.update()

	render_dr_mario_game(&app.renderer, mut app.game)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape {
					if app.game.state == .title {
						exit(0)
					} else {
						app.game.reset_to_title()
					}
				}
				.a, .left {
					if app.game.state == .title {
						if app.game.level > 0 { app.game.level-- }
					} else {
						app.game.key_left = true
						app.game.move_horizontal(-1)
					}
				}
				.d, .right {
					if app.game.state == .title {
						if app.game.level < 20 { app.game.level++ }
					} else {
						app.game.key_right = true
						app.game.move_horizontal(1)
					}
				}
				.s, .down {
					app.game.key_down = true
				}
				.space, .enter {
					if app.game.state == .title {
						app.game.start_game(app.game.level, app.game.speed)
					} else if app.game.state == .stage_clear {
						app.game.next_level()
					} else if app.game.state == .game_over {
						app.game.reset_to_title()
					} else if app.game.state == .playing {
						app.game.hard_drop()
					}
				}
				.w, .up, .j, .z {
					if app.game.state == .title {
						app.game.start_game(app.game.level, app.game.speed)
					} else if app.game.state == .stage_clear {
						app.game.next_level()
					} else if app.game.state == .game_over {
						app.game.reset_to_title()
					} else {
						app.game.rotate_pill(true)
					}
				}
				.k, .x {
					app.game.rotate_pill(false)
				}
				.h, .left_shift, .right_shift {
					if app.game.state == .playing {
						app.game.hold_current_pill()
					}
				}
				._1 {
					app.game.speed = .low
				}
				._2 {
					app.game.speed = .med
				}
				._3 {
					app.game.speed = .hi
				}
				.p {
					if app.game.state in [.playing, .clearing_matches, .cascade_falling] {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.r {
					app.game.reset_to_title()
				}
				.m {
					app.game.sound_mgr.toggle_sound()
				}
				.b, .t {
					app.game.sound_mgr.cycle_bgm()
				}
				.c {
					app.game.crt_filter = !app.game.crt_filter
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.a, .left {
					app.game.key_left = false
				}
				.d, .right {
					app.game.key_right = false
				}
				.s, .down {
					app.game.key_down = false
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
		height:       600
		window_title: 'Dr. Mario (1990 Nintendo Classic Recreation)'
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
    with open(os.path.join(DST_REPO, 'drmario', 'main.v'), 'w') as fp:
        fp.write(code)

def generate_frogger():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      FroggerGame
	tex_mgr   FroggerTextureManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_frogger_game()
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
	app.game.sound_mgr.update()

	render_frogger_game(&app.renderer, mut app.game, app.tex_mgr.sprite_texture)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape {
					exit(0)
				}
				.up, .w {
					app.game.hop(0, -1)
				}
				.down, .s {
					app.game.hop(0, 1)
				}
				.left, .a {
					app.game.hop(-1, 0)
				}
				.right, .d {
					app.game.hop(1, 0)
				}
				.space {
					if app.game.state == .menu || app.game.state == .game_over {
						app.game.reset_game()
					}
				}
				.p {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.r {
					app.game.reset_game()
				}
				.m {
					app.game.sound_mgr.toggle_sound()
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
		height:       600
		window_title: 'Frogger Arcade Classic'
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
    with open(os.path.join(DST_REPO, 'frogger', 'main.v'), 'w') as fp:
        fp.write(code)

def generate_galaga():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx        &gg.Context = unsafe { nil }
	renderer   Renderer
	game       GalagaGame
	last_tick  i64
}

fn new_app() App {
	return App{
		game:      new_galaga_game()
		last_tick: time.ticks()
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.game.init_textures(&app.renderer)
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(dt)
	app.game.sound_mgr.update()

	render_galaga_game(&app.renderer, mut app.game)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape {
					exit(0)
				}
				.left, .a {
					app.game.key_left = true
				}
				.right, .d {
					app.game.key_right = true
				}
				.space {
					if app.game.state == .menu || app.game.state == .game_over {
						app.game.reset_game()
					} else {
						app.game.key_fire = true
					}
				}
				.p {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.r {
					app.game.reset_game()
				}
				.m {
					app.game.sound_mgr.toggle_sound()
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.left, .a {
					app.game.key_left = false
				}
				.right, .d {
					app.game.key_right = false
				}
				.space {
					app.game.key_fire = false
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
		height:       600
		window_title: 'Galaga Space Shooter Arcade'
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
    with open(os.path.join(DST_REPO, 'galaga', 'main.v'), 'w') as fp:
        fp.write(code)

def generate_kungfu():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      KungFuGame
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_kung_fu_game()
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

	app.game.update(dt)
	app.game.sound_mgr.update()

	render_kung_fu_game(&app.renderer, mut app.game)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape {
					exit(0)
				}
				.left, .a {
					app.game.key_left = true
					if app.game.last_dir_key == 2 {
						app.game.shake_off_grippers()
					}
					app.game.last_dir_key = 1
				}
				.right, .d {
					app.game.key_right = true
					if app.game.last_dir_key == 1 {
						app.game.shake_off_grippers()
					}
					app.game.last_dir_key = 2
				}
				.down, .s {
					app.game.key_down = true
				}
				.up, .w, .space {
					if app.game.state == .title {
						app.game.start_game()
					} else if app.game.state == .floor_clear {
						app.game.next_floor()
					} else if app.game.state == .game_over || app.game.state == .victory {
						app.game.reset_to_title()
					} else {
						app.game.key_jump = true
					}
				}
				.enter {
					if app.game.state == .title {
						app.game.start_game()
					} else if app.game.state == .floor_clear {
						app.game.next_floor()
					} else if app.game.state == .game_over || app.game.state == .victory {
						app.game.reset_to_title()
					}
				}
				.j, .z {
					app.game.key_punch = true
				}
				.k, .x {
					app.game.key_kick = true
				}
				.p {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.c {
					app.game.crt_filter = !app.game.crt_filter
				}
				.r {
					app.game.reset_to_title()
				}
				.m {
					app.game.sound_mgr.toggle_sound()
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.left, .a {
					app.game.key_left = false
				}
				.right, .d {
					app.game.key_right = false
				}
				.down, .s {
					app.game.key_down = false
				}
				.j, .z {
					app.game.key_punch = false
				}
				.k, .x {
					app.game.key_kick = false
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
		height:       600
		window_title: 'Kung-Fu Master Arcade Classic'
		user_data:    &app
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
    with open(os.path.join(DST_REPO, 'kungfu', 'main.v'), 'w') as fp:
        fp.write(code)

def generate_legendofkage():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      LegendOfKageGame
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_legend_of_kage_game()
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

	app.game.update(dt)
	app.game.sound_mgr.update()

	render_legend_of_kage_game(&app.renderer, mut app.game, unsafe { nil })
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape {
					exit(0)
				}
				.left, .a {
					app.game.key_left = true
				}
				.right, .d {
					app.game.key_right = true
				}
				.down, .s {
					app.game.key_down = true
				}
				.up, .w, .space {
					if app.game.state == .title {
						app.game.start_game()
					} else if app.game.state == .stage_clear {
						app.game.next_stage()
					} else if app.game.state == .game_over {
						app.game.reset_to_title()
					} else {
						app.game.key_jump = true
					}
				}
				.enter {
					if app.game.state == .title {
						app.game.start_game()
					} else if app.game.state == .stage_clear {
						app.game.next_stage()
					} else if app.game.state == .game_over {
						app.game.reset_to_title()
					}
				}
				.j, .z {
					app.game.player_slash()
				}
				.k, .x {
					app.game.player_throw_shuriken()
				}
				.p {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.c {
					app.game.crt_filter = !app.game.crt_filter
				}
				.r {
					app.game.reset_to_title()
				}
				.m {
					app.game.sound_mgr.toggle_sound()
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.left, .a {
					app.game.key_left = false
				}
				.right, .d {
					app.game.key_right = false
				}
				.down, .s {
					app.game.key_down = false
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
		height:       600
		window_title: 'The Legend of Kage Arcade Classic'
		user_data:    &app
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
    with open(os.path.join(DST_REPO, 'legendofkage', 'main.v'), 'w') as fp:
        fp.write(code)

if __name__ == '__main__':
    generate_drmario()
    generate_frogger()
    generate_galaga()
    generate_kungfu()
    generate_legendofkage()
    print("Pattern A games generated successfully")
