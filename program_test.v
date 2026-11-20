module termkit

import time

struct CounterModel {
mut:
	n    int
	seen []string
}

fn (mut m CounterModel) init() Cmd {
	return no_cmd
}

fn (mut m CounterModel) update(msg Msg) (Model, Cmd) {
	match msg {
		KeyMsg {
			m.seen << msg.key
			if msg.key == 'i' {
				m.n++
			}
			if msg.key == 'e' {
				return m, msg_cmd(KeyMsg{ key: 'echo' })
			}
			if msg.key == 'q' {
				return m, quit()
			}
		}
		TickMsg {
			m.seen << 'tick'
		}
		else {}
	}
	return m, no_cmd
}

fn (mut m CounterModel) view() string {
	return 'n=${m.n}:${m.seen.join(',')}'
}

fn new_test_program() Program {
	mut model := &CounterModel{}
	return new_program(mut model, ProgramOpts{ without_renderer: true })
}

fn test_program_updates_model() {
	mut p := new_test_program()
	p.send(KeyMsg{ key: 'i' })
	p.process_queue()
	assert p.view() == 'n=1:i'
}

fn test_program_dispatches_commands() {
	mut p := new_test_program()
	p.send(KeyMsg{ key: 'e' })
	p.process_queue()
	assert p.view() == 'n=0:e,echo'
}

fn test_program_quits() {
	mut p := new_test_program()
	p.send(KeyMsg{ key: 'q' })
	p.process_queue()
	assert p.quitting
}

fn tick_test_message(at i64) Msg {
	return TickMsg{ id: 9, at: at }
}

fn test_program_pumps_timers() {
	mut p := new_test_program()
	p.dispatch(tick(9, time.Duration(0), tick_test_message))
	p.pump_timers()
	p.process_queue()
	assert p.view() == 'n=0:tick'
}

fn test_program_skips_noop() {
	mut p := new_test_program()
	p.send(NoopMsg{})
	p.process_queue()
	assert p.view() == 'n=0:'
}
