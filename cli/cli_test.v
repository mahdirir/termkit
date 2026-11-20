@[has_globals]
module cli

__global (
	test_executed bool
)

fn mark_executed() ! {
	test_executed = true
}

fn test_string_flag() ! {
	mut cmd := Command{
		name:       'app'
		execute_fn: mark_executed
		flags:      [Flag{ name: 'name', abbrev: 'n', description: 'a name' }]
	}
	cmd.run(['app', '--name', 'v'])!
	assert (cmd.flag('name')!.get_string()!) == 'v'
	assert test_executed
}

fn test_bool_and_short_cluster() ! {
	test_executed = false
	mut cmd := Command{
		name:       'app'
		execute_fn: mark_executed
		flags:      [Flag{ name: 'verbose', abbrev: 'v', flag: .bool },
			Flag{ name: 'all', abbrev: 'a', flag: .bool }]
	}
	cmd.run(['app', '-va'])!
	assert cmd.flag('verbose')!.get_bool()!
	assert cmd.flag('all')!.get_bool()!
	assert test_executed
}

fn test_positional_args() ! {
	mut cmd := Command{
		name:      'app'
		args_rule: .exact_one
		flags:     []Flag{}
	}
	cmd.execute_fn = mark_executed
	cmd.run(['app', 'hello'])!
	assert cmd.args == ['hello']
}

fn test_args_rule_error() {
	mut cmd := Command{ name: 'app', args_rule: .exact_one }
	cmd.run(['app']) or {
		return
	}
	assert false
}

fn test_unknown_flag_suggests() {
	mut cmd := Command{ name: 'app', flags: [Flag{ name: 'verbose', flag: .bool }] }
	cmd.run(['app', '--verbos']) or {
		assert err.msg().contains('did you mean')
		return
	}
	assert false
}

fn test_required_flag() {
	mut cmd := Command{ name: 'app', flags: [Flag{ name: 'token', required: true }] }
	cmd.run(['app']) or {
		return
	}
	assert false
}

fn test_subcommand_dispatch() ! {
	test_executed = false
	mut root := Command{ name: 'app' }
	root.add_command(Command{
		name:       'greet'
		aliases:    ['g']
		execute_fn: mark_executed
		flags:      [Flag{ name: 'loud', abbrev: 'l', flag: .bool }]
	})
	root.run(['app', 'g', '-l'])!
	assert test_executed
	assert root.commands[0].flag('loud')!.get_bool()!
}

fn test_help_output() {
	mut cmd := Command{ name: 'app', description: 'demo', version: '1.0' }
	cmd.flags << Flag{ name: 'name', description: 'a name' }
	assert cmd.help_message().contains('--name')
	assert cmd.help_message().contains('demo')
}

fn test_suggestion_distance() {
	assert levenshtein('verbos', 'verbose') == 1
	assert suggest('verbos', ['verbose', 'quiet']).contains('verbose')
	assert suggest('xyz', ['verbose']) == ''
}

fn test_completion_result() {
	mut cmd := Command{ name: 'app' }
	cmd.setup()
	cmd.add_command(Command{ name: 'greet', description: 'say hello' })
	cmd.setup()
	assert completion_result(cmd, ['']).contains('greet')
	assert completion_result(cmd, ['--']).contains('--help')
}

fn test_manpage() {
	mut cmd := Command{ name: 'app', description: 'demo' }
	cmd.flags << Flag{ name: 'name', description: 'a name' }
	page := cmd.manpage()
	assert page.contains('.Nm app')
	assert page.contains('a name')
}

fn test_completion_scripts() {
	for shell in ['bash', 'zsh', 'fish', 'powershell'] {
		assert completion_script('app', shell).len > 0
	}
	assert completion_script('app', 'unknown') == ''
}

fn test_completion_golden() {
	expected := $embed_file('testdata/completion_bash.out').to_string()
	assert completion_script('app', 'bash') == expected
}
