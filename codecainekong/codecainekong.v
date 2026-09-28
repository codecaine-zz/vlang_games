module main

import math
import rand

enum GameState {
	menu
	playing
	paused
	game_over
	victory
}

enum BarrelType {
	normal
	blue
}

struct Girder {
	x1 f32
	y1 f32
	x2 f32
	y2 f32
}

struct Ladder {
	x     f32
	top_y f32
	bot_y f32
}

struct Barrel {
mut:
	x           f32
	y           f32
	vx          f32
	vy          f32
	b_type      BarrelType = .normal
	is_climbing bool
	active      bool       = true
	jumped_over bool
}

struct Fireball {
mut:
	x           f32
	y           f32
	vx          f32
	vy          f32
	is_climbing bool
	active      bool = true
	anim_timer  f32
}

struct HammerItem {
mut:
	x      f32
	y      f32
	active bool = true
}

struct DonkeyKongGame {
mut:
	state         GameState = .menu
	score         int
	high_score    int = 5000
	stage         int = 1
	lives         int = 3
	player_x      f32 = 100.0
	player_y      f32 = 520.0
	player_vx     f32
	player_vy     f32
	is_grounded   bool
	is_climbing   bool
	hammer_timer  f32
	girders       []Girder
	ladders       []Ladder
	barrels       []Barrel
	fireballs     []Fireball
	hammers       []HammerItem
	sound_mgr     SoundManager
	barrel_timer  f32
	barrel_count  int
	dk_anim_timer f32
	oil_ignite    f32
	shake_trauma  f32
	key_left      bool
	key_right     bool
	key_up        bool
	key_down      bool
	key_jump      bool
}

fn new_donkeykong_game() DonkeyKongGame {
	mut g := DonkeyKongGame{
		sound_mgr: new_sound_manager()
	}
	g.reset_game()
	return g
}

fn (mut g DonkeyKongGame) reset_game() {
	g.score = 0
	g.stage = 1
	g.lives = 3
	g.shake_trauma = 0.0
	g.init_stage()
	g.state = .playing
}

fn get_girder_downhill_speed(g_line Girder, b_type BarrelType) f32 {
	spd := if b_type == .blue { f32(160.0) } else { f32(140.0) }
	dx := g_line.x2 - g_line.x1
	dy := g_line.y2 - g_line.y1
	if dx == 0 { return spd }
	slope := dy / dx
	if slope > 0 {
		return spd
	} else if slope < 0 {
		return -spd
	}
	return spd
}

fn (mut g DonkeyKongGame) init_stage() {
	g.girders = [
		// Tier 1 (Bottom): slanted down to left (x=750 y=520 -> x=50 y=540)
		Girder{ x1: 750.0, y1: 520.0, x2: 50.0, y2: 540.0 },
		// Tier 2: slanted down to left (x=740 y=420 -> x=70 y=440)
		Girder{ x1: 740.0, y1: 420.0, x2: 70.0, y2: 440.0 },
		// Tier 3: slanted down to right (x=60 y=320 -> x=730 y=340)
		Girder{ x1: 60.0, y1: 320.0, x2: 730.0, y2: 340.0 },
		// Tier 4: slanted down to left (x=740 y=220 -> x=70 y=240)
		Girder{ x1: 740.0, y1: 220.0, x2: 70.0, y2: 240.0 },
		// Tier 5 (Top DK Platform): flat (x=50 y=140 -> x=450 y=140)
		Girder{ x1: 50.0, y1: 140.0, x2: 450.0, y2: 140.0 },
		// Top Pauline Platform
		Girder{ x1: 300.0, y1: 90.0, x2: 420.0, y2: 90.0 },
	]

	g.ladders = [
		Ladder{ x: 680.0, top_y: 422.0, bot_y: 522.0 },
		Ladder{ x: 120.0, top_y: 322.0, bot_y: 438.0 },
		Ladder{ x: 660.0, top_y: 222.0, bot_y: 338.0 },
		Ladder{ x: 150.0, top_y: 140.0, bot_y: 238.0 },
		Ladder{ x: 360.0, top_y: 90.0, bot_y: 140.0 },
	]

	g.hammers = [
		HammerItem{ x: 220.0, y: 410.0, active: true },
		HammerItem{ x: 580.0, y: 210.0, active: true },
	]

	g.barrels.clear()
	g.fireballs.clear()
	g.player_x = 100.0
	g.player_y = 520.0
	g.player_vx = 0.0
	g.player_vy = 0.0
	g.is_grounded = true
	g.is_climbing = false
	g.hammer_timer = 0.0
	g.barrel_timer = 0.0
	g.barrel_count = 0
	g.dk_anim_timer = 0.0
	g.oil_ignite = 0.0
}

fn (mut g DonkeyKongGame) update(dt f32) {
	if g.state != .playing { return }

	if g.shake_trauma > 0.0 {
		g.shake_trauma -= dt * 2.2
		if g.shake_trauma < 0.0 {
			g.shake_trauma = 0.0
		}
	}

	if g.hammer_timer > 0 {
		g.hammer_timer -= dt
	}
	if g.dk_anim_timer > 0 {
		g.dk_anim_timer -= dt
	}
	if g.oil_ignite > 0 {
		g.oil_ignite -= dt
	}

	// 1. Spawn Barrels from DK at top
	g.barrel_timer += dt
	if g.barrel_timer > 2.8 {
		g.barrel_timer = 0.0
		g.barrel_count++
		b_type := if g.barrel_count % 3 == 0 { BarrelType.blue } else { BarrelType.normal }
		speed := if b_type == .blue { f32(160.0) } else { f32(140.0) }
		g.barrels << Barrel{
			x: 160.0
			y: 126.0
			vx: speed
			vy: 0.0
			b_type: b_type
			active: true
		}
		g.dk_anim_timer = 0.6
		g.shake_trauma += 0.18
		if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
		g.sound_mgr.play_stomp_sound()
	}

	// 2. Player Input & Physics
	// Arcade Jumpman jump strength (-220.0, max height ~32px): cannot reach upper platform without ladder!
	if !g.is_climbing {
		g.player_vx = 0.0
		if g.key_left { g.player_vx = -140.0 }
		if g.key_right { g.player_vx = 140.0 }

		if g.key_jump && g.is_grounded {
			g.player_vy = -220.0
			g.is_grounded = false
			g.sound_mgr.play_jump_sound()
		}

		// Apply Gravity
		if !g.is_grounded {
			g.player_vy += 750.0 * dt
		}
	} else {
		// Climbing ladder (cannot climb while holding hammer)
		g.player_vx = 0.0
		g.player_vy = 0.0
		if g.key_up { g.player_vy = -120.0 }
		if g.key_down { g.player_vy = 120.0 }
	}

	// Update Player Position
	g.player_x += g.player_vx * dt
	g.player_y += g.player_vy * dt

	// Screen Bounds
	if g.player_x < 60 { g.player_x = 60 }
	if g.player_x > 740 { g.player_x = 740 }

	// Check Ladder Grab (Disallowed while holding hammer)
	mut near_ladder := false
	for l in g.ladders {
		if math.abs(g.player_x - l.x) < 14.0 && g.player_y >= l.top_y - 12.0 && g.player_y <= l.bot_y + 12.0 {
			near_ladder = true
			if (g.key_up || g.key_down) && !g.is_climbing && g.hammer_timer <= 0 {
				g.is_climbing = true
				g.player_x = l.x
			}
			break
		}
	}
	if !near_ladder {
		g.is_climbing = false
	}

	// Check Girder Platform Collisions
	if !g.is_climbing {
		g.is_grounded = false
		for g_line in g.girders {
			if g.player_x >= math.min(g_line.x1, g_line.x2) - 8.0 && g.player_x <= math.max(g_line.x1, g_line.x2) + 8.0 {
				t := (g.player_x - g_line.x1) / (g_line.x2 - g_line.x1)
				floor_y := g_line.y1 + t * (g_line.y2 - g_line.y1)

				// Only land if player is dropping onto floor near floor_y
				if g.player_y >= floor_y - 22.0 && g.player_y <= floor_y + 8.0 && g.player_vy >= 0 {
					g.player_y = floor_y - 14.0
					g.player_vy = 0.0
					g.is_grounded = true
					break
				}
			}
		}
	}

	// Check Hammer Pickups
	if g.hammer_timer <= 0 {
		for mut h in g.hammers {
			if h.active && math.abs(g.player_x - h.x) < 18.0 && math.abs(g.player_y - h.y) < 18.0 {
				h.active = false
				g.hammer_timer = 8.0
				g.sound_mgr.play_hammer_smash_sound()
				break
			}
		}
	}

	// 3. Update Barrels (Arcade physics: roll downhill, drop vertically off platform edges)
	for mut b in g.barrels {
		if !b.active { continue }

		if !b.is_climbing {
			// Apply downward gravity
			b.vy += 700.0 * dt
			if b.vy < 0 { b.vy = 0.0 }

			// Check girder landings (iterating from top tier to bottom tier)
			mut grounded := false
			tier_order := [4, 3, 2, 1, 0]
			for tier_idx in tier_order {
				g_line := g.girders[tier_idx]
				min_x := math.min(g_line.x1, g_line.x2)
				max_x := math.max(g_line.x1, g_line.x2)

				// A girder can only support a barrel if barrel x is strictly within the girder span (+2px margin)
				if b.x >= min_x - 2.0 && b.x <= max_x + 2.0 {
					clamp_x := math.max(min_x, math.min(max_x, b.x))
					t := (clamp_x - g_line.x1) / (g_line.x2 - g_line.x1)
					floor_y := g_line.y1 + t * (g_line.y2 - g_line.y1)

					// If falling onto this girder floor from above
					if b.y >= floor_y - 18.0 && b.y <= floor_y + 16.0 && b.vy >= 0 {
						b.y = floor_y - 10.0
						b.vy = 0.0
						grounded = true

						// Roll strictly downhill based on girder slope
						b.vx = get_girder_downhill_speed(g_line, b.b_type)
						break
					}
				}
			}

			// If falling off an edge (not grounded), zero horizontal velocity so it drops straight down vertically
			if !grounded {
				b.vx = 0.0
			}

			// Move barrel
			b.x += b.vx * dt
			b.y += b.vy * dt

			// Screen bounds check for barrels (allow wide bounds so barrels reach edge drop openings)
			if b.x < 35.0 { b.x = 35.0 }
			if b.x > 765.0 { b.x = 765.0 }

			// Chance to roll down ladder when passing over one
			if grounded {
				for l in g.ladders {
					if math.abs(b.x - l.x) < 8.0 && b.y >= l.top_y - 20.0 && b.y <= l.top_y + 15.0 {
						chance := if b.b_type == .blue { 60 } else { 35 }
						if (rand.intn(100) or { 0 }) < chance {
							b.is_climbing = true
							b.vy = 160.0
							b.vx = 0.0
							b.x = l.x
							break
						}
					}
				}
			}
		} else {
			// Moving down ladder (vy strictly positive downward)
			if b.vy <= 0 { b.vy = 160.0 }
			b.y += b.vy * dt

			for l in g.ladders {
				// Only match the specific ladder the barrel is currently climbing (matching X coordinate)
				if math.abs(b.x - l.x) < 4.0 && b.y >= l.bot_y - 5.0 {
					b.is_climbing = false
					b.vy = 0.0

					// Find lower girder tier at ladder bottom and roll downhill
					mut rolled := false
					tier_order := [4, 3, 2, 1, 0]
					for tier_idx in tier_order {
						g_line := g.girders[tier_idx]
						min_x := math.min(g_line.x1, g_line.x2)
						max_x := math.max(g_line.x1, g_line.x2)
						if b.x >= min_x - 10.0 && b.x <= max_x + 10.0 {
							clamp_x := math.max(min_x, math.min(max_x, b.x))
							t := (clamp_x - g_line.x1) / (g_line.x2 - g_line.x1)
							floor_y := g_line.y1 + t * (g_line.y2 - g_line.y1)
							if math.abs(b.y - (floor_y - 10.0)) < 25.0 {
								b.y = floor_y - 10.0
								b.vx = get_girder_downhill_speed(g_line, b.b_type)
								rolled = true
								break
							}
						}
					}
					if !rolled {
						b.vx = -140.0
					}
					break
				}
			}
		}

		// Reaching Oil Drum at bottom left (x: 80, y: 520)
		if b.x <= 95.0 && b.y >= 495.0 {
			b.active = false
			g.oil_ignite = 0.6
			// Blue barrel or 50% chance spawns a Fireball from Oil Drum
			if b.b_type == .blue || g.fireballs.len < 3 {
				g.fireballs << Fireball{
					x: 85.0
					y: 505.0
					vx: 80.0
					vy: 0.0
					active: true
				}
			}
			continue
		}

		// Deactivate if fallen off bottom of screen
		if b.y > 580.0 {
			b.active = false
			continue
		}

		// Score points for jumping over barrel
		if !g.is_grounded && !g.is_climbing && !b.jumped_over {
			if math.abs(g.player_x - b.x) < 18.0 && g.player_y < b.y - 8.0 && g.player_y > b.y - 45.0 {
				b.jumped_over = true
				g.score += 100
			}
		}

		// Check collision with Player
		dist := f32(math.abs(g.player_x - b.x) + math.abs(g.player_y - b.y))
		if dist < 20.0 {
			if g.hammer_timer > 0 {
				b.active = false
				g.score += 500
				g.shake_trauma += 0.35
				if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
				g.sound_mgr.play_hammer_smash_sound()
			} else {
				g.handle_player_death()
				return
			}
		}
	}
	g.barrels = g.barrels.filter(it.active)

	// 4. Update Fireballs (Arcade Firebug enemy logic)
	for mut f in g.fireballs {
		if !f.active { continue }
		f.anim_timer += dt

		if !f.is_climbing {
			f.x += f.vx * dt

			// Follow girder slope
			for g_line in g.girders {
				if f.x >= math.min(g_line.x1, g_line.x2) && f.x <= math.max(g_line.x1, g_line.x2) {
					t := (f.x - g_line.x1) / (g_line.x2 - g_line.x1)
					floor_y := g_line.y1 + t * (g_line.y2 - g_line.y1)
					if f.y >= floor_y - 20.0 && f.y <= floor_y + 15.0 {
						f.y = floor_y - 14.0
						if f.x <= 70.0 || f.x >= 730.0 {
							f.vx = -f.vx
						}
						break
					}
				}
			}

			// Random decision at ladders to climb UP or DOWN
			for l in g.ladders {
				if math.abs(f.x - l.x) < 10.0 {
					// Check near bottom -> climb up
					if f.y >= l.bot_y - 12.0 && f.y <= l.bot_y + 6.0 {
						if (rand.intn(100) or { 0 }) < 35 {
							f.is_climbing = true
							f.vy = -75.0
							f.x = l.x
							break
						}
					}
					// Check near top -> climb down
					if f.y >= l.top_y - 6.0 && f.y <= l.top_y + 12.0 {
						if (rand.intn(100) or { 0 }) < 35 {
							f.is_climbing = true
							f.vy = 75.0
							f.x = l.x
							break
						}
					}
				}
			}
		} else {
			// Fireball climbing ladder
			f.y += f.vy * dt
			for l in g.ladders {
				if (f.vy < 0 && f.y <= l.top_y - 5.0) || (f.vy > 0 && f.y >= l.bot_y - 5.0) {
					f.is_climbing = false
					dir := if (rand.intn(100) or { 0 }) < 50 { f32(80.0) } else { f32(-80.0) }
					f.vx = dir
					f.vy = 0.0
					break
				}
			}
		}

		// Collision with Player
		dist := f32(math.abs(g.player_x - f.x) + math.abs(g.player_y - f.y))
		if dist < 20.0 {
			if g.hammer_timer > 0 {
				f.active = false
				g.score += 500
				g.shake_trauma += 0.35
				if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
				g.sound_mgr.play_hammer_smash_sound()
			} else {
				g.handle_player_death()
				return
			}
		}
	}
	g.fireballs = g.fireballs.filter(it.active)

	// 5. Check Rescue Victory at top (Pauline Platform X 300..420, Y 90)
	if g.player_y <= 100.0 && g.player_x >= 300.0 && g.player_x <= 420.0 {
		g.state = .victory
		g.score += 1500
		if g.score > g.high_score { g.high_score = g.score }
		g.sound_mgr.play_victory_sound()
	}
}

fn (mut g DonkeyKongGame) handle_player_death() {
	g.lives--
	g.shake_trauma += 0.65
	if g.shake_trauma > 1.0 { g.shake_trauma = 1.0 }
	g.sound_mgr.play_death_sound()
	if g.lives <= 0 {
		g.state = .game_over
	} else {
		g.player_x = 100.0
		g.player_y = 520.0
		g.player_vx = 0.0
		g.player_vy = 0.0
		g.is_grounded = true
		g.is_climbing = false
	}
}

