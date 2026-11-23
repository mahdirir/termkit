# MVU guide

termkit follows the Model / View / Update shape popularised by Bubble Tea.
State lives in a model, events arrive as messages, and side effects are
requested by returning a command.

## The Model interface

A model implements three methods on a mutable pointer receiver:

```v ignore
pub interface Model {
mut:
	init() Cmd
	update(Msg) (Model, Cmd)
	view() string
}
```

- `init` returns the command to run once when the program starts.
- `update` receives a `Msg`, mutates the model and returns the next model plus
  a command. Return `termkit.no_cmd` when there is no follow-up work.
- `view` returns the frame text. It is called once per frame by the runtime and
  drawn through the diffing renderer.

Messages are any type implementing the empty `Msg` interface. Built-in
messages include:

| Message | Meaning |
| --- | --- |
| `KeyMsg` | A key press, repeat or release |
| `MouseMsg` | Mouse click, movement, drag or scroll |
| `WindowSizeMsg` | Terminal resize; carries `width` and `height` |
| `PasteMsg` | Bracketed paste text as one message |
| `FocusMsg` / `BlurMsg` | Terminal gained or lost focus |
| `TickMsg` | Produced by `tick` or `every`; carries `id` and `at` |
| `ErrorMsg` | An error a model may display |
| `QuitMsg` | Stops the program |
| `NoopMsg` | Input the runtime could not translate |

`KeyMsg` exposes `key`, `code`, `modifiers`, `kind` and `utf8`, plus helpers
`is_ctrl()`, `is_shift()`, `is_alt()` and `is_press()`. Use the key constants
(`termkit.key_up`, `key_enter`, `key_tab`, `key_ctrl_c`, and so on) instead of
literal key names where possible.

## Commands

A `Cmd` is a value describing side effects, not a bare closure. V keeps
closure contexts alive for the whole process, so capturing a fresh closure on
every keystroke would leak. Use these constructors:

| Constructor | Effect |
| --- | --- |
| `termkit.no_cmd` | Do nothing |
| `termkit.msg_cmd(msg)` | Deliver `msg` to the model |
| `termkit.cmd_fn(f)` | Call a non-capturing `fn () Msg` |
| `termkit.batch(c1, c2, ...)` | Run commands in any order |
| `termkit.sequence(c1, c2, ...)` | Run commands in order |
| `termkit.tick(id, d, produce)` | Deliver one message after duration `d` |
| `termkit.every(id, d, produce)` | Deliver a message on each interval `d` |

`batch_array` and `sequence_array` take a `[]Cmd`. The timer callbacks have
the signature `fn (i64) Msg` and receive the timestamp at which the message
was produced:

```v ignore
import termkit
import time

fn tick_message(at i64) termkit.Msg {
	return termkit.TickMsg{ id: 7, at: at }
}

fn start_timer() termkit.Cmd {
	return termkit.every(7, 100 * time.millisecond, tick_message)
}
```

Always use `cmd_fn` rather than relying on implicit coercion of a function to
`Cmd`: coercion in an argument position can lose the variant tag.

Convenience commands built on `msg_cmd`:

- `termkit.quit()` — stop the program.
- `termkit.set_window_title(title)` — change the terminal title.
- `termkit.write_line(text)` — write a line outside the rendered frame.
- `termkit.log_to_file(path, message)` — append a line to a log file.

`termkit.delivered_msgs(cmd)` returns the messages a command would deliver
without running timers; it is handy in tests.

## Program options

Pass options to `termkit.new_program(model, opts)`:

| Field | Default | Purpose |
| --- | --- | --- |
| `alt_screen` | `true` | Use the terminal alternate buffer |
| `mouse` | `false` | Enable mouse tracking |
| `capture_events` | `true` | Raw mode for control keys |
| `window_title` | `''` | Initial terminal title |
| `fps` | `60` | Frame rate (values <= 0 fall back to 60) |
| `hide_cursor` | `true` | Hide the cursor while running |
| `without_renderer` | `false` | Process messages but write no frame |
| `out` | none | `fn (string)` receiving `view()` when headless |
| `cancel` | none | `fn () bool` checked each frame; true stops |
| `ctx` | none | `context.Context`; cancellation stops the program |
| `init_fn` | none | `fn ()` run once after term.ui starts |
| `cleanup_fn` | none | `fn ()` run before terminal restore |
| `filter` | none | `fn (Msg) ?Msg` drop/transform messages |

## Sending messages from threads

`Program.send` is mutex-protected and safe to call from spawned threads. Take
a pointer to the program and call `send` on that pointer:

```v ignore
ptr := &program
go ptr.send(termkit.KeyMsg{ key: 'i' })
```

Queued messages are delivered by `process_queue()`, which the runtime calls
once per frame. In headless code you can call `process_queue()` yourself.

## Filters

A filter runs inside `send`, before the message is queued. Return `none` to
drop a message, or return a message to replace it:

```v ignore
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

mut p := termkit.new_program(model, termkit.ProgramOpts{
	without_renderer: true
	filter:           drop_noop
})
```

## Lifecycle hooks

`init_fn` runs once after term.ui is initialised. `cleanup_fn` runs both on a
normal `quit()` and on a shutdown signal; on a normal quit the runtime also
emits the reset, cursor-show and alternate-screen-leave sequences. `cancel`
and `ctx` offer an additional per-frame way to stop. `Program.suspend()`,
`resume()` and `repaint()` are available for external editors or screen
changes.

## Paste, focus and repeat

term.ui passes unrecognised escape sequences through in `Event.utf8`, so no
stdlib patching is needed. On startup the runtime requests bracketed paste and
focus reporting; terminals that ignore the request keep normal behaviour.

- Paste markers `CSI 200 ~` / `CSI 201 ~` are accumulated and delivered to the
  model as a single `PasteMsg`. `TextInput` and `TextArea` accept it.
- `CSI I` and `CSI O` become `FocusMsg` and `BlurMsg`. For focus between
  widgets use `FocusGroup`; its Tab routing is independent of the terminal.
- CSI-u reports with event type 3 arrive as `KeyMsg` with `kind == .repeat`;
  type 2 reports become `.release`.

Windows' native console API does not report these sequences; Windows Terminal
with the modes enabled is expected to work.

See [Testing guide](testing-guide.md) for driving a model without a TTY.
