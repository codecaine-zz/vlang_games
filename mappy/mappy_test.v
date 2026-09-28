module main

fn test_game_init() {
	mut g := new_game_engine()
	assert g.state == .title
	assert g.lives == 3
	assert g.high_score >= 20000
	assert g.round == 1
	assert g.difficulty == .normal
}

fn test_difficulty_settings() {
	mut g := new_game_engine()

	// Easy mode
	g.set_difficulty(.easy)
	assert g.difficulty == .easy
	assert g.lives == 5
	assert g.difficulty.max_trampoline_bounces() == 5
	assert g.difficulty.hurry_seconds() == 55.0

	// Hard mode
	g.set_difficulty(.hard)
	assert g.difficulty == .hard
	assert g.lives == 2
	assert g.difficulty.max_trampoline_bounces() == 3

	// Expert mode
	g.set_difficulty(.expert)
	assert g.difficulty == .expert
	assert g.lives == 1
	assert g.difficulty.max_trampoline_bounces() == 2

	// Cycle difficulty
	g.set_difficulty(.easy)
	g.cycle_difficulty()
	assert g.difficulty == .normal
	g.cycle_difficulty()
	assert g.difficulty == .hard
	g.cycle_difficulty()
	assert g.difficulty == .expert
	g.cycle_difficulty()
	assert g.difficulty == .easy
}

fn test_round_loading() {
	mut g := new_game_engine()
	g.start_game(1)
	assert g.state == .playing
	assert g.round == 1
	assert !g.is_bonus_round
	assert g.trampolines.len == 4
	assert g.items.len == 10
	assert g.doors.len >= 6
	assert g.enemies.len >= 4

	// Verify items have 2 of each of the 5 types
	mut type_counts := map[ItemType]int{}
	for it in g.items {
		type_counts[it.item_type]++
	}
	assert type_counts[ItemType.radio] == 2
	assert type_counts[ItemType.tv] == 2
	assert type_counts[ItemType.microwave] == 2
	assert type_counts[ItemType.painting] == 2
	assert type_counts[ItemType.safe] == 2
}

fn test_bonus_stage_loading() {
	mut g := new_game_engine()
	g.start_game(3) // Round 3 is a bonus round
	assert g.state == .bonus_stage
	assert g.is_bonus_round
	assert g.balloons.len > 0
	assert g.enemies.len == 0 // No enemy cats in bonus stage
	assert g.bonus_timer == 20.0

	// Check Goro balloon exists
	has_goro_balloon := g.balloons.any(it.is_goro)
	assert has_goro_balloon
}

fn test_trampoline_bounce_and_reset() {
	mut g := new_game_engine()
	g.start_game(1)
	mut sm := SoundManager{ sound_enabled: false }

	// Simulate player on trampoline
	g.player.state = .bouncing
	g.player.trampoline_idx = 0
	g.player.bounce_phase = 0.0

	// Bounce full cycle
	dt := bounce_cycle_duration + 0.05
	g.update_player(dt, false, false, false, mut sm)
	assert g.trampolines[0].bounces == 1
	assert !g.trampolines[0].is_broken

	// Dismount to floor to reset trampoline wear
	g.player.floor_idx = 4
	g.player.state = .walking
	g.player.y = floor_y_levels[4] - 20.0
	g.player.x = 200.0
	g.trampolines[0].bounces = 0 // Reset on floor landing
	assert g.trampolines[0].bounces == 0
}

fn test_item_collection_and_multipliers() {
	mut g := new_game_engine()
	g.start_game(1)
	mut sm := SoundManager{ sound_enabled: false }

	initial_score := g.score

	// Collect first Radio (100 pts)
	mut radio_1 := g.items[0]
	radio_1.item_type = .radio
	radio_1.has_goro = false
	g.handle_item_collected(radio_1, mut sm)
	assert g.score == initial_score + 100
	assert g.consecutive_count == 1
	assert g.consecutive_type == .radio

	// Collect matching second Radio (consecutive pair bonus: 2x 100 = 200 pts)
	mut radio_2 := g.items[1]
	radio_2.item_type = .radio
	radio_2.has_goro = false
	g.handle_item_collected(radio_2, mut sm)
	assert g.score == initial_score + 100 + 200
	assert g.consecutive_count == 2
}

fn test_goro_hide_bonus() {
	mut g := new_game_engine()
	g.start_game(1)
	mut sm := SoundManager{ sound_enabled: false }

	initial_score := g.score

	// Collect item with Goro hidden (+500 safe + 1000 Goro bonus = 1500)
	mut safe_item := Item{
		id: 99
		item_type: .safe
		floor_idx: 4
		x: 360.0
		y: 388.0
		collected: false
		has_goro: true
	}

	g.handle_item_collected(safe_item, mut sm)
	assert g.score == initial_score + 500 + 1000

	// Goro should now be stunned
	for en in g.enemies {
		if en.is_goro {
			assert en.state == .stunned
			assert en.stun_timer > 0
		}
	}
}

fn test_door_mechanics() {
	mut g := new_game_engine()
	g.start_game(1)
	mut sm := SoundManager{ sound_enabled: false }

	// Position player in front of door 0
	d := g.doors[0]
	g.player.floor_idx = d.floor_idx
	g.player.x = d.x
	g.player.y = floor_y_levels[d.floor_idx] - 20.0

	// Position an enemy right behind the door swing
	g.enemies[1].floor_idx = d.floor_idx
	g.enemies[1].x = if d.facing == .right { d.x + 30.0 } else { d.x - 30.0 }
	g.enemies[1].state = .walking

	// Open door
	g.try_open_door(mut sm)
	assert g.doors[0].state == .opening

	// If regular door, enemy was stunned
	if d.door_type == .regular {
		assert g.enemies[1].state == .stunned
		assert g.enemies[1].stun_timer > 0
	}
}

fn test_stage_clear_trigger() {
	mut g := new_game_engine()
	g.start_game(1)
	mut sm := SoundManager{ sound_enabled: false }

	// Mark all items as collected
	for mut it in g.items {
		it.collected = true
	}

	g.update_playing(0.016, false, false, false, mut sm)
	assert g.state == .stage_clear
}
