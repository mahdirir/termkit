module main

import os
import termkit.cli

fn greet() ! {
	println('Hello!')
}

fn main() {
	mut root := cli.Command{
		name:        'demo'
		description: 'a small termkit CLI demo'
		version:     '0.1.0'
		flags:       [cli.Flag{ name: 'name', abbrev: 'n', description: 'who to greet' }]
	}
	root.add_command(cli.Command{
		name:        'greet'
		description: 'say hello'
		execute_fn:  greet
		flags:       [cli.Flag{ name: 'loud', abbrev: 'l', description: 'shout', flag: .bool }]
	})
	root.run(os.args)!
}
