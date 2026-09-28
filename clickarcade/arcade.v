module main

pub enum ArcadeScreen {
	menu
	gem_rush
	chain_reaction
	whack_monster
	blade_slicer
}

pub struct MenuButton {
pub:
	id       int
	x        int
	y        int
	w        int
	h        int
	title    string
	subtitle string
	tag      string
	color    Color
}

pub struct Star {
pub mut:
	x     f64
	y     f64
	speed f64
	size  int
	color Color
}

pub struct ArcadeManager {
pub mut:
	screen            ArcadeScreen = .menu
	hovered_btn       int = -1
	buttons           []MenuButton
	stars             []Star

	// Mini game instances
	gem_game          GemRushGame
	chain_game        ChainReactionGame
	whack_game        WhackMonsterGame
	blade_game        BladeSlicerGame

	// High scores & stats
	total_clicks      int
	gem_rush_best     f64
	chain_best_score  int
	chain_best_level  int
	whack_best_score  int
	blade_best_score  int
}

pub fn new_arcade_manager() ArcadeManager {
	mut btns := []MenuButton{}

	// 4 Game selection cards
	btns << MenuButton{
		id: 0
		x: 60
		y: 160
		w: 360
		h: 170
		title: 'GEM RUSH TYCOON'
		subtitle: 'Deep Idle Clicker & Upgrades'
		tag: 'CLICK & ASCEND'
		color: col_gold
	}

	btns << MenuButton{
		id: 1
		x: 460
		y: 160
		w: 360
		h: 170
		title: 'CHAIN REACTION'
		subtitle: 'Atomic Cascade Physics Puzzle'
		tag: 'ONE CLICK BOOM'
		color: col_cyan
	}

	btns << MenuButton{
		id: 2
		x: 60
		y: 360
		w: 360
		h: 170
		title: 'WHACK-A-BOSS'
		subtitle: 'Rapid Monster Reflex Smasher'
		tag: 'STREAK COMBOS'
		color: col_green
	}

	btns << MenuButton{
		id: 3
		x: 460
		y: 360
		w: 360
		h: 170
		title: 'BLADE SLICER'
		subtitle: 'Juicy Fruit Slicing & Combos'
		tag: 'SWIPE & CUT'
		color: col_pink
	}

	mut stars := []Star{cap: 60}
	for i in 0 .. 60 {
		stars << Star{
			x: f64(i * 15 + 7)
			y: f64((i * 23) % 600)
			speed: 15.0 + f64((i * 17) % 35)
			size: if i % 4 == 0 { 2 } else { 1 }
			color: if i % 3 == 0 { col_cyan } else if i % 5 == 0 { col_pink } else { col_gray }
		}
	}

	saved := load_clickarcade_save()
	mut am := ArcadeManager{
		screen: .menu
		buttons: btns
		stars: stars
		gem_game: new_gem_rush_game()
		chain_game: new_chain_reaction_game()
		whack_game: new_whack_monster_game()
		blade_game: new_blade_slicer_game()
		total_clicks: saved.total_clicks
		gem_rush_best: saved.gem_rush_best
		chain_best_score: saved.chain_best_score
		chain_best_level: saved.chain_best_level
		whack_best_score: saved.whack_best_score
		blade_best_score: saved.blade_best_score
	}
	return am
}

pub fn (mut am ArcadeManager) update(dt f64, mut sm SoundManager) {
	// Background starfield
	for mut s in am.stars {
		s.y += s.speed * dt
		if s.y > 600.0 {
			s.y = 0.0
			s.x = f64(int(s.x + 83.0) % 880)
		}
	}

	match am.screen {
		.menu {}
		.gem_rush {
			am.gem_game.update(dt)
			if am.gem_game.total_gems_earned > am.gem_rush_best {
				am.gem_rush_best = am.gem_game.total_gems_earned
			}
		}
		.chain_reaction {
			am.chain_game.update(dt, mut sm)
			if am.chain_game.score > am.chain_best_score {
				am.chain_best_score = am.chain_game.score
			}
			if am.chain_game.level > am.chain_best_level {
				am.chain_best_level = am.chain_game.level
			}
		}
		.whack_monster {
			am.whack_game.update(dt)
			if am.whack_game.score > am.whack_best_score {
				am.whack_best_score = am.whack_game.score
			}
		}
		.blade_slicer {
			am.blade_game.update(dt)
			if am.blade_game.score > am.blade_best_score {
				am.blade_best_score = am.blade_game.score
			}
		}
	}
	am.save_progress()
}

pub fn (mut am ArcadeManager) save_progress() {
	mut saved := load_clickarcade_save()
	saved.total_clicks = am.total_clicks
	saved.gem_rush_best = am.gem_rush_best
	saved.chain_best_score = am.chain_best_score
	saved.chain_best_level = am.chain_best_level
	saved.whack_best_score = am.whack_best_score
	saved.blade_best_score = am.blade_best_score
	save_clickarcade_data(&saved)
}
