@[has_globals]
module cli

__global (
	test_executed   bool
	test_flag_value string
	test_output     string
	test_hook_order []string
)

fn root_pre() ! {
	test_hook_order << 'root_pre'
}

fn sub_pre() ! {
	test_hook_order << 'sub_pre'
}

fn root_post() ! {
	test_hook_order << 'root_post'
}

fn sub_post() ! {
	test_hook_order << 'sub_post'
}

fn sub_execute() ! {
	test_hook_order << 'execute'
}

fn mark_executed() ! {
	test_executed = true
}

fn capture_output(s string) {
	test_output += s
}

fn test_persistent_parent_hooks() ! {
	test_hook_order = []string{}
	mut root := Command{
		name:              'app'
		persistent_before: root_pre
		persistent_after:  root_post
		commands:          [Command{
			name:              'sub'
			execute_fn:        sub_execute
			persistent_before: sub_pre
			persistent_after:  sub_post
		}]
	}
	root.run(['app', 'sub'])!
	assert test_hook_order == ['root_pre', 'sub_pre', 'execute', 'sub_post', 'root_post']
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

fn test_short_cluster_with_value() ! {
	mut cmd := Command{
		name:       'app'
		execute_fn: mark_executed
		flags:      [Flag{ name: 'all', abbrev: 'a', flag: .bool }, Flag{ name: 'name', abbrev: 'n' }]
	}
	cmd.run(['app', '-an', 'v'])!
	assert cmd.flag('all')!.get_bool()!
	assert cmd.flag('name')!.get_string()! == 'v'

	mut attached := Command{
		name:       'app'
		execute_fn: mark_executed
		flags:      [Flag{ name: 'all', abbrev: 'a', flag: .bool }, Flag{ name: 'name', abbrev: 'n' }]
	}
	attached.run(['app', '-anvalue'])!
	assert attached.flag('all')!.get_bool()!
	assert attached.flag('name')!.get_string()! == 'value'
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

fn uppercase_value(s string) !string {
	return s.to_upper()
}

fn test_negatable_bool() ! {
	mut cmd := Command{
		name:       'app'
		execute_fn: mark_executed
		flags:      [Flag{ name: 'color', flag: .bool, negatable: true }]
	}
	cmd.run(['app', '--no-color'])!
	assert cmd.flag('color')!.get_bool()! == false
}

fn test_flag_validator() ! {
	mut cmd := Command{
		name:       'app'
		execute_fn: mark_executed
		flags:      [Flag{ name: 'name', validate: uppercase_value }]
	}
	cmd.run(['app', '--name', 'v'])!
	assert (cmd.flag('name')!.get_string()!) == 'V'
}

fn test_flag_validator_error() {
	mut cmd := Command{
		name:  'app'
		flags: [Flag{ name: 'name', validate: fn (s string) !string { return error('bad value') } }]
	}
	cmd.run(['app', '--name', 'v']) or {
		assert err.msg().contains('bad value')
		return
	}
	assert false
}

fn test_mutually_exclusive_flags() {
	mut cmd := Command{
		name:               'app'
		flags:              [Flag{ name: 'a', flag: .bool }, Flag{ name: 'b', flag: .bool }]
		mutually_exclusive: [['a', 'b']]
	}
	cmd.run(['app', '--a', '--b']) or {
		assert err.msg().contains('mutually exclusive')
		return
	}
	assert false
}

fn test_required_together_flags() {
	mut cmd := Command{
		name:              'app'
		flags:             [Flag{ name: 'user', flag: .bool }, Flag{ name: 'token', flag: .bool }]
		required_together: [['user', 'token']]
	}
	cmd.run(['app', '--user']) or {
		assert err.msg().contains('required together')
		return
	}
	assert false
}

fn test_hook_receives_parsed_command() ! {
	mut cmd := Command{ name: 'app', flags: [Flag{ name: 'name' }] }
	cmd.execute_with_fn = fn (c Command) ! {
		test_flag_value = c.get_flag('name')!.get_string() or { '' }
	}
	cmd.run(['app', '--name', 'v'])!
	assert test_flag_value == 'v'
}

fn test_injectable_help_output() {
	test_output = ''
	mut cmd := Command{ name: 'app', description: 'demo', out: capture_output }
	cmd.run(['app', '--help'])!
	assert test_output.contains('demo')
}

fn int_parse_fails(f Flag) bool {
	f.get_int() or { return true }
	return false
}

fn float_parse_fails(f Flag) bool {
	f.get_float() or { return true }
	return false
}

fn test_typed_flags_reject_bad_values() {
	mut bad_int := Flag{ name: 'count', flag: .int, value: ['oops'] }
	assert int_parse_fails(bad_int)
	mut bad_float := Flag{ name: 'ratio', flag: .float, value: ['abc'] }
	assert float_parse_fails(bad_float)
	mut good_ints := Flag{ name: 'ids', flag: .int_array, value: ['1', '2'] }
	assert good_ints.get_ints() or { []int{} } == [1, 2]
	mut good_floats := Flag{ name: 'xs', flag: .float_array, value: ['1.5', '2.5'] }
	assert good_floats.get_floats() or { []f64{} } == [1.5, 2.5]
}

fn test_silence_usage() {
	test_output = ''
	mut cmd := Command{
		name:          'app'
		out:           capture_output
		silence_usage: true
	}
	cmd.add_command(Command{ name: 'sub' })
	cmd.run(['app'])!
	assert test_output == ''
}

fn test_unknown_command_suggestion() {
	mut root := Command{ name: 'app' }
	root.add_command(Command{ name: 'greet', aliases: ['g'] })
	root.run(['app', 'greetx']) or {
		assert err.msg().contains('greet')
		return
	}
	assert false
}

fn test_nested_completion() {
	mut root := Command{ name: 'app' }
	root.add_command(Command{
		name:  'issue'
		flags: [Flag{ name: 'label', description: 'filter by label' }]
	})
	root.setup()
	result := completion_result(root, ['issue', '--'])
	assert result.contains('--label')
}

fn test_deprecated_flag_warning() ! {
	test_output = ''
	mut cmd := Command{
		name:       'app'
		out:        capture_output
		err_out:    capture_output
		execute_fn: mark_executed
		flags:      [Flag{ name: 'old', flag: .bool, deprecated: 'use --new' }]
	}
	cmd.run(['app', '--old'])!
	assert test_output.contains('deprecated')
	assert test_output.contains('use --new')
}

fn test_manpage() {
	mut cmd := Command{ name: 'app', description: 'demo' }
	cmd.flags << Flag{ name: 'name', description: 'a name' }
	page := cmd.manpage()
	assert page.contains('.Nm app')
	assert page.contains('a name')
	assert page.contains('.Bl -tag')
	assert page.contains('.El')
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
