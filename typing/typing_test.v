module main

fn test_game_init() {
	mut g := new_game_engine()
	assert g.state == .title
	assert g.mode == .arcade
	assert g.shields == 4
	assert g.stars.len > 50
	assert g.high_score >= 15000
}

fn test_word_dictionaries() {
	assert short_words.len > 50
	assert medium_words.len > 50
	assert long_boss_words.len > 30
	assert code_words.len > 50
	assert emp_words.len > 5

	w_short := get_random_word(0, false)
	assert w_short.len >= 3 && w_short.len <= 5

	w_code := get_random_word(0, true)
	assert w_code.len >= 3
}

fn test_targeting_and_typing() {
	mut g := new_game_engine()
	g.start_game(.arcade)
	mut sm := SoundManager{ sound_enabled: false }

	// Clear auto-spawned enemies and inject known enemy
	g.enemies.clear()
	g.enemies << EnemyShip{
		id: 101
		word: 'laser'
		typed_count: 0
		enemy_type: .scout
		x: 200.0
		y: 100.0
		vx: 0.0
		vy: 30.0
		width: 100.0
		height: 32.0
		alive: true
		color: Color{ r: 255, g: 120, b: 120 }
	}

	assert g.locked_enemy_id == -1

	// Type 'l' -> Locks onto target 101 and increments typed_count to 1
	g.handle_character_input(`l`, mut sm)
	assert g.locked_enemy_id == 101
	assert g.enemies[0].typed_count == 1
	assert g.combo_streak == 1
	assert g.lasers.len == 1

	// Type 'a' -> typed_count becomes 2
	g.handle_character_input(`a`, mut sm)
	assert g.enemies[0].typed_count == 2
	assert g.combo_streak == 2

	// Type incorrect letter 'x' -> resets combo streak
	g.handle_character_input(`x`, mut sm)
	assert g.enemies[0].typed_count == 2
	assert g.combo_streak == 0

	// Finish word: 's', 'e', 'r'
	g.handle_character_input(`s`, mut sm)
	g.handle_character_input(`e`, mut sm)
	g.handle_character_input(`r`, mut sm)

	// Enemy should be destroyed and lock released
	assert !g.enemies[0].alive
	assert g.locked_enemy_id == -1
	assert g.words_typed == 1
	assert g.score > 0
}

fn test_emp_nuke_blast() {
	mut g := new_game_engine()
	g.start_game(.arcade)
	mut sm := SoundManager{ sound_enabled: false }

	g.enemies.clear()
	// EMP word
	g.enemies << EnemyShip{
		id: 1
		word: 'nuke'
		typed_count: 0
		enemy_type: .emp_nuke
		x: 100.0
		y: 100.0
		alive: true
		color: Color{ r: 0, g: 240, b: 255 }
	}
	// Normal enemy 1
	g.enemies << EnemyShip{
		id: 2
		word: 'plasma'
		typed_count: 0
		enemy_type: .cruiser
		x: 300.0
		y: 150.0
		alive: true
		color: Color{ r: 255, g: 215, b: 0 }
	}
	// Normal enemy 2
	g.enemies << EnemyShip{
		id: 3
		word: 'quantum'
		typed_count: 0
		enemy_type: .dreadnought
		x: 500.0
		y: 200.0
		alive: true
		color: Color{ r: 255, g: 60, b: 180 }
	}

	// Complete the EMP word 'nuke'
	g.handle_character_input(`n`, mut sm)
	g.handle_character_input(`u`, mut sm)
	g.handle_character_input(`k`, mut sm)
	g.handle_character_input(`e`, mut sm)

	// All other enemies should have been obliterated by the EMP blast
	assert !g.enemies[0].alive
	assert !g.enemies[1].alive
	assert !g.enemies[2].alive
	assert g.words_typed >= 3
}

fn test_time_freeze_and_shield_repair() {
	mut g := new_game_engine()
	g.start_game(.arcade)
	g.shields = 2 // Damaged shields
	mut sm := SoundManager{ sound_enabled: false }

	g.enemies.clear()
	// Freeze word
	g.enemies << EnemyShip{
		id: 10
		word: 'freeze'
		typed_count: 0
		enemy_type: .time_freeze
		alive: true
	}
	// Shield word
	g.enemies << EnemyShip{
		id: 11
		word: 'heal'
		typed_count: 0
		enemy_type: .shield_repair
		alive: true
	}

	// Type freeze
	for ch in 'freeze' {
		g.handle_character_input(ch, mut sm)
	}
	assert g.freeze_timer > 3.0

	// Type heal
	for ch in 'heal' {
		g.handle_character_input(ch, mut sm)
	}
	assert g.shields == 3 // Restored 1 shield point
}

fn test_wpm_and_accuracy_calculations() {
	mut g := new_game_engine()
	g.start_game(.arcade)

	g.game_timer = 60.0 // 1 minute
	g.correct_keystrokes = 200 // 200 / 5 = 40 words
	g.total_keystrokes = 250   // 200 / 250 = 80% accuracy

	wpm := g.calculate_wpm()
	assert wpm == 40

	acc := g.calculate_accuracy()
	assert acc == 80
}

fn test_game_modes() {
	mut g := new_game_engine()

	g.set_mode(.speed_blitz)
	g.start_game(.speed_blitz)
	assert g.mode == .speed_blitz
	assert g.blitz_timer == 60.0

	g.set_mode(.code_words)
	g.start_game(.code_words)
	assert g.mode == .code_words

	g.cycle_mode()
	assert g.mode == .endless
}
