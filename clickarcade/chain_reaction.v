module main

import math
import rand

pub enum BallType {
	standard
	gold
	super_nova
}

pub struct AtomBall {
pub mut:
	x          f64
	y          f64
	vx         f64
	vy         f64
	radius     f64
	ball_type  BallType
	color      Color
	active     bool = true
}

pub struct Shockwave {
pub mut:
	x         f64
	y         f64
	radius    f64
	max_radius f64
	growth_spd f64
	life      f64
	max_life  f64
	color     Color
	active    bool
	is_super  bool
}

pub struct ChainReactionGame {
pub mut:
	level            int = 1
	score            int
	high_score       int
	total_popped     int
	stage_target     int = 6
	stage_total_balls int = 25

	balls            []AtomBall
	waves            []Shockwave
	particles        []Particle
	floating_texts   []FloatingText

	state            string = 'ready' // 'ready', 'reacting', 'cleared', 'failed'
	clicks_left      int = 1
	current_chain    int
	max_chain        int
	time_in_state    f64

	// Arena boundaries
	arena_x          int = 40
	arena_y          int = 60
	arena_w          int = 800
	arena_h          int = 500
}

pub fn new_chain_reaction_game() ChainReactionGame {
	mut g := ChainReactionGame{}
	g.start_level(1)
	return g
}

pub fn (mut g ChainReactionGame) start_level(lvl int) {
	g.level = lvl
	g.clicks_left = 1
	g.current_chain = 0
	g.state = 'ready'
	g.time_in_state = 0.0

	// Dynamic difficulty
	g.stage_total_balls = 20 + lvl * 6
	if g.stage_total_balls > 85 {
		g.stage_total_balls = 85
	}

	g.stage_target = int(f64(g.stage_total_balls) * math.min(0.25 + f64(lvl) * 0.05, 0.82))

	g.balls = []AtomBall{cap: g.stage_total_balls}
	g.waves = []Shockwave{}
	g.particles = []Particle{}
	g.floating_texts = []FloatingText{}

	ball_colors := [
		col_cyan,
		col_pink,
		col_green,
		col_purple,
		col_orange,
		col_yellow,
	]

	for i in 0 .. g.stage_total_balls {
		ang := rand.f64() * math.pi * 2.0
		spd := 70.0 + rand.f64() * 70.0 + f64(lvl) * 4.0

		mut b_type := BallType.standard
		mut b_col := ball_colors[i % ball_colors.len]
		mut rad := 9.0

		roll := rand.f64()
		if roll < 0.10 {
			b_type = .gold
			b_col = col_gold
			rad = 11.0
		} else if roll < 0.18 {
			b_type = .super_nova
			b_col = col_white
			rad = 12.0
		}

		g.balls << AtomBall{
			x: f64(g.arena_x) + 20.0 + rand.f64() * f64(g.arena_w - 40)
			y: f64(g.arena_y) + 20.0 + rand.f64() * f64(g.arena_h - 40)
			vx: math.cos(ang) * spd
			vy: math.sin(ang) * spd
			radius: rad
			ball_type: b_type
			color: b_col
			active: true
		}
	}
}

pub fn (mut g ChainReactionGame) click_trigger(mx f64, my f64, mut sm SoundManager) {
	if g.state != 'ready' || g.clicks_left <= 0 {
		return
	}
	if mx < f64(g.arena_x) || mx > f64(g.arena_x + g.arena_w) || my < f64(g.arena_y) || my > f64(g.arena_y + g.arena_h) {
		return
	}

	g.clicks_left--
	g.state = 'reacting'
	g.current_chain = 0

	// Spawn initial catalyst shockwave
	g.waves << Shockwave{
		x: mx
		y: my
		radius: 4.0
		max_radius: 58.0
		growth_spd: 90.0
		life: 2.8
		max_life: 2.8
		color: col_cyan
		active: true
		is_super: false
	}

	sm.play_chain_pop(0)

	// Ripple sparkles
	for _ in 0 .. 16 {
		ang := rand.f64() * math.pi * 2.0
		spd := 50.0 + rand.f64() * 80.0
		g.particles << Particle{
			x: mx
			y: my
			vx: math.cos(ang) * spd
			vy: math.sin(ang) * spd
			color: col_cyan
			size: 3.0
			life: 0.6
			max_life: 0.6
		}
	}
}

pub fn (mut g ChainReactionGame) trigger_ball_pop(ball_idx int, mut sm SoundManager) {
	if !g.balls[ball_idx].active {
		return
	}
	g.balls[ball_idx].active = false
	g.total_popped++
	g.current_chain++
	if g.current_chain > g.max_chain {
		g.max_chain = g.current_chain
	}

	b := g.balls[ball_idx]
	pts := if b.ball_type == .gold {
		500 * g.current_chain
	} else if b.ball_type == .super_nova {
		300 * g.current_chain
	} else {
		100 * g.current_chain
	}
	g.score += pts

	sm.play_chain_pop(g.current_chain)

	// Spawn expanding wave
	is_super := b.ball_type == .super_nova
	max_rad := if b.ball_type == .gold { 75.0 } else if is_super { 85.0 } else { 52.0 }

	g.waves << Shockwave{
		x: b.x
		y: b.y
		radius: 4.0
		max_radius: max_rad
		growth_spd: 85.0
		life: 2.4
		max_life: 2.4
		color: b.color
		active: true
		is_super: is_super
	}

	// Floating score text
	g.floating_texts << FloatingText{
		x: b.x
		y: b.y - 12.0
		text: '+${pts}'
		color: b.color
		life: 0.8
		max_life: 0.8
		scale: if g.current_chain > 5 { 2 } else { 1 }
		vy: -50.0
	}

	// Burst particles
	num_p := if is_super { 22 } else { 12 }
	for _ in 0 .. num_p {
		ang := rand.f64() * math.pi * 2.0
		spd := 70.0 + rand.f64() * 110.0
		g.particles << Particle{
			x: b.x
			y: b.y
			vx: math.cos(ang) * spd
			vy: math.sin(ang) * spd
			color: b.color
			size: 3.0 + rand.f64() * 3.0
			life: 0.5 + rand.f64() * 0.3
			max_life: 0.8
		}
	}
}

pub fn (mut g ChainReactionGame) update(dt f64, mut sm SoundManager) {
	g.time_in_state += dt

	// Update bouncing balls
	for mut b in g.balls {
		if !b.active {
			continue
		}
		b.x += b.vx * dt
		b.y += b.vy * dt

		// Wall bounce
		left := f64(g.arena_x) + b.radius
		right := f64(g.arena_x + g.arena_w) - b.radius
		top := f64(g.arena_y) + b.radius
		bottom := f64(g.arena_y + g.arena_h) - b.radius

		if b.x < left {
			b.x = left
			b.vx = math.abs(b.vx)
		} else if b.x > right {
			b.x = right
			b.vx = -math.abs(b.vx)
		}

		if b.y < top {
			b.y = top
			b.vy = math.abs(b.vy)
		} else if b.y > bottom {
			b.y = bottom
			b.vy = -math.abs(b.vy)
		}
	}

	// Update shockwaves & check collisions
	mut keep_waves := []Shockwave{}
	for mut w in g.waves {
		if !w.active {
			continue
		}
		w.life -= dt

		// Grow to max_radius, then stay or slightly shrink before disappearing
		if w.radius < w.max_radius {
			w.radius = math.min(w.radius + w.growth_spd * dt, w.max_radius)
		}

		// Collision with active balls
		for i in 0 .. g.balls.len {
			if !g.balls[i].active {
				continue
			}
			dx := g.balls[i].x - w.x
			dy := g.balls[i].y - w.y
			dist_sq := dx * dx + dy * dy
			thresh := w.radius + g.balls[i].radius
			if dist_sq <= thresh * thresh {
				g.trigger_ball_pop(i, mut sm)
			}
		}

		if w.life > 0.0 {
			keep_waves << w
		}
	}
	g.waves = keep_waves

	// Check state transition when reacting
	if g.state == 'reacting' {
		if g.waves.len == 0 {
			// All chain reactions have completed!
			if g.total_popped >= g.stage_target {
				g.state = 'cleared'
				g.time_in_state = 0.0
				sm.play_victory()
			} else {
				g.state = 'failed'
				g.time_in_state = 0.0
				sm.play_explosion()
			}
		}
	}

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
		if p.life > 0.0 {
			keep_p << p
		}
	}
	g.particles = keep_p
}
