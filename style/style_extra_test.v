module style

import term

fn test_extra_attrs_sgr() {
	faint := Style{ attrs: attr_faint }
	assert faint.sgr().contains('[2m')
	blink := Style{ attrs: attr_blink }
	assert blink.sgr().contains('[5m')
	strike := Style{ attrs: attr_strike }
	assert strike.sgr().contains('[9m')
	curly := Style{ underline_style: .curly }
	assert curly.sgr().contains('[4:3m')
	double := Style{ underline_style: .double }
	assert double.sgr().contains('[4:2m')
	plain_underline := Style{ attrs: attr_underline }
	assert plain_underline.sgr().contains('[4m')
	colored := Style{ attrs: attr_underline, underline_color: '31' }
	assert colored.sgr().contains('58;31m')
}

fn test_apply_hyperlink() {
	s := Style{ link: 'https://example.com' }
	out := s.apply('hi')
	assert out.contains(']8;;https://example.com')
	assert out.contains('hi')
	plain := Style{}
	assert !plain.apply('hi').contains(']8;;')
}

fn test_inherit_fills_unset() {
	base := Style{ fg: '31', padding: 2 }
	child := Style{ bg: '42' }
	merged := child.inherit(base)
	assert merged.fg == '31'
	assert merged.bg == '42'
	assert merged.padding == 2
	other := Style{ fg: '32' }
	kept := child.inherit(other)
	assert kept.bg == '42'
	bold_child := Style{ attrs: attr_bold }
	bold_merged := bold_child.inherit(Style{ attrs: attr_italic })
	assert bold_merged.attrs & attr_bold != 0
	assert bold_merged.attrs & attr_italic != 0
}

fn test_wrap_text_basic() {
	assert wrap_text('one two three', 7) == 'one two\nthree'
	assert wrap_text('a b c', 1) == 'a\nb\nc'
	assert wrap_text('', 10) == ''
	assert wrap_text('hi', 0) == 'hi'
}

fn test_wrap_text_long_word() {
	out := wrap_text('abcdefghij', 4)
	assert out == 'abcd\nefgh\nij'
}

fn test_wrap_text_keeps_ansi() {
	styled := '\x1b[31mone two three\x1b[0m'
	out := wrap_text(styled, 7)
	assert out.contains('\x1b[31m')
	assert out.split('\n').len == 2
	for line in out.split('\n') {
		assert term.printable_len(line) <= 7
	}
}

fn test_render_inline_skips_block() {
	s := Style{ border: .single, padding: 2, inline: true }
	out := s.render('hi')
	assert !out.contains('┌')
	assert out.contains('hi')
}

fn test_render_max_width_clamps() {
	s := Style{ border: .single, width: 40, max_width: 10 }
	out := s.render('hi')
	assert term.printable_len(out.split('\n')[0]) <= 12
}

fn test_render_max_height_truncates() {
	s := Style{ max_height: 2 }
	out := s.render('one\ntwo\nthree')
	assert out.split('\n').len == 2
}
