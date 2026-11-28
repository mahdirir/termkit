module main

import termkit
import termkit.widgets

struct App {
mut:
	input widgets.TextInput
	list  widgets.List
	help  widgets.Help
}

fn (mut m App) init() termkit.Cmd {
	m.list.set_items(['alpha', 'beta', 'gamma', 'delta'])
	m.help.bindings = [
		widgets.Binding{ key: 'type', description: 'filter items' },
		widgets.Binding{ key: 'up/down', description: 'move selection' },
		widgets.Binding{ key: 'q', description: 'quit' },
	]
	return termkit.no_cmd
}

fn (mut m App) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.KeyMsg {
			if msg.kind == .release {
				return m, termkit.no_cmd
			}
			if msg.key == 'q' {
				return m, termkit.quit()
			}
		}
		else {}
	}
	match msg {
		termkit.KeyMsg {
			if msg.key in [termkit.key_up, termkit.key_down, termkit.key_page_up,
				termkit.key_page_down] {
				m.list.update(msg)
			} else {
				m.input.update(msg)
				m.list.filter = m.input.value
			}
		}
		else {}
	}
	return m, termkit.no_cmd
}

fn (mut m App) view() string {
	return m.input.view() + '\n\n' + m.list.view() + '\n\n' + m.help.view()
}

fn main() {
	mut app := &App{}
	mut program := termkit.new_program(app, termkit.ProgramOpts{})
	program.run()!
}
