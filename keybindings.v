module termkit

import term

// KeyBinding associates a key and modifier set with a command. Disabled
// bindings never resolve and are hidden from help output.
pub struct KeyBinding {
pub:
	key         string
	modifiers   Modifiers
	description string
	cmd         Cmd
pub mut:
	enabled bool = true
}

// Binding is a declarative key binding without a command: one or more key
// names sharing help text. It is the source of truth help views render.
pub struct Binding {
pub:
	keys        []string
	modifiers   Modifiers
	description string
pub mut:
	enabled bool = true
}

// matches reports whether the binding fires for the key event. Disabled
// bindings never match.
pub fn (b Binding) matches(key string, modifiers Modifiers) bool {
	if !b.enabled {
		return false
	}
	return key in b.keys && modifiers == b.modifiers
}

// help_text renders the binding as `ctrl+k, ctrl+j  move`.
pub fn (b Binding) help_text() string {
	mut label := b.keys.join(', ')
	if b.modifiers.has(.ctrl) {
		label = 'ctrl+' + label
	}
	if b.modifiers.has(.shift) {
		label = 'shift+' + label
	}
	if b.modifiers.has(.alt) {
		label = 'alt+' + label
	}
	return '${label}  ${b.description}'
}

// KeyMap is a collection of key bindings.
pub struct KeyMap {
pub mut:
	bindings []KeyBinding
}

// bind adds a binding to the map.
pub fn (mut m KeyMap) bind(key string, modifiers Modifiers, description string, cmd Cmd) {
	m.bindings << KeyBinding{
		key:         key
		modifiers:   modifiers
		description: description
		cmd:         cmd
	}
}

// resolve returns the command for a key and modifier set. Disabled bindings
// never resolve.
pub fn (m KeyMap) resolve(key string, modifiers Modifiers) ?Cmd {
	for b in m.bindings {
		if !b.enabled {
			continue
		}
		if b.key == key && b.modifiers == modifiers {
			return b.cmd
		}
	}
	return none
}

// resolve_msg returns the command bound to a key message.
pub fn (m KeyMap) resolve_msg(msg KeyMsg) ?Cmd {
	return m.resolve(msg.key, msg.modifiers)
}

// unbind removes every binding for a key and modifier set.
pub fn (mut m KeyMap) unbind(key string, modifiers Modifiers) {
	m.bindings = m.bindings.filter(!(it.key == key && it.modifiers == modifiers))
}

// set_enabled enables or disables every binding for a key and modifier set.
pub fn (mut m KeyMap) set_enabled(key string, modifiers Modifiers, enabled bool) {
	for i in 0 .. m.bindings.len {
		if m.bindings[i].key == key && m.bindings[i].modifiers == modifiers {
			m.bindings[i].enabled = enabled
		}
	}
}

// help renders the bindings as a compact list.
pub fn (m KeyMap) help() string {
	return m.help_width(0)
}

// help_width renders enabled bindings, truncating each line to width when
// width is positive.
pub fn (m KeyMap) help_width(width int) string {
	mut out := []string{}
	for b in m.bindings {
		if !b.enabled {
			continue
		}
		mut label := b.key
		if b.modifiers.has(.ctrl) {
			label = 'ctrl+' + label
		}
		if b.modifiers.has(.shift) {
			label = 'shift+' + label
		}
		if b.modifiers.has(.alt) {
			label = 'alt+' + label
		}
		line := '  ${label}  ${b.description}'
		out << if width > 0 { truncate_line(line, width) } else { line }
	}
	return out.join('\n')
}

// truncate_line shortens s to width on rune boundaries, adding an ellipsis.
fn truncate_line(s string, width int) string {
	if width <= 0 || term.printable_len(s) <= width {
		return s
	}
	if width == 1 {
		return '…'
	}
	mut out := ''
	mut used := 0
	for r in s.runes() {
		w := term.printable_len(r.str())
		if used + w > width - 1 {
			break
		}
		out += r.str()
		used += w
	}
	return out + '…'
}
