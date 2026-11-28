module main

import termkit
import termkit.widgets
import time

fn tick_message(at i64) termkit.Msg {
	return termkit.TickMsg{ id: 1, at: at }
}

struct Clock {
mut:
	stopwatch widgets.Stopwatch
	timer     widgets.Timer
}

fn (mut m Clock) init() termkit.Cmd {
	m.timer = widgets.new_timer(10 * time.second)
	m.stopwatch.start()
	m.timer.start()
	return termkit.every(1, 100 * time.millisecond, tick_message)
}

fn (mut m Clock) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.KeyMsg {
			if msg.kind == .release {
				return m, termkit.no_cmd
			}
			if msg.key == 'q' {
				return m, termkit.quit()
			}
			if msg.key == 's' {
				m.stopwatch.stop()
				m.timer.stop()
			}
			if msg.key == 'r' {
				m.stopwatch.start()
				m.timer.start()
			}
		}
		else {}
	}
	m.stopwatch.update(msg)
	m.timer.update(msg)
	return m, termkit.no_cmd
}

fn (mut m Clock) view() string {
	return 'elapsed:   ${m.stopwatch.view()}\nremaining: ${m.timer.view()}\n\ns/r: stop/resume, q: quit'
}

fn main() {
	mut clock := &Clock{}
	mut program := termkit.new_program(clock, termkit.ProgramOpts{})
	program.run()!
}
