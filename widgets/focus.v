module widgets

import termkit

// Focusable is a widget that can own keyboard focus.
pub interface Focusable {
mut:
	update(termkit.Msg)
	view() string
	focus()
	blur()
	is_focused() bool
}

// FocusGroup routes input to one focused widget at a time. Tab and shift+tab
// move focus; any other message is delivered only to the active widget.
pub struct FocusGroup {
pub mut:
	widgets []Focusable
	active  int
}

// new_focus_group creates an empty group.
pub fn new_focus_group() FocusGroup {
	return FocusGroup{ active: -1 }
}

// add appends a widget and focuses it when it is the first one.
pub fn (mut g FocusGroup) add(widget Focusable) {
	mut added := widget
	added.blur()
	g.widgets << added
	if g.active < 0 {
		g.active = 0
		g.widgets[0].focus()
	}
}

// active_widget returns the currently focused widget, if any.
pub fn (mut g FocusGroup) active_widget() ?Focusable {
	if g.active < 0 || g.active >= g.widgets.len {
		return none
	}
	return g.widgets[g.active]
}

fn (mut g FocusGroup) set_active(index int) {
	if g.active >= 0 && g.active < g.widgets.len {
		g.widgets[g.active].blur()
	}
	g.active = index
	if index >= 0 && index < g.widgets.len {
		g.widgets[index].focus()
	}
}

// focus_next moves focus to the following widget.
pub fn (mut g FocusGroup) focus_next() {
	if g.widgets.len == 0 {
		return
	}
	g.set_active((g.active + 1) % g.widgets.len)
}

// focus_prev moves focus to the previous widget.
pub fn (mut g FocusGroup) focus_prev() {
	if g.widgets.len == 0 {
		return
	}
	prev := g.active - 1
	g.set_active(if prev < 0 { g.widgets.len - 1 } else { prev })
}

// focus_index focuses the widget at index.
pub fn (mut g FocusGroup) focus_index(index int) {
	if index >= 0 && index < g.widgets.len {
		g.set_active(index)
	}
}

// update routes a message to the focused widget.
pub fn (mut g FocusGroup) update(msg termkit.Msg) {
	match msg {
		termkit.KeyMsg {
			if msg.kind != .press {
				return
			}
			if msg.key == termkit.key_tab {
				if msg.modifiers.has(.shift) {
					g.focus_prev()
				} else {
					g.focus_next()
				}
				return
			}
		}
		else {}
	}
	if g.active < 0 || g.active >= g.widgets.len {
		return
	}
	g.widgets[g.active].update(msg)
}

// view renders every widget in the group, one per line.
pub fn (mut g FocusGroup) view() string {
	mut out := []string{}
	for i in 0 .. g.widgets.len {
		prefix := if i == g.active { '• ' } else { '  ' }
		out << prefix + g.widgets[i].view().replace('\n', '\n  ')
	}
	return out.join('\n')
}
