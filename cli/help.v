module cli

// help_message returns the generated help text for a command.
pub fn (c &Command) help_message() string {
	mut lines := []string{}
	mut title := c.full_name()
	if c.description != '' {
		title += ' - ${c.description}'
	}
	lines << title
	if c.usage != '' {
		lines << 'Usage: ${c.usage}'
	}
	if c.version != '' {
		lines << 'Version: ${c.version}'
	}
	if c.examples.len > 0 {
		lines << ''
		lines << 'Examples:'
		for example in c.examples {
			lines << '  ${example}'
		}
	}
	flags := if c.all_flags.len > 0 { c.all_flags } else { c.flags }
	lines << ''
	lines << 'Flags:'
	for f in flags {
		if f.hidden {
			continue
		}
		mut label := ''
		if f.name != '' {
			label = '--${f.name}'
		} else if f.abbrev != '' {
			label = '-${f.abbrev}'
		}
		if f.name != '' && f.abbrev != '' {
			label += ', -${f.abbrev}'
		}
		if f.required {
			label += ' (required)'
		}
		if f.deprecated != '' {
			label += ' (deprecated: ${f.deprecated})'
		}
		lines << '  ${label}  ${f.description}'
	}
	visible := c.commands.filter(!it.hidden)
	if visible.len > 0 {
		lines << ''
		lines << 'Commands:'
		for sub in visible {
			lines << '  ${sub.name}  ${sub.description}'
		}
	}
	return lines.join('\n') + '\n'
}
