module main

import os

pub struct PicrossSaveData {
pub mut:
	puzzle_idx       int
	solved_puzzles   []int
	save_state_valid bool
	state_puzzle_idx int
	grid_lines       []string
}

pub fn get_picross_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'picross')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'picross')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'picross')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_picross_save() PicrossSaveData {
	path := get_picross_save_path()
	if !os.exists(path) {
		return PicrossSaveData{}
	}
	lines := os.read_lines(path) or { return PicrossSaveData{} }
	mut data := PicrossSaveData{}

	for line in lines {
		if line.starts_with('grid=') {
			data.grid_lines << line.all_after('grid=')
			continue
		}
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'puzzle_idx' { data.puzzle_idx = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			'state_puzzle_idx' { data.state_puzzle_idx = val.int() }
			'solved_puzzles' {
				tokens := val.split(',')
				for t in tokens {
					if t != '' {
						data.solved_puzzles << t.int()
					}
				}
			}
			else {}
		}
	}
	return data
}

pub fn save_picross_data(data &PicrossSaveData) {
	path := get_picross_save_path()
	mut content := 'puzzle_idx=${data.puzzle_idx}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'state_puzzle_idx=${data.state_puzzle_idx}\n'
	mut solved_strs := []string{}
	for sp in data.solved_puzzles {
		solved_strs << sp.str()
	}
	content += 'solved_puzzles=${solved_strs.join(",")}\n'
	for line in data.grid_lines {
		content += 'grid=${line}\n'
	}
	os.write_file(path, content) or {}
}
