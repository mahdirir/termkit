@[has_globals]
module cli

__global (
	m12_order    []string
	m12_output   string
	m12_executed bool
)

fn m12_capture(s string) {
	m12_output += s
}

fn m12_pre_root(c Command) ! {
	m12_order << 'root_pre'
}

fn m12_post_root(c Command) ! {
	m12_order << 'root_post'
}

fn m12_pre_sub(c Command) ! {
	m12_order << 'sub_pre'
}

fn m12_post_sub(c Command) ! {
	m12_order << 'sub_post'
}

fn m12_fail(c Command) ! {
	return error('hook stopped')
}

fn m12_mark() ! {
	m12_executed = true
}

fn m12_dash(s string) string {
	return s.replace('-', '_')
}

fn test_persistent_with_fn_order() {
	m12_order = []string{}
	mut root := Command{
		name:                      'app'
		persistent_before_with_fn: m12_pre_root
		persistent_after_with_fn:  m12_post_root
		commands:                  [Command{
			name:                      'sub'
			execute_with_fn:           fn (c Command) ! {}
			persistent_before_with_fn: m12_pre_sub
			persistent_after_with_fn:  m12_post_sub
		}]
	}
	root.run(['app', 'sub'])!
	assert m12_order == ['root_pre', 'sub_pre', 'sub_post', 'root_post']
}

fn test_persistent_with_fn_error_aborts() {
	mut root := Command{
		name:                      'app'
		persistent_before_with_fn: m12_fail
		commands:                  [Command{
			name:            'sub'
			execute_with_fn: fn (c Command) ! {}
		}]
	}
	root.run(['app', 'sub']) or {
		assert err.msg().contains('hook stopped')
		return
	}
	assert false
}

fn test_count_flags() ! {
	mut cmd := Command{
		name:       'app'
		execute_fn: m12_mark
		flags:      [Flag{ name: 'verbose', abbrev: 'v', flag: .count }]
	}
	cmd.run(['app', '-vvv'])!
	assert cmd.flag('verbose')!.get_count()! == 3
	mut single := Command{
		name:       'app'
		execute_fn: m12_mark
		flags:      [Flag{ name: 'verbose', flag: .count }]
	}
	single.run(['app', '--verbose', '--verbose'])!
	assert single.flag('verbose')!.get_count()! == 2
	bad := Flag{ name: 'x', flag: .bool }
	bad.get_count() or {
		return
	}
	assert false
}

fn test_no_opt_default() ! {
	mut cmd := Command{
		name:       'app'
		execute_fn: m12_mark
		flags:      [Flag{ name: 'level', no_opt_default: '1' }]
	}
	cmd.run(['app', '--level'])!
	assert cmd.flag('level')!.get_string()! == '1'
	mut explicit := Command{
		name:       'app'
		execute_fn: m12_mark
		flags:      [Flag{ name: 'level', no_opt_default: '1' }]
	}
	explicit.run(['app', '--level', '3'])!
	assert explicit.flag('level')!.get_string()! == '3'
	mut with_eq := Command{
		name:       'app'
		execute_fn: m12_mark
		flags:      [Flag{ name: 'level', no_opt_default: '1' }]
	}
	with_eq.run(['app', '--level=5'])!
	assert with_eq.flag('level')!.get_string()! == '5'
}

fn test_flag_normalization() ! {
	mut cmd := Command{
		name:         'app'
		execute_fn:   m12_mark
		normalize_fn: m12_dash
		flags:        [Flag{ name: 'log_level' }]
	}
	cmd.run(['app', '--log-level', 'debug'])!
	assert cmd.flag('log_level')!.get_string()! == 'debug'
}

fn test_equals_in_value_preserved() ! {
	mut cmd := Command{
		name:       'app'
		execute_fn: m12_mark
		flags:      [Flag{ name: 'pair' }]
	}
	cmd.run(['app', '--pair=a=b'])!
	assert cmd.flag('pair')!.get_string()! == 'a=b'
}

fn test_traverse_children() ! {
	m12_executed = false
	mut root := Command{
		name:              'app'
		traverse_children: true
		commands:          [Command{
			name:            'sub'
			execute_with_fn: fn (c Command) ! {
				m12_executed = c.get_flag('mode')!.get_string() or { '' } == 'fast'
			}
			flags:           [Flag{ name: 'mode' }]
		}]
	}
	root.flags << Flag{ name: 'top' }
	root.run(['app', 'sub', '--top', '1', '--mode', 'fast'])!
	assert m12_executed
}

fn test_disable_flag_parsing() ! {
	mut cmd := Command{
		name:                 'app'
		args_rule:            .any
		execute_fn:           m12_mark
		disable_flag_parsing: true
		commands:             [Command{ name: 'sub', execute_fn: m12_mark }]
	}
	cmd.run(['app', '--weird', 'x'])!
	assert cmd.args == ['--weird', 'x']
}

fn test_non_interspersed() ! {
	mut cmd := Command{
		name:         'app'
		args_rule:    .any
		execute_fn:   m12_mark
		interspersed: false
		flags:        [Flag{ name: 'a', flag: .bool }]
	}
	cmd.run(['app', 'pos', '--a'])!
	assert cmd.args == ['pos', '--a']
	assert !cmd.flag('a')!.get_bool()!
}

fn test_markdown_and_yaml_docs() {
	mut cmd := Command{
		name:        'app'
		description: 'demo'
		version:     '1.0'
		usage:       'app [flags]'
		examples:    ['app --name v']
		flags:       [Flag{ name: 'name', abbrev: 'n', description: 'a name', required: true }]
	}
	md := cmd.markdown()
	assert md.contains('# app')
	assert md.contains('| `--name`, `-n` |')
	assert md.contains('(required)')
	yml := cmd.to_yaml()
	assert yml.contains('name: app')
	assert yml.contains('required: true')
	assert yml.contains('abbrev: n')
}

fn test_help_fn_override() {
	mut cmd := Command{
		name:    'app'
		help_fn: fn (c &Command) string {
			return 'custom help for ${c.name}\n'
		}
	}
	assert cmd.help_message() == 'custom help for app\n'
}

fn test_version_template() {
	mut cmd := Command{
		name:             'tool'
		version:          '2.0'
		version_template: '{{name}}-{{version}}'
		out:              m12_capture
	}
	m12_output = ''
	cmd.run(['tool', '--version'])!
	assert m12_output == 'tool-2.0\n'
	mut plain := Command{ name: 'tool', version: '2.0' }
	assert plain.version_line() == 'tool version 2.0\n'
}
