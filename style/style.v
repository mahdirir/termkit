module style

import term
import termkit.layout

// attr_bold marks text as bold.
pub const attr_bold = u8(1)
// attr_italic marks text as italic.
pub const attr_italic = u8(2)
// attr_underline marks text as underlined.
pub const attr_underline = u8(4)
// attr_reverse marks text as reverse video.
pub const attr_reverse = u8(8)

// BorderKind selects the characters used for a box border.
pub enum BorderKind {
	none
	single
	rounded
	double
}

// Style describes how a block of text is rendered.
pub struct Style {
pub mut:
	fg      string
	bg      string
	attrs   u8
	border  BorderKind = .none
	padding int
	margin  int
	align   layout.Align = .start
	width   int
	title   string
}

// sgr returns the SGR sequence that activates this style.
pub fn (s Style) sgr() string {
	mut out := '\x1b[0m'
	if s.fg != '' {
		out += '\x1b[${s.fg}m'
	}
	if s.bg != '' {
		out += '\x1b[${s.bg}m'
	}
	if s.attrs & attr_bold != 0 {
		out += '\x1b[1m'
	}
	if s.attrs & attr_italic != 0 {
		out += '\x1b[3m'
	}
	if s.attrs & attr_underline != 0 {
		out += '\x1b[4m'
	}
	if s.attrs & attr_reverse != 0 {
		out += '\x1b[7m'
	}
	return out
}

// apply wraps text in this style and a trailing reset.
pub fn (s Style) apply(text string) string {
	return s.sgr() + text + '\x1b[0m'
}

struct Glyphs {
	tl string
	tr string
	bl string
	br string
	h  string
	v  string
}

fn glyphs_for(kind BorderKind) Glyphs {
	return match kind {
		.single { Glyphs{ tl: '┌', tr: '┐', bl: '└', br: '┘', h: '─', v: '│' } }
		.rounded { Glyphs{ tl: '╭', tr: '╮', bl: '╰', br: '╯', h: '─', v: '│' } }
		.double { Glyphs{ tl: '╔', tr: '╗', bl: '╚', br: '╝', h: '═', v: '║' } }
		else { Glyphs{} }
	}
}

fn repeat(s string, n int) string {
	if n <= 0 {
		return ''
	}
	mut out := ''
	for _ in 0 .. n {
		out += s
	}
	return out
}

// render lays out text with margin, padding, alignment and an optional
// border. The returned string contains SGR codes the termkit renderer parses.
pub fn (s Style) render(text string) string {
	margin := if s.margin < 0 { 0 } else { s.margin }
	if margin == 0 {
		return s.render_block(text)
	}
	mut inner_style := s
	inner_style.margin = 0
	inner_style.width = if s.width > 0 { s.width - 2 * margin } else { 0 }
	if inner_style.width < 1 {
		inner_style.width = 1
	}
	block := inner_style.render_block(text)
	reset := '\x1b[0m'
	core := if block.ends_with(reset) { block[..block.len - reset.len] } else { block }
	lines := core.split('\n')
	mut width := 0
	for line in lines {
		w := term.printable_len(line)
		if w > width {
			width = w
		}
	}
	total := width + 2 * margin
	mut out := ''
	for _ in 0 .. margin {
		out += repeat(' ', total) + '\n'
	}
	for line in lines {
		out += repeat(' ', margin) + line + repeat(' ', margin) + '\n'
	}
	for _ in 0 .. margin {
		out += repeat(' ', total) + '\n'
	}
	return out.trim_right('\n') + reset
}

fn (s Style) render_block(text string) string {
	lines := text.split('\n')
	mut content_width := 0
	for line in lines {
		w := term.printable_len(line)
		if w > content_width {
			content_width = w
		}
	}
	bordered := s.border != .none
	frame_width := if bordered { 2 } else { 0 }
	mut inner := content_width + s.padding * 2
	if s.width > 0 {
		inner = s.width - frame_width
		if inner < content_width + s.padding * 2 {
			inner = content_width + s.padding * 2
		}
	}
	mut body := []string{}
	for line in lines {
		w := term.printable_len(line)
		mut space := inner - w
		if space < 0 {
			space = 0
		}
		mut left := s.padding
		mut right := space - s.padding
		match s.align {
			.center {
				left = s.padding + space / 2
				right = space - left
			}
			.end {
				left = space - s.padding
				right = s.padding
			}
			else {}
		}
		body << repeat(' ', left) + line + repeat(' ', right)
	}
	mut out := s.sgr()
	if !bordered {
		return out + body.join('\n') + '\x1b[0m'
	}
	g := glyphs_for(s.border)
	mut title := s.title
	if title.len > inner - 2 && inner > 4 {
		title = title[..inner - 2]
	}
	top_label := if title == '' { '' } else { ' ' + title + ' ' }
	mut top_fill := inner - term.printable_len(top_label)
	if top_fill < 0 {
		top_fill = 0
	}
	out += g.tl + top_label + repeat(g.h, top_fill) + g.tr + '\n'
	for line in body {
		out += g.v + line + g.v + '\n'
	}
	out += g.bl + repeat(g.h, inner) + g.br
	return out + '\x1b[0m'
}
