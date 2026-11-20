module widgets

import term

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

fn truncate(s string, width int) string {
	if width <= 0 {
		return ''
	}
	if term.printable_len(s) <= width {
		return s
	}
	if width == 1 {
		return '…'
	}
	mut out := ''
	mut used := 0
	for ch in s.runes() {
		w := term.printable_len(ch.str())
		if used + w > width - 1 {
			break
		}
		out += ch.str()
		used += w
	}
	return out + '…'
}

fn pad(s string, width int) string {
	w := term.printable_len(s)
	if w >= width {
		return s
	}
	return s + repeat(' ', width - w)
}
