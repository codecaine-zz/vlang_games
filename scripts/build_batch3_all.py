#!/usr/bin/env python3
import os

DST = '/Users/codecaine/vlang_games'

def write_file(game, code):
    p = os.path.join(DST, game, 'main.v')
    with open(p, 'w') as fp:
        fp.write(code)
    print(f"Wrote {game}/main.v")

def gen_liarsdice():
    code = '''module main

import gg
import time

const win_w = 940
const win_h = 660

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      LiarsDiceGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_liarsdice_game(false)
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

	app.game.update(dt)
	app.sound_mgr.update()

	render_liarsdice_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y)
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
				panel_y := win_h - 85

				if app.game.phase == .round_over {
					app.game.start_new_round()
					app.sound_mgr.play_cup_shake()
				} else if app.game.phase == .game_over {
					app.game.reset()
					app.sound_mgr.play_cup_shake()
				} else if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
					if mx >= 80 && mx <= 110 && my >= panel_y + 10 && my <= panel_y + 42 {
						if app.game.selected_qty > 1 {
							app.game.selected_qty--
							app.sound_mgr.play_bid()
						}
					}
					if mx >= 160 && mx <= 190 && my >= panel_y + 10 && my <= panel_y + 42 {
						if app.game.selected_qty < app.game.total_active_dice() {
							app.game.selected_qty++
							app.sound_mgr.play_bid()
						}
					}
					for f := 1; f <= 6; f++ {
						fx := 260 + (f - 1) * 44
						if mx >= fx - 2 && mx <= fx + 34 && my >= panel_y + 8 && my <= panel_y + 44 {
							app.game.selected_face = f
							app.sound_mgr.play_bid()
						}
					}
					if mx >= 540 && mx <= 640 && my >= panel_y + 10 && my <= panel_y + 44 {
						if app.game.make_bid(app.game.current_player, app.game.selected_qty, app.game.selected_face) {
							app.sound_mgr.play_bid()
						}
					}
					if mx >= 655 && mx <= 765 && my >= panel_y + 10 && my <= panel_y + 44 {
						if app.game.call_liar(app.game.current_player) {
							app.sound_mgr.play_challenge()
						}
					}
					if mx >= 780 && mx <= 890 && my >= panel_y + 10 && my <= panel_y + 44 {
						if app.game.call_spot_on(app.game.current_player) {
							app.sound_mgr.play_spot_on()
						}
					}
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.r {
					app.game.reset()
					app.sound_mgr.play_cup_shake()
				}
				.m {
					app.game.is_two_player = !app.game.is_two_player
					app.game.reset()
					app.sound_mgr.play_cup_shake()
				}
				.s { app.sound_mgr.toggle_sound() }
				.space {
					if app.game.phase == .round_over {
						app.game.start_new_round()
						app.sound_mgr.play_cup_shake()
					} else if app.game.phase == .game_over {
						app.game.reset()
						app.sound_mgr.play_cup_shake()
					} else if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
						if app.game.make_bid(app.game.current_player, app.game.selected_qty, app.game.selected_face) {
							app.sound_mgr.play_bid()
						}
					}
				}
				.l {
					if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
						if app.game.call_liar(app.game.current_player) {
							app.sound_mgr.play_challenge()
						}
					}
				}
				.c {
					if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
						if app.game.call_spot_on(app.game.current_player) {
							app.sound_mgr.play_spot_on()
						}
					}
				}
				.up {
					if app.game.selected_qty < app.game.total_active_dice() {
						app.game.selected_qty++
						app.sound_mgr.play_bid()
					}
				}
				.down {
					if app.game.selected_qty > 1 {
						app.game.selected_qty--
						app.sound_mgr.play_bid()
					}
				}
				.right {
					if app.game.selected_face < 6 {
						app.game.selected_face++
						app.sound_mgr.play_bid()
					}
				}
				.left {
					if app.game.selected_face > 1 {
						app.game.selected_face--
						app.sound_mgr.play_bid()
					}
				}
				._1 { app.game.selected_face = 1; app.sound_mgr.play_bid() }
				._2 { app.game.selected_face = 2; app.sound_mgr.play_bid() }
				._3 { app.game.selected_face = 3; app.sound_mgr.play_bid() }
				._4 { app.game.selected_face = 4; app.sound_mgr.play_bid() }
				._5 { app.game.selected_face = 5; app.sound_mgr.play_bid() }
				._6 { app.game.selected_face = 6; app.sound_mgr.play_bid() }
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
		window_title: "Liar's Dice (Perudo / Dudo) - Bluffing Dice Game"
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 20, g: 25, b: 35, a: 255}
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
    write_file('liarsdice', code)

def gen_lightcycles():
    code = '''module main

import gg
import time

const win_w = 920
const win_h = 700

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      LightCyclesGame
	sound_mgr SoundManager
	particles []CrashParticle
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_lightcycles_game()
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

	update_crash_particles(mut app.particles, dt)

	ev := app.game.update(dt)
	if ev.crashed {
		app.sound_mgr.play_crash_sound()
		col := if app.game.round_winner == 1 { Color{r: 255, g: 110, b: 30, a: 255} } else { Color{r: 30, g: 220, b: 255, a: 255} }
		app.particles << create_crash_particles(f64(win_w / 2), f64(win_h / 2), col)
	}
	if ev.round_ended && app.game.state == .match_over {
		app.sound_mgr.play_win_sound()
	}

	app.sound_mgr.update()

	render_lightcycles_arena(&app.renderer, &app.game, win_w, win_h, app.particles)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.r { app.game.reset_match() }
				.m {
					app.game.mode = if app.game.mode == .pve { GameMode.pvp } else { GameMode.pve }
					app.game.reset_match()
				}
				.d {
					app.game.diff = match app.game.diff {
						.easy { Difficulty.normal }
						.normal { Difficulty.master }
						.master { Difficulty.easy }
					}
				}
				.s { app.sound_mgr.toggle_sound() }
				.space {
					if app.game.state == .round_over {
						app.game.reset_round()
					} else if app.game.state == .match_over {
						app.game.reset_match()
					} else {
						app.game.p1.is_boosting = true
						app.sound_mgr.play_boost_sound()
					}
				}
				.w, .up {
					if app.game.set_p1_dir(.up) { app.sound_mgr.play_turn_sound() }
				}
				.down {
					if app.game.set_p1_dir(.down) { app.sound_mgr.play_turn_sound() }
				}
				.a, .left {
					if app.game.set_p1_dir(.left) { app.sound_mgr.play_turn_sound() }
				}
				.right {
					if app.game.set_p1_dir(.right) { app.sound_mgr.play_turn_sound() }
				}
				.i {
					if app.game.mode == .pvp {
						if app.game.set_p2_dir(.up) { app.sound_mgr.play_turn_sound() }
					}
				}
				.k {
					if app.game.mode == .pvp {
						if app.game.set_p2_dir(.down) { app.sound_mgr.play_turn_sound() }
					}
				}
				.j {
					if app.game.mode == .pvp {
						if app.game.set_p2_dir(.left) { app.sound_mgr.play_turn_sound() }
					}
				}
				.l {
					if app.game.mode == .pvp {
						if app.game.set_p2_dir(.right) { app.sound_mgr.play_turn_sound() }
					}
				}
				.right_shift {
					if app.game.mode == .pvp {
						app.game.p2.is_boosting = true
						app.sound_mgr.play_boost_sound()
					}
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.space { app.game.p1.is_boosting = false }
				.right_shift { app.game.p2.is_boosting = false }
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
		window_title: 'Light Cycles - Retro Cyber Arena'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 5, g: 8, b: 15, a: 255}
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
    write_file('lightcycles', code)

def gen_lolo():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx              &gg.Context = unsafe { nil }
	renderer         Renderer
	game             Game
	sound_mgr        SoundManager
	btn_editor       Button
	btn_sound        Button
	btn_prev         Button
	btn_next         Button
	btn_restart      Button
	btn_undo         Button
	btn_level_select Button
	btn_test         Button
	btn_clear        Button
	mouse_x          int
	mouse_y          int
	last_tick        i64
}

fn new_app() App {
	return App{
		game:             new_game()
		sound_mgr:        new_sound_manager()
		btn_editor:       Button{
			x:            775
			y:            12
			w:            165
			h:            40
			text:         'DESIGNER [TAB]'
			bg_color:     Color{ r: 12, g: 30, b: 65, a: 255 }
			hover_color:  Color{ r: 0, g: 120, b: 200, a: 255 }
			text_color:   Color{ r: 0, g: 240, b: 255, a: 255 }
			border_color: Color{ r: 0, g: 240, b: 255, a: 255 }
		}
		btn_sound:        Button{
			x:            595
			y:            600
			w:            338
			h:            42
			text:         'AUDIO: ON [S]'
			bg_color:     Color{ r: 15, g: 25, b: 45, a: 255 }
			hover_color:  Color{ r: 30, g: 50, b: 90, a: 255 }
			text_color:   Color{ r: 0, g: 230, b: 255, a: 255 }
			border_color: Color{ r: 0, g: 200, b: 255, a: 255 }
		}
		btn_undo:         Button{
			x:            595
			y:            380
			w:            165
			h:            38
			text:         'UNDO [U/Z]'
			bg_color:     Color{ r: 25, g: 35, b: 50, a: 255 }
			hover_color:  Color{ r: 40, g: 60, b: 90, a: 255 }
			text_color:   Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 80, g: 120, b: 180, a: 255 }
		}
		btn_restart:      Button{
			x:            768
			y:            380
			w:            165
			h:            38
			text:         'RESTART [R]'
			bg_color:     Color{ r: 50, g: 20, b: 25, a: 255 }
			hover_color:  Color{ r: 90, g: 30, b: 40, a: 255 }
			text_color:   Color{ r: 255, g: 120, b: 120, a: 255 }
			border_color: Color{ r: 200, g: 60, b: 70, a: 255 }
		}
		btn_prev:         Button{
			x:            595
			y:            425
			w:            165
			h:            38
			text:         'PREV [P/[]'
			bg_color:     Color{ r: 20, g: 30, b: 45, a: 255 }
			hover_color:  Color{ r: 35, g: 55, b: 80, a: 255 }
			text_color:   Color{ r: 200, g: 220, b: 255, a: 255 }
			border_color: Color{ r: 60, g: 90, b: 140, a: 255 }
		}
		btn_next:         Button{
			x:            768
			y:            425
			w:            165
			h:            38
			text:         'NEXT [N/]]'
			bg_color:     Color{ r: 20, g: 30, b: 45, a: 255 }
			hover_color:  Color{ r: 35, g: 55, b: 80, a: 255 }
			text_color:   Color{ r: 200, g: 220, b: 255, a: 255 }
			border_color: Color{ r: 60, g: 90, b: 140, a: 255 }
		}
		btn_level_select: Button{
			x:            595
			y:            470
			w:            338
			h:            38
			text:         'LEVEL SELECT [L]'
			bg_color:     Color{ r: 25, g: 25, b: 50, a: 255 }
			hover_color:  Color{ r: 45, g: 45, b: 85, a: 255 }
			text_color:   Color{ r: 180, g: 200, b: 255, a: 255 }
			border_color: Color{ r: 80, g: 80, b: 160, a: 255 }
		}
		btn_test:         Button{
			x:            595
			y:            515
			w:            165
			h:            38
			text:         'TEST RUN [T]'
			bg_color:     Color{ r: 20, g: 45, b: 35, a: 255 }
			hover_color:  Color{ r: 30, g: 80, b: 60, a: 255 }
			text_color:   Color{ r: 120, g: 255, b: 180, a: 255 }
			border_color: Color{ r: 50, g: 180, b: 120, a: 255 }
		}
		btn_clear:        Button{
			x:            768
			y:            515
			w:            165
			h:            38
			text:         'CLEAR MAP [C]'
			bg_color:     Color{ r: 45, g: 25, b: 20, a: 255 }
			hover_color:  Color{ r: 80, g: 40, b: 30, a: 255 }
			text_color:   Color{ r: 255, g: 160, b: 120, a: 255 }
			border_color: Color{ r: 180, g: 80, b: 50, a: 255 }
		}
		last_tick:        time.ticks()
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
	app.sound_mgr.update()

	draw_game(&app.renderer, app.game, app.mouse_x, app.mouse_y, app.btn_editor, app.btn_restart, app.btn_sound, app.btn_prev, app.btn_next, app.btn_test, app.btn_clear, app.btn_undo, app.btn_level_select)
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
				if app.btn_editor.contains(mx, my) {
					app.game.toggle_editor_mode()
				} else if app.btn_sound.contains(mx, my) {
					app.sound_mgr.toggle_sound()
				} else if app.btn_undo.contains(mx, my) {
					app.game.undo(mut app.sound_mgr)
				} else if app.btn_restart.contains(mx, my) {
					app.game.restart_level(mut app.sound_mgr)
				} else if app.btn_prev.contains(mx, my) {
					app.game.prev_level(mut app.sound_mgr)
				} else if app.btn_next.contains(mx, my) {
					app.game.next_level(mut app.sound_mgr)
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.tab { app.game.toggle_editor_mode() }
				.s { app.sound_mgr.toggle_sound() }
				.u, .z { app.game.undo(mut app.sound_mgr) }
				.r { app.game.restart_level(mut app.sound_mgr) }
				.up, .w { app.game.try_move(.up, mut app.sound_mgr) }
				.down { app.game.try_move(.down, mut app.sound_mgr) }
				.left, .a { app.game.try_move(.left, mut app.sound_mgr) }
				.right, .d { app.game.try_move(.right, mut app.sound_mgr) }
				.space { app.game.try_shoot(mut app.sound_mgr) }
				.p, .left_bracket { app.game.prev_level(mut app.sound_mgr) }
				.n, .right_bracket { app.game.next_level(mut app.sound_mgr) }
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
		window_title: 'Adventures of Lolo - Cyber Puzzle Odyssey'
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
    write_file('lolo', code)

def gen_lunarlander():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      LunarLanderGame
	tex_mgr   LunarLanderTextureManager
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_lunarlander_game()
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

	app.game.update(dt)
	app.sound_mgr.update()

	render_lunarlander_game(&app.renderer, mut app.game, app.tex_mgr.sprite_texture)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.up, .w, .space { app.game.key_thrust = true }
				.left, .a { app.game.key_rot_left = true }
				.right, .d { app.game.key_rot_right = true }
				.r { app.game.reset_game() }
				.m { app.sound_mgr.toggle_sound() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.up, .w, .space { app.game.key_thrust = false }
				.left, .a { app.game.key_rot_left = false }
				.right, .d { app.game.key_rot_right = false }
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
		window_title: 'Lunar Lander Simulator'
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
    write_file('lunarlander', code)

def gen_mappy():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx        &gg.Context = unsafe { nil }
	renderer   Renderer
	game       GameEngine
	tex_mgr    MappyTextureManager
	sound_mgr  SoundManager
	key_left   bool
	key_right  bool
	key_action bool
	last_tick  i64
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

	app.game.update(dt, app.key_left, app.key_right, app.key_action, mut app.sound_mgr)
	app.key_action = false
	app.sound_mgr.update()

	draw_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.left, .a { app.key_left = true }
				.right, .d { app.key_right = true }
				.space, .up, .w, .enter {
					app.key_action = true
					if app.game.state == .title || app.game.state == .game_over {
						app.game.start_game(1)
					}
				}
				.m { app.sound_mgr.toggle_sound() }
				.r { app.game.start_game(1) }
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
		width:        800
		height:       600
		window_title: 'Mappy - Namco Arcade Police Mouse Classic'
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
    write_file('mappy', code)

def gen_marblemadness():
    code = '''module main

import gg
import time

const win_w = 840
const win_h = 640

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      MarbleGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_marble_game()
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

	app.game.update(dt)
	app.sound_mgr.update()

	render_game(&app.renderer, &app.game, win_w, win_h)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.space, .enter {
					match app.game.state {
						.title { app.game.start_game(1) }
						.level_intro { app.game.state = .playing }
						.game_over, .victory { app.game.init_title() }
						.playing {
							app.game.input_turbo = true
							app.game.input_jump = true
						}
						else {}
					}
				}
				.up, .w { app.game.input_up = true }
				.down, .s { app.game.input_down = true }
				.left, .a { app.game.input_left = true }
				.right, .d { app.game.input_right = true }
				.p {
					if app.game.state == .playing { app.game.state = .paused }
					else if app.game.state == .paused { app.game.state = .playing }
				}
				.r { app.game.start_game(app.game.current_level) }
				.m { app.sound_mgr.toggle_sound() }
				.t { app.game.control_diagonal = !app.game.control_diagonal }
				._1 { app.game.start_game(1) }
				._2 { app.game.start_game(2) }
				._3 { app.game.start_game(3) }
				._4 { app.game.start_game(4) }
				._5 { app.game.start_game(5) }
				._6 { app.game.start_game(6) }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.up, .w { app.game.input_up = false }
				.down, .s { app.game.input_down = false }
				.left, .a { app.game.input_left = false }
				.right, .d { app.game.input_right = false }
				.space, .enter {
					app.game.input_turbo = false
					app.game.input_jump = false
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
		window_title: 'Marble Madness (Atari 1984 Isometric Arcade)'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 12, g: 15, b: 24, a: 255}
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
    write_file('marblemadness', code)

def gen_mariobros():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      MarioBrosGame
	tex_mgr   MarioBrosTextureManager
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_mario_bros_game()
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

	app.game.update(dt)
	app.sound_mgr.update()

	render_mario_bros_game(&app.renderer, mut app.game, app.tex_mgr.sprite_texture)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.a, .left { app.game.p1_left = true }
				.d, .right { app.game.p1_right = true }
				.s, .down { app.game.p1_down = true }
				.f, .x { app.game.p1_fire = true }
				.w, .space {
					if app.game.state == .title {
						app.game.start_game(app.game.mode)
					} else if app.game.state == .phase_clear {
						app.game.next_phase()
					} else if app.game.state == .game_over {
						app.game.reset_to_title()
					} else {
						app.game.p1_jump = true
					}
				}
				.m { app.sound_mgr.toggle_sound() }
				.r { app.game.reset_to_title() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.a, .left { app.game.p1_left = false }
				.d, .right { app.game.p1_right = false }
				.s, .down { app.game.p1_down = false }
				.f, .x { app.game.p1_fire = false }
				.w, .space { app.game.p1_jump = false }
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
		window_title: 'Mario Bros. (1983 Arcade Recreation)'
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
    write_file('mariobros', code)

def gen_mathmunchers():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        MathMunchersGame
	sound_mgr   SoundManager
	btn_restart Button
	btn_sound   Button
	btn_pause   Button
	btn_menu    Button
	mouse_x     int
	mouse_y     int
	last_tick   i64
}

fn new_app() App {
	return App{
		game:        new_mathmunchers_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{ x: 10, y: 550, w: 110, h: 40, text: 'RESET [R]' }
		btn_sound:   Button{ x: 130, y: 550, w: 120, h: 40, text: 'SOUND: ON [O]' }
		btn_pause:   Button{ x: 260, y: 550, w: 100, h: 40, text: 'PAUSE [P]' }
		btn_menu:    Button{ x: 370, y: 550, w: 100, h: 40, text: 'MENU [M]' }
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

	app.game.update(dt)
	app.sound_mgr.update()

	render_mathmunchers_game(&app.renderer, &app.game)
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
					app.game.start_new_game()
				} else if app.btn_sound.contains(mx, my) {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
				} else if app.btn_pause.contains(mx, my) {
					if app.game.state == .playing { app.game.state = .paused }
					else if app.game.state == .paused { app.game.state = .playing }
				} else if app.btn_menu.contains(mx, my) {
					app.game.state = .start_menu
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.m {
					app.game.state = .start_menu
					app.sound_mgr.play_sound('move')
				}
				.d {
					app.game.cycle_difficulty()
					app.sound_mgr.play_sound('move')
				}
				.a, .left {
					if app.game.state == .playing && app.game.player.grid_x > 0 {
						app.game.player.grid_x--
						app.game.player.facing_right = false
						app.sound_mgr.play_sound('move')
					}
				}
				.right {
					if app.game.state == .playing && app.game.player.grid_x < grid_cols - 1 {
						app.game.player.grid_x++
						app.game.player.facing_right = true
						app.sound_mgr.play_sound('move')
					}
				}
				.w, .up {
					if app.game.state == .playing && app.game.player.grid_y > 0 {
						app.game.player.grid_y--
						app.sound_mgr.play_sound('move')
					}
				}
				.down {
					if app.game.state == .playing && app.game.player.grid_y < grid_rows - 1 {
						app.game.player.grid_y++
						app.sound_mgr.play_sound('move')
					}
				}
				.space, .enter {
					if app.game.state == .start_menu {
						app.game.start_new_game()
					} else if app.game.state == .level_clear {
						app.game.next_level()
					} else if app.game.state == .game_over {
						app.game.start_new_game()
					} else if app.game.state == .playing {
						app.game.munch()
					}
				}
				.r { app.game.start_new_game() }
				.o {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
				}
				.p {
					if app.game.state == .playing { app.game.state = .paused }
					else if app.game.state == .paused { app.game.state = .playing }
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
		window_title: 'Math Munchers - Retro Educational Arcade'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 15, g: 20, b: 35, a: 255}
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
    write_file('mathmunchers', code)

def gen_memorymatch():
    code = '''module main

import gg
import time

const win_w = 900
const win_h = 650

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      MemoryGame
	sound_mgr SoundManager
	hover_idx int = -1
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_memorymatch_game()
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

	app.game.update(dt)
	app.sound_mgr.update()

	render_memory_match(&app.renderer, &app.game, win_w, win_h, app.hover_idx)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_move {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			app.hover_idx = app.game.get_card_at_pos(mx, my, win_w, win_h)
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.game.state == .game_won {
					app.game.reset_game()
				} else {
					if my < 54 {
						if mx >= 220 && mx <= 360 {
							app.game.toggle_grid_mode()
							app.sound_mgr.play_click_sound()
						} else if mx >= 380 && mx <= 490 {
							app.sound_mgr.toggle_sound()
						} else if mx >= win_w - 140 && mx <= win_w - 20 {
							app.game.reset_game()
							app.sound_mgr.play_click_sound()
						}
					} else {
						clicked_idx := app.game.get_card_at_pos(mx, my, win_w, win_h)
						if clicked_idx >= 0 {
							app.game.handle_card_click(clicked_idx, mut app.sound_mgr)
						}
					}
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.r { app.game.reset_game() }
				.g { app.game.toggle_grid_mode() }
				.s { app.sound_mgr.toggle_sound() }
				.space {
					if app.game.state == .game_won { app.game.reset_game() }
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
		window_title: 'Memory Match - Cyber Cyberdeck Flip Puzzle'
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
    write_file('memorymatch', code)

def gen_micromayhem():
    code = '''module main

import gg
import time

const win_w = 940
const win_h = 660

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      MicroMayhemGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_micromayhem_game()
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

	app.game.update(dt, f64(app.mouse_x))

	if app.game.sound_event != '' {
		ev := app.game.sound_event
		app.game.sound_event = ''
		match ev {
			'tick' { app.sound_mgr.play_tick(600.0) }
			'win' { app.sound_mgr.play_win() }
			'fail' { app.sound_mgr.play_fail() }
			'speedup' { app.sound_mgr.play_speedup() }
			else {}
		}
	}
	app.sound_mgr.update()

	render_micromayhem_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y)
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
				if app.game.phase == .title || app.game.phase == .game_over {
					app.game.start_game()
					app.sound_mgr.play_speedup()
				} else if app.game.phase == .playing {
					app.game.handle_click(f64(e.mouse_x), f64(e.mouse_y))
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.space {
					if app.game.phase == .title || app.game.phase == .game_over {
						app.game.start_game()
						app.sound_mgr.play_speedup()
					} else if app.game.phase == .playing {
						app.game.handle_key_action(0)
					}
				}
				.r { app.game.start_game() }
				.v, .o { app.sound_mgr.toggle_sound() }
				._1 { app.game.handle_key_action(1) }
				._2 { app.game.handle_key_action(2) }
				._3 { app.game.handle_key_action(3) }
				.a, .left { app.game.handle_key_action(-1) }
				.d, .right { app.game.handle_key_action(1) }
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
		window_title: 'Micro Mayhem - Rapid Microgames Challenge'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 20, g: 15, b: 30, a: 255}
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
    write_file('micromayhem', code)

def gen_minesweeper():
    code = '''module main

import gg
import time

const win_width = 860
const win_height = 680

struct App {
mut:
	ctx          &gg.Context = unsafe { nil }
	renderer     Renderer
	game         Minesweeper
	sound_mgr    SoundManager
	tex_mgr      MinesweeperTextureManager
	btn_beg      Button
	btn_int      Button
	btn_exp      Button
	btn_theme    Button
	btn_sound    Button
	btn_reset    Button
	mouse_x      int
	mouse_y      int
	mouse_down   bool
	cell_size    int = 32
	face_rect    Rect
	board_x      int
	board_y      int
	last_tick    i64
}

fn new_app() App {
	mut app := App{
		game:      new_minesweeper(.beginner)
		sound_mgr: new_sound_manager()
		btn_beg:   Button{ x: 20, y: 620, w: 125, h: 38, text: '1: BEG' }
		btn_int:   Button{ x: 155, y: 620, w: 125, h: 38, text: '2: INT' }
		btn_exp:   Button{ x: 290, y: 620, w: 125, h: 38, text: '3: EXP' }
		btn_theme: Button{ x: 425, y: 620, w: 135, h: 38, text: 'THEME [T]' }
		btn_sound: Button{ x: 570, y: 620, w: 135, h: 38, text: 'SOUND [S]' }
		btn_reset: Button{ x: 715, y: 620, w: 125, h: 38, text: 'RESET [R]' }
		last_tick: time.ticks()
	}
	app.recalc_layout()
	return app
}

fn (mut app App) recalc_layout() {
	match app.game.difficulty {
		.beginner { app.cell_size = 40 }
		.intermediate { app.cell_size = 28 }
		.expert { app.cell_size = 24 }
		.custom { app.cell_size = 24 }
	}
	board_w := app.game.cols * app.cell_size
	app.board_x = (win_width - board_w) / 2
	app.board_y = 138
	app.face_rect = Rect{ x: win_width / 2 - 20, y: 80, w: 40, h: 40 }
}

fn (mut app App) restart_game() {
	app.game.reset()
	app.recalc_layout()
}

fn (mut app App) change_diff(diff Difficulty) {
	app.game.set_difficulty(diff)
	app.recalc_layout()
}

fn (app &App) render() {
	r := &app.renderer
	is_neon := app.game.theme_neon
	bg_color := if is_neon { Color{r: 12, g: 15, b: 24, a: 255} } else { Color{r: 192, g: 192, b: 192, a: 255} }
	panel_bg := if is_neon { Color{r: 20, g: 26, b: 40, a: 255} } else { Color{r: 192, g: 192, b: 192, a: 255} }
	light_bev := if is_neon { Color{r: 60, g: 80, b: 130, a: 255} } else { Color{r: 255, g: 255, b: 255, a: 255} }
	dark_bev := if is_neon { Color{r: 10, g: 12, b: 20, a: 255} } else { Color{r: 128, g: 128, b: 128, a: 255} }
	title_col := if is_neon { Color{r: 80, g: 220, b: 255, a: 255} } else { Color{r: 20, g: 30, b: 60, a: 255} }

	set_render_draw_color(r, bg_color.r, bg_color.g, bg_color.b, 255)
	render_clear(r)

	draw_text_centered(r, win_width / 2, 18, 'MINESWEEPER PRO', 3, title_col)

	frame_w := app.game.cols * app.cell_size + 24
	frame_h := app.game.rows * app.cell_size + 80
	frame_x := (win_width - frame_w) / 2
	frame_y := 70

	draw_bevel_rect(r, frame_x, frame_y, frame_w, frame_h, true, panel_bg, light_bev, dark_bev, 4)

	grid_x := frame_x + 10
	grid_y := frame_y + 66
	for row in 0 .. app.game.rows {
		for col in 0 .. app.game.cols {
			cx := grid_x + col * app.cell_size
			cy := grid_y + row * app.cell_size
			cell := app.game.board[row][col]

			if cell.revealed {
				if cell.has_mine {
					draw_bevel_rect(r, cx, cy, app.cell_size, app.cell_size, false, Color{r: 240, g: 50, b: 50, a: 255}, light_bev, dark_bev, 1)
					draw_mine_icon(r, cx + app.cell_size / 2, cy + app.cell_size / 2, app.cell_size - 8, true, app.tex_mgr.sprite_texture)
				} else {
					draw_bevel_rect(r, cx, cy, app.cell_size, app.cell_size, false, panel_bg, light_bev, dark_bev, 1)
					if cell.neighbor_mines > 0 {
						draw_text_centered(r, cx + app.cell_size / 2, cy + 4, '${cell.neighbor_mines}', 2, Color{r: 30, g: 120, b: 255, a: 255})
					}
				}
			} else {
				draw_bevel_rect(r, cx, cy, app.cell_size, app.cell_size, true, panel_bg, light_bev, dark_bev, 2)
				if cell.flagged {
					draw_flag_icon(r, cx + app.cell_size / 2, cy + app.cell_size / 2, app.cell_size - 8, app.tex_mgr.sprite_texture)
				}
			}
		}
	}

	app.btn_beg.render(r, app.mouse_x, app.mouse_y)
	app.btn_int.render(r, app.mouse_x, app.mouse_y)
	app.btn_exp.render(r, app.mouse_x, app.mouse_y)
	app.btn_theme.render(r, app.mouse_x, app.mouse_y)
	app.btn_sound.render(r, app.mouse_x, app.mouse_y)
	app.btn_reset.render(r, app.mouse_x, app.mouse_y)
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

	app.game.update_timer(dt)
	app.sound_mgr.update()

	app.render()
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
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			app.mouse_down = true

			if e.mouse_button == .left {
				if app.btn_beg.contains(mx, my) { app.change_diff(.beginner) }
				else if app.btn_int.contains(mx, my) { app.change_diff(.intermediate) }
				else if app.btn_exp.contains(mx, my) { app.change_diff(.expert) }
				else if app.btn_theme.contains(mx, my) { app.game.theme_neon = !app.game.theme_neon }
				else if app.btn_sound.contains(mx, my) { app.sound_mgr.toggle_sound() }
				else if app.btn_reset.contains(mx, my) { app.restart_game() }
				else {
					// Check Board Grid Click
					frame_w := app.game.cols * app.cell_size + 24
					frame_x := (win_width - frame_w) / 2
					grid_x := frame_x + 10
					grid_y := 70 + 66
					if mx >= grid_x && mx < grid_x + app.game.cols * app.cell_size && my >= grid_y && my < grid_y + app.game.rows * app.cell_size {
						c := (mx - grid_x) / app.cell_size
						r := (my - grid_y) / app.cell_size
						app.game.reveal_cell(r, c)
					}
				}
			} else if e.mouse_button == .right {
				frame_w := app.game.cols * app.cell_size + 24
				frame_x := (win_width - frame_w) / 2
				grid_x := frame_x + 10
				grid_y := 70 + 66
				if mx >= grid_x && mx < grid_x + app.game.cols * app.cell_size && my >= grid_y && my < grid_y + app.game.rows * app.cell_size {
					c := (mx - grid_x) / app.cell_size
					r := (my - grid_y) / app.cell_size
					app.game.toggle_flag(r, c)
				}
			}
		}
		.mouse_up {
			app.mouse_down = false
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.r { app.restart_game() }
				._1 { app.change_diff(.beginner) }
				._2 { app.change_diff(.intermediate) }
				._3 { app.change_diff(.expert) }
				.t { app.game.theme_neon = !app.game.theme_neon }
				.s { app.sound_mgr.toggle_sound() }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:        win_width
		height:       win_height
		window_title: 'Minesweeper Pro'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 192, g: 192, b: 192, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_width
		height: win_height
	}
	ctx.run()
}
'''
    write_file('minesweeper', code)

def gen_missilecommand():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      MissileCommandGame
	tex_mgr   MissileCommandTextureManager
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_missilecommand_game()
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

	app.game.update(dt)
	app.sound_mgr.update()

	render_missilecommand_game(&app.renderer, mut app.game, app.tex_mgr.sprite_texture)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_move {
			app.game.crosshair_x = f32(e.mouse_x)
			app.game.crosshair_y = f32(e.mouse_y)
		}
		.mouse_down {
			if e.mouse_button == .left {
				if app.game.state == .menu || app.game.state == .game_over {
					app.game.reset_game()
				} else {
					app.game.fire_interceptor(f32(e.mouse_x), f32(e.mouse_y))
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.space {
					if app.game.state == .menu || app.game.state == .game_over {
						app.game.reset_game()
					} else {
						app.game.fire_interceptor(app.game.crosshair_x, app.game.crosshair_y)
					}
				}
				.p {
					if app.game.state == .playing { app.game.state = .paused }
					else if app.game.state == .paused { app.game.state = .playing }
				}
				.r { app.game.reset_game() }
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
		window_title: 'Missile Command Air Defense'
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
    write_file('missilecommand', code)

def gen_nuclearthrone():
    code = '''module main

import gg
import math
import time

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        NuclearThroneGame
	tex_mgr     NuclearThroneTextureManager
	sound_mgr   SoundManager
	btn_restart Button
	btn_sound   Button
	mouse_x     int
	mouse_y     int
	key_w       bool
	key_a       bool
	key_s       bool
	key_d       bool
	key_shoot   bool
	key_ability bool
	key_swap    bool
	last_tick   i64
}

fn new_app() App {
	return App{
		game:        new_nuclear_throne_game()
		tex_mgr:     new_nuclear_throne_texture_manager()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{ x: 10, y: 550, w: 120, h: 40, text: 'RESET [R]' }
		btn_sound:   Button{ x: 140, y: 550, w: 130, h: 40, text: 'SOUND: ON [O]' }
		last_tick:   time.ticks()
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

	mut move_x := 0.0
	mut move_y := 0.0
	if app.key_a { move_x -= 1.0 }
	if app.key_d { move_x += 1.0 }
	if app.key_w { move_y -= 1.0 }
	if app.key_s { move_y += 1.0 }

	if move_x != 0 && move_y != 0 {
		move_x *= 0.7071
		move_y *= 0.7071
	}

	player_screen_x := app.game.player.x - app.game.camera_x
	player_screen_y := app.game.player.y - app.game.camera_y
	aim_angle := math.atan2(f64(app.mouse_y) - player_screen_y, f64(app.mouse_x) - player_screen_x)

	app.game.update(dt, move_x, move_y, aim_angle, app.key_shoot, app.key_ability, app.key_swap)
	app.key_swap = false

	if app.game.last_sound_event != '' {
		app.sound_mgr.play_sound(app.game.last_sound_event)
		app.game.last_sound_event = ''
	}
	app.sound_mgr.update()

	render_nuclear_throne_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
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
				if app.game.mutation_screen {
					if app.mouse_y >= 190 && app.mouse_y <= 440 {
						idx := (app.mouse_y - 190) / 55
						app.game.select_mutation(idx)
					}
				} else {
					app.key_shoot = true
				}
			} else if e.mouse_button == .right {
				app.key_ability = true
			}
		}
		.mouse_up {
			if e.mouse_button == .left { app.key_shoot = false }
			else if e.mouse_button == .right { app.key_ability = false }
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.w, .up { app.key_w = true }
				.a, .left { app.key_a = true }
				.s, .down { app.key_s = true }
				.d, .right { app.key_d = true }
				.e, .f, .q { app.key_swap = true }
				.space, .left_shift { app.key_ability = true }
				.r { app.game.start_new_game() }
				.o { app.sound_mgr.toggle_sound() }
				._1, ._2, ._3, ._4, ._5 {
					if app.game.mutation_screen {
						app.game.select_mutation(int(e.key_code) - int(gg.KeyCode._1))
					}
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.w, .up { app.key_w = false }
				.a, .left { app.key_a = false }
				.s, .down { app.key_s = false }
				.d, .right { app.key_d = false }
				.space, .left_shift { app.key_ability = false }
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
		window_title: 'Nuclear Throne - Wasteland Twin-Stick Shooter'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 20, g: 15, b: 12, a: 255}
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
    write_file('nuclearthrone', code)

def gen_pacman():
    code = '''module main

import gg
import math
import time

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        Game
	sound_mgr   SoundManager
	tex_mgr     PacmanTextureManager
	btn_reset   Button
	btn_sound   Button
	btn_pause   Button
	mouse_x     int
	mouse_y     int
	last_tick   i64
}

fn new_app() App {
	return App{
		game:      new_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_pacman_texture_manager()
		btn_reset: Button{
			x:            735
			y:            160
			w:            200
			h:            44
			text:         'RESET [R]'
			bg_color:     Color{ r: 35, g: 45, b: 70, a: 255 }
			hover_color:  Color{ r: 55, g: 70, b: 105, a: 255 }
			text_color:   Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 90, g: 120, b: 180, a: 255 }
		}
		btn_sound: Button{
			x:            735
			y:            220
			w:            200
			h:            44
			text:         'SOUND: ON [S]'
			bg_color:     Color{ r: 35, g: 45, b: 70, a: 255 }
			hover_color:  Color{ r: 55, g: 70, b: 105, a: 255 }
			text_color:   Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 90, g: 120, b: 180, a: 255 }
		}
		btn_pause: Button{
			x:            735
			y:            280
			w:            200
			h:            44
			text:         'PAUSE [P]'
			bg_color:     Color{ r: 35, g: 45, b: 70, a: 255 }
			hover_color:  Color{ r: 55, g: 70, b: 105, a: 255 }
			text_color:   Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 90, g: 120, b: 180, a: 255 }
		}
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

	game_ev := app.game.update(dt)
	if game_ev.ate_dot || (game_ev.is_moving && math.fmod(app.game.global_timer, 0.2) < dt) {
		app.sound_mgr.play_waka_sound()
	}
	if game_ev.ate_power { app.sound_mgr.play_power_pellet_sound() }
	if game_ev.ate_fruit { app.sound_mgr.play_eat_fruit_sound() }
	if game_ev.ate_ghost { app.sound_mgr.play_eat_ghost_sound() }
	if game_ev.pac_died { app.sound_mgr.play_death_sound() }
	if game_ev.level_win { app.sound_mgr.play_extra_life_sound() }

	app.sound_mgr.update()

	draw_game(&app.renderer, &app.game, app.mouse_x, app.mouse_y, &app.btn_reset, &app.btn_sound, &app.btn_pause, app.tex_mgr.sprite_texture)
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
				if app.btn_reset.contains(mx, my) {
					app.game.init_level()
					app.game.score = 0
					app.game.lives = 3
					app.sound_mgr.play_intro_sound()
				} else if app.btn_sound.contains(mx, my) {
					is_on := app.sound_mgr.toggle_sound()
					app.btn_sound.text = if is_on { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
				} else if app.btn_pause.contains(mx, my) {
					if app.game.status == .playing { app.game.status = .paused }
					else if app.game.status == .paused { app.game.status = .playing }
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.up, .w { app.game.pacman.next_dir = .up }
				.down, .s { app.game.pacman.next_dir = .down }
				.left, .a { app.game.pacman.next_dir = .left }
				.right, .d { app.game.pacman.next_dir = .right }
				.r {
					app.game.init_level()
					app.game.score = 0
					app.game.lives = 3
				}
				.p {
					if app.game.status == .playing { app.game.status = .paused }
					else if app.game.status == .paused { app.game.status = .playing }
				}
				.o {
					is_on := app.sound_mgr.toggle_sound()
					app.btn_sound.text = if is_on { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
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
		window_title: 'Pac-Man Arcade'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 5, g: 5, b: 15, a: 255}
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
    write_file('pacman', code)

def gen_paneldepon():
    code = '''module main

import gg
import math
import rand
import time

const win_width = 860
const win_height = 840

const board_x = 240
const board_y = 120
const cell_size = 64
const grid_w = board_w * cell_size
const grid_h = board_h * cell_size

struct PopParticle {
mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	max_l f64
	color Color
	size  int
}

struct FloatText {
mut:
	x     f64
	y     f64
	text  string
	life  f64
	max_l f64
	scale int
	color Color
}

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	sound_mgr   SoundManager
	game        PanelGame
	tex_mgr     PanelDePonTextureManager
	particles   []PopParticle
	float_texts []FloatText
	shake_timer f64
	paused      bool
	btn_reset   Button
	btn_sound   Button
	btn_pause   Button
	mouse_x     int
	mouse_y     int
	last_tick   i64
}

fn (mut tm PanelDePonTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/paneldepon.png',
		'./assets/sprites/paneldepon.png',
		'../assets/sprites/paneldepon.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				return
			}
		}
	}
}

fn new_app() App {
	btn_y := 770
	return App{
		sound_mgr: new_sound_manager()
		game:      new_panel_game()
		btn_reset: Button{
			x: 40, y: btn_y, w: 160, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 45, g: 30, b: 55, a: 255},
			hover_color: Color{r: 75, g: 45, b: 90, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255},
			border_color: Color{r: 160, g: 80, b: 180, a: 255},
		}
		btn_sound: Button{
			x: 220, y: btn_y, w: 160, h: 42, text: 'SOUND [M]',
			bg_color: Color{r: 30, g: 45, b: 50, a: 255},
			hover_color: Color{r: 50, g: 75, b: 85, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255},
			border_color: Color{r: 80, g: 140, b: 160, a: 255},
		}
		btn_pause: Button{
			x: 400, y: btn_y, w: 160, h: 42, text: 'PAUSE [P]',
			bg_color: Color{r: 45, g: 45, b: 30, a: 255},
			hover_color: Color{r: 75, g: 75, b: 45, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255},
			border_color: Color{r: 160, g: 160, b: 70, a: 255},
		}
		last_tick: time.ticks()
	}
}

fn get_panel_colors(panel_type int) (Color, Color, Color) {
	match panel_type {
		1 { return Color{r: 240, g: 40, b: 65, a: 255}, Color{r: 255, g: 140, b: 160, a: 255}, Color{r: 145, g: 15, b: 30, a: 255} }
		2 { return Color{r: 250, g: 215, b: 35, a: 255}, Color{r: 255, g: 245, b: 145, a: 255}, Color{r: 160, g: 135, b: 15, a: 255} }
		3 { return Color{r: 35, g: 195, b: 245, a: 255}, Color{r: 130, g: 235, b: 255, a: 255}, Color{r: 15, g: 110, b: 165, a: 255} }
		4 { return Color{r: 40, g: 215, b: 75, a: 255}, Color{r: 140, g: 255, b: 160, a: 255}, Color{r: 15, g: 130, b: 40, a: 255} }
		5 { return Color{r: 195, g: 45, b: 240, a: 255}, Color{r: 235, g: 140, b: 255, a: 255}, Color{r: 115, g: 20, b: 150, a: 255} }
		else { return Color{r: 90, g: 90, b: 90, a: 255}, Color{r: 140, g: 140, b: 140, a: 255}, Color{r: 50, g: 50, b: 50, a: 255} }
	}
}

fn draw_panel(renderer &Renderer, cx int, cy int, size int, panel_type int, tex &Texture) {
	if panel_type == 0 { return }
	r := size / 2 - 2

	main_c, high_c, _ := get_panel_colors(panel_type)

	rect := Rect{ x: cx - r + 1, y: cy - r + 1, w: (r - 1) * 2, h: (r - 1) * 2 }
	set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, 255)
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 255)
	for i in 0 .. 3 {
		render_draw_line(renderer, cx - r + 1 + i, cy - r + 1 + i, cx + r - 1 - i, cy - r + 1 + i)
		render_draw_line(renderer, cx - r + 1 + i, cy - r + 1 + i, cx - r + 1 + i, cy + r - 1 - i)
	}
}

fn (mut app App) spawn_burst(cx int, cy int, panel_type int) {
	main_c, _, _ := get_panel_colors(panel_type)
	for _ in 0 .. 16 {
		ang := rand.f64_in_range(0.0, 2.0 * math.pi) or { 0.0 }
		spd := rand.f64_in_range(80.0, 240.0) or { 150.0 }
		life := rand.f64_in_range(0.3, 0.6) or { 0.45 }
		app.particles << PopParticle{
			x:     f64(cx)
			y:     f64(cy)
			vx:    math.cos(ang) * spd
			vy:    math.sin(ang) * spd
			life:  life
			max_l: life
			color: main_c
			size:  rand.int_in_range(3, 6) or { 4 }
		}
	}
}

fn (mut app App) update(dt f64) {
	if app.paused { return }
	if app.shake_timer > 0 { app.shake_timer -= dt }

	prev_clears := app.game.clears_count
	app.game.update(dt)

	if app.game.clears_count > prev_clears {
		app.sound_mgr.play_clear_sound(app.game.chain_counter)
		app.shake_timer = 0.15
	}

	mut active_p := []PopParticle{}
	for mut p in app.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.life -= dt
		if p.life > 0 { active_p << p }
	}
	app.particles = active_p
}

fn (mut app App) render() {
	renderer := &app.renderer
	set_render_draw_color(renderer, 20, 16, 32, 255)
	render_clear(renderer)

	// Board background
	b_rect := Rect{ x: board_x - 6, y: board_y - 6, w: grid_w + 12, h: grid_h + 12 }
	set_render_draw_color(renderer, 35, 28, 55, 255)
	render_fill_rect(renderer, &b_rect)

	// Grid panels
	for r in 0 .. board_h {
		for c in 0 .. board_w {
			p := app.game.grid[r][c]
			if p.panel_type != 0 {
				cx := board_x + c * cell_size + cell_size / 2
				cy := board_y + r * cell_size + cell_size / 2
				draw_panel(renderer, cx, cy, cell_size, p.panel_type, app.tex_mgr.sprite_texture)
			}
		}
	}

	// Cursor
	cur_x := board_x + app.game.cursor_c * cell_size
	cur_y := board_y + app.game.cursor_r * cell_size
	set_render_draw_color(renderer, 255, 255, 255, 255)
	c_box := Rect{ x: cur_x, y: cur_y, w: cell_size * 2, h: cell_size }
	render_draw_rect(renderer, &c_box)

	// Particles
	for p in app.particles {
		prect := Rect{ x: int(p.x), y: int(p.y), w: p.size, h: p.size }
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, 255)
		render_fill_rect(renderer, &prect)
	}

	// HUD
	draw_text(renderer, 40, 140, 'SCORE', 2, Color{r: 180, g: 190, b: 220, a: 255})
	draw_text(renderer, 40, 170, '${app.game.score}', 3, Color{r: 255, g: 220, b: 70, a: 255})
	draw_text(renderer, 40, 230, 'CHAIN', 2, Color{r: 180, g: 190, b: 220, a: 255})
	draw_text(renderer, 40, 260, '${app.game.chain_counter}x', 3, Color{r: 70, g: 220, b: 255, a: 255})

	app.btn_reset.render(renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.render(renderer, app.mouse_x, app.mouse_y)
	app.btn_pause.render(renderer, app.mouse_x, app.mouse_y)

	if app.game.state == .game_over {
		over_box := Rect{ x: win_width / 2 - 180, y: win_height / 2 - 50, w: 360, h: 100 }
		set_render_draw_color(renderer, 30, 10, 15, 240)
		render_fill_rect(renderer, &over_box)
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 30, 'GAME OVER', 4, Color{r: 255, g: 60, b: 80, a: 255})
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 15, 'PRESS [R] TO RESTART', 2, Color{r: 255, g: 255, b: 255, a: 255})
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.update(dt)
	app.sound_mgr.update()

	app.render()
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
				if app.btn_reset.is_hovered(mx, my) { app.game = new_panel_game() }
				else if app.btn_sound.is_hovered(mx, my) { app.sound_mgr.toggle_sound() }
				else if app.btn_pause.is_hovered(mx, my) { app.paused = !app.paused }
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.r { app.game = new_panel_game() }
				.p { app.paused = !app.paused }
				.m { app.sound_mgr.toggle_sound() }
				.up, .w { app.game.move_cursor(-1, 0) }
				.down, .s { app.game.move_cursor(1, 0) }
				.left, .a { app.game.move_cursor(0, -1) }
				.right, .d { app.game.move_cursor(0, 1) }
				.space, .enter {
					if app.game.swap_panels() {
						app.sound_mgr.play_swap_sound()
					}
				}
				.f { app.game.raise_stack() }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:        win_width
		height:       win_height
		window_title: 'Panel de Pon / Puzzle League'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 20, g: 16, b: 32, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_width
		height: win_height
	}
	app.tex_mgr.init(&app.renderer)
	ctx.run()
}
'''
    write_file('paneldepon', code)

def main():
    gen_liarsdice()
    gen_lightcycles()
    gen_lolo()
    gen_lunarlander()
    gen_mappy()
    gen_marblemadness()
    gen_mariobros()
    gen_mathmunchers()
    gen_memorymatch()
    gen_micromayhem()
    gen_minesweeper()
    gen_missilecommand()
    gen_nuclearthrone()
    gen_pacman()
    gen_paneldepon()

if __name__ == '__main__':
    main()
