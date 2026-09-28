module main

import math
import rand

pub const world_w = 800
pub const world_h = 600
pub const surface_y = 100.0

pub enum ItemType {
	gold_small
	gold_med
	gold_large
	diamond
	rock_small
	rock_large
	tnt
	mystery
}

pub struct MineItem {
pub mut:
	x       f64
	y       f64
	rad     f64
	val     int
	weight  f64
	@type   ItemType
	active  bool = true
}

pub enum ClawState {
	swinging
	extending
	retracting
}

pub struct Claw {
pub mut:
	angle       f64  = 0.0
	ang_dir     f64  = 1.0
	len         f64  = 30.0
	min_len     f64  = 30.0
	max_len     f64  = 650.0
	state       ClawState = .swinging
	hooked_item int  = -1
}

pub enum MinerGameState {
	mining
	shop
	won_level
	game_over
}

pub struct GoldMinerGame {
pub mut:
	state          MinerGameState = .mining
	money          int
	target_money   int = 650
	level          int = 1
	time_left      f64 = 60.0
	dynamite_count int = 1
	has_strength   bool
	has_clover     bool
	claw           Claw
	items          []MineItem
	high_score     int = 8500
	max_level      int = 1
	toast_msg      string
	toast_timer    f64
}

pub fn new_gold_miner_game() GoldMinerGame {
	mut g := GoldMinerGame{}
	saved := load_gold_save()
	if saved.high_score > 0 { g.high_score = saved.high_score }
	if saved.max_level > 0 { g.max_level = saved.max_level }
	g.reset_game()
	return g
}

pub fn (mut g GoldMinerGame) reset_game() {
	g.money = 0
	g.level = 1
	g.dynamite_count = 1
	g.has_strength = false
	g.has_clover = false
	g.reset_level()
}

pub fn (mut g GoldMinerGame) reset_level() {
	g.state = .mining
	g.time_left = 60.0
	g.target_money = 600 + (g.level - 1) * 900
	g.claw = Claw{
		angle:       0.0
		ang_dir:     1.0
		len:         30.0
		min_len:     30.0
		max_len:     650.0
		state:       .swinging
		hooked_item: -1
	}

	g.generate_level_items()
}

pub fn (mut g GoldMinerGame) generate_level_items() {
	g.items.clear()

	// Gold pieces
	g.items << MineItem{ x: 180.0, y: 260.0, rad: 14.0, val: 50, weight: 1.0, @type: .gold_small }
	g.items << MineItem{ x: 380.0, y: 340.0, rad: 22.0, val: 250, weight: 2.2, @type: .gold_med }
	g.items << MineItem{ x: 620.0, y: 440.0, rad: 34.0, val: 500, weight: 4.5, @type: .gold_large }
	g.items << MineItem{ x: 500.0, y: 220.0, rad: 14.0, val: 50, weight: 1.0, @type: .gold_small }
	g.items << MineItem{ x: 260.0, y: 480.0, rad: 22.0, val: 250, weight: 2.2, @type: .gold_med }

	// Diamonds
	g.items << MineItem{ x: 300.0, y: 220.0, rad: 10.0, val: 600, weight: 0.4, @type: .diamond }
	g.items << MineItem{ x: 680.0, y: 300.0, rad: 10.0, val: 600, weight: 0.4, @type: .diamond }

	// Rocks
	g.items << MineItem{ x: 120.0, y: 380.0, rad: 16.0, val: 11, weight: 3.5, @type: .rock_small }
	g.items << MineItem{ x: 440.0, y: 460.0, rad: 26.0, val: 20, weight: 5.5, @type: .rock_large }

	// TNT Barrel
	g.items << MineItem{ x: 560.0, y: 380.0, rad: 18.0, val: 0, weight: 1.0, @type: .tnt }

	// Mystery Bag
	g.items << MineItem{ x: 340.0, y: 520.0, rad: 16.0, val: 200, weight: 1.2, @type: .mystery }
}

pub fn (mut g GoldMinerGame) launch_claw() bool {
	if g.state == .mining && g.claw.state == .swinging {
		g.claw.state = .extending
		return true
	}
	return false
}

pub fn (mut g GoldMinerGame) use_dynamite() bool {
	if g.state == .mining && g.claw.state == .retracting && g.claw.hooked_item != -1 && g.dynamite_count > 0 {
		g.dynamite_count--
		idx := g.claw.hooked_item
		if idx >= 0 && idx < g.items.len {
			g.items[idx].active = false
		}
		g.claw.hooked_item = -1
		return true
	}
	return false
}

pub struct MinerEvents {
pub mut:
	caught_gold     bool
	caught_diamond  bool
	tnt_exploded    bool
	item_reeled     bool
	won_level       bool
	game_over       bool
}

pub fn (mut g GoldMinerGame) update(dt f64) MinerEvents {
	mut ev := MinerEvents{}
	if g.state != .mining {
		return ev
	}

	g.time_left -= dt
	if g.time_left <= 0.0 {
		g.time_left = 0.0
		if g.money >= g.target_money {
			g.state = .won_level
			ev.won_level = true
			if g.money > g.high_score {
				g.high_score = g.money
			}
		} else {
			g.state = .game_over
			ev.game_over = true
			if g.money > g.high_score {
				g.high_score = g.money
			}
		}
		return ev
	}

	claw_ox := f64(world_w) / 2.0
	claw_oy := surface_y

	match g.claw.state {
		.swinging {
			swing_speed := 1.7
			max_angle := 1.25 // ~71 degrees
			g.claw.angle += g.claw.ang_dir * swing_speed * dt
			if g.claw.angle > max_angle {
				g.claw.angle = max_angle
				g.claw.ang_dir = -1.0
			} else if g.claw.angle < -max_angle {
				g.claw.angle = -max_angle
				g.claw.ang_dir = 1.0
			}
		}
		.extending {
			ext_speed := 380.0
			g.claw.len += ext_speed * dt

			// Current tip position
			tip_x := claw_ox + math.sin(g.claw.angle) * g.claw.len
			tip_y := claw_oy + math.cos(g.claw.angle) * g.claw.len

			// Check wall / floor bounds
			if tip_x <= 20.0 || tip_x >= f64(world_w) - 20.0 || tip_y >= f64(world_h) - 20.0 || g.claw.len >= g.claw.max_len {
				g.claw.state = .retracting
			} else {
				// Check item collision
				for i, item in g.items {
					if item.active {
						dist_sq := (tip_x - item.x) * (tip_x - item.x) + (tip_y - item.y) * (tip_y - item.y)
						if dist_sq <= item.rad * item.rad {
							// Hooked item!
							if item.@type == .tnt {
								// TNT Explodes! Destroy all nearby items
								g.items[i].active = false
								ev.tnt_exploded = true
								for j in 0 .. g.items.len {
									if g.items[j].active {
										d_sq := (item.x - g.items[j].x) * (item.x - g.items[j].x) + (item.y - g.items[j].y) * (item.y - g.items[j].y)
										if d_sq <= 120.0 * 120.0 {
											g.items[j].active = false
										}
									}
								}
								g.claw.hooked_item = -1
								g.claw.state = .retracting
								break
							} else {
								g.claw.hooked_item = i
								g.claw.state = .retracting
								if item.@type == .diamond {
									ev.caught_diamond = true
								} else if item.@type == .gold_small || item.@type == .gold_med || item.@type == .gold_large {
									ev.caught_gold = true
								}
								break
							}
						}
					}
				}
			}
		}
		.retracting {
			mut weight := 0.0
			if g.claw.hooked_item != -1 && g.claw.hooked_item < g.items.len {
				weight = g.items[g.claw.hooked_item].weight
				if g.has_strength {
					weight = weight * 0.4
				}
			}
			ret_speed := 380.0 / (1.0 + weight * 0.65)
			g.claw.len -= ret_speed * dt

			// Move hooked item with claw tip
			if g.claw.hooked_item != -1 && g.claw.hooked_item < g.items.len {
				tip_x := claw_ox + math.sin(g.claw.angle) * g.claw.len
				tip_y := claw_oy + math.cos(g.claw.angle) * g.claw.len
				g.items[g.claw.hooked_item].x = tip_x
				g.items[g.claw.hooked_item].y = tip_y
			}

			// Reeled all the way back to origin
			if g.claw.len <= g.claw.min_len {
				g.claw.len = g.claw.min_len
				g.claw.state = .swinging

				if g.claw.hooked_item != -1 && g.claw.hooked_item < g.items.len {
					item := g.items[g.claw.hooked_item]
					mut val := item.val
					if item.@type == .mystery {
						val = if g.has_clover { 500 + rand.intn(300) or { 0 } } else { 100 + rand.intn(350) or { 0 } }
					}
					g.money += val
					g.items[g.claw.hooked_item].active = false
					g.claw.hooked_item = -1
					ev.item_reeled = true

				if g.money > g.high_score {
						g.high_score = g.money
					}
					g.save_progress()
				}
			}
		}
	}

	if g.toast_timer > 0.0 {
		g.toast_timer -= dt
	}
	return ev
}

pub fn (mut g GoldMinerGame) save_progress() {
	if g.money > g.high_score {
		g.high_score = g.money
	}
	mut saved := load_gold_save()
	saved.high_score = g.high_score
	if g.level > saved.max_level {
		saved.max_level = g.level
	}
	saved.money = g.money
	saved.level = g.level
	saved.target_money = g.target_money
	saved.time_left = g.time_left
	saved.dynamite_count = g.dynamite_count
	saved.has_strength = g.has_strength
	saved.has_clover = g.has_clover
	save_gold_data(&saved)
}

pub fn (mut g GoldMinerGame) save_state() {
	g.save_progress()
	mut saved := load_gold_save()
	saved.save_state_valid = true
	save_gold_data(&saved)

	g.toast_msg = 'GAME SAVED (F5)'
	g.toast_timer = 2.0
}

pub fn (mut g GoldMinerGame) load_state() {
	saved := load_gold_save()
	if !saved.save_state_valid {
		g.toast_msg = 'NO SAVE FOUND'
		g.toast_timer = 2.0
		return
	}
	if saved.high_score > 0 { g.high_score = saved.high_score }
	g.money = saved.money
	g.level = saved.level
	g.target_money = saved.target_money
	g.time_left = saved.time_left
	g.dynamite_count = saved.dynamite_count
	g.has_strength = saved.has_strength
	g.has_clover = saved.has_clover
	g.state = .mining

	g.toast_msg = 'GAME LOADED (F9)'
	g.toast_timer = 2.0
}
