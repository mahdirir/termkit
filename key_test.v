module termkit

import term.ui as tui

fn test_key_name_printable() {
	assert key_name(tui.KeyCode.a) == 'a'
	assert key_name(tui.KeyCode.z) == 'z'
	assert key_name(tui.KeyCode._0) == '0'
	assert key_name(tui.KeyCode._9) == '9'
	assert key_name(tui.KeyCode.plus) == '+'
	assert key_name(tui.KeyCode.backslash) == '\\'
}

fn test_key_name_special() {
	assert key_name(tui.KeyCode.enter) == key_enter
	assert key_name(tui.KeyCode.escape) == key_esc
	assert key_name(tui.KeyCode.tab) == key_tab
	assert key_name(tui.KeyCode.f1) == 'f1'
	assert key_name(tui.KeyCode.f12) == 'f12'
	assert key_name(tui.KeyCode.f24) == 'f24'
	assert key_name(tui.KeyCode.null) == ''
}

fn test_key_for_event_special_keys_ignore_raw_utf8() {
	// Windows term.ui puts NUL in utf8 for non-printable keys; Unix term.ui
	// puts the raw escape sequence there. Neither is the key name.
	win := &tui.Event{ typ: .key_down, code: .up, utf8: '\x00' }
	assert key_for_event(win) == key_up
	unix := &tui.Event{ typ: .key_down, code: .down, utf8: '\x1b[B' }
	assert key_for_event(unix) == key_down
	assert key_for_event(&tui.Event{ typ: .key_down, code: .enter, utf8: '\r' }) == key_enter
	assert key_for_event(&tui.Event{ typ: .key_down, code: .backspace, utf8: '\x00' }) == key_backspace
	assert key_for_event(&tui.Event{ typ: .key_down, code: .f1, utf8: '\x00' }) == 'f1'
}

fn test_key_for_event_preserves_printable_text() {
	assert key_for_event(&tui.Event{ typ: .key_down, code: .a, utf8: 'A' }) == 'A'
	assert key_for_event(&tui.Event{ typ: .key_down, code: .space, utf8: ' ' }) == key_space
	assert key_for_event(&tui.Event{ typ: .key_down, code: .null, utf8: 'é' }) == 'é'
	assert key_for_event(&tui.Event{ typ: .key_down, code: .null, utf8: '' }) == ''
}

fn test_modifiers_from() {
	mut m := unsafe { tui.Modifiers(0) }
	m |= .ctrl
	m |= .shift
	out := modifiers_from(m)
	assert out.has(.ctrl)
	assert out.has(.shift)
	assert !out.has(.alt)
}
