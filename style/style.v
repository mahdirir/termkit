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
// attr_faint marks text as faint.
pub const attr_faint = u8(16)
// attr_blink marks text as blinking.
pub const attr_blink = u8(32)
// attr_strike marks text as struck through.
pub const attr_strike = u8(64)

// UnderlineStyle selects the underline variant (SGR 4:x).
pub enum UnderlineStyle {
	none
	single
	double
	curly
	dotted
	dashed
}

// BorderKind selects the characters used for a box border.
pub enum BorderKind {
	none
	single
	rounded
	double
	thick
	block
	ascii
	hidden
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
	// max_width clamps the rendered block to at most this many visible cells.
	// Values <= 0 mean no clamp.
	max_width int
	// max_height truncates the rendered block to at most this many lines.
	// Values <= 0 mean no clamp.
	max_height int
	// inline disables border, padding, margin and width so the style only
	// contributes inline SGR attributes.
	inline bool
	// underline_style selects the underline variant. .none keeps attr_underline.
	underline_style UnderlineStyle = .none
	// underline_color is the SGR parameter for the underline color.
	underline_color string
	// link wraps rendered output in an OSC8 hyperlink when non-empty. The
	// diffing renderer only parses SGR, so linked output is best used with
	// Style.apply rather than the cell renderer.
	link string
	// tab_width expands tab characters to this many spaces during render.
	// Values <= 0 leave tabs untouched.
	tab_width int
	// border_fg is the SGR parameter for the border color. Empty keeps the
	// style foreground.
	border_fg string
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
	if s.attrs & attr_faint != 0 {
		out += '\x1b[2m'
	}
	if s.attrs & attr_italic != 0 {
		out += '\x1b[3m'
	}
	if s.attrs & attr_blink != 0 {
		out += '\x1b[5m'
	}
	if s.attrs & attr_reverse != 0 {
		out += '\x1b[7m'
	}
	if s.attrs & attr_strike != 0 {
		out += '\x1b[9m'
	}
	match s.underline_style {
		.single {
			out += '\x1b[4:1m'
		}
		.double {
			out += '\x1b[4:2m'
		}
		.curly {
			out += '\x1b[4:3m'
		}
		.dotted {
			out += '\x1b[4:4m'
		}
		.dashed {
			out += '\x1b[4:5m'
		}
		else {}
	}
	if s.attrs & attr_underline != 0 && s.underline_style == .none {
		out += '\x1b[4m'
	}
	if s.underline_color != '' {
		out += '\x1b[58;${s.underline_color}m'
	}
	return out
}

// apply wraps text in this style and a trailing reset. When link is set, the
// result is additionally wrapped in an OSC8 hyperlink.
pub fn (s Style) apply(text string) string {
	styled := s.sgr() + text + '\x1b[0m'
	if s.link == '' {
		return styled
	}
	return '\x1b]8;;${s.link}\x1b\\' + styled + '\x1b]8;;\x1b\\'
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
		.thick { Glyphs{ tl: '┏', tr: '┓', bl: '┗', br: '┛', h: '━', v: '┃' } }
		.block { Glyphs{ tl: '█', tr: '█', bl: '█', br: '█', h: '█', v: '█' } }
		.ascii { Glyphs{ tl: '+', tr: '+', bl: '+', br: '+', h: '-', v: '|' } }
		.hidden { Glyphs{ tl: ' ', tr: ' ', bl: ' ', br: ' ', h: ' ', v: ' ' } }
		else { Glyphs{} }
	}
}

// border_open returns the SGR switch for border glyphs, or an empty string
// when the border uses the style foreground.
fn (s Style) border_open() string {
	if s.border_fg == '' {
		return ''
	}
	return '\x1b[${s.border_fg}m'
}

// expand_tabs replaces tab characters with tab_width spaces.
pub fn expand_tabs(text string, tab_width int) string {
	if tab_width <= 0 || !text.contains('\t') {
		return text
	}
	return text.replace('\t', ' '.repeat(tab_width))
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

// truncate_width shortens s to at most width visible cells on rune boundaries.
fn truncate_width(s string, width int) string {
	if width <= 0 {
		return ''
	}
	if term.printable_len(s) <= width {
		return s
	}
	mut out := ''
	mut used := 0
	for r in s.runes() {
		rs := r.str()
		w := term.printable_len(rs)
		if used + w > width {
			break
		}
		out += rs
		used += w
	}
	return out
}

// inherit returns a copy of s with every unset field taken from other.
// Empty strings, zero numbers, .none variants and .start alignment count as
// unset; attribute bits are combined.
pub fn (s Style) inherit(other Style) Style {
	mut out := s
	if out.fg == '' {
		out.fg = other.fg
	}
	if out.bg == '' {
		out.bg = other.bg
	}
	if out.border == .none {
		out.border = other.border
	}
	if out.padding == 0 {
		out.padding = other.padding
	}
	if out.margin == 0 {
		out.margin = other.margin
	}
	if out.align == .start {
		out.align = other.align
	}
	if out.width == 0 {
		out.width = other.width
	}
	if out.title == '' {
		out.title = other.title
	}
	if out.max_width == 0 {
		out.max_width = other.max_width
	}
	if out.max_height == 0 {
		out.max_height = other.max_height
	}
	if out.underline_style == .none {
		out.underline_style = other.underline_style
	}
	if out.underline_color == '' {
		out.underline_color = other.underline_color
	}
	if out.link == '' {
		out.link = other.link
	}
	out.attrs |= other.attrs
	return out
}

// wrap_text wraps text to at most width visible cells per line, breaking on
// spaces. ANSI escape sequences ride along with their word and never count
// toward the width.
pub fn wrap_text(text string, width int) string {
	if width <= 0 {
		return text
	}
	mut out := []string{}
	for raw_line in text.split('\n') {
		out << wrap_line(raw_line, width)
	}
	return out.join('\n')
}

fn wrap_line(line string, width int) []string {
	mut lines := []string{}
	mut cur := ''
	mut cur_w := 0
	for word in line.split(' ') {
		w := term.printable_len(word)
		if cur == '' {
			if w <= width {
				cur = word
				cur_w = w
				continue
			}
			for chunk in break_word(word, width) {
				lines << chunk
			}
			continue
		}
		if cur_w + 1 + w <= width {
			cur += ' ' + word
			cur_w += 1 + w
			continue
		}
		lines << cur
		if w <= width {
			cur = word
			cur_w = w
		} else {
			cur = ''
			cur_w = 0
			for chunk in break_word(word, width) {
				lines << chunk
			}
		}
	}
	if cur != '' {
		lines << cur
	}
	if lines.len == 0 {
		return ['']
	}
	return lines
}

// break_word hard-breaks an oversized word into width-sized printable chunks,
// keeping ANSI escape sequences attached to their text.
fn break_word(word string, width int) []string {
	mut chunks := []string{}
	mut cur := ''
	mut cur_w := 0
	runes := word.runes()
	mut i := 0
	for i < runes.len {
		if runes[i].str() == '\x1b' && i + 1 < runes.len && runes[i + 1].str() == '[' {
			mut j := i + 2
			for j < runes.len {
				c := runes[j].str()
				if (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') {
					j++
					break
				}
				j++
			}
			for k in i .. j {
				cur += runes[k].str()
			}
			i = j
			continue
		}
		w := term.printable_len(runes[i].str())
		if cur_w + w > width && cur_w > 0 {
			chunks << cur
			cur = ''
			cur_w = 0
		}
		cur += runes[i].str()
		cur_w += w
		i++
	}
	if cur != '' {
		chunks << cur
	}
	return chunks
}

// render lays out text with margin, padding, alignment and an optional
// border. The returned string contains SGR codes the termkit renderer parses.
// Inline styles skip block layout; max_width and max_height clamp the block.
pub fn (s Style) render(text string) string {
	if s.inline {
		return s.apply(text)
	}
	mut styled := s
	if styled.max_width > 0 && (styled.width <= 0 || styled.width > styled.max_width) {
		styled.width = styled.max_width
	}
	mut body := expand_tabs(text, styled.tab_width)
	if styled.max_height > 0 {
		lines := body.split('\n')
		if lines.len > styled.max_height {
			body = lines[..styled.max_height].join('\n')
		}
	}
	return styled.render_inner(body)
}

fn (s Style) render_inner(text string) string {
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
	fg_open := s.border_open()
	fg_resume := if fg_open == '' { '' } else { s.sgr() }
	mut title := s.title
	if inner > 4 {
		title = truncate_width(title, inner - 2)
	}
	top_label := if title == '' { '' } else { ' ' + title + ' ' }
	mut top_fill := inner - term.printable_len(top_label)
	if top_fill < 0 {
		top_fill = 0
	}
	out += fg_open + g.tl + top_label + repeat(g.h, top_fill) + g.tr + fg_resume + '\n'
	for line in body {
		out += fg_open + g.v + fg_resume + line + fg_open + g.v + fg_resume + '\n'
	}
	out += fg_open + g.bl + repeat(g.h, inner) + g.br + fg_resume
	return out + '\x1b[0m'
}
