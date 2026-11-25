module cli

fn dyn_mark_executed() ! {
}

fn dyn_complete(_cmd Command, _words []string) []CompletionItem {
	return [CompletionItem{ value: 'dynamic-one', description: 'first' },
		CompletionItem{ value: 'dynamic-two', description: 'second' }]
}

fn flag_dyn_complete(_cmd Command, _flag Flag) []CompletionItem {
	return [CompletionItem{ value: 'json', description: 'json output' }]
}

fn test_dynamic_command_completion() {
	mut cmd := Command{ name: 'app', complete_fn: dyn_complete }
	cmd.setup()
	assert completion_result(cmd, ['dyn']).contains('dynamic-one')
	assert completion_result(cmd, ['dyn']).contains('dynamic-two')
	assert !completion_result(cmd, ['zzz']).contains('dynamic-one')
}

fn test_dynamic_completion_hint_lines() {
	mut cmd := Command{
		name:        'app'
		complete_fn: fn (c Command, words []string) []CompletionItem {
			return [CompletionItem{ value: 'try --verbose', description: 'tip', hint: true }]
		}
	}
	cmd.setup()
	out := completion_result(cmd, [''])
	assert out.contains(':try --verbose')
}

fn test_flag_choices_completion() {
	mut cmd := Command{
		name:  'app'
		flags: [Flag{ name: 'format', choices: ['json', 'yaml'] }]
	}
	cmd.setup()
	out := completion_result(cmd, ['--format', ''])
	assert out.contains('json')
	assert out.contains('yaml')
	assert completion_result(cmd, ['--format', 'j']).contains('json')
	assert !completion_result(cmd, ['--format', 'j']).contains('yaml')
}

fn test_flag_dynamic_completion() {
	mut cmd := Command{
		name:  'app'
		flags: [Flag{ name: 'format', complete_fn: flag_dyn_complete }]
	}
	cmd.setup()
	assert completion_result(cmd, ['--format', '']).contains('json')
}

fn test_required_flag_marked_in_completion() {
	mut cmd := Command{
		name:  'app'
		flags: [Flag{ name: 'token', description: 'api token', required: true }]
	}
	cmd.setup()
	assert completion_result(cmd, ['--']).contains('(required)')
}

fn test_one_required_flags() {
	mut cmd := Command{
		name:         'app'
		execute_fn:   dyn_mark_executed
		flags:        [Flag{ name: 'a', flag: .bool }, Flag{ name: 'b', flag: .bool }]
		one_required: [['a', 'b']]
	}
	cmd.run(['app', '--a']) or { assert false }
	mut neither := Command{
		name:         'app'
		flags:        [Flag{ name: 'a', flag: .bool }, Flag{ name: 'b', flag: .bool }]
		one_required: [['a', 'b']]
	}
	neither.run(['app']) or {
		assert err.msg().contains('exactly one')
		return
	}
	assert false
}

fn test_one_required_rejects_two() {
	mut cmd := Command{
		name:         'app'
		flags:        [Flag{ name: 'a', flag: .bool }, Flag{ name: 'b', flag: .bool }]
		one_required: [['a', 'b']]
	}
	cmd.run(['app', '--a', '--b']) or {
		assert err.msg().contains('exactly one')
		return
	}
	assert false
}

fn test_suggest_for_aliases() {
	mut root := Command{ name: 'app' }
	root.add_command(Command{ name: 'checkout', suggest_for: ['co', 'check'] })
	assert suggest_command('chek', root.commands).contains('check')
}

fn test_suggest_subcommand_threshold() {
	mut root := Command{ name: 'app', suggest_min_distance: 5 }
	root.add_command(Command{ name: 'checkout' })
	assert root.suggest_subcommand('chekout').contains('checkout')
	mut strict := Command{ name: 'app', suggest_min_distance: 1 }
	strict.add_command(Command{ name: 'checkout' })
	assert strict.suggest_subcommand('chekoutz') == ''
}
