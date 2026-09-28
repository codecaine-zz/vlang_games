module main

import os

pub struct DopeSaveData {
pub mut:
	high_score       int
	save_state_valid bool
	day              int = 1
	cash             int = 2000
	bank             int
	debt             int = 5500
	health           int = 100
	max_pockets      int = 100
	location_idx     int
	inventory_pairs  []string
}

pub fn get_dope_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'dopewars')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'dopewars')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'dopewars')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_dope_save() DopeSaveData {
	path := get_dope_save_path()
	if !os.exists(path) {
		return DopeSaveData{}
	}
	lines := os.read_lines(path) or { return DopeSaveData{} }
	mut data := DopeSaveData{}

	for line in lines {
		if line.starts_with('inv=') {
			data.inventory_pairs << line.all_after('inv=')
			continue
		}
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'high_score' { data.high_score = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			'day' { data.day = val.int() }
			'cash' { data.cash = val.int() }
			'bank' { data.bank = val.int() }
			'debt' { data.debt = val.int() }
			'health' { data.health = val.int() }
			'max_pockets' { data.max_pockets = val.int() }
			'location_idx' { data.location_idx = val.int() }
			else {}
		}
	}
	return data
}

pub fn save_dope_data(data &DopeSaveData) {
	path := get_dope_save_path()
	mut content := 'high_score=${data.high_score}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'day=${data.day}\n'
	content += 'cash=${data.cash}\n'
	content += 'bank=${data.bank}\n'
	content += 'debt=${data.debt}\n'
	content += 'health=${data.health}\n'
	content += 'max_pockets=${data.max_pockets}\n'
	content += 'location_idx=${data.location_idx}\n'
	for pair in data.inventory_pairs {
		content += 'inv=${pair}\n'
	}
	os.write_file(path, content) or {}
}
