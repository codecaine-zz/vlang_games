module main

import math
import rand

pub const world_w = 480
pub const world_h = 680
pub const ground_height = 90.0
pub const pipe_width = 65.0
pub const pipe_gap = 135.0
pub const bird_width = 34.0
pub const bird_height = 24.0

pub enum GameState {
	ready
	playing
	dead
	game_over
}

pub struct Pipe {
pub mut:
	x      f64
	top_h  f64
	passed bool
}

pub struct Bird {
pub mut:
	x          f64  = 110.0
	y          f64  = 300.0
	vy         f64
	angle      f64
	wing_frame int
	wing_timer f64
	alive      bool = true
}

pub struct FlappyGame {
pub mut:
	state          GameState = .ready
	bird           Bird
	pipes          []Pipe
	score          int
	best_score     int = 24
	scroll_x       f64
	pipe_speed     f64 = 185.0
	pipe_spawn_x   f64 = 550.0
	last_pipe_x    f64
	dead_timer     f64
}

pub fn new_flappy_game() FlappyGame {
	mut g := FlappyGame{}
	g.reset_game()
	return g
}

pub fn (mut g FlappyGame) reset_game() {
	g.state = .ready
	g.bird = Bird{
		x:          110.0
		y:          (f64(world_h) - ground_height) / 2.0
		vy:         0.0
		angle:      0.0
		wing_frame: 0
		wing_timer: 0.0
		alive:      true
	}
	g.pipes.clear()
	g.score = 0
	g.scroll_x = 0.0
	g.dead_timer = 0.0

	// Pre-spawn initial pipes
	mut px := g.pipe_spawn_x
	for _ in 0 .. 3 {
		top_h := 80.0 + f64(rand.intn(220) or { 110 })
		g.pipes << Pipe{
			x:      px
			top_h:  top_h
			passed: false
		}
		px += 230.0
	}
	g.last_pipe_x = px - 230.0
}

pub fn (mut g FlappyGame) flap() bool {
	if g.state == .ready {
		g.state = .playing
	}
	if g.state == .playing && g.bird.alive {
		g.bird.vy = -340.0
		g.bird.angle = -0.45 // tilt upwards
		g.bird.wing_frame = (g.bird.wing_frame + 1) % 3
		return true
	}
	return false
}

pub struct FlappyEvents {
pub mut:
	scored      bool
	hit_pipe    bool
	hit_ground  bool
}

pub fn (mut g FlappyGame) update(dt f64) FlappyEvents {
	mut ev := FlappyEvents{}

	// Scroll ground and clouds
	if g.state == .ready || g.state == .playing {
		g.scroll_x += g.pipe_speed * dt
	}

	// Bird hover bobbing in ready state
	if g.state == .ready {
		g.bird.y = (f64(world_h) - ground_height) / 2.0 + math.sin(g.scroll_x * 0.05) * 8.0
		g.bird.wing_timer += dt
		if g.bird.wing_timer >= 0.12 {
			g.bird.wing_timer = 0.0
			g.bird.wing_frame = (g.bird.wing_frame + 1) % 3
		}
		return ev
	}

	// Bird physics in playing & dead states
	if g.state == .playing || g.state == .dead {
		g.bird.vy += 960.0 * dt // gravity
		g.bird.y += g.bird.vy * dt

		// Rotational pitch dynamics
		if g.bird.vy < 0 {
			g.bird.angle = -0.45
		} else {
			g.bird.angle = math.min(1.2, g.bird.angle + 2.8 * dt)
		}

		// Animated wing flapping
		if g.bird.alive {
			g.bird.wing_timer += dt
			if g.bird.wing_timer >= 0.09 {
				g.bird.wing_timer = 0.0
				g.bird.wing_frame = (g.bird.wing_frame + 1) % 3
			}
		}
	}

	// Check ground collision
	ground_y := f64(world_h) - ground_height
	if g.bird.y + bird_height / 2.0 >= ground_y {
		g.bird.y = ground_y - bird_height / 2.0
		g.bird.vy = 0.0
		if g.state == .playing {
			g.state = .game_over
			g.bird.alive = false
			ev.hit_ground = true
			if g.score > g.best_score {
				g.best_score = g.score
			}
		} else if g.state == .dead {
			g.state = .game_over
		}
		return ev
	}

	// Playing state: update pipes and collisions
	if g.state == .playing {
		// Ceil collision
		if g.bird.y - bird_height / 2.0 <= 0.0 {
			g.bird.y = bird_height / 2.0
			g.bird.vy = 0.0
		}

		// Update and move pipes
		mut new_pipes := []Pipe{cap: g.pipes.len}
		for mut pipe in g.pipes {
			pipe.x -= g.pipe_speed * dt

			// Check score passing
			if !pipe.passed && pipe.x + pipe_width < g.bird.x {
				pipe.passed = true
				g.score++
				ev.scored = true
			}

			// Keep on-screen pipes
			if pipe.x + pipe_width > -50.0 {
				new_pipes << pipe
			}
		}
		g.pipes = new_pipes.clone()

		// Spawn new pipes as old ones scroll off
		if g.pipes.len > 0 {
			last_p := g.pipes[g.pipes.len - 1]
			if last_p.x < f64(world_w) + 50.0 {
				top_h := 80.0 + f64(rand.intn(220) or { 110 })
				g.pipes << Pipe{
					x:      last_p.x + 230.0
					top_h:  top_h
					passed: false
				}
			}
		}

		// Check pipe collisions
		bird_left := g.bird.x - bird_width * 0.4
		bird_right := g.bird.x + bird_width * 0.4
		bird_top := g.bird.y - bird_height * 0.4
		bird_bot := g.bird.y + bird_height * 0.4

		for pipe in g.pipes {
			if bird_right >= pipe.x && bird_left <= pipe.x + pipe_width {
				// Inside pipe horizontal slice
				if bird_top <= pipe.top_h || bird_bot >= pipe.top_h + pipe_gap {
					// Hit pipe!
					g.state = .dead
					g.bird.alive = false
					g.bird.vy = -180.0
					ev.hit_pipe = true
					if g.score > g.best_score {
						g.best_score = g.score
					}
					return ev
				}
			}
		}
	}

	return ev
}

pub enum Medal {
	none
	bronze
	silver
	gold
	platinum
}

pub fn (g &FlappyGame) get_medal() Medal {
	if g.score >= 50 {
		return .platinum
	} else if g.score >= 30 {
		return .gold
	} else if g.score >= 20 {
		return .silver
	} else if g.score >= 10 {
		return .bronze
	}
	return .none
}
