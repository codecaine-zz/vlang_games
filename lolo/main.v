module main

import gg
import time

struct App {
mut:
	ctx              &gg.Context = unsafe { nil }
	renderer         Renderer
	game             Game
	sound_mgr        SoundManager
	btn_ghost        Button
	btn_undo         Button
	btn_restart      Button
	btn_prev         Button
	btn_next         Button
	btn_level_select Button
	btn_map          Button
	btn_manual       Button
	btn_editor       Button
	btn_sound        Button
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
		btn_ghost:        Button{ x: 735, y: 120, w: 190, h: 36, text: 'GHOST GUIDE [H]', bg_color: Color{ r: 12, g: 35, b: 50 }, hover_color: Color{ r: 0, g: 180, b: 220 }, text_color: Color{ r: 0, g: 240, b: 255 }, border_color: Color{ r: 0, g: 240, b: 255 } }
		btn_undo:         Button{ x: 735, y: 165, w: 190, h: 36, text: 'REWIND [Z]', bg_color: Color{ r: 18, g: 28, b: 46 }, hover_color: Color{ r: 35, g: 55, b: 90 }, text_color: Color{ r: 200, g: 220, b: 255 }, border_color: Color{ r: 0, g: 200, b: 255 } }
		btn_restart:      Button{ x: 735, y: 210, w: 190, h: 36, text: 'RESET [R]', bg_color: Color{ r: 18, g: 28, b: 46 }, hover_color: Color{ r: 35, g: 55, b: 90 }, text_color: Color{ r: 200, g: 220, b: 255 }, border_color: Color{ r: 0, g: 200, b: 255 } }
		btn_prev:         Button{ x: 735, y: 255, w: 90, h: 36, text: '< PREV', bg_color: Color{ r: 18, g: 28, b: 46 }, hover_color: Color{ r: 35, g: 55, b: 90 }, text_color: Color{ r: 200, g: 220, b: 255 }, border_color: Color{ r: 0, g: 200, b: 255 } }
		btn_next:         Button{ x: 835, y: 255, w: 90, h: 36, text: 'NEXT >', bg_color: Color{ r: 18, g: 28, b: 46 }, hover_color: Color{ r: 35, g: 55, b: 90 }, text_color: Color{ r: 200, g: 220, b: 255 }, border_color: Color{ r: 0, g: 200, b: 255 } }
		btn_level_select: Button{ x: 735, y: 300, w: 190, h: 36, text: 'CHAMBERS [L]', bg_color: Color{ r: 18, g: 28, b: 46 }, hover_color: Color{ r: 35, g: 55, b: 90 }, text_color: Color{ r: 255, g: 215, b: 0 }, border_color: Color{ r: 255, g: 215, b: 0 } }
		btn_map:          Button{ x: 735, y: 345, w: 190, h: 36, text: 'SECTORS [M]', bg_color: Color{ r: 18, g: 28, b: 46 }, hover_color: Color{ r: 35, g: 55, b: 90 }, text_color: Color{ r: 0, g: 255, b: 150 }, border_color: Color{ r: 0, g: 255, b: 150 } }
		btn_manual:       Button{ x: 735, y: 390, w: 190, h: 36, text: 'DOSSIER [F1]', bg_color: Color{ r: 18, g: 28, b: 46 }, hover_color: Color{ r: 35, g: 55, b: 90 }, text_color: Color{ r: 255, g: 140, b: 60 }, border_color: Color{ r: 255, g: 140, b: 60 } }
		btn_editor:       Button{ x: 735, y: 435, w: 190, h: 36, text: 'ARCHITECT [TAB]', bg_color: Color{ r: 18, g: 28, b: 46 }, hover_color: Color{ r: 35, g: 55, b: 90 }, text_color: Color{ r: 255, g: 0, b: 127 }, border_color: Color{ r: 255, g: 0, b: 127 } }
		btn_sound:        Button{ x: 735, y: 480, w: 190, h: 36, text: 'AUDIO: ON [S]', bg_color: Color{ r: 18, g: 28, b: 46 }, hover_color: Color{ r: 35, g: 55, b: 90 }, text_color: Color{ r: 160, g: 240, b: 255 }, border_color: Color{ r: 100, g: 180, b: 240 } }
		btn_test:         Button{ x: 735, y: 525, w: 90, h: 36, text: 'TEST', bg_color: Color{ r: 18, g: 28, b: 46 }, hover_color: Color{ r: 35, g: 55, b: 90 }, text_color: Color{ r: 200, g: 220, b: 255 }, border_color: Color{ r: 0, g: 200, b: 255 } }
		btn_clear:        Button{ x: 835, y: 525, w: 90, h: 36, text: 'CLEAR', bg_color: Color{ r: 18, g: 28, b: 46 }, hover_color: Color{ r: 35, g: 55, b: 90 }, text_color: Color{ r: 200, g: 220, b: 255 }, border_color: Color{ r: 0, g: 200, b: 255 } }
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

	app.game.update(f64(dt))
	app.sound_mgr.update()

	// Drain sound event queue from game
	for ev in app.game.sound_event_queue {
		match ev {
			'step' { app.sound_mgr.play_step() }
			'heart' { app.sound_mgr.play_heart() }
			'shot' { app.sound_mgr.play_shot() }
			'egg' { app.sound_mgr.play_egg() }
			'push' { app.sound_mgr.play_push() }
			'chest' { app.sound_mgr.play_chest() }
			'door' { app.sound_mgr.play_key() }
			'victory' { app.sound_mgr.play_victory() }
			'death' { app.sound_mgr.play_spike() }
			'warp' { app.sound_mgr.play_warp() }
			'slide' { app.sound_mgr.play_slide() }
			'bomb' { app.sound_mgr.play_bomb() }
			'dry_fire' { app.sound_mgr.play_dry_fire() }
			'plate' { app.sound_mgr.play_plate() }
			'powerup' { app.sound_mgr.play_powerup() }
			else {}
		}
	}
	app.game.sound_event_queue.clear()

	draw_game(
		&app.renderer,
		app.game,
		app.mouse_x,
		app.mouse_y,
		app.btn_editor,
		app.btn_restart,
		app.btn_sound,
		app.btn_prev,
		app.btn_next,
		app.btn_test,
		app.btn_clear,
		app.btn_undo,
		app.btn_level_select,
		app.btn_ghost,
		app.btn_map,
		app.btn_manual
	)
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

				// Check modal clicks first
				if app.game.level_selector_open {
					start_idx := app.game.level_selector_page * 25
					end_idx := math_min(start_idx + 25, app.game.campaign_levels.len)
					for i in start_idx .. end_idx {
						rel_idx := i - start_idx
						col := rel_idx % 5
						row := rel_idx / 5
						bx := 90 + col * 150
						by := 130 + row * 85
						if mx >= bx && mx <= bx + 135 && my >= by && my <= by + 72 {
							if i <= app.game.save_data.max_level_unlocked {
								app.game.load_level(i)
								app.game.level_selector_open = false
							}
							return
						}
					}
					// Next page button click or close
					if my >= 580 {
						app.game.level_selector_page = (app.game.level_selector_page + 1) % 4
						return
					}
					app.game.level_selector_open = false
					return
				}

				if app.game.sector_map_open {
					for s in 0 .. 10 {
						sy := 140 + s * 45
						if mx >= 120 && mx <= 840 && my >= sy && my <= sy + 36 {
							lvl_idx := s * 10
							if lvl_idx <= app.game.save_data.max_level_unlocked {
								app.game.load_level(lvl_idx)
								app.game.sector_map_open = false
							}
							return
						}
					}
					app.game.sector_map_open = false
					return
				}

				if app.game.field_manual_open {
					app.game.field_manual_open = false
					return
				}

				// Check Sidebar Buttons
				if app.btn_ghost.contains(mx, my) {
					app.game.toggle_ghost_guide()
				} else if app.btn_undo.contains(mx, my) {
					app.game.undo()
				} else if app.btn_restart.contains(mx, my) {
					app.game.restart_level()
				} else if app.btn_prev.contains(mx, my) {
					app.game.prev_level()
				} else if app.btn_next.contains(mx, my) {
					app.game.next_level()
				} else if app.btn_level_select.contains(mx, my) {
					app.game.toggle_level_selector()
				} else if app.btn_map.contains(mx, my) {
					app.game.toggle_sector_map()
				} else if app.btn_manual.contains(mx, my) {
					app.game.toggle_field_manual()
				} else if app.btn_editor.contains(mx, my) {
					app.game.toggle_editor_mode()
				} else if app.btn_sound.contains(mx, my) {
					app.sound_mgr.toggle_sound()
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
					if app.game.level_selector_open || app.game.sector_map_open || app.game.field_manual_open {
						app.game.close_all_overlays()
					} else {
						exit(0)
					}
				}
				.tab { app.game.toggle_editor_mode() }
				.h { app.game.toggle_ghost_guide() }
				.l { app.game.toggle_level_selector() }
				.m { app.game.toggle_sector_map() }
				.f1 { app.game.toggle_field_manual() }
				.s { app.sound_mgr.toggle_sound() }
				.u, .z { app.game.undo() }
				.r { app.game.restart_level() }
				.up, .w { app.game.move_lolo(.up) }
				.down { app.game.move_lolo(.down) }
				.left, .a { app.game.move_lolo(.left) }
				.right, .d { app.game.move_lolo(.right) }
				.space, .x {
					if app.game.status == .stage_cleared {
						app.game.next_level()
					} else {
						app.game.fire_magic_shot()
					}
				}
				.b {
					app.sound_mgr.toggle_music()
				}
				.p, .left_bracket { app.game.prev_level() }
				.n, .right_bracket { app.game.next_level() }
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
		window_title: 'Adventures of Lolo - Cyberpunk Remaster'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 5, g: 8, b: 16, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
