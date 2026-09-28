module main

fn test_duke_sectors_loading() {
	mut g := new_duke_game()
	assert g.level_num == 1
	assert g.cameras_total == 3
	assert g.cameras_left == 3

	// Load Sector 2
	g.load_sector(2)
	assert g.level_num == 2
	assert g.cameras_total == 4
	assert g.cameras_left == 4
	assert g.sector_name.contains('REACTOR')

	// Load Sector 3
	g.load_sector(3)
	assert g.level_num == 3
	assert g.boss.active == true
	assert g.boss.hp == 35
	assert g.sector_name.contains('ORBITAL')
}

fn test_jump_and_gravity() {
	mut g := new_duke_game()
	g.player.on_ground = true
	jumped := g.player_jump()
	assert jumped == true
	assert g.player.vy < 0.0
	assert g.player.on_ground == false

	// Update with gravity
	g.update(0.1, 0, 0, false, false)
	assert g.player.vy > -380.0
}

fn test_keycard_and_door_unlocking() {
	mut g := new_duke_game()
	// Red door at [14][35]
	assert g.tiles[14][35] == 5

	// Position player adjacent to door without key
	g.player.x = f64(34 * tile_sz + 10.0)
	g.player.y = f64(14 * tile_sz)
	g.player.dir = 1
	g.player.has_red_key = false

	g.update(0.05, 1, 0, false, false)
	assert g.tiles[14][35] == 5 // still locked

	// Give Red Keycard
	g.player.has_red_key = true
	ev := g.update(0.05, 1, 0, false, false)
	assert ev.unlocked_door == true
	assert g.tiles[14][35] == 0 // unlocked!
}

fn test_shooting_and_camera_destruction() {
	mut g := new_duke_game()
	g.player.weapon = .blaster
	shot := g.player_shoot()
	assert shot == true
	assert g.bullets.len == 1
	assert g.bullets[0].damage == 1

	// Test hitting a camera destructible
	g.destructs[0].x = 100.0
	g.destructs[0].y = 100.0
	g.destructs[0].hp = 1
	g.destructs[0].is_camera = true

	g.bullets[0].x = 105.0
	g.bullets[0].y = 105.0

	ev := g.update(0.01, 0, 0, false, false)
	assert g.destructs[0].active == false
	assert ev.camera_destroyed == true
	assert g.cameras_left == 2
}

fn test_boss_battle_damage() {
	mut g := new_duke_game()
	g.load_sector(3)
	assert g.boss.active == true
	initial_hp := g.boss.hp

	// Fire missile at boss
	g.bullets << Bullet{
		x: g.boss.x + 10.0
		y: g.boss.y + 10.0
		vx: 100.0
		vy: 0.0
		rad: 7.0
		damage: 5
		@type: .missile
		is_enemy: false
	}

	ev := g.update(0.01, 0, 0, false, false)
	assert ev.boss_hit == true
	assert g.boss.hp == initial_hp - 5
}

fn test_ladder_climb_and_top_dismount() {
	mut g := new_duke_game()
	// Ladder at col 8, rows 15..19
	assert g.tiles[15][8] == 3
	assert g.tiles[14][8] == 0 // Air above ladder

	// Place player on ladder
	g.player.x = f64(8 * tile_sz + 6.0)
	g.player.y = f64(17 * tile_sz)
	g.player.on_ground = false

	// Climb UP towards top
	for _ in 0 .. 50 {
		g.update(0.05, 0, -1, false, false)
		if g.player.on_ground {
			break
		}
	}

	// Should have successfully dismounted on top platform
	assert g.player.on_ground == true
	assert g.player.is_climbing == false
	assert int(g.player.y + g.player.h) == 15 * int(tile_sz)

	// Can now move horizontally onto platform (col 9)
	initial_x := g.player.x
	g.update(0.05, 1, 0, false, false)
	assert g.player.x > initial_x
}

