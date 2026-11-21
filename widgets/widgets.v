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

// rune_len returns the number of runes in s.
fn rune_len(s string) int {
	mut n := 0
	for _ in s.runes() {
		n++
	}
	return n
}

// rune_prefix returns the first n runes of s as a string.
fn rune_prefix(s string, n int) string {
	mut out := ''
	mut i := 0
	for r in s.runes() {
		if i >= n {
			break
		}
		out += r.str()
		i++
	}
	return out
}

// rune_at returns the nth rune of s as a string, or '' when out of range.
fn rune_at(s string, n int) string {
	mut i := 0
	for r in s.runes() {
		if i == n {
			return r.str()
		}
		i++
	}
	return ''
}

fn pad(s string, width int) string {
	w := term.printable_len(s)
	if w >= width {
		return s
	}
	return s + repeat(' ', width - w)
}
