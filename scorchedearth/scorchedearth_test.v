module main

fn test_scorched_initialization() {
	mut g := new_scorched_game()
	assert g.round == 1
	assert g.tanks.len == 2
	assert g.terrain_y.len == 920
	assert !g.tanks[0].is_dead
	assert !g.tanks[1].is_dead
	assert g.tanks[0].cash >= 1000
}

fn test_scorched_firing_and_ballistics() {
	mut g := new_scorched_game()
	assert g.projectiles.len == 0
	assert g.fire_shot()
	assert g.projectiles.len == 1
	assert g.projectiles[0].active

	// Advance physics
	g.update(0.1)
	assert g.projectiles[0].trail.len >= 2
}

fn test_scorched_weapon_shop_and_buying() {
	mut g := new_scorched_game()
	g.tanks[0].cash = 1000
	assert g.buy_weapon(.baby_nuke)
	assert g.tanks[0].cash == 1000 - 350
	assert g.tanks[0].inventory[WeaponType.baby_nuke.str()] == 3
}

fn test_scorched_direct_hit_and_death() {
	mut g := new_scorched_game()
	bot_x := g.tanks[1].x
	bot_y := g.tanks[1].y

	// Launch projectile right at the bot
	p := Projectile{
		wtype: .standard
		x: f64(bot_x)
		y: f64(bot_y - 8)
		vx: 0
		vy: 10
		owner_id: 0
		active: true
	}
	g.detonate_projectile(p)

	assert g.tanks[1].health == 0
	assert g.tanks[1].is_dead
	assert g.tanks[0].kills == 1
	assert g.damage_texts.len > 0
}
