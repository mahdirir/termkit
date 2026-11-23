# module cli


## Contents
- [completion_result](#completion_result)
- [completion_script](#completion_script)
- [levenshtein](#levenshtein)
- [suggest](#suggest)
- [suggest_command](#suggest_command)
- [ArgsRule.from](#ArgsRule.from)
- [FlagType.from](#FlagType.from)
- [Hook](#Hook)
- [HookWithCommand](#HookWithCommand)
- [[]Flag](#[]Flag)
  - [get](#get)
- [ArgsRule](#ArgsRule)
- [FlagType](#FlagType)
- [Command](#Command)
  - [add_command](#add_command)
  - [add_flag](#add_flag)
  - [full_name](#full_name)
  - [setup](#setup)
  - [run](#run)
  - [get_flag](#get_flag)
  - [flag](#flag)
  - [help_message](#help_message)
  - [manpage](#manpage)
- [Flag](#Flag)
  - [is_found](#is_found)
  - [get_bool](#get_bool)
  - [get_string](#get_string)
  - [get_int](#get_int)
  - [get_ints](#get_ints)
  - [get_float](#get_float)
  - [get_floats](#get_floats)
  - [get_strings](#get_strings)
  - [get_value_or_default](#get_value_or_default)

## completion_result
```v ignore
fn completion_result(c &Command, args []string) string
```

completion_result implements the dynamic `__complete` protocol. Each line is
`value<TAB>description`, a format all supported shells can consume.

[[Return to contents]](#Contents)

## completion_script
```v ignore
fn completion_script(name string, shell string) string
```

completion_script returns a shell completion script for name. Shell metacharacters are written as
`~` in the templates and substituted at runtime so V does not try to interpolate them.

[[Return to contents]](#Contents)

## levenshtein
```v ignore
fn levenshtein(a string, b string) int
```

levenshtein returns the edit distance between two strings.

[[Return to contents]](#Contents)

## suggest
```v ignore
fn suggest(input string, candidates []string) string
```

suggest returns a 'did you mean' hint for the closest candidate.

[[Return to contents]](#Contents)

## suggest_command
```v ignore
fn suggest_command(input string, commands []Command) string
```

suggest_command returns a suggestion for a mistyped sub-command.

[[Return to contents]](#Contents)

## ArgsRule.from
```v ignore
fn ArgsRule.from[W](input W) !ArgsRule
```

from returns the `ArgsRule` value of an integer or of a field name, or an error if there is none.

[[Return to contents]](#Contents)

## FlagType.from
```v ignore
fn FlagType.from[W](input W) !FlagType
```

from returns the `FlagType` value of an integer or of a field name, or an error if there is none.

[[Return to contents]](#Contents)

## Hook
```v ignore
type Hook = fn () !
```

Hook is a command callback. It takes no arguments; use the command's captured state or module state
to communicate results.

[[Return to contents]](#Contents)

## HookWithCommand
```v ignore
type HookWithCommand = fn (Command) !
```

HookWithCommand is a callback that receives the parsed command.

[[Return to contents]](#Contents)

## []Flag
## get
```v ignore
fn (flags []Flag) get(name string) !Flag
```

get returns the flag with the given name or abbreviation.

[[Return to contents]](#Contents)

## ArgsRule
```v ignore
enum ArgsRule {
	any
	none
	exact_one
	at_least_one
	exact_two
}
```

ArgsRule is a built-in positional argument check.

[[Return to contents]](#Contents)

## FlagType
```v ignore
enum FlagType {
	bool
	int
	float
	string
	int_array
	float_array
	string_array
}
```

FlagType is the kind of value a flag accepts.

[[Return to contents]](#Contents)

## Command
```v ignore
struct Command {
pub mut:
	name        string
	aliases     []string
	usage       string
	description string
	version     string
	group       string
	examples    []string
	flags       []Flag
	commands    []Command
	args        []string
	args_rule   ArgsRule
	hidden      bool
	deprecated  string
	// silence_usage suppresses generated help when a command has no callback.
	silence_usage bool
	// silence_errors suppresses error text; errors are still returned.
	silence_errors bool
	// mutually_exclusive lists groups of flag names that cannot be combined.
	mutually_exclusive [][]string
	// required_together lists groups where supplying one requires all.
	required_together [][]string
	before            Hook = unsafe { nil }
	execute_fn        Hook = unsafe { nil }
	after             Hook = unsafe { nil }
	// persistent_before runs before before hooks for this command and every
	// descendant, from the root command down to the executed one.
	persistent_before Hook = unsafe { nil }
	// persistent_after runs after after hooks for this command and every
	// descendant, from the executed command up to the root.
	persistent_after Hook = unsafe { nil }
	init_fn          ?fn ()
	// The *_with_fn hooks receive the parsed command, so callbacks can read
	// flags without globals. They take precedence over the plain hooks.
	before_with_fn  HookWithCommand = unsafe { nil }
	execute_with_fn HookWithCommand = unsafe { nil }
	after_with_fn   HookWithCommand = unsafe { nil }
	// out and err_out capture generated output in tests. When absent, output
	// goes to the process streams.
	out     ?fn (string)
	err_out ?fn (string)
mut:
	parent       &Command = unsafe { nil }
	inherited    []Flag
	all_flags    []Flag
	show_help    bool
	show_version bool
}
```

Command is a node in a command tree.

[[Return to contents]](#Contents)

## add_command
```v ignore
fn (mut c Command) add_command(sub Command)
```

add_command appends a sub-command.

[[Return to contents]](#Contents)

## add_flag
```v ignore
fn (mut c Command) add_flag(f Flag)
```

add_flag appends a flag.

[[Return to contents]](#Contents)

## full_name
```v ignore
fn (c &Command) full_name() string
```

full_name returns the space-separated path to this command.

[[Return to contents]](#Contents)

## setup
```v ignore
fn (mut c Command) setup()
```

setup links parents and collects inherited global flags.

[[Return to contents]](#Contents)

## run
```v ignore
fn (mut c Command) run(args []string) !
```

run parses args (including the program name) and executes the command.

[[Return to contents]](#Contents)

## get_flag
```v ignore
fn (c &Command) get_flag(name string) !Flag
```

get_flag returns a copy of a flag in this command or its ancestors. It is available to read-only
callbacks such as HookWithCommand.

[[Return to contents]](#Contents)

## flag
```v ignore
fn (mut c Command) flag(name string) !&Flag
```

flag returns a pointer to a flag in this command or its ancestors.

[[Return to contents]](#Contents)

## help_message
```v ignore
fn (c &Command) help_message() string
```

help_message returns the generated help text for a command.

[[Return to contents]](#Contents)

## manpage
```v ignore
fn (c &Command) manpage() string
```

manpage returns an mdoc-style manual page for a command.

[[Return to contents]](#Contents)

## Flag
```v ignore
struct Flag {
pub mut:
	name          string
	abbrev        string
	description   string
	flag          FlagType = .string
	global        bool
	required      bool
	hidden        bool
	deprecated    string
	default_value []string
	choices       []string
	// negatable allows --no-<name> to set a bool flag to false.
	negatable bool
	// validate transforms or rejects a value supplied for this flag.
	validate ?fn (string) !string
mut:
	found bool
	value []string
}
```

Flag describes a command line option.

[[Return to contents]](#Contents)

## is_found
```v ignore
fn (f &Flag) is_found() bool
```

found reports whether the flag was supplied on the command line.

[[Return to contents]](#Contents)

## get_bool
```v ignore
fn (f &Flag) get_bool() !bool
```

get_bool returns the boolean value of the flag.

[[Return to contents]](#Contents)

## get_string
```v ignore
fn (f &Flag) get_string() !string
```

get_string returns the string value of the flag.

[[Return to contents]](#Contents)

## get_int
```v ignore
fn (f &Flag) get_int() !int
```

get_int returns the integer value of the flag, rejecting malformed input.

[[Return to contents]](#Contents)

## get_ints
```v ignore
fn (f &Flag) get_ints() ![]int
```

get_ints returns all integer values of a repeatable flag.

[[Return to contents]](#Contents)

## get_float
```v ignore
fn (f &Flag) get_float() !f64
```

get_float returns the floating point value of the flag.

[[Return to contents]](#Contents)

## get_floats
```v ignore
fn (f &Flag) get_floats() ![]f64
```

get_floats returns all floating point values of a repeatable flag.

[[Return to contents]](#Contents)

## get_strings
```v ignore
fn (f &Flag) get_strings() ![]string
```

get_strings returns all string values of a repeatable flag.

[[Return to contents]](#Contents)

## get_value_or_default
```v ignore
fn (f &Flag) get_value_or_default() []string
```

get_value_or_default returns the supplied values, or the defaults when the flag was not present on
the command line.

[[Return to contents]](#Contents)

#### Powered by vdoc.
