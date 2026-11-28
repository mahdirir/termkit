module termkit

import context
import os
import sync
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
	ui          &tui.Context = unsafe { nil }
	queue_mutex &sync.Mutex  = unsafe { nil }
	queue       []Msg
	scheduled   []Scheduled
	renderer    ?Renderer
	next_id     int
	quitting    bool
	pasting     bool
	paste_buf   string
}

// new_program creates a Program for model.
pub fn new_program(model Model, opts ProgramOpts) Program {
	return Program{
		model:       model
		opts:        opts
		queue_mutex: sync.new_mutex()
	}
}

fn init_cb(user_data voidptr) {
	mut p := unsafe { &Program(user_data) }
	if f := p.opts.init_fn {
		f()
	}
}

// call_cleanup invokes the user's cleanup hook. It is called both when term.ui
// handles a shutdown signal and on a normal quit from frame_cb.
fn (mut p Program) call_cleanup() {
	if f := p.opts.cleanup_fn {
		f()
	}
}

fn cleanup_cb(user_data voidptr) {
	mut p := unsafe { &Program(user_data) }
	if !isnil(p.ui) {
		p.ui.write('\x1b[?2004l\x1b[?1004l')
		p.ui.flush()
	}
	if f := p.opts.cleanup_fn {
		f()
	}
}

// send queues a message for the model. It is safe to call from other threads.
pub fn (mut p Program) send(msg Msg) {
	mut delivered := msg
	if f := p.opts.filter {
		delivered = f(msg) or { return }
	}
	if isnil(p.queue_mutex) {
		p.queue << delivered
		return
	}
	mut mutex := p.queue_mutex
	mutex.lock()
	p.queue << delivered
	mutex.unlock()
}

// take_msg removes and returns the next queued message.
fn (mut p Program) take_msg() ?Msg {
	if isnil(p.queue_mutex) {
		if p.queue.len == 0 {
			return none
		}
		msg := p.queue[0]
		p.queue = p.queue[1..]
		return msg
	}
	mut mutex := p.queue_mutex
	mutex.lock()
	if p.queue.len == 0 {
		mutex.unlock()
		return none
	}
	msg := p.queue[0]
	p.queue = p.queue[1..]
	mutex.unlock()
	return msg
}

// process_queue delivers all queued messages, stopping on QuitMsg.
pub fn (mut p Program) process_queue() {
	for !p.quitting {
		msg := p.take_msg() or { break }
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
		init_fn:              init_cb
		cleanup_fn:           cleanup_cb
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
	// Ask the terminal for bracketed paste and focus-change reporting. Both
	// modes are best-effort; terminals that ignore them keep normal behaviour.
	p.ui.write('\x1b[?2004h\x1b[?1004h')
	p.ui.flush()
	p.dispatch(p.model.init())
	ctx.run()!
}

fn (mut p Program) handle(msg Msg) {
	match msg {
		PasteStartMsg {
			p.pasting = true
			p.paste_buf = ''
			return
		}
		PasteEndMsg {
			if p.pasting && p.paste_buf.len > 0 {
				p.send(PasteMsg{ text: p.paste_buf })
			}
			p.pasting = false
			p.paste_buf = ''
			return
		}
		QuitMsg {
			p.quitting = true
			return
		}
		InterruptMsg {
			// Interrupts reach the model (so it can e.g. confirm unsaved
			// work) and still stop the program afterwards.
			p.quitting = true
		}
		SuspendMsg {
			p.suspend()
			return
		}
		ResumeMsg {
			p.resume()
			return
		}
		ClearScreenMsg {
			if !isnil(p.ui) {
				p.ui.write('\x1b[2J\x1b[H')
				p.ui.flush()
			}
			p.repaint()
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
		LogMsg {
			if msg.path != '' {
				mut file := os.open_append(msg.path) or { return }
				file.writeln(msg.message) or {}
				file.close()
			}
			return
		}
		NoopMsg {
			return
		}
		WindowSizeMsg {
			p.resize_renderer(msg.width, msg.height)
		}
		else {}
	}
	if p.pasting {
		match msg {
			KeyMsg {
				text := msg.text()
				if text != '' {
					p.paste_buf += text
				} else if msg.utf8 == '\r' || msg.utf8 == '\n' || msg.utf8 == '\t' {
					// Line breaks and tabs are paste content, not key names.
					p.paste_buf += msg.utf8
				} else if !msg.is_ctrl() && !msg.is_alt() && single_rune_text(msg.key) {
					p.paste_buf += msg.key
				}
				return
			}
			else {}
		}
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
		ExecCmd {
			p.run_exec(cmd)
		}
		QueryCmd {
			if !isnil(p.ui) {
				p.ui.write(terminal_query(cmd.kind))
				p.ui.flush()
			}
		}
		ClipboardCmd {
			if !isnil(p.ui) {
				p.ui.write(osc52_encode(cmd.text))
				p.ui.flush()
			}
		}
		EnvCmd {
			mut vars := map[string]string{}
			for key in cmd.keys {
				vars[key] = os.getenv(key)
			}
			p.send(EnvMsg{ vars: vars })
		}
		CursorCmd {
			if !isnil(p.ui) {
				p.ui.write(cursor_sequences(cmd.cursor))
				p.ui.flush()
			}
		}
		TaskProgressCmd {
			if !isnil(p.ui) {
				p.ui.write(task_progress_seq(cmd.state, cmd.value))
				p.ui.flush()
			}
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
	if f := p.opts.cancel {
		if f() {
			p.quitting = true
		}
	}
	if ctx := p.opts.ctx {
		if context_cancelled(ctx) {
			p.quitting = true
		}
	}
	if p.quitting {
		// term.ui only calls its cleanup callback on signals, so a normal quit
		// would skip the program's cleanup hook and terminal restore.
		p.call_cleanup()
		if !isnil(p.ui) {
			mut restore := '\x1b[0m\x1b[?25h\x1b[?2004l\x1b[?1004l'
			if p.opts.alt_screen {
				restore += '\x1b[?1049l'
			}
			p.ui.write(restore)
			p.ui.flush()
		}
		exit(0)
	}
	if p.opts.without_renderer {
		if f := p.opts.out {
			f(p.view())
		}
		return
	}
	if isnil(p.ui) {
		return
	}
	profile := if forced := p.opts.force_profile {
		forced
	} else {
		detect_color_profile()
	}
	w := if p.ui.window_width > 0 { p.ui.window_width } else { 80 }
	h := if p.ui.window_height > 0 { p.ui.window_height } else { 24 }
	p.ui.write(p.draw_frame(profile, w, h))
	p.ui.flush()
}

// draw_frame renders the current view and returns this frame's escape
// sequences. The first call creates the renderer and includes its enter
// sequence. It is separate from frame_cb so the render path is testable.
fn (mut p Program) draw_frame(profile ColorProfile, width int, height int) string {
	mut r := p.renderer or { Renderer{} }
	mut out := ''
	if p.renderer == none {
		r = new_renderer(width, height, profile)
		r.alt_screen = p.opts.alt_screen
		out += r.enter()
		p.renderer = r
	}
	r.clear()
	r.draw_text(0, 0, p.view(), '', '', 0)
	out += r.frame()
	p.renderer = r
	return out
}

// context_cancelled reports whether ctx has been cancelled.
pub fn context_cancelled(ctx context.Context) bool {
	mut c := ctx
	return c.err() != none
}

fn (mut p Program) resize_renderer(width int, height int) {
	if width <= 0 || height <= 0 {
		return
	}
	if mut r := p.renderer {
		r.resize(width, height)
		p.renderer = r
	}
}

// repaint discards the diff baseline so the next frame redraws every cell.
pub fn (mut p Program) repaint() {
	if mut r := p.renderer {
		blank := Cell{}
		for i in 0 .. r.prev.len {
			r.prev[i] = blank
		}
		p.renderer = r
	}
}

// suspend leaves the alternate screen and restores the terminal cursor.
pub fn (mut p Program) suspend() {
	if isnil(p.ui) {
		return
	}
	if p.opts.alt_screen {
		p.ui.write('\x1b[?1049l')
	}
	p.ui.show_cursor()
	p.ui.flush()
}

// resume re-enters the alternate screen and forces a full repaint.
pub fn (mut p Program) resume() {
	if isnil(p.ui) {
		return
	}
	if p.opts.alt_screen {
		p.ui.write('\x1b[?1049h')
	}
	p.ui.hide_cursor()
	p.ui.flush()
	p.repaint()
}

// release_terminal leaves the alternate screen and restores the terminal
// cursor. It is the user-driven form of suspend for e.g. `$EDITOR`
// invocations; restore_terminal re-enters the program.
pub fn (mut p Program) release_terminal() {
	p.suspend()
}

// restore_terminal re-enters the alternate screen after release_terminal.
pub fn (mut p Program) restore_terminal() {
	p.resume()
}

// run_exec suspends the terminal, runs the command synchronously, restores
// the terminal and queues the result as an ExecDoneMsg.
fn (mut p Program) run_exec(cmd ExecCmd) {
	p.suspend()
	mut argv := [cmd.path]
	argv << cmd.args
	res := os.exec(argv)
	p.resume()
	p.send(ExecDoneMsg{
		id:        cmd.id
		path:      cmd.path
		exit_code: res.exit_code
		output:    res.output
	})
}

// is_repeat_report recognises a CSI-u key report with event type 3 (repeat).
fn is_repeat_report(raw string) bool {
	return raw.starts_with('\x1b[') && raw.ends_with('u') && raw.contains(':3')
}

fn msg_from_event(e &tui.Event) Msg {
	if e.typ == .key_down || e.typ == .key_up {
		// term.ui passes unrecognised escape sequences through in utf8. That
		// lets termkit support bracketed paste and focus reports without
		// changing the stdlib input layer.
		match e.utf8 {
			'\x1b[200~' {
				return PasteStartMsg{}
			}
			'\x1b[201~' {
				return PasteEndMsg{}
			}
			'\x1b[I' {
				return FocusMsg{}
			}
			'\x1b[O' {
				return BlurMsg{}
			}
			else {}
		}
	}
	match e.typ {
		.key_down, .key_up {
			kind := if e.typ == .key_up {
				KeyEventKind.release
			} else if is_repeat_report(e.utf8) {
				KeyEventKind.repeat
			} else {
				KeyEventKind.press
			}
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
