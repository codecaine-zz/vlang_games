module main

fn test_dopewars_initialization() {
	mut g := new_dopewars_game()
	assert g.day == 1
	assert g.cash == 2000
	assert g.debt == 5500
	assert g.current_loc == .manhattan
	assert g.inventory.len == drug_catalogue.len
}

fn test_dopewars_buying_and_selling() {
	mut g := new_dopewars_game()
	g.market_prices['Weed'] = 400
	g.cash = 2000

	// Buy 3 units of Weed
	assert g.buy_drug(7, 3)
	assert g.inventory['Weed'] == 3
	assert g.cash == 2000 - (3 * 400)
	assert g.get_used_pockets() == 3

	// Sell 2 units of Weed at higher price
	g.market_prices['Weed'] = 800
	assert g.sell_drug(7, 2)
	assert g.inventory['Weed'] == 1
	assert g.cash == 800 + (2 * 800)
}

fn test_dopewars_subway_travel_and_interest() {
	mut g := new_dopewars_game()
	init_debt := g.debt
	g.travel_to(.brooklyn)

	assert g.day == 2
	assert g.current_loc == .brooklyn
	assert g.debt > init_debt // 10% daily compound interest
}
