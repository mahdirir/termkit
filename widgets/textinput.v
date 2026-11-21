module widgets

import termkit

// TextInput is a single-line editable field.
pub struct TextInput {
pub mut:
	prompt   string = '> '
	value    string
	position int
	// mask, when non-zero, replaces each character in the rendered value.
	mask    u8
	focused bool = true
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
	length := rune_len(t.value)
	pos := t.position
	if pos < 0 || pos > length {
		t.position = length
		return
	}
	prefix := rune_prefix(t.value, pos)
	t.value = prefix + text + t.value[prefix.len..]
	t.position += rune_len(text)
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
			length := rune_len(t.value)
			match msg.key {
				termkit.key_left {
					if t.position > 0 {
						t.position--
					}
				}
				termkit.key_right {
					if t.position < length {
						t.position++
					}
				}
				termkit.key_home {
					t.position = 0
				}
				termkit.key_end {
					t.position = length
				}
				termkit.key_backspace {
					if t.position > 0 {
						ch := rune_at(t.value, t.position - 1)
						prefix := rune_prefix(t.value, t.position - 1)
						t.value = prefix + t.value[prefix.len + ch.len..]
						t.position--
					}
				}
				termkit.key_delete {
					if t.position < length {
						ch := rune_at(t.value, t.position)
						prefix := rune_prefix(t.value, t.position)
						t.value = prefix + t.value[prefix.len + ch.len..]
					}
				}
				else {
					// A multi-byte key that is a single rune is printable text.
					// Named keys such as f1 have one byte per rune and are ignored.
					if msg.utf8 != '' {
						t.insert(msg.utf8)
					} else if msg.key.len == 1 || rune_len(msg.key) < msg.key.len {
						t.insert(msg.key)
					}
				}
			}
		}
		else {}
	}
}

fn (t TextInput) display(s string) string {
	if t.mask == 0 {
		return s
	}
	glyph := u8(t.mask).ascii_str()
	mut out := ''
	for _ in s.runes() {
		out += glyph
	}
	return out
}

// view renders the prompt, value and a cursor marker. When mask is set, the
// value is hidden behind the mask glyph.
pub fn (t TextInput) view() string {
	before := rune_prefix(t.value, t.position)
	mut marker := rune_at(t.value, t.position)
	after := if marker == '' { '' } else { t.value[before.len + marker.len..] }
	if marker == '' {
		marker = ' '
	}
	return t.prompt + t.display(before) + '\x1b[7m' + t.display(marker) + '\x1b[0m' +
		t.display(after)
}
