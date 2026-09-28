module main

fn test_new_tamagotchi_game() {
	g := new_tamagotchi_game()
	assert g.stage == .baby
	assert g.hunger == 3
	assert g.happiness == 3
	assert g.poop_count == 0
}

fn test_tamagotchi_feeding() {
	mut g := new_tamagotchi_game()
	g.hunger = 2
	g.selected_icon = 0 // Meal
	g.button_b()
	assert g.hunger == 3
	assert g.weight_oz == 6
}

fn test_tamagotchi_cleaning() {
	mut g := new_tamagotchi_game()
	g.poop_count = 2
	g.selected_icon = 4 // Bath
	g.button_b()
	assert g.poop_count == 0
}

fn test_tamagotchi_light_sleep() {
	mut g := new_tamagotchi_game()
	assert !g.is_sleeping
	g.selected_icon = 1 // Light
	g.button_b()
	assert g.is_sleeping
	g.button_b()
	assert !g.is_sleeping
}
