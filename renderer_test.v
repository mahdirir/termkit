module termkit

fn test_color_profile_from_env() {
	assert color_profile_from_env('1', 'truecolor', 'xterm-256color') == .ascii
	assert color_profile_from_env('', 'truecolor', 'xterm') == .truecolor
	assert color_profile_from_env('', '', 'xterm-256color') == .ansi256
	assert color_profile_from_env('', '', 'dumb') == .ascii
	assert color_profile_from_env('', '', 'xterm') == .ansi
}

fn test_new_renderer_is_blank() {
	mut r := new_renderer(4, 2, .ansi)
	assert r.cells.len == 8
	assert r.prev.len == 8
	assert r.frame() == ''
}

fn test_draw_text_and_diff() {
	mut r := new_renderer(10, 1, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, 'hi', -1, -1, 0)
	first := r.frame()
	assert first.starts_with('\x1b[1;1H')
	assert first.contains('hi')
	assert r.frame() == ''
	r.draw_text(0, 0, 'ho', -1, -1, 0)
	second := r.frame()
	assert second.contains('o')
	assert !second.contains('hi')
}

fn test_style_codes() {
	mut r := new_renderer(4, 1, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, 'x', 31, 44, attr_bold | attr_underline)
	out := r.frame()
	assert out.contains('\x1b[31m')
	assert out.contains('\x1b[44m')
	assert out.contains('\x1b[1m')
	assert out.contains('\x1b[4m')
}

fn test_ascii_profile_drops_color() {
	mut r := new_renderer(4, 1, .ascii)
	r.sync_updates = false
	r.draw_text(0, 0, 'x', 31, 44, 0)
	out := r.frame()
	assert !out.contains('\x1b[31m')
	assert !out.contains('\x1b[44m')
}

fn test_wide_glyph_uses_two_cells() {
	mut r := new_renderer(4, 1, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, '世', -1, -1, 0)
	assert r.cells[0].width == 2
	assert r.cells[1].width == 0
	out := r.frame()
	assert out.contains('世')
	assert r.frame() == ''
}

fn test_draw_text_newlines() {
	mut r := new_renderer(5, 3, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, 'ab\ncd', -1, -1, 0)
	assert r.cells[0].text == 'a'
	assert r.cells[5].text == 'c'
}

fn test_sync_updates_wrapper() {
	mut r := new_renderer(4, 1, .ansi)
	r.draw_text(0, 0, 'a', -1, -1, 0)
	out := r.frame()
	assert out.starts_with('\x1b[?2026h')
	assert out.ends_with('\x1b[?2026l')
}

fn test_enter_leave() {
	mut r := new_renderer(4, 1, .ansi)
	assert !r.enter().contains('1049')
	r.alt_screen = true
	assert r.enter().contains('\x1b[?1049h')
	assert r.leave().contains('\x1b[?1049l')
}
