module main

import os

pub struct TDSaveData {
pub mut:
	high_score       int
	max_wave         int
	save_state_valid bool
	wave             int = 1
	score            int
	lives            int = 10
	gold             int = 350
	turret_lines     []string
}

pub fn get_td_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'towerdefense')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'towerdefense')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'towerdefense')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_td_save() TDSaveData {
	path := get_td_save_path()
	if !os.exists(path) {
		return TDSaveData{}
	}
	lines := os.read_lines(path) or { return TDSaveData{} }
	mut data := TDSaveData{}

	for line in lines {
		if line.starts_with('turret=') {
			data.turret_lines << line.all_after('turret=')
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
			'max_wave' { data.max_wave = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			'wave' { data.wave = val.int() }
			'score' { data.score = val.int() }
			'lives' { data.lives = val.int() }
			'gold' { data.gold = val.int() }
			else {}
		}
	}
	return data
}

pub fn save_td_data(data &TDSaveData) {
	path := get_td_save_path()
	mut content := 'high_score=${data.high_score}\n'
	content += 'max_wave=${data.max_wave}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'wave=${data.wave}\n'
	content += 'score=${data.score}\n'
	content += 'lives=${data.lives}\n'
	content += 'gold=${data.gold}\n'
	for line in data.turret_lines {
		content += 'turret=${line}\n'
	}
	os.write_file(path, content) or {}
}
