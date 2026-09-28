module main

import os

pub struct TetrisSaveData {
pub mut:
	high_score       int
	score            int
	lines            int
	level            int = 1
	save_state_valid bool
	grid_lines       []string
}

pub fn get_tetris_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'tetris')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'tetris')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'tetris')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_tetris_save() TetrisSaveData {
	path := get_tetris_save_path()
	if !os.exists(path) {
		return TetrisSaveData{}
	}
	lines := os.read_lines(path) or { return TetrisSaveData{} }
	mut data := TetrisSaveData{}

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
			'high_score' { data.high_score = val.int() }
			'score' { data.score = val.int() }
			'lines' { data.lines = val.int() }
			'level' { data.level = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			else {}
		}
	}
	return data
}

pub fn save_tetris_data(data &TetrisSaveData) {
	path := get_tetris_save_path()
	mut content := 'high_score=${data.high_score}\n'
	content += 'score=${data.score}\n'
	content += 'lines=${data.lines}\n'
	content += 'level=${data.level}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	for row in data.grid_lines {
		content += 'row=${row}\n'
	}
	os.write_file(path, content) or {}
}
