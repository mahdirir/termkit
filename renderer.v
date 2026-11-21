module termkit

import os

// ColorProfile describes how much color a terminal supports.
pub enum ColorProfile {
	ascii
	ansi
	ansi256
	truecolor
}

pub const attr_bold = u8(1)
pub const attr_italic = u8(2)
pub const attr_underline = u8(4)
pub const attr_reverse = u8(8)

// color_profile_from_env derives a profile from the usual environment
// variables. Keeping this pure makes it testable without touching the process
// environment.
pub fn color_profile_from_env(no_color string, colorterm string, term_name string) ColorProfile {
	if no_color != '' {
		return .ascii
	}
	ct := colorterm.to_lower()
	if ct == 'truecolor' || ct == '24bit' {
		return .truecolor
	}
	t := term_name.to_lower()
	if t.contains('256color') || t == 'xterm-kitty' {
		return .ansi256
	}
	if t == '' || t == 'dumb' || t == 'linux' {
		return .ascii
	}
	return .ansi
}

// detect_color_profile reads the process environment and returns the profile.
pub fn detect_color_profile() ColorProfile {
	return color_profile_from_env(os.getenv('NO_COLOR'), os.getenv('COLORTERM'), os.getenv('TERM'))
}

struct Cell {
	text  string
	width int
	fg    string
	bg    string
	attrs u8
}

// Renderer keeps a cell grid and emits only the cells that changed since the
// previous frame. It is independent of term.ui so it can be tested with plain
// strings.
pub struct Renderer {
pub mut:
	width  int
	height int
pub:
	profile ColorProfile
mut:
	cells        []Cell
	prev         []Cell
	sync_updates bool = true
	alt_screen   bool
	has_rendered bool
}

// new_renderer creates a blank renderer of the given size.
pub fn new_renderer(width int, height int, profile ColorProfile) Renderer {
	size := if width > 0 && height > 0 { width * height } else { 0 }
	blank := Cell{}
	return Renderer{
		width:   width
		height:  height
		profile: profile
		cells:   []Cell{len: size, init: blank}
		prev:    []Cell{len: size, init: blank}
	}
}

// resize changes the grid dimensions. The diff baseline is reset so the next
// frame redraws the whole screen.
pub fn (mut r Renderer) resize(width int, height int) {
	if width <= 0 || height <= 0 {
		return
	}
	if width == r.width && height == r.height {
		return
	}
	blank := Cell{}
	r.width = width
	r.height = height
	r.cells = []Cell{len: width * height, init: blank}
	r.prev = []Cell{len: width * height, init: blank}
}

// clear resets the current grid to blank cells.
pub fn (mut r Renderer) clear() {
	blank := Cell{}
	for i in 0 .. r.cells.len {
		r.cells[i] = blank
	}
}

// set_cell places a string at x,y. fg and bg are SGR parameter strings (for
// example "31" or "38;5;42"); empty means default. attrs is a combination of
// the attr_* bits.
pub fn (mut r Renderer) set_cell(x int, y int, text string, fg string, bg string, attrs u8) {
	if x < 0 || y < 0 || x >= r.width || y >= r.height {
		return
	}
	w := utf8_str_visible_length(text)
	if w <= 0 {
		return
	}
	if w > 1 && x + w > r.width {
		return
	}
	idx := y * r.width + x
	r.cells[idx] = Cell{ text: text, width: w, fg: fg, bg: bg, attrs: attrs }
	for i in x + 1 .. x + w {
		r.cells[y * r.width + i] = Cell{ width: 0 }
	}
}

// draw_text writes text starting at x,y. SGR color and attribute sequences in
// the text are parsed into cell styles; other escape sequences are ignored.
pub fn (mut r Renderer) draw_text(x int, y int, text string, fg string, bg string, attrs u8) {
	mut cx := x
	mut cy := y
	mut state := SgrState{ fg: fg, bg: bg, attrs: attrs }
	mut cluster := ''
	mut in_sgr := false
	mut sgr := ''
	for ch in text.runes() {
		if ch == 27 {
			in_sgr = true
			sgr = ''
			continue
		}
		if in_sgr {
			sgr += ch.str()
			if ch == `m` {
				apply_sgr(sgr, mut state)
				in_sgr = false
				sgr = ''
			}
			continue
		}
		if ch == `\n` {
			if cluster != '' {
				r.set_cell(cx, cy, cluster, state.fg, state.bg, state.attrs)
				cluster = ''
			}
			cx = x
			cy++
			continue
		}
		if ch == `\t` {
			if cluster != '' {
				r.set_cell(cx, cy, cluster, state.fg, state.bg, state.attrs)
				cluster = ''
			}
			r.set_cell(cx, cy, '    ', state.fg, state.bg, state.attrs)
			cx += 4
			continue
		}
		cluster += ch.str()
		w := utf8_str_visible_length(cluster)
		if w == 0 {
			continue
		}
		r.set_cell(cx, cy, cluster, state.fg, state.bg, state.attrs)
		cx += w
		cluster = ''
	}
	if cluster != '' {
		w := utf8_str_visible_length(cluster)
		if w > 0 {
			r.set_cell(cx, cy, cluster, state.fg, state.bg, state.attrs)
		}
	}
}

struct SgrState {
mut:
	fg    string
	bg    string
	attrs u8
}

fn apply_sgr(seq string, mut st SgrState) {
	if seq.len < 2 || seq[0] != `[` || seq[seq.len - 1] != `m` {
		return
	}
	parts := seq[1..seq.len - 1].split(';')
	mut i := 0
	for i < parts.len {
		code := parts[i].int()
		match code {
			0 {
				st.fg = ''
				st.bg = ''
				st.attrs = 0
			}
			1 {
				st.attrs |= attr_bold
			}
			3 {
				st.attrs |= attr_italic
			}
			4 {
				st.attrs |= attr_underline
			}
			7 {
				st.attrs |= attr_reverse
			}
			22 {
				if st.attrs & attr_bold != 0 {
					st.attrs -= attr_bold
				}
				if st.attrs & attr_italic != 0 {
					st.attrs -= attr_italic
				}
			}
			23 {
				if st.attrs & attr_italic != 0 {
					st.attrs -= attr_italic
				}
			}
			24 {
				if st.attrs & attr_underline != 0 {
					st.attrs -= attr_underline
				}
			}
			27 {
				if st.attrs & attr_reverse != 0 {
					st.attrs -= attr_reverse
				}
			}
			39 {
				st.fg = ''
			}
			49 {
				st.bg = ''
			}
			38, 48 {
				if i + 1 < parts.len && parts[i + 1] == '5' && i + 2 < parts.len {
					value := '${code};5;${parts[i + 2]}'
					if code == 38 {
						st.fg = value
					} else {
						st.bg = value
					}
					i += 2
				} else if i + 4 < parts.len && parts[i + 1] == '2' {
					value := '${code};2;${parts[i + 2]};${parts[i + 3]};${parts[i + 4]}'
					if code == 38 {
						st.fg = value
					} else {
						st.bg = value
					}
					i += 4
				}
			}
			else {
				if code >= 30 && code <= 37 {
					st.fg = '${code}'
				} else if code >= 90 && code <= 97 {
					st.fg = '${code}'
				} else if code >= 40 && code <= 47 {
					st.bg = '${code}'
				} else if code >= 100 && code <= 107 {
					st.bg = '${code}'
				}
			}
		}
		i++
	}
}

// frame returns the escape sequences needed to turn the previous grid into
// the current one, then swaps the buffers. An unchanged frame returns ''.
pub fn (mut r Renderer) frame() string {
	mut out := ''
	mut skip_until := -1
	for y in 0 .. r.height {
		for x in 0 .. r.width {
			idx := y * r.width + x
			if idx <= skip_until {
				continue
			}
			c := r.cells[idx]
			if c.width == 0 {
				continue
			}
			p := r.prev[idx]
			if c.text == p.text && c.fg == p.fg && c.bg == p.bg && c.attrs == p.attrs {
				continue
			}
			// Batch adjacent changed cells that share a style into one write.
			mut run := c.text
			mut j := idx + 1
			row_end := (y + 1) * r.width
			for j < row_end {
				nc := r.cells[j]
				np := r.prev[j]
				if nc.width == 0 {
					j++
					continue
				}
				if nc.fg != c.fg || nc.bg != c.bg || nc.attrs != c.attrs {
					break
				}
				if nc.text == np.text && nc.fg == np.fg && nc.bg == np.bg && nc.attrs == np.attrs {
					break
				}
				run += nc.text
				j++
			}
			skip_until = j - 1
			out += '\x1b[${y + 1};${x + 1}H'
			out += style_for(c, r.profile)
			out += run
		}
	}
	r.prev = r.cells.clone()
	r.clear()
	r.has_rendered = true
	if out == '' {
		return ''
	}
	out += '\x1b[0m'
	if r.sync_updates {
		return '\x1b[?2026h' + out + '\x1b[?2026l'
	}
	return out
}

fn style_for(c Cell, profile ColorProfile) string {
	mut s := '\x1b[0m'
	if profile != .ascii {
		if c.fg != '' {
			s += '\x1b[${c.fg}m'
		}
		if c.bg != '' {
			s += '\x1b[${c.bg}m'
		}
	}
	if c.attrs & attr_bold != 0 {
		s += '\x1b[1m'
	}
	if c.attrs & attr_italic != 0 {
		s += '\x1b[3m'
	}
	if c.attrs & attr_underline != 0 {
		s += '\x1b[4m'
	}
	if c.attrs & attr_reverse != 0 {
		s += '\x1b[7m'
	}
	return s
}

// enter returns the sequences used when the renderer takes over the screen.
pub fn (r &Renderer) enter() string {
	mut s := ''
	if r.alt_screen {
		s += '\x1b[?1049h'
	}
	s += '\x1b[?25l\x1b[2J\x1b[H'
	return s
}

// leave returns the sequences used to restore the terminal.
pub fn (r &Renderer) leave() string {
	mut s := '\x1b[0m\x1b[?25h'
	if r.alt_screen {
		s += '\x1b[?1049l'
	}
	return s
}
