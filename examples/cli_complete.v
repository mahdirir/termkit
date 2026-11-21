@[has_globals]
module main

import os
import termkit.cli

__global (
	trace []string
)

fn before_all() ! {
	trace << 'before'
}

fn after_all() ! {
	trace << 'after'
}

fn serve(cmd cli.Command) ! {
	port := cmd.get_flag('port')!.get_int()!
	println('serving on port ${port}')
}

fn main() {
	if os.args.len > 1 && os.args[1] == '--print-completion' {
		print(cli.completion_script('tool', 'bash'))
		return
	}
	mut root := cli.Command{
		name:              'tool'
		description:       'termkit CLI with completions and hooks'
		version:           '0.1.0'
		persistent_before: before_all
		persistent_after:  after_all
		flags:             [cli.Flag{ name: 'verbose', abbrev: 'v', description: 'verbose output', flag: .bool }]
	}
	root.add_command(cli.Command{
		name:            'serve'
		description:     'start the server'
		aliases:         ['run']
		execute_with_fn: serve
		flags:           [cli.Flag{
			name:          'port'
			abbrev:        'p'
			description:   'listen port'
			flag:          .int
			default_value: ['8080']
		}]
	})
	root.run(os.args)!
	for event in trace {
		println('hook: ${event}')
	}
}
