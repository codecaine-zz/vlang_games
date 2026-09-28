module main

import math
import rand

pub enum MonsterType {
	goblin
	gold_gnome
	spiky_bomb
	armored_boss
	time_clock
}

pub struct Hole {
pub mut:
	x            f64
	y            f64
	w            f64 = 110.0
	h            f64 = 60.0
	active       bool
	m_type       MonsterType
	rise_progress f64 // 0.0 (hidden) to 1.0 (fully out)
	state        string = 'hidden' // 'hidden', 'rising', 'idle', 'hit', 'descending'
	timer        f64
	max_idle     f64
	hp           int = 1
	max_hp       int = 1
}

pub struct HammerEffect {
pub mut:
	x        f64
	y        f64
	angle    f64
	timer    f64
	active   bool
}

pub struct WhackMonsterGame {
pub mut:
	score         int
	high_score    int
	combo         int
	max_combo     int
	time_left     f64 = 45.0
	lives         int = 3
	game_over     bool
	monsters_whacked int

	holes         []Hole
	floating_texts []FloatingText
	particles     []Particle
	hammer        HammerEffect

	spawn_cooldown f64
	difficulty     f64 = 1.0
}

pub fn new_whack_monster_game() WhackMonsterGame {
	mut g := WhackMonsterGame{}
	g.reset()
	return g
}

pub fn (mut g WhackMonsterGame) reset() {
	g.score = 0
	g.combo = 0
	g.max_combo = 0
	g.time_left = 45.0
	g.lives = 3
	g.game_over = false
	g.monsters_whacked = 0
	g.difficulty = 1.0
	g.spawn_cooldown = 0.5

	g.holes = []Hole{cap: 9}
	g.floating_texts = []FloatingText{}
	g.particles = []Particle{}

	// 3x3 grid setup
	start_x := 180.0
	start_y := 160.0
	spacing_x := 180.0
	spacing_y := 125.0

	for row in 0 .. 3 {
		for col in 0 .. 3 {
			g.holes << Hole{
				x: start_x + f64(col) * spacing_x
				y: start_y + f64(row) * spacing_y
				active: false
				state: 'hidden'
			}
		}
	}
}

pub fn (mut g WhackMonsterGame) click_at(mx f64, my f64, mut sm SoundManager) {
	if g.game_over {
		return
	}

	// Trigger hammer visual swing
	g.hammer = HammerEffect{
		x: mx
		y: my
		angle: -45.0
		timer: 0.15
		active: true
	}

	mut hit_anything := false

	for i in 0 .. g.holes.len {
		mut h := &g.holes[i]
		if h.state == 'hidden' || h.state == 'descending' || h.state == 'hit' {
			continue
		}

		// Hitbox check
		hit_cx := h.x + h.w / 2.0
		hit_cy := h.y - h.rise_progress * 40.0 + 20.0
		dx := mx - hit_cx
		dy := my - hit_cy

		if math.abs(dx) <= 45.0 && math.abs(dy) <= 45.0 {
			hit_anything = true

			match h.m_type {
				.spiky_bomb {
					g.lives--
					g.combo = 0
					h.state = 'hit'
					h.timer = 0.2
					sm.play_explosion()

					g.floating_texts << FloatingText{
						x: hit_cx
						y: hit_cy - 20.0
						text: 'BOOM! -1 LIFE'
						color: col_red
						life: 1.0
						max_life: 1.0
						scale: 2
						vy: -60.0
					}

					for _ in 0 .. 20 {
						ang := rand.f64() * math.pi * 2.0
						spd := 80.0 + rand.f64() * 120.0
						g.particles << Particle{
							x: hit_cx
							y: hit_cy
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
				}
				.armored_boss {
					h.hp--
					sm.play_whack_impact(true)

					if h.hp <= 0 {
						h.state = 'hit'
						h.timer = 0.25
						g.combo++
						g.monsters_whacked++
						pts := 800 * (1 + g.combo / 5)
						g.score += pts

						g.floating_texts << FloatingText{
							x: hit_cx
							y: hit_cy - 20.0
							text: 'BOSS CRUSHED! +${pts}'
							color: col_orange
							life: 1.2
							max_life: 1.2
							scale: 2
							vy: -70.0
						}

						for _ in 0 .. 25 {
							ang := rand.f64() * math.pi * 2.0
							spd := 100.0 + rand.f64() * 140.0
							g.particles << Particle{
								x: hit_cx
								y: hit_cy
								vx: math.cos(ang) * spd
								vy: math.sin(ang) * spd
								color: col_orange
								size: 4.0
								life: 0.7
								max_life: 0.7
							}
						}
					} else {
						// Boss damage twitch
						g.floating_texts << FloatingText{
							x: hit_cx
							y: hit_cy - 15.0
							text: 'HIT! (${h.hp}/${h.max_hp})'
							color: col_yellow
							life: 0.5
							max_life: 0.5
							scale: 1
							vy: -50.0
						}
					}
				}
				.time_clock {
					h.state = 'hit'
					h.timer = 0.2
					g.time_left = math.min(g.time_left + 6.0, 60.0)
					sm.play_golden_frenzy()

					g.floating_texts << FloatingText{
						x: hit_cx
						y: hit_cy - 20.0
						text: '+6 SECONDS!'
						color: col_cyan
						life: 1.0
						max_life: 1.0
						scale: 2
						vy: -60.0
					}
				}
				.gold_gnome {
					h.state = 'hit'
					h.timer = 0.2
					g.combo++
					g.monsters_whacked++
					pts := 350 * (1 + g.combo / 4)
					g.score += pts
					sm.play_upgrade_bought()

					g.floating_texts << FloatingText{
						x: hit_cx
						y: hit_cy - 20.0
						text: '+${pts} GOLDEN!'
						color: col_gold
						life: 1.0
						max_life: 1.0
						scale: 2
						vy: -60.0
					}

					for _ in 0 .. 18 {
						ang := rand.f64() * math.pi * 2.0
						spd := 80.0 + rand.f64() * 100.0
						g.particles << Particle{
							x: hit_cx
							y: hit_cy
							vx: math.cos(ang) * spd
							vy: math.sin(ang) * spd
							color: col_gold
							size: 3.5
							life: 0.6
							max_life: 0.6
						}
					}
				}
				.goblin {
					h.state = 'hit'
					h.timer = 0.2
					g.combo++
					g.monsters_whacked++
					pts := 100 * (1 + g.combo / 5)
					g.score += pts
					sm.play_whack_impact(false)

					g.floating_texts << FloatingText{
						x: hit_cx
						y: hit_cy - 15.0
						text: '+${pts}'
						color: col_green
						life: 0.7
						max_life: 0.7
						scale: if g.combo > 4 { 2 } else { 1 }
						vy: -50.0
					}

					for _ in 0 .. 12 {
						ang := rand.f64() * math.pi * 2.0
						spd := 60.0 + rand.f64() * 90.0
						g.particles << Particle{
							x: hit_cx
							y: hit_cy
							vx: math.cos(ang) * spd
							vy: math.sin(ang) * spd
							color: col_green
							size: 3.0
							life: 0.5
							max_life: 0.5
						}
					}
				}
			}

			if g.combo > g.max_combo {
				g.max_combo = g.combo
			}
			break
		}
	}

	if !hit_anything {
		// Missed click resets combo streak
		if g.combo > 0 {
			g.combo = 0
		}
		sm.play_click_pop()
	}
}

pub fn (mut g WhackMonsterGame) spawn_monster() {
	mut available := []int{}
	for i in 0 .. g.holes.len {
		if g.holes[i].state == 'hidden' {
			available << i
		}
	}
	if available.len == 0 {
		return
	}

	idx := available[rand.int_in_range(0, available.len) or { 0 }]
	roll := rand.f64()

	mut m_type := MonsterType.goblin
	mut idle_time := 1.2 / g.difficulty
	mut hp := 1

	if roll < 0.12 {
		m_type = .time_clock
		idle_time = 1.0 / g.difficulty
	} else if roll < 0.28 {
		m_type = .spiky_bomb
		idle_time = 1.3 / g.difficulty
	} else if roll < 0.44 {
		m_type = .gold_gnome
		idle_time = 0.65 / g.difficulty
	} else if roll < 0.58 {
		m_type = .armored_boss
		idle_time = 2.0 / g.difficulty
		hp = 3
	}

	g.holes[idx].active = true
	g.holes[idx].m_type = m_type
	g.holes[idx].state = 'rising'
	g.holes[idx].rise_progress = 0.0
	g.holes[idx].timer = 0.0
	g.holes[idx].max_idle = idle_time
	g.holes[idx].hp = hp
	g.holes[idx].max_hp = hp
}

pub fn (mut g WhackMonsterGame) update(dt f64) {
	if g.game_over {
		return
	}

	g.time_left -= dt
	if g.time_left <= 0.0 {
		g.time_left = 0.0
		g.game_over = true
	}

	g.difficulty = 1.0 + (45.0 - g.time_left) * 0.02

	// Hammer anim
	if g.hammer.active {
		g.hammer.timer -= dt
		if g.hammer.timer <= 0.0 {
			g.hammer.active = false
		}
	}

	// Spawn logic
	g.spawn_cooldown -= dt
	if g.spawn_cooldown <= 0.0 {
		g.spawn_cooldown = (0.45 + rand.f64() * 0.4) / g.difficulty
		g.spawn_monster()
	}

	// Update holes
	for mut h in g.holes {
		match h.state {
			'rising' {
				h.rise_progress += dt * 6.0 * g.difficulty
				if h.rise_progress >= 1.0 {
					h.rise_progress = 1.0
					h.state = 'idle'
					h.timer = 0.0
				}
			}
			'idle' {
				h.timer += dt
				if h.timer >= h.max_idle {
					h.state = 'descending'
				}
			}
			'hit' {
				h.timer -= dt
				if h.timer <= 0.0 {
					h.state = 'descending'
				}
			}
			'descending' {
				h.rise_progress -= dt * 6.0 * g.difficulty
				if h.rise_progress <= 0.0 {
					h.rise_progress = 0.0
					h.state = 'hidden'
					h.active = false
				}
			}
			else {}
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
		p.vy += 80.0 * dt
		if p.life > 0.0 {
			keep_p << p
		}
	}
	g.particles = keep_p
}
