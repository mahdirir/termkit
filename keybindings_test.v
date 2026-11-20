module termkit

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
