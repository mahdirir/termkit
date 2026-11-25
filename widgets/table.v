module widgets

import termkit
import termkit.style

// Table renders rows of cells with a selectable row.
pub struct Table {
pub mut:
	headers  []string
	rows     [][]string
	widths   []int
	selected int
	// offset is the first visible row when height limits the view.
	offset int
	height int
	// header_style styles the header row. The zero style renders plainly.
	header_style style.Style
	// style_fn returns the style for a body cell. A zero style renders
	// the cell plainly. May be nil.
	style_fn ?fn (row int, col int) style.Style
}

fn (t &Table) measure() []int {
	mut widths := []int{len: t.headers.len}
	for i, header in t.headers {
		widths[i] = term_visible(header)
	}
	for row in t.rows {
		for i in 0 .. row.len {
			if i < widths.len {
				w := term_visible(row[i])
				if w > widths[i] {
					widths[i] = w
				}
			}
		}
	}
	return widths
}

fn term_visible(s string) int {
	mut n := 0
	for _ in s.runes() {
		n++
	}
	return n
}

// set_data replaces the table contents.
pub fn (mut t Table) set_data(headers []string, rows [][]string) {
	t.headers = headers
	t.rows = rows
	t.widths = t.measure()
	t.selected = 0
	t.offset = 0
}

// update moves the selection.
pub fn (mut t Table) update(msg termkit.Msg) {
	match msg {
		termkit.KeyMsg {
			if msg.kind != .press {
				return
			}
			match msg.key {
				termkit.key_up {
					if t.selected > 0 {
						t.selected--
					}
				}
				termkit.key_down {
					if t.selected < t.rows.len - 1 {
						t.selected++
					}
				}
				else {}
			}
			t.clamp_offset()
		}
		else {}
	}
}

fn (mut t Table) clamp_offset() {
	if t.height <= 0 {
		t.offset = 0
		return
	}
	if t.offset < 0 {
		t.offset = 0
	}
	if t.selected < t.offset {
		t.offset = t.selected
	}
	if t.selected >= t.offset + t.height {
		t.offset = t.selected - t.height + 1
	}
	max_offset := t.rows.len - t.height
	if max_offset >= 0 && t.offset > max_offset {
		t.offset = max_offset
	}
}

fn render_row(cells []string, widths []int, marker string, row int, style_fn ?fn (int, int) style.Style) string {
	mut out := marker
	for i, cell in cells {
		if i > 0 {
			out += '  '
		}
		w := if i < widths.len { widths[i] } else { 0 }
		mut text := pad(cell, w)
		if f := style_fn {
			st := f(row, i)
			if st != style.Style{} {
				text = st.apply(text)
			}
		}
		out += text
	}
	return out
}

// view renders the header and visible rows.
pub fn (t Table) view() string {
	mut header_cells := []string{}
	for i, h in t.headers {
		w := if i < t.widths.len { t.widths[i] } else { 0 }
		mut text := pad(h, w)
		if t.header_style != style.Style{} {
			text = t.header_style.apply(text)
		}
		header_cells << text
	}
	mut out := ['  ' + header_cells.join('  ')]
	mut end := t.rows.len
	if t.height > 0 && end > t.offset + t.height {
		end = t.offset + t.height
	}
	for i in t.offset .. end {
		marker := if i == t.selected { '> ' } else { '  ' }
		out << render_row(t.rows[i], t.widths, marker, i, t.style_fn)
	}
	return out.join('\n')
}
