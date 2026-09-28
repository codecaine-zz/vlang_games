module main

import os

pub struct LoloSaveData {
pub mut:
	max_level_unlocked int
	current_level      int
	save_state_valid   bool
	state_level        int
	state_player_x     int
	state_player_y     int
	state_shots        int
	state_hearts_got   int
	state_grid_lines   []string
}

pub fn get_lolo_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'lolo')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'lolo')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'lolo')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_lolo_save() LoloSaveData {
	path := get_lolo_save_path()
	if !os.exists(path) {
		return LoloSaveData{}
	}
	lines := os.read_lines(path) or { return LoloSaveData{} }
	mut data := LoloSaveData{}

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
			'state_shots' { data.state_shots = val.int() }
			'state_hearts_got' { data.state_hearts_got = val.int() }
			else {}
		}
	}
	return data
}

pub fn save_lolo_data(data &LoloSaveData) {
	path := get_lolo_save_path()
	mut content := 'max_level_unlocked=${data.max_level_unlocked}\n'
	content += 'current_level=${data.current_level}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'state_level=${data.state_level}\n'
	content += 'state_player_x=${data.state_player_x}\n'
	content += 'state_player_y=${data.state_player_y}\n'
	content += 'state_shots=${data.state_shots}\n'
	content += 'state_hearts_got=${data.state_hearts_got}\n'
	for line in data.state_grid_lines {
		content += 'grid_line=${line}\n'
	}
	os.write_file(path, content) or {}
}
