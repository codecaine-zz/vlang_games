module main

import math
import rand

pub enum PetStage {
	egg
	baby
	child
	teen
	adult
}

pub enum PetAction {
	none
	eat_meal
	eat_snack
	play_game
	clean_poop
	take_medicine
	sleep_toggle
	discipline
	view_stats
}

pub enum GameMiniStage {
	choose_dir
	show_result
}

pub struct TamagotchiGame {
pub mut:
	stage           PetStage = .baby
	name            string   = 'Mametchi'
	age_days        int      = 1
	weight_oz       int      = 5
	hunger          int      = 3 // 0 to 4 hearts
	happiness       int      = 3 // 0 to 4 hearts
	discipline      int      = 50 // 0 to 100%
	energy          int      = 100 // 0 to 100%
	is_sleeping     bool
	is_sick         bool
	poop_count      int
	attention_needed bool
	
	// Lifecycle & Animation timers
	age_timer       f64
	anim_timer      f64
	frame_idx       int
	pet_x           int = 12 // 0 to 24 in 32-wide LCD grid
	pet_dir         int = 1
	idle_action_t   f64

	// Menu & Actions
	selected_icon   int      // 0 to 7 (Food, Light, Game, Med, Bath, Stats, Disc, Alert)
	active_action   PetAction = .none
	action_timer    f64
	dialog_msg      string
	dialog_timer    f64

	// Mini-game state (Guess Left or Right)
	mini_stage      GameMiniStage = .choose_dir
	player_guess    int // 0: Left, 1: Right
	pet_choice      int // 0: Left, 1: Right
	game_round      int
	game_wins       int
	mini_timer      f64
	toast_msg       string
	toast_timer     f64
}

pub fn new_tamagotchi_game() TamagotchiGame {
	mut g := TamagotchiGame{}
	saved := load_tama_save()
	if saved.save_state_valid {
		g.load_state()
	} else {
		g.reset_pet()
	}
	return g
}

pub fn (mut g TamagotchiGame) reset_pet() {
	g.stage = .baby
	g.name = 'Mametchi'
	g.age_days = 0
	g.weight_oz = 5
	g.hunger = 3
	g.happiness = 3
	g.discipline = 20
	g.energy = 100
	g.is_sleeping = false
	g.is_sick = false
	g.poop_count = 0
	g.attention_needed = false
	g.age_timer = 0.0
	g.anim_timer = 0.0
	g.frame_idx = 0
	g.pet_x = 12
	g.pet_dir = 1
	g.selected_icon = 0
	g.active_action = .none
	g.dialog_msg = 'A NEW PET HATCHED!'
	g.dialog_timer = 3.0
}

pub fn (mut g TamagotchiGame) update(dt f64) {
	g.anim_timer += dt
	if g.anim_timer >= 0.35 {
		g.anim_timer = 0.0
		g.frame_idx = (g.frame_idx + 1) % 4
		
		// Pet wandering on LCD screen
		if g.active_action == .none && !g.is_sleeping {
			g.pet_x += g.pet_dir
			if g.pet_x <= 4 {
				g.pet_x = 4
				g.pet_dir = 1
			} else if g.pet_x >= 20 {
				g.pet_x = 20
				g.pet_dir = -1
			}
		}
	}

	// Dialog timer
	if g.dialog_timer > 0.0 {
		g.dialog_timer -= dt
		if g.dialog_timer <= 0.0 {
			g.dialog_msg = ''
		}
	}

	// Action timer
	if g.action_timer > 0.0 {
		g.action_timer -= dt
		if g.action_timer <= 0.0 {
			g.finish_active_action()
		}
	}

	// Mini game timer
	if g.active_action == .play_game && g.mini_stage == .show_result {
		g.mini_timer -= dt
		if g.mini_timer <= 0.0 {
			g.advance_mini_game()
		}
	}

	// Real-time decay (accelerated for fun demo play)
	g.age_timer += dt
	if g.age_timer >= 45.0 {
		g.age_timer = 0.0
		g.age_days++
		
		if !g.is_sleeping {
			if g.hunger > 0 { g.hunger-- }
			if g.happiness > 0 { g.happiness-- }
		}

		// Stage progression
		if g.stage == .baby && g.age_days >= 1 {
			g.stage = .child
			g.dialog_msg = '${g.name} EVOLVED TO CHILD!'
			g.dialog_timer = 3.5
		} else if g.stage == .child && g.age_days >= 3 {
			g.stage = .teen
			g.dialog_msg = '${g.name} EVOLVED TO TEEN!'
			g.dialog_timer = 3.5
		} else if g.stage == .teen && g.age_days >= 6 {
			g.stage = .adult
			g.dialog_msg = '${g.name} REACHED ADULT!'
			g.dialog_timer = 3.5
		}

		// Poop check
		if g.hunger < 2 && g.poop_count < 3 {
			g.poop_count++
		}
	}

	// Attention check
	g.attention_needed = (g.hunger == 0 || g.happiness == 0 || g.is_sick || g.poop_count >= 2) && !g.is_sleeping
}

pub fn (mut g TamagotchiGame) button_a() {
	// A: Next Menu Icon / Left in Mini-game
	if g.active_action == .play_game && g.mini_stage == .choose_dir {
		g.choose_mini_dir(0) // Guess Left
		return
	}

	if g.active_action == .none {
		g.selected_icon = (g.selected_icon + 1) % 8
	}
}

pub fn (mut g TamagotchiGame) button_b() {
	// B: Confirm / Right in Mini-game
	if g.active_action == .play_game && g.mini_stage == .choose_dir {
		g.choose_mini_dir(1) // Guess Right
		return
	}

	if g.active_action != .none {
		if g.active_action == .view_stats {
			g.active_action = .none
		}
		return
	}

	match g.selected_icon {
		0 {
			// Feed Meal
			if g.hunger < 4 {
				g.hunger = math.min(4, g.hunger + 1)
				g.weight_oz++
				g.active_action = .eat_meal
				g.action_timer = 2.0
				g.dialog_msg = 'YUMMY MEAL! +1 MEAL'
				g.dialog_timer = 2.0
			} else {
				g.dialog_msg = 'ALREADY FULL!'
				g.dialog_timer = 2.0
			}
		}
		1 {
			// Toggle Light / Sleep
			g.is_sleeping = !g.is_sleeping
			g.dialog_msg = if g.is_sleeping { 'LIGHTS OFF - SLEEPING' } else { 'LIGHTS ON - AWAKE' }
			g.dialog_timer = 2.0
		}
		2 {
			// Play Game (Guess direction)
			if !g.is_sleeping {
				g.start_mini_game()
			}
		}
		3 {
			// Medicine
			if g.is_sick {
				g.is_sick = false
				g.active_action = .take_medicine
				g.action_timer = 2.0
				g.dialog_msg = 'MEDICINE CURED SICKNESS!'
				g.dialog_timer = 2.5
			} else {
				g.dialog_msg = 'PET IS HEALTHY!'
				g.dialog_timer = 2.0
			}
		}
		4 {
			// Clean Bath / Poop
			if g.poop_count > 0 {
				g.poop_count = 0
				g.active_action = .clean_poop
				g.action_timer = 2.0
				g.dialog_msg = 'CLEANED UP! SPARKLE!'
				g.dialog_timer = 2.0
			} else {
				g.dialog_msg = 'ALREADY CLEAN!'
				g.dialog_timer = 1.5
			}
		}
		5 {
			// View Stats Meter
			g.active_action = .view_stats
		}
		6 {
			// Discipline
			if !g.is_sleeping {
				g.discipline = math.min(100, g.discipline + 25)
				g.active_action = .discipline
				g.action_timer = 2.0
				g.dialog_msg = 'DISCIPLINE PRAISE! +25%'
				g.dialog_timer = 2.0
			}
		}
		else {}
	}
}

pub fn (mut g TamagotchiGame) button_c() {
	// C: Cancel / Return to Idle
	if g.active_action != .none {
		g.active_action = .none
		g.dialog_msg = ''
	}
}

fn (mut g TamagotchiGame) start_mini_game() {
	g.active_action = .play_game
	g.mini_stage = .choose_dir
	g.game_round = 1
	g.game_wins = 0
	g.dialog_msg = 'ROUND 1/5: GUESS (A:LEFT, B:RIGHT)'
	g.dialog_timer = 2.5
}

fn (mut g TamagotchiGame) choose_mini_dir(dir int) {
	g.player_guess = dir
	g.pet_choice = rand.intn(2) or { 0 }
	g.mini_stage = .show_result
	g.mini_timer = 1.5

	if g.player_guess == g.pet_choice {
		g.game_wins++
		g.dialog_msg = 'CORRECT! (${g.game_wins}/5 WINS)'
	} else {
		g.dialog_msg = 'WRONG! (${g.game_wins}/5 WINS)'
	}
	g.dialog_timer = 1.5
}

fn (mut g TamagotchiGame) advance_mini_game() {
	if g.game_round < 5 {
		g.game_round++
		g.mini_stage = .choose_dir
		g.dialog_msg = 'ROUND ${g.game_round}/5: (A:LEFT, B:RIGHT)'
		g.dialog_timer = 2.0
	} else {
		// Game Over
		if g.game_wins >= 3 {
			g.happiness = math.min(4, g.happiness + 2)
			g.weight_oz = math.max(2, g.weight_oz - 1)
			g.dialog_msg = 'YOU WON! HAPPY PET +2 HEARTS!'
		} else {
			g.happiness = math.min(4, g.happiness + 1)
			g.dialog_msg = 'GOOD EFFORT! +1 HEART'
		}
		g.dialog_timer = 3.0
		g.active_action = .none
	}
}

fn (mut g TamagotchiGame) finish_active_action() {
	g.active_action = .none
	g.save_progress()
}

pub fn (mut g TamagotchiGame) save_progress() {
	mut saved := load_tama_save()
	saved.save_state_valid = true
	saved.stage_idx = int(g.stage)
	saved.name = g.name
	saved.age_days = g.age_days
	saved.weight_oz = g.weight_oz
	saved.hunger = g.hunger
	saved.happiness = g.happiness
	saved.discipline = g.discipline
	saved.energy = g.energy
	saved.is_sleeping = g.is_sleeping
	saved.is_sick = g.is_sick
	saved.poop_count = g.poop_count
	save_tama_data(&saved)
}

pub fn (mut g TamagotchiGame) save_state() {
	g.save_progress()
	g.toast_msg = 'PET SAVED (F5)'
	g.toast_timer = 2.0
}

pub fn (mut g TamagotchiGame) load_state() {
	saved := load_tama_save()
	if !saved.save_state_valid {
		g.toast_msg = 'NO SAVE FOUND'
		g.toast_timer = 2.0
		return
	}
	g.stage = unsafe { PetStage(saved.stage_idx) }
	g.name = saved.name
	g.age_days = saved.age_days
	g.weight_oz = saved.weight_oz
	g.hunger = saved.hunger
	g.happiness = saved.happiness
	g.discipline = saved.discipline
	g.energy = saved.energy
	g.is_sleeping = saved.is_sleeping
	g.is_sick = saved.is_sick
	g.poop_count = saved.poop_count
	g.toast_msg = 'PET LOADED (F9)'
	g.toast_timer = 2.0
}
