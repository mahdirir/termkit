module widgets

import termkit.style

// Progress is a percentage bar with optional color gradient.
pub struct Progress {
pub mut:
	percent int
	width   int = 20
	// gradient blends each bar cell from from to to. When off, the bar is
	// plain block characters.
	gradient bool
	from     style.Rgb
	to       style.Rgb
}

// set clamps and stores a percentage.
pub fn (mut p Progress) set(value int) {
	p.percent = if value < 0 {
		0
	} else if value > 100 {
		100
	} else {
		value
	}
}

// view_at renders the bar for percent without changing the stored value.
pub fn (p Progress) view_at(percent int) string {
	width := if p.width < 4 { 4 } else { p.width }
	v := if percent < 0 {
		0
	} else if percent > 100 {
		100
	} else {
		percent
	}
	filled := v * (width - 2) / 100
	mut bar := ''
	for i in 0 .. width - 2 {
		ch := if i < filled { '█' } else { '░' }
		if p.gradient {
			t := if width > 3 { f64(i) / f64(width - 3) } else { 0.0 }
			c := style.blend_rgb(p.from, p.to, t)
			bar += '\x1b[${c.fg()}m' + ch + '\x1b[0m'
		} else {
			bar += ch
		}
	}
	return '[${bar}] ${v}%'
}

// view renders the bar and percentage.
pub fn (p Progress) view() string {
	return p.view_at(p.percent)
}
