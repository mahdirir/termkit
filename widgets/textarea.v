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

// focus marks the text area as accepting keys.
pub fn (mut t TextArea) focus() {
	t.focused = true
}

// blur marks the text area as not accepting keys.
pub fn (mut t TextArea) blur() {
	t.focused = false
}

// is_focused reports whether the text area accepts keyboard input.
pub fn (t &TextArea) is_focused() bool {
	return t.focused
}

// set_text replaces the content and moves the cursor to the end.
pub fn (mut t TextArea) set_text(text string) {
	t.lines = if text == '' { [''] } else { text.split('\n') }
	t.row = t.lines.len - 1
	t.col = rune_len(t.lines[t.row])
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
	if t.col > rune_len(line) {
		t.col = rune_len(line)
	}
	prefix := rune_prefix(line, t.col)
	t.lines[t.row] = prefix + text + line[prefix.len..]
	t.col += rune_len(text)
}

// newline splits the current line at the cursor and moves to the new line.
fn (mut t TextArea) newline() {
	line := t.lines[t.row]
	prefix := rune_prefix(line, t.col)
	t.lines[t.row] = prefix
	t.lines.insert(t.row + 1, line[prefix.len..])
	t.row++
	t.col = 0
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
			for i, part in msg.text.split('\n') {
				if i > 0 {
					t.newline()
				}
				t.insert(part)
			}
		}
		termkit.KeyMsg {
			if msg.kind != .press {
				return
			}
			length := rune_len(t.lines[t.row])
			match msg.key {
				termkit.key_left {
					if t.col > 0 {
						t.col--
					}
				}
				termkit.key_right {
					if t.col < length {
						t.col++
					}
				}
				termkit.key_up {
					if t.row > 0 {
						t.row--
						if t.col > rune_len(t.lines[t.row]) {
							t.col = rune_len(t.lines[t.row])
						}
					}
				}
				termkit.key_down {
					if t.row < t.lines.len - 1 {
						t.row++
						if t.col > rune_len(t.lines[t.row]) {
							t.col = rune_len(t.lines[t.row])
						}
					}
				}
				termkit.key_home {
					t.col = 0
				}
				termkit.key_end {
					t.col = rune_len(t.lines[t.row])
				}
				termkit.key_enter {
					t.newline()
				}
				termkit.key_backspace {
					if t.col > 0 {
						line := t.lines[t.row]
						ch := rune_at(line, t.col - 1)
						prefix := rune_prefix(line, t.col - 1)
						t.lines[t.row] = prefix + line[prefix.len + ch.len..]
						t.col--
					} else if t.row > 0 {
						previous := t.lines[t.row - 1]
						t.col = rune_len(previous)
						t.lines[t.row - 1] = previous + t.lines[t.row]
						t.lines.delete(t.row)
						t.row--
					}
				}
				termkit.key_delete {
					if t.col < length {
						line := t.lines[t.row]
						ch := rune_at(line, t.col)
						prefix := rune_prefix(line, t.col)
						t.lines[t.row] = prefix + line[prefix.len + ch.len..]
					}
				}
				else {
					text := msg.text()
					if text != '' {
						t.insert(text)
					} else if !msg.is_ctrl() && !msg.is_alt() && termkit.single_rune_text(msg.key) {
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
