module main

import os

pub struct SaveData {
pub mut:
	high_score       int
	save_state_valid bool
	stage            int
	gems             int
	score            int
	weapon           WeaponType
}

pub fn get_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'downwell')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'downwell')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'downwell')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_save_data() SaveData {
	path := get_save_path()
	if !os.exists(path) {
		return SaveData{}
	}
	lines := os.read_lines(path) or { return SaveData{} }
	mut data := SaveData{}

	for line in lines {
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'high_score' { data.high_score = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			'stage' { data.stage = val.int() }
			'gems' { data.gems = val.int() }
			'score' { data.score = val.int() }
			'weapon' {
				match val {
					'machinegun' { data.weapon = .machinegun }
					'shotgun' { data.weapon = .shotgun }
					'laser' { data.weapon = .laser }
					'burst' { data.weapon = .burst }
					else { data.weapon = .standard }
				}
			}
			else {}
		}
	}
	return data
}

pub fn save_data_to_file(data &SaveData) {
	path := get_save_path()
	mut w_str := 'standard'
	match data.weapon {
		.machinegun { w_str = 'machinegun' }
		.shotgun { w_str = 'shotgun' }
		.laser { w_str = 'laser' }
		.burst { w_str = 'burst' }
		else {}
	}
	mut content := 'high_score=${data.high_score}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'stage=${data.stage}\n'
	content += 'gems=${data.gems}\n'
	content += 'score=${data.score}\n'
	content += 'weapon=${w_str}\n'
	os.write_file(path, content) or {}
}
