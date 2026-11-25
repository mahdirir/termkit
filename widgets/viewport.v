module widgets

import termkit

// Viewport shows a scrollable window over a list of lines.
pub struct Viewport {
pub mut:
	lines  []string
	offset int
	height int = 10
	width  int
	// offset_x/offset_y locate the viewport on screen for mouse hit-testing.
	offset_x int
	offset_y int
	// gutter shows line numbers when true.
	gutter bool
mut:
	last_find string
	find_pos  int = -1
}

// set_content replaces the content and keeps the offset in range.
pub fn (mut v Viewport) set_content(lines []string) {
	v.lines = lines
	v.clamp()
}

fn (mut v Viewport) clamp() {
	max_offset := v.lines.len - v.height
	if max_offset < 0 {
		v.offset = 0
	} else if v.offset > max_offset {
		v.offset = max_offset
	}
	if v.offset < 0 {
		v.offset = 0
	}
}

// line_count returns the total number of content lines.
pub fn (v Viewport) line_count() int {
	return v.lines.len
}

// scroll_percent returns how far the viewport has scrolled from 0 to 100.
pub fn (v Viewport) scroll_percent() int {
	max_offset := v.lines.len - v.height
	if max_offset <= 0 {
		return 100
	}
	return v.offset * 100 / max_offset
}

// find jumps to the first line containing query and returns true.
pub fn (mut v Viewport) find(query string) bool {
	v.last_find = query
	v.find_pos = -1
	return v.find_next()
}

// find_next jumps to the next line containing the last find query,
// wrapping around. It returns false when nothing matches.
pub fn (mut v Viewport) find_next() bool {
	if v.last_find == '' || v.lines.len == 0 {
		return false
	}
	for n in 1 .. v.lines.len + 1 {
		i := (v.find_pos + n) % v.lines.len
		if v.lines[i].contains(v.last_find) {
			v.find_pos = i
			v.offset = i
			v.clamp()
			return true
		}
	}
	return false
}

// update handles scrolling keys.
pub fn (mut v Viewport) update(msg termkit.Msg) {
	match msg {
		termkit.KeyMsg {
			if msg.kind != .press {
				return
			}
			match msg.key {
				termkit.key_up {
					if v.offset > 0 {
						v.offset--
					}
				}
				termkit.key_down {
					if v.offset < v.lines.len - v.height {
						v.offset++
					}
				}
				termkit.key_page_up {
					v.offset -= v.height
				}
				termkit.key_page_down {
					v.offset += v.height
				}
				termkit.key_home {
					v.offset = 0
				}
				termkit.key_end {
					v.offset = v.lines.len
				}
				else {}
			}
			v.clamp()
		}
		termkit.WindowSizeMsg {
			if msg.height > 0 {
				v.height = msg.height
			}
			if msg.width > 0 {
				v.width = msg.width
			}
			v.clamp()
		}
		termkit.MouseMsg {
			if msg.action != .scroll || msg.y < v.offset_y || msg.y >= v.offset_y + v.height {
				return
			}
			if msg.scroll == .up {
				v.offset -= 1
			}
			if msg.scroll == .down {
				v.offset += 1
			}
			v.clamp()
		}
		else {}
	}
}

// view renders the visible lines.
pub fn (v Viewport) view() string {
	mut out := []string{}
	mut end := v.offset + v.height
	if end > v.lines.len {
		end = v.lines.len
	}
	gutter_width := if v.gutter { '${v.lines.len}'.len + 1 } else { 0 }
	for i in v.offset .. end {
		line := v.lines[i]
		mut shown := if v.width > 0 { pad(truncate(line, v.width), v.width) } else { line }
		if v.gutter {
			shown = pad('${i + 1}', gutter_width) + shown
		}
		out << shown
	}
	return out.join('\n')
}
