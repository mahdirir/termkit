module widgets

// Binding associates a key with a short description.
pub struct Binding {
pub:
	key         string
	description string
}

// Help renders a compact two-column keybinding list.
pub struct Help {
pub mut:
	bindings []Binding
	width    int
}

// view renders the bindings.
pub fn (h Help) view() string {
	mut key_width := 0
	for b in h.bindings {
		if b.key.len > key_width {
			key_width = b.key.len
		}
	}
	mut out := []string{}
	for b in h.bindings {
		line := pad(b.key, key_width) + '  ' + b.description
		out << if h.width > 0 { truncate(line, h.width) } else { line }
	}
	return out.join('\n')
}
