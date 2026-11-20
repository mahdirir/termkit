module widgets

import termkit

// Viewport shows a scrollable window over a list of lines.
pub struct Viewport {
pub mut:
	lines  []string
	offset int
	height int = 10
	width  int
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
	for i in v.offset .. end {
		line := v.lines[i]
		out << if v.width > 0 { pad(truncate(line, v.width), v.width) } else { line }
	}
	return out.join('\n')
}
