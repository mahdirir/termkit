module termkit

import encoding.base64

// QueryKind selects a terminal query. Responses arrive as raw escape reports
// and are not decoded yet; queries are useful for capability probing.
pub enum QueryKind {
	device_attrs
	bg_color
	fg_color
	cursor_pos
}

// terminal_query builds the escape sequence for a terminal query.
pub fn terminal_query(kind QueryKind) string {
	return match kind {
		.device_attrs { '\x1b[c' }
		.bg_color { '\x1b]11;?\x1b\\' }
		.fg_color { '\x1b]10;?\x1b\\' }
		.cursor_pos { '\x1b[6n' }
	}
}

// query_terminal asks the terminal a capability question. The reply, if any,
// arrives as raw input.
pub fn query_terminal(kind QueryKind) Cmd {
	return Cmd(QueryCmd{ kind: kind })
}

// QueryCmd writes a terminal query sequence.
pub struct QueryCmd {
pub:
	kind QueryKind
}

// osc52_encode wraps text in an OSC52 clipboard-write sequence.
pub fn osc52_encode(text string) string {
	return '\x1b]52;c;' + base64.encode_str(text) + '\x1b\\'
}

// copy_to_clipboard writes text to the terminal clipboard via OSC52.
pub fn copy_to_clipboard(text string) Cmd {
	return Cmd(ClipboardCmd{ text: text })
}

// ClipboardCmd writes its text to the clipboard.
pub struct ClipboardCmd {
pub:
	text string
}

// ClipboardMsg carries text read from the clipboard. Terminal replies to
// clipboard reads are not decoded yet.
pub struct ClipboardMsg {
pub:
	text string
}

// EnvMsg carries environment variables captured by read_env.
pub struct EnvMsg {
pub:
	vars map[string]string
}

// EnvCmd captures environment variables into an EnvMsg.
pub struct EnvCmd {
pub:
	keys []string
}

// read_env captures the listed environment variables into an EnvMsg.
pub fn read_env(keys []string) Cmd {
	return Cmd(EnvCmd{ keys: keys })
}

// CursorShape selects the terminal cursor shape (DECSCUSR).
pub enum CursorShape {
	block
	underline
	bar
}

// Cursor describes a terminal cursor: position, color, shape and blink.
pub struct Cursor {
pub:
	x     int
	y     int
	color string
	shape CursorShape = .block
	blink bool
}

// cursor_sequences builds the escape sequences for a cursor: position,
// DECSCUSR shape and OSC 12 color. Empty color skips the color sequence.
pub fn cursor_sequences(c Cursor) string {
	mut out := '\x1b[${c.y + 1};${c.x + 1}H'
	shape_n := match c.shape {
		.block {
			if c.blink { 1 } else { 2 }
		}
		.underline {
			if c.blink { 3 } else { 4 }
		}
		.bar {
			if c.blink { 5 } else { 6 }
		}
	}
	out += '\x1b[${shape_n} q'
	if c.color != '' {
		out += '\x1b]12;${c.color}\x1b\\'
	}
	return out
}

// set_cursor moves the terminal cursor and sets its shape and color.
pub fn set_cursor(c Cursor) Cmd {
	return Cmd(CursorCmd{ cursor: c })
}

// CursorCmd applies a cursor description to the terminal.
pub struct CursorCmd {
pub:
	cursor Cursor
}

// task_progress_seq builds the task progress sequence (state 0-4, value
// 0-100): 0 removes progress, 1 is normal, 2 is error, 3 is indeterminate,
// 4 is paused.
pub fn task_progress_seq(state int, value int) string {
	v := if value < 0 {
		0
	} else if value > 100 {
		100
	} else {
		value
	}
	s := if state < 0 {
		0
	} else if state > 4 {
		4
	} else {
		state
	}
	return '\x1b]9;4;${s};${v}\x1b\\'
}

// set_task_progress reports OS-level task progress (taskbar/dock).
pub fn set_task_progress(state int, value int) Cmd {
	return Cmd(TaskProgressCmd{ state: state, value: value })
}

// TaskProgressCmd writes a task progress sequence.
pub struct TaskProgressCmd {
pub:
	state int
	value int
}
