module termkit

import term.ui as tui

// key_enter is the name of the Enter key.
pub const key_enter = 'enter'
// key_tab is the name of the Tab key.
pub const key_tab = 'tab'
// key_esc is the name of the Escape key.
pub const key_esc = 'esc'
// key_space is the name of the Space key.
pub const key_space = ' '
// key_backspace is the name of the Backspace key.
pub const key_backspace = 'backspace'
// key_delete is the name of the Delete key.
pub const key_delete = 'delete'
// key_up is the name of the Up arrow.
pub const key_up = 'up'
// key_down is the name of the Down arrow.
pub const key_down = 'down'
// key_left is the name of the Left arrow.
pub const key_left = 'left'
// key_right is the name of the Right arrow.
pub const key_right = 'right'
// key_home is the name of the Home key.
pub const key_home = 'home'
// key_end is the name of the End key.
pub const key_end = 'end'
// key_page_up is the name of the Page Up key.
pub const key_page_up = 'pgup'
// key_page_down is the name of the Page Down key.
pub const key_page_down = 'pgdown'
// key_insert is the name of the Insert key.
pub const key_insert = 'insert'
// key_ctrl_c is the name of the Ctrl+C key combination.
pub const key_ctrl_c = 'ctrl+c'

// key_name converts a term.ui key code to a stable name.
//
// Printable ASCII is returned as the character itself. Special keys use the
// short names above, and function keys use `f1` through `f24`.
pub fn key_name(code tui.KeyCode) string {
	n := int(code)
	if n >= int(tui.KeyCode._0) && n <= int(tui.KeyCode._9) {
		return u8(n).ascii_str()
	}
	if n >= int(tui.KeyCode.a) && n <= int(tui.KeyCode.z) {
		return u8(n).ascii_str()
	}
	match code {
		.null {
			return ''
		}
		.tab {
			return key_tab
		}
		.enter {
			return key_enter
		}
		.escape {
			return key_esc
		}
		.space {
			return key_space
		}
		.backspace {
			return key_backspace
		}
		.exclamation {
			return '!'
		}
		.double_quote {
			return '"'
		}
		.hashtag {
			return '#'
		}
		.dollar {
			return '$'
		}
		.percent {
			return '%'
		}
		.ampersand {
			return '&'
		}
		.single_quote {
			return "'"
		}
		.left_paren {
			return '('
		}
		.right_paren {
			return ')'
		}
		.asterisk {
			return '*'
		}
		.plus {
			return '+'
		}
		.comma {
			return ','
		}
		.minus {
			return '-'
		}
		.period {
			return '.'
		}
		.slash {
			return '/'
		}
		.colon {
			return ':'
		}
		.semicolon {
			return ';'
		}
		.less_than {
			return '<'
		}
		.equal {
			return '='
		}
		.greater_than {
			return '>'
		}
		.question_mark {
			return '?'
		}
		.at {
			return '@'
		}
		.left_square_bracket {
			return '['
		}
		.backslash {
			return '\\'
		}
		.right_square_bracket {
			return ']'
		}
		.caret {
			return '^'
		}
		.underscore {
			return '_'
		}
		.backtick {
			return '`'
		}
		.left_curly_bracket {
			return '{'
		}
		.vertical_bar {
			return '|'
		}
		.right_curly_bracket {
			return '}'
		}
		.tilde {
			return '~'
		}
		.insert {
			return key_insert
		}
		.delete {
			return key_delete
		}
		.up {
			return key_up
		}
		.down {
			return key_down
		}
		.right {
			return key_right
		}
		.left {
			return key_left
		}
		.page_up {
			return key_page_up
		}
		.page_down {
			return key_page_down
		}
		.home {
			return key_home
		}
		.end {
			return key_end
		}
		else {}
	}
	if n >= int(tui.KeyCode.f1) && n <= int(tui.KeyCode.f24) {
		return 'f${n - int(tui.KeyCode.f1) + 1}'
	}
	return ''
}

// key_for_event returns the key name carried by a term.ui event. Printable
// text is preferred so UTF-8 and IME input survive; control characters, NUL
// padding and raw escape sequences are not text and must not mask the decoded
// key name (arrows, function keys, Enter, Backspace and friends all arrive
// with bytes in Event.utf8).
pub fn key_for_event(e &tui.Event) string {
	if is_printable_text(e.utf8) {
		return e.utf8
	}
	return key_name(e.code)
}

fn is_printable_text(s string) bool {
	if s == '' {
		return false
	}
	for r in s.runes() {
		if r < 0x20 || (r >= 0x7f && r <= 0x9f) || (r >= 0xd800 && r <= 0xdfff) {
			return false
		}
	}
	return true
}

// modifiers_from converts term.ui modifiers to termkit modifiers.
pub fn modifiers_from(m tui.Modifiers) Modifiers {
	// The zero flag value has no literal spelling; the cast is safe because
	// the result is immediately built up with valid flag combinations.
	mut out := unsafe { Modifiers(0) }
	if m.has(.ctrl) {
		out |= .ctrl
	}
	if m.has(.shift) {
		out |= .shift
	}
	if m.has(.alt) {
		out |= .alt
	}
	return out
}
