module main

import gg
import math
import rand
import time

const win_width = 880
const win_height = 840

// Slanted Conveyor Ramp Perspective Coordinates
const ramp_top_y = 110
const ramp_bottom_y = 440
const ramp_top_w = 260
const ramp_bottom_w = 480
const ramp_center_x = win_width / 2

// 5x5 Bin Coordinates
const bin_x = win_width / 2 - 125
const bin_y = 520
const bin_cell_w = 50
const bin_cell_h = 42

struct TileParticle {
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
	ctx             &gg.Context = unsafe { nil }
	renderer        Renderer
	sound_mgr       SoundManager
	game            KlaxGame
	particles       []TileParticle
	float_texts     []FloatText
	shake_timer     f64
	paused          bool
	btn_reset       Button
	btn_sound       Button
	btn_pause       Button
	mouse_x         int
	mouse_y         int
	last_tick       i64
}

fn new_app() App {
	btn_y := 770
	return App{
		sound_mgr: new_sound_manager()
		game:      new_klax_game()
		btn_reset: Button{
			x: 40
			y: btn_y
			w: 160
			h: 42
			text: 'RESET [R]'
			bg_color: Color{ r: 45, g: 28, b: 35, a: 255 }
			hover_color: Color{ r: 80, g: 45, b: 58, a: 255 }
			text_color: Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 175, g: 85, b: 95, a: 255 }
		}
		btn_sound: Button{
			x: 220
			y: btn_y
			w: 160
			h: 42
			text: 'SOUND [M]'
			bg_color: Color{ r: 28, g: 38, b: 52, a: 255 }
			hover_color: Color{ r: 48, g: 68, b: 95, a: 255 }
			text_color: Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 85, g: 125, b: 175, a: 255 }
		}
		btn_pause: Button{
			x: 400
			y: btn_y
			w: 160
			h: 42
			text: 'PAUSE [P]'
			bg_color: Color{ r: 42, g: 40, b: 28, a: 255 }
			hover_color: Color{ r: 75, g: 72, b: 42, a: 255 }
			text_color: Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 160, g: 155, b: 75, a: 255 }
		}
		last_tick: time.ticks()
	}
}

fn get_tile_colors(tile_type int) (Color, Color, Color, Color) {
	match tile_type {
		1 { // Crimson Red
			return Color{ r: 235, g: 40, b: 50, a: 255 }, Color{ r: 255, g: 135, b: 145, a: 255 }, Color{ r: 135, g: 15, b: 25, a: 255 }, Color{ r: 255, g: 220, b: 225, a: 255 }
		}
		2 { // Cyan Blue
			return Color{ r: 30, g: 140, b: 245, a: 255 }, Color{ r: 120, g: 205, b: 255, a: 255 }, Color{ r: 15, g: 75, b: 160, a: 255 }, Color{ r: 215, g: 240, b: 255, a: 255 }
		}
		3 { // Lime Green
			return Color{ r: 40, g: 215, b: 70, a: 255 }, Color{ r: 135, g: 255, b: 155, a: 255 }, Color{ r: 15, g: 125, b: 35, a: 255 }, Color{ r: 220, g: 255, b: 230, a: 255 }
		}
		4 { // Golden Amber Yellow
			return Color{ r: 250, g: 210, b: 30, a: 255 }, Color{ r: 255, g: 245, b: 135, a: 255 }, Color{ r: 155, g: 130, b: 15, a: 255 }, Color{ r: 255, g: 255, b: 220, a: 255 }
		}
		5 { // Vivid Magenta
			return Color{ r: 220, g: 40, b: 190, a: 255 }, Color{ r: 255, g: 135, b: 230, a: 255 }, Color{ r: 135, g: 15, b: 115, a: 255 }, Color{ r: 255, g: 220, b: 250, a: 255 }
		}
		6 { // Wild Rainbow
			return Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 180, g: 180, b: 220, a: 255 }, Color{ r: 255, g: 255, b: 255, a: 255 }
		}
		else {
			return Color{ r: 100, g: 100, b: 110, a: 255 }, Color{ r: 160, g: 160, b: 170, a: 255 }, Color{ r: 50, g: 50, b: 60, a: 255 }, Color{ r: 200, g: 200, b: 210, a: 255 }
		}
	}
}

// Draw a 3D Bevelled Tile with Gloss Highlight and Shading
fn draw_tile(renderer &Renderer, cx int, cy int, w int, h int, tile_type int, ticks u32) {
	if tile_type == 0 {
		return
	}

	if tile_type == wild_tile_type {
		t := f64(ticks) * 0.009
		red := u8((math.sin(t) * 0.5 + 0.5) * 255.0)
		green := u8((math.sin(t + 2.09) * 0.5 + 0.5) * 255.0)
		blue := u8((math.sin(t + 4.18) * 0.5 + 0.5) * 255.0)

		rect := Rect{ x: cx - w / 2, y: cy - h / 2, w: w, h: h }
		set_render_draw_color(renderer, red, green, blue, 255)
		render_fill_rect(renderer, &rect)

		set_render_draw_color(renderer, 255, 255, 255, 240)
		inner := Rect{ x: cx - w / 2 + 3, y: cy - h / 2 + 3, w: w - 6, h: h - 6 }
		render_draw_rect(renderer, &inner)

		render_draw_line(renderer, cx - 4, cy, cx + 4, cy)
		render_draw_line(renderer, cx, cy - 4, cx, cy + 4)
		return
	}

	main_c, high_c, shadow_c, _ := get_tile_colors(tile_type)

	rect := Rect{ x: cx - w / 2, y: cy - h / 2, w: w, h: h }
	set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, 255)
	render_fill_rect(renderer, &rect)

	// Top & Left bevel highlight
	set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 255)
	for i in 0 .. 4 {
		render_draw_line(renderer, cx - w / 2 + i, cy - h / 2 + i, cx + w / 2 - i, cy - h / 2 + i)
		render_draw_line(renderer, cx - w / 2 + i, cy - h / 2 + i, cx - w / 2 + i, cy + h / 2 - i)
	}

	// Bottom & Right bevel shadow
	set_render_draw_color(renderer, shadow_c.r, shadow_c.g, shadow_c.b, 255)
	for i in 0 .. 4 {
		render_draw_line(renderer, cx - w / 2 + i, cy + h / 2 - i, cx + w / 2 - i, cy + h / 2 - i)
		render_draw_line(renderer, cx + w / 2 - i, cy - h / 2 + i, cx + w / 2 - i, cy + h / 2 - i)
	}

	// Glossy reflection line across top-third
	set_render_draw_color(renderer, 255, 255, 255, 140)
	render_draw_line(renderer, cx - w / 2 + 5, cy - h / 4, cx + w / 4, cy - h / 4)

	// Border
	set_render_draw_color(renderer, 15, 15, 22, 255)
	render_draw_rect(renderer, &rect)
}

fn (mut app App) spawn_burst(cx int, cy int, tile_type int) {
	main_c, _, _, _ := get_tile_colors(tile_type)
	for _ in 0 .. 18 {
		ang := rand.f64_in_range(0.0, 2.0 * math.pi) or { 0.0 }
		spd := rand.f64_in_range(90.0, 300.0) or { 160.0 }
		life := rand.f64_in_range(0.35, 0.7) or { 0.5 }
		app.particles << TileParticle{
			x:     f64(cx)
			y:     f64(cy)
			vx:    math.cos(ang) * spd
			vy:    math.sin(ang) * spd
			life:  life
			max_l: life
			color: main_c
			size:  rand.int_in_range(3, 6) or { 4 }
			rot:   rand.f64_in_range(0.0, 6.28) or { 0.0 }
		}
	}
}

fn (mut app App) update(dt f64) {
	if app.paused {
		return
	}

	if app.shake_timer > 0 {
		app.shake_timer -= dt
	}

	prev_state := app.game.state
	prev_paddle_count := app.game.paddle_tiles.len
	prev_drops_count := app.game.drops_left

	app.game.update(dt)

	// Sound triggers
	if app.game.paddle_tiles.len > prev_paddle_count {
		app.sound_mgr.play_catch_sound()
	}
	if app.game.drops_left < prev_drops_count {
		app.sound_mgr.play_drop_loss_sound()
		app.shake_timer = 0.25
	}
	if prev_state != .clearing && app.game.state == .clearing {
		app.sound_mgr.play_klax_sound(app.game.combo_count)
		app.shake_timer = 0.18

		for pos in app.game.clearing_pos {
			cx := bin_x + pos.c * bin_cell_w + bin_cell_w / 2
			cy := bin_y + pos.r * bin_cell_h + bin_cell_h / 2
			tile_val := app.game.bin[pos.r][pos.c]
			app.spawn_burst(cx, cy, tile_val)
		}

		app.float_texts << FloatText{
			x:     f64(win_width / 2)
			y:     f64(bin_y - 25)
			text:  'KLAX! +${app.game.combo_count * 1000}'
			life:  1.1
			max_l: 1.1
			scale: 3
			color: Color{ r: 255, g: 230, b: 60, a: 255 }
		}
	}
	if prev_state != .wave_cleared && app.game.state == .wave_cleared {
		app.sound_mgr.play_wave_clear_sound()
	}
	if prev_state != .game_over && app.game.state == .game_over {
		app.sound_mgr.play_game_over_sound()
	}

	// Update Particles
	mut active_particles := []TileParticle{}
	for mut p in app.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 380.0 * dt
		p.vx *= 0.985
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

// Convert ramp lane (0..4) and progress (0.0..1.0) into Screen (X, Y, W, H)
fn get_ramp_screen_pos(lane int, progress f64) (int, int, int, int) {
	current_y := ramp_top_y + int(progress * f64(ramp_bottom_y - ramp_top_y))
	current_w := ramp_top_w + int(progress * f64(ramp_bottom_w - ramp_top_w))
	lane_w := current_w / klax_lanes
	left_x := ramp_center_x - current_w / 2
	cx := left_x + lane * lane_w + lane_w / 2

	tile_w := int(f64(bin_cell_w) * (0.55 + progress * 0.45))
	tile_h := int(f64(bin_cell_h) * (0.55 + progress * 0.45))
	return cx, current_y, tile_w, tile_h
}

fn (mut app App) render() {
	renderer := &app.renderer
	ticks := u32(time.ticks())

	set_render_draw_color(renderer, 15, 12, 24, 255)
	render_clear(renderer)

	// Screen Shake Offset
	mut sx := 0
	mut sy := 0
	if app.shake_timer > 0 {
		mag := app.shake_timer * 15.0
		sx = int((rand.f64() * 2.0 - 1.0) * mag)
		sy = int((rand.f64() * 2.0 - 1.0) * mag)
	}

	// Title Banner
	draw_text_centered_fitted(renderer, win_width / 2 + sx, 20 + sy, 'KLAX // IT IS THE NINETIES...', 3, win_width - 60, Color{ r: 255, g: 70, b: 90, a: 255 })
	draw_text_centered_fitted(renderer, win_width / 2 + sx, 55 + sy, '...AND THERE IS TIME FOR KLAX!', 2, win_width - 60, Color{ r: 255, g: 215, b: 90, a: 255 })

	// Render Conveyor Ramp (3D Perspective with Rolling Metallic Ribs)
	for p := 0; p <= 16; p++ {
		prog := f64(p) / 16.0
		cur_y := ramp_top_y + int(prog * f64(ramp_bottom_y - ramp_top_y))
		cur_w := ramp_top_w + int(prog * f64(ramp_bottom_w - ramp_top_w))

		shade := u8(22.0 + prog * 28.0)
		rline := Rect{ x: ramp_center_x - cur_w / 2 + sx, y: cur_y + sy, w: cur_w, h: 4 }
		set_render_draw_color(renderer, shade, shade - 4, shade + 12, 255)
		render_fill_rect(renderer, &rline)
	}

	// Conveyor Lanes & Neon Guides
	for lane in 0 .. klax_lanes + 1 {
		x_top := ramp_center_x - ramp_top_w / 2 + (ramp_top_w / klax_lanes) * lane
		x_bot := ramp_center_x - ramp_bottom_w / 2 + (ramp_bottom_w / klax_lanes) * lane
		set_render_draw_color(renderer, 85, 65, 130, 255)
		render_draw_line(renderer, x_top + sx, ramp_top_y + sy, x_bot + sx, ramp_bottom_y + sy)
	}

	// Render Rolling Ramp Tiles
	for tile in app.game.ramp_tiles {
		cx, cy, tw, th := get_ramp_screen_pos(tile.lane, tile.progress)
		draw_tile(renderer, cx + sx, cy + sy, tw, th, tile.tile_type, ticks)
	}

	// Catching Paddle (Cyber Futuristic Paddle)
	paddle_lane := app.game.paddle_lane
	px, py, pw, _ := get_ramp_screen_pos(paddle_lane, 1.0)
	paddle_rect := Rect{
		x: px - pw / 2 - 5 + sx
		y: py + 8 + sy
		w: pw + 10
		h: 18
	}
	set_render_draw_color(renderer, 245, 205, 65, 255)
	render_fill_rect(renderer, &paddle_rect)
	set_render_draw_color(renderer, 255, 255, 255, 220)
	render_draw_line(renderer, paddle_rect.x + 2, paddle_rect.y + 2, paddle_rect.x + paddle_rect.w - 2, paddle_rect.y + 2)
	set_render_draw_color(renderer, 150, 100, 15, 255)
	render_draw_rect(renderer, &paddle_rect)

	// Render Tiles Stacked on Paddle
	for idx, p_tile in app.game.paddle_tiles {
		stack_y := py - 6 - idx * 10
		draw_tile(renderer, px + sx, stack_y + sy, bin_cell_w - 6, bin_cell_h - 10, p_tile, ticks)
	}

	// Render 5x5 Bin
	bin_rect := Rect{
		x: bin_x - 10 + sx
		y: bin_y - 10 + sy
		w: bin_cell_w * bin_size + 20
		h: bin_cell_h * bin_size + 20
	}
	set_render_draw_color(renderer, 32, 28, 48, 255)
	render_fill_rect(renderer, &bin_rect)
	set_render_draw_color(renderer, 95, 80, 140, 255)
	render_draw_rect(renderer, &bin_rect)

	// Bin Sockets
	for r in 0 .. bin_size {
		for c in 0 .. bin_size {
			cell_r := Rect{
				x: bin_x + c * bin_cell_w + sx
				y: bin_y + r * bin_cell_h + sy
				w: bin_cell_w
				h: bin_cell_h
			}
			set_render_draw_color(renderer, 16, 14, 22, 255)
			render_fill_rect(renderer, &cell_r)
			set_render_draw_color(renderer, 50, 42, 70, 255)
			render_draw_rect(renderer, &cell_r)

			tile_val := app.game.bin[r][c]
			if tile_val != 0 {
				cx := bin_x + c * bin_cell_w + bin_cell_w / 2 + sx
				cy := bin_y + r * bin_cell_h + bin_cell_h / 2 + sy
				draw_tile(renderer, cx, cy, bin_cell_w - 4, bin_cell_h - 4, tile_val, ticks)
			}
		}
	}

	// Left HUD Card: Score, Wave & Goal
	card_x := 32
	card_y := 120
	card_w := 180
	card_h := 320
	card_rect := Rect{ x: card_x, y: card_y, w: card_w, h: card_h }
	set_render_draw_color(renderer, 24, 18, 36, 240)
	render_fill_rect(renderer, &card_rect)
	set_render_draw_color(renderer, 80, 60, 120, 255)
	render_draw_rect(renderer, &card_rect)

	info_x := card_x + 14
	draw_text(renderer, info_x, card_y + 16, 'SCORE', 2, Color{ r: 180, g: 190, b: 230, a: 255 })
	draw_text(renderer, info_x, card_y + 40, '${app.game.score}', 3, Color{ r: 255, g: 230, b: 70, a: 255 })

	draw_text(renderer, info_x, card_y + 90, 'HIGH SCORE', 2, Color{ r: 180, g: 190, b: 230, a: 255 })
	draw_text(renderer, info_x, card_y + 114, '${app.game.high_score}', 3, Color{ r: 255, g: 160, b: 60, a: 255 })

	draw_text(renderer, info_x, card_y + 165, 'WAVE', 2, Color{ r: 180, g: 190, b: 230, a: 255 })
	draw_text(renderer, info_x, card_y + 188, '${app.game.wave}', 3, Color{ r: 90, g: 230, b: 255, a: 255 })

	// Goal Display
	draw_text(renderer, info_x, card_y + 240, 'MISSION GOAL', 2, Color{ r: 255, g: 215, b: 90, a: 255 })
	goal_desc := match app.game.goal_type {
		.klaxes { 'KLAXES' }
		.diagonals { 'DIAGONALS' }
		.points { 'POINTS' }
		.tiles_cleared { 'TILES' }
		.horizontals { 'HORIZONTALS' }
	}
	draw_text(renderer, info_x, card_y + 265, '${goal_desc}: ${app.game.goal_progress} / ${app.game.goal_target}', 2, Color{ r: 120, g: 255, b: 160, a: 255 })

	// Right HUD Card: Drops Remaining & Controls
	rcard_x := 668
	rcard_y := 120
	rcard_w := 180
	rcard_h := 320
	rcard_rect := Rect{ x: rcard_x, y: rcard_y, w: rcard_w, h: rcard_h }
	set_render_draw_color(renderer, 24, 18, 36, 240)
	render_fill_rect(renderer, &rcard_rect)
	set_render_draw_color(renderer, 80, 60, 120, 255)
	render_draw_rect(renderer, &rcard_rect)

	rhud_x := rcard_x + 14
	draw_text(renderer, rhud_x, rcard_y + 16, 'DROPS LEFT', 2, Color{ r: 255, g: 90, b: 110, a: 255 })
	for d in 0 .. 3 {
		d_rect := Rect{ x: rhud_x + d * 48, y: rcard_y + 44, w: 36, h: 28 }
		if d < app.game.drops_left {
			set_render_draw_color(renderer, 245, 60, 80, 255)
			render_fill_rect(renderer, &d_rect)
			set_render_draw_color(renderer, 255, 140, 160, 255)
			render_draw_line(renderer, d_rect.x + 2, d_rect.y + 2, d_rect.x + d_rect.w - 2, d_rect.y + 2)
		} else {
			set_render_draw_color(renderer, 50, 32, 42, 255)
			render_fill_rect(renderer, &d_rect)
		}
		set_render_draw_color(renderer, 120, 50, 65, 255)
		render_draw_rect(renderer, &d_rect)
	}

	ctrl_y := rcard_y + 130
	draw_text(renderer, rhud_x, ctrl_y, 'CONTROLS', 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	draw_text(renderer, rhud_x, ctrl_y + 26, 'A/D: MOVE PADDLE', 1, Color{ r: 190, g: 200, b: 230, a: 255 })
	draw_text(renderer, rhud_x, ctrl_y + 50, 'S / SPACE: FLIP', 1, Color{ r: 190, g: 200, b: 230, a: 255 })
	draw_text(renderer, rhud_x, ctrl_y + 74, 'W / UP: PUSH UP', 1, Color{ r: 190, g: 200, b: 230, a: 255 })

	// Render Particles
	for p in app.particles {
		prect := Rect{ x: int(p.x), y: int(p.y), w: p.size, h: p.size }
		alpha := u8((p.life / p.max_l) * 255.0)
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		render_fill_rect(renderer, &prect)
	}

	// Render Floating Texts
	for ft in app.float_texts {
		draw_text_centered(renderer, int(ft.x), int(ft.y), ft.text, ft.scale, ft.color)
	}

	// Buttons
	app.btn_reset.render(renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.render(renderer, app.mouse_x, app.mouse_y)
	app.btn_pause.render(renderer, app.mouse_x, app.mouse_y)

	// Overlays
	if app.game.state == .wave_cleared {
		box := Rect{ x: win_width / 2 - 200, y: win_height / 2 - 60, w: 400, h: 120 }
		set_render_draw_color(renderer, 20, 35, 20, 245)
		render_fill_rect(renderer, &box)
		set_render_draw_color(renderer, 60, 240, 90, 255)
		render_draw_rect(renderer, &box)
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 35, 'WAVE ${app.game.wave} CLEARED!', 3, Color{ r: 80, g: 255, b: 120, a: 255 })
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 15, 'PRESS [SPACE] FOR NEXT WAVE', 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	} else if app.game.state == .game_over {
		box := Rect{ x: win_width / 2 - 200, y: win_height / 2 - 60, w: 400, h: 120 }
		set_render_draw_color(renderer, 35, 15, 20, 245)
		render_fill_rect(renderer, &box)
		set_render_draw_color(renderer, 255, 60, 70, 255)
		render_draw_rect(renderer, &box)
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 35, 'GAME OVER', 3, Color{ r: 255, g: 70, b: 90, a: 255 })
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 15, 'PRESS [R] TO RESTART', 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	} else if app.paused {
		box := Rect{ x: win_width / 2 - 160, y: win_height / 2 - 50, w: 320, h: 100 }
		set_render_draw_color(renderer, 20, 25, 40, 245)
		render_fill_rect(renderer, &box)
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 25, 'PAUSED', 3, Color{ r: 255, g: 220, b: 80, a: 255 })
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 15, 'PRESS [P] TO RESUME', 2, Color{ r: 200, g: 220, b: 255, a: 255 })
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
				if app.btn_reset.is_hovered(mx, my) {
					app.game = new_klax_game()
				} else if app.btn_sound.is_hovered(mx, my) {
					app.sound_mgr.toggle_sound()
				} else if app.btn_pause.is_hovered(mx, my) {
					app.paused = !app.paused
				} else if app.game.state == .wave_cleared {
					app.game.init_wave(app.game.wave + 1)
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
					app.sound_mgr.toggle_music()
				}
				.left, .a {
					app.game.move_paddle(-1)
				}
				.right, .d {
					app.game.move_paddle(1)
				}
				.down, .s, .space {
					if app.game.state == .wave_cleared {
						app.game.init_wave(app.game.wave + 1)
					} else {
						if app.game.flip_tile() {
							app.sound_mgr.play_flip_sound()
						}
					}
				}
				.up, .w {
					if app.game.push_tile_up() {
						app.sound_mgr.play_push_sound()
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
