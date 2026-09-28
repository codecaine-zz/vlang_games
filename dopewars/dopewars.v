module main

import math
import rand

pub enum Borough {
	manhattan
	bronx
	brooklyn
	queens
	staten_island
	coney_island
}

pub struct DrugInfo {
pub:
	name      string
	min_price int
	max_price int
}

pub const drug_catalogue = [
	DrugInfo{'Acid', 1000, 4400},
	DrugInfo{'Cocaine', 15000, 29000},
	DrugInfo{'Hashish', 480, 1280},
	DrugInfo{'Heroin', 5500, 13000},
	DrugInfo{'Ludes', 11, 60},
	DrugInfo{'MDA', 1500, 4400},
	DrugInfo{'Opium', 540, 1250},
	DrugInfo{'Weed', 315, 890},
]

pub enum UIState {
	market
	subway
	bank
	loan_shark
	police_encounter
	game_over_screen
}

pub struct DopeWarsGame {
pub mut:
	day             int = 1
	max_days        int = 30
	current_loc     Borough = .manhattan
	ui_state        UIState = .market

	cash            int = 2000
	bank            int
	debt            int = 5500
	health          int = 100
	max_pockets     int = 100

	inventory       map[string]int
	market_prices   map[string]int

	police_count    int
	is_game_over    bool

	sound_event     string
	banner_text     string
	banner_timer    f64
	selected_drug   int
	high_score      int
	toast_msg       string
	toast_timer     f64
}

pub fn new_dopewars_game() DopeWarsGame {
	mut g := DopeWarsGame{
		inventory: map[string]int{}
		market_prices: map[string]int{}
	}
	g.init_game()
	return g
}

pub fn (mut g DopeWarsGame) init_game() {
	g.day = 1
	g.current_loc = .manhattan
	g.ui_state = .market
	g.cash = 2000
	g.bank = 0
	g.debt = 5500
	g.health = 100
	g.max_pockets = 100
	g.is_game_over = false
	g.selected_drug = 7 // Select 'Weed' by default since it's affordable ($315-$890) with starting $2,000

	g.inventory.clear()
	for d in drug_catalogue {
		g.inventory[d.name] = 0
	}

	g.generate_market_prices()
	g.banner_text = 'WELCOME TO DOPE WARS! CLICK OR USE KEYS [1-8], [B], [S], [T]'
	g.banner_timer = 4.0
}

pub fn (mut g DopeWarsGame) generate_market_prices() {
	g.market_prices.clear()
	for d in drug_catalogue {
		// 90% chance drug is available in this borough
		if rand.f64() < 0.90 {
			price := d.min_price + rand.int_in_range(0, d.max_price - d.min_price) or { 0 }
			g.market_prices[d.name] = price
		}
	}
}

pub fn (g DopeWarsGame) get_used_pockets() int {
	mut total := 0
	for _, qty in g.inventory {
		total += qty
	}
	return total
}

pub fn (mut g DopeWarsGame) buy_drug(drug_idx int, amount int) bool {
	if drug_idx < 0 || drug_idx >= drug_catalogue.len {
		return false
	}
	d := drug_catalogue[drug_idx]
	if !(d.name in g.market_prices) {
		g.banner_text = '${d.name.to_upper()} IS NOT AVAILABLE IN THIS BOROUGH'
		g.banner_timer = 2.0
		return false
	}
	price := g.market_prices[d.name]

	available_space := g.max_pockets - g.get_used_pockets()
	if available_space <= 0 {
		g.banner_text = 'TRENCHCOAT IS FULL! (${g.max_pockets}/${g.max_pockets} UNITS)'
		g.banner_timer = 2.0
		return false
	}

	max_affordable := g.cash / price
	if max_affordable <= 0 {
		g.banner_text = 'NOT ENOUGH CASH! 1X ${d.name.to_upper()} COSTS $${price} (YOU HAVE $${g.cash})'
		g.banner_timer = 2.5
		return false
	}

	actual_qty := math.min(amount, math.min(available_space, max_affordable))
	if actual_qty <= 0 {
		return false
	}

	cost := actual_qty * price
	g.cash -= cost
	g.inventory[d.name] += actual_qty
	g.sound_event = 'cash'
	g.banner_text = 'BOUGHT ${actual_qty}X ${d.name.to_upper()} FOR $${cost}'
	g.banner_timer = 2.5
	return true
}

pub fn (mut g DopeWarsGame) sell_drug(drug_idx int, amount int) bool {
	if drug_idx < 0 || drug_idx >= drug_catalogue.len {
		return false
	}
	d := drug_catalogue[drug_idx]
	if !(d.name in g.market_prices) {
		g.banner_text = 'CANNOT SELL: NO BUYERS FOR ${d.name.to_upper()} IN THIS BOROUGH'
		g.banner_timer = 2.0
		return false
	}
	price := g.market_prices[d.name]

	owned := g.inventory[d.name]
	if owned <= 0 {
		g.banner_text = 'YOU DO NOT OWN ANY ${d.name.to_upper()} TO SELL'
		g.banner_timer = 2.0
		return false
	}

	actual_qty := math.min(amount, owned)
	if actual_qty <= 0 {
		return false
	}

	revenue := actual_qty * price
	g.cash += revenue
	g.inventory[d.name] -= actual_qty
	g.sound_event = 'cash'
	g.banner_text = 'SOLD ${actual_qty}X ${d.name.to_upper()} FOR $${revenue}'
	g.banner_timer = 2.5
	return true
}

pub fn (mut g DopeWarsGame) travel_to(loc Borough) {
	if loc == g.current_loc || g.is_game_over {
		return
	}
	g.current_loc = loc
	g.day++
	g.sound_event = 'subway'

	// Compound Loan Shark Debt (10% per day)
	if g.debt > 0 {
		g.debt = int(f64(g.debt) * 1.10)
	}

	// Bank Interest (5% per day)
	if g.bank > 0 {
		g.bank = int(f64(g.bank) * 1.05)
	}

	g.generate_market_prices()

	// Check for Random Events (Police Chase, Price Spikes)
	roll := rand.f64()
	if roll < 0.15 {
		// Police Encounter!
		g.police_count = 2 + rand.int_in_range(0, 4) or { 2 }
		g.ui_state = .police_encounter
		g.sound_event = 'siren'
		g.banner_text = 'OFFICER BOB AND ${g.police_count} DEPUTIES ARE CHASING YOU!'
		g.banner_timer = 3.5
		return
	} else if roll < 0.35 {
		// Random Market Spike
		d_idx := rand.int_in_range(0, drug_catalogue.len) or { 0 }
		d_name := drug_catalogue[d_idx].name
		if d_name in g.market_prices {
			g.market_prices[d_name] *= 3
			g.banner_text = 'COPS RAIDED STASH! ${d_name.to_upper()} PRICES TRIPLED!'
			g.banner_timer = 3.0
		}
	}

	if g.day > g.max_days {
		g.ui_state = .game_over_screen
		g.is_game_over = true
		g.banner_text = 'DAY 30 COMPLETED! FINAL NET WORTH CALCULATED'
		g.banner_timer = 6.0
	} else {
		g.ui_state = .market
		g.banner_text = 'ARRIVED IN ${g.get_loc_name(loc).to_upper()} (DAY ${g.day}/30)'
		g.banner_timer = 2.5
	}
}

pub fn (g DopeWarsGame) get_loc_name(loc Borough) string {
	return match loc {
		.manhattan { 'Manhattan' }
		.bronx { 'The Bronx' }
		.brooklyn { 'Brooklyn' }
		.queens { 'Queens' }
		.staten_island { 'Staten Island' }
		.coney_island { 'Coney Island' }
	}
}

pub fn (g DopeWarsGame) get_net_worth() int {
	return g.cash + g.bank - g.debt
}

pub fn (mut g DopeWarsGame) deposit_bank(amount int) {
	actual := math.min(amount, g.cash)
	if actual > 0 {
		g.cash -= actual
		g.bank += actual
		g.sound_event = 'cash'
		g.banner_text = 'DEPOSITED $${actual} INTO 1ST NATIONAL BANK'
		g.banner_timer = 2.0
	} else {
		g.banner_text = 'NO CASH TO DEPOSIT'
		g.banner_timer = 1.5
	}
}

pub fn (mut g DopeWarsGame) withdraw_bank(amount int) {
	actual := math.min(amount, g.bank)
	if actual > 0 {
		g.bank -= actual
		g.cash += actual
		g.sound_event = 'cash'
		g.banner_text = 'WITHDREW $${actual} FROM BANK'
		g.banner_timer = 2.0
	} else {
		g.banner_text = 'NO BANK FUNDS TO WITHDRAW'
		g.banner_timer = 1.5
	}
}

pub fn (mut g DopeWarsGame) pay_debt(amount int) {
	actual := math.min(amount, math.min(g.cash, g.debt))
	if actual > 0 {
		g.cash -= actual
		g.debt -= actual
		g.sound_event = 'cash'
		g.banner_text = 'PAID $${actual} TO LOAN SHARK (REMAINING DEBT: $${g.debt})'
		g.banner_timer = 2.0
	} else {
		g.banner_text = if g.debt == 0 { 'DEBT IS FULLY PAID OFF!' } else { 'NO CASH TO PAY DEBT' }
		g.banner_timer = 1.5
	}
}

pub fn (mut g DopeWarsGame) handle_police_action(action string) {
	match action {
		'run' {
			if rand.f64() < 0.65 {
				g.ui_state = .market
				g.banner_text = 'YOU LOST THE COPS IN THE SUBWAY TUNNEL!'
				g.banner_timer = 2.5
			} else {
				// Cops shoot at you
				dmg := 20 + rand.int_in_range(0, 25) or { 15 }
				g.health -= dmg
				g.sound_event = 'gunshot'
				if g.health <= 0 {
					g.health = 0
					g.is_game_over = true
					g.ui_state = .game_over_screen
					g.banner_text = 'YOU WERE SHOT BY THE POLICE! GAME OVER'
					g.banner_timer = 5.0
				} else {
					g.banner_text = 'HIT BY BULLET (-${dmg} HP)! KEEP RUNNING!'
					g.banner_timer = 2.0
				}
			}
		}
		'bribe' {
			bribe_cost := g.police_count * 1000
			if g.cash >= bribe_cost {
				g.cash -= bribe_cost
				g.ui_state = .market
				g.sound_event = 'cash'
				g.banner_text = 'OFFICER BOB TOOK THE $${bribe_cost} BRIBE AND WALKED AWAY'
				g.banner_timer = 3.0
			} else {
				g.banner_text = 'NOT ENOUGH CASH TO BRIBE! ($${bribe_cost} REQUIRED)'
				g.banner_timer = 2.0
			}
		}
		else {}
	}
}

pub fn (mut g DopeWarsGame) update(dt f64) {
	if g.banner_timer > 0.0 {
		g.banner_timer -= dt
	}
	if g.toast_timer > 0.0 {
		g.toast_timer -= dt
	}
}

pub fn (mut g DopeWarsGame) save_progress() {
	net_worth := g.cash + g.bank - g.debt
	if net_worth > g.high_score {
		g.high_score = net_worth
	}
	mut saved := load_dope_save()
	saved.high_score = g.high_score
	saved.day = g.day
	saved.cash = g.cash
	saved.bank = g.bank
	saved.debt = g.debt
	saved.health = g.health
	saved.max_pockets = g.max_pockets
	saved.location_idx = int(g.current_loc)

	mut pairs := []string{}
	for k, v in g.inventory {
		if v > 0 {
			pairs << '${k}:${v}'
		}
	}
	saved.inventory_pairs = pairs
	save_dope_data(&saved)
}

pub fn (mut g DopeWarsGame) save_state() {
	g.save_progress()
	g.toast_msg = 'GAME SAVED (F5)'
	g.toast_timer = 2.0
}

pub fn (mut g DopeWarsGame) load_state() {
	saved := load_dope_save()
	if saved.high_score > 0 {
		g.high_score = saved.high_score
	}
	g.day = saved.day
	g.cash = saved.cash
	g.bank = saved.bank
	g.debt = saved.debt
	g.health = saved.health
	g.max_pockets = saved.max_pockets
	g.current_loc = unsafe { Borough(saved.location_idx) }
	
	g.inventory.clear()
	for pair in saved.inventory_pairs {
		parts := pair.split(':')
		if parts.len == 2 {
			g.inventory[parts[0]] = parts[1].int()
		}
	}
	g.ui_state = .market
	g.toast_msg = 'GAME LOADED (F9)'
	g.toast_timer = 2.0
}
