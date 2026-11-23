module main

import os
import termkit.cli

fn root_before() ! {
	println('[hook] root:before')
}

fn root_after() ! {
	println('[hook] root:after')
}

fn project_before() ! {
	println('[hook] project:before')
}

fn project_after() ! {
	println('[hook] project:after')
}

fn project_list(c cli.Command) ! {
	format := c.get_flag('format')!.get_string()!
	limit := c.get_flag('limit')!.get_int()!
	as_json := c.get_flag('json')!.get_bool()!
	long_mode := c.get_flag('long')!.get_bool()!
	println('project list: format=${format}, limit=${limit}, json=${as_json}, long=${long_mode}')
	for arg in c.args {
		println('  arg: ${arg}')
	}
}

fn project_add(c cli.Command) ! {
	name := c.get_flag('name')!.get_string()!
	priority := c.get_flag('priority')!.get_int()!
	println('project add: name=${name}, priority=${priority}')
}

fn serve(c cli.Command) ! {
	port := c.get_flag('port')!.get_int()!
	host := c.get_flag('host')!.get_string()!
	mode := c.get_flag('mode')!.get_string()!
	ratio := c.get_flag('ratio')!.get_float()!
	detach := c.get_flag('detach')!.get_bool()!
	foreground := c.get_flag('foreground')!.get_bool()!
	println('serve: ${host}:${port}, mode=${mode}, ratio=${ratio}, detach=${detach}, foreground=${foreground}')
}

fn main() {
	if os.args.len > 1 && os.args[1] == '--print-completion' {
		print(cli.completion_script('tool', 'bash'))
		return
	}

	// Nested subcommands with their own persistent hooks and aliases.
	mut project := cli.Command{
		name:              'project'
		aliases:           ['p', 'proj']
		description:       'manage projects'
		persistent_before: project_before
		persistent_after:  project_after
	}
	project.add_command(cli.Command{
		name:               'list'
		aliases:            ['ls']
		description:        'list projects'
		execute_with_fn:    project_list
		args_rule:          .any
		flags:              [
			cli.Flag{
				name:          'format'
				abbrev:        'f'
				description:   'output format'
				flag:          .string
				choices:       ['table', 'json', 'plain']
				default_value: ['table']
			},
			cli.Flag{
				name:          'limit'
				abbrev:        'n'
				description:   'max rows'
				flag:          .int
				default_value: ['20']
			},
			cli.Flag{ name: 'json', abbrev: 'j', description: 'JSON output', flag: .bool },
			cli.Flag{ name: 'long', abbrev: 'l', description: 'long output', flag: .bool },
		]
		mutually_exclusive: [['json', 'long']]
	})
	project.add_command(cli.Command{
		name:            'add'
		aliases:         ['new']
		description:     'add a project'
		execute_with_fn: project_add
		flags:           [
			cli.Flag{ name: 'name', abbrev: 'n', description: 'project name', required: true },
			cli.Flag{
				name:          'priority'
				abbrev:        'p'
				description:   'priority 1-5'
				flag:          .int
				default_value: ['3']
			},
		]
	})

	mut root := cli.Command{
		name:              'tool'
		description:       'termkit CLI demo: nested commands, typed flags and completion'
		version:           '1.2.0'
		persistent_before: root_before
		persistent_after:  root_after
		flags:             [
			cli.Flag{
				name:        'verbose'
				abbrev:      'v'
				description: 'verbose output'
				flag:        .bool
				global:      true
			},
			cli.Flag{
				name:          'config'
				abbrev:        'c'
				description:   'config file'
				default_value: ['tool.toml']
				global:        true
			},
		]
	}
	root.add_command(project)
	root.add_command(cli.Command{
		name:               'serve'
		aliases:            ['run', 's']
		description:        'start the server'
		execute_with_fn:    serve
		flags:              [
			cli.Flag{
				name:          'port'
				abbrev:        'p'
				description:   'listen port'
				flag:          .int
				default_value: ['8080']
			},
			cli.Flag{ name: 'host', description: 'bind address', default_value: ['127.0.0.1'] },
			cli.Flag{
				name:          'mode'
				description:   'server mode'
				flag:          .string
				choices:       ['dev', 'prod']
				default_value: ['dev']
			},
			cli.Flag{
				name:          'ratio'
				description:   'sample ratio'
				flag:          .float
				default_value: ['0.5']
			},
			cli.Flag{ name: 'detach', abbrev: 'd', description: 'run in background', flag: .bool },
			cli.Flag{ name: 'foreground', abbrev: 'f', description: 'run in foreground', flag: .bool },
		]
		mutually_exclusive: [['detach', 'foreground']]
	})

	// root.run handles the built-in __complete protocol; the tree above is
	// intentionally named/described so shells get useful completions.
	root.run(os.args)!
}
