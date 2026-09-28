module main

import gg
import math
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
				mx := int(e.mouse_x)
				my := int(e.mouse_y)

				// Sound toggle badge
				sound_x := win_w - 140
				if mx >= sound_x && mx <= sound_x + 120 && my >= 10 && my <= 36 {
					app.sound_mgr.toggle_sound()
					return
				}

				panel_y := win_h - 80
				if my >= panel_y {
					skills := [
						Skill.climber,
						Skill.floater,
						Skill.bomber,
						Skill.blocker,
						Skill.builder,
						Skill.basher,
						Skill.miner,
						Skill.digger,
					]
					mut sx := 20
					mut clicked_skill := false
					for s in skills {
						if mx >= sx && mx <= sx + 72 {
							app.game.selected_skill = s
							clicked_skill = true
							break
						}
						sx += 76
					}
					if clicked_skill {
						return
					}

					// Pause
					if mx >= sx + 8 && mx <= sx + 78 {
						app.game.is_paused = !app.game.is_paused
						return
					}
					// Speed
					if mx >= sx + 84 && mx <= sx + 149 {
						app.game.game_speed = if app.game.game_speed >= 4.0 { 1.0 } else { app.game.game_speed * 2.0 }
						return
					}
					// Nuke
					if mx >= sx + 155 && mx <= sx + 235 {
						app.game.trigger_nuke()
						return
					}
				} else if my >= 40 && my < panel_y {
					// Assign Skill to closest clicked Lemming
					scale := 2
					mut closest_lem := -1
					mut min_dist := 35.0
					for i, lem in app.game.lemmings {
						if lem.state != .dead && lem.state != .exiting {
							lx := f64(int(lem.x) * scale)
							ly := f64(40 + int(lem.y) * scale)
							dist := math.sqrt(f64((mx - int(lx)) * (mx - int(lx)) + (my - int(ly)) * (my - int(ly))))
							if dist < min_dist {
								min_dist = dist
								closest_lem = i
							}
						}
					}
					if closest_lem >= 0 {
						app.game.assign_skill(closest_lem)
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
				.p, .space {
					app.game.is_paused = !app.game.is_paused
				}
				.n {
					app.game.trigger_nuke()
				}
				.r {
					app.game.load_level(app.game.level_idx)
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
		window_title: 'Lemmings (1991 Psygnosis Classic Recreation)'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:       ctx
		width:     win_w
		height:    win_h
		logical_w: win_w
		logical_h: win_h
	}
	ctx.run()
}
