module widgets

import os
import termkit

// FilePicker browses directories and selects a file: arrows move, Enter
// descends or selects and Backspace ascends.
pub struct FilePicker {
pub mut:
	path        string
	entries     []string
	cursor      int
	height      int = 10
	width       int
	show_hidden bool
	selected    string
	// offset_x/offset_y locate the picker on screen for mouse hit-testing.
	offset_x int
	offset_y int
	focused  bool = true
}

// new_filepicker creates a picker for path, loading its entries.
pub fn new_filepicker(path string) !FilePicker {
	mut picker := FilePicker{ path: path }
	picker.reload()!
	return picker
}

// reload refreshes the entry list from the current directory.
pub fn (mut p FilePicker) reload() ! {
	names := os.ls(p.path) or { return error('cannot read `${p.path}`: ${err}') }
	mut entries := []string{}
	for name in names {
		if !p.show_hidden && name.starts_with('.') {
			continue
		}
		full := os.join_path(p.path, name)
		entries << if os.is_dir(full) { name + '/' } else { name }
	}
	entries.sort()
	p.entries = entries
	if p.cursor >= p.entries.len {
		p.cursor = p.entries.len - 1
	}
	if p.cursor < 0 {
		p.cursor = 0
	}
}

// focus marks the picker as accepting keys.
pub fn (mut p FilePicker) focus() {
	p.focused = true
}

// blur marks the picker as not accepting keys.
pub fn (mut p FilePicker) blur() {
	p.focused = false
}

// is_focused reports whether the picker accepts keyboard input.
pub fn (p &FilePicker) is_focused() bool {
	return p.focused
}

fn (p FilePicker) full_path(name string) string {
	clean := if name.ends_with('/') { name[..name.len - 1] } else { name }
	return os.join_path(p.path, clean)
}

// selection returns the last selected absolute path.
pub fn (p FilePicker) selection() string {
	return p.selected
}

// update handles navigation and selection keys.
pub fn (mut p FilePicker) update(msg termkit.Msg) {
	if !p.focused {
		return
	}
	match msg {
		termkit.FocusMsg {
			p.focused = true
		}
		termkit.BlurMsg {
			p.focused = false
		}
		termkit.KeyMsg {
			if msg.kind != .press {
				return
			}
			match msg.key {
				termkit.key_up {
					if p.cursor > 0 {
						p.cursor--
					}
				}
				termkit.key_down {
					if p.cursor < p.entries.len - 1 {
						p.cursor++
					}
				}
				termkit.key_home {
					p.cursor = 0
				}
				termkit.key_end {
					p.cursor = p.entries.len - 1
				}
				termkit.key_backspace {
					mut parent := os.dir(p.path)
					if parent == '' || parent == p.path {
						parent = os.join_path(p.path, '..')
					}
					p.path = parent
					p.reload() or { return }
				}
				termkit.key_enter {
					p.activate() or { return }
				}
				else {}
			}
		}
		termkit.MouseMsg {
			p.handle_mouse(msg)
		}
		else {}
	}
}

fn (mut p FilePicker) activate() ! {
	if p.cursor < 0 || p.cursor >= p.entries.len {
		return
	}
	entry := p.entries[p.cursor]
	full := p.full_path(entry)
	if os.is_dir(full) {
		p.path = full
		p.reload()!
	} else {
		p.selected = full
	}
}

fn (p FilePicker) visible_start() int {
	if p.height > 0 && p.cursor >= p.height {
		return p.cursor - p.height + 1
	}
	return 0
}

fn (mut p FilePicker) handle_mouse(msg termkit.MouseMsg) {
	match msg.action {
		.scroll {
			if msg.scroll == .up && p.cursor > 0 {
				p.cursor--
			}
			if msg.scroll == .down && p.cursor < p.entries.len - 1 {
				p.cursor++
			}
		}
		.down {
			if msg.button != .left {
				return
			}
			row := msg.y - p.offset_y - 1
			if row < 0 {
				return
			}
			idx := p.visible_start() + row
			if idx >= 0 && idx < p.entries.len {
				p.cursor = idx
				p.activate() or { return }
			}
		}
		else {}
	}
}

// view renders a window of entries around the cursor.
pub fn (p FilePicker) view() string {
	mut out := [p.path]
	start := p.visible_start()
	mut end := p.entries.len
	if p.height > 0 && end > start + p.height {
		end = start + p.height
	}
	for i in start .. end {
		marker := if i == p.cursor { '> ' } else { '  ' }
		mut line := p.entries[i]
		if p.width > 0 {
			line = pad(truncate(line, p.width - 2), p.width - 2)
		}
		out << marker + line
	}
	return out.join('\n')
}
