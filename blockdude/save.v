module main

import os

pub struct BlockDudeSaveData {
pub mut:
	max_level_unlocked int
	current_level      int
	save_state_valid   bool
	state_level        int
	state_player_x     int
	state_player_y     int
	state_facing_right bool
	state_carrying     bool
	state_moves        int
	state_grid_lines   []string
}

pub fn get_blockdude_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'blockdude')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'blockdude')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'blockdude')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_blockdude_save() BlockDudeSaveData {
	path := get_blockdude_save_path()
	if !os.exists(path) {
		return BlockDudeSaveData{}
	}
	lines := os.read_lines(path) or { return BlockDudeSaveData{} }
	mut data := BlockDudeSaveData{}

	for line in lines {
		if line.starts_with('grid_line=') {
			data.state_grid_lines << line.all_after('grid_line=')
			continue
		}
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'max_level_unlocked' { data.max_level_unlocked = val.int() }
			'current_level' { data.current_level = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			'state_level' { data.state_level = val.int() }
			'state_player_x' { data.state_player_x = val.int() }
			'state_player_y' { data.state_player_y = val.int() }
			'state_facing_right' { data.state_facing_right = val.bool() }
			'state_carrying' { data.state_carrying = val.bool() }
			'state_moves' { data.state_moves = val.int() }
			else {}
		}
	}
	return data
}

pub fn save_blockdude_data(data &BlockDudeSaveData) {
	path := get_blockdude_save_path()
	mut content := 'max_level_unlocked=${data.max_level_unlocked}\n'
	content += 'current_level=${data.current_level}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'state_level=${data.state_level}\n'
	content += 'state_player_x=${data.state_player_x}\n'
	content += 'state_player_y=${data.state_player_y}\n'
	content += 'state_facing_right=${data.state_facing_right}\n'
	content += 'state_carrying=${data.state_carrying}\n'
	content += 'state_moves=${data.state_moves}\n'
	for line in data.state_grid_lines {
		content += 'grid_line=${line}\n'
	}
	os.write_file(path, content) or {}
}
