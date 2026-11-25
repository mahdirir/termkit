module cli

// CompletionDirective controls how a shell treats a completion item.
// Built-in scripts pass value and description through; custom consumers of
// the `__complete` protocol can honor the directive.
pub enum CompletionDirective {
	none
	no_space
	no_file_comp
	filter_ext
	filter_dirs
	keep_order
}

// CompletionItem is one dynamic completion result.
pub struct CompletionItem {
pub:
	value       string
	description string
	// hint marks ActiveHelp-style annotation lines. They are shown by
	// consumers but never completed; lines are emitted with a `:` prefix.
	hint      bool
	directive CompletionDirective = .none
}

// line renders the item in `value<TAB>description` protocol form.
pub fn (item CompletionItem) line() string {
	if item.hint {
		return ':${item.value}\t${item.description}'
	}
	return '${item.value}\t${item.description}'
}

// completion_result implements the dynamic `__complete` protocol. Each line is
// `value<TAB>description`, a format all supported shells can consume. Hint
// items use a `:` prefix and are display-only.
pub fn completion_result(c &Command, args []string) string {
	last := if args.len > 0 { args[args.len - 1] } else { '' }
	remaining := if args.len > 1 { args[..args.len - 1] } else { []string{} }
	return completion_for(c, remaining, last).join('\n')
}

fn completion_for(c &Command, remaining []string, last string) []string {
	if remaining.len > 0 {
		idx := c.find_sub(remaining[0])
		if idx >= 0 {
			return completion_for(&c.commands[idx], remaining[1..], last)
		}
		// A value-taking flag consumes the next word: complete its values.
		flag_name, is_value_pos := flag_value_position(c, remaining)
		if is_value_pos {
			return complete_flag_values(c, flag_name, last)
		}
	}
	mut out := []string{}
	if last.starts_with('-') {
		for f in c.all_flags {
			if f.hidden || f.name == '' {
				continue
			}
			if '--${f.name}'.starts_with(last) {
				out << flag_completion_line(f)
			}
		}
	} else {
		for sub in c.commands {
			if !sub.hidden && sub.name.starts_with(last) {
				out << '${sub.name}\t${sub.description}'
			}
		}
	}
	out << dynamic_completion_lines(c, remaining, last)
	return out
}

// flag_value_position reports whether the word being completed is the value
// of a value-taking flag named in remaining.
fn flag_value_position(c &Command, remaining []string) (string, bool) {
	if remaining.len == 0 {
		return '', false
	}
	prev := remaining[remaining.len - 1]
	if !prev.starts_with('--') || prev.contains('=') {
		return '', false
	}
	name := prev[2..]
	for f in c.all_flags {
		if f.name == name && f.flag != .bool {
			return name, true
		}
	}
	return '', false
}

// complete_flag_values completes static choices and dynamic items for the
// value of flag name.
fn complete_flag_values(c &Command, name string, last string) []string {
	mut out := []string{}
	for f in c.all_flags {
		if f.name != name {
			continue
		}
		for choice in f.choices {
			if choice.starts_with(last) {
				out << '${choice}\t'
			}
		}
		if complete := f.complete_fn {
			for item in complete(*c, f) {
				if item.value.starts_with(last) {
					out << item.line()
				}
			}
		}
	}
	return out
}

// dynamic_completion_lines runs the command's complete_fn and filters items
// by the current prefix.
fn dynamic_completion_lines(c &Command, remaining []string, last string) []string {
	mut out := []string{}
	if complete := c.complete_fn {
		mut words := remaining.clone()
		words << last
		for item in complete(*c, words) {
			if item.hint || item.value.starts_with(last.trim_left('-')) {
				out << item.line()
			}
		}
	}
	return out
}

// flag_completion_line renders a flag, marking required flags.
fn flag_completion_line(f Flag) string {
	desc := if f.required { '${f.description} (required)' } else { f.description }
	return '--${f.name}\t${desc}'
}

// completion_script returns a shell completion script for name. Shell
// metacharacters are written as `~` in the templates and substituted at
// runtime so V does not try to interpolate them.
pub fn completion_script(name string, shell string) string {
	script := match shell {
		'bash' { bash_script() }
		'zsh' { zsh_script() }
		'fish' { fish_script() }
		'powershell' { powershell_script() }
		else { return '' }
	}
	return script.replace('~', '$').replace('NAME', name)
}

fn bash_script() string {
	lines := [
		'_NAME_complete() {',
		'  local cur="~{COMP_WORDS[COMP_CWORD]}"',
		'  local out',
		'  out=~("~{COMP_WORDS[0]}" __complete "~{COMP_WORDS[@]:1:~COMP_CWORD}")',
		'  COMPREPLY=(~(compgen -W "~(printf "%s\\n" "~out" | cut -f1)" -- "~cur"))',
		'}',
		'complete -F _NAME_complete NAME',
	]
	return lines.join('\n') + '\n'
}

fn zsh_script() string {
	lines := [
		'#compdef NAME',
		'_NAME_complete() {',
		'  local -a completions',
		'  completions=("~{(@f)~("~{words[1]}" __complete "~{words[@]:2}")}")',
		'  _describe "commands" completions',
		'}',
		'compdef _NAME_complete NAME',
	]
	return lines.join('\n') + '\n'
}

fn fish_script() string {
	lines := [
		'complete -c NAME -f',
		'complete -c NAME -a "(NAME __complete (commandline -opc)[2..-1])"',
	]
	return lines.join('\n') + '\n'
}

fn powershell_script() string {
	lines := [
		'Register-ArgumentCompleter -Native -CommandName NAME -ScriptBlock {',
		'  param(~wordToComplete, ~commandAst, ~cursorPosition)',
		'  & NAME __complete @(~commandAst.CommandElements | Select-Object -Skip 1) |',
		'    ForEach-Object { [System.Management.Automation.CompletionResult]::new(~_, ~_, "ParameterValue", ~_) }',
		'}',
	]
	return lines.join('\n') + '\n'
}
