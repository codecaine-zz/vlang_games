module main

import os

pub struct EtchSaveData {
pub mut:
	save_state_valid bool
	point_lines      []string
}

pub fn get_etch_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'etchasketch')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'etchasketch')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'etchasketch')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_etch_save() EtchSaveData {
	path := get_etch_save_path()
	if !os.exists(path) {
		return EtchSaveData{}
	}
	lines := os.read_lines(path) or { return EtchSaveData{} }
	mut data := EtchSaveData{}

	for line in lines {
		if line.starts_with('pt=') {
			data.point_lines << line.all_after('pt=')
			continue
		}
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'save_state_valid' { data.save_state_valid = val.bool() }
			else {}
		}
	}
	return data
}

pub fn save_etch_data(data &EtchSaveData) {
	path := get_etch_save_path()
	mut content := 'save_state_valid=${data.save_state_valid}\n'
	for pt in data.point_lines {
		content += 'pt=${pt}\n'
	}
	os.write_file(path, content) or {}
}
