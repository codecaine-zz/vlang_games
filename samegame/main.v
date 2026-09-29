module main

import math
import rand
import gg
import time

const win_width = 880
const win_height = 840

const cell_size = 44
const grid_w = sg_cols * cell_size
const grid_h = sg_rows * cell_size

const board_x = 240
const board_y = 110

struct GemParticle {
mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	max_l f64
	color Color
	size  int
	rot   f64
	vrot  f64
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
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	last_tick i64
	mouse_x   int
	mouse_y   int
	sound_mgr   SoundManager
	game        SameGame
	particles   []GemParticle
	float_texts []FloatText
	shake_timer f64
	paused      bool
	btn_reset   Button
	btn_sound   Button
	btn_mode    Button
}

fn new_app() App {
	btn_y := 770
	return App{
		last_tick: time.ticks()
		sound_mgr: new_sound_manager()
		game:      new_same_game(.puzzle)
		btn_reset: Button{
			x: 40, y: btn_y, w: 160, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 45, g: 30, b: 50},
			hover_color: Color{r: 75, g: 45, b: 85},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 160, g: 80, b: 180},
		}
		btn_sound: Button{
			x: 220, y: btn_y, w: 160, h: 42, text: 'SOUND [M]',
			bg_color: Color{r: 30, g: 45, b: 55},
			hover_color: Color{r: 50, g: 75, b: 95},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 140, b: 170},
		}
		btn_mode:  Button{
			x: 400, y: btn_y, w: 160, h: 42, text: 'MODE [T]',
			bg_color: Color{r: 45, g: 45, b: 30},
			hover_color: Color{r: 75, g: 75, b: 45},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 160, g: 160, b: 70},
		}
	}
}

fn get_sg_colors(color_id int) (Color, Color, Color, Color) {
	match color_id {
		1 { // Ruby Red
			return Color{r: 240, g: 40, b: 60}, Color{r: 255, g: 140, b: 155}, Color{r: 145, g: 15, b: 25}, Color{r: 255, g: 230, b: 240}
		}
		2 { // Sapphire Blue
			return Color{r: 35, g: 135, b: 250}, Color{r: 125, g: 205, b: 255}, Color{r: 15, g: 70, b: 170}, Color{r: 215, g: 240, b: 255}
		}
		3 { // Emerald Green
			return Color{r: 35, g: 215, b: 85}, Color{r: 130, g: 255, b: 160}, Color{r: 15, g: 125, b: 40}, Color{r: 220, g: 255, b: 230}
		}
		4 { // Topaz Yellow
			return Color{r: 250, g: 215, b: 30}, Color{r: 255, g: 245, b: 135}, Color{r: 160, g: 130, b: 15}, Color{r: 255, g: 255, b: 220}
		}
		5 { // Amethyst Purple
			return Color{r: 200, g: 45, b: 240}, Color{r: 240, g: 140, b: 255}, Color{r: 120, g: 20, b: 150}, Color{r: 250, g: 220, b: 255}
		}
		else {
			return Color{r: 80, g: 80, b: 90}, Color{r: 140, g: 140, b: 150}, Color{r: 40, g: 40, b: 50}, Color{r: 220, g: 220, b: 230}
		}
	}
}

// Draw a Crystal Tile Block
fn draw_sg_gem(renderer &Renderer, cx int, cy int, size int, color_id int, is_hovered bool, ticks u32) {
	if color_id == 0 {
		return
	}
	r := size / 2 - 2
	main_c, high_c, shadow_c, glint_c := get_sg_colors(color_id)

	rect := Rect{x: cx - r + 1, y: cy - r + 1, w: (r - 1) * 2, h: (r - 1) * 2}
	set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, 255)
	render_fill_rect(renderer, &rect)

	// Top & Left bevel highlight
	set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 255)
	for i in 0 .. 3 {
		render_draw_line(renderer, cx - r + 1 + i, cy - r + 1 + i, cx + r - 1 - i, cy - r + 1 + i)
		render_draw_line(renderer, cx - r + 1 + i, cy - r + 1 + i, cx - r + 1 + i, cy + r - 1 - i)
	}

	// Bottom & Right shadow
	set_render_draw_color(renderer, shadow_c.r, shadow_c.g, shadow_c.b, 255)
	for i in 0 .. 3 {
		render_draw_line(renderer, cx - r + 1 + i, cy + r - 1 - i, cx + r - 1 - i, cy + r - 1 - i)
		render_draw_line(renderer, cx + r - 1 - i, cy - r + 1 + i, cx + r - 1 - i, cy + r - 1 - i)
	}

	// Inner Glint Point
	set_render_draw_color(renderer, glint_c.r, glint_c.g, glint_c.b, 255)
	render_draw_point(renderer, cx - r / 2, cy - r / 2)
	render_draw_point(renderer, cx - r / 2 + 1, cy - r / 2)

	// Border
	set_render_draw_color(renderer, 15, 15, 25, 255)
	render_draw_rect(renderer, &rect)

	// Hover highlight aura
	if is_hovered {
		t := f64(ticks) * 0.01
		pulse := u8((math.sin(t * 3.0) * 0.5 + 0.5) * 180.0 + 75.0)
		set_render_draw_color(renderer, 255, 255, 255, pulse)
		h_rect := Rect{x: cx - r + 2, y: cy - r + 2, w: (r - 2) * 2, h: (r - 2) * 2}
		render_draw_rect(renderer, &h_rect)
	}
}

fn (mut app App) spawn_burst(cx int, cy int, color_id int) {
	main_c, _, _, _ := get_sg_colors(color_id)
	for _ in 0 .. 16 {
		ang := rand.f64_in_range(0.0, 2.0 * math.pi) or { 0.0 }
		spd := rand.f64_in_range(90.0, 300.0) or { 160.0 }
		life := rand.f64_in_range(0.35, 0.7) or { 0.5 }
		app.particles << GemParticle{
			x:     f64(cx)
			y:     f64(cy)
			vx:    math.cos(ang) * spd
			vy:    math.sin(ang) * spd
			life:  life
			max_l: life
			color: main_c
			size:  rand.int_in_range(3, 6) or { 4 }
			rot:   rand.f64_in_range(0.0, 6.28) or { 0.0 }
			vrot:  rand.f64_in_range(-8.0, 8.0) or { 4.0 }
		}
	}
}

fn (mut app App) get_cell_under_mouse(mx int, my int) (int, int) {
	if mx >= board_x && mx < board_x + grid_w && my >= board_y && my < board_y + grid_h {
		c := (mx - board_x) / cell_size
		r := (my - board_y) / cell_size
		return r, c
	}
	return -1, -1
}

fn (mut app App) update(dt f64) {
	if app.paused {
		return
	}

	if app.shake_timer > 0 {
		app.shake_timer -= dt
	}

	app.game.update(dt)

	// Update Particles
	mut active_particles := []GemParticle{}
	for mut p in app.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 380.0 * dt
		p.vx *= 0.985
		p.rot += p.vrot * dt
		p.life -= dt
		if p.life > 0 {
			active_particles << p
		}
	}
	app.particles = active_particles

	// Update Floating Texts
	mut active_texts := []FloatText{}
	for mut ft in app.float_texts {
		ft.y -= 35.0 * dt
		ft.life -= dt
		if ft.life > 0 {
			active_texts << ft
		}
	}
	app.float_texts = active_texts
}

fn (mut app App) render() {
	renderer := app.renderer
	ticks := u32(time.ticks())

	// Deep midnight obsidian background
	set_render_draw_color(renderer, 16, 14, 24, 255)
	render_clear(renderer)

	// Screen Shake
	mut bx := board_x
	mut by := board_y
	if app.shake_timer > 0 {
		mag := app.shake_timer * 15.0
		bx += int((rand.f64() * 2.0 - 1.0) * mag)
		by += int((rand.f64() * 2.0 - 1.0) * mag)
	}

	// Header Banner
	draw_text_centered_fitted(renderer, win_width / 2, 20, 'SAMEGAME // GEM CLUSTER COLLAPSE', 3, win_width - 60, Color{r: 255, g: 180, b: 90})
	mode_str := if app.game.mode == .puzzle { 'PUZZLE CLEAR MODE' } else { 'CONTINUOUS COLLAPSE ARCADE' }
	draw_text_centered_fitted(renderer, win_width / 2, 55, 'CLICK CONNECTED GEM CLUSTERS // ${mode_str}', 2, win_width - 60, Color{r: 160, g: 210, b: 255})

	// Outer Board Frame
	frame := Rect{x: bx - 8, y: by - 8, w: grid_w + 16, h: grid_h + 16}
	set_render_draw_color(renderer, 35, 30, 50, 255)
	render_fill_rect(renderer, &frame)
	set_render_draw_color(renderer, 90, 75, 130, 255)
	render_draw_rect(renderer, &frame)

	// Inner Grid Area
	grid_bg := Rect{x: bx, y: by, w: grid_w, h: grid_h}
	set_render_draw_color(renderer, 10, 8, 16, 255)
	render_fill_rect(renderer, &grid_bg)

	// Grid Lines
	set_render_draw_color(renderer, 22, 18, 32, 255)
	for r in 0 .. sg_rows + 1 {
		render_draw_line(renderer, bx, by + r * cell_size, bx + grid_w, by + r * cell_size)
	}
	for c in 0 .. sg_cols + 1 {
		render_draw_line(renderer, bx + c * cell_size, by, bx + c * cell_size, by + grid_h)
	}

	// Create lookup table for hovered cluster cells
	mut is_hover_map := [14][12]bool{}
	for p in app.game.hover_cluster {
		is_hover_map[p.r][p.c] = true
	}

	// Render Gems
	for r in 0 .. sg_rows {
		for c in 0 .. sg_cols {
			val := app.game.grid[r][c]
			if val != 0 {
				cx := bx + c * cell_size + cell_size / 2
				cy := by + r * cell_size + cell_size / 2
				draw_sg_gem(renderer, cx, cy, cell_size, val, is_hover_map[r][c], ticks)
			}
		}
	}

	// Left HUD Card: Score & Stats
	card_x := 32
	card_y := 120
	card_w := 180
	card_h := 340
	card_rect := Rect{x: card_x, y: card_y, w: card_w, h: card_h}
	set_render_draw_color(renderer, 24, 18, 38, 240)
	render_fill_rect(renderer, &card_rect)
	set_render_draw_color(renderer, 95, 75, 140, 255)
	render_draw_rect(renderer, &card_rect)

	info_x := card_x + 14
	draw_text(renderer, info_x, card_y + 16, 'SCORE', 2, Color{r: 180, g: 190, b: 230})
	draw_text(renderer, info_x, card_y + 38, '${app.game.score}', 3, Color{r: 255, g: 230, b: 70})

	draw_text(renderer, info_x, card_y + 88, 'HIGH SCORE', 2, Color{r: 180, g: 190, b: 230})
	draw_text(renderer, info_x, card_y + 110, '${app.game.high_score}', 3, Color{r: 255, g: 160, b: 60})

	draw_text(renderer, info_x, card_y + 160, 'CLEARED', 2, Color{r: 180, g: 190, b: 230})
	draw_text(renderer, info_x, card_y + 182, '${app.game.gems_cleared}', 3, Color{r: 100, g: 240, b: 255})

	if app.game.hover_cluster.len >= 2 {
		pts := (app.game.hover_cluster.len - 2) * (app.game.hover_cluster.len - 2) * 100 + app.game.hover_cluster.len * 50
		draw_text(renderer, info_x, card_y + 235, 'CLUSTER', 2, Color{r: 255, g: 215, b: 90})
		draw_text(renderer, info_x, card_y + 258, '${app.game.hover_cluster.len} GEMS (+${pts})', 2, Color{r: 120, g: 255, b: 160})
	}

	// Right HUD Info
	rcard_x := 800
	rcard_y := 120
	draw_text(renderer, rcard_x, rcard_y, 'CONTROLS', 1, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, rcard_x, rcard_y + 20, 'HOVER', 1, Color{r: 180, g: 200, b: 230})
	draw_text(renderer, rcard_x, rcard_y + 36, 'CLICK', 1, Color{r: 180, g: 200, b: 230})

	// Render Particles
	for p in app.particles {
		prect := Rect{x: int(p.x), y: int(p.y), w: p.size, h: p.size}
		alpha := u8((p.life / p.max_l) * 255.0)
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		render_fill_rect(renderer, &prect)
	}

	// Render Floating Texts
	for ft in app.float_texts {
		draw_text_centered(renderer, int(ft.x), int(ft.y), ft.text, ft.scale, ft.color)
	}

	// Buttons
	mx := app.mouse_x
	my := app.mouse_y
	app.btn_reset.render(renderer, mx, my)
	app.btn_sound.render(renderer, mx, my)
	app.btn_mode.render(renderer, mx, my)

	// Overlays
	if app.game.state == .cleared_all {
		box := Rect{x: bx + 10, y: by + grid_h / 2 - 60, w: grid_w - 20, h: 120}
		set_render_draw_color(renderer, 20, 35, 25, 245)
		render_fill_rect(renderer, &box)
		set_render_draw_color(renderer, 60, 240, 100, 255)
		render_draw_rect(renderer, &box)
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 - 35, 'PERFECT CLEAR! +20,000', 3, Color{r: 80, g: 255, b: 120})
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 + 15, 'PRESS [R] FOR NEW BOARD', 2, Color{r: 255, g: 255, b: 255})
	} else if app.game.state == .no_moves_left {
		box := Rect{x: bx + 10, y: by + grid_h / 2 - 60, w: grid_w - 20, h: 120}
		set_render_draw_color(renderer, 35, 20, 35, 245)
		render_fill_rect(renderer, &box)
		set_render_draw_color(renderer, 220, 100, 240, 255)
		render_draw_rect(renderer, &box)
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 - 35, 'NO MORE MOVES', 3, Color{r: 230, g: 120, b: 255})
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 + 15, 'PRESS [R] TO RESTART  [F11] Fullscreen', 2, Color{r: 255, g: 255, b: 255})
	} else if app.game.state == .game_over {
		box := Rect{x: bx + 10, y: by + grid_h / 2 - 60, w: grid_w - 20, h: 120}
		set_render_draw_color(renderer, 35, 15, 20, 245)
		render_fill_rect(renderer, &box)
		set_render_draw_color(renderer, 255, 60, 70, 255)
		render_draw_rect(renderer, &box)
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 - 35, 'CEILING BREACH! GAME OVER', 2, Color{r: 255, g: 70, b: 90})
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 + 15, 'PRESS [R] TO RESTART  [F11] Fullscreen', 2, Color{r: 255, g: 255, b: 255})
	}

	
	
}


fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.update(f64(dt))
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
			r, c := app.get_cell_under_mouse(app.mouse_x, app.mouse_y)
			app.game.update_hover(r, c)
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.btn_reset.is_hovered(mx, my) {
					app.game = new_same_game(app.game.mode)
				} else if app.btn_sound.is_hovered(mx, my) {
					app.sound_mgr.toggle_sound()
				} else if app.btn_mode.is_hovered(mx, my) {
					new_mode := if app.game.mode == .puzzle { GameMode.arcade_collapse } else { GameMode.puzzle }
					app.game = new_same_game(new_mode)
				} else {
					r, c := app.get_cell_under_mouse(mx, my)
					if r >= 0 && c >= 0 {
						cluster := app.game.find_cluster(r, c)
						if cluster.len >= 2 {
							col := app.game.grid[r][c]
							cleared := app.game.click_cell(r, c)
							if cleared > 0 {
								app.sound_mgr.play_shatter_sound(cleared)
								app.shake_timer = 0.15
								for p in cluster {
									cx := board_x + p.c * cell_size + cell_size / 2
									cy := board_y + p.r * cell_size + cell_size / 2
									app.spawn_burst(cx, cy, col)
								}
								pts := (cleared - 2) * (cleared - 2) * 100 + cleared * 50
								app.float_texts << FloatText{
									x:     f64(board_x + c * cell_size + cell_size / 2)
									y:     f64(board_y + r * cell_size)
									text:  '+${pts}'
									life:  0.8
									max_l: 0.8
									scale: 2
									color: Color{r: 255, g: 230, b: 80}
								}
								if app.game.state == .cleared_all {
									app.sound_mgr.play_clear_all_sound()
								}
							}
						}
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
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.escape { exit(0) }
				.r {
					app.game = new_same_game(app.game.mode)
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.t {
					new_mode := if app.game.mode == .puzzle { GameMode.arcade_collapse } else { GameMode.puzzle }
					app.game = new_same_game(new_mode)
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
		window_title: 'SAMEGAME // Gem Cluster Collapse Classic'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 16, g: 14, b: 24, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_width
		height: win_height
	}
	ctx.run()
}
