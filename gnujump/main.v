module main

import gg
import math
import rand
import time

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        GNUJumpEngine
	sound_mgr   SoundManager
	tex_mgr     GNUJumpTextureManager
	particles   []Particle
	mouse_x     int
	mouse_y     int
	p1_left     bool
	p1_right    bool
	p1_up       bool
	p2_left     bool
	p2_right    bool
	p2_up       bool
	btn_1p      Button
	btn_2p      Button
	btn_start   Button
	btn_restart Button
	btn_sound   Button
	last_tick   i64
}

fn new_app() App {
	return App{
		game:        new_gnujump_engine()
		sound_mgr:   new_sound_manager()
		tex_mgr:     new_gnujump_texture_manager()
		btn_1p:      Button{
			x:            210
			y:            300
			w:            180
			h:            110
			text:         '1P SOLO'
			bg_color:     Color{ r: 34, g: 211, b: 238, a: 255 }
			hover_color:  Color{ r: 103, g: 232, b: 249, a: 255 }
			text_color:   Color{ r: 15, g: 23, b: 42, a: 255 }
			border_color: Color{ r: 250, g: 204, b: 21, a: 255 }
		}
		btn_2p:      Button{
			x:            410
			y:            300
			w:            180
			h:            110
			text:         '2P VERSUS'
			bg_color:     Color{ r: 30, g: 41, b: 59, a: 255 }
			hover_color:  Color{ r: 51, g: 65, b: 85, a: 255 }
			text_color:   Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 71, g: 85, b: 105, a: 255 }
		}
		btn_start:   Button{
			x:            250
			y:            440
			w:            300
			h:            52
			text:         'START JUMPING'
			bg_color:     Color{ r: 59, g: 130, b: 246, a: 255 }
			hover_color:  Color{ r: 96, g: 165, b: 250, a: 255 }
			text_color:   Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 250, g: 204, b: 21, a: 255 }
		}
		btn_restart: Button{
			x:            250
			y:            480
			w:            300
			h:            48
			text:         'RESTART GAME [R]'
			bg_color:     Color{ r: 239, g: 68, b: 68, a: 255 }
			hover_color:  Color{ r: 248, g: 113, b: 113, a: 255 }
			text_color:   Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 250, g: 204, b: 21, a: 255 }
		}
		btn_sound:   Button{
			x:            630
			y:            10
			w:            150
			h:            36
			text:         'SOUND: ON [O]'
			bg_color:     Color{ r: 30, g: 41, b: 59, a: 255 }
			hover_color:  Color{ r: 51, g: 65, b: 85, a: 255 }
			text_color:   Color{ r: 80, g: 240, b: 140, a: 255 }
			border_color: Color{ r: 71, g: 85, b: 105, a: 255 }
		}
		last_tick:   time.ticks()
	}
}

fn (mut app App) spawn_particles(cx f64, cy f64, color Color, count int) {
	for _ in 0 .. count {
		angle := rand.f64() * 6.28
		speed := 1.5 + rand.f64() * 4.0
		app.particles << Particle{
			x:     cx
			y:     cy
			vx:    math.cos(angle) * speed
			vy:    math.sin(angle) * speed
			life:  1.0
			color: color
			size:  3 + rand.intn(3) or { 3 }
		}
	}
}

fn (mut app App) update_particles() {
	for i := app.particles.len - 1; i >= 0; i-- {
		app.particles[i].x += app.particles[i].vx
		app.particles[i].y += app.particles[i].vy
		app.particles[i].life -= 0.03
		if app.particles[i].life <= 0 {
			app.particles.delete(i)
		}
	}
}

fn (mut app App) toggle_mode() {
	app.sound_mgr.play_click_sound()
	if app.game.game_mode == .solo {
		app.game.game_mode = .pvp
		app.btn_1p.bg_color = Color{ r: 30, g: 41, b: 59, a: 255 }
		app.btn_1p.text_color = Color{ r: 255, g: 255, b: 255, a: 255 }
		app.btn_2p.bg_color = Color{ r: 245, g: 158, b: 11, a: 255 }
		app.btn_2p.text_color = Color{ r: 15, g: 23, b: 42, a: 255 }
	} else {
		app.game.game_mode = .solo
		app.btn_1p.bg_color = Color{ r: 34, g: 211, b: 238, a: 255 }
		app.btn_1p.text_color = Color{ r: 15, g: 23, b: 42, a: 255 }
		app.btn_2p.bg_color = Color{ r: 30, g: 41, b: 59, a: 255 }
		app.btn_2p.text_color = Color{ r: 255, g: 255, b: 255, a: 255 }
	}
}

fn (mut app App) handle_mouse_click(x int, y int) {
	if app.btn_sound.is_hovered(x, y) {
		is_on := app.sound_mgr.toggle_sound()
		app.btn_sound.text = if is_on { 'SOUND: ON [O]' } else { 'SOUND: OFF [O]' }
		app.btn_sound.text_color = if is_on {
			Color{ r: 80, g: 240, b: 140, a: 255 }
		} else {
			Color{ r: 240, g: 90, b: 90, a: 255 }
		}
		return
	}

	if app.game.mode == .menu {
		if app.btn_1p.is_hovered(x, y) || app.btn_2p.is_hovered(x, y) {
			app.toggle_mode()
		} else if app.btn_start.is_hovered(x, y) {
			app.sound_mgr.play_click_sound()
			app.game.start_game()
		}
	} else if app.game.mode == .game_over {
		if app.btn_restart.is_hovered(x, y) {
			app.sound_mgr.play_click_sound()
			app.game.start_game()
		}
	}
}

fn (mut app App) render() {
	renderer := &app.renderer
	ticks := u32(time.ticks())
	set_render_draw_color(renderer, 15, 23, 42, 255)
	render_clear(renderer)

	render_tower_walls(renderer, ticks)

	if app.game.mode == .playing {
		// Render Platforms
		for p in app.game.platforms {
			render_platform(renderer, p, ticks, app.tex_mgr.sprite_texture)
		}

		// Render Lava Surface
		render_lava(renderer, app.game.lava_y, ticks, app.tex_mgr.sprite_texture)

		// Render Jumpers
		render_jumper(renderer, app.game.p1, app.tex_mgr.sprite_texture, false)
		if app.game.game_mode == .pvp {
			render_jumper(renderer, app.game.p2, app.tex_mgr.sprite_texture, true)
		}
	}

	// Render Particles
	for p in app.particles {
		draw_filled_circle(renderer, int(p.x), int(p.y), p.size, Color{
			r: p.color.r
			g: p.color.g
			b: p.color.b
			a: u8(p.life * 255.0)
		})
	}

	// Top Glassmorphic HUD Card
	draw_glass_card(renderer, 0, 0, win_width, 56, Color{ r: 59, g: 130, b: 246, a: 255 })
	draw_text(renderer, 20, 16, 'GNUJUMP', 3, Color{ r: 96, g: 165, b: 250, a: 255 })

	if app.game.game_mode == .solo {
		draw_text(renderer, 200, 18, 'SCORE: ${app.game.score_p1}', 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text(renderer, 420, 18, 'LIVES: ${app.game.p1.lives}', 2, Color{ r: 239, g: 68, b: 68, a: 255 })
	} else {
		// 2P Local Versus Split HUD
		draw_text(renderer, 180, 10, 'P1 CYAN: ${app.game.score_p1} L:${app.game.p1.lives}', 2, Color{ r: 34, g: 211, b: 238, a: 255 })
		draw_text(renderer, 180, 32, 'P2 AMBER: ${app.game.score_p2} L:${app.game.p2.lives}', 2, Color{ r: 245, g: 158, b: 11, a: 255 })

		leader_text := if app.game.score_p1 > app.game.score_p2 {
			'P1 LEAD'
		} else if app.game.score_p2 > app.game.score_p1 {
			'P2 LEAD'
		} else {
			'TIED!'
		}
		leader_color := if app.game.score_p1 > app.game.score_p2 {
			Color{ r: 34, g: 211, b: 238, a: 255 }
		} else if app.game.score_p2 > app.game.score_p1 {
			Color{ r: 245, g: 158, b: 11, a: 255 }
		} else {
			Color{ r: 250, g: 204, b: 21, a: 255 }
		}
		draw_text(renderer, 480, 18, leader_text, 2, leader_color)
	}

	app.btn_sound.draw(renderer, app.mouse_x, app.mouse_y)

	// Menu Overlay
	if app.game.mode == .menu {
		draw_glass_card(renderer, 160, 120, 480, 440, Color{ r: 59, g: 130, b: 246, a: 255 })
		draw_text_centered(renderer, win_width / 2, 145, 'GNUJUMP TOWER', 3, Color{ r: 96, g: 165, b: 250, a: 255 })
		draw_text_centered(renderer, win_width / 2, 185, 'VERTICAL SURVIVAL', 2, Color{ r: 250, g: 204, b: 21, a: 255 })

		draw_text_centered(renderer, win_width / 2, 235, 'HIGH RECORD: ${app.game.high_score}', 2, Color{ r: 148, g: 163, b: 184, a: 255 })
		draw_text_centered(renderer, win_width / 2, 275, 'SELECT GAME MODE [M]:', 2, Color{ r: 255, g: 255, b: 255, a: 255 })

		app.btn_1p.draw(renderer, app.mouse_x, app.mouse_y)
		draw_text_centered(renderer, 300, 340, 'CLIMB ALONE', 1, Color{ r: 15, g: 23, b: 42, a: 255 })
		status_1p := if app.game.game_mode == .solo { '[ SELECTED ]' } else { '[ CLICK TO SELECT ]' }
		draw_text_centered(renderer, 300, 375, status_1p, 1, Color{ r: 15, g: 23, b: 42, a: 255 })

		app.btn_2p.draw(renderer, app.mouse_x, app.mouse_y)
		draw_text_centered(renderer, 500, 340, 'TOWER RACE', 1, Color{ r: 255, g: 255, b: 255, a: 255 })
		status_2p := if app.game.game_mode == .pvp { '[ SELECTED ]' } else { '[ CLICK TO SELECT ]' }
		draw_text_centered(renderer, 500, 375, status_2p, 1, Color{ r: 250, g: 204, b: 21, a: 255 })

		app.btn_start.draw(renderer, app.mouse_x, app.mouse_y)

		ctrl_text := if app.game.game_mode == .solo {
			'CONTROLS: ARROWS / WASD TO JUMP & STEER'
		} else {
			'CONTROLS: P1 = ARROWS | P2 = WASD'
		}
		draw_text_centered(renderer, win_width / 2, 520, ctrl_text, 1, Color{ r: 148, g: 163, b: 184, a: 255 })
	} else if app.game.mode == .game_over {
		draw_glass_card(renderer, 180, 160, 440, 410, Color{ r: 239, g: 68, b: 68, a: 255 })

		title_text := if app.game.game_mode == .pvp {
			if app.game.score_p1 > app.game.score_p2 {
				'P1 CYAN VICTORIOUS!'
			} else if app.game.score_p2 > app.game.score_p1 {
				'P2 AMBER VICTORIOUS!'
			} else {
				'STALEMATE TIE!'
			}
		} else {
			'TOWER FELL'
		}

		draw_text_centered(renderer, win_width / 2, 190, title_text, 3, Color{ r: 248, g: 113, b: 113, a: 255 })
		draw_text_centered(renderer, win_width / 2, 235, 'CONSUMED BY LAVA', 2, Color{ r: 255, g: 255, b: 255, a: 255 })

		draw_text_centered(renderer, win_width / 2, 300, 'P1 SCORE: ${app.game.score_p1}', 2, Color{ r: 34, g: 211, b: 238, a: 255 })
		if app.game.game_mode == .pvp {
			draw_text_centered(renderer, win_width / 2, 340, 'P2 SCORE: ${app.game.score_p2}', 2, Color{ r: 245, g: 158, b: 11, a: 255 })
		}
		draw_text_centered(renderer, win_width / 2, 390, 'HIGH RECORD: ${app.game.high_score}', 2, Color{ r: 250, g: 204, b: 21, a: 255 })

		app.btn_restart.draw(renderer, app.mouse_x, app.mouse_y)
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	jumped, landed, springed, broken, combo := app.game.update_step(app.p1_left, app.p1_right,
		app.p1_up, app.p2_left, app.p2_right, app.p2_up)

	if jumped {
		app.sound_mgr.play_jump_sound()
	}
	if landed {
		app.sound_mgr.play_land_sound()
	}
	if springed {
		app.sound_mgr.play_spring_sound()
	}
	if broken {
		app.sound_mgr.play_crumbly_sound()
	}
	if combo {
		app.sound_mgr.play_combo_sound()
		app.spawn_particles(app.game.p1.x, app.game.p1.y, Color{ r: 250, g: 204, b: 21, a: 255 }, 15)
	}

	app.update_particles()
	app.sound_mgr.update()

	app.render()
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
				app.handle_mouse_click(int(e.mouse_x), int(e.mouse_y))
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
				.r {
					if app.game.mode == .game_over {
						app.sound_mgr.play_click_sound()
						app.game.start_game()
					}
				}
				.m {
					if app.game.mode == .menu {
						app.toggle_mode()
					}
				}
				.o {
					is_on := app.sound_mgr.toggle_sound()
					app.btn_sound.text = if is_on { 'SOUND: ON [O]' } else { 'SOUND: OFF [O]' }
					app.btn_sound.text_color = if is_on {
						Color{ r: 80, g: 240, b: 140, a: 255 }
					} else {
						Color{ r: 240, g: 90, b: 90, a: 255 }
					}
				}
				.left {
					app.p1_left = true
				}
				.right {
					app.p1_right = true
				}
				.up, .space {
					app.p1_up = true
				}
				.a {
					if app.game.game_mode == .pvp {
						app.p2_left = true
					} else {
						app.p1_left = true
					}
				}
				.d {
					if app.game.game_mode == .pvp {
						app.p2_right = true
					} else {
						app.p1_right = true
					}
				}
				.w {
					if app.game.game_mode == .pvp {
						app.p2_up = true
					} else {
						app.p1_up = true
					}
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.left {
					app.p1_left = false
				}
				.right {
					app.p1_right = false
				}
				.up, .space {
					app.p1_up = false
				}
				.a {
					if app.game.game_mode == .pvp {
						app.p2_left = false
					} else {
						app.p1_left = false
					}
				}
				.d {
					if app.game.game_mode == .pvp {
						app.p2_right = false
					} else {
						app.p1_right = false
					}
				}
				.w {
					if app.game.game_mode == .pvp {
						app.p2_up = false
					} else {
						app.p1_up = false
					}
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
		resizable:     true
		window_title: 'GNUjump - Vertical Tower Survival'
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
	app.tex_mgr.init(&app.renderer)
	ctx.run()
}
