module termkit

import context
import os
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
	return new_program(model, ProgramOpts{ without_renderer: true })
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

fn drop_noop(msg termkit.Msg) ?termkit.Msg {
	match msg {
		termkit.NoopMsg {
			return none
		}
		else {
			return msg
		}
	}
}

fn test_log_to_file() {
	path := os.join_path(os.vtmp_dir(), 'termkit_log_test.txt')
	os.rm(path) or {}
	mut p := new_test_program()
	p.send(LogMsg{ path: path, message: 'hello log' })
	p.process_queue()
	assert os.read_file(path) or { '' }.contains('hello log')
	os.rm(path) or {}
}

fn test_message_filter() {
	mut model := &CounterModel{}
	mut p := new_program(model, ProgramOpts{ without_renderer: true, filter: drop_noop })
	p.send(termkit.NoopMsg{})
	p.process_queue()
	assert p.view() == 'n=0:'
	p.send(termkit.KeyMsg{ key: 'i' })
	p.process_queue()
	assert p.view() == 'n=1:i'
}

fn test_lifecycle_hooks_exist() {
	opts := ProgramOpts{
		init_fn:    fn () {}
		cleanup_fn: fn () {}
	}
	if f := opts.init_fn {
		f()
	}
	if f := opts.cleanup_fn {
		f()
	}
	assert true
}

fn test_program_resizes_renderer() {
	mut p := new_test_program()
	r := new_renderer(4, 1, .ansi)
	p.renderer = r
	p.send(WindowSizeMsg{ width: 8, height: 3 })
	p.process_queue()
	if restored := p.renderer {
		assert restored.width == 8
		assert restored.height == 3
	} else {
		assert false
	}
}

fn test_threaded_send() {
	mut p := new_test_program()
	ptr := &p
	go ptr.send(KeyMsg{ key: 'i' })
	time.sleep(20 * time.millisecond)
	p.process_queue()
	assert p.view() == 'n=1:i'
}

fn test_context_cancellation() {
	mut parent := context.background()
	mut ctx, cancel := context.with_cancel(mut parent)
	assert !context_cancelled(ctx)
	cancel()
	assert context_cancelled(ctx)
}

fn test_program_opts_hooks() {
	opts := ProgramOpts{
		without_renderer: true
		out:              fn (s string) {}
		cancel:           fn () bool { return false }
	}
	assert opts.without_renderer
}

fn test_repaint_clears_baseline() {
	mut p := new_test_program()
	mut r := new_renderer(4, 1, .ansi)
	r.draw_text(0, 0, 'x', '', '', 0)
	r.frame()
	p.renderer = r
	p.repaint()
	if restored := p.renderer {
		assert restored.prev[0].text == ''
	} else {
		assert false
	}
}
