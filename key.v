module termkit

import term.ui as tui

pub const key_enter = 'enter'
pub const key_tab = 'tab'
pub const key_esc = 'esc'
pub const key_space = ' '
pub const key_backspace = 'backspace'
pub const key_delete = 'delete'
pub const key_up = 'up'
pub const key_down = 'down'
pub const key_left = 'left'
pub const key_right = 'right'
pub const key_home = 'home'
pub const key_end = 'end'
pub const key_page_up = 'pgup'
pub const key_page_down = 'pgdown'
pub const key_insert = 'insert'
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

// key_for_event returns the key name carried by a term.ui event. Text events
// are preferred so UTF-8 input is preserved.
pub fn key_for_event(e &tui.Event) string {
	if e.utf8 != '' {
		return e.utf8
	}
	return key_name(e.code)
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
