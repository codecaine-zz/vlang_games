module main

fn test_missilecommand_initialization() {
	mut g := new_missilecommand_game()
	assert g.silos.len == 3
	assert g.cities.len == 6
	assert g.silos[0].ammo == 10
	assert g.cities[0].active
}

fn test_missilecommand_fire_interceptor() {
	mut g := new_missilecommand_game()
	g.fire_interceptor(400.0, 300.0)
	assert g.interceptors.len == 1
	assert g.silos[1].ammo == 9
}

fn test_missilecommand_blast_expansion() {
	mut g := new_missilecommand_game()
	g.fire_interceptor(400.0, 300.0)
	g.update(0.3)
	g.update(0.3)
	assert g.blasts.len > 0
}

fn test_missilecommand_reset() {
	mut g := new_missilecommand_game()
	g.fire_interceptor(400.0, 300.0)
	g.reset_game()
	assert g.silos[0].ammo == 10
	assert g.cities[0].active
	assert g.interceptors.len == 0
}
