module widgets

// Progress is a simple percentage bar.
pub struct Progress {
pub mut:
	percent int
	width   int = 20
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

// view renders the bar and percentage.
pub fn (p Progress) view() string {
	width := if p.width < 4 { 4 } else { p.width }
	percent := if p.percent < 0 {
		0
	} else if p.percent > 100 {
		100
	} else {
		p.percent
	}
	filled := percent * (width - 2) / 100
	mut bar := ''
	for i in 0 .. width - 2 {
		bar += if i < filled { '█' } else { '░' }
	}
	return '[${bar}] ${percent}%'
}
