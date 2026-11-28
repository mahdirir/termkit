@[has_globals]
module termkit

import context
import os
import term.ui as tui
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

struct StaticViewModel {
mut:
	text string
}

fn (mut m StaticViewModel) init() Cmd {
	return no_cmd
}

fn (mut m StaticViewModel) update(_ Msg) (Model, Cmd) {
	return m, no_cmd
}

fn (mut m StaticViewModel) view() string {
	return m.text
}

struct PasteModel {
mut:
	pasted        string
	focus_changes int
	repeats       int
}

fn (mut m PasteModel) init() Cmd {
	return no_cmd
}

fn (mut m PasteModel) update(msg Msg) (Model, Cmd) {
	match msg {
		PasteMsg {
			m.pasted = msg.text
		}
		FocusMsg {
			m.focus_changes++
		}
		BlurMsg {
			m.focus_changes--
		}
		KeyMsg {
			if msg.kind == .repeat {
				m.repeats++
			}
		}
		else {}
	}
	return m, no_cmd
}

fn (mut m PasteModel) view() string {
	return m.pasted
}

fn new_paste_program() Program {
	return new_program(&PasteModel{}, ProgramOpts{ without_renderer: true })
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

fn test_key_release_from_terminal_is_marked_release() {
	release := msg_from_event(&tui.Event{ typ: .key_up, code: .down, utf8: '\x00' })
	match release {
		KeyMsg {
			assert release.key == key_down
			assert release.kind == .release
		}
		else {
			assert false
		}
	}
}

fn test_program_quits() {
	mut p := new_test_program()
	p.send(KeyMsg{ key: 'q' })
	p.process_queue()
	assert p.quitting
}

fn test_repeat_keys_still_reach_model() {
	mut p := new_test_program()
	p.send(KeyMsg{ key: 'i', kind: .repeat })
	p.process_queue()
	assert p.view() == 'n=1:i'
}

fn test_program_draw_frame_erases_shrinking_view() {
	mut model := &StaticViewModel{ text: 'abcd' }
	mut p := new_program(model, ProgramOpts{ without_renderer: true })
	p.renderer = new_renderer(8, 2, .ansi)
	first := p.draw_frame(.ansi, 8, 2)
	assert first.contains('abcd')
	model.text = 'ab'
	second := p.draw_frame(.ansi, 8, 2)
	assert second.contains('\x1b[1;3H')
	assert second.contains('  ')
	assert p.draw_frame(.ansi, 8, 2) == ''
}

fn test_navigation_keys_reach_model_from_terminal_events() {
	mut p := new_test_program()
	// Unix reports the raw escape sequence in utf8; Windows reports NUL.
	p.send(msg_from_event(&tui.Event{ typ: .key_down, code: .down, utf8: '\x1b[B' }))
	p.send(msg_from_event(&tui.Event{ typ: .key_down, code: .up, utf8: '\x00' }))
	p.process_queue()
	assert p.view() == 'n=0:down,up'
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

__global (
	cleanup_called bool
)

fn mark_cleanup() {
	cleanup_called = true
}

fn test_msg_from_event_special_sequences() {
	start := msg_from_event(&tui.Event{ typ: .key_down, utf8: '\x1b[200~' })
	assert start is PasteStartMsg
	end := msg_from_event(&tui.Event{ typ: .key_down, utf8: '\x1b[201~' })
	assert end is PasteEndMsg
	focus := msg_from_event(&tui.Event{ typ: .key_down, utf8: '\x1b[I' })
	assert focus is FocusMsg
	blur := msg_from_event(&tui.Event{ typ: .key_down, utf8: '\x1b[O' })
	assert blur is BlurMsg
}

fn test_bracketed_paste_accumulates_into_one_message() {
	mut p := new_paste_program()
	p.send(PasteStartMsg{})
	p.send(KeyMsg{ key: 'h' })
	p.send(KeyMsg{ key: 'i' })
	p.send(PasteEndMsg{})
	p.process_queue()
	assert p.view() == 'hi'
}

fn test_paste_preserves_multibyte_and_control_keys() {
	mut p := new_paste_program()
	p.send(PasteStartMsg{})
	p.send(KeyMsg{ key: 'é' })
	p.send(KeyMsg{ key: '世' })
	p.send(msg_from_event(&tui.Event{ typ: .key_down, code: .enter, utf8: '\r' }))
	p.send(PasteEndMsg{})
	p.process_queue()
	assert p.view() == 'é世\r'
}

fn test_paste_through_raw_terminal_events() {
	mut p := new_paste_program()
	p.send(msg_from_event(&tui.Event{ typ: .key_down, utf8: '\x1b[200~' }))
	p.send(msg_from_event(&tui.Event{ typ: .key_down, utf8: 'a' }))
	p.send(msg_from_event(&tui.Event{ typ: .key_down, utf8: '\x1b[201~' }))
	p.process_queue()
	assert p.view() == 'a'
}

fn test_focus_blur_and_repeat_from_events() {
	mut p := new_paste_program()
	p.send(msg_from_event(&tui.Event{ typ: .key_down, utf8: '\x1b[I' }))
	p.send(msg_from_event(&tui.Event{ typ: .key_down, utf8: '\x1b[O' }))
	repeat_evt := tui.Event{
		typ:  .key_down
		code: .a
		utf8: '\x1b[97;1:3u'
	}
	repeat_msg := msg_from_event(&repeat_evt)
	match repeat_msg {
		KeyMsg {
			assert repeat_msg.kind == .repeat
		}
		else {
			assert false
		}
	}
	p.send(repeat_msg)
	p.process_queue()
	model := p.model as PasteModel
	assert model.focus_changes == 0
	assert model.repeats == 1
}

fn test_cleanup_hook_on_normal_quit() {
	cleanup_called = false
	mut p := new_program(&CounterModel{}, ProgramOpts{
		without_renderer: true
		cleanup_fn:       mark_cleanup
	})
	p.call_cleanup()
	assert cleanup_called
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

fn send_many(p &Program, count int) {
	for _ in 0 .. count {
		p.send(KeyMsg{ key: 'i' })
	}
}

fn test_threaded_send_stress() {
	mut p := new_test_program()
	ptr := &p
	mut workers := []thread{}
	for _ in 0 .. 4 {
		workers << go send_many(ptr, 25)
	}
	for worker in workers {
		worker.wait()
	}
	p.process_queue()
	assert p.view().starts_with('n=100:')
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
