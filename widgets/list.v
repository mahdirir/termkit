module widgets

import termkit

// List is a filterable, scrollable selection list.
pub struct List {
pub mut:
	items    []string
	selected int
	filter   string
	height   int = 10
	width    int
	// offset_x/offset_y locate the list on screen for mouse hit-testing.
	offset_x int
	offset_y int
	focused  bool = true
}

// set_items replaces the items and resets selection and filter.
pub fn (mut l List) set_items(items []string) {
	l.items = items
	l.selected = 0
	l.filter = ''
	l.clamp()
}

fn (l List) visible() []int {
	mut out := []int{}
	for i, item in l.items {
		if l.filter == '' || item.to_lower().contains(l.filter.to_lower()) {
			out << i
		}
	}
	return out
}

fn (mut l List) clamp() {
	vis := l.visible()
	if vis.len == 0 {
		l.selected = 0
		return
	}
	mut pos := 0
	for i, idx in vis {
		if idx == l.selected {
			pos = i
			break
		}
	}
	page := if l.height > 0 { l.height } else { 1 }
	if pos < 0 {
		pos = 0
	}
	if pos >= vis.len {
		pos = vis.len - 1
	}
	if pos < l.selected - page + 1 {
		l.selected = vis[pos]
	}
	l.selected = vis[pos]
}

// is_focused reports whether this list accepts keyboard input.
pub fn (l &List) is_focused() bool {
	return l.focused
}

// selected_item returns the currently selected string, if any.
pub fn (l List) selected_item() string {
	vis := l.visible()
	if vis.len == 0 || l.selected < 0 || l.selected >= l.items.len {
		return ''
	}
	return l.items[l.selected]
}

// update handles navigation and filter editing.
pub fn (mut l List) update(msg termkit.Msg) {
	if !l.focused {
		return
	}
	match msg {
		termkit.FocusMsg {
			l.focused = true
		}
		termkit.BlurMsg {
			l.focused = false
		}
		termkit.KeyMsg {
			if msg.kind != .press {
				return
			}
			vis := l.visible()
			mut pos := 0
			for i, idx in vis {
				if idx == l.selected {
					pos = i
					break
				}
			}
			match msg.key {
				termkit.key_up {
					if pos > 0 {
						l.selected = vis[pos - 1]
					}
				}
				termkit.key_down {
					if pos < vis.len - 1 {
						l.selected = vis[pos + 1]
					}
				}
				termkit.key_backspace {
					if l.filter.len > 0 {
						l.filter = l.filter[..l.filter.len - 1]
						l.clamp()
					}
				}
				else {
					if msg.utf8.len > 0 {
						l.filter += msg.utf8
						l.clamp()
					} else if msg.key.len == 1 {
						l.filter += msg.key
						l.clamp()
					}
				}
			}
		}
		termkit.MouseMsg {
			l.handle_mouse(msg)
		}
		else {}
	}
}

fn (l List) visible_start() int {
	vis := l.visible()
	for i, idx in vis {
		if idx == l.selected {
			half := l.height / 2
			return if i > half { i - half } else { 0 }
		}
	}
	return 0
}

fn (mut l List) handle_mouse(msg termkit.MouseMsg) {
	vis := l.visible()
	if vis.len == 0 {
		return
	}
	match msg.action {
		.scroll {
			mut pos := 0
			for i, idx in vis {
				if idx == l.selected {
					pos = i
					break
				}
			}
			if msg.scroll == .up && pos > 0 {
				l.selected = vis[pos - 1]
			}
			if msg.scroll == .down && pos < vis.len - 1 {
				l.selected = vis[pos + 1]
			}
		}
		.down {
			if msg.button != .left {
				return
			}
			row := msg.y - l.offset_y
			if row < 0 {
				return
			}
			idx := l.visible_start() + row
			if idx < vis.len {
				l.selected = vis[idx]
			}
		}
		else {}
	}
}

// view renders the visible slice, marking the selection.
pub fn (l List) view() string {
	vis := l.visible()
	mut out := []string{}
	start := l.visible_start()
	mut end := start + l.height
	if end > vis.len {
		end = vis.len
	}
	for i in start .. end {
		idx := vis[i]
		marker := if idx == l.selected { '> ' } else { '  ' }
		mut line := l.items[idx]
		if l.width > 0 {
			line = pad(truncate(line, l.width - 2), l.width - 2)
		}
		out << marker + line
	}
	if out.len == 0 {
		return 'no matches'
	}
	return out.join('\n')
}
