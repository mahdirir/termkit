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

fn test_modifiers_from() {
	mut m := unsafe { tui.Modifiers(0) }
	m |= .ctrl
	m |= .shift
	out := modifiers_from(m)
	assert out.has(.ctrl)
	assert out.has(.shift)
	assert !out.has(.alt)
}
