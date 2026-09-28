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

# 1. Update pinball
p_pinball = os.path.join(DST, 'pinball', 'main.v')
with open(p_pinball) as f:
    c = f.read()
c = c.replace('.r { app.game.reset_game() }', '.r { app.game.start_game(app.game.mode) }')
with open(p_pinball, 'w') as f:
    f.write(c)
print("Updated pinball")

# 2. Update pool
p_pool = os.path.join(DST, 'pool', 'main.v')
with open(p_pool) as f:
    c = f.read()
c = c.replace('app.game.cue_angle = math.atan2', 'app.game.aim_angle = math.atan2')
with open(p_pool, 'w') as f:
    f.write(c)
print("Updated pool")

# 3. racer: add Button definition
btn_code = '''struct Button {
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

fn (b &Button) contains(px int, py int) bool {
	return px >= b.x && px <= b.x + b.w && py >= b.y && py <= b.y + b.h
}

fn (b &Button) draw(renderer &Renderer, mouse_x int, mouse_y int) {
	is_hover := b.contains(mouse_x, mouse_y)
	c := if is_hover { b.hover_color } else { b.bg_color }
	rect := Rect{ x: b.x, y: b.y, w: b.w, h: b.h }
	set_render_draw_color(renderer, c.r, c.g, c.b, 255)
	render_fill_rect(renderer, &rect)
	set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, 255)
	render_draw_rect(renderer, &rect)
	draw_text_centered(renderer, b.x + b.w / 2, b.y + (b.h - 8) / 2, b.text, 1, b.text_color)
}
'''
for g in ['racer', 'ragdoll', 'rain']:
    p = os.path.join(DST, g, 'main.v')
    with open(p) as f:
        c = f.read()
    c = c.replace('struct App {', btn_code + '\nstruct App {')
    with open(p, 'w') as f:
        f.write(c)
    print(f"Added Button to {g}")

# 4. scorchedearth
def gen_scorchedearth_full():
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
	game      ScorchedGame
	sound_mgr SoundManager
	key_left  bool
	key_right bool
	key_up    bool
	key_down  bool
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

	if !app.game.in_shop && !app.game.is_game_over {
		if app.game.current_turn < app.game.tanks.len {
			mut cur_t := app.game.tanks[app.game.current_turn]
			if !cur_t.is_ai && cur_t.is_alive && !app.game.projectile_active {
				if app.key_left {
					cur_t.angle = math.min(180.0, cur_t.angle + 35.0 * f64(dt))
				}
				if app.key_right {
					cur_t.angle = math.max(0.0, cur_t.angle - 35.0 * f64(dt))
				}
				if app.key_up {
					cur_t.power = math.min(1000.0, cur_t.power + 250.0 * f64(dt))
				}
				if app.key_down {
					cur_t.power = math.max(50.0, cur_t.power - 250.0 * f64(dt))
				}
				app.game.tanks[app.game.current_turn] = cur_t
			}
		}
	}

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
				sound_x := win_w - 110
				if mx >= sound_x && mx <= sound_x + 95 && my >= 8 && my <= 32 {
					app.sound_mgr.toggle_sound()
				} else if app.game.in_shop {
					weps := [
						WeaponType.baby_nuke,
						WeaponType.mirv,
						WeaponType.mountain_mover,
						WeaponType.napalm,
						WeaponType.digger,
					]
					mut row_y := 160
					for w in weps {
						if mx >= 110 && mx <= win_w - 110 && my >= row_y && my <= row_y + 48 {
							app.game.buy_weapon(w)
							break
						}
						row_y += 58
					}
					if my >= win_h - 120 && my <= win_h - 70 && mx >= win_w / 2 - 200 && mx <= win_w / 2 + 200 {
						app.game.start_next_round()
					}
				} else if !app.game.is_game_over {
					if my >= win_h - 55 {
						if mx >= win_w - 220 {
							app.game.fire_shot()
						} else if mx >= 330 && mx <= win_w - 230 {
							app.game.cycle_weapon(true)
						}
					}
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.left, .a { app.key_left = true }
				.right, .d { app.key_right = true }
				.up, .w { app.key_up = true }
				.down, .s { app.key_down = true }
				.space, .enter {
					if app.game.in_shop {
						app.game.start_next_round()
					} else {
						app.game.fire_shot()
					}
				}
				.tab { app.game.cycle_weapon(true) }
				._1 {
					if app.game.in_shop { app.game.buy_weapon(.baby_nuke) }
					else { app.game.select_weapon(.standard) }
				}
				._2 {
					if app.game.in_shop { app.game.buy_weapon(.mirv) }
					else { app.game.select_weapon(.baby_nuke) }
				}
				._3 {
					if app.game.in_shop { app.game.buy_weapon(.mountain_mover) }
					else { app.game.select_weapon(.mirv) }
				}
				._4 {
					if app.game.in_shop { app.game.buy_weapon(.napalm) }
					else { app.game.select_weapon(.mountain_mover) }
				}
				._5 {
					if app.game.in_shop { app.game.buy_weapon(.digger) }
					else { app.game.select_weapon(.napalm) }
				}
				.m { app.sound_mgr.toggle_sound() }
				.r { app.game.init_match() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.left, .a { app.key_left = false }
				.right, .d { app.key_right = false }
				.up, .w { app.key_up = false }
				.down, .s { app.key_down = false }
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

gen_scorchedearth_full()
