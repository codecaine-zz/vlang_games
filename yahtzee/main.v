module main

import gg
import math
import time

const win_w = 920
const win_h = 660

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      YahtzeeGame
	sound_mgr SoundManager
	tex_mgr   YahtzeeTextureManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_yahtzee_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   YahtzeeTextureManager{}
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

	app.game.update(dt)

	if app.game.sound_event != '' {
		ev := app.game.sound_event
		app.game.sound_event = ''
		match ev {
			'clatter' { app.sound_mgr.play_dice_clatter() }
			'yahtzee' { app.sound_mgr.play_yahtzee_fanfare() }
			'bonus' { app.sound_mgr.play_bonus_fanfare() }
			'score' { app.sound_mgr.play_score_recorded() }
			'win' { app.sound_mgr.play_bonus_fanfare() }
			else {}
		}
	}

	render_yahtzee_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.sound_mgr.enabled, app.tex_mgr.sprite_texture)
	app.sound_mgr.update()
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
			app.mouse_x = mx
			app.mouse_y = my

			// 1. Check Top Sound Toggle Button
			sound_x := win_w - 145
			if mx >= sound_x && mx <= sound_x + 125 && my >= 12 && my <= 38 {
				app.sound_mgr.toggle_sound()
			}

			// 2. Check Mode Selector Tabs
			for i in 0 .. 3 {
				tab_x := 460 + i * 90
				if mx >= tab_x && mx <= tab_x + 80 && my >= 12 && my <= 38 {
					app.game.mode = match i {
						0 { GameMode.solo }
						1 { GameMode.vs_ai }
						else { GameMode.two_player }
					}
					app.game.reset_game()
					app.sound_mgr.play_score_recorded()
				}
			}

			// 3. Check Dice Clicks (Toggle Hold)
			for i, d in app.game.dice {
				half := 32
				dx := int(d.x)
				dy := int(d.y)
				if mx >= dx - half && mx <= dx + half && my >= dy - half && my <= dy + half {
					app.game.toggle_hold(i)
					app.sound_mgr.play_dice_toggle(app.game.dice[i].held)
				}
			}

			// 4. Check Big ROLL DICE Button
			btn_x := 30 + 50
			btn_y := 70 + 570 - 85
			btn_w := 460 - 100
			btn_h := 55
			if mx >= btn_x && mx <= btn_x + btn_w && my >= btn_y && my <= btn_y + btn_h {
				if app.game.roll_dice() {
					app.sound_mgr.play_cup_shake()
				}
			}

			// 5. Check Scorecard Category Clicks
			score_x := 510
			score_y := 70
			score_w := 380
			row_h := 24

			// Upper categories
			mut cur_y := score_y + 30 + 18
			upper_cats := [Category.ones, .twos, .threes, .fours, .fives, .sixes]
			for cat in upper_cats {
				if mx >= score_x && mx <= score_x + score_w && my >= cur_y && my <= cur_y + row_h {
					if app.game.choose_category(cat) {
						app.sound_mgr.play_score_recorded()
					}
				}
				cur_y += row_h
			}

			// Lower categories
			cur_y += row_h * 2 + 4 + 18
			lower_cats := [
				Category.three_of_kind,
				.four_of_kind,
				.full_house,
				.small_straight,
				.large_straight,
				.yahtzee,
				.chance,
			]
			for cat in lower_cats {
				if mx >= score_x && mx <= score_x + score_w && my >= cur_y && my <= cur_y + row_h {
					if app.game.choose_category(cat) {
						app.sound_mgr.play_score_recorded()
					}
				}
				cur_y += row_h
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
				.escape {
					exit(0)
				}
				.space {
					if app.game.roll_dice() {
						app.sound_mgr.play_cup_shake()
					}
				}
				._1 {
					app.game.toggle_hold(0)
					app.sound_mgr.play_dice_toggle(app.game.dice[0].held)
				}
				._2 {
					app.game.toggle_hold(1)
					app.sound_mgr.play_dice_toggle(app.game.dice[1].held)
				}
				._3 {
					app.game.toggle_hold(2)
					app.sound_mgr.play_dice_toggle(app.game.dice[2].held)
				}
				._4 {
					app.game.toggle_hold(3)
					app.sound_mgr.play_dice_toggle(app.game.dice[3].held)
				}
				._5 {
					app.game.toggle_hold(4)
					app.sound_mgr.play_dice_toggle(app.game.dice[4].held)
				}
				.r {
					app.game.reset_game()
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
		width:         win_w
		height:        win_h
		resizable:     true
		window_title:  'Yahtzee Deluxe - 16-Bit Casino Dice Game'
		user_data:     &app
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 18, g: 38, b: 28, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx: ctx
	}
	app.tex_mgr.init(&app.renderer)
	ctx.run()
}
