module cli

// completion_result implements the dynamic `__complete` protocol. Each line is
// `value<TAB>description`, a format all supported shells can consume.
pub fn completion_result(c &Command, args []string) string {
	last := if args.len > 0 { args[args.len - 1] } else { '' }
	mut out := []string{}
	if last.starts_with('-') {
		for f in c.all_flags {
			if f.hidden || f.name == '' {
				continue
			}
			if '--${f.name}'.starts_with(last) {
				out << '--${f.name}\t${f.description}'
			}
		}
		return out.join('\n')
	}
	for sub in c.commands {
		if !sub.hidden && sub.name.starts_with(last) {
			out << '${sub.name}\t${sub.description}'
		}
	}
	return out.join('\n')
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
