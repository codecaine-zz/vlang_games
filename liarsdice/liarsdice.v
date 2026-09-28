module main

import math
import rand

pub enum GamePhase {
	rolling
	bidding
	challenge_reveal
	round_over
	game_over
}

pub struct Bid {
pub mut:
	qty  int
	face int // 1 to 6
}

pub fn (b Bid) is_valid_higher(previous Bid, total_dice int) bool {
	if b.qty < 1 || b.qty > total_dice || b.face < 1 || b.face > 6 {
		return false
	}
	if previous.qty == 0 {
		return true
	}

	// If previous bid was for 1s (Pacos)
	if previous.face == 1 {
		if b.face == 1 {
			return b.qty > previous.qty
		} else {
			// Shifting from 1s to normal: must be at least 2*qty + 1
			return b.qty >= previous.qty * 2 + 1
		}
	}

	// If shifting TO 1s: can halve the quantity (rounded up)
	if b.face == 1 {
		required := int(math.ceil(f64(previous.qty) / 2.0))
		return b.qty >= required
	}

	// Normal bids: higher quantity with any face, OR same quantity with strictly higher face
	if b.qty > previous.qty {
		return true
	}
	if b.qty == previous.qty {
		return b.face > previous.face
	}
	return false
}

pub struct Player {
pub mut:
	name        string
	is_ai       bool
	dice_count  int = 5
	dice        []int
	eliminated  bool
	peek_dice   bool
}

pub struct LiarsDiceGame {
pub mut:
	players          []Player
	current_player   int
	last_bid         Bid
	last_bidder      int = -1
	phase            GamePhase = .rolling
	round            int = 1
	wild_ones        bool = true
	selected_qty     int = 1
	selected_face    int = 2
	challenge_type   string // "LIAR" or "SPOT_ON"
	challenger_idx   int = -1
	actual_count     int
	loser_idx        int = -1
	winner_idx       int = -1
	reveal_timer     f64
	ai_timer         f64
	roll_anim_timer  f64
	status_message   string
	history          []string
	is_two_player    bool
}

pub fn new_liarsdice_game(is_2p bool) LiarsDiceGame {
	mut g := LiarsDiceGame{
		is_two_player: is_2p
	}
	g.reset()
	return g
}

pub fn (mut g LiarsDiceGame) reset() {
	g.players.clear()
	if g.is_two_player {
		g.players << Player{ name: 'Player 1', is_ai: false, dice_count: 5, peek_dice: true }
		g.players << Player{ name: 'Player 2', is_ai: false, dice_count: 5, peek_dice: true }
	} else {
		g.players << Player{ name: 'You (P1)', is_ai: false, dice_count: 5, peek_dice: true }
		g.players << Player{ name: 'Captain Hook', is_ai: true, dice_count: 5, peek_dice: false }
		g.players << Player{ name: 'Blackbeard', is_ai: true, dice_count: 5, peek_dice: false }
		g.players << Player{ name: 'Calico Jack', is_ai: true, dice_count: 5, peek_dice: false }
	}
	g.round = 1
	g.winner_idx = -1
	g.history.clear()
	g.start_new_round()
}

pub fn (g LiarsDiceGame) total_active_dice() int {
	mut total := 0
	for p in g.players {
		if !p.eliminated {
			total += p.dice_count
		}
	}
	return total
}

pub fn (g LiarsDiceGame) count_matching_dice(face int) int {
	mut count := 0
	for p in g.players {
		if p.eliminated { continue }
		for d in p.dice {
			if d == face {
				count++
			} else if g.wild_ones && face != 1 && d == 1 {
				// 1s are wild!
				count++
			}
		}
	}
	return count
}

pub fn (mut g LiarsDiceGame) start_new_round() {
	g.last_bid = Bid{ qty: 0, face: 0 }
	g.last_bidder = -1
	g.challenger_idx = -1
	g.loser_idx = -1
	g.actual_count = 0
	g.selected_qty = 1
	g.selected_face = 2
	g.roll_anim_timer = 0.6
	g.phase = .rolling

	// Roll dice for all active players
	for mut p in g.players {
		p.dice.clear()
		if !p.eliminated {
			for _ in 0 .. p.dice_count {
				p.dice << rand.int_in_range(1, 7) or { 1 }
			}
			// Sort player dice for cleaner presentation
			p.dice.sort()
		}
	}

	// Ensure starting player is active
	if g.players[g.current_player].eliminated {
		g.advance_to_next_active_player()
	}

	g.status_message = 'Round ${g.round}: Shake and roll! ${g.players[g.current_player].name}\'s turn to bid.'
}

pub fn (mut g LiarsDiceGame) advance_to_next_active_player() {
	for _ in 0 .. g.players.len {
		g.current_player = (g.current_player + 1) % g.players.len
		if !g.players[g.current_player].eliminated {
			break
		}
	}
}

pub fn (mut g LiarsDiceGame) make_bid(player_idx int, qty int, face int) bool {
	if g.phase != .bidding || player_idx != g.current_player {
		return false
	}
	bid := Bid{ qty: qty, face: face }
	if !bid.is_valid_higher(g.last_bid, g.total_active_dice()) {
		return false
	}

	g.last_bid = bid
	g.last_bidder = player_idx
	p_name := g.players[player_idx].name
	face_str := match face {
		1 { 'Ones (Wild)' }
		2 { 'Twos' }
		3 { 'Threes' }
		4 { 'Fours' }
		5 { 'Fives' }
		6 { 'Sixes' }
		else { '${face}s' }
	}
	msg := '${p_name} bids ${qty}x [${face_str}]'
	g.history << msg
	g.status_message = msg

	// Prepare minimum valid default selection for next bidder
	g.advance_to_next_active_player()
	if face == 1 {
		g.selected_qty = qty + 1
		g.selected_face = 1
	} else if qty == g.total_active_dice() {
		g.selected_qty = qty
		g.selected_face = math.min(6, face + 1)
	} else {
		g.selected_qty = qty
		g.selected_face = math.min(6, face + 1)
		if g.selected_face <= face {
			g.selected_qty = qty + 1
			g.selected_face = 2
		}
	}

	return true
}

pub fn (mut g LiarsDiceGame) call_liar(challenger_idx int) bool {
	if g.phase != .bidding || g.last_bidder == -1 || challenger_idx != g.current_player {
		return false
	}
	g.challenger_idx = challenger_idx
	g.challenge_type = 'LIAR'
	g.phase = .challenge_reveal
	g.reveal_timer = 2.5

	g.actual_count = g.count_matching_dice(g.last_bid.face)
	bidder := g.players[g.last_bidder].name
	challenger := g.players[challenger_idx].name

	if g.actual_count < g.last_bid.qty {
		// Bid was a lie! Bidder loses die
		g.loser_idx = g.last_bidder
		msg := '${challenger} called LIAR on ${bidder}! Actual: ${g.actual_count} vs Bid: ${g.last_bid.qty}. ${bidder} caught bluffing!'
		g.history << msg
		g.status_message = msg
	} else {
		// Bid was true! Challenger was wrong and loses die
		g.loser_idx = challenger_idx
		msg := '${challenger} called LIAR on ${bidder}! Actual: ${g.actual_count} vs Bid: ${g.last_bid.qty}. Bid was valid! ${challenger} loses a die.'
		g.history << msg
		g.status_message = msg
	}
	return true
}

pub fn (mut g LiarsDiceGame) call_spot_on(challenger_idx int) bool {
	if g.phase != .bidding || g.last_bidder == -1 || challenger_idx != g.current_player {
		return false
	}
	g.challenger_idx = challenger_idx
	g.challenge_type = 'SPOT_ON'
	g.phase = .challenge_reveal
	g.reveal_timer = 2.5

	g.actual_count = g.count_matching_dice(g.last_bid.face)
	challenger := g.players[challenger_idx].name

	if g.actual_count == g.last_bid.qty {
		// Exact match! Challenger gains a die (up to 5)
		if g.players[challenger_idx].dice_count < 5 {
			g.players[challenger_idx].dice_count++
		}
		g.loser_idx = -1
		msg := '${challenger} called SPOT ON and nailed it exactly! (${g.actual_count}). ${challenger} gains a die!'
		g.history << msg
		g.status_message = msg
	} else {
		// Wrong! Challenger loses die
		g.loser_idx = challenger_idx
		msg := '${challenger} called SPOT ON, but actual count was ${g.actual_count} vs Bid ${g.last_bid.qty}. ${challenger} loses a die.'
		g.history << msg
		g.status_message = msg
	}
	return true
}

pub fn (mut g LiarsDiceGame) resolve_challenge_end() {
	if g.loser_idx >= 0 {
		g.players[g.loser_idx].dice_count--
		if g.players[g.loser_idx].dice_count <= 0 {
			g.players[g.loser_idx].eliminated = true
			g.history << '${g.players[g.loser_idx].name} is eliminated from the game!'
		}
	}

	// Check if only 1 active player remains
	mut active_players := []int{}
	for i, p in g.players {
		if !p.eliminated {
			active_players << i
		}
	}

	if active_players.len == 1 {
		g.winner_idx = active_players[0]
		g.phase = .game_over
		g.status_message = '🏆 ${g.players[g.winner_idx].name} WINS THE GAME!'
	} else {
		g.phase = .round_over
		// Next round starts with the player who lost the die (or challenger if spot on succeeded)
		if g.loser_idx >= 0 && !g.players[g.loser_idx].eliminated {
			g.current_player = g.loser_idx
		} else if g.challenger_idx >= 0 && !g.players[g.challenger_idx].eliminated {
			g.current_player = g.challenger_idx
		} else {
			g.advance_to_next_active_player()
		}
	}
}

pub fn (mut g LiarsDiceGame) update(dt f64) {
	if g.phase == .rolling {
		g.roll_anim_timer -= dt
		if g.roll_anim_timer <= 0 {
			g.phase = .bidding
			g.ai_timer = 0.7
		}
		return
	}

	if g.phase == .challenge_reveal {
		g.reveal_timer -= dt
		if g.reveal_timer <= 0 {
			g.resolve_challenge_end()
		}
		return
	}

	if g.phase == .bidding && g.players[g.current_player].is_ai {
		g.ai_timer -= dt
		if g.ai_timer <= 0 {
			g.ai_take_turn()
		}
	}
}

// AI decision making engine
pub fn (mut g LiarsDiceGame) ai_take_turn() {
	if g.phase != .bidding || !g.players[g.current_player].is_ai {
		return
	}

	cur_p := g.players[g.current_player]
	total_dice := g.total_active_dice()
	hidden_dice := total_dice - cur_p.dice_count

	// First bid of the round: make a solid initial bid based on own hand
	if g.last_bid.qty == 0 {
		// Find most frequent face in hand
		mut counts := map[int]int{}
		for d in cur_p.dice {
			counts[d]++
		}
		mut best_face := 2
		mut best_count := 0
		for f := 2; f <= 6; f++ {
			if counts[f] > best_count {
				best_count = counts[f]
				best_face = f
			}
		}
		expected_others := int(math.round(f64(hidden_dice) / 3.0)) // 1s + target face = 2/6 = 1/3
		qty := math.max(1, best_count + expected_others)
		g.make_bid(g.current_player, math.min(qty, total_dice), best_face)
		return
	}

	// Analyze last bid probability
	target_face := g.last_bid.face
	mut my_matching := 0
	for d in cur_p.dice {
		if d == target_face || (g.wild_ones && target_face != 1 && d == 1) {
			my_matching++
		}
	}

	needed_from_others := g.last_bid.qty - my_matching
	prob_match := if target_face == 1 { 1.0 / 6.0 } else { 2.0 / 6.0 }
	expected_from_others := f64(hidden_dice) * prob_match

	// If the needed amount exceeds expected by a large margin -> call LIAR!
	if needed_from_others > int(math.ceil(expected_from_others + 1.2)) {
		g.call_liar(g.current_player)
		return
	}

	// Small chance to call Spot On if exact match seems very plausible
	if needed_from_others > 0 && f64(needed_from_others) == math.round(expected_from_others) && rand.f64() < 0.15 {
		g.call_spot_on(g.current_player)
		return
	}

	// Otherwise, raise the bid
	mut candidate_qty := g.last_bid.qty
	mut candidate_face := g.last_bid.face + 1

	if candidate_face > 6 {
		candidate_qty++
		candidate_face = 2
	}

	if candidate_qty > total_dice {
		// Cannot bid higher than total dice, must challenge
		g.call_liar(g.current_player)
		return
	}

	g.make_bid(g.current_player, candidate_qty, candidate_face)
}
