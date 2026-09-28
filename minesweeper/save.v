module main

import os

pub struct MineSaveData {
pub mut:
	best_beg         int = 999
	best_int         int = 999
	best_exp         int = 999
	save_state_valid bool
	diff_idx         int
	cols             int
	rows             int
	total_mines      int
	timer_ticks      int
	grid_lines       []string
}

pub fn get_mine_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'minesweeper')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'minesweeper')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'minesweeper')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_mine_save() MineSaveData {
	path := get_mine_save_path()
	if !os.exists(path) {
		return MineSaveData{}
	}
	lines := os.read_lines(path) or { return MineSaveData{} }
	mut data := MineSaveData{}

	for line in lines {
		if line.starts_with('cell=') {
			data.grid_lines << line.all_after('cell=')
			continue
		}
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'best_beg' { data.best_beg = val.int() }
			'best_int' { data.best_int = val.int() }
			'best_exp' { data.best_exp = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			'diff_idx' { data.diff_idx = val.int() }
			'cols' { data.cols = val.int() }
			'rows' { data.rows = val.int() }
			'total_mines' { data.total_mines = val.int() }
			'timer_ticks' { data.timer_ticks = val.int() }
			else {}
		}
	}
	return data
}

pub fn save_mine_data(data &MineSaveData) {
	path := get_mine_save_path()
	mut content := 'best_beg=${data.best_beg}\n'
	content += 'best_int=${data.best_int}\n'
	content += 'best_exp=${data.best_exp}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'diff_idx=${data.diff_idx}\n'
	content += 'cols=${data.cols}\n'
	content += 'rows=${data.rows}\n'
	content += 'total_mines=${data.total_mines}\n'
	content += 'timer_ticks=${data.timer_ticks}\n'
	for line in data.grid_lines {
		content += 'cell=${line}\n'
	}
	os.write_file(path, content) or {}
}
