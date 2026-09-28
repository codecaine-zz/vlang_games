module main

fn test_dartboard_bullseye_detection() {
	// Center (0,0) is Double Bullseye (50)
	hit_center := calculate_dart_hit(0.0, 0.0)
	assert hit_center.is_double_bull == true
	assert hit_center.score == 50

	// Radius 20mm is Outer Bullseye (25)
	hit_outer := calculate_dart_hit(20.0, 0.0)
	assert hit_outer.is_bull == true
	assert hit_outer.is_double_bull == false
	assert hit_outer.score == 25
}

fn test_dartboard_triple_20_detection() {
	// Top 20 is at -Y, radius between r_triple_in and r_triple_out (around 105px)
	hit_t20 := calculate_dart_hit(0.0, -105.0)
	assert hit_t20.base_num == 20
	assert hit_t20.multiplier == 3
	assert hit_t20.score == 60
}

fn test_501_checkout_hint() {
	mut g := new_darts_game()
	g.players[0].score_left = 170
	g.update_checkout_hint()
	assert g.checkout_hint == 'T20 -> T20 -> BULL'

	g.players[0].score_left = 40
	g.update_checkout_hint()
	assert g.checkout_hint == 'DOUBLE 20'

	g.players[0].score_left = 32
	g.update_checkout_hint()
	assert g.checkout_hint == 'DOUBLE 16'
}
