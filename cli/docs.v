module cli

// markdown returns the command tree rendered as Markdown.
pub fn (c &Command) markdown() string {
	mut out := ['# ${c.name}', '']
	if c.description != '' {
		out << c.description
		out << ''
	}
	if c.usage != '' {
		out << 'Usage: `${c.usage}`'
		out << ''
	}
	if c.version != '' {
		out << 'Version: ${c.version}'
		out << ''
	}
	flags := if c.all_flags.len > 0 { c.all_flags } else { c.flags }
	mut shown := flags.filter(!it.hidden && it.name != '')
	if shown.len > 0 {
		out << '## Flags'
		out << ''
		out << '| Flag | Description |'
		out << '| --- | --- |'
		for f in shown {
			mut label := '`--${f.name}`'
			if f.abbrev != '' {
				label += ', `-${f.abbrev}`'
			}
			mut desc := f.description
			if f.required {
				desc += ' (required)'
			}
			if f.deprecated != '' {
				desc += ' (deprecated: ${f.deprecated})'
			}
			out << '| ${label} | ${desc} |'
		}
		out << ''
	}
	if c.examples.len > 0 {
		out << '## Examples'
		out << ''
		for example in c.examples {
			out << '```'
			out << example
			out << '```'
		}
		out << ''
	}
	visible := c.commands.filter(!it.hidden)
	if visible.len > 0 {
		out << '## Commands'
		out << ''
		for sub in visible {
			out << '- `${sub.name}`: ${sub.description}'
			out << ''
			for line in sub.markdown_body() {
				out << line
			}
		}
	}
	return out.join('\n')
}

fn (c &Command) markdown_body() []string {
	mut out := []string{}
	flags := if c.all_flags.len > 0 { c.all_flags } else { c.flags }
	mut shown := flags.filter(!it.hidden && it.name != '')
	for f in shown {
		out << '  `--${f.name}`: ${f.description}'
	}
	return out
}

// to_yaml returns the command tree rendered as YAML.
pub fn (c &Command) to_yaml() string {
	mut out := ['name: ${c.name}']
	if c.description != '' {
		out << 'description: ${c.description}'
	}
	if c.version != '' {
		out << 'version: ${c.version}'
	}
	if c.usage != '' {
		out << 'usage: ${c.usage}'
	}
	flags := if c.all_flags.len > 0 { c.all_flags } else { c.flags }
	mut shown := flags.filter(!it.hidden && it.name != '')
	if shown.len > 0 {
		out << 'flags:'
		for f in shown {
			out << '  - name: ${f.name}'
			if f.abbrev != '' {
				out << '    abbrev: ${f.abbrev}'
			}
			out << '    type: ${f.flag}'
			if f.description != '' {
				out << '    description: ${f.description}'
			}
			if f.required {
				out << '    required: true'
			}
			if f.default_value.len > 0 {
				out << '    default: ${f.default_value.join(',')}'
			}
		}
	}
	if c.examples.len > 0 {
		out << 'examples:'
		for example in c.examples {
			out << '  - ${example}'
		}
	}
	visible := c.commands.filter(!it.hidden)
	if visible.len > 0 {
		out << 'commands:'
		for sub in visible {
			for line in sub.to_yaml().split('\n') {
				out << '  ' + line
			}
		}
	}
	return out.join('\n') + '\n'
}
