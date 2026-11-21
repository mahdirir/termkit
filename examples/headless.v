module main

import termkit

// A non-interactive example: drive a model with injected messages, no TTY
// required. This is the pattern used by termkit's own tests.
struct Echo {
mut:
	seen []string
}

fn (mut m Echo) init() termkit.Cmd {
	return termkit.no_cmd
}

fn (mut m Echo) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.KeyMsg {
			m.seen << msg.key
		}
		else {}
	}
	return m, termkit.no_cmd
}

fn (mut m Echo) view() string {
	return m.seen.join(' ')
}

fn main() {
	mut model := &Echo{}
	mut program := termkit.new_program(model, termkit.ProgramOpts{
		without_renderer: true
		out:              fn (s string) { println('view: ${s}') }
	})
	program.send(termkit.KeyMsg{ key: 'h' })
	program.send(termkit.KeyMsg{ key: 'i' })
	program.process_queue()
	println('final: ${program.view()}')
	assert program.view() == 'h i'
}
