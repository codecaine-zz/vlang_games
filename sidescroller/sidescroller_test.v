module main

fn test_new_game_engine() {
	ge := new_game_engine()
	assert ge.state == .title
	assert ge.stage == 1
	assert ge.score == 0
	assert ge.player.hp == 100.0
	assert ge.player.shield == 50.0
	assert ge.player.bombs == 3
	assert ge.player.active_weapon == .pulse
	assert ge.player.ammo['PLS'] == 999
	assert ge.player.ammo['SPD'] == 60
}

fn test_weapon_switching() {
	mut ge := new_game_engine()
	ge.switch_weapon(true)
	assert ge.player.active_weapon == .spread

	ge.set_weapon_by_idx(3)
	assert ge.player.active_weapon == .missile

	ge.set_weapon_by_idx(6)
	assert ge.player.active_weapon == .hyper_laser
}

fn test_weapon_projectiles() {
	weapons := [
		WeaponType.pulse,
		.spread,
		.plasma,
		.missile,
		.flame,
		.grenade,
		.hyper_laser,
		.tesla,
	]
	for w in weapons {
		projs := create_projectiles(w, 100.0, 200.0, 1.0, 0.0, false, false)
		assert projs.len > 0
		info := get_weapon_info(w)
		assert info.name.len > 0
	}
}

fn test_player_damage_and_shield() {
	mut ge := new_game_engine()
	sm := new_sound_manager()

	// Initial HP=100, Shield=50
	ge.damage_player(30.0, &sm)
	assert ge.player.shield == 20.0
	assert ge.player.hp == 100.0

	// Further damage breaks shield (20 absorbed) and 20 hits HP (100 - 20 = 80)
	ge.damage_player(40.0, &sm)
	assert ge.player.shield == 0.0
	assert ge.player.hp == 80.0
}

fn test_powerup_application() {
	mut ge := new_game_engine()
	pu_shield := PowerUp{
		x:     100
		y:     100
		ptype: .shield_core
		wtype: .spread
	}
	ge.apply_powerup(pu_shield)
	assert ge.player.shield == ge.player.max_shield

	pu_overdrive := PowerUp{
		x:     100
		y:     100
		ptype: .overdrive
		wtype: .spread
	}
	ge.apply_powerup(pu_overdrive)
	assert ge.player.overdrive_timer > 0

	pu_drone := PowerUp{
		x:     100
		y:     100
		ptype: .combat_drone
		wtype: .spread
	}
	ge.apply_powerup(pu_drone)
	assert ge.player.drone_active == true

	pu_mult := PowerUp{
		x:     100
		y:     100
		ptype: .multiplier_orb
		wtype: .spread
	}
	ge.apply_powerup(pu_mult)
	assert ge.player.multiplier == 2
}

fn test_emp_bomb_clears_enemies() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game()

	ge.enemies << Enemy{
		id:        1
		etype:     .scout
		x:         200
		y:         200
		hp:        50
		max_hp:    50
		active:    true
		score_val: 100
	}

	assert ge.player.bombs == 3
	ge.trigger_emp_bomb(&sm)
	assert ge.player.bombs == 2
	assert ge.enemies[0].hp < 50
}

fn test_boss_spawning_and_stage_progression() {
	mut ge := new_game_engine()
	ge.start_game()
	assert ge.stage == 1

	ge.spawn_stage_boss()
	assert ge.enemies.len == 1
	assert ge.enemies[0].is_boss == true
	assert ge.enemies[0].hp == 600.0
}
