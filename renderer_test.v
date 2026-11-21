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
	r.draw_text(0, 0, 'hi', '', '', 0)
	first := r.frame()
	assert first.starts_with('\x1b[1;1H')
	assert first.contains('hi')
	assert r.frame() == ''
	r.draw_text(0, 0, 'ho', '', '', 0)
	second := r.frame()
	assert second.contains('o')
	assert !second.contains('hi')
}

fn test_style_codes() {
	mut r := new_renderer(4, 1, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, 'x', '31', '44', attr_bold | attr_underline)
	out := r.frame()
	assert out.contains('\x1b[31m')
	assert out.contains('\x1b[44m')
	assert out.contains('\x1b[1m')
	assert out.contains('\x1b[4m')
}

fn test_ascii_profile_drops_color() {
	mut r := new_renderer(4, 1, .ascii)
	r.sync_updates = false
	r.draw_text(0, 0, 'x', '31', '44', 0)
	out := r.frame()
	assert !out.contains('\x1b[31m')
	assert !out.contains('\x1b[44m')
}

fn test_wide_glyph_uses_two_cells() {
	mut r := new_renderer(4, 1, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, '世', '', '', 0)
	assert r.cells[0].width == 2
	assert r.cells[1].width == 0
	out := r.frame()
	assert out.contains('世')
	assert r.frame() == ''
}

fn test_rgb_to_ansi256_greys() {
	assert rgb_to_ansi256(0, 0, 0) == 16
	assert rgb_to_ansi256(8, 8, 8) == 232
	assert rgb_to_ansi256(248, 248, 248) == 255
	assert rgb_to_ansi256(250, 250, 250) == 231
}

fn test_rgb_downgrade() {
	mut r := new_renderer(2, 1, .ansi256)
	r.sync_updates = false
	r.draw_text(0, 0, '\x1b[38;2;255;0;0mx', '', '', 0)
	out := r.frame()
	assert out.contains('\x1b[38;5;196m')
	assert !out.contains('38;2;')
	mut basic := new_renderer(2, 1, .ansi)
	basic.sync_updates = false
	basic.draw_text(0, 0, '\x1b[48;2;0;0;255mx', '', '', 0)
	basic_out := basic.frame()
	assert basic_out.contains('\x1b[44m')
}

fn test_resize() {
	mut r := new_renderer(4, 1, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, 'ab', '', '', 0)
	r.frame()
	r.resize(6, 2)
	assert r.cells.len == 12
	assert r.prev.len == 12
	r.draw_text(0, 0, 'xy', '', '', 0)
	assert r.frame().contains('xy')
}

fn test_non_sgr_escapes_are_skipped() {
	mut r := new_renderer(8, 1, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, '\x1b[Ax', '', '', 0)
	assert r.cells[0].text == 'x'
	r.clear()
	r.draw_text(0, 0, '\x1b]0;title\x07y', '', '', 0)
	assert r.cells[0].text == 'y'
	r.clear()
	r.draw_text(0, 0, '\x1b7z', '', '', 0)
	assert r.cells[0].text == 'z'
}

fn test_combining_marks_stay_with_base() {
	mut r := new_renderer(8, 1, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, 'e\u0301x', '', '', 0)
	assert r.cells[0].text == 'e\u0301'
	assert r.cells[0].width == 1
	assert r.cells[1].text == 'x'
	r.clear()
	r.draw_text(0, 0, '世\u0301x', '', '', 0)
	assert r.cells[0].text == '世\u0301'
	assert r.cells[0].width == 2
	assert r.cells[2].text == 'x'
}

fn test_draw_text_carriage_return() {
	mut r := new_renderer(4, 1, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, 'ab\rc', '', '', 0)
	assert r.cells[0].text == 'c'
	assert !r.cells[0].text.contains('\r')
}

fn test_draw_text_newlines() {
	mut r := new_renderer(5, 3, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, 'ab\ncd', '', '', 0)
	assert r.cells[0].text == 'a'
	assert r.cells[5].text == 'c'
}

fn test_draw_text_parses_sgr() {
	mut r := new_renderer(4, 1, .ansi)
	r.sync_updates = false
	r.draw_text(0, 0, '\x1b[31mR\x1b[0m', '', '', 0)
	assert r.cells[0].fg == '31'
	out := r.frame()
	assert out.contains('\x1b[31m')
}

fn test_sync_updates_wrapper() {
	mut r := new_renderer(4, 1, .ansi)
	r.draw_text(0, 0, 'a', '', '', 0)
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
