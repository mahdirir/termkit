@[has_globals]
module main

import termkit
import termkit.cli
import termkit.layout
import termkit.style
import term.ui as tui

// Returned string pointers point into a buffer owned by the library. They stay
// valid until the next call to the same function. Copy them if you need to
// keep the value.
__global (
	tk_frame_buf string
	tk_style_buf string
	tk_cli_buf   string
	tk_color_buf string
	tk_key_buf   string
	tk_empty_buf string = ''
)

struct CRenderer {
	r termkit.Renderer
}

fn cstr(s &char) string {
	if isnil(s) {
		return ''
	}
	return unsafe { s.vstring() }
}

fn renderer(h voidptr) &CRenderer {
	return unsafe { &CRenderer(h) }
}

// tk_version returns the termkit version string.
@[export: 'tk_version']
pub fn c_version() &char {
	return c'0.1.0'
}

// tk_color_profile_from_env maps NO_COLOR/COLORTERM/TERM to a profile:
// 0 = ascii, 1 = ansi, 2 = ansi256, 3 = truecolor.
@[export: 'tk_color_profile_from_env']
pub fn c_color_profile(no_color &char, colorterm &char, term_name &char) int {
	return int(termkit.color_profile_from_env(cstr(no_color), cstr(colorterm), cstr(term_name)))
}

// tk_renderer_new creates an opaque renderer handle.
@[export: 'tk_renderer_new']
pub fn c_renderer_new(width int, height int, profile int) voidptr {
	prof := unsafe { termkit.ColorProfile(profile) }
	mut r := termkit.new_renderer(width, height, prof)
	return voidptr(&CRenderer{ r: r })
}

// tk_renderer_free releases a renderer handle. The underlying memory is
// reclaimed by the V runtime when no references remain.
@[export: 'tk_renderer_free']
pub fn c_renderer_free(h voidptr) {
	if isnil(h) {
		return
	}
	_ = renderer(h)
}

// tk_renderer_clear blanks the current grid.
@[export: 'tk_renderer_clear']
pub fn c_renderer_clear(h voidptr) {
	if isnil(h) {
		return
	}
	mut cr := renderer(h)
	cr.r.clear()
}

// tk_renderer_resize changes the grid size and resets the diff baseline.
@[export: 'tk_renderer_resize']
pub fn c_renderer_resize(h voidptr, width int, height int) {
	if isnil(h) {
		return
	}
	mut cr := renderer(h)
	cr.r.resize(width, height)
}

// tk_renderer_draw_text writes styled text at x,y. fg/bg are SGR parameter
// strings such as "31" or "38;5;42"; pass null for default colors.
@[export: 'tk_renderer_draw_text']
pub fn c_renderer_draw_text(h voidptr, x int, y int, text &char, fg &char, bg &char, attrs u8) {
	if isnil(h) {
		return
	}
	mut cr := renderer(h)
	cr.r.draw_text(x, y, cstr(text), cstr(fg), cstr(bg), attrs)
}

// tk_renderer_frame returns the escape sequences diffing the last frame.
@[export: 'tk_renderer_frame']
pub fn c_renderer_frame(h voidptr) &char {
	if isnil(h) {
		return tk_empty_buf.str
	}
	mut cr := renderer(h)
	tk_frame_buf = cr.r.frame()
	return tk_frame_buf.str
}

// tk_style_render renders text with border, padding, margin and alignment.
// border: 0 none, 1 single, 2 rounded, 3 double. align: 0 start, 1 center, 2 end.
@[export: 'tk_style_render']
pub fn c_style_render(text &char, border int, title &char, padding int, margin int, width int, align int) &char {
	s := unsafe {
		style.Style{
			border:  style.BorderKind(border)
			title:   cstr(title)
			padding: padding
			margin:  margin
			width:   width
			align:   layout.Align(align)
		}
	}
	tk_style_buf = s.render(cstr(text))
	return tk_style_buf.str
}

// tk_cli_help generates help text for a root command with no flags.
@[export: 'tk_cli_help']
pub fn c_cli_help(name &char, description &char, version &char) &char {
	mut cmd := cli.Command{
		name:        cstr(name)
		description: cstr(description)
		version:     cstr(version)
	}
	cmd.setup()
	tk_cli_buf = cmd.help_message()
	return tk_cli_buf.str
}

// tk_cli_suggest returns a "did you mean" hint for input over the given
// candidates, or an empty string when no close candidate exists.
@[export: 'tk_cli_suggest']
pub fn c_cli_suggest(input &char, candidates &&char, count int) &char {
	mut words := []string{}
	if count > 0 && !isnil(candidates) {
		for i in 0 .. count {
			p := unsafe { candidates[i] }
			words << cstr(p)
		}
	}
	tk_cli_buf = cli.suggest(cstr(input), words)
	return tk_cli_buf.str
}

// tk_levenshtein returns the edit distance between two strings.
@[export: 'tk_levenshtein']
pub fn c_levenshtein(a &char, b &char) int {
	return cli.levenshtein(cstr(a), cstr(b))
}

// tk_key_name maps a term.ui KeyCode number to its termkit name.
@[export: 'tk_key_name']
pub fn c_key_name(code int) &char {
	tk_key_buf = termkit.key_name(unsafe { tui.KeyCode(code) })
	return tk_key_buf.str
}

// tk_rgb_fg returns the SGR parameters for a 24-bit foreground color.
@[export: 'tk_rgb_fg']
pub fn c_rgb_fg(r u8, g u8, b u8) &char {
	tk_color_buf = style.rgb(r, g, b).fg()
	return tk_color_buf.str
}

// tk_rgb_bg returns the SGR parameters for a 24-bit background color.
@[export: 'tk_rgb_bg']
pub fn c_rgb_bg(r u8, g u8, b u8) &char {
	tk_color_buf = style.rgb(r, g, b).bg()
	return tk_color_buf.str
}

// tk_rgb_to_ansi256 maps 24-bit RGB to an xterm 256-color index.
@[export: 'tk_rgb_to_ansi256']
pub fn c_rgb_to_ansi256(r int, g int, b int) u8 {
	return termkit.rgb_to_ansi256(r, g, b)
}

// tk_rgb_to_basic maps 24-bit RGB to one of the eight basic ANSI colors.
@[export: 'tk_rgb_to_basic']
pub fn c_rgb_to_basic(r int, g int, b int) u8 {
	return termkit.rgb_to_basic(r, g, b)
}
