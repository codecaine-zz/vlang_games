module main

import rand

pub const pyramid_rows = 7
pub const total_cubes = 28

pub enum HopDir {
	up_left
	up_right
	down_left
	down_right
}

pub enum QbertState {
	ready
	playing
	hopping
	cursing
	riding_disc
	level_cleared
	game_over
}

pub struct JumpingActor {
pub mut:
	r        int
	c        int
	from_r   int
	from_c   int
	anim_t   f64 = 1.0
	is_alive bool = true
}

pub struct Disc {
pub mut:
	r      int // anchor row
	c      int // anchor col
	side   int // -1 = left, +1 = right
	active bool = true
}

pub struct QbertGame {
pub mut:
	cubes        []int // 0 = base, 1 = target (28 cubes)
	state        QbertState = .ready
	score        int
	high_score   int = 12500
	lives        int = 3
	round_num    int = 1
	player       JumpingActor
	coily        JumpingActor
	coily_hatched bool
	red_ball     JumpingActor
	slick_sam    JumpingActor
	discs        []Disc
	curse_timer  f64
	enemy_timer  f64
	shake_trauma f32
}

pub fn get_cube_index(r int, c int) int {
	if r < 0 || r >= pyramid_rows || c < 0 || c > r {
		return -1
	}
	// Row starts: r=0 -> 0, r=1 -> 1, r=2 -> 3, r=3 -> 6, r=4 -> 10, r=5 -> 15, r=6 -> 21
	return (r * (r + 1)) / 2 + c
}

pub fn new_qbert_game() QbertGame {
	mut g := QbertGame{}
	g.reset_game()
	return g
}

pub fn (mut g QbertGame) reset_game() {
	g.score = 0
	g.lives = 3
	g.round_num = 1
	g.reset_round()
}

pub fn (mut g QbertGame) reset_round() {
	g.cubes = []int{len: total_cubes, init: 0}
	g.state = .playing
	g.curse_timer = 0.0
	g.enemy_timer = 0.0

	// Player at top (0,0)
	g.player = JumpingActor{
		r:        0
		c:        0
		from_r:   0
		from_c:   0
		anim_t:   1.0
		is_alive: true
	}
	g.cubes[0] = 1 // Step on apex

	// Coily egg
	g.coily = JumpingActor{
		r:        1
		c:        0
		from_r:   1
		from_c:   0
		anim_t:   1.0
		is_alive: false
	}
	g.coily_hatched = false

	// Red ball
	g.red_ball = JumpingActor{
		r:        1
		c:        1
		from_r:   1
		from_c:   1
		anim_t:   1.0
		is_alive: false
	}

	// Flying escape discs
	g.discs.clear()
	g.discs << Disc{ r: 2, c: -1, side: -1, active: true } // Left flank
	g.discs << Disc{ r: 4, c: 5, side: 1, active: true }   // Right flank
}

pub fn (mut g QbertGame) try_hop(dir HopDir) (bool, bool) {
	// Returns (valid_hop, hopped_on_disc)
	if g.state != .playing || g.player.anim_t < 1.0 {
		return false, false
	}

	mut nr := g.player.r
	mut nc := g.player.c

	match dir {
		.up_left {
			nr = g.player.r - 1
			nc = g.player.c - 1
		}
		.up_right {
			nr = g.player.r - 1
			nc = g.player.c
		}
		.down_left {
			nr = g.player.r + 1
			nc = g.player.c
		}
		.down_right {
			nr = g.player.r + 1
			nc = g.player.c + 1
		}
	}

	// Check if hopping onto an escape disc
	for mut disc in g.discs {
		if disc.active {
			if (disc.side == -1 && nr == disc.r - 1 && nc == -1) ||
			   (disc.side == 1 && nr == disc.r - 1 && nc == disc.r) {
				disc.active = false
				g.state = .riding_disc
				g.score += 500
				// Reset player to top
				g.player.r = 0
				g.player.c = 0
				g.player.from_r = 0
				g.player.from_c = 0
				g.player.anim_t = 1.0

				// If coily was chasing, coily dies
				if g.coily.is_alive {
					g.coily.is_alive = false
					g.score += 500
					g.shake_trauma += 0.35
					if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
				}
				g.state = .playing
				return true, true
			}
		}
	}

	// Check if inside pyramid
	idx := get_cube_index(nr, nc)
	if idx == -1 {
		// Fell off edge! Curse and lose life
		g.state = .cursing
		g.curse_timer = 1.2
		g.lives--
		g.shake_trauma += 0.50
		if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
		if g.lives <= 0 {
			g.state = .game_over
			if g.score > g.high_score {
				g.high_score = g.score
			}
		}
		return true, false
	}

	// Valid hop to pyramid cube
	g.player.from_r = g.player.r
	g.player.from_c = g.player.c
	g.player.r = nr
	g.player.c = nc
	g.player.anim_t = 0.0
	g.shake_trauma += 0.04
	if g.shake_trauma > 0.08 { g.shake_trauma = 0.08 }

	// Flip cube color
	if g.cubes[idx] == 0 {
		g.cubes[idx] = 1
		g.score += 25
	}

	// Check level clear
	mut all_flipped := true
	for val in g.cubes {
		if val == 0 {
			all_flipped = false
			break
		}
	}

	if all_flipped {
		g.state = .level_cleared
		g.score += 1000 + g.lives * 250
		g.shake_trauma += 0.30
		if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
		if g.score > g.high_score {
			g.high_score = g.score
		}
	}

	return true, false
}

pub struct QbertEvents {
pub mut:
	hopped    bool
	hit_enemy bool
	cleared   bool
}

pub fn (mut g QbertGame) update(dt f64) QbertEvents {
	mut ev := QbertEvents{}

	if g.shake_trauma > 0 {
		g.shake_trauma -= f32(2.0 * dt)
		if g.shake_trauma < 0 {
			g.shake_trauma = 0
		}
	}

	// Animate player hop
	if g.player.anim_t < 1.0 {
		g.player.anim_t = (g.player.anim_t + dt * 6.0)
		if g.player.anim_t >= 1.0 {
			g.player.anim_t = 1.0
		}
	}

	if g.state == .cursing {
		g.curse_timer -= dt
		if g.curse_timer <= 0 {
			if g.lives > 0 {
				g.player.r = 0
				g.player.c = 0
				g.player.from_r = 0
				g.player.from_c = 0
				g.player.anim_t = 1.0
				g.state = .playing
			} else {
				g.state = .game_over
			}
		}
		return ev
	}

	if g.state != .playing {
		return ev
	}

	// Enemies AI tick
	g.enemy_timer += dt
	if g.enemy_timer >= 1.2 {
		g.enemy_timer = 0.0

		// Spawn / Move Coily
		if !g.coily.is_alive {
			g.coily.r = 1
			g.coily.c = rand.intn(2) or { 0 }
			g.coily.from_r = g.coily.r
			g.coily.from_c = g.coily.c
			g.coily.anim_t = 1.0
			g.coily.is_alive = true
			g.coily_hatched = false
		} else if !g.coily_hatched {
			// Egg bounces down
			if g.coily.r < pyramid_rows - 1 {
				g.coily.from_r = g.coily.r
				g.coily.from_c = g.coily.c
				g.coily.r++
				g.coily.c += rand.intn(2) or { 0 }
				g.coily.anim_t = 0.0
			} else {
				// Hatches at bottom!
				g.coily_hatched = true
			}
		} else {
			// Hatched Snake tracks Q*bert
			mut dr := if g.player.r > g.coily.r { 1 } else if g.player.r < g.coily.r { -1 } else { 0 }
			mut dc := if g.player.c > g.coily.c { 1 } else if g.player.c < g.coily.c { -1 } else { 0 }
			if dr == 0 && dc == 0 {
				dr = 1
			}
			nr := g.coily.r + dr
			nc := g.coily.c + if dr > 0 && dc > 0 { 1 } else { 0 }
			if get_cube_index(nr, nc) != -1 {
				g.coily.from_r = g.coily.r
				g.coily.from_c = g.coily.c
				g.coily.r = nr
				g.coily.c = nc
				g.coily.anim_t = 0.0
			}
		}

		// Spawn / Move Red Ball
		if !g.red_ball.is_alive {
			g.red_ball.r = 1
			g.red_ball.c = rand.intn(2) or { 0 }
			g.red_ball.from_r = g.red_ball.r
			g.red_ball.from_c = g.red_ball.c
			g.red_ball.anim_t = 1.0
			g.red_ball.is_alive = true
		} else {
			if g.red_ball.r < pyramid_rows - 1 {
				g.red_ball.from_r = g.red_ball.r
				g.red_ball.from_c = g.red_ball.c
				g.red_ball.r++
				g.red_ball.c += rand.intn(2) or { 0 }
				g.red_ball.anim_t = 0.0
			} else {
				// Falls off bottom
				g.red_ball.is_alive = false
			}
		}
	}

	// Collision check between Q*bert and enemies
	if g.coily.is_alive && g.coily.r == g.player.r && g.coily.c == g.player.c {
		g.state = .cursing
		g.curse_timer = 1.2
		g.lives--
		g.shake_trauma += 0.65
		if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
		ev.hit_enemy = true
		if g.lives <= 0 {
			g.state = .game_over
			if g.score > g.high_score {
				g.high_score = g.score
			}
		}
	} else if g.red_ball.is_alive && g.red_ball.r == g.player.r && g.red_ball.c == g.player.c {
		g.state = .cursing
		g.curse_timer = 1.2
		g.lives--
		g.shake_trauma += 0.65
		if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
		ev.hit_enemy = true
		if g.lives <= 0 {
			g.state = .game_over
			if g.score > g.high_score {
				g.high_score = g.score
			}
		}
	}

	return ev
}
