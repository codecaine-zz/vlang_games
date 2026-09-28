module main

import math
import rand

pub enum GameMode {
	solo
	vs_ai
	two_player
}

pub enum Category {
	ones
	twos
	threes
	fours
	fives
	sixes
	three_of_kind
	four_of_kind
	full_house
	small_straight
	large_straight
	yahtzee
	chance
}

pub struct Die {
pub mut:
	value     int = 1
	held      bool
	x         f64
	y         f64
	target_x  f64
	target_y  f64
	angle     f64
	rot_v     f64
	rolling   bool
	roll_time f64
}

pub struct PlayerScorecard {
pub mut:
	name          string
	is_ai         bool
	scores        map[string]int // Category name -> score. Unfilled categories absent
	upper_bonus   bool
	yahtzee_bonus int // +100 for extra Yahtzees
}

pub fn new_player_scorecard(name string, is_ai bool) PlayerScorecard {
	return PlayerScorecard{
		name: name
		is_ai: is_ai
		scores: map[string]int{}
	}
}

pub fn (sc PlayerScorecard) is_filled(cat Category) bool {
	return cat.str() in sc.scores
}

pub fn (sc PlayerScorecard) get_upper_subtotal() int {
	mut sum := 0
	upper_cats := [Category.ones, .twos, .threes, .fours, .fives, .sixes]
	for c in upper_cats {
		if c.str() in sc.scores {
			sum += sc.scores[c.str()]
		}
	}
	return sum
}

pub fn (sc PlayerScorecard) get_upper_total() int {
	sub := sc.get_upper_subtotal()
	bonus := if sub >= 63 { 35 } else { 0 }
	return sub + bonus
}

pub fn (sc PlayerScorecard) get_lower_total() int {
	mut sum := 0
	lower_cats := [Category.three_of_kind, .four_of_kind, .full_house, .small_straight, .large_straight, .yahtzee, .chance]
	for c in lower_cats {
		if c.str() in sc.scores {
			sum += sc.scores[c.str()]
		}
	}
	return sum + sc.yahtzee_bonus
}

pub fn (sc PlayerScorecard) get_grand_total() int {
	return sc.get_upper_total() + sc.get_lower_total()
}

pub fn (sc PlayerScorecard) is_complete() bool {
	return sc.scores.len == 13
}

pub struct ConfettiParticle {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	angle f64
	rot_v f64
	w     int
	h     int
	life  f64
	max_l f64
	col   Color
}

pub struct YahtzeeGame {
pub mut:
	mode            GameMode = .solo
	players         []PlayerScorecard
	current_player  int
	round           int = 1 // 1..13
	rolls_left      int = 3

	// 5 Dice
	dice            []Die

	// Hovered / selected category for preview
	hover_cat       Category = .ones
	has_hover       bool

	// Confetti
	confetti        []ConfettiParticle

	// AI Turn timers
	ai_step_timer   f64
	is_ai_thinking  bool

	// Audio & Notifications
	sound_event     string
	banner_text     string
	banner_timer    f64
	is_game_over    bool
}

pub fn new_yahtzee_game() YahtzeeGame {
	mut g := YahtzeeGame{}
	g.reset_game()
	return g
}

pub fn (mut g YahtzeeGame) reset_game() {
	g.players.clear()
	match g.mode {
		.solo {
			g.players << new_player_scorecard('Player 1', false)
		}
		.vs_ai {
			g.players << new_player_scorecard('You', false)
			g.players << new_player_scorecard('Dice Master Bot', true)
		}
		.two_player {
			g.players << new_player_scorecard('Player 1', false)
			g.players << new_player_scorecard('Player 2', false)
		}
	}

	g.current_player = 0
	g.round = 1
	g.rolls_left = 3
	g.is_game_over = false
	g.confetti.clear()
	g.sound_event = ''
	g.banner_text = 'WELCOME! ROLL DICE [SPACE] TO START'
	g.banner_timer = 3.0

	// Initialize 5 Dice
	g.dice.clear()
	for i in 0 .. 5 {
		slot_x := 100.0 + f64(i * 84)
		slot_y := 480.0
		g.dice << Die{
			value: 1 + i
			held: false
			x: slot_x
			y: slot_y
			target_x: slot_x
			target_y: slot_y
			angle: 0.0
			rot_v: 0.0
			rolling: false
		}
	}
}

pub fn (mut g YahtzeeGame) toggle_hold(index int) {
	if index < 0 || index >= 5 || g.rolls_left == 3 || g.is_rolling() || g.is_game_over {
		return
	}
	g.dice[index].held = !g.dice[index].held
	g.sound_event = if g.dice[index].held { 'hold' } else { 'unhold' }
}

pub fn (g YahtzeeGame) is_rolling() bool {
	for d in g.dice {
		if d.rolling {
			return true
		}
	}
	return false
}

pub fn (mut g YahtzeeGame) roll_dice() bool {
	if g.rolls_left <= 0 || g.is_rolling() || g.is_game_over {
		return false
	}

	g.rolls_left--
	g.sound_event = 'roll'

	for i in 0 .. 5 {
		if !g.dice[i].held {
			g.dice[i].rolling = true
			g.dice[i].roll_time = 0.0
			g.dice[i].rot_v = (rand.f64() * 2.0 - 1.0) * 18.0
			g.dice[i].x = g.dice[i].target_x + (rand.f64() * 40.0 - 20.0)
			g.dice[i].y = g.dice[i].target_y - (60.0 + rand.f64() * 40.0)
		}
	}
	return true
}

pub fn (mut g YahtzeeGame) update(dt f64) {
	if g.banner_timer > 0.0 {
		g.banner_timer -= dt
	}

	// 1. Update Dice Rolling Physics
	mut any_just_stopped := false
	for mut d in g.dice {
		if d.rolling {
			d.roll_time += dt
			d.angle += d.rot_v * dt

			// Shuffle values during roll
			if (int(d.roll_time * 60.0)) % 4 == 0 {
				d.value = 1 + rand.int_in_range(0, 6) or { 1 }
			}

			// Spring back to target slot
			d.x += (d.target_x - d.x) * 10.0 * dt
			d.y += (d.target_y - d.y) * 10.0 * dt

			if d.roll_time >= 0.42 {
				d.rolling = false
				d.value = 1 + rand.int_in_range(0, 6) or { 1 }
				d.x = d.target_x
				d.y = d.target_y
				d.angle = 0.0
				any_just_stopped = true
			}
		}
	}

	if any_just_stopped && !g.is_rolling() {
		// Check for natural Yahtzee roll
		if g.calculate_score(Category.yahtzee) == 50 {
			g.sound_event = 'yahtzee'
			g.banner_text = '★ YAHTZEE ROLL! 50 POINTS! ★'
			g.banner_timer = 3.0
			g.spawn_confetti(320.0, 300.0, 70)
		}
	}

	// 2. AI Turn Management
	if g.players[g.current_player].is_ai && !g.is_rolling() && !g.is_game_over {
		g.ai_step_timer += dt
		if g.ai_step_timer >= 0.75 {
			g.ai_step_timer = 0.0
			g.execute_ai_step()
		}
	}

	// 3. Update Confetti Particles
	g.update_confetti(dt)
}

fn (mut g YahtzeeGame) execute_ai_step() {
	if g.rolls_left == 3 {
		// AI Roll 1
		g.roll_dice()
		return
	}

	if g.rolls_left > 0 {
		// AI Decision on Holds
		best_holds := g.ai_choose_holds()
		for i in 0 .. 5 {
			g.dice[i].held = best_holds[i]
		}
		// If already have high-value combo (e.g. Large Straight or Yahtzee), score immediately
		if g.calculate_score(Category.yahtzee) == 50 || g.calculate_score(Category.large_straight) == 40 {
			g.ai_score_best_category()
			return
		}
		g.roll_dice()
		return
	}

	// Rolls exhausted: score best category
	g.ai_score_best_category()
}

fn (g YahtzeeGame) ai_choose_holds() []bool {
	mut holds := [false, false, false, false, false]
	vals := g.get_dice_values()

	// Check for Yahtzee or 4 of a kind: hold the matching numbers
	mut counts := [0, 0, 0, 0, 0, 0, 0]
	for v in vals {
		counts[v]++
	}

	mut max_count := 0
	mut max_val := 0
	for v in 1 .. 7 {
		if counts[v] > max_count {
			max_count = counts[v]
			max_val = v
		}
	}

	if max_count >= 3 {
		for i in 0 .. 5 {
			if g.dice[i].value == max_val {
				holds[i] = true
			}
		}
		return holds
	}

	// Check Straight potential
	if !g.players[g.current_player].is_filled(Category.large_straight) || !g.players[g.current_player].is_filled(Category.small_straight) {
		mut seen := map[int]bool{}
		for i in 0 .. 5 {
			v := g.dice[i].value
			is_straight_val := (v >= 1 && v <= 4) || (v >= 2 && v <= 5) || (v >= 3 && v <= 6)
			if !(v in seen) && is_straight_val {
				seen[v] = true
				holds[i] = true
			}
		}
		if seen.len >= 3 {
			return holds
		}
	}

	// Default: hold highest pair or high values (5s, 6s)
	if max_count >= 2 {
		for i in 0 .. 5 {
			if g.dice[i].value == max_val {
				holds[i] = true
			}
		}
	} else {
		for i in 0 .. 5 {
			if g.dice[i].value >= 5 {
				holds[i] = true
			}
		}
	}
	return holds
}

fn (mut g YahtzeeGame) ai_score_best_category() {
	all_cats := [
		Category.yahtzee,
		.large_straight,
		.small_straight,
		.full_house,
		.four_of_kind,
		.three_of_kind,
		.sixes,
		.fives,
		.fours,
		.chance,
		.threes,
		.twos,
		.ones,
	]

	mut best_cat := Category.ones
	mut max_score := -1

	for c in all_cats {
		if !g.players[g.current_player].is_filled(c) {
			sc := g.calculate_score(c)
			if sc > max_score {
				max_score = sc
				best_cat = c
			}
		}
	}

	g.choose_category(best_cat)
}

pub fn (g YahtzeeGame) get_dice_values() []int {
	mut vals := []int{cap: 5}
	for d in g.dice {
		vals << d.value
	}
	return vals
}

pub fn (g YahtzeeGame) calculate_score(cat Category) int {
	vals := g.get_dice_values()
	mut sum := 0
	mut counts := [0, 0, 0, 0, 0, 0, 0]
	for v in vals {
		sum += v
		counts[v]++
	}

	match cat {
		.ones {
			return counts[1] * 1
		}
		.twos {
			return counts[2] * 2
		}
		.threes {
			return counts[3] * 3
		}
		.fours {
			return counts[4] * 4
		}
		.fives {
			return counts[5] * 5
		}
		.sixes {
			return counts[6] * 6
		}
		.three_of_kind {
			for c in counts {
				if c >= 3 {
					return sum
				}
			}
			return 0
		}
		.four_of_kind {
			for c in counts {
				if c >= 4 {
					return sum
				}
			}
			return 0
		}
		.full_house {
			mut has_3 := false
			mut has_2 := false
			for c in counts {
				if c == 3 {
					has_3 = true
				}
				if c == 2 {
					has_2 = true
				}
				if c == 5 {
					return 25
				}
			}
			if has_3 && has_2 {
				return 25
			}
			return 0
		}
		.small_straight {
			// 1-2-3-4, 2-3-4-5, or 3-4-5-6
			if (counts[1] > 0 && counts[2] > 0 && counts[3] > 0 && counts[4] > 0)
				|| (counts[2] > 0 && counts[3] > 0 && counts[4] > 0 && counts[5] > 0)
				|| (counts[3] > 0 && counts[4] > 0 && counts[5] > 0 && counts[6] > 0) {
				return 30
			}
			return 0
		}
		.large_straight {
			// 1-2-3-4-5 or 2-3-4-5-6
			if (counts[1] == 1 && counts[2] == 1 && counts[3] == 1 && counts[4] == 1 && counts[5] == 1)
				|| (counts[2] == 1 && counts[3] == 1 && counts[4] == 1 && counts[5] == 1 && counts[6] == 1) {
				return 40
			}
			return 0
		}
		.yahtzee {
			for c in counts {
				if c == 5 {
					return 50
				}
			}
			return 0
		}
		.chance {
			return sum
		}
	}
}

pub fn (mut g YahtzeeGame) choose_category(cat Category) bool {
	if g.rolls_left == 3 || g.is_rolling() || g.is_game_over {
		return false
	}
	if g.players[g.current_player].is_filled(cat) {
		return false
	}

	pts := g.calculate_score(cat)

	// Check Yahtzee Bonus rule (+100 for subsequent Yahtzees)
	if g.calculate_score(Category.yahtzee) == 50 && g.players[g.current_player].is_filled(Category.yahtzee) {
		if g.players[g.current_player].scores[Category.yahtzee.str()] == 50 {
			g.players[g.current_player].yahtzee_bonus += 100
			g.sound_event = 'yahtzee'
			g.banner_text = 'BONUS YAHTZEE! +100 PTS!'
			g.banner_timer = 3.0
			g.spawn_confetti(320.0, 300.0, 60)
		}
	}

	g.players[g.current_player].scores[cat.str()] = pts

	// Check Upper section +35 bonus unlock
	sub := g.players[g.current_player].get_upper_subtotal()
	if sub >= 63 && !g.players[g.current_player].upper_bonus {
		g.players[g.current_player].upper_bonus = true
		g.sound_event = 'bonus'
		g.banner_text = 'UPPER BONUS UNLOCKED! +35 POINTS!'
		g.banner_timer = 3.0
		g.spawn_confetti(320.0, 300.0, 50)
	} else if g.sound_event == '' {
		g.sound_event = 'score'
	}

	// Advance Turn
	g.advance_turn()
	return true
}

fn (mut g YahtzeeGame) advance_turn() {
	// Reset holds & rolls
	for mut d in g.dice {
		d.held = false
	}
	g.rolls_left = 3
	g.ai_step_timer = 0.0

	// Check if all players completed 13 rounds
	g.current_player = (g.current_player + 1) % g.players.len
	if g.current_player == 0 {
		g.round++
		if g.round > 13 {
			g.is_game_over = true
			g.sound_event = 'win'
			g.banner_text = 'GAME COMPLETED! FINAL SCORES RECORDED'
			g.banner_timer = 6.0
			g.spawn_confetti(450.0, 300.0, 100)
			return
		}
	}

	p_name := g.players[g.current_player].name
	if !g.is_game_over {
		g.banner_text = "${p_name.to_upper()}'S TURN - ROLL 1 OF 3"
		g.banner_timer = 2.0
	}
}

pub fn (mut g YahtzeeGame) spawn_confetti(x f64, y f64, count int) {
	cols := [
		Color{255, 215, 0, 255},
		Color{255, 60, 80, 255},
		Color{0, 220, 255, 255},
		Color{50, 255, 120, 255},
		Color{255, 120, 220, 255},
	]

	for _ in 0 .. count {
		g.confetti << ConfettiParticle{
			x: x + (rand.f64() * 60.0 - 30.0)
			y: y + (rand.f64() * 40.0 - 20.0)
			vx: (rand.f64() * 2.0 - 1.0) * 220.0
			vy: -150.0 - rand.f64() * 200.0
			angle: rand.f64() * math.pi * 2.0
			rot_v: (rand.f64() * 2.0 - 1.0) * 12.0
			w: 6 + rand.int_in_range(0, 4) or { 2 }
			h: 4 + rand.int_in_range(0, 3) or { 2 }
			life: 0.0
			max_l: 1.2 + rand.f64() * 0.8
			col: cols[rand.int_in_range(0, cols.len) or { 0 }]
		}
	}
}

fn (mut g YahtzeeGame) update_confetti(dt f64) {
	for i := g.confetti.len - 1; i >= 0; i-- {
		mut p := g.confetti[i]
		p.life += dt
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 220.0 * dt // Gravity
		p.vx *= 0.98
		p.angle += p.rot_v * dt

		if p.life >= p.max_l {
			g.confetti.delete(i)
		} else {
			g.confetti[i] = p
		}
	}
}
