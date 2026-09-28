module main

import os

pub struct GoldSaveData {
pub mut:
	high_score       int
	max_level        int = 1
	save_state_valid bool
	money            int
	level            int = 1
	target_money     int = 650
	time_left        f64 = 60.0
	dynamite_count   int = 1
	has_strength     bool
	has_clover       bool
	has_rock_val     bool
}

pub fn get_gold_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'goldminer')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'goldminer')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'goldminer')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_gold_save() GoldSaveData {
	path := get_gold_save_path()
	if !os.exists(path) {
		return GoldSaveData{}
	}
	lines := os.read_lines(path) or { return GoldSaveData{} }
	mut data := GoldSaveData{}

	for line in lines {
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'high_score' { data.high_score = val.int() }
			'max_level' { data.max_level = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			'money' { data.money = val.int() }
			'level' { data.level = val.int() }
			'target_money' { data.target_money = val.int() }
			'time_left' { data.time_left = val.f64() }
			'dynamite_count' { data.dynamite_count = val.int() }
			'has_strength' { data.has_strength = val.bool() }
			'has_clover' { data.has_clover = val.bool() }
			'has_rock_val' { data.has_rock_val = val.bool() }
			else {}
		}
	}
	return data
}

pub fn save_gold_data(data &GoldSaveData) {
	path := get_gold_save_path()
	mut content := 'high_score=${data.high_score}\n'
	content += 'max_level=${data.max_level}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'money=${data.money}\n'
	content += 'level=${data.level}\n'
	content += 'target_money=${data.target_money}\n'
	content += 'time_left=${data.time_left}\n'
	content += 'dynamite_count=${data.dynamite_count}\n'
	content += 'has_strength=${data.has_strength}\n'
	content += 'has_clover=${data.has_clover}\n'
	content += 'has_rock_val=${data.has_rock_val}\n'
	os.write_file(path, content) or {}
}
