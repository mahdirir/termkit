module widgets

import termkit

// TextArea is a small multi-line editor.
pub struct TextArea {
pub mut:
	lines   []string
	row     int
	col     int
	width   int
	height  int
	focused bool = true
}

// set_text replaces the content and moves the cursor to the end.
pub fn (mut t TextArea) set_text(text string) {
	t.lines = if text == '' { [''] } else { text.split('\n') }
	t.row = t.lines.len - 1
	t.col = t.lines[t.row].len
}

// text returns the joined content.
pub fn (t TextArea) text() string {
	return t.lines.join('\n')
}

fn (mut t TextArea) insert(text string) {
	if t.lines.len == 0 {
		t.lines = ['']
	}
	line := t.lines[t.row]
	if t.col > line.len {
		t.col = line.len
	}
	t.lines[t.row] = line[..t.col] + text + line[t.col..]
	t.col += text.len
}

// update handles editing and navigation keys.
pub fn (mut t TextArea) update(msg termkit.Msg) {
	if !t.focused {
		return
	}
	match msg {
		termkit.FocusMsg {
			t.focused = true
		}
		termkit.BlurMsg {
			t.focused = false
		}
		termkit.PasteMsg {
			for part in msg.text.split('\n') {
				t.insert(part)
			}
		}
		termkit.KeyMsg {
			if msg.kind != .press {
				return
			}
			match msg.key {
				termkit.key_left {
					if t.col > 0 {
						t.col--
					}
				}
				termkit.key_right {
					if t.col < t.lines[t.row].len {
						t.col++
					}
				}
				termkit.key_up {
					if t.row > 0 {
						t.row--
						if t.col > t.lines[t.row].len {
							t.col = t.lines[t.row].len
						}
					}
				}
				termkit.key_down {
					if t.row < t.lines.len - 1 {
						t.row++
						if t.col > t.lines[t.row].len {
							t.col = t.lines[t.row].len
						}
					}
				}
				termkit.key_enter {
					line := t.lines[t.row]
					before := line[..t.col]
					after := line[t.col..]
					t.lines[t.row] = before
					t.lines.insert(t.row + 1, after)
					t.row++
					t.col = 0
				}
				termkit.key_backspace {
					if t.col > 0 {
						t.col--
						t.lines[t.row] = t.lines[t.row][..t.col] + t.lines[t.row][t.col + 1..]
					} else if t.row > 0 {
						previous := t.lines[t.row - 1]
						t.col = previous.len
						t.lines[t.row - 1] = previous + t.lines[t.row]
						t.lines.delete(t.row)
						t.row--
					}
				}
				else {
					if msg.utf8 != '' {
						t.insert(msg.utf8)
					} else if msg.key.len == 1 {
						t.insert(msg.key)
					}
				}
			}
		}
		else {}
	}
}

// view renders a window of lines around the cursor.
pub fn (t TextArea) view() string {
	mut out := []string{}
	mut end := t.lines.len
	if t.height > 0 && end > t.height {
		end = t.height
	}
	for i in 0 .. end {
		line := t.lines[i]
		out << if t.width > 0 { pad(truncate(line, t.width), t.width) } else { line }
	}
	return out.join('\n')
}
