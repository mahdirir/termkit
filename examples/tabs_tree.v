module main

import termkit
import termkit.widgets

struct Explorer {
mut:
	tabs widgets.Tabs
	tree widgets.Tree
}

fn (mut m Explorer) init() termkit.Cmd {
	m.tabs.set_tabs(['Project', 'Symbols'])
	root := m.tree.add_node('project', -1)
	m.tree.add_node('src', root)
	m.tree.add_node('main.v', 1)
	m.tree.add_node('tests', root)
	m.tree.add_node('app_test.v', 3)
	return termkit.no_cmd
}

fn (mut m Explorer) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.KeyMsg {
			if msg.key == 'q' {
				return m, termkit.quit()
			}
			if msg.key == termkit.key_tab {
				m.tabs.update(msg)
			} else {
				m.tree.update(msg)
			}
		}
		else {}
	}
	return m, termkit.no_cmd
}

fn (mut m Explorer) view() string {
	return m.tabs.view() + '\n\n' + m.tree.view() +
		'\n\nleft/right: collapse/expand, up/down: move, tab: switch tab, q: quit'
}

fn main() {
	mut app := &Explorer{}
	mut program := termkit.new_program(app, termkit.ProgramOpts{})
	program.run()!
}
