module main

import os

pub struct ClickArcadeSaveData {
pub mut:
	total_clicks     int
	gem_rush_best    f64
	chain_best_score int
	chain_best_level int
	whack_best_score int
	blade_best_score int
}

pub fn get_clickarcade_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'clickarcade')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'clickarcade')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'clickarcade')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_clickarcade_save() ClickArcadeSaveData {
	path := get_clickarcade_save_path()
	if !os.exists(path) {
		return ClickArcadeSaveData{}
	}
	lines := os.read_lines(path) or { return ClickArcadeSaveData{} }
	mut data := ClickArcadeSaveData{}

	for line in lines {
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'total_clicks' { data.total_clicks = val.int() }
			'gem_rush_best' { data.gem_rush_best = val.f64() }
			'chain_best_score' { data.chain_best_score = val.int() }
			'chain_best_level' { data.chain_best_level = val.int() }
			'whack_best_score' { data.whack_best_score = val.int() }
			'blade_best_score' { data.blade_best_score = val.int() }
			else {}
		}
	}
	return data
}

pub fn save_clickarcade_data(data &ClickArcadeSaveData) {
	path := get_clickarcade_save_path()
	mut content := 'total_clicks=${data.total_clicks}\n'
	content += 'gem_rush_best=${data.gem_rush_best}\n'
	content += 'chain_best_score=${data.chain_best_score}\n'
	content += 'chain_best_level=${data.chain_best_level}\n'
	content += 'whack_best_score=${data.whack_best_score}\n'
	content += 'blade_best_score=${data.blade_best_score}\n'
	os.write_file(path, content) or {}
}
