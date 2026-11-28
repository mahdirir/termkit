module termkit

import term.ui as tui

fn test_keymap_resolves_terminal_arrow_event() {
	mut km := KeyMap{}
	km.bind(key_down, unsafe { Modifiers(0) }, 'next', no_cmd)
	msg := msg_from_event(&tui.Event{ typ: .key_down, code: .down, utf8: '\x00' }) as KeyMsg
	assert km.resolve_msg(msg) != none
}

fn test_keymap_resolve() {
	mut km := KeyMap{}
	km.bind('q', unsafe { Modifiers(0) }, 'quit', quit())
	mut ctrl := unsafe { Modifiers(0) }
	ctrl |= .ctrl
	km.bind('c', ctrl, 'copy', msg_cmd(QuitMsg{}))
	if cmd := km.resolve('q', unsafe { Modifiers(0) }) {
		assert delivered_msgs(cmd).len == 1
	} else {
		assert false
	}
	assert km.resolve('x', unsafe { Modifiers(0) }) == none
}

fn test_keymap_help() {
	mut km := KeyMap{}
	km.bind('q', unsafe { Modifiers(0) }, 'quit', no_cmd)
	assert km.help().contains('quit')
}

fn test_binding_matches() {
	no_mod := unsafe { Modifiers(0) }
	mut ctrl := unsafe { Modifiers(0) }
	ctrl |= .ctrl
	b := Binding{ keys: ['k', 'j'], modifiers: ctrl, description: 'move' }
	assert b.matches('k', ctrl)
	assert b.matches('j', ctrl)
	assert !b.matches('x', ctrl)
	assert !b.matches('k', no_mod)
	assert b.help_text().contains('move')
	assert b.help_text().contains('ctrl+')
}

fn test_binding_disabled_never_matches() {
	no_mod := unsafe { Modifiers(0) }
	mut b := Binding{ keys: ['q'], modifiers: no_mod, description: 'quit' }
	assert b.matches('q', no_mod)
	b.enabled = false
	assert !b.matches('q', no_mod)
}

fn test_keymap_enable_disable_unbind() {
	no_mod := unsafe { Modifiers(0) }
	mut km := KeyMap{}
	km.bind('q', no_mod, 'quit', quit())
	assert km.resolve('q', no_mod) != none
	km.set_enabled('q', no_mod, false)
	assert km.resolve('q', no_mod) == none
	assert !km.help().contains('quit')
	km.set_enabled('q', no_mod, true)
	assert km.resolve('q', no_mod) != none
	km.unbind('q', no_mod)
	assert km.resolve('q', no_mod) == none
}

fn test_keymap_help_width_truncates() {
	no_mod := unsafe { Modifiers(0) }
	mut km := KeyMap{}
	km.bind('q', no_mod, 'quit the program now', no_cmd)
	full := km.help()
	assert full.contains('quit the program now')
	short := km.help_width(10)
	assert short.len < full.len
	assert short.contains('…')
}
