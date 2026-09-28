#!/usr/bin/env python3
import os

DST = '/Users/codecaine/vlang_games'

def write_file(game, code):
    p = os.path.join(DST, game, 'main.v')
    with open(p, 'w') as fp:
        fp.write(code)
    print(f"Wrote {game}/main.v")

def gen_fire():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      FireGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_fire_game()
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

	app.game.update(dt, mut app.sound_mgr)
	app.sound_mgr.update()

	draw_fire_game(&app.renderer, &app.game)
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
				.m {
					app.sound_mgr.toggle_sound()
				}
				._1 {
					app.game.start_game(.game_a)
				}
				._2 {
					app.game.start_game(.game_b)
				}
				.space, .enter {
					if app.game.state == .title || app.game.state == .game_over {
						app.game.start_game(app.game.mode)
					}
				}
				.left, .a {
					app.game.move_left()
				}
				.right, .d {
					app.game.move_right()
				}
				.r {
					app.game.reset_game()
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
		window_title: 'Fire (Game & Watch Multi Screen Classic)'
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
    write_file('fire', code)

def gen_flappy():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      FlappyGame
	tex_mgr   FlappyTextureManager
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_flappy_game()
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

	render_flappy_game(&app.renderer, &app.game, world_w, world_h, app.tex_mgr.sprite_texture)
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
				.r {
					app.game.reset_game()
				}
				.s, .m {
					app.sound_mgr.toggle_sound()
				}
				.space, .up, .w {
					if app.game.state == .game_over {
						app.game.reset_game()
					} else {
						if app.game.flap() {
							app.sound_mgr.play_flap()
						}
					}
				}
				else {}
			}
		}
		.mouse_down {
			if app.game.state == .game_over {
				app.game.reset_game()
			} else {
				if app.game.flap() {
					app.sound_mgr.play_flap()
				}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:        world_w
		height:       world_h
		window_title: 'Flappy Bird Arcade'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  world_w
		height: world_h
	}
	ctx.run()
}
'''
    write_file('flappy', code)

def gen_game2048():
    code = '''module main

import gg
import time

const win_w = 600
const win_h = 700

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      Game2048
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_game_2048()
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

	render_game_2048(&app.renderer, &app.game, win_w, win_h, []MergeParticle{})
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn (mut app App) handle_slide(dir Direction) {
	moved, pts, _ := app.game.slide(dir)
	if moved {
		if pts > 0 {
			app.sound_mgr.play_merge()
		} else {
			app.sound_mgr.play_slide()
		}
	}
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.key_down {
			match e.key_code {
				.escape {
					exit(0)
				}
				.f5 {
					app.game.save_state()
				}
				.f9 {
					app.game.load_state()
				}
				.r {
					app.game.reset()
				}
				.u {
					app.game.undo()
				}
				.s, .m {
					app.sound_mgr.toggle_sound()
				}
				.left, .a {
					app.handle_slide(.left)
				}
				.right, .d {
					app.handle_slide(.right)
				}
				.up, .w {
					app.handle_slide(.up)
				}
				.down {
					app.handle_slide(.down)
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
		window_title: '2048 - Classic Sliding Tile Puzzle'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 250, g: 248, b: 239, a: 255}
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
    write_file('game2048', code)

def gen_goldminer():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      GoldMinerGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_gold_miner_game()
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

	ev := app.game.update(dt)
	if ev.hit_item {
		app.sound_mgr.play_grab()
	}
	if ev.won_level {
		app.sound_mgr.play_win()
	}
	if ev.lost_level {
		app.sound_mgr.play_gameover()
	}
	app.sound_mgr.update()

	render_goldminer_game(&app.renderer, &app.game, world_w, world_h)
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
				.f5 {
					app.game.save_state()
				}
				.f9 {
					app.game.load_state()
				}
				.r {
					app.game.reset_game()
				}
				.s, .m {
					app.sound_mgr.toggle_sound()
				}
				.down, .space {
					if app.game.state == .level_win {
						app.game.next_level()
					} else if app.game.state == .game_over {
						app.game.reset_game()
					} else {
						if app.game.launch_claw() {
							app.sound_mgr.play_launch()
						}
					}
				}
				.up, .w {
					if app.game.use_dynamite() {
						app.sound_mgr.play_dynamite()
					}
				}
				else {}
			}
		}
		.mouse_down {
			if app.game.state == .level_win {
				app.game.next_level()
			} else if app.game.state == .game_over {
				app.game.reset_game()
			} else {
				if app.game.launch_claw() {
					app.sound_mgr.play_launch()
				}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:        world_w
		height:       world_h
		window_title: 'Gold Miner Arcade'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  world_w
		height: world_h
	}
	ctx.run()
}
'''
    write_file('goldminer', code)

def gen_jezzball():
    code = '''module main

import gg
import time

const win_w = 880
const win_h = 600

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      JezzGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_jezz_game()
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

	render_jezz_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y)
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
				if app.game.is_won {
					app.game.init_level(app.game.level + 1)
				} else if app.game.is_game_over {
					app.game.init_level(1)
					app.game.lives = 3
					app.game.score = 0
				} else {
					app.game.start_wall(app.mouse_x, app.mouse_y)
				}
			} else if e.mouse_button == .right {
				app.game.toggle_orientation()
			}
		}
		.key_down {
			match e.key_code {
				.escape {
					exit(0)
				}
				.space {
					if app.game.is_won {
						app.game.init_level(app.game.level + 1)
					} else if app.game.is_game_over {
						app.game.init_level(1)
						app.game.lives = 3
						app.game.score = 0
					} else {
						app.game.toggle_orientation()
					}
				}
				.n {
					if app.game.is_won {
						app.game.init_level(app.game.level + 1)
					}
				}
				.r {
					app.game.init_level(1)
					app.game.lives = 3
					app.game.score = 0
				}
				.m {
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
		window_title: 'JezzBall (Windows Entertainment Pack Classic)'
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
    write_file('jezzball', code)

def gen_downwell():
    code = '''module main

import gg
import time

struct Button {
pub mut:
	x           int
	y           int
	w           int
	h           int
	text        string
	bg_color    Color
	hover_color Color
	text_color  Color
}

fn (b Button) contains(px int, py int) bool {
	return px >= b.x && px <= b.x + b.w && py >= b.y && py <= b.y + b.h
}

fn (b Button) render(renderer &Renderer, mx int, my int) {
	hovered := b.contains(mx, my)
	col := if hovered { b.hover_color } else { b.bg_color }
	set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
	render_fill_rect(renderer, &Rect{ x: b.x, y: b.y, w: b.w, h: b.h })
	draw_text_centered(renderer, b.x + b.w / 2, b.y + b.h / 2 - 6, b.text, 2, b.text_color)
}

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        DownwellGame
	sound_mgr   SoundManager
	tex_mgr     DownwellTextureManager
	mouse_x     int
	mouse_y     int
	key_left    bool
	key_right   bool
	key_jump    bool
	key_shoot   bool
	paused      bool
	btn_restart Button
	btn_sound   Button
	last_tick   i64
}

fn new_app() App {
	return App{
		game:        new_downwell_game()
		sound_mgr:   new_sound_manager()
		last_tick:   time.ticks()
		btn_restart: Button{
			x:           20
			y:           540
			w:           150
			h:           40
			text:        'RESTART [R]'
			bg_color:    Color{ r: 40, g: 40, b: 50, a: 220 }
			hover_color: Color{ r: 70, g: 70, b: 85, a: 255 }
			text_color:  Color{ r: 255, g: 255, b: 255, a: 255 }
		}
		btn_sound:   Button{
			x:           180
			y:           540
			w:           150
			h:           40
			text:        'SOUND: ON [O]'
			bg_color:    Color{ r: 40, g: 40, b: 50, a: 220 }
			hover_color: Color{ r: 70, g: 70, b: 85, a: 255 }
			text_color:  Color{ r: 255, g: 255, b: 255, a: 255 }
		}
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

	if !app.paused {
		app.game.key_left = app.key_left
		app.game.key_right = app.key_right
		app.game.key_jump = app.key_jump
		app.game.key_shoot = app.key_shoot
		app.game.update(dt)
	}
	app.sound_mgr.update()

	render_downwell_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
	app.btn_restart.render(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.render(&app.renderer, app.mouse_x, app.mouse_y)
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
			if app.btn_restart.contains(mx, my) {
				app.game.start_new_game()
			} else if app.btn_sound.contains(mx, my) {
				muted := !app.sound_mgr.toggle_sound()
				app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
			} else if app.game.shop_active {
				if my >= 200 && my <= 400 {
					idx := (my - 200) / 55
					app.game.buy_shop_item(idx)
				}
			} else {
				app.key_shoot = true
			}
		}
		.mouse_up {
			app.key_shoot = false
		}
		.key_down {
			match e.key_code {
				.escape {
					exit(0)
				}
				.a, .left {
					app.key_left = true
				}
				.d, .right {
					app.key_right = true
				}
				.space, .up, .z {
					app.key_jump = true
				}
				.down, .x {
					app.key_shoot = true
				}
				.r {
					app.game.start_new_game()
				}
				.o, .m {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
				}
				.p {
					app.paused = !app.paused
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.a, .left {
					app.key_left = false
				}
				.d, .right {
					app.key_right = false
				}
				.space, .up, .z {
					app.key_jump = false
				}
				.down, .x {
					app.key_shoot = false
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
		window_title: 'Downwell - Gunboots Vertical Descent'
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
    write_file('downwell', code)

def gen_duke():
    code = '''module main

import gg
import time

const win_w = 960
const win_h = 600

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      DukeGame
	sound_mgr SoundManager
	sparks    []SparkParticle
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_duke_game()
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

	update_sparks(mut app.sparks, dt)
	app.game.update(dt, mut app.sparks)
	app.sound_mgr.update()

	render_duke_game(&app.renderer, &app.game, win_w, win_h, app.sparks)
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
				.a, .left {
					app.game.key_left = true
				}
				.d, .right {
					app.game.key_right = true
				}
				.w, .up {
					app.game.key_up = true
				}
				.s, .down {
					app.game.key_down = true
				}
				.space, .f, .left_control {
					app.game.fire_weapon()
				}
				.r {
					app.game.reset()
				}
				.m {
					app.sound_mgr.toggle_sound()
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
				.w, .up {
					app.game.key_up = false
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
		width:        win_w
		height:       win_h
		window_title: 'Duke - 90s Platformer Classic'
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
    write_file('duke', code)

def gen_etchasketch():
    code = '''module main

import gg
import time

const win_w = 920
const win_h = 680

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      EtchGame
	sound_mgr SoundManager
	key_left  bool
	key_right bool
	key_up    bool
	key_down  bool
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_etch_game()
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

	spd := 140.0 * dt
	mut kx := 0.0
	mut ky := 0.0
	if app.key_left { kx -= spd }
	if app.key_right { kx += spd }
	if app.key_up { ky -= spd }
	if app.key_down { ky += spd }
	if kx != 0.0 || ky != 0.0 {
		app.game.move_knobs(kx, ky)
	}

	app.game.update(dt)
	app.sound_mgr.update()

	render_etch_game(&app.renderer, mut app.game, win_w, win_h, app.sound_mgr.sound_enabled)
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
				.f5 {
					app.game.save_state()
				}
				.f9 {
					app.game.load_state()
				}
				.left, .a {
					app.key_left = true
				}
				.right, .d {
					app.key_right = true
				}
				.up, .w {
					app.key_up = true
				}
				.down, .s {
					app.key_down = true
				}
				.c {
					app.game.clear_screen()
					app.sound_mgr.play_shake()
				}
				.r {
					app.game.shake_and_erase()
					app.sound_mgr.play_shake()
				}
				.m {
					app.sound_mgr.toggle_sound()
				}
				._1 {
					app.game.color_idx = 0
				}
				._2 {
					app.game.color_idx = 1
				}
				._3 {
					app.game.color_idx = 2
				}
				._4 {
					app.game.color_idx = 3
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
				.up, .w {
					app.key_up = false
				}
				.down, .s {
					app.key_down = false
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
		window_title: 'Etch A Sketch - Classic Mechanical Drawing Toy'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 220, g: 30, b: 30, a: 255}
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
    write_file('etchasketch', code)

def gen_dopewars():
    code = '''module main

import gg
import time

const win_w = 920
const win_h = 640

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      DopeWarsGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_dopewars_game()
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

	render_dopewars_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.sound_mgr.sound_enabled)
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
		.key_down {
			match e.key_code {
				.escape {
					if app.game.ui_state != .market && app.game.ui_state != .police_encounter {
						app.game.ui_state = .market
					} else {
						exit(0)
					}
				}
				.f5 {
					app.game.save_state()
				}
				.f9 {
					app.game.load_state()
				}
				.up {
					if app.game.ui_state == .market {
						if app.game.selected_drug > 0 { app.game.selected_drug-- }
					}
				}
				.down {
					if app.game.ui_state == .market {
						if app.game.selected_drug < app.game.drugs.len - 1 { app.game.selected_drug++ }
					}
				}
				.b {
					app.game.buy_drug(app.game.selected_drug, 1)
				}
				.d, .s {
					app.game.sell_drug(app.game.selected_drug, 1)
				}
				.t {
					app.game.ui_state = .travel
				}
				.l {
					app.game.ui_state = .loan_shark
				}
				.k {
					app.game.ui_state = .bank
				}
				.m {
					app.sound_mgr.toggle_sound()
				}
				.r {
					if app.game.ui_state == .police_encounter {
						app.game.police_run()
					} else {
						app.game.reset()
					}
				}
				.f {
					if app.game.ui_state == .police_encounter {
						app.game.police_fight()
					}
				}
				._1 {
					if app.game.ui_state == .travel { app.game.travel(0) }
					else { app.game.selected_drug = 0 }
				}
				._2 {
					if app.game.ui_state == .travel { app.game.travel(1) }
					else { app.game.selected_drug = 1 }
				}
				._3 {
					if app.game.ui_state == .travel { app.game.travel(2) }
					else { app.game.selected_drug = 2 }
				}
				._4 {
					if app.game.ui_state == .travel { app.game.travel(3) }
					else { app.game.selected_drug = 3 }
				}
				._5 {
					if app.game.ui_state == .travel { app.game.travel(4) }
					else { app.game.selected_drug = 4 }
				}
				._6 {
					if app.game.ui_state == .travel { app.game.travel(5) }
					else { app.game.selected_drug = 5 }
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
		window_title: 'Dope Wars - 1984 Financial Strategy Game'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 10, g: 15, b: 24, a: 255}
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
    write_file('dopewars', code)

def gen_lemmings():
    code = '''module main

import gg
import time

const win_w = 920
const win_h = 600

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      LemmingsGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_lemmings_game()
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

	render_lemmings_game(&app.renderer, app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.sound_mgr.sound_enabled)
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
				app.game.assign_skill_at(app.mouse_x, app.mouse_y)
			}
		}
		.key_down {
			match e.key_code {
				.escape {
					exit(0)
				}
				._1, .c {
					app.game.selected_skill = .climber
				}
				._2, .f {
					app.game.selected_skill = .floater
				}
				._3, .b {
					app.game.selected_skill = .bomber
				}
				._4, .k {
					app.game.selected_skill = .blocker
				}
				._5, .u {
					app.game.selected_skill = .builder
				}
				._6, .s {
					app.game.selected_skill = .basher
				}
				._7, .m {
					app.game.selected_skill = .miner
				}
				._8, .d {
					app.game.selected_skill = .digger
				}
				.p {
					app.game.is_paused = !app.game.is_paused
				}
				.r {
					app.game.reset()
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
		window_title: 'Lemmings (1991 Psygnosis Classic Recreation)'
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
    write_file('lemmings', code)

def gen_klax():
    code = '''module main

import gg
import time

const win_width = 880
const win_height = 840

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        KlaxGame
	sound_mgr   SoundManager
	paused      bool
	last_tick   i64
}

fn new_app() App {
	return App{
		game:      new_klax_game()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn (mut app App) render() {
	renderer := &app.renderer
	ticks := u32(time.ticks())

	set_render_draw_color(renderer, 15, 12, 24, 255)
	render_clear(renderer)

	draw_text_centered_fitted(renderer, win_width / 2, 20, 'KLAX // IT IS THE NINETIES AND THERE IS TIME FOR...', 3, Color{ r: 255, g: 215, b: 0, a: 255 })
	draw_text_centered(renderer, win_width / 2, 50, 'SCORE: ${app.game.score}   LIVES: ${app.game.lives}   TILES LEFT: ${app.game.tiles_to_drop}', 2, Color{ r: 240, g: 240, b: 255, a: 255 })

	// Paddle
	px := 440 + (app.game.paddle_pos - 2) * 50
	py := 620
	set_render_draw_color(renderer, 200, 220, 255, 255)
	render_fill_rect(renderer, &Rect{ x: px - 25, y: py, w: 50, h: 10 })

	// Held tiles
	for i, t in app.game.held_tiles {
		col := match t {
			1 { Color{ r: 255, g: 50, b: 50, a: 255 } }
			2 { Color{ r: 50, g: 100, b: 255, a: 255 } }
			3 { Color{ r: 50, g: 255, b: 100, a: 255 } }
			4 { Color{ r: 255, g: 255, b: 50, a: 255 } }
			else { Color{ r: 200, g: 50, b: 255, a: 255 } }
		}
		set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
		render_fill_rect(renderer, &Rect{ x: px - 20, y: py - 15 - i * 15, w: 40, h: 12 })
	}

	// Well bin grid
	for r in 0 .. 5 {
		for c in 0 .. 5 {
			bx := 340 + c * 40
			by := 650 + r * 30
			t := app.game.bin[r][c]
			if t > 0 {
				col := match t {
					1 { Color{ r: 255, g: 50, b: 50, a: 255 } }
					2 { Color{ r: 50, g: 100, b: 255, a: 255 } }
					3 { Color{ r: 50, g: 255, b: 100, a: 255 } }
					4 { Color{ r: 255, g: 255, b: 50, a: 255 } }
					else { Color{ r: 200, g: 50, b: 255, a: 255 } }
				}
				set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
				render_fill_rect(renderer, &Rect{ x: bx, y: by, w: 38, h: 28 })
			} else {
				set_render_draw_color(renderer, 30, 25, 45, 255)
				render_draw_rect(renderer, &Rect{ x: bx, y: by, w: 38, h: 28 })
			}
		}
	}

	if app.game.is_game_over {
		set_render_draw_color(renderer, 0, 0, 0, 180)
		render_fill_rect(renderer, &Rect{ x: 0, y: 0, w: win_width, h: win_height })
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 20, 'GAME OVER', 5, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 30, 'PRESS [R] TO RESTART', 2, Color{ r: 255, g: 255, b: 255, a: 255 })
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
		app.game.update(dt)
	}
	app.sound_mgr.update()

	app.render()
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
				.r {
					app.game = new_klax_game()
				}
				.p {
					app.paused = !app.paused
				}
				.m {
					app.sound_mgr.toggle_sound()
				}
				.left, .a {
					app.game.move_paddle(-1)
				}
				.right, .d {
					app.game.move_paddle(1)
				}
				.down, .s, .space {
					app.game.flip_tile()
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
		width:        win_width
		height:       win_height
		window_title: 'Klax (Atari 1989 Arcade Recreation)'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 15, g: 12, b: 24, a: 255}
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
    write_file('klax', code)

def gen_gnujump():
    code = '''module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      GnuJumpEngine
	sound_mgr SoundManager
	key_left  bool
	key_right bool
	key_jump  bool
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_gnujump_engine()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn (mut app App) render() {
	renderer := &app.renderer
	set_render_draw_color(renderer, 15, 23, 42, 255)
	render_clear(renderer)

	render_tower_walls(renderer, win_width, win_height)

	for p in app.game.platforms {
		render_platform(renderer, p, int(app.game.cam_y), win_height)
	}

	render_jumper(renderer, app.game.p1, int(app.game.cam_y), win_height, true)

	render_lava(renderer, app.game.lava_y, int(app.game.cam_y), win_width, win_height)

	draw_text(renderer, 20, 20, 'SCORE: ${app.game.score_p1}', 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	draw_text(renderer, win_width - 180, 20, 'HIGH: ${app.game.high_score}', 2, Color{ r: 255, g: 215, b: 0, a: 255 })

	if app.game.mode == .menu {
		draw_glass_card(renderer, win_width / 2 - 150, win_height / 2 - 80, 300, 160, Color{ r: 59, g: 130, b: 246, a: 255 })
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 50, 'GNU JUMP', 4, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 10, 'PRESS SPACE TO JUMP', 2, Color{ r: 200, g: 220, b: 255, a: 255 })
	} else if app.game.mode == .game_over {
		draw_glass_card(renderer, win_width / 2 - 150, win_height / 2 - 80, 300, 160, Color{ r: 239, g: 68, b: 68, a: 255 })
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 50, 'GAME OVER', 4, Color{ r: 255, g: 80, b: 80, a: 255 })
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 10, 'PRESS [R] TO RETRY', 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	if app.game.mode == .playing {
		app.game.update_step(app.key_left, app.key_right, app.key_jump, false, false, false)
	}
	app.sound_mgr.update()

	app.render()
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
				.r {
					app.game.start_game()
				}
				.m, .o {
					app.sound_mgr.toggle_sound()
				}
				.left, .a {
					app.key_left = true
				}
				.right, .d {
					app.key_right = true
				}
				.space, .up, .w {
					if app.game.mode == .menu {
						app.game.start_game()
					} else if app.game.mode == .game_over {
						app.game.start_game()
					} else {
						app.key_jump = true
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
				.space, .up, .w {
					app.key_jump = false
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
		width:        win_width
		height:       win_height
		window_title: 'GnuJump (XJump Clone)'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 15, g: 23, b: 42, a: 255}
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
    write_file('gnujump', code)

if __name__ == '__main__':
    gen_fire()
    gen_flappy()
    gen_game2048()
    gen_goldminer()
    gen_jezzball()
    gen_downwell()
    gen_duke()
    gen_etchasketch()
    gen_dopewars()
    gen_lemmings()
    gen_klax()
    gen_gnujump()
    print("Batch 2 remaining games written!")
