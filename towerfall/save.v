module main

import os

pub struct TowerFallSaveData {
pub mut:
	high_score       int
	max_quest_wave   int = 1
	unlocked_arenas  int = 1
	save_state_valid bool
	mode             int // 0 = menu, 1 = quest, 2 = versus
	quest_wave       int = 1
	score            int
	p1_lives         int = 3
	p1_arrows        int = 3
	p1_x             f64 = 100.0
	p1_y             f64 = 400.0
	p2_lives         int = 3
	p2_arrows        int = 3
	p2_x             f64 = 700.0
	p2_y             f64 = 400.0
	arena_idx        int
}

pub fn get_towerfall_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'towerfall')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'towerfall')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'towerfall')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_towerfall_save() TowerFallSaveData {
	path := get_towerfall_save_path()
	if !os.exists(path) {
		return TowerFallSaveData{}
	}
	lines := os.read_lines(path) or { return TowerFallSaveData{} }
	mut data := TowerFallSaveData{}

	for line in lines {
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'high_score' { data.high_score = val.int() }
			'max_quest_wave' { data.max_quest_wave = val.int() }
			'unlocked_arenas' { data.unlocked_arenas = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			'mode' { data.mode = val.int() }
			'quest_wave' { data.quest_wave = val.int() }
			'score' { data.score = val.int() }
			'p1_lives' { data.p1_lives = val.int() }
			'p1_arrows' { data.p1_arrows = val.int() }
			'p1_x' { data.p1_x = val.f64() }
			'p1_y' { data.p1_y = val.f64() }
			'p2_lives' { data.p2_lives = val.int() }
			'p2_arrows' { data.p2_arrows = val.int() }
			'p2_x' { data.p2_x = val.f64() }
			'p2_y' { data.p2_y = val.f64() }
			'arena_idx' { data.arena_idx = val.int() }
			else {}
		}
	}
	return data
}

pub fn save_towerfall_data(data &TowerFallSaveData) {
	path := get_towerfall_save_path()
	mut content := 'high_score=${data.high_score}\n'
	content += 'max_quest_wave=${data.max_quest_wave}\n'
	content += 'unlocked_arenas=${data.unlocked_arenas}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'mode=${data.mode}\n'
	content += 'quest_wave=${data.quest_wave}\n'
	content += 'score=${data.score}\n'
	content += 'p1_lives=${data.p1_lives}\n'
	content += 'p1_arrows=${data.p1_arrows}\n'
	content += 'p1_x=${data.p1_x}\n'
	content += 'p1_y=${data.p1_y}\n'
	content += 'p2_lives=${data.p2_lives}\n'
	content += 'p2_arrows=${data.p2_arrows}\n'
	content += 'p2_x=${data.p2_x}\n'
	content += 'p2_y=${data.p2_y}\n'
	content += 'arena_idx=${data.arena_idx}\n'
	os.write_file(path, content) or {}
}
