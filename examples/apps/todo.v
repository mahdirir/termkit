module main

import termkit
import termkit.widgets

struct Todo {
mut:
	input      widgets.TextInput
	list       widgets.List
	help       widgets.Help
	focus_list bool
}

fn (mut m Todo) set_focus(list bool) {
	m.focus_list = list
	if list {
		m.input.blur()
		m.list.focused = true
	} else {
		m.input.focus()
		m.list.focused = false
	}
}

fn (mut m Todo) init() termkit.Cmd {
	m.input = widgets.TextInput{ prompt: 'New task: ' }
	m.list = widgets.List{ multi_select: true, height: 8 }
	m.list.set_items(['Buy milk', 'Write release notes', 'Review PR'])
	m.set_focus(false)
	m.help.bindings = [
		widgets.Binding{ key: 'tab', description: 'switch input / list' },
		widgets.Binding{ key: 'enter', description: 'add task' },
		widgets.Binding{ key: 'space', description: 'toggle mark (list)' },
		widgets.Binding{ key: 'delete', description: 'remove selected task' },
		widgets.Binding{ key: 'q', description: 'quit' },
	]
	return termkit.no_cmd
}

fn (mut m Todo) add_current() {
	name := m.input.value.trim_space()
	if name == '' {
		return
	}
	mut items := m.list.items.clone()
	items << name
	m.list.set_items(items)
	m.input.value = ''
	m.input.position = 0
}

fn (mut m Todo) remove_selected() {
	idx := m.list.selected
	if idx < 0 || idx >= m.list.items.len {
		return
	}
	mut items := []string{}
	for i, item in m.list.items {
		if i != idx {
			items << item
		}
	}
	m.list.set_items(items)
}

fn (mut m Todo) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.KeyMsg {
			if msg.kind == .release {
				return m, termkit.no_cmd
			}
			match msg.key {
				'q' {
					return m, termkit.quit()
				}
				termkit.key_tab {
					m.set_focus(!m.focus_list)
					return m, termkit.no_cmd
				}
				termkit.key_enter {
					if !m.focus_list {
						m.add_current()
					}
					return m, termkit.no_cmd
				}
				termkit.key_delete {
					if m.focus_list {
						m.remove_selected()
					}
					return m, termkit.no_cmd
				}
				else {}
			}
		}
		else {}
	}
	if m.focus_list {
		m.list.update(msg)
	} else {
		m.input.update(msg)
	}
	return m, termkit.no_cmd
}

fn (mut m Todo) view() string {
	focus := if m.focus_list { 'list' } else { 'input' }
	marked := m.list.selected_items()
	summary := if marked.len > 0 { 'marked: ${marked.join(', ')}' } else { 'no tasks marked' }
	return 'TODO  (focus: ${focus})\n\n' + m.input.view() + '\n\n' + m.list.view() +
		'\n\n${summary}\n\n' + m.help.view()
}

fn main() {
	mut app := &Todo{}
	mut program := termkit.new_program(app, termkit.ProgramOpts{})
	program.run()!
}
