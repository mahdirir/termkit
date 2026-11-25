# CLI guide

`termkit.cli` is a command framework with typed flags, generated
help and shell completion. Errors are returned rather than printed directly.

Import it as `import termkit.cli`. A `Command` tree is built by constructing
commands, calling `add_command` / `add_flag`, then `root.run(os.args)!`.
`run` expects the program name in `args[0]`.

```v ignore
module main

import os
import termkit.cli

fn main() {
	mut root := cli.Command{
		name:        'demo'
		description: 'a small demo'
		version:     '0.1.0'
	}
	root.add_command(cli.Command{
		name:        'greet'
		description: 'greet someone'
		args_rule:   .at_least_one
		flags:       [cli.Flag{ name: 'loud', abbrev: 'l', flag: .bool }]
		execute_fn:  fn () ! { println('hello!') }
	})
	root.run(os.args)!
}
```

## Subcommands and aliases

Each `Command` may have `commands` (add with `add_command`) and `aliases`.
`get_flag` finds a flag on the command or any ancestor, which makes global
flags (`global: true`) readable from leaf commands. `full_name()` returns the
space-separated path, used in error messages and help.

## Typed flags

`FlagType` is one of `.bool`, `.int`, `.float`, `.string`, `.int_array`,
`.float_array` or `.string_array`; the default is `.string`. Read values with
the matching getter:

| Getter | Flag type |
| --- | --- |
| `get_bool()` | `.bool` |
| `get_string()` | `.string` |
| `get_int()` | `.int` |
| `get_ints()` | `.int_array` |
| `get_float()` / `get_floats()` | `.float` / `.float_array` |
| `get_strings()` | `.string_array` |

Getters return errors for the wrong flag type or malformed input.
`is_found()` reports whether the flag appeared on the command line; getters
otherwise fall back to `default_value`. Callbacks that need flags should use
`execute_with_fn`, which receives the parsed `Command`:

```v ignore
fn serve(cmd cli.Command) ! {
	port := cmd.get_flag('port')!.get_int()!
	println('serving on port ${port}')
}

mut root := cli.Command{ name: 'tool' }
root.add_command(cli.Command{
	name:            'serve'
	aliases:         ['run']
	execute_with_fn: serve
	flags:           [cli.Flag{
		name:          'port'
		abbrev:        'p'
		flag:          .int
		default_value: ['8080']
	}]
})
```

Long flags accept `--name value` and `--name=value`. Short flags accept
`-n value` and `-n=value`; clustered shorts such as `-abc` are split into
`-a -b -c`, with a value-taking flag consuming the rest of the token or the
next argument. A bare `--` terminates flag parsing: everything after it is a
positional argument, even if it starts with `-`.

## Validation

The parser enforces:

- `required: true` flags — `flag X is required by COMMAND`.
- `choices: [...]`, or a `validate: fn (string) !string` callback that can
  transform or reject a value.
- `negatable: true` on a bool flag accepts `--no-<name>` to set it false;
  explicit `--flag=false` also works.
- `mutually_exclusive` and `required_together`, each a list of flag-name
  groups.
- `args_rule`: `.any` (default), `.none`, `.exact_one`, `.exact_two` or
  `.at_least_one`.

`hidden` removes a command/flag from help and completion, and `deprecated` (a
message string) emits a warning while still accepting the flag.

## Hooks

For a leaf command the order is: `init_fn` (once, in `run`), then
`persistent_before` hooks from the root down to the leaf, then `before`, then
the executor (`execute_fn` or `execute_with_fn`), then `after`, then
`persistent_after` hooks from the leaf back up to the root. The
`*_with_fn` variants (`before_with_fn`, `execute_with_fn`, `after_with_fn`)
receive the command and take precedence over the plain hooks.

All hooks have the signature `fn () !` or `fn (Command) !`. Set `out` and
`err_out` on a command to capture generated output in tests; by default help
goes to stdout and errors to stderr. `silence_usage` suppresses generated help
when no executor is set, and `silence_errors` suppresses error text while the
error is still returned.

## Help, man page and version

`setup()` automatically adds `-h` / `--help`, and `--version` when the command
has a non-empty `version`. The generated text is available from
`cmd.help_message()`; `cmd.manpage()` returns an mdoc-style manual page. Set
`usage`, `examples` and `group` to enrich the output. A parent command with no
executor prints its help automatically.

## Suggestions

Mistyped subcommands and flags produce a `did you mean \`x\`?` hint based on
Levenshtein edit distance. The public helpers are `cli.levenshtein(a, b)`,
`cli.suggest(input, candidates)` and `cli.suggest_command(input, commands)`.
A hint is only returned for a close match (distance at most 2 and shorter than
the input). Per-command tuning is available: `suggest_for` adds extra alias
names that suggest a command, and `suggest_min_distance` overrides the
threshold for that command's subcommands (`cmd.suggest_subcommand(input)`).

## Dynamic completion and hints

Static completions cover subcommands, `choices` lists and flag names.
`complete_fn` on a command adds dynamic items for the current context, and
`complete_fn` on a flag adds dynamic values when completing that flag's
value. Items carry an optional directive (`no_space`, `keep_order`, file
filters) for custom `__complete` consumers. Items with `hint: true` are
ActiveHelp-style annotation lines: they are shown but never completed.

```v ignore
cmd.complete_fn = fn (c cli.Command, words []string) []cli.CompletionItem {
	return [cli.CompletionItem{ value: 'staging', description: 'deploy target' }]
}
```

Flags marked `required: true` are annotated `(required)` in completion output,
and `one_required` groups require exactly one of the listed flags.

## Parsing control, hooks and generated docs

- Command-aware persistent hooks run around the plain hooks:
  `persistent_before_with_fn` (root down to the executed command) and
  `persistent_after_with_fn` (back up). Returning an error aborts the run.
- `FlagType.count` counts occurrences (`-vvv` is 3, read with
  `get_count()`); count flags take no value.
- `no_opt_default` on a flag supplies the value when none is given
  (`--level` means `--level 1`). A value starting with `-` needs the
  `--flag=value` form.
- `normalize_fn` maps long flag names before lookup, e.g. dashes to
  underscores so `--log-level` fills a `log_level` flag.
- `traverse_children: true` lets subcommands accept the parent's local flags.
  `disable_flag_parsing: true` passes flag-like tokens through as positional
  arguments (subcommands still dispatch). With `interspersed: false`, the
  first positional argument ends flag parsing.
- `cmd.markdown()` and `cmd.to_yaml()` render the command tree; `cmd.manpage()`
  already covers mdoc. `help_fn` overrides help rendering and
  `version_template` (`{{name}}`/`{{version}}`) overrides `--version` output.

Configuration files need no dependency: read env or a file in `init_fn` or a
persistent before-hook and fill flag values with `get_flag`/`default_value`
before validation runs.

## Completion protocol

`run` recognises a first argument of `__complete`. It prints completion lines
of the form `value<TAB>description` and returns without executing anything:

```sh
tool __complete se      # e.g. "serve\tstart the server"
tool __complete --p     # e.g. "--port\tlisten port"
```

`cli.completion_result(cmd, args)` builds that output directly, and
`cli.completion_script(name, shell)` returns a script for `bash`, `zsh`,
`fish` or `powershell` (empty string for an unknown shell). A common pattern
is a `--print-completion` switch that prints the script and exits:

```v ignore
if os.args.len > 1 && os.args[1] == '--print-completion' {
	print(cli.completion_script('tool', 'bash'))
	return
}
```
