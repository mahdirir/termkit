module main

import termkit

struct Counter {
mut:
	n int
}

fn (mut m Counter) init() termkit.Cmd {
	return termkit.no_cmd
}

fn (mut m Counter) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.KeyMsg {
			match msg.key {
				'q' {
					return m, termkit.quit()
				}
				'+' {
					m.n++
				}
				'-' {
					m.n--
				}
				else {}
			}
		}
		else {}
	}
	return m, termkit.no_cmd
}

fn (mut m Counter) view() string {
	return 'Count: ${m.n}\n\n+ / - to change, q to quit'
}

fn main() {
	mut model := &Counter{}
	mut program := termkit.new_program(model, termkit.ProgramOpts{ alt_screen: true })
	program.run()!
}
