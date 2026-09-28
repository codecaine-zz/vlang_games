module main

import math
import rand

pub enum SliceItemType {
	watermelon
	orange
	apple
	dragonfruit
	diamond_star
	bomb
}

pub struct SliceableItem {
pub mut:
	x          f64
	y          f64
	vx         f64
	vy         f64
	radius     f64 = 28.0
	rotation   f64
	rot_speed  f64
	item_type  SliceItemType
	color      Color
	active     bool = true
	sliced     bool
}

pub struct SlicedHalf {
pub mut:
	x         f64
	y         f64
	vx        f64
	vy        f64
	rotation  f64
	rot_speed f64
	radius    f64
	color     Color
	item_type SliceItemType
	life      f64 = 1.2
	is_left   bool
}

pub struct TrailPoint {
pub:
	x    f64
	y    f64
	life f64
}

pub struct BladeSlicerGame {
pub mut:
	score         int
	high_score    int
	lives         int = 3
	game_over     bool
	combo_counter int
	total_sliced  int

	items         []SliceableItem
	halves        []SlicedHalf
	trail         []TrailPoint
	floating_texts []FloatingText
	particles     []Particle

	is_mouse_down bool
	last_mouse_x  f64
	last_mouse_y  f64

	spawn_timer   f64
	difficulty    f64 = 1.0
	frenzy_timer  f64
	is_frenzy     bool

	swipe_combo   int
}

pub fn new_blade_slicer_game() BladeSlicerGame {
	mut g := BladeSlicerGame{}
	g.reset()
	return g
}

pub fn (mut g BladeSlicerGame) reset() {
	g.score = 0
	g.lives = 3
	g.game_over = false
	g.combo_counter = 0
	g.total_sliced = 0
	g.difficulty = 1.0
	g.spawn_timer = 1.0
	g.frenzy_timer = 0.0
	g.is_frenzy = false
	g.swipe_combo = 0

	g.items = []SliceableItem{}
	g.halves = []SlicedHalf{}
	g.trail = []TrailPoint{}
	g.floating_texts = []FloatingText{}
	g.particles = []Particle{}
}

pub fn (mut g BladeSlicerGame) spawn_wave() {
	count := if g.is_frenzy {
		3 + rand.int_in_range(0, 4) or { 2 }
	} else {
		1 + rand.int_in_range(0, 3) or { 1 }
	}

	for _ in 0 .. count {
		start_x := 120.0 + rand.f64() * 640.0
		start_y := 620.0
		target_x := 200.0 + rand.f64() * 480.0
		dx := target_x - start_x

		mut vy := -620.0 - rand.f64() * 160.0
		if g.is_frenzy {
			vy *= 0.85
		}
		vx := dx * 0.9

		roll := rand.f64()
		mut itype := SliceItemType.watermelon
		mut col := col_green
		mut rad := 30.0

		if roll < 0.16 && !g.is_frenzy {
			itype = .bomb
			col = col_dark_gray
			rad = 24.0
		} else if roll < 0.28 {
			itype = .dragonfruit
			col = col_pink
			rad = 28.0
		} else if roll < 0.44 {
			itype = .diamond_star
			col = col_cyan
			rad = 26.0
		} else if roll < 0.70 {
			itype = .orange
			col = col_orange
			rad = 26.0
		} else if roll < 0.85 {
			itype = .apple
			col = col_red
			rad = 25.0
		}

		g.items << SliceableItem{
			x: start_x
			y: start_y
			vx: vx
			vy: vy
			radius: rad
			rotation: rand.f64() * math.pi * 2.0
			rot_speed: (rand.f64() - 0.5) * 5.0
			item_type: itype
			color: col
			active: true
			sliced: false
		}
	}
}

// Line segment intersection with circle for blade swipe
fn line_intersects_circle(x1 f64, y1 f64, x2 f64, y2 f64, cx f64, cy f64, r f64) bool {
	dx := x2 - x1
	dy := y2 - y1
	len_sq := dx * dx + dy * dy
	if len_sq == 0.0 {
		dist_sq := (x1 - cx) * (x1 - cx) + (y1 - cy) * (y1 - cy)
		return dist_sq <= r * r
	}
	dot := (cx - x1) * dx + (cy - y1) * dy
	t := math.max(0.0, math.min(1.0, dot / len_sq))
	proj_x := x1 + t * dx
	proj_y := y1 + t * dy
	dist_sq := (proj_x - cx) * (proj_x - cx) + (proj_y - cy) * (proj_y - cy)
	return dist_sq <= r * r
}

pub fn (mut g BladeSlicerGame) process_mouse_move(x f64, y f64, is_down bool, mut sm SoundManager) {
	if g.game_over {
		return
	}

	if is_down {
		g.trail << TrailPoint{
			x: x
			y: y
			life: 0.22
		}

		if g.is_mouse_down {
			// Check slicing collisions
			for mut item in g.items {
				if !item.active || item.sliced {
					continue
				}

				if line_intersects_circle(g.last_mouse_x, g.last_mouse_y, x, y, item.x, item.y, item.radius) {
					g.slice_item(mut item, x, y, mut sm)
				}
			}
		}
	} else {
		// Released mouse -> check combo bonus
		if g.swipe_combo >= 3 {
			bonus := g.swipe_combo * 150
			g.score += bonus
			g.floating_texts << FloatingText{
				x: x
				y: y - 30.0
				text: '${g.swipe_combo}x COMBO SLICE! +${bonus}'
				color: col_gold
				life: 1.2
				max_life: 1.2
				scale: 2
				vy: -70.0
			}
		}
		g.swipe_combo = 0
	}

	g.is_mouse_down = is_down
	g.last_mouse_x = x
	g.last_mouse_y = y
}

pub fn (mut g BladeSlicerGame) slice_item(mut item SliceableItem, slice_x f64, slice_y f64, mut sm SoundManager) {
	item.sliced = true
	item.active = false
	g.swipe_combo++
	g.total_sliced++

	if item.item_type == .bomb {
		g.lives--
		sm.play_explosion()
		g.floating_texts << FloatingText{
			x: item.x
			y: item.y
			text: 'BOMB HIT! -1 LIFE'
			color: col_red
			life: 1.0
			max_life: 1.0
			scale: 2
			vy: -60.0
		}

		for _ in 0 .. 30 {
			ang := rand.f64() * math.pi * 2.0
			spd := 90.0 + rand.f64() * 140.0
			g.particles << Particle{
				x: item.x
				y: item.y
				vx: math.cos(ang) * spd
				vy: math.sin(ang) * spd
				color: col_red
				size: 4.0
				life: 0.6
				max_life: 0.6
			}
		}

		if g.lives <= 0 {
			g.game_over = true
		}
		return
	}

	mut base_pts := 100
	match item.item_type {
		.watermelon { base_pts = 100 }
		.orange { base_pts = 150 }
		.apple { base_pts = 200 }
		.diamond_star { base_pts = 500 }
		.dragonfruit {
			base_pts = 350
			g.is_frenzy = true
			g.frenzy_timer = 8.0
			sm.play_golden_frenzy()
			g.floating_texts << FloatingText{
				x: item.x
				y: item.y - 25.0
				text: 'FRENZY STORM!'
				color: col_pink
				life: 1.5
				max_life: 1.5
				scale: 2
				vy: -80.0
			}
		}
		else {}
	}

	pts := base_pts * g.swipe_combo
	g.score += pts
	sm.play_blade_slice(g.swipe_combo)

	// Floating score
	g.floating_texts << FloatingText{
		x: item.x
		y: item.y - 15.0
		text: '+${pts}'
		color: item.color
		life: 0.7
		max_life: 0.7
		scale: if g.swipe_combo >= 2 { 2 } else { 1 }
		vy: -55.0
	}

	// Spawn two split halves flying apart
	g.halves << SlicedHalf{
		x: item.x - 8.0
		y: item.y
		vx: item.vx * 0.4 - 120.0 - rand.f64() * 40.0
		vy: item.vy * 0.5 - 60.0
		rotation: item.rotation
		rot_speed: -6.0
		radius: item.radius
		color: item.color
		item_type: item.item_type
		is_left: true
	}

	g.halves << SlicedHalf{
		x: item.x + 8.0
		y: item.y
		vx: item.vx * 0.4 + 120.0 + rand.f64() * 40.0
		vy: item.vy * 0.5 - 60.0
		rotation: item.rotation
		rot_speed: 6.0
		radius: item.radius
		color: item.color
		item_type: item.item_type
		is_left: false
	}

	// Splatter particles
	for _ in 0 .. 16 {
		ang := rand.f64() * math.pi * 2.0
		spd := 80.0 + rand.f64() * 130.0
		g.particles << Particle{
			x: item.x
			y: item.y
			vx: math.cos(ang) * spd
			vy: math.sin(ang) * spd
			color: item.color
			size: 3.0 + rand.f64() * 3.0
			life: 0.5 + rand.f64() * 0.3
			max_life: 0.8
		}
	}
}

pub fn (mut g BladeSlicerGame) update(dt f64) {
	if g.game_over {
		return
	}

	g.difficulty += dt * 0.015

	if g.is_frenzy {
		g.frenzy_timer -= dt
		if g.frenzy_timer <= 0.0 {
			g.is_frenzy = false
		}
	}

	// Spawn timer
	g.spawn_timer -= dt
	if g.spawn_timer <= 0.0 {
		g.spawn_timer = if g.is_frenzy {
			0.45 + rand.f64() * 0.3
		} else {
			(1.2 + rand.f64() * 0.8) / math.min(g.difficulty, 2.2)
		}
		g.spawn_wave()
	}

	gravity := if g.is_frenzy { 420.0 } else { 620.0 }

	// Update items
	mut keep_items := []SliceableItem{}
	for mut it in g.items {
		it.x += it.vx * dt
		it.y += it.vy * dt
		it.vy += gravity * dt
		it.rotation += it.rot_speed * dt

		// Check if fell off screen
		if it.y > 680.0 && it.vy > 0.0 {
			if !it.sliced && it.item_type != .bomb && !g.is_frenzy {
				g.lives--
				if g.lives <= 0 {
					g.game_over = true
				}
			}
			continue
		}
		if it.active {
			keep_items << it
		}
	}
	g.items = keep_items

	// Update halves
	mut keep_halves := []SlicedHalf{}
	for mut h in g.halves {
		h.life -= dt
		h.x += h.vx * dt
		h.y += h.vy * dt
		h.vy += gravity * 1.2 * dt
		h.rotation += h.rot_speed * dt

		if h.life > 0.0 && h.y < 700.0 {
			keep_halves << h
		}
	}
	g.halves = keep_halves

	// Update blade trail
	mut keep_trail := []TrailPoint{}
	for t in g.trail {
		new_life := t.life - dt
		if new_life > 0.0 {
			keep_trail << TrailPoint{
				x: t.x
				y: t.y
				life: new_life
			}
		}
	}
	g.trail = keep_trail

	// Update floating texts
	mut keep_texts := []FloatingText{}
	for mut ft in g.floating_texts {
		ft.life -= dt
		ft.y += ft.vy * dt
		if ft.life > 0.0 {
			keep_texts << ft
		}
	}
	g.floating_texts = keep_texts

	// Update particles
	mut keep_p := []Particle{}
	for mut p in g.particles {
		p.life -= dt
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 120.0 * dt
		if p.life > 0.0 {
			keep_p << p
		}
	}
	g.particles = keep_p
}
