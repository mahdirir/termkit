module termkit

import time

// NoCmd asks the runtime for no follow-up work.
pub struct NoCmd {}

// MsgCmd delivers an already-built message.
pub struct MsgCmd {
pub:
	msg Msg
}

// CmdFn computes a message when the runtime dispatches it. Only non-capturing
// functions should be used here: V keeps closure contexts alive for the whole
// process.
pub type CmdFn = fn () Msg

// BatchCmd runs its commands without a guaranteed order.
pub struct BatchCmd {
pub:
	cmds []Cmd
}

// SequenceCmd runs its commands in declaration order.
pub struct SequenceCmd {
pub:
	cmds []Cmd
}

// TickCmd delivers a message once after a delay.
pub struct TickCmd {
pub:
	id      int
	delay   time.Duration
	produce fn (i64) Msg = unsafe { nil }
}

// EveryCmd delivers a message on every interval.
pub struct EveryCmd {
pub:
	id      int
	delay   time.Duration
	produce fn (i64) Msg = unsafe { nil }
}

// Cmd is a request for side effects from an update. It is a sum type rather
// than a bare function so that messages and timers remain ordinary values.
pub type Cmd = NoCmd | MsgCmd | CmdFn | BatchCmd | SequenceCmd | TickCmd | EveryCmd

// no_cmd is the command that does nothing.
pub const no_cmd = Cmd(NoCmd{})

// msg_cmd builds a command that delivers msg.
pub fn msg_cmd(msg Msg) Cmd {
	return Cmd(MsgCmd{ msg: msg })
}

// cmd_fn wraps a non-capturing function as a command.
//
// Always use this constructor instead of relying on implicit coercion to Cmd:
// coercion in an argument position can lose the variant tag.
pub fn cmd_fn(f fn () Msg) Cmd {
	return Cmd(CmdFn(f))
}

// batch runs the given commands without a guaranteed order.
pub fn batch(cmds ...Cmd) Cmd {
	return Cmd(BatchCmd{ cmds: cmds })
}

// batch_array is batch, taking an array of commands.
pub fn batch_array(cmds []Cmd) Cmd {
	return Cmd(BatchCmd{ cmds: cmds })
}

// sequence runs the given commands in order.
pub fn sequence(cmds ...Cmd) Cmd {
	return Cmd(SequenceCmd{ cmds: cmds })
}

// sequence_array is sequence, taking an array of commands.
pub fn sequence_array(cmds []Cmd) Cmd {
	return Cmd(SequenceCmd{ cmds: cmds })
}

// tick produces one message after d has elapsed. The callback receives the
// timestamp at which the message is generated.
pub fn tick(id int, d time.Duration, produce fn (i64) Msg) Cmd {
	return Cmd(TickCmd{ id: id, delay: d, produce: produce })
}

// every produces a message on every interval d.
pub fn every(id int, d time.Duration, produce fn (i64) Msg) Cmd {
	return Cmd(EveryCmd{ id: id, delay: d, produce: produce })
}

// quit asks the runtime to stop the program.
pub fn quit() Cmd {
	return msg_cmd(QuitMsg{})
}

// set_window_title asks the runtime to change the terminal title.
pub fn set_window_title(title string) Cmd {
	return msg_cmd(TitleMsg{ title: title })
}

// write_line asks the runtime to write a line outside the rendered frame.
pub fn write_line(text string) Cmd {
	return msg_cmd(WriteLineMsg{ text: text })
}

// call_cmd_fn invokes a CmdFn. Going through a parameter avoids the unreliable
// result of calling a function value straight out of a sum-type match arm.
fn call_cmd_fn(f CmdFn) Msg {
	return f()
}

// delivered_msgs returns the messages a command would deliver without running
// timers or command functions. It is useful for asserting model transitions.
pub fn delivered_msgs(cmd Cmd) []Msg {
	mut out := []Msg{}
	collect_delivered_msgs(cmd, mut out, 0)
	return out
}

fn collect_delivered_msgs(cmd Cmd, mut out []Msg, depth int) {
	if depth > 32 {
		return
	}
	match cmd {
		NoCmd {}
		MsgCmd {
			out << cmd.msg
		}
		CmdFn {}
		BatchCmd {
			for inner in cmd.cmds {
				collect_delivered_msgs(inner, mut out, depth + 1)
			}
		}
		SequenceCmd {
			for inner in cmd.cmds {
				collect_delivered_msgs(inner, mut out, depth + 1)
			}
		}
		TickCmd {}
		EveryCmd {}
	}
}
