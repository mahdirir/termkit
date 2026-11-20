module termkit

import term.ui as tui
import time

// Model is the state of an MVU program. init returns the first command,
// update handles a message and returns the next model plus a command, and
// view renders the current state.
pub interface Model {
mut:
	init() Cmd
	update(Msg) (Model, Cmd)
	view() string
}

struct Scheduled {
pub:
	id       int
	interval i64
	produce  fn (i64) Msg = unsafe { nil }
mut:
	next i64
}

// Program drives a Model using term.ui for input and output.
pub struct Program {
pub:
	opts ProgramOpts
pub mut:
	model Model
mut:
	ui        &tui.Context = unsafe { nil }
	queue     []Msg
	scheduled []Scheduled
	next_id   int
	quitting  bool
}

// new_program creates a Program for model.
pub fn new_program(mut model Model, opts ProgramOpts) Program {
	return Program{
		model: model
		opts:  opts
	}
}

// send queues a message for the model.
pub fn (mut p Program) send(msg Msg) {
	p.queue << msg
}

// process_queue delivers all queued messages, stopping on QuitMsg.
pub fn (mut p Program) process_queue() {
	for p.queue.len > 0 && !p.quitting {
		msg := p.queue[0]
		p.queue = p.queue[1..]
		p.handle(msg)
	}
}

// view renders the current model state.
pub fn (mut p Program) view() string {
	return p.model.view()
}

// run sets up term.ui, schedules the init command and starts the event loop.
pub fn (mut p Program) run() ! {
	mut ctx := tui.init(tui.Config{
		user_data:            p
		frame_fn:             frame_cb
		event_fn:             event_cb
		frame_rate:           if p.opts.fps > 0 { p.opts.fps } else { 60 }
		mouse_enabled:        p.opts.mouse
		capture_events:       p.opts.capture_events
		use_alternate_buffer: p.opts.alt_screen
		window_title:         p.opts.window_title
		hide_cursor:          p.opts.hide_cursor
	})
	p.ui = ctx
	p.dispatch(p.model.init())
	ctx.run()!
}

fn (mut p Program) handle(msg Msg) {
	match msg {
		QuitMsg {
			p.quitting = true
			return
		}
		TitleMsg {
			if !isnil(p.ui) {
				p.ui.set_window_title(msg.title)
			}
			return
		}
		WriteLineMsg {
			if !isnil(p.ui) {
				p.ui.write(msg.text)
				p.ui.write('\n')
				p.ui.flush()
			}
			return
		}
		NoopMsg {
			return
		}
		else {}
	}
	updated, cmd := p.model.update(msg)
	p.model = updated
	p.dispatch(cmd)
}

fn (mut p Program) dispatch(cmd Cmd) {
	match cmd {
		NoCmd {}
		MsgCmd {
			p.send(cmd.msg)
		}
		CmdFn {
			p.send(call_cmd_fn(cmd))
		}
		BatchCmd {
			for inner in cmd.cmds {
				p.dispatch(inner)
			}
		}
		SequenceCmd {
			for inner in cmd.cmds {
				p.dispatch(inner)
			}
		}
		TickCmd {
			p.schedule(cmd.id, cmd.delay, cmd.produce, false)
		}
		EveryCmd {
			p.schedule(cmd.id, cmd.delay, cmd.produce, true)
		}
	}
}

fn (mut p Program) schedule(id int, delay time.Duration, produce fn (i64) Msg, repeat bool) {
	if isnil(produce) {
		return
	}
	p.next_id++
	sid := if id == 0 { p.next_id } else { id }
	mut interval := i64(0)
	if repeat {
		interval = delay.nanoseconds()
		if interval <= 0 {
			return
		}
	}
	p.scheduled << Scheduled{
		id:       sid
		next:     time.now().unix_nano() + delay.nanoseconds()
		interval: interval
		produce:  produce
	}
}

// pump_timers moves due timers into the message queue. It is called once per
// frame so no extra threads are needed.
fn (mut p Program) pump_timers() {
	now := time.now().unix_nano()
	for i := p.scheduled.len - 1; i >= 0; i-- {
		s := p.scheduled[i]
		if now < s.next {
			continue
		}
		p.send(s.produce(s.next))
		if s.interval > 0 {
			mut next := s
			next.next += s.interval
			if next.next <= now {
				next.next = now + s.interval
			}
			p.scheduled[i] = next
		} else {
			p.scheduled.delete(i)
		}
	}
}

fn event_cb(e &tui.Event, user_data voidptr) {
	mut p := unsafe { &Program(user_data) }
	p.send(msg_from_event(e))
}

fn frame_cb(user_data voidptr) {
	mut p := unsafe { &Program(user_data) }
	p.pump_timers()
	p.process_queue()
	if p.quitting {
		exit(0)
	}
	if !p.opts.without_renderer && !isnil(p.ui) {
		p.ui.write(p.view())
		p.ui.reset()
		p.ui.flush()
	}
}

fn msg_from_event(e &tui.Event) Msg {
	match e.typ {
		.key_down, .key_up {
			kind := if e.typ == .key_up { KeyEventKind.release } else { KeyEventKind.press }
			return KeyMsg{
				key:       key_for_event(e)
				code:      int(e.code)
				modifiers: modifiers_from(e.modifiers)
				kind:      kind
				utf8:      e.utf8
			}
		}
		.mouse_down, .mouse_up, .mouse_move, .mouse_drag, .mouse_scroll {
			mut action := MouseAction.move
			match e.typ {
				.mouse_down {
					action = .down
				}
				.mouse_up {
					action = .up
				}
				.mouse_drag {
					action = .drag
				}
				.mouse_scroll {
					action = .scroll
				}
				else {}
			}
			return MouseMsg{
				x:         e.x
				y:         e.y
				button:    mouse_button_from(e.button)
				action:    action
				scroll:    scroll_from(e.direction)
				modifiers: modifiers_from(e.modifiers)
			}
		}
		.resized {
			return WindowSizeMsg{ width: e.width, height: e.height }
		}
		else {}
	}
	return NoopMsg{}
}

fn mouse_button_from(b tui.MouseButton) MouseButton {
	return match b {
		.left { .left }
		.middle { .middle }
		.right { .right }
		else { .unknown }
	}
}

fn scroll_from(d tui.Direction) ScrollDirection {
	return match d {
		.up { .up }
		.down { .down }
		.left { .left }
		.right { .right }
		else { .none }
	}
}
