module style

import os

// Rgb is an 8-bit-per-channel color.
pub struct Rgb {
pub:
	r u8
	g u8
	b u8
}

// fg returns the SGR parameter string for a 24-bit foreground color.
pub fn (c Rgb) fg() string {
	return '38;2;${c.r};${c.g};${c.b}'
}

// bg returns the SGR parameter string for a 24-bit background color.
pub fn (c Rgb) bg() string {
	return '48;2;${c.r};${c.g};${c.b}'
}

// rgb creates a color from three 8-bit channels.
pub fn rgb(r u8, g u8, b u8) Rgb {
	return Rgb{ r: r, g: g, b: b }
}

// from_hex parses a #RRGGBB string into a color.
pub fn from_hex(text string) ?Rgb {
	s := if text.starts_with('#') { text[1..] } else { text }
	if s.len != 6 {
		return none
	}
	r := parse_hex_pair(s[0..2]) or { return none }
	g := parse_hex_pair(s[2..4]) or { return none }
	b := parse_hex_pair(s[4..6]) or { return none }
	return Rgb{ r: r, g: g, b: b }
}

fn parse_hex_pair(pair string) ?u8 {
	if pair.len != 2 {
		return none
	}
	hi := hex_nibble(pair[0]) or { return none }
	lo := hex_nibble(pair[1]) or { return none }
	return u8(hi * 16 + lo)
}

fn hex_nibble(ch u8) ?u8 {
	if ch >= `0` && ch <= `9` {
		return ch - `0`
	}
	if ch >= `a` && ch <= `f` {
		return ch - `a` + 10
	}
	if ch >= `A` && ch <= `F` {
		return ch - `A` + 10
	}
	return none
}

// ansi256_fg returns the SGR parameter for an indexed foreground color.
pub fn ansi256_fg(index u8) string {
	return '38;5;${index}'
}

// ansi256_bg returns the SGR parameter for an indexed background color.
pub fn ansi256_bg(index u8) string {
	return '48;5;${index}'
}

// blend_rgb linearly interpolates between a and b by t in [0, 1].
pub fn blend_rgb(a Rgb, b Rgb, t f64) Rgb {
	clamped := if t < 0 {
		0.0
	} else if t > 1 {
		1.0
	} else {
		t
	}
	return Rgb{
		r: u8(f64(a.r) + (f64(b.r) - f64(a.r)) * clamped)
		g: u8(f64(a.g) + (f64(b.g) - f64(a.g)) * clamped)
		b: u8(f64(a.b) + (f64(b.b) - f64(a.b)) * clamped)
	}
}

// darken moves a color toward black by t in [0, 1].
pub fn darken(c Rgb, t f64) Rgb {
	return blend_rgb(c, Rgb{}, t)
}

// lighten moves a color toward white by t in [0, 1].
pub fn lighten(c Rgb, t f64) Rgb {
	return blend_rgb(c, Rgb{ r: 255, g: 255, b: 255 }, t)
}

// complementary returns the channel-inverted color.
pub fn complementary(c Rgb) Rgb {
	return Rgb{ r: 255 - c.r, g: 255 - c.g, b: 255 - c.b }
}

// ColorScheme holds one color with light and dark terminal variants.
pub struct ColorScheme {
pub:
	light Rgb
	dark  Rgb
}

// resolve picks the variant for a dark or light background.
pub fn (s ColorScheme) resolve(dark_bg bool) Rgb {
	if dark_bg {
		return s.dark
	}
	return s.light
}

// detect_dark_background reads COLORFGBG to guess a dark background. It
// returns none when the variable is absent or unparseable. Many terminals
// set COLORFGBG as "fg;bg" with 0-6 and 8 meaning dark backgrounds.
pub fn detect_dark_background() ?bool {
	raw := os.getenv('COLORFGBG')
	if raw == '' {
		return none
	}
	parts := raw.split(';')
	if parts.len < 2 {
		return none
	}
	bg := parts[parts.len - 1].int()
	if bg >= 0 && (bg <= 6 || bg == 8) {
		return true
	}
	if bg == 7 || (bg >= 9 && bg <= 15) || bg >= 253 {
		return false
	}
	return none
}
