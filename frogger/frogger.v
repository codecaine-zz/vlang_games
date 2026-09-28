module main

import math

enum GameState {
	menu
	playing
	paused
	game_over
}

enum ObjectType {
	car
	truck
	race_car
	log_small
	log_medium
	log_large
	turtles
}

struct LaneObject {
mut:
	obj_type  ObjectType
	row       int
	x         f32
	width     f32
	speed     f32
	submerged bool
}

struct DockBay {
mut:
	x      f32
	filled bool
}

struct FroggerGame {
pub mut:
	state          GameState = .menu
	score          int
	high_score     int = 5000
	level          int = 1
	lives          int = 3
	timer          f32 = 30.0
	max_timer      f32 = 30.0
	frog_x         f32
	frog_y         f32
	frog_row       int = 12
	frog_facing    int // 0: Up, 1: Right, 2: Down, 3: Left
	hop_progress   f32 = 1.0
	hop_start_x    f32
	hop_start_y    f32
	hop_target_x   f32
	hop_target_y   f32
	is_hopping     bool
	hop_dur        f32 = 0.13
	idle_timer     f32
	docks          []DockBay
	objects        []LaneObject
	sound_mgr      SoundManager
	submerge_timer f32
	shake_trauma   f32
}

fn new_frogger_game() FroggerGame {
	mut g := FroggerGame{
		sound_mgr: new_sound_manager()
	}
	g.reset_game()
	return g
}

fn (mut g FroggerGame) reset_game() {
	g.score = 0
	g.level = 1
	g.lives = 3
	g.shake_trauma = 0.0
	g.reset_docks()
	g.reset_frog()
	g.init_objects()
	g.state = .playing
}

fn (mut g FroggerGame) reset_docks() {
	g.docks = [
		DockBay{ x: 80.0, filled: false },
		DockBay{ x: 240.0, filled: false },
		DockBay{ x: 400.0, filled: false },
		DockBay{ x: 560.0, filled: false },
		DockBay{ x: 720.0, filled: false },
	]
}

fn (mut g FroggerGame) reset_frog() {
	g.frog_row = 12
	g.frog_x = 400.0
	g.frog_y = f32(40 + 12 * 40 + 20)
	g.hop_start_x = g.frog_x
	g.hop_start_y = g.frog_y
	g.hop_target_x = g.frog_x
	g.hop_target_y = g.frog_y
	g.hop_progress = 1.0
	g.is_hopping = false
	g.frog_facing = 0
	g.timer = 30.0
}

fn (mut g FroggerGame) init_objects() {
	g.objects.clear()
	speed_mult := 1.0 + f32(g.level - 1) * 0.15

	// Highway Lanes (Rows 7..11)
	// Row 11: Slow Cars (right to left)
	for i in 0 .. 3 {
		g.objects << LaneObject{ obj_type: .car, row: 11, x: f32(i) * 280.0, width: 45.0, speed: -100.0 * speed_mult }
	}
	// Row 10: Race Cars (left to right)
	for i in 0 .. 2 {
		g.objects << LaneObject{ obj_type: .race_car, row: 10, x: f32(i) * 400.0, width: 40.0, speed: 200.0 * speed_mult }
	}
	// Row 9: Medium Cars (right to left)
	for i in 0 .. 3 {
		g.objects << LaneObject{ obj_type: .car, row: 9, x: f32(i) * 260.0, width: 45.0, speed: -140.0 * speed_mult }
	}
	// Row 8: Trucks (left to right)
	for i in 0 .. 2 {
		g.objects << LaneObject{ obj_type: .truck, row: 8, x: f32(i) * 420.0, width: 85.0, speed: 90.0 * speed_mult }
	}
	// Row 7: Fast Sports Cars (right to left)
	for i in 0 .. 2 {
		g.objects << LaneObject{ obj_type: .race_car, row: 7, x: f32(i) * 380.0, width: 40.0, speed: -220.0 * speed_mult }
	}

	// River Lanes (Rows 1..5)
	// Row 5: Medium Logs (left to right)
	for i in 0 .. 3 {
		g.objects << LaneObject{ obj_type: .log_medium, row: 5, x: f32(i) * 300.0, width: 120.0, speed: 110.0 * speed_mult }
	}
	// Row 4: Fast Large Logs (right to left)
	for i in 0 .. 2 {
		g.objects << LaneObject{ obj_type: .log_large, row: 4, x: f32(i) * 450.0, width: 180.0, speed: -160.0 * speed_mult }
	}
	// Row 3: Submerging Turtles (right to left)
	for i in 0 .. 3 {
		g.objects << LaneObject{ obj_type: .turtles, row: 3, x: f32(i) * 260.0, width: 75.0, speed: -120.0 * speed_mult }
	}
	// Row 2: Small Logs (left to right)
	for i in 0 .. 3 {
		g.objects << LaneObject{ obj_type: .log_small, row: 2, x: f32(i) * 280.0, width: 90.0, speed: 95.0 * speed_mult }
	}
	// Row 1: Submerging Turtles (right to left)
	for i in 0 .. 3 {
		g.objects << LaneObject{ obj_type: .turtles, row: 1, x: f32(i) * 270.0, width: 75.0, speed: -130.0 * speed_mult }
	}
}

fn (mut g FroggerGame) update(dt f32) {
	if g.state != .playing { return }

	if g.shake_trauma > 0.0 {
		g.shake_trauma = math.max(0.0, g.shake_trauma - dt * 2.2)
	}

	g.idle_timer += dt
	g.timer -= dt
	if g.timer <= 0 {
		g.handle_frog_death(false)
		return
	}

	// Interpolate Smooth Hop Movement
	if g.is_hopping {
		g.hop_progress += dt / g.hop_dur
		if g.hop_progress >= 1.0 {
			g.hop_progress = 1.0
			g.is_hopping = false
			g.frog_x = g.hop_target_x
			g.frog_y = g.hop_target_y
		} else {
			t := g.hop_progress
			smooth_t := t * t * (3.0 - 2.0 * t)
			g.frog_x = g.hop_start_x + (g.hop_target_x - g.hop_start_x) * smooth_t
			g.frog_y = g.hop_start_y + (g.hop_target_y - g.hop_start_y) * smooth_t
		}
	}

	g.submerge_timer += dt
	submerged := (int(g.submerge_timer * 2.0) % 4) == 3

	// Update Objects
	for mut obj in g.objects {
		obj.x += obj.speed * dt
		if obj.obj_type == .turtles && (obj.row == 1 || obj.row == 3) {
			obj.submerged = submerged
		}

		if obj.speed > 0 && obj.x > 850.0 {
			obj.x = -obj.width - 20.0
		} else if obj.speed < 0 && obj.x < -obj.width - 20.0 {
			obj.x = 850.0
		}
	}

	// Frog state check
	if g.frog_row >= 7 && g.frog_row <= 11 {
		// Highway: check car collision
		for obj in g.objects {
			if obj.row == g.frog_row {
				if g.frog_x + 12.0 > obj.x && g.frog_x - 12.0 < obj.x + obj.width {
					g.sound_mgr.play_squish_sound()
					g.handle_frog_death(true)
					return
				}
			}
		}
	} else if g.frog_row >= 1 && g.frog_row <= 5 {
		// River: must be on a floating log or turtle
		mut on_platform := false
		mut plat_speed := f32(0.0)

		for obj in g.objects {
			if obj.row == g.frog_row {
				if g.frog_x > obj.x - 5.0 && g.frog_x < obj.x + obj.width + 5.0 {
					if !(obj.obj_type == .turtles && obj.submerged) {
						on_platform = true
						plat_speed = obj.speed
						break
					}
				}
			}
		}

		if on_platform {
			g.frog_x += plat_speed * dt
			g.hop_target_x += plat_speed * dt
			g.hop_start_x += plat_speed * dt
			if g.frog_x < 10.0 || g.frog_x > 790.0 {
				g.handle_frog_death(false)
				return
			}
		} else if !g.is_hopping {
			// Drowned!
			g.sound_mgr.play_splash_sound()
			g.handle_frog_death(false)
			return
		}
	} else if g.frog_row == 0 && !g.is_hopping {
		// Docking Row: check if landing into an unfilled dock bay
		mut landed := false
		for mut d in g.docks {
			if !d.filled && math.abs(g.frog_x - d.x) < 30.0 {
				d.filled = true
				landed = true
				g.score += 500 + int(g.timer) * 20
				if g.score > g.high_score {
					g.high_score = g.score
				}
				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.18)
				g.sound_mgr.play_dock_sound()
				g.reset_frog()
				break
			}
		}

		if !landed {
			// Hit wall or already filled dock
			g.handle_frog_death(false)
			return
		}

		// Check if all docks filled -> next level!
		mut all_filled := true
		for d in g.docks {
			if !d.filled { all_filled = false; break }
		}
		if all_filled {
			g.level++
			g.score += 1000
			g.shake_trauma = math.min(1.0, g.shake_trauma + 0.35)
			g.reset_docks()
			g.init_objects()
			g.reset_frog()
		}
	}
}

fn (mut g FroggerGame) hop(dir_x int, dir_y int) {
	if g.state != .playing { return }

	// Set facing direction: 0 = Up, 1 = Right, 2 = Down, 3 = Left
	if dir_y < 0 {
		g.frog_facing = 0
	} else if dir_y > 0 {
		g.frog_facing = 2
	} else if dir_x > 0 {
		g.frog_facing = 1
	} else if dir_x < 0 {
		g.frog_facing = 3
	}

	g.hop_start_x = g.frog_x
	g.hop_start_y = g.frog_y
	mut next_x := g.frog_x
	mut next_y := g.frog_y

	if dir_y < 0 && g.frog_row > 0 {
		g.frog_row--
		next_y -= 40.0
		g.score += 10
		g.sound_mgr.play_hop_sound()
	} else if dir_y > 0 && g.frog_row < 12 {
		g.frog_row++
		next_y += 40.0
		g.score += 10
		g.sound_mgr.play_hop_sound()
	}

	if dir_x < 0 && g.frog_x > 30.0 {
		next_x -= 40.0
		g.sound_mgr.play_hop_sound()
	} else if dir_x > 0 && g.frog_x < 770.0 {
		next_x += 40.0
		g.sound_mgr.play_hop_sound()
	}

	g.hop_target_x = next_x
	g.hop_target_y = next_y
	g.hop_progress = 0.0
	g.is_hopping = true
}

fn (mut g FroggerGame) handle_frog_death(is_squish bool) {
	g.shake_trauma = math.min(1.0, g.shake_trauma + 0.55)
	if is_squish {
		g.sound_mgr.play_squish_sound()
	} else {
		g.sound_mgr.play_splash_sound()
	}
	g.lives--
	if g.lives <= 0 {
		g.state = .game_over
	} else {
		g.reset_frog()
	}
}
