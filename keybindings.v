module termkit

// KeyBinding associates a key and modifier set with a command.
pub struct KeyBinding {
pub:
	key         string
	modifiers   Modifiers
	description string
	cmd         Cmd
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

// resolve returns the command for a key and modifier set.
pub fn (m KeyMap) resolve(key string, modifiers Modifiers) ?Cmd {
	for b in m.bindings {
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

// help renders the bindings as a compact list.
pub fn (m KeyMap) help() string {
	mut out := []string{}
	for b in m.bindings {
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
		out << '  ${label}  ${b.description}'
	}
	return out.join('\n')
}
