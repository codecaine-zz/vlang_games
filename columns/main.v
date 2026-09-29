module main

import math
import rand
import gg
import time

const win_width = 860
const win_height = 840

const cell_size = 46
const grid_w = col_cols * cell_size
const grid_h = col_rows * cell_size
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

struct Star {
mut:
	x     int
	y     int
	size  int
	speed f64
	phase f64
}

struct App {
mut:
	ctx &gg.Context = unsafe { nil }
	renderer Renderer
	last_tick i64
	mouse_x int
	mouse_y int
	sound_mgr   SoundManager
	game        ColumnsGame
	particles   []GemParticle
	float_texts []FloatText
	stars       []Star
	shake_timer f64
	paused      bool
	btn_reset   Button
	btn_sound   Button
	btn_pause   Button
	glint_timer f64
}

fn new_app() App {
	mut stars := []Star{cap: 80}
	for _ in 0 .. 80 {
		stars << Star{
			x:     rand.int_in_range(0, win_width) or { 0 }
			y:     rand.int_in_range(0, win_height) or { 0 }
			size:  rand.int_in_range(1, 3) or { 1 }
			speed: rand.f64_in_range(8.0, 26.0) or { 14.0 }
			phase: rand.f64_in_range(0.0, 6.28) or { 0.0 }
		}
	}

	btn_y := 744
	return App{
		sound_mgr: new_sound_manager()
		game:      new_columns_game()
		stars:     stars
		btn_reset: Button{
			x: 40, y: btn_y, w: 160, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 38, g: 28, b: 58},
			hover_color: Color{r: 72, g: 48, b: 115},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 140, g: 95, b: 210},
		}
		btn_sound: Button{
			x: 220, y: btn_y, w: 160, h: 42, text: 'SOUND [M]',
			bg_color: Color{r: 28, g: 42, b: 62},
			hover_color: Color{r: 45, g: 75, b: 115},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 85, g: 150, b: 210},
		}
		btn_pause: Button{
			x: 400, y: btn_y, w: 160, h: 42, text: 'PAUSE [P]',
			bg_color: Color{r: 45, g: 42, b: 30},
			hover_color: Color{r: 80, g: 75, b: 45},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 175, g: 165, b: 85},
		}
	}
}

// Rich Gem Color Palettes
fn get_gem_colors(gem_type int) (Color, Color, Color, Color) {
	match gem_type {
		1 { // Ruby Red
			return Color{r: 235, g: 35, b: 55}, Color{r: 255, g: 140, b: 160}, Color{r: 130, g: 10, b: 20}, Color{r: 255, g: 220, b: 230}
		}
		2 { // Amber Orange
			return Color{r: 255, g: 135, b: 15}, Color{r: 255, g: 195, b: 80}, Color{r: 160, g: 70, b: 5}, Color{r: 255, g: 240, b: 200}
		}
		3 { // Topaz Gold
			return Color{r: 245, g: 220, b: 25}, Color{r: 255, g: 250, b: 140}, Color{r: 150, g: 130, b: 10}, Color{r: 255, g: 255, b: 220}
		}
		4 { // Emerald Green
			return Color{r: 25, g: 210, b: 85}, Color{r: 110, g: 255, b: 155}, Color{r: 10, g: 115, b: 40}, Color{r: 220, g: 255, b: 230}
		}
		5 { // Sapphire Blue
			return Color{r: 35, g: 130, b: 245}, Color{r: 120, g: 195, b: 255}, Color{r: 15, g: 65, b: 160}, Color{r: 215, g: 240, b: 255}
		}
		6 { // Amethyst Purple
			return Color{r: 190, g: 45, b: 230}, Color{r: 230, g: 135, b: 255}, Color{r: 105, g: 15, b: 140}, Color{r: 250, g: 220, b: 255}
		}
		7 { // Magic Rainbow Gem
			return Color{r: 255, g: 255, b: 255}, Color{r: 255, g: 255, b: 255}, Color{r: 180, g: 180, b: 220}, Color{r: 255, g: 255, b: 255}
		}
		else {
			return Color{r: 90, g: 90, b: 90}, Color{r: 150, g: 150, b: 150}, Color{r: 45, g: 45, b: 45}, Color{r: 200, g: 200, b: 200}
		}
	}
}

// Expert Procedural Faceted Gem Drawing Routine with Octagonal Cuts & Glints
fn draw_gem(renderer &Renderer, cx int, cy int, size int, gem_type int, ticks u32, is_clearing bool) {
	if gem_type == 0 {
		return
	}
	r := size / 2 - 2

	if gem_type == magic_gem_type {
		// Prismatic Rotating Rainbow Crystal with Outer Corona
		t := f64(ticks) * 0.009
		red := u8((math.sin(t) * 0.5 + 0.5) * 255.0)
		green := u8((math.sin(t + 2.09) * 0.5 + 0.5) * 255.0)
		blue := u8((math.sin(t + 4.18) * 0.5 + 0.5) * 255.0)

		// Corona Rings
		for ring in 0 .. 4 {
			aura_rect := Rect{x: cx - r - ring, y: cy - r - ring, w: (r + ring) * 2, h: (r + ring) * 2}
			set_render_draw_color(renderer, red, green, blue, u8(160 - ring * 35))
			render_draw_rect(renderer, &aura_rect)
		}
		// Core Diamond
		core := Rect{x: cx - r + 3, y: cy - r + 3, w: (r - 3) * 2, h: (r - 3) * 2}
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_fill_rect(renderer, &core)

		// Prismatic cross-facets
		set_render_draw_color(renderer, red, green, blue, 255)
		render_draw_line(renderer, cx - r, cy, cx + r, cy)
		render_draw_line(renderer, cx, cy - r, cx, cy + r)
		render_draw_line(renderer, cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3)
		render_draw_line(renderer, cx + r - 3, cy - r + 3, cx - r + 3, cy + r - 3)
		return
	}

	main_c, high_c, shadow_c, glint_c := get_gem_colors(gem_type)

	// Flashing white if currently in match/clearing state
	if is_clearing {
		t_flash := (ticks / 50) % 2
		if t_flash == 0 {
			flash_rect := Rect{x: cx - r, y: cy - r, w: r * 2, h: r * 2}
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &flash_rect)
			return
		}
	}

	// Main Faceted Jewel Base
	body := Rect{x: cx - r + 2, y: cy - r + 2, w: (r - 2) * 2, h: (r - 2) * 2}
	set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, 255)
	render_fill_rect(renderer, &body)

	// Top Facet Highlight
	set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 255)
	for i in 0 .. 5 {
		render_draw_line(renderer, cx - r + 2 + i, cy - r + 2 + i, cx + r - 2 - i, cy - r + 2 + i)
		render_draw_line(renderer, cx - r + 2 + i, cy - r + 2 + i, cx - r + 2 + i, cy + r - 2 - i)
	}

	// Bottom Facet Shadow
	set_render_draw_color(renderer, shadow_c.r, shadow_c.g, shadow_c.b, 255)
	for i in 0 .. 5 {
		render_draw_line(renderer, cx - r + 2 + i, cy + r - 2 - i, cx + r - 2 - i, cy + r - 2 - i)
		render_draw_line(renderer, cx + r - 2 - i, cy - r + 2 + i, cx + r - 2 - i, cy + r - 2 - i)
	}

	// Center Table Facet
	table_rect := Rect{x: cx - r / 2, y: cy - r / 2, w: r, h: r}
	set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, 255)
	render_fill_rect(renderer, &table_rect)

	// Diagonal Facet Bevels
	set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 200)
	render_draw_line(renderer, cx - r + 2, cy - r + 2, cx - r / 2, cy - r / 2)
	render_draw_line(renderer, cx + r - 2, cy - r + 2, cx + r / 2, cy - r / 2)

	set_render_draw_color(renderer, shadow_c.r, shadow_c.g, shadow_c.b, 200)
	render_draw_line(renderer, cx - r + 2, cy + r - 2, cx - r / 2, cy + r / 2)
	render_draw_line(renderer, cx + r - 2, cy + r - 2, cx + r / 2, cy + r / 2)

	// Sparkling Glint Star
	glint_phase := (f64(ticks + u32(cx * 17 + cy * 23)) * 0.004)
	if math.sin(glint_phase) > 0.85 {
		set_render_draw_color(renderer, glint_c.r, glint_c.g, glint_c.b, 255)
		gx := cx - r / 3
		gy := cy - r / 3
		render_draw_line(renderer, gx - 3, gy, gx + 3, gy)
		render_draw_line(renderer, gx, gy - 3, gx, gy + 3)
		render_draw_point(renderer, gx, gy)
	}

	// Crisp Dark Outline
	border := Rect{x: cx - r + 1, y: cy - r + 1, w: (r - 1) * 2, h: (r - 1) * 2}
	set_render_draw_color(renderer, 15, 15, 25, 255)
	render_draw_rect(renderer, &border)
}

fn (mut app App) spawn_gem_burst(cx int, cy int, gem_type int) {
	main_c, _, _, _ := get_gem_colors(gem_type)
	for _ in 0 .. 16 {
		ang := rand.f64_in_range(0.0, 2.0 * math.pi) or { 0.0 }
		spd := rand.f64_in_range(90.0, 300.0) or { 160.0 }
		life := rand.f64_in_range(0.4, 0.75) or { 0.55 }
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

fn (mut app App) update(dt f64) {
	if app.paused {
		return
	}

	if app.shake_timer > 0 {
		app.shake_timer -= dt
	}

	// Update Stars with twinkle
	for mut star in app.stars {
		star.y += int(star.speed * dt * 2.0)
		star.phase += dt * 3.0
		if star.y > win_height {
			star.y = 0
			star.x = rand.int_in_range(0, win_width) or { 0 }
		}
	}

	prev_state := app.game.state
	app.game.update(dt)

	// Trigger sound & fx on clearing state entry
	if prev_state != .clearing && app.game.state == .clearing {
		if app.game.active_col.gems[0] == magic_gem_type {
			app.sound_mgr.play_magic_sound()
			app.shake_timer = 0.35
		} else {
			app.sound_mgr.play_match_sound(app.game.combo_count)
			if app.game.combo_count > 1 {
				app.shake_timer = 0.18
			}
		}

		for pos in app.game.clearing_pos {
			cx := board_x + pos.c * cell_size + cell_size / 2
			cy := board_y + pos.r * cell_size + cell_size / 2
			gem_val := app.game.grid[pos.r][pos.c]
			app.spawn_gem_burst(cx, cy, gem_val)
		}

		if app.game.combo_count > 1 {
			app.float_texts << FloatText{
				x:     f64(board_x + grid_w / 2)
				y:     f64(board_y + grid_h / 2 - app.game.combo_count * 22)
				text:  'COMBO x${app.game.combo_count}!'
				life:  1.1
				max_l: 1.1
				scale: 3
				color: Color{r: 255, g: 230, b: 70}
			}
		}
	}

	if prev_state != .game_over && app.game.state == .game_over {
		app.sound_mgr.play_game_over_sound()
	}

	// Update Particles
	mut active_particles := []GemParticle{}
	for mut p in app.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 420.0 * dt // Gravity
		p.vx *= 0.985      // Air drag
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
		ft.y -= 38.0 * dt
		ft.life -= dt
		if ft.life > 0 {
			active_texts << ft
		}
	}
	app.float_texts = active_texts
}

fn (mut app App) render() {
	renderer := &app.renderer
	ticks := u32(time.ticks())

	// Starry Greek temple midnight blue background
	set_render_draw_color(renderer, 12, 10, 24, 255)
	render_clear(renderer)

	// Twinkling Starfield
	for star in app.stars {
		alpha := u8((math.sin(star.phase) * 0.4 + 0.6) * 220.0)
		set_render_draw_color(renderer, 190, 200, 240, alpha)
		srect := Rect{x: star.x, y: star.y, w: star.size, h: star.size}
		render_fill_rect(renderer, &srect)
	}

	// Screen Shake Offset
	mut bx := board_x
	mut by := board_y
	if app.shake_timer > 0 {
		mag := app.shake_timer * 16.0
		bx += int((rand.f64() * 2.0 - 1.0) * mag)
		by += int((rand.f64() * 2.0 - 1.0) * mag)
	}

	// Header Banner with Gold Accents
	draw_text_centered_fitted(renderer, win_width / 2, 22, 'COLUMNS // SEGA ARCADE CLASSIC', 3, win_width - 60, Color{r: 255, g: 215, b: 90})
	draw_text_centered_fitted(renderer, win_width / 2, 60, 'CYCLE & MATCH 3 JEWELS // HORIZONTAL, VERTICAL & DIAGONAL', 2, win_width - 60, Color{r: 170, g: 200, b: 245})

	// Marble Pillar Capitals & Fluting (Left & Right)
	pillar_w := 28
	left_pillar := Rect{x: bx - pillar_w - 6, y: by - 16, w: pillar_w, h: grid_h + 32}
	right_pillar := Rect{x: bx + grid_w + 6, y: by - 16, w: pillar_w, h: grid_h + 32}

	// Pillar Body (Marble gradient)
	set_render_draw_color(renderer, 225, 220, 205, 255)
	render_fill_rect(renderer, &left_pillar)
	render_fill_rect(renderer, &right_pillar)

	// Fluting lines
	set_render_draw_color(renderer, 160, 150, 135, 255)
	for f in 1 .. 4 {
		fx_l := left_pillar.x + f * 7
		fx_r := right_pillar.x + f * 7
		render_draw_line(renderer, fx_l, left_pillar.y + 4, fx_l, left_pillar.y + left_pillar.h - 4)
		render_draw_line(renderer, fx_r, right_pillar.y + 4, fx_r, right_pillar.y + right_pillar.h - 4)
	}
	set_render_draw_color(renderer, 110, 100, 90, 255)
	render_draw_rect(renderer, &left_pillar)
	render_draw_rect(renderer, &right_pillar)

	// Board Background
	board_rect := Rect{x: bx, y: by, w: grid_w, h: grid_h}
	set_render_draw_color(renderer, 8, 8, 16, 255)
	render_fill_rect(renderer, &board_rect)

	// Grid Checker / Lines
	for r in 0 .. col_rows {
		for c in 0 .. col_cols {
			cell_bg := Rect{x: bx + c * cell_size, y: by + r * cell_size, w: cell_size, h: cell_size}
			if (r + c) % 2 == 0 {
				set_render_draw_color(renderer, 14, 14, 26, 255)
				render_fill_rect(renderer, &cell_bg)
			}
		}
	}
	set_render_draw_color(renderer, 30, 32, 50, 255)
	for r in 0 .. col_rows + 1 {
		render_draw_line(renderer, bx, by + r * cell_size, bx + grid_w, by + r * cell_size)
	}
	for c in 0 .. col_cols + 1 {
		render_draw_line(renderer, bx + c * cell_size, by, bx + c * cell_size, by + grid_h)
	}

	// Create map of clearing cells
	mut is_clear_map := [13][6]bool{}
	for p in app.game.clearing_pos {
		is_clear_map[p.r][p.c] = true
	}

	// Render Settled Gems in Grid
	for r in 0 .. col_rows {
		for c in 0 .. col_cols {
			gem := app.game.grid[r][c]
			if gem != 0 {
				cx := bx + c * cell_size + cell_size / 2
				cy := by + r * cell_size + cell_size / 2
				draw_gem(renderer, cx, cy, cell_size, gem, ticks, is_clear_map[r][c])
			}
		}
	}

	// Render Active Falling Column
	if app.game.state == .falling {
		c := app.game.active_col.c
		y_pos := app.game.active_col.y
		for i in 0 .. 3 {
			gem_r := y_pos + f64(i)
			if gem_r >= -0.8 && gem_r < f64(col_rows) {
				cx := bx + c * cell_size + cell_size / 2
				cy := by + int(gem_r * f64(cell_size)) + cell_size / 2
				draw_gem(renderer, cx, cy, cell_size, app.game.active_col.gems[i], ticks, false)
			}
		}

		// Landing Ghost / Shadow Guide
		landing_r := app.game.get_landing_row(c)
		shadow_box := Rect{
			x: bx + c * cell_size + 2
			y: by + (landing_r - 2) * cell_size + 2
			w: cell_size - 4
			h: cell_size * 3 - 4
		}
		set_render_draw_color(renderer, 255, 255, 255, 55)
		render_draw_rect(renderer, &shadow_box)
	}

	// Left HUD Card: Score, High Score, Level
	card_x := 32
	card_y := 120
	card_w := 176
	card_h := 360
	card_rect := Rect{x: card_x, y: card_y, w: card_w, h: card_h}
	set_render_draw_color(renderer, 22, 18, 38, 240)
	render_fill_rect(renderer, &card_rect)
	set_render_draw_color(renderer, 75, 60, 120, 255)
	render_draw_rect(renderer, &card_rect)

	info_x := card_x + 14
	draw_text(renderer, info_x, card_y + 20, 'SCORE', 2, Color{r: 170, g: 185, b: 230})
	draw_text(renderer, info_x, card_y + 45, '${app.game.score}', 3, Color{r: 255, g: 235, b: 110})

	draw_text(renderer, info_x, card_y + 105, 'HIGH SCORE', 2, Color{r: 170, g: 185, b: 230})
	draw_text(renderer, info_x, card_y + 130, '${app.game.high_score}', 3, Color{r: 255, g: 170, b: 70})

	draw_text(renderer, info_x, card_y + 190, 'LEVEL', 2, Color{r: 170, g: 185, b: 230})
	draw_text(renderer, info_x, card_y + 215, '${app.game.level}', 3, Color{r: 95, g: 240, b: 255})

	draw_text(renderer, info_x, card_y + 275, 'CLEARED', 2, Color{r: 170, g: 185, b: 230})
	draw_text(renderer, info_x, card_y + 300, '${app.game.jewels_cleared}', 3, Color{r: 140, g: 255, b: 140})

	// Right HUD: Next Preview Box & Controls
	rcard_x := 615
	rcard_y := 120
	rcard_w := 210
	rcard_h := 360
	rcard_rect := Rect{x: rcard_x, y: rcard_y, w: rcard_w, h: rcard_h}
	set_render_draw_color(renderer, 22, 18, 38, 240)
	render_fill_rect(renderer, &rcard_rect)
	set_render_draw_color(renderer, 75, 60, 120, 255)
	render_draw_rect(renderer, &rcard_rect)

	draw_text_centered(renderer, rcard_x + rcard_w / 2, rcard_y + 16, 'NEXT COLUMN', 2, Color{r: 255, g: 215, b: 90})

	pbox := Rect{x: rcard_x + rcard_w / 2 - cell_size / 2 - 6, y: rcard_y + 44, w: cell_size + 12, h: cell_size * 3 + 12}
	set_render_draw_color(renderer, 10, 8, 18, 255)
	render_fill_rect(renderer, &pbox)
	set_render_draw_color(renderer, 110, 90, 170, 255)
	render_draw_rect(renderer, &pbox)

	for i in 0 .. 3 {
		cx := rcard_x + rcard_w / 2
		cy := rcard_y + 50 + i * cell_size + cell_size / 2
		draw_gem(renderer, cx, cy, cell_size, app.game.next_gems[i], ticks, false)
	}

	ctrl_y := rcard_y + 215
	draw_text(renderer, rcard_x + 14, ctrl_y, 'CONTROLS', 2, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, rcard_x + 14, ctrl_y + 26, 'A / D / ARROWS: MOVE', 1, Color{r: 190, g: 210, b: 240})
	draw_text(renderer, rcard_x + 14, ctrl_y + 46, 'W / UP / SPACE: CYCLE', 1, Color{r: 190, g: 210, b: 240})
	draw_text(renderer, rcard_x + 14, ctrl_y + 66, 'S / DOWN: SOFT DROP', 1, Color{r: 190, g: 210, b: 240})
	draw_text(renderer, rcard_x + 14, ctrl_y + 86, 'ENTER: HARD DROP', 1, Color{r: 190, g: 210, b: 240})

	// Render Particles
	for p in app.particles {
		prect := Rect{x: int(p.x), y: int(p.y), w: p.size, h: p.size}
		alpha := u8((p.life / p.max_l) * 255.0)
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		render_fill_rect(renderer, &prect)
	}

	// Render Floating Combo Texts
	for ft in app.float_texts {
		draw_text_centered(renderer, int(ft.x), int(ft.y), ft.text, ft.scale, ft.color)
	}

	// Buttons
	mut mx := 0
	mut my := 0
	mx = app.mouse_x
	my = app.mouse_y
	app.btn_reset.render(renderer, mx, my)
	app.btn_sound.render(renderer, mx, my)
	app.btn_pause.render(renderer, mx, my)

	// Game Over / Pause Overlays
	if app.game.state == .game_over {
		over_box := Rect{x: bx + 10, y: by + grid_h / 2 - 60, w: grid_w - 20, h: 120}
		set_render_draw_color(renderer, 25, 12, 22, 245)
		render_fill_rect(renderer, &over_box)
		set_render_draw_color(renderer, 255, 65, 85, 255)
		render_draw_rect(renderer, &over_box)
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 - 35, 'GAME OVER', 3, Color{r: 255, g: 75, b: 95})
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 + 15, 'PRESS [R] TO RESTART  [F11] Fullscreen', 2, Color{r: 255, g: 255, b: 255})
	} else if app.paused {
		p_box := Rect{x: bx + 10, y: by + grid_h / 2 - 50, w: grid_w - 20, h: 100}
		set_render_draw_color(renderer, 15, 20, 35, 245)
		render_fill_rect(renderer, &p_box)
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 - 25, 'PAUSED', 3, Color{r: 255, g: 220, b: 80})
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 + 15, 'PRESS [P] TO RESUME', 2, Color{r: 200, g: 220, b: 255})
	}

	prod_fx_render(app.ctx)
	render_present(renderer)
}


fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := math.min(0.033, if raw_dt > 0.001 { raw_dt } else { 1.0 / 60.0 })

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
					app.game = new_columns_game()
				} else if app.btn_sound.is_hovered(mx, my) {
					app.sound_mgr.toggle_sound()
				} else if app.btn_pause.is_hovered(mx, my) {
					app.paused = !app.paused
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
					app.game = new_columns_game()
				}
				.p {
					app.paused = !app.paused
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.left, .a {
					if app.game.move_column(-1) {
						app.sound_mgr.play_move_sound()
					}
				}
				.right, .d {
					if app.game.move_column(1) {
						app.sound_mgr.play_move_sound()
					}
				}
				.up, .w, .space {
					app.game.cycle_gems()
					app.sound_mgr.play_cycle_sound()
				}
				.down, .s {
					if app.game.state == .falling {
						app.game.active_col.y += 0.8
					}
				}
				.enter {
					app.game.hard_drop()
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
		window_title: 'COLUMNS // Sega Gem Puzzle Classic'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_width
		height: win_height
	}
	ctx.run()
}
