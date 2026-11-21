module widgets

import termkit

// TextInput is a single-line editable field.
pub struct TextInput {
pub mut:
	prompt   string = '> '
	value    string
	position int
	focused  bool = true
}

// focus marks the input as accepting keys.
pub fn (mut t TextInput) focus() {
	t.focused = true
}

// blur marks the input as not accepting keys.
pub fn (mut t TextInput) blur() {
	t.focused = false
}

fn (mut t TextInput) insert(text string) {
	if text == '' {
		return
	}
	pos := t.position
	if pos < 0 || pos > t.value.len {
		t.position = t.value.len
		return
	}
	t.value = t.value[..pos] + text + t.value[pos..]
	t.position += text.len
}

// is_focused reports whether this input accepts keyboard input.
pub fn (t &TextInput) is_focused() bool {
	return t.focused
}

// update handles editing keys and printable text.
pub fn (mut t TextInput) update(msg termkit.Msg) {
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
			t.insert(msg.text)
		}
		termkit.KeyMsg {
			if msg.kind != .press {
				return
			}
			match msg.key {
				termkit.key_left {
					if t.position > 0 {
						t.position--
					}
				}
				termkit.key_right {
					if t.position < t.value.len {
						t.position++
					}
				}
				termkit.key_home {
					t.position = 0
				}
				termkit.key_end {
					t.position = t.value.len
				}
				termkit.key_backspace {
					if t.position > 0 {
						t.position--
						t.value = t.value[..t.position] + t.value[t.position + 1..]
					}
				}
				termkit.key_delete {
					if t.position < t.value.len {
						t.value = t.value[..t.position] + t.value[t.position + 1..]
					}
				}
				else {
					if msg.utf8 != '' {
						t.insert(msg.utf8)
					} else if msg.key.len == 1 && msg.key != ' ' {
						t.insert(msg.key)
					} else if msg.key == ' ' {
						t.insert(' ')
					}
				}
			}
		}
		else {}
	}
}

// view renders the prompt, value and a cursor marker.
pub fn (t TextInput) view() string {
	before := t.value[..t.position]
	after := if t.position < t.value.len { t.value[t.position + 1..] } else { '' }
	marker := if t.position < t.value.len { t.value[t.position..t.position + 1] } else { ' ' }
	return t.prompt + before + '\x1b[7m' + marker + '\x1b[0m' + after
}
