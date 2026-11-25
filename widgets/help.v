module widgets

// Binding associates a key with a short description. Disabled bindings are
// hidden from the help view.
pub struct Binding {
pub:
	key         string
	description string
pub mut:
	enabled bool = true
}

// Help renders a compact keybinding list, or a two-column full view.
pub struct Help {
pub mut:
	bindings []Binding
	width    int
	// full renders two bindings per line instead of one per line.
	full bool
}

// visible returns the enabled bindings.
fn (h Help) visible() []Binding {
	return h.bindings.filter(it.enabled)
}

// short_view renders one binding per line.
fn (h Help) short_view() string {
	vis := h.visible()
	mut key_width := 0
	for b in vis {
		if b.key.len > key_width {
			key_width = b.key.len
		}
	}
	mut out := []string{}
	for b in vis {
		line := pad(b.key, key_width) + '  ' + b.description
		out << if h.width > 0 { truncate(line, h.width) } else { line }
	}
	return out.join('\n')
}

// full_view renders two bindings per line for a denser overview.
fn (h Help) full_view() string {
	vis := h.visible()
	mut cells := []string{}
	mut key_width := 0
	for b in vis {
		if b.key.len > key_width {
			key_width = b.key.len
		}
	}
	for b in vis {
		cells << pad(b.key, key_width) + '  ' + b.description
	}
	mut out := []string{}
	mut i := 0
	for i < cells.len {
		mut line := cells[i]
		if i + 1 < cells.len {
			line += '    ' + cells[i + 1]
		}
		out << if h.width > 0 { truncate(line, h.width) } else { line }
		i += 2
	}
	return out.join('\n')
}

// view renders the bindings.
pub fn (h Help) view() string {
	if h.full {
		return h.full_view()
	}
	return h.short_view()
}
