module main

fn test_player_creation_and_starting_weapons() {
	p1 := create_player(0, .antonio, 100.0, 100.0)
	assert p1.name == 'Antonio'
	assert p1.weapons.len == 1
	assert p1.weapons[0].kind == .whip

	p2 := create_player(1, .imelda, 100.0, 100.0)
	assert p2.name == 'Imelda'
	assert p2.weapons.len == 1
	assert p2.weapons[0].kind == .magic_wand

	p3 := create_player(2, .pasqualina, 100.0, 100.0)
	assert p3.weapons[0].kind == .holy_bible

	p4 := create_player(3, .gennaro, 100.0, 100.0)
	assert p4.weapons[0].kind == .knife
}

fn test_distance_and_normalization() {
	d := dist(0.0, 0.0, 3.0, 4.0)
	assert int(d) == 5

	nx, ny := normalize(10.0, 0.0)
	assert int(nx) == 1
	assert int(ny) == 0

	zx, zy := normalize(0.0, 0.0)
	assert zx == 0.0 && zy == 0.0
}

fn test_weapon_creation_and_passives() {
	mut w := create_weapon(.whip)
	assert w.level == 1
	assert w.damage >= 20.0

	mut p := create_player(0, .antonio, 500.0, 500.0)
	assert p.get_passive_level(.spinach) == 0

	p.passives << Passive{kind: .spinach, level: 2}
	assert p.get_passive_level(.spinach) == 2
}

fn test_level_up_and_upgrade_selection() {
	mut g := new_game()
	g.start_game(.antonio, .imelda, false)
	assert g.players[0].level == 1

	g.trigger_level_up(0)
	assert g.state == .level_up
	assert g.upgrade_cards.len >= 1

	g.select_upgrade(0)
	assert g.state == .playing
}

fn test_enemy_creation_and_types() {
	bat := create_enemy(.bat, 100.0, 100.0, false)
	assert bat.hp >= 8.0
	assert bat.speed >= 110.0

	reaper := create_enemy(.reaper_boss, 100.0, 100.0, true)
	assert reaper.is_boss
	assert reaper.hp >= 1500.0
}

fn test_sound_bgm_cycle() {
	mut sm := new_sound_manager()
	assert sm.bgm_track == .gothic_rondo
	sm.cycle_bgm()
	assert sm.bgm_track == .vampires_eclipse
	sm.cycle_bgm()
	assert sm.bgm_track == .bloodlust_symphony
	sm.cycle_bgm()
	assert sm.bgm_track == .off
	sm.cycle_bgm()
	assert sm.bgm_track == .gothic_rondo
}

fn test_weapon_evolutions_and_pickups() {
	mut p := create_player(0, .antonio, 200.0, 200.0)
	p.weapons[0].level = 8
	p.passives << Passive{kind: .spinach, level: 1}

	evo, ok := get_weapon_evolution(.whip, &p)
	assert ok
	assert evo == .bloody_tear

	bt := create_weapon(.bloody_tear)
	assert bt.is_evolved
	assert bt.damage >= 40.0

	mut g := new_game()
	g.save_data = SaveData{}
	g.start_game(.antonio, .imelda, false)
	g.breakables << BreakableProp{x: 150.0, y: 150.0, hp: 1.0, is_urn: false}
	assert g.breakables.len >= 1

	// Test floor pickups collection
	g.collect_floor_pickup(.floor_chicken, 0)
	assert g.players[0].hp == 120.0

	g.collect_floor_pickup(.freeze_watch, 0)
	assert g.frozen_timer >= 5.0

	// Test Ultimate Ability
	assert g.players[0].ultimate_meter >= 100.0
	g.activate_ultimate(0)
	assert g.players[0].ultimate_meter == 0.0
	assert g.projectiles.len >= 16

	// Test Massive Horde Weapons
	nuke := create_weapon(.cataclysm_nuke)
	assert nuke.damage >= 100.0
	laser := create_weapon(.prismatic_laser)
	assert laser.speed >= 600.0

	// Test Speed Cycle
	assert g.game_speed == 1.0
	g.cycle_speed()
	assert g.game_speed == 1.5
	g.cycle_speed()
	assert g.game_speed == 2.0
	g.cycle_speed()
	assert g.game_speed == 3.0
	g.cycle_speed()
	assert g.game_speed == 1.0

	// Test Difficulty Cycle and Scaling
	assert g.difficulty == .hard
	g.cycle_difficulty()
	assert g.difficulty == .inferno
	inferno_bat := g.create_scaled_enemy(.bat, 100.0, 100.0, false, false)
	assert inferno_bat.hp >= 30.0
	g.cycle_difficulty()
	assert g.difficulty == .normal
}

fn test_all_weapon_evolutions_and_new_passives() {
	mut p := create_player(0, .antonio, 200.0, 200.0)

	// Lightning Ring + Duplicator -> Thunder Loop
	p.passives << Passive{kind: .duplicator, level: 1}
	evo1, ok1 := get_weapon_evolution(.lightning_ring, &p)
	assert ok1 && evo1 == .thunder_loop

	// Fire Wand + Spinach -> Hellfire
	p.passives << Passive{kind: .spinach, level: 1}
	evo2, ok2 := get_weapon_evolution(.fire_wand, &p)
	assert ok2 && evo2 == .hellfire

	// Cataclysm Nuke + Hollow Heart -> Supernova
	p.passives << Passive{kind: .hollow_heart, level: 1}
	evo3, ok3 := get_weapon_evolution(.cataclysm_nuke, &p)
	assert ok3 && evo3 == .supernova

	// Prismatic Laser + Clover -> Gamma Ray
	p.passives << Passive{kind: .clover, level: 1}
	evo4, ok4 := get_weapon_evolution(.prismatic_laser, &p)
	assert ok4 && evo4 == .gamma_ray

	// Verify weapon creation stats
	tl := create_weapon(.thunder_loop)
	assert tl.is_evolved && tl.count >= 6
	hf := create_weapon(.hellfire)
	assert hf.is_evolved && hf.damage >= 100.0
	sn := create_weapon(.supernova)
	assert sn.is_evolved && sn.damage >= 200.0
	gr := create_weapon(.gamma_ray)
	assert gr.is_evolved && gr.speed >= 700.0
}

fn test_reroll_skip_banish_and_slot_limits() {
	mut g := new_game()
	g.start_game(.antonio, .imelda, false)

	assert g.players[0].rerolls == 2
	assert g.players[0].skips == 2
	assert g.players[0].banishes == 2

	g.trigger_level_up(0)
	assert g.state == .level_up
	initial_card := g.upgrade_cards[0].name

	// Banish card 0
	g.banish_upgrade(0, 0)
	assert g.players[0].banishes == 1
	assert initial_card in g.players[0].banished_items

	// Reroll upgrades
	g.reroll_upgrades(0)
	assert g.players[0].rerolls == 1

	// Skip upgrade
	g.skip_upgrade(0)
	assert g.players[0].skips == 1
	assert g.state == .playing

	// Test 6-Weapon Slot Limit
	for w_k in [WeaponType.magic_wand, WeaponType.knife, WeaponType.axe, WeaponType.holy_bible, WeaponType.garlic] {
		g.players[0].weapons << create_weapon(w_k)
	}
	assert g.players[0].weapons.len == 6
}

fn test_30min_victory_condition() {
	mut g := new_game()
	g.start_game(.antonio, .imelda, false)
	assert g.state == .playing

	g.update(1801.0)
	assert g.state == .victory
}

fn test_powerup_shop_and_save_data() {
	mut g := new_game()
	g.save_data = SaveData{
		unlocked_stages: ['mad_forest']
		unlocked_chars:  ['antonio', 'imelda', 'pasqualina', 'gennaro']
	}
	g.save_data.total_gold = 1000
	g.buy_powerup('might')
	assert g.save_data.might_lvl == 1
	assert g.save_data.total_gold == 750

	g.buy_powerup('health')
	assert g.save_data.health_lvl == 1
	assert g.save_data.total_gold == 500

	g.start_game(.antonio, .imelda, false)
	assert g.players[0].max_hp == 130.0
}

fn test_dash_and_stages() {
	mut g := new_game()
	g.start_game(.antonio, .imelda, false)
	assert g.stage == .mad_forest

	g.cycle_stage()
	assert g.stage == .inlaid_library

	g.perform_dash(0)
	assert g.players[0].is_dashing
	assert g.players[0].dash_cooldown > 0
}

fn test_new_characters() {
	p_mort := create_player(0, .mortaccio, 100.0, 100.0)
	assert p_mort.name == 'Mortaccio'
	assert p_mort.weapons[0].kind == .axe

	p_elea := create_player(0, .eleanor, 100.0, 100.0)
	assert p_elea.name == 'Eleanor'
	assert p_elea.weapons[0].kind == .prismatic_laser
}

fn test_stage_progression_and_waves() {
	mut g := new_game()
	g.start_game(.antonio, .imelda, false)

	// Test stage multipliers
	forest_bat := g.create_scaled_enemy(.bat, 100.0, 100.0, false, false)
	g.stage = .castle_grounds
	castle_bat := g.create_scaled_enemy(.bat, 100.0, 100.0, false, false)
	assert castle_bat.hp > forest_bat.hp
	assert castle_bat.damage > forest_bat.damage

	// Test wave progression events
	g.game_time = 91.0
	g.stage_event_idx = 0
	g.update_spawner(0.016)
	assert g.stage_event_idx == 1
	assert g.wave_title.len > 0
}


