module cli

import time

// manpage returns an mdoc-style manual page for a command.
pub fn (c &Command) manpage() string {
	now := time.now()
	mut out := [
		'.Dd ${now.year}-${int(now.month):02}-${now.day:02}',
		'.Dt ${c.name.to_upper()} 1',
		'.Sh NAME',
		'.Nm ${c.name}',
	]
	if c.description != '' {
		out << '.Nd ${c.description}'
	}
	out << '.Sh SYNOPSIS'
	out << '.Nm ${c.name}'
	for f in c.all_flags {
		if f.hidden || f.name == '' {
			continue
		}
		out << '.Op Fl -${f.name}'
	}
	out << '.Sh DESCRIPTION'
	out << c.description
	flags := if c.all_flags.len > 0 { c.all_flags } else { c.flags }
	if flags.len > 0 {
		out << '.Sh FLAGS'
		for f in flags {
			if f.hidden {
				continue
			}
			out << '.It Fl -${f.name}'
			if f.abbrev != '' {
				out << '.It Fl ${f.abbrev}'
			}
			out << f.description
		}
	}
	visible := c.commands.filter(!it.hidden)
	if visible.len > 0 {
		out << '.Sh COMMANDS'
		for sub in visible {
			out << '.It Nm ${sub.name}'
			out << sub.description
		}
	}
	return out.join('\n') + '\n'
}
