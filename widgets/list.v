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
	// multi_select allows several items to be marked with the space key.
	multi_select bool
	marked       []bool
	focused      bool = true
	// status is a one-line footer shown when non-empty. Set it with
	// set_status and clear it with clear_status.
	status string
	// highlight_matches wraps the current filter match in reverse video.
	highlight_matches bool
	// cycle wraps the cursor from the last item to the first and back.
	cycle bool
	// filter_fn decides whether item matches query. The default is a
	// case-insensitive substring match. May be nil.
	filter_fn ?fn (item string, query string) bool
}

// set_status shows a footer line such as a spinner state or item count.
pub fn (mut l List) set_status(s string) {
	l.status = s
}

// clear_status hides the footer line.
pub fn (mut l List) clear_status() {
	l.status = ''
}

// match_count returns the number of items passing the current filter.
pub fn (l List) match_count() int {
	return l.visible().len
}

// set_items replaces the items and resets selection and filter.
pub fn (mut l List) set_items(items []string) {
	l.items = items
	l.selected = 0
	l.filter = ''
	l.marked = []bool{len: items.len}
	l.clamp()
}

// toggle marks or unmarks the selected item when multi_select is enabled.
pub fn (mut l List) toggle() {
	if !l.multi_select || l.selected < 0 || l.selected >= l.marked.len {
		return
	}
	l.marked[l.selected] = !l.marked[l.selected]
}

// selected_items returns the values of all marked items in declaration order.
pub fn (l List) selected_items() []string {
	mut out := []string{}
	for i, marked in l.marked {
		if marked && i < l.items.len {
			out << l.items[i]
		}
	}
	return out
}

fn (l List) visible() []int {
	mut out := []int{}
	for i, item in l.items {
		if l.filter == '' || l.item_matches(item, l.filter) {
			out << i
		}
	}
	return out
}

// item_matches reports whether item passes query using filter_fn or the
// default case-insensitive substring match.
fn (l List) item_matches(item string, query string) bool {
	if f := l.filter_fn {
		return f(item, query)
	}
	return item.to_lower().contains(query.to_lower())
}

// highlight wraps the first case-insensitive match of query in item in
// reverse video. It returns item unchanged when there is no match.
fn highlight_match(item string, query string) string {
	if query == '' {
		return item
	}
	lower_item := item.to_lower()
	lower_query := query.to_lower()
	at := lower_item.index(lower_query) or { return item }
	return item[..at] + '\x1b[7m' + item[at..at + query.len] + '\x1b[0m' +
		item[at + query.len..]
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
	if pos < 0 {
		pos = 0
	}
	if pos >= vis.len {
		pos = vis.len - 1
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
					} else if l.cycle && vis.len > 0 {
						l.selected = vis[vis.len - 1]
					}
				}
				termkit.key_down {
					if pos < vis.len - 1 {
						l.selected = vis[pos + 1]
					} else if l.cycle && vis.len > 0 {
						l.selected = vis[0]
					}
				}
				termkit.key_backspace {
					if l.filter.len > 0 {
						l.filter = l.filter[..l.filter.len - 1]
						l.clamp()
					}
				}
				termkit.key_space {
					if l.multi_select {
						l.toggle()
					} else {
						l.filter += ' '
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
		mut marker := if idx == l.selected { '> ' } else { '  ' }
		if idx < l.marked.len && l.marked[idx] {
			marker = '* '
		}
		mut line := l.items[idx]
		if l.highlight_matches && l.filter != '' {
			line = highlight_match(line, l.filter)
		}
		if l.width > 0 {
			line = pad(truncate(line, l.width - 2), l.width - 2)
		}
		out << marker + line
	}
	if out.len == 0 {
		return 'no matches'
	}
	if l.status != '' {
		out << l.status
	}
	return out.join('\n')
}
