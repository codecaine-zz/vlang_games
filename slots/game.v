module main

import math
import rand

pub enum SlotTheme {
	vegas_classic // 3 Reels, 5 Paylines, Classic Fruits & 777
	neon_cyber    // 5 Reels, 20 Paylines, Wilds, Scatters & Free Spins
}

pub enum SymbolType {
	cherry
	lemon
	orange
	plum
	bell
	bar_single
	bar_double
	bar_triple
	seven
	diamond
	wild
	scatter
}

pub struct CellPos {
pub mut:
	reel int
	row  int
}

pub struct Reel {
pub mut:
	symbols       []SymbolType
	offset_y      f64 // Continuous rolling offset
	speed_y       f64 // Pixels per second
	target_stop   int // Index of target symbol
	stopping      bool
	stopped       bool
	bounce_t      f64 // Elastic bounce back upon stopping
	hold          bool // Player hold feature
}

pub struct WinningLine {
pub mut:
	line_idx   int
	symbol     SymbolType
	count      int
	payout     int
	positions  []CellPos
}

pub struct CoinParticle {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	rot   f64
	v_rot f64
	life  f64
	max_l f64
	size  int
}

pub struct SlotsGame {
pub mut:
	theme          SlotTheme = .vegas_classic
	reels          []Reel
	num_reels      int = 3
	visible_rows   int = 3
	balance        int = 1000
	bet_per_line   int = 5
	active_lines   int = 5 // 1 to 5 for 3-reel, 1 to 20 for 5-reel
	last_win       int
	progressive_jackpot int = 25000
	is_spinning    bool
	spin_time      f64
	stopping_reels int
	winning_lines  []WinningLine
	free_spins     int
	free_spin_mult int = 1
	// Lever pull animation
	lever_pos      f64 = 0.0 // 0.0 top, 1.0 bottom
	lever_pulling  bool
	lever_dir      f64 = 1.0
	// Stats
	total_spins    int
	total_won      int
	total_bet      int
	celebration    string
	celeb_timer    f64
	show_paytable  bool
	particles      []CoinParticle
	// Grid cell dimensions
	reel_w         f64 = 92.0
	row_h          f64 = 82.0
	grid_x         f64 = 210.0
	grid_y         f64 = 170.0
}

// 20 Standard Payline configurations for 5-reel (3x5 grid)
pub const paylines_5x3 = [
	[1, 1, 1, 1, 1], // 1: Middle horizontal
	[0, 0, 0, 0, 0], // 2: Top horizontal
	[2, 2, 2, 2, 2], // 3: Bottom horizontal
	[0, 1, 2, 1, 0], // 4: V-shape
	[2, 1, 0, 1, 2], // 5: Inverted V
	[0, 0, 1, 2, 2], // 6: Top-to-bottom step
	[2, 2, 1, 0, 0], // 7: Bottom-to-top step
	[1, 0, 0, 0, 1], // 8: Top crest
	[1, 2, 2, 2, 1], // 9: Bottom valley
	[0, 1, 1, 1, 0], // 10: Shallow V
	[2, 1, 1, 1, 2], // 11: Shallow inverted V
	[0, 1, 0, 1, 0], // 12: Top zig-zag
	[2, 1, 2, 1, 2], // 13: Bottom zig-zag
	[1, 0, 1, 0, 1], // 14: Middle-top zig-zag
	[1, 2, 1, 2, 1], // 15: Middle-bottom zig-zag
	[0, 0, 1, 0, 0], // 16: Top arrow
	[2, 2, 1, 2, 2], // 17: Bottom arrow
	[1, 1, 0, 1, 1], // 18: Middle-high peak
	[1, 1, 2, 1, 1], // 19: Middle-low dip
	[0, 2, 0, 2, 0]  // 20: Extreme zig-zag
]

// 5 Standard Paylines for 3-reel (3x3 grid)
pub const paylines_3x3 = [
	[1, 1, 1], // 1: Center
	[0, 0, 0], // 2: Top
	[2, 2, 2], // 3: Bottom
	[0, 1, 2], // 4: Diagonal top-left to bottom-right
	[2, 1, 0]  // 5: Diagonal bottom-left to top-right
]

pub fn new_slots_game() SlotsGame {
	mut game := SlotsGame{
		theme: .vegas_classic
		reels: []Reel{cap: 5}
		num_reels: 3
		visible_rows: 3
		balance: 1000
		bet_per_line: 5
		active_lines: 5
		progressive_jackpot: 25000
	}
	game.init_theme(.vegas_classic)
	return game
}

pub fn (mut g SlotsGame) init_theme(theme SlotTheme) {
	g.theme = theme
	g.reels.clear()
	g.winning_lines.clear()
	g.is_spinning = false
	g.celebration = ''

	if theme == .vegas_classic {
		g.num_reels = 3
		g.active_lines = 5
		g.grid_x = 260.0
		g.reel_w = 96.0

		// Classic 3-reel strips (16 symbols per strip)
		strip_syms := [
			SymbolType.cherry, SymbolType.lemon, SymbolType.orange, SymbolType.plum,
			SymbolType.bar_single, SymbolType.cherry, SymbolType.bell, SymbolType.bar_double,
			SymbolType.orange, SymbolType.bar_triple, SymbolType.lemon, SymbolType.seven,
			SymbolType.plum, SymbolType.diamond, SymbolType.wild, SymbolType.seven
		]

		for r := 0; r < 3; r++ {
			mut reel_strip := strip_syms.clone()
			// Stagger start offsets
			g.reels << Reel{
				symbols: reel_strip
				offset_y: f64(r * 4) * g.row_h
				stopped: true
			}
		}
	} else {
		// Neon Cyberpunk 5-reel
		g.num_reels = 5
		g.active_lines = 20
		g.grid_x = 160.0
		g.reel_w = 88.0

		cyber_syms := [
			SymbolType.cherry, SymbolType.lemon, SymbolType.orange, SymbolType.plum,
			SymbolType.bell, SymbolType.bar_single, SymbolType.wild, SymbolType.bar_double,
			SymbolType.orange, SymbolType.bar_triple, SymbolType.scatter, SymbolType.seven,
			SymbolType.diamond, SymbolType.wild, SymbolType.scatter, SymbolType.seven
		]

		for r := 0; r < 5; r++ {
			mut reel_strip := cyber_syms.clone()
			g.reels << Reel{
				symbols: reel_strip
				offset_y: f64(r * 3) * g.row_h
				stopped: true
			}
		}
	}
}

pub fn (mut g SlotsGame) pull_lever(mut sound_mgr SoundManager) {
	if g.is_spinning {
		return
	}

	total_bet := g.bet_per_line * g.active_lines
	if g.balance < total_bet && g.free_spins <= 0 {
		g.celebration = 'INSUFFICIENT BALANCE! PRESS [C] TO INSERT COINS'
		g.celeb_timer = 2.5
		return
	}

	if g.free_spins > 0 {
		g.free_spins--
	} else {
		g.balance -= total_bet
		g.total_bet += total_bet
		g.progressive_jackpot += int(f64(total_bet) * 0.05)
	}

	g.total_spins++
	g.is_spinning = true
	g.spin_time = 0.0
	g.stopping_reels = 0
	g.winning_lines.clear()
	g.celebration = ''
	g.lever_pulling = true
	g.lever_pos = 0.0
	g.lever_dir = 1.0

	sound_mgr.play_lever_pull()

	// Spin reels with varied initial speeds
	for i := 0; i < g.num_reels; i++ {
		mut reel := &g.reels[i]
		if !reel.hold {
			reel.speed_y = 1100.0 + f64(i) * 150.0
			reel.stopping = false
			reel.stopped = false
			reel.bounce_t = 0.0
		}
	}
}

pub fn (mut g SlotsGame) update(dt f64, mut sound_mgr SoundManager) {
	// Update celebration timer
	if g.celeb_timer > 0.0 {
		g.celeb_timer -= dt
		if g.celeb_timer <= 0.0 {
			g.celebration = ''
		}
	}

	// Update lever pull animation
	if g.lever_pulling {
		g.lever_pos += g.lever_dir * 5.0 * dt
		if g.lever_pos >= 1.0 {
			g.lever_pos = 1.0
			g.lever_dir = -1.0
		} else if g.lever_pos <= 0.0 && g.lever_dir < 0.0 {
			g.lever_pos = 0.0
			g.lever_pulling = false
		}
	}

	// Update Coin Particles
	for i := g.particles.len - 1; i >= 0; i-- {
		mut p := &g.particles[i]
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 650.0 * dt // Gravity
		p.rot += p.v_rot * dt
		p.life -= dt
		if p.life <= 0.0 {
			g.particles.delete(i)
		}
	}

	if g.is_spinning {
		g.spin_time += dt

		// Staggered reel stop timing: Reel 0 stops at 1.2s, Reel 1 at 1.6s, etc.
		for i := 0; i < g.num_reels; i++ {
			mut reel := &g.reels[i]
			if reel.hold || reel.stopped {
				continue
			}

			stop_delay := 1.0 + f64(i) * 0.45

			if g.spin_time > stop_delay && !reel.stopping {
				reel.stopping = true
				// Pick landing symbol index
				reel.target_stop = rand.int_in_range(0, reel.symbols.len) or { 0 }
			}

			if reel.stopping {
				// Decelerate smoothly to target grid row alignment
				target_y := f64(reel.target_stop) * g.row_h
				mut diff := target_y - reel.offset_y
				strip_total_h := f64(reel.symbols.len) * g.row_h

				// Wrap diff into positive range
				for diff < 0.0 {
					diff += strip_total_h
				}

				if diff < 15.0 && reel.speed_y < 350.0 {
					reel.offset_y = target_y
					reel.speed_y = 0.0
					reel.stopping = false
					reel.stopped = true
					reel.bounce_t = 0.15
					sound_mgr.play_reel_stop(i)
					g.stopping_reels++

					// If all reels stopped, evaluate paylines!
					if g.stopping_reels >= g.num_reels {
						g.evaluate_spin_payouts(mut sound_mgr)
					}
				} else {
					reel.speed_y = math.max(180.0, reel.speed_y - 1200.0 * dt)
					reel.offset_y += reel.speed_y * dt
				}
			} else {
				reel.offset_y += reel.speed_y * dt
			}

			// Wrap offset around strip height
			strip_total_h := f64(reel.symbols.len) * g.row_h
			if reel.offset_y >= strip_total_h {
				reel.offset_y -= strip_total_h
			}
		}
	}
}

// Get symbol currently visible at [reel_idx, row_idx (0..2)]
pub fn (g &SlotsGame) get_visible_symbol(reel_idx int, row_idx int) SymbolType {
	reel := g.reels[reel_idx]
	base_idx := int(math.round(reel.offset_y / g.row_h))
	idx := (base_idx + row_idx) % reel.symbols.len
	return reel.symbols[idx]
}

pub fn (mut g SlotsGame) evaluate_spin_payouts(mut sound_mgr SoundManager) {
	g.is_spinning = false
	g.winning_lines.clear()
	mut total_spin_win := 0
	mut scatter_count := 0

	// 1. Evaluate Line Payouts
	if g.theme == .vegas_classic {
		for line_idx := 0; line_idx < g.active_lines; line_idx++ {
			line_cfg := paylines_3x3[line_idx]
			s0 := g.get_visible_symbol(0, line_cfg[0])
			s1 := g.get_visible_symbol(1, line_cfg[1])
			s2 := g.get_visible_symbol(2, line_cfg[2])

			payout, match_sym := evaluate_3reel_line(s0, s1, s2, g.bet_per_line)
			if payout > 0 {
				total_spin_win += payout
				mut positions := []CellPos{cap: 3}
				positions << CellPos{ reel: 0, row: line_cfg[0] }
				positions << CellPos{ reel: 1, row: line_cfg[1] }
				positions << CellPos{ reel: 2, row: line_cfg[2] }

				g.winning_lines << WinningLine{
					line_idx: line_idx
					symbol: match_sym
					count: 3
					payout: payout
					positions: positions
				}
			}
		}
	} else {
		// 5-Reel Video Slot
		for line_idx := 0; line_idx < g.active_lines; line_idx++ {
			line_cfg := paylines_5x3[line_idx]
			mut symbols := []SymbolType{cap: 5}
			for r := 0; r < 5; r++ {
				symbols << g.get_visible_symbol(r, line_cfg[r])
			}

			payout, match_sym, match_len := evaluate_5reel_line(symbols, g.bet_per_line)
			if payout > 0 {
				total_spin_win += payout
				mut positions := []CellPos{cap: match_len}
				for r := 0; r < match_len; r++ {
					positions << CellPos{ reel: r, row: line_cfg[r] }
				}

				g.winning_lines << WinningLine{
					line_idx: line_idx
					symbol: match_sym
					count: match_len
					payout: payout
					positions: positions
				}
			}
		}

		// Count Scatters across all visible cells
		for r := 0; r < 5; r++ {
			for row := 0; row < 3; row++ {
				if g.get_visible_symbol(r, row) == .scatter {
					scatter_count++
				}
			}
		}

		// 3+ Scatters trigger Free Spins Bonus Round!
		if scatter_count >= 3 {
			awarded_spins := match scatter_count {
				3 { 10 }
				4 { 15 }
				else { 25 }
			}
			g.free_spins += awarded_spins
			g.free_spin_mult = 3
			g.celebration = 'SCATTER BONUS! ${awarded_spins} FREE SPINS (3X MULTIPLIER)!!'
			g.celeb_timer = 4.0
			sound_mgr.play_jackpot_fanfare()
		}
	}

	// Apply Free Spin Multipliers
	if g.free_spin_mult > 1 {
		total_spin_win *= g.free_spin_mult
	}

	g.last_win = total_spin_win
	g.balance += total_spin_win
	g.total_won += total_spin_win

	// Check Mega Jackpot / Celebration
	if total_spin_win > 0 {
		// Spawn Coin Fountain
		g.spawn_coin_fountain(math.min(100, total_spin_win / 5 + 15))

		if total_spin_win >= g.bet_per_line * g.active_lines * 50 {
			g.celebration = 'MEGA JACKPOT!! $${total_spin_win} WON!!'
			g.celeb_timer = 5.0
			sound_mgr.play_jackpot_fanfare()
		} else if total_spin_win >= g.bet_per_line * g.active_lines * 10 {
			g.celebration = 'BIG WIN!! $${total_spin_win}'
			g.celeb_timer = 3.0
			sound_mgr.play_win_chime()
		} else {
			g.celebration = 'WIN: $${total_spin_win}'
			g.celeb_timer = 2.0
			sound_mgr.play_win_chime()
			sound_mgr.play_coin_payout()
		}
	} else {
		sound_mgr.play_lose_sound()
	}

	// Reset holds
	for mut reel in g.reels {
		reel.hold = false
	}
}

pub fn evaluate_3reel_line(s0 SymbolType, s1 SymbolType, s2 SymbolType, bet int) (int, SymbolType) {
	// Diamond 3x (Jackpot: 500x)
	if (s0 == .diamond || s0 == .wild) && (s1 == .diamond || s1 == .wild) && (s2 == .diamond || s2 == .wild) {
		return bet * 500, SymbolType.diamond
	}
	// Lucky 7 3x (200x)
	if (s0 == .seven || s0 == .wild) && (s1 == .seven || s1 == .wild) && (s2 == .seven || s2 == .wild) {
		return bet * 200, SymbolType.seven
	}
	// Triple BAR (100x)
	if (s0 == .bar_triple || s0 == .wild) && (s1 == .bar_triple || s1 == .wild) && (s2 == .bar_triple || s2 == .wild) {
		return bet * 100, SymbolType.bar_triple
	}
	// Double BAR (50x)
	if (s0 == .bar_double || s0 == .wild) && (s1 == .bar_double || s1 == .wild) && (s2 == .bar_double || s2 == .wild) {
		return bet * 50, SymbolType.bar_double
	}
	// Single BAR (30x)
	if (s0 == .bar_single || s0 == .wild) && (s1 == .bar_single || s1 == .wild) && (s2 == .bar_single || s2 == .wild) {
		return bet * 30, SymbolType.bar_single
	}
	// Any 3 BARs combination (15x)
	if is_any_bar(s0) && is_any_bar(s1) && is_any_bar(s2) {
		return bet * 15, SymbolType.bar_single
	}
	// Bell 3x (25x)
	if (s0 == .bell || s0 == .wild) && (s1 == .bell || s1 == .wild) && (s2 == .bell || s2 == .wild) {
		return bet * 25, SymbolType.bell
	}
	// Plum 3x (15x)
	if (s0 == .plum || s0 == .wild) && (s1 == .plum || s1 == .wild) && (s2 == .plum || s2 == .wild) {
		return bet * 15, SymbolType.plum
	}
	// Orange 3x (10x)
	if (s0 == .orange || s0 == .wild) && (s1 == .orange || s1 == .wild) && (s2 == .orange || s2 == .wild) {
		return bet * 10, SymbolType.orange
	}
	// Lemon 3x (8x)
	if (s0 == .lemon || s0 == .wild) && (s1 == .lemon || s1 == .wild) && (s2 == .lemon || s2 == .wild) {
		return bet * 8, SymbolType.lemon
	}
	// Cherry 3x (20x), 2x (5x), 1x (2x)
	if s0 == .cherry && s1 == .cherry && s2 == .cherry {
		return bet * 20, SymbolType.cherry
	} else if s0 == .cherry && s1 == .cherry {
		return bet * 5, SymbolType.cherry
	} else if s0 == .cherry {
		return bet * 2, SymbolType.cherry
	}

	return 0, SymbolType.cherry
}

pub fn evaluate_5reel_line(symbols []SymbolType, bet int) (int, SymbolType, int) {
	first_sym := symbols[0]
	mut target := first_sym
	mut match_len := 1

	for i := 1; i < 5; i++ {
		sym := symbols[i]
		if target == .wild && sym != .wild && sym != .scatter {
			target = sym
			match_len++
		} else if sym == target || sym == .wild {
			match_len++
		} else {
			break
		}
	}

	if match_len < 3 {
		return 0, target, match_len
	}

	mult := match target {
		.diamond { match match_len { 5 { 1000 } 4 { 250 } else { 60 } } }
		.seven { match match_len { 5 { 500 } 4 { 150 } else { 40 } } }
		.bar_triple { match match_len { 5 { 250 } 4 { 80 } else { 25 } } }
		.bar_double { match match_len { 5 { 150 } 4 { 50 } else { 15 } } }
		.bar_single { match match_len { 5 { 100 } 4 { 30 } else { 10 } } }
		.bell { match match_len { 5 { 80 } 4 { 25 } else { 8 } } }
		.plum { match match_len { 5 { 60 } 4 { 20 } else { 6 } } }
		.orange { match match_len { 5 { 40 } 4 { 15 } else { 5 } } }
		.lemon { match match_len { 5 { 30 } 4 { 10 } else { 4 } } }
		.cherry { match match_len { 5 { 25 } 4 { 8 } else { 3 } } }
		.wild { match match_len { 5 { 1500 } 4 { 400 } else { 100 } } }
		else { 0 }
	}

	return bet * mult, target, match_len
}

fn is_any_bar(s SymbolType) bool {
	return s == .bar_single || s == .bar_double || s == .bar_triple || s == .wild
}

fn (mut g SlotsGame) spawn_coin_fountain(count int) {
	for _ in 0 .. count {
		g.particles << CoinParticle{
			x: 400.0 + (rand.f64() * 80.0 - 40.0)
			y: 520.0
			vx: (rand.f64() * 320.0 - 160.0)
			vy: -(380.0 + rand.f64() * 260.0)
			rot: rand.f64() * 6.28
			v_rot: (rand.f64() * 12.0 - 6.0)
			life: 1.5
			max_l: 1.5
			size: 8
		}
	}
}

pub fn (mut g SlotsGame) toggle_hold(reel_idx int) {
	if !g.is_spinning && reel_idx >= 0 && reel_idx < g.num_reels && g.theme == .vegas_classic {
		g.reels[reel_idx].hold = !g.reels[reel_idx].hold
	}
}

pub fn (mut g SlotsGame) adjust_bet(delta int) {
	new_bet := g.bet_per_line + delta
	if new_bet >= 1 && new_bet <= 500 {
		g.bet_per_line = new_bet
	}
}

pub fn (mut g SlotsGame) adjust_lines(delta int) {
	max_l := if g.theme == .vegas_classic { 5 } else { 20 }
	new_lines := g.active_lines + delta
	if new_lines >= 1 && new_lines <= max_l {
		g.active_lines = new_lines
	}
}

pub fn (mut g SlotsGame) max_bet() {
	g.bet_per_line = 100
	g.active_lines = if g.theme == .vegas_classic { 5 } else { 20 }
}

pub fn (mut g SlotsGame) add_credits(amount int) {
	g.balance += amount
	g.celebration = '+$${amount} CREDITS INSERTED!'
	g.celeb_timer = 2.0
}
