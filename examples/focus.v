module main

import termkit
import termkit.widgets

struct Form {
mut:
	group  widgets.FocusGroup
	picker widgets.FilePicker
}

fn (mut m Form) init() termkit.Cmd {
	mut name := widgets.TextInput{ prompt: 'Name: ' }
	mut filter := widgets.TextInput{ prompt: 'Filter: ' }
	m.group.add(name)
	m.group.add(filter)
	picker := widgets.new_filepicker('.') or { widgets.FilePicker{ path: '.' } }
	m.group.add(picker)
	return termkit.no_cmd
}

fn (mut m Form) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.KeyMsg {
			if msg.key == 'q' {
				return m, termkit.quit()
			}
		}
		else {}
	}
	m.group.update(msg)
	return m, termkit.no_cmd
}

fn (mut m Form) view() string {
	return 'Tab / Shift+Tab to switch fields, q to quit\n\n' + m.group.view()
}

fn main() {
	mut form := &Form{}
	mut program := termkit.new_program(form, termkit.ProgramOpts{})
	program.run()!
}
