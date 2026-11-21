module cli

// FlagType is the kind of value a flag accepts.
pub enum FlagType {
	bool
	int
	float
	string
	int_array
	float_array
	string_array
}

// Flag describes a command line option.
pub struct Flag {
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

// found reports whether the flag was supplied on the command line.
pub fn (f &Flag) is_found() bool {
	return f.found
}

pub fn (f &Flag) get_bool() !bool {
	if f.flag != .bool {
		return error('${f.name}: expected bool flag')
	}
	v := f.get_value_or_default()
	return v.len > 0 && v[0] == 'true'
}

pub fn (f &Flag) get_string() !string {
	if f.flag != .string {
		return error('${f.name}: expected string flag')
	}
	v := f.get_value_or_default()
	return if v.len > 0 { v[0] } else { '' }
}

pub fn (f &Flag) get_int() !int {
	if f.flag != .int {
		return error('${f.name}: expected int flag')
	}
	v := f.get_value_or_default()
	return if v.len > 0 { v[0].int() } else { 0 }
}

pub fn (f &Flag) get_float() !f64 {
	if f.flag != .float {
		return error('${f.name}: expected float flag')
	}
	v := f.get_value_or_default()
	return if v.len > 0 { v[0].f64() } else { 0.0 }
}

pub fn (f &Flag) get_strings() ![]string {
	if f.flag != .string_array {
		return error('${f.name}: expected string_array flag')
	}
	return f.get_value_or_default()
}

pub fn (f &Flag) get_value_or_default() []string {
	if f.value.len > 0 {
		return f.value
	}
	return f.default_value
}

fn (f &Flag) matches(token string) bool {
	if f.flag == .bool && f.negatable && f.name != '' && token == '--no-${f.name}' {
		return true
	}
	if f.name != '' && token == '--${f.name}' {
		return true
	}
	if f.name != '' && token.starts_with('--${f.name}=') {
		return true
	}
	if f.abbrev != '' && token == '-${f.abbrev}' {
		return true
	}
	if f.abbrev != '' && token.starts_with('-${f.abbrev}=') {
		return true
	}
	return false
}

fn (mut f Flag) set_value(token string, next string) !int {
	if f.flag == .bool {
		if token.starts_with('--no-') {
			f.value = ['false']
		} else if token.contains('=') {
			f.value = [token.split('=')[1]]
		} else {
			f.value = ['true']
		}
		return 0
	}
	mut val := ''
	if token.contains('=') {
		val = token.split('=')[1]
	} else {
		if next == '' {
			return error('missing value for flag `${f.name}`')
		}
		val = next
	}
	if f.choices.len > 0 && val !in f.choices {
		return error('invalid value `${val}` for flag `${f.name}`')
	}
	if validator := f.validate {
		val = validator(val) or { return error('invalid value for flag `${f.name}`: ${err}') }
	}
	f.value << val
	return if token.contains('=') { 0 } else { 1 }
}

pub fn (flags []Flag) get(name string) !Flag {
	for f in flags {
		if f.name == name || f.abbrev == name {
			return f
		}
	}
	return error('flag `${name}` not found')
}

// ArgsRule is a built-in positional argument check.
pub enum ArgsRule {
	any
	none
	exact_one
	at_least_one
	exact_two
}

// Hook is a command callback. It takes no arguments; use the command's
// captured state or module state to communicate results.
pub type Hook = fn () !

// HookWithCommand is a callback that receives the parsed command.
pub type HookWithCommand = fn (Command) !

// Command is a node in a command tree.
pub struct Command {
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
	// mutually_exclusive lists groups of flag names that cannot be combined.
	mutually_exclusive [][]string
	// required_together lists groups where supplying one requires all.
	required_together [][]string
	before            Hook = unsafe { nil }
	execute_fn        Hook = unsafe { nil }
	after             Hook = unsafe { nil }
	init_fn           ?fn ()
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

fn (c &Command) write_out(s string) {
	if f := c.out {
		f(s)
		return
	}
	print(s)
}

fn (c &Command) write_err(s string) {
	if f := c.err_out {
		f(s)
		return
	}
	eprint(s)
}

// add_command appends a sub-command.
pub fn (mut c Command) add_command(sub Command) {
	c.commands << sub
}

// add_flag appends a flag.
pub fn (mut c Command) add_flag(f Flag) {
	c.flags << f
}

// full_name returns the space-separated path to this command.
pub fn (c &Command) full_name() string {
	if isnil(c.parent) {
		return c.name
	}
	return c.parent.full_name() + ' ' + c.name
}

// setup links parents and collects inherited global flags.
pub fn (mut c Command) setup() {
	c.all_flags = c.flags.clone()
	c.all_flags << c.inherited
	if !c.all_flags.any(it.name == 'help') {
		c.all_flags << Flag{ name: 'help', abbrev: 'h', description: 'show help', flag: .bool }
	}
	if c.version != '' && !c.all_flags.any(it.name == 'version') {
		c.all_flags << Flag{ name: 'version', description: 'show version', flag: .bool }
	}
	for i in 0 .. c.commands.len {
		c.commands[i].parent = &c
		c.commands[i].inherited = c.all_flags.filter(it.global)
		c.commands[i].setup()
	}
}

fn (c &Command) find_sub(token string) int {
	for i, sub in c.commands {
		if sub.name == token {
			return i
		}
		for alias in sub.aliases {
			if alias == token {
				return i
			}
		}
	}
	return -1
}

// run parses args (including the program name) and executes the command.
pub fn (mut c Command) run(args []string) ! {
	c.setup()
	if f := c.init_fn {
		f()
	}
	mut rest := if args.len > 0 { args[1..] } else { []string{} }
	if rest.len > 0 && rest[0] == '__complete' {
		print(completion_result(c, rest[1..]))
		return
	}
	c.dispatch(mut rest)!
}

fn (mut c Command) dispatch(mut args []string) ! {
	mut i := 0
	mut end_flags := false
	for i < args.len {
		token := args[i]
		if !end_flags && token == '--' {
			end_flags = true
			i++
			continue
		}
		if !end_flags && token.len > 1 && token.starts_with('-') && token != '-' {
			if token.starts_with('--') {
				i += c.parse_long(token, args, i)!
			} else {
				i += c.parse_short(token, args, i)!
			}
			continue
		}
		idx := c.find_sub(token)
		if idx >= 0 {
			mut sub := c.commands[idx]
			sub.dispatch(mut args[i + 1..])!
			return
		}
		c.args << token
		i++
	}
	c.finish()!
}

fn (mut c Command) parse_long(token string, args []string, pos int) !int {
	name_part := token[2..]
	name := if name_part.contains('=') { name_part.split('=')[0] } else { name_part }
	lookup := if name.starts_with('no-') { name[3..] } else { name }
	for i in 0 .. c.all_flags.len {
		mut f := &c.all_flags[i]
		if f.name != lookup {
			continue
		}
		if !f.matches(token) {
			continue
		}
		next := if pos + 1 < args.len { args[pos + 1] } else { '' }
		consumed := f.set_value(token, next)!
		f.found = true
		if f.name == 'help' && f.value[0] == 'true' {
			c.show_help = true
		}
		if f.name == 'version' && f.value[0] == 'true' {
			c.show_version = true
		}
		return 1 + consumed
	}
	return error('unknown flag `${token}` for `${c.full_name()}`. ${suggest_flags(name, c.all_flags)}')
}

fn (mut c Command) parse_short(token string, args []string, pos int) !int {
	bytes := token.bytes()
	// A cluster like -abc is split into -a -b -c when every letter is known.
	if bytes.len > 2 && !token.contains('=') {
		mut recognised := true
		for j in 1 .. bytes.len {
			if c.find_short(bytes[j]) < 0 {
				recognised = false
				break
			}
		}
		if recognised {
			for j in 1 .. bytes.len {
				c.apply_short(bytes[j], '', []string{}, 0)!
			}
			return 1
		}
	}
	return c.apply_short(bytes[1], token, args, pos)
}

fn (c &Command) find_short(ch u8) int {
	for i, f in c.all_flags {
		if f.abbrev.len == 1 && f.abbrev[0] == ch {
			return i
		}
	}
	return -1
}

fn (mut c Command) apply_short(ch u8, token string, args []string, pos int) !int {
	idx := c.find_short(ch)
	if idx < 0 {
		return error('unknown flag `-${ch.ascii_str()}` for `${c.full_name()}`')
	}
	mut f := &c.all_flags[idx]
	name := if token.len > 0 { token } else { '-${ch.ascii_str()}' }
	next := if pos + 1 < args.len { args[pos + 1] } else { '' }
	consumed := f.set_value(name, next)!
	f.found = true
	if f.name == 'help' && f.value[0] == 'true' {
		c.show_help = true
	}
	return 1 + consumed
}

fn (mut c Command) finish() ! {
	if c.show_help {
		c.write_out(c.help_message())
		return
	}
	if c.show_version {
		c.write_out('${c.name} version ${c.version}\n')
		return
	}
	for f in c.all_flags {
		if f.required && f.value.len == 0 {
			return error('flag `${f.name}` is required by `${c.full_name()}`')
		}
	}
	for group in c.mutually_exclusive {
		mut count := 0
		for name in group {
			if c.flag_found(name) {
				count++
			}
		}
		if count > 1 {
			return error('flags ${group.join(', ')} are mutually exclusive')
		}
	}
	for group in c.required_together {
		mut any := false
		for name in group {
			if c.flag_found(name) {
				any = true
			}
		}
		if any {
			for name in group {
				if !c.flag_found(name) {
					return error('flag `${name}` is required together with ${group.join(', ')}')
				}
			}
		}
	}
	match c.args_rule {
		.none {
			if c.args.len > 0 {
				return error('`${c.full_name()}` takes no positional arguments')
			}
		}
		.exact_one {
			if c.args.len != 1 {
				return error('`${c.full_name()}` needs exactly one argument')
			}
		}
		.exact_two {
			if c.args.len != 2 {
				return error('`${c.full_name()}` needs exactly two arguments')
			}
		}
		.at_least_one {
			if c.args.len == 0 {
				return error('`${c.full_name()}` needs at least one argument')
			}
		}
		else {}
	}
	if !isnil(c.before_with_fn) {
		c.before_with_fn(*c)!
	} else if !isnil(c.before) {
		c.before()!
	}
	if isnil(c.execute_fn) && isnil(c.execute_with_fn) {
		if c.commands.len == 0 {
			return error('`${c.full_name()}` has no run callback')
		}
		c.write_out(c.help_message())
		return
	}
	if !isnil(c.execute_with_fn) {
		c.execute_with_fn(*c)!
	} else {
		c.execute_fn()!
	}
	if !isnil(c.after_with_fn) {
		c.after_with_fn(*c)!
	} else if !isnil(c.after) {
		c.after()!
	}
}

fn (c &Command) flag_found(name string) bool {
	for f in c.all_flags {
		if (f.name == name || f.abbrev == name) && f.found {
			return true
		}
	}
	return false
}

// get_flag returns a copy of a flag in this command or its ancestors. It is
// available to read-only callbacks such as HookWithCommand.
pub fn (c &Command) get_flag(name string) !Flag {
	for f in c.all_flags {
		if f.name == name || f.abbrev == name {
			return f
		}
	}
	return error('flag `${name}` not found')
}

// flag returns a pointer to a flag in this command or its ancestors.
pub fn (mut c Command) flag(name string) !&Flag {
	for i in 0 .. c.all_flags.len {
		if c.all_flags[i].name == name || c.all_flags[i].abbrev == name {
			return &c.all_flags[i]
		}
	}
	return error('flag `${name}` not found')
}
