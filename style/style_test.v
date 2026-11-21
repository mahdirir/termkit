module style

import term
import termkit.layout

fn test_sgr() {
	s := Style{ fg: '31', bg: '44', attrs: attr_bold | attr_underline }
	assert s.sgr() == '\x1b[0m\x1b[31m\x1b[44m\x1b[1m\x1b[4m'
	assert s.apply('x').ends_with('\x1b[0m')
}

fn test_render_plain() {
	mut s := Style{}
	s.width = 6
	s.align = .center
	out := s.render('hi')
	assert out.contains('hi')
	assert term.printable_len(out) >= 6
}

fn test_render_border() {
	s := Style{ border: .single, title: 'box' }
	out := s.render('hi')
	assert out.contains('┌ box')
	assert out.contains('│')
	assert out.ends_with('┘\x1b[0m')
}

fn test_render_utf8_title() {
	s := Style{ border: .single, title: '你好世界', width: 8 }
	out := s.render('x')
	assert out.contains('你好')
}

fn test_color_helpers() {
	c := from_hex('#1a2b3c') or {
		assert false
		return
	}
	assert c.r == 26 && c.g == 43 && c.b == 60
	assert c.fg() == '38;2;26;43;60'
	assert c.bg() == '48;2;26;43;60'
	assert from_hex('bad') == none
	assert ansi256_fg(42) == '38;5;42'
	assert ansi256_bg(42) == '48;5;42'
}

fn test_render_margin() {
	s := Style{ border: .single, margin: 1, width: 12 }
	out := s.render('hi')
	assert out.starts_with('            \n')
	assert out.contains('┌')
	assert out.ends_with(' \x1b[0m')
}

fn test_render_alignment() {
	mut s := Style{ width: 8, align: .end }
	assert s.render('x').contains('       x')
	s.align = layout.Align.start
	assert s.render('x').starts_with('\x1b[0mx')
}
