module main

import os

pub struct SokobanSaveData {
pub mut:
	max_level_unlocked int
	current_level      int
	save_state_valid   bool
	state_level        int
	state_steps        int
	state_pushes       int
	state_player_r     int
	state_player_c     int
	state_grid_lines   []string
}

pub fn get_sokoban_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'sokoban')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'sokoban')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'sokoban')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_sokoban_save() SokobanSaveData {
	path := get_sokoban_save_path()
	if !os.exists(path) {
		return SokobanSaveData{}
	}
	lines := os.read_lines(path) or { return SokobanSaveData{} }
	mut data := SokobanSaveData{}

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
			'state_steps' { data.state_steps = val.int() }
			'state_pushes' { data.state_pushes = val.int() }
			'state_player_r' { data.state_player_r = val.int() }
			'state_player_c' { data.state_player_c = val.int() }
			else {}
		}
	}
	return data
}

pub fn save_sokoban_data(data &SokobanSaveData) {
	path := get_sokoban_save_path()
	mut content := 'max_level_unlocked=${data.max_level_unlocked}\n'
	content += 'current_level=${data.current_level}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'state_level=${data.state_level}\n'
	content += 'state_steps=${data.state_steps}\n'
	content += 'state_pushes=${data.state_pushes}\n'
	content += 'state_player_r=${data.state_player_r}\n'
	content += 'state_player_c=${data.state_player_c}\n'
	for line in data.state_grid_lines {
		content += 'grid_line=${line}\n'
	}
	os.write_file(path, content) or {}
}
