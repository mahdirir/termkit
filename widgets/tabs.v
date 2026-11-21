module widgets

import termkit

// Tabs is a horizontal row of selectable tabs.
pub struct Tabs {
pub mut:
	tabs   []string
	active int
}

// set_tabs replaces the tab labels and selects the first one.
pub fn (mut t Tabs) set_tabs(tabs []string) {
	t.tabs = tabs
	t.active = if tabs.len > 0 { 0 } else { -1 }
}

// select activates the tab at index, if it exists.
pub fn (mut t Tabs) select(index int) {
	if index >= 0 && index < t.tabs.len {
		t.active = index
	}
}

// active_name returns the label of the active tab, or an empty string.
pub fn (t Tabs) active_name() string {
	if t.active < 0 || t.active >= t.tabs.len {
		return ''
	}
	return t.tabs[t.active]
}

// update handles left/right/home/end navigation for a key press.
pub fn (mut t Tabs) update(msg termkit.Msg) {
	match msg {
		termkit.KeyMsg {
			if msg.kind != .press || t.tabs.len == 0 {
				return
			}
			match msg.key {
				termkit.key_left {
					if t.active > 0 {
						t.active--
					}
				}
				termkit.key_right {
					if t.active < t.tabs.len - 1 {
						t.active++
					}
				}
				termkit.key_home {
					t.active = 0
				}
				termkit.key_end {
					t.active = t.tabs.len - 1
				}
				else {}
			}
		}
		else {}
	}
}

// view renders the tab row, marking the active tab with brackets.
pub fn (t Tabs) view() string {
	mut out := []string{}
	for i, label in t.tabs {
		out << if i == t.active { '[${label}]' } else { ' ${label} ' }
	}
	return out.join(' ')
}
