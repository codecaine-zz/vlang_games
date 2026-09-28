module main

import os

pub struct Save2048 {
pub mut:
	best_score       int
	score            int
	max_tile         int
	save_state_valid bool
	grid_lines       []string
}

pub fn get_2048_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'game2048')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'game2048')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'game2048')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_2048_save() Save2048 {
	path := get_2048_save_path()
	if !os.exists(path) {
		return Save2048{}
	}
	lines := os.read_lines(path) or { return Save2048{} }
	mut data := Save2048{}

	for line in lines {
		if line.starts_with('row=') {
			data.grid_lines << line.all_after('row=')
			continue
		}
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'best_score' { data.best_score = val.int() }
			'score' { data.score = val.int() }
			'max_tile' { data.max_tile = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			else {}
		}
	}
	return data
}

pub fn save_2048_data(data &Save2048) {
	path := get_2048_save_path()
	mut content := 'best_score=${data.best_score}\n'
	content += 'score=${data.score}\n'
	content += 'max_tile=${data.max_tile}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	for row in data.grid_lines {
		content += 'row=${row}\n'
	}
	os.write_file(path, content) or {}
}
