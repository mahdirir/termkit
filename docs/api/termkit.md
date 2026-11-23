# module termkit


## Contents
- [Constants](#Constants)
- [batch](#batch)
- [batch_array](#batch_array)
- [cmd_fn](#cmd_fn)
- [color_profile_from_env](#color_profile_from_env)
- [context_cancelled](#context_cancelled)
- [delivered_msgs](#delivered_msgs)
- [detect_color_profile](#detect_color_profile)
- [every](#every)
- [key_for_event](#key_for_event)
- [key_name](#key_name)
- [log_to_file](#log_to_file)
- [modifiers_from](#modifiers_from)
- [msg_cmd](#msg_cmd)
- [new_program](#new_program)
- [new_renderer](#new_renderer)
- [quit](#quit)
- [rgb_to_ansi256](#rgb_to_ansi256)
- [rgb_to_basic](#rgb_to_basic)
- [sequence](#sequence)
- [sequence_array](#sequence_array)
- [set_window_title](#set_window_title)
- [tick](#tick)
- [write_line](#write_line)
- [ColorProfile.from](#ColorProfile.from)
- [KeyEventKind.from](#KeyEventKind.from)
- [Modifiers.from](#Modifiers.from)
- [Modifiers.zero](#Modifiers.zero)
- [MouseAction.from](#MouseAction.from)
- [MouseButton.from](#MouseButton.from)
- [ScrollDirection.from](#ScrollDirection.from)
- [Model](#Model)
- [Msg](#Msg)
- [Cmd](#Cmd)
- [CmdFn](#CmdFn)
- [ColorProfile](#ColorProfile)
- [KeyEventKind](#KeyEventKind)
- [Modifiers](#Modifiers)
  - [is_empty](#is_empty)
  - [has](#has)
  - [all](#all)
  - [set](#set)
  - [set_all](#set_all)
  - [clear](#clear)
  - [clear_all](#clear_all)
  - [toggle](#toggle)
- [MouseAction](#MouseAction)
- [MouseButton](#MouseButton)
- [ScrollDirection](#ScrollDirection)
- [BatchCmd](#BatchCmd)
- [BlurMsg](#BlurMsg)
- [ErrorMsg](#ErrorMsg)
- [EveryCmd](#EveryCmd)
- [FocusMsg](#FocusMsg)
- [KeyBinding](#KeyBinding)
- [KeyMap](#KeyMap)
  - [bind](#bind)
  - [resolve](#resolve)
  - [resolve_msg](#resolve_msg)
  - [help](#help)
- [KeyMsg](#KeyMsg)
  - [is_ctrl](#is_ctrl)
  - [is_shift](#is_shift)
  - [is_alt](#is_alt)
  - [is_press](#is_press)
- [LogMsg](#LogMsg)
- [MouseMsg](#MouseMsg)
- [MsgCmd](#MsgCmd)
- [NoCmd](#NoCmd)
- [NoopMsg](#NoopMsg)
- [PasteEndMsg](#PasteEndMsg)
- [PasteMsg](#PasteMsg)
- [PasteStartMsg](#PasteStartMsg)
- [Program](#Program)
  - [send](#send)
  - [process_queue](#process_queue)
  - [view](#view)
  - [run](#run)
  - [repaint](#repaint)
  - [suspend](#suspend)
  - [resume](#resume)
- [ProgramOpts](#ProgramOpts)
- [QuitMsg](#QuitMsg)
- [Renderer](#Renderer)
  - [resize](#resize)
  - [clear](#clear)
  - [set_cell](#set_cell)
  - [draw_text](#draw_text)
  - [frame](#frame)
  - [enter](#enter)
  - [leave](#leave)
- [SequenceCmd](#SequenceCmd)
- [TickCmd](#TickCmd)
- [TickMsg](#TickMsg)
- [TitleMsg](#TitleMsg)
- [WindowSizeMsg](#WindowSizeMsg)
- [WriteLineMsg](#WriteLineMsg)

## Constants
```v ignore
const no_cmd = Cmd(NoCmd{})
```

no_cmd is the command that does nothing.

[[Return to contents]](#Contents)

```v ignore
const key_enter = 'enter'
```

key_enter is the name of the Enter key.

[[Return to contents]](#Contents)

```v ignore
const key_tab = 'tab'
```

key_tab is the name of the Tab key.

[[Return to contents]](#Contents)

```v ignore
const key_esc = 'esc'
```

key_esc is the name of the Escape key.

[[Return to contents]](#Contents)

```v ignore
const key_space = ' '
```

key_space is the name of the Space key.

[[Return to contents]](#Contents)

```v ignore
const key_backspace = 'backspace'
```

key_backspace is the name of the Backspace key.

[[Return to contents]](#Contents)

```v ignore
const key_delete = 'delete'
```

key_delete is the name of the Delete key.

[[Return to contents]](#Contents)

```v ignore
const key_up = 'up'
```

key_up is the name of the Up arrow.

[[Return to contents]](#Contents)

```v ignore
const key_down = 'down'
```

key_down is the name of the Down arrow.

[[Return to contents]](#Contents)

```v ignore
const key_left = 'left'
```

key_left is the name of the Left arrow.

[[Return to contents]](#Contents)

```v ignore
const key_right = 'right'
```

key_right is the name of the Right arrow.

[[Return to contents]](#Contents)

```v ignore
const key_home = 'home'
```

key_home is the name of the Home key.

[[Return to contents]](#Contents)

```v ignore
const key_end = 'end'
```

key_end is the name of the End key.

[[Return to contents]](#Contents)

```v ignore
const key_page_up = 'pgup'
```

key_page_up is the name of the Page Up key.

[[Return to contents]](#Contents)

```v ignore
const key_page_down = 'pgdown'
```

key_page_down is the name of the Page Down key.

[[Return to contents]](#Contents)

```v ignore
const key_insert = 'insert'
```

key_insert is the name of the Insert key.

[[Return to contents]](#Contents)

```v ignore
const key_ctrl_c = 'ctrl+c'
```

key_ctrl_c is the name of the Ctrl+C key combination.

[[Return to contents]](#Contents)

```v ignore
const attr_bold = u8(1)
```

attr_bold marks a cell as bold.

[[Return to contents]](#Contents)

```v ignore
const attr_italic = u8(2)
```

attr_italic marks a cell as italic.

[[Return to contents]](#Contents)

```v ignore
const attr_underline = u8(4)
```

attr_underline marks a cell as underlined.

[[Return to contents]](#Contents)

```v ignore
const attr_reverse = u8(8)
```

attr_reverse marks a cell as reverse video.

[[Return to contents]](#Contents)

## batch
```v ignore
fn batch(cmds ...Cmd) Cmd
```

batch runs the given commands without a guaranteed order.

[[Return to contents]](#Contents)

## batch_array
```v ignore
fn batch_array(cmds []Cmd) Cmd
```

batch_array is batch, taking an array of commands.

[[Return to contents]](#Contents)

## cmd_fn
```v ignore
fn cmd_fn(f fn () Msg) Cmd
```

cmd_fn wraps a non-capturing function as a command.

Always use this constructor instead of relying on implicit coercion to Cmd: coercion in an argument
position can lose the variant tag.

[[Return to contents]](#Contents)

## color_profile_from_env
```v ignore
fn color_profile_from_env(no_color string, colorterm string, term_name string) ColorProfile
```

color_profile_from_env derives a profile from the usual environment variables. Keeping this pure
makes it testable without touching the process environment.

[[Return to contents]](#Contents)

## context_cancelled
```v ignore
fn context_cancelled(ctx context.Context) bool
```

context_cancelled reports whether ctx has been cancelled.

[[Return to contents]](#Contents)

## delivered_msgs
```v ignore
fn delivered_msgs(cmd Cmd) []Msg
```

delivered_msgs returns the messages a command would deliver without running timers or command
functions. It is useful for asserting model transitions.

[[Return to contents]](#Contents)

## detect_color_profile
```v ignore
fn detect_color_profile() ColorProfile
```

detect_color_profile reads the process environment and returns the profile.

[[Return to contents]](#Contents)

## every
```v ignore
fn every(id int, d time.Duration, produce fn (i64) Msg) Cmd
```

every produces a message on every interval d.

[[Return to contents]](#Contents)

## key_for_event
```v ignore
fn key_for_event(e &tui.Event) string
```

key_for_event returns the key name carried by a term.ui event. Text events are preferred so UTF-8
input is preserved.

[[Return to contents]](#Contents)

## key_name
```v ignore
fn key_name(code tui.KeyCode) string
```

key_name converts a term.ui key code to a stable name.

Printable ASCII is returned as the character itself. Special keys use the short names above, and
function keys use `f1` through `f24`.

[[Return to contents]](#Contents)

## log_to_file
```v ignore
fn log_to_file(path string, message string) Cmd
```

log_to_file asks the runtime to append message to a log file.

[[Return to contents]](#Contents)

## modifiers_from
```v ignore
fn modifiers_from(m tui.Modifiers) Modifiers
```

modifiers_from converts term.ui modifiers to termkit modifiers.

[[Return to contents]](#Contents)

## msg_cmd
```v ignore
fn msg_cmd(msg Msg) Cmd
```

msg_cmd builds a command that delivers msg.

[[Return to contents]](#Contents)

## new_program
```v ignore
fn new_program(model Model, opts ProgramOpts) Program
```

new_program creates a Program for model.

[[Return to contents]](#Contents)

## new_renderer
```v ignore
fn new_renderer(width int, height int, profile ColorProfile) Renderer
```

new_renderer creates a blank renderer of the given size.

[[Return to contents]](#Contents)

## quit
```v ignore
fn quit() Cmd
```

quit asks the runtime to stop the program.

[[Return to contents]](#Contents)

## rgb_to_ansi256
```v ignore
fn rgb_to_ansi256(r int, g int, b int) u8
```

rgb_to_ansi256 maps a 24-bit color to the xterm 256-color cube and greys.

[[Return to contents]](#Contents)

## rgb_to_basic
```v ignore
fn rgb_to_basic(r int, g int, b int) u8
```

rgb_to_basic maps a 24-bit color to one of the eight ANSI base colors.

[[Return to contents]](#Contents)

## sequence
```v ignore
fn sequence(cmds ...Cmd) Cmd
```

sequence runs the given commands in order.

[[Return to contents]](#Contents)

## sequence_array
```v ignore
fn sequence_array(cmds []Cmd) Cmd
```

sequence_array is sequence, taking an array of commands.

[[Return to contents]](#Contents)

## set_window_title
```v ignore
fn set_window_title(title string) Cmd
```

set_window_title asks the runtime to change the terminal title.

[[Return to contents]](#Contents)

## tick
```v ignore
fn tick(id int, d time.Duration, produce fn (i64) Msg) Cmd
```

tick produces one message after d has elapsed. The callback receives the timestamp at which the
message is generated.

[[Return to contents]](#Contents)

## write_line
```v ignore
fn write_line(text string) Cmd
```

write_line asks the runtime to write a line outside the rendered frame.

[[Return to contents]](#Contents)

## ColorProfile.from
```v ignore
fn ColorProfile.from[W](input W) !ColorProfile
```

from returns the `ColorProfile` value of an integer or of a field name, or an error if there is
none.

[[Return to contents]](#Contents)

## KeyEventKind.from
```v ignore
fn KeyEventKind.from[W](input W) !KeyEventKind
```

from returns the `KeyEventKind` value of an integer or of a field name, or an error if there is
none.

[[Return to contents]](#Contents)

## Modifiers.from
```v ignore
fn Modifiers.from[W](input W) !Modifiers
```

from returns the `Modifiers` value of an integer or of a field name, or an error if there is none.

[[Return to contents]](#Contents)

## Modifiers.zero
```v ignore
fn Modifiers.zero() Modifiers
```

zero returns a `Modifiers` value with no flags set.

[[Return to contents]](#Contents)

## MouseAction.from
```v ignore
fn MouseAction.from[W](input W) !MouseAction
```

from returns the `MouseAction` value of an integer or of a field name, or an error if there is none.

[[Return to contents]](#Contents)

## MouseButton.from
```v ignore
fn MouseButton.from[W](input W) !MouseButton
```

from returns the `MouseButton` value of an integer or of a field name, or an error if there is none.

[[Return to contents]](#Contents)

## ScrollDirection.from
```v ignore
fn ScrollDirection.from[W](input W) !ScrollDirection
```

from returns the `ScrollDirection` value of an integer or of a field name, or an error if there is
none.

[[Return to contents]](#Contents)

## Model
```v ignore
interface Model {
mut:
	init() Cmd
	update(Msg) (Model, Cmd)
	view() string
}
```

Model is the state of an MVU program. init returns the first command, update handles a message and
returns the next model plus a command, and view renders the current state.

[[Return to contents]](#Contents)

## Msg
```v ignore
interface Msg {}
```

Msg is the marker interface for everything that can be delivered to a model's update method. Any
type that implements it can be sent.

[[Return to contents]](#Contents)

## Cmd
```v ignore
type Cmd = NoCmd | MsgCmd | CmdFn | BatchCmd | SequenceCmd | TickCmd | EveryCmd
```

Cmd is a request for side effects from an update. It is a sum type rather than a bare function so
that messages and timers remain ordinary values.

[[Return to contents]](#Contents)

## CmdFn
```v ignore
type CmdFn = fn () Msg
```

CmdFn computes a message when the runtime dispatches it. Only non-capturing functions should be used
here: V keeps closure contexts alive for the whole process.

[[Return to contents]](#Contents)

## ColorProfile
```v ignore
enum ColorProfile {
	ascii
	ansi
	ansi256
	truecolor
}
```

ColorProfile describes how much color a terminal supports.

[[Return to contents]](#Contents)

## KeyEventKind
```v ignore
enum KeyEventKind {
	press
	release
	repeat
}
```

KeyEventKind distinguishes presses from releases and auto-repeat events.

[[Return to contents]](#Contents)

## Modifiers
```v ignore
@[flag]
enum Modifiers {
	ctrl
	shift
	alt
}
```

Modifiers records the control keys held during a key or mouse event. Modifiers records the control
keys held during a key or mouse event.

[[Return to contents]](#Contents)

## is_empty
```v ignore
fn (e &Modifiers) is_empty() bool
```

is_empty returns true if no flags are set.

[[Return to contents]](#Contents)

## has
```v ignore
fn (e &Modifiers) has(flag Modifiers) bool
```

has returns true if any of the flags in `flag` are set.

[[Return to contents]](#Contents)

## all
```v ignore
fn (e &Modifiers) all(flag Modifiers) bool
```

all returns true if all the flags in `flag` are set.

[[Return to contents]](#Contents)

## set
```v ignore
fn (mut e Modifiers) set(flag Modifiers)
```

set sets the flags in `flag`.

[[Return to contents]](#Contents)

## set_all
```v ignore
fn (mut e Modifiers) set_all()
```

set_all sets all the flags.

[[Return to contents]](#Contents)

## clear
```v ignore
fn (mut e Modifiers) clear(flag Modifiers)
```

clear clears the flags in `flag`.

[[Return to contents]](#Contents)

## clear_all
```v ignore
fn (mut e Modifiers) clear_all()
```

clear_all clears all the flags.

[[Return to contents]](#Contents)

## toggle
```v ignore
fn (mut e Modifiers) toggle(flag Modifiers)
```

toggle flips the flags in `flag`.

[[Return to contents]](#Contents)

## MouseAction
```v ignore
enum MouseAction {
	down
	up
	move
	drag
	scroll
}
```

MouseAction describes what a MouseMsg represents.

[[Return to contents]](#Contents)

## MouseButton
```v ignore
enum MouseButton {
	unknown
	left
	middle
	right
}
```

MouseButton identifies which button was involved in a mouse event.

[[Return to contents]](#Contents)

## ScrollDirection
```v ignore
enum ScrollDirection {
	none
	up
	down
	left
	right
}
```

ScrollDirection is the direction of a mouse scroll event.

[[Return to contents]](#Contents)

## BatchCmd
```v ignore
struct BatchCmd {
pub:
	cmds []Cmd
}
```

BatchCmd runs its commands without a guaranteed order.

[[Return to contents]](#Contents)

## BlurMsg
```v ignore
struct BlurMsg {}
```

BlurMsg is delivered when the terminal loses focus.

[[Return to contents]](#Contents)

## ErrorMsg
```v ignore
struct ErrorMsg {
pub:
	message string
}
```

ErrorMsg carries an error that a model may want to display.

[[Return to contents]](#Contents)

## EveryCmd
```v ignore
struct EveryCmd {
pub:
	id      int
	delay   time.Duration
	produce fn (i64) Msg = unsafe { nil }
}
```

EveryCmd delivers a message on every interval.

[[Return to contents]](#Contents)

## FocusMsg
```v ignore
struct FocusMsg {}
```

FocusMsg is delivered when the terminal gains focus.

[[Return to contents]](#Contents)

## KeyBinding
```v ignore
struct KeyBinding {
pub:
	key         string
	modifiers   Modifiers
	description string
	cmd         Cmd
}
```

KeyBinding associates a key and modifier set with a command.

[[Return to contents]](#Contents)

## KeyMap
```v ignore
struct KeyMap {
pub mut:
	bindings []KeyBinding
}
```

KeyMap is a collection of key bindings.

[[Return to contents]](#Contents)

## bind
```v ignore
fn (mut m KeyMap) bind(key string, modifiers Modifiers, description string, cmd Cmd)
```

bind adds a binding to the map.

[[Return to contents]](#Contents)

## resolve
```v ignore
fn (m KeyMap) resolve(key string, modifiers Modifiers) ?Cmd
```

resolve returns the command for a key and modifier set.

[[Return to contents]](#Contents)

## resolve_msg
```v ignore
fn (m KeyMap) resolve_msg(msg KeyMsg) ?Cmd
```

resolve_msg returns the command bound to a key message.

[[Return to contents]](#Contents)

## help
```v ignore
fn (m KeyMap) help() string
```

help renders the bindings as a compact list.

[[Return to contents]](#Contents)

## KeyMsg
```v ignore
struct KeyMsg {
pub:
	key       string
	code      int
	modifiers Modifiers
	kind      KeyEventKind
	utf8      string
}
```

KeyMsg is delivered for a key press, release or repeat.

[[Return to contents]](#Contents)

## is_ctrl
```v ignore
fn (m KeyMsg) is_ctrl() bool
```

is_ctrl reports whether ctrl was held for this key event.

[[Return to contents]](#Contents)

## is_shift
```v ignore
fn (m KeyMsg) is_shift() bool
```

is_shift reports whether shift was held for this key event.

[[Return to contents]](#Contents)

## is_alt
```v ignore
fn (m KeyMsg) is_alt() bool
```

is_alt reports whether alt was held for this key event.

[[Return to contents]](#Contents)

## is_press
```v ignore
fn (m KeyMsg) is_press() bool
```

is_press reports whether this is a key press rather than a release.

[[Return to contents]](#Contents)

## LogMsg
```v ignore
struct LogMsg {
pub:
	path    string
	message string
}
```

LogMsg asks the runtime to append a line to a log file. File logging is useful in TUI apps where
stdout is reserved for the rendered frame.

[[Return to contents]](#Contents)

## MouseMsg
```v ignore
struct MouseMsg {
pub:
	x         int
	y         int
	button    MouseButton
	action    MouseAction
	scroll    ScrollDirection
	modifiers Modifiers
}
```

MouseMsg is delivered for mouse activity.

[[Return to contents]](#Contents)

## MsgCmd
```v ignore
struct MsgCmd {
pub:
	msg Msg
}
```

MsgCmd delivers an already-built message.

[[Return to contents]](#Contents)

## NoCmd
```v ignore
struct NoCmd {}
```

NoCmd asks the runtime for no follow-up work.

[[Return to contents]](#Contents)

## NoopMsg
```v ignore
struct NoopMsg {}
```

NoopMsg is produced for input the runtime does not translate. Models can safely ignore it.

[[Return to contents]](#Contents)

## PasteEndMsg
```v ignore
struct PasteEndMsg {}
```

PasteEndMsg marks the end of a bracketed paste.

[[Return to contents]](#Contents)

## PasteMsg
```v ignore
struct PasteMsg {
pub:
	text string
}
```

PasteMsg carries text that arrived as a single bracketed paste.

[[Return to contents]](#Contents)

## PasteStartMsg
```v ignore
struct PasteStartMsg {}
```

PasteStartMsg marks the start of a bracketed paste. The runtime consumes it and accumulates
following key events into a single PasteMsg.

[[Return to contents]](#Contents)

## Program
```v ignore
struct Program {
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
```

Program drives a Model using term.ui for input and output.

[[Return to contents]](#Contents)

## send
```v ignore
fn (mut p Program) send(msg Msg)
```

send queues a message for the model. It is safe to call from other threads.

[[Return to contents]](#Contents)

## process_queue
```v ignore
fn (mut p Program) process_queue()
```

process_queue delivers all queued messages, stopping on QuitMsg.

[[Return to contents]](#Contents)

## view
```v ignore
fn (mut p Program) view() string
```

view renders the current model state.

[[Return to contents]](#Contents)

## run
```v ignore
fn (mut p Program) run() !
```

run sets up term.ui, schedules the init command and starts the event loop.

[[Return to contents]](#Contents)

## repaint
```v ignore
fn (mut p Program) repaint()
```

repaint discards the diff baseline so the next frame redraws every cell.

[[Return to contents]](#Contents)

## suspend
```v ignore
fn (mut p Program) suspend()
```

suspend leaves the alternate screen and restores the terminal cursor.

[[Return to contents]](#Contents)

## resume
```v ignore
fn (mut p Program) resume()
```

resume re-enters the alternate screen and forces a full repaint.

[[Return to contents]](#Contents)

## ProgramOpts
```v ignore
struct ProgramOpts {
pub:
	// alt_screen switches to the terminal alternate buffer while running.
	alt_screen bool = true
	// mouse enables mouse tracking in term.ui.
	mouse bool
	// capture_events puts the terminal into raw mode so control keys can be
	// handled by the model.
	capture_events bool = true
	// window_title is the initial terminal title.
	window_title string
	// fps is the frame rate used by term.ui. Values <= 0 fall back to 60.
	fps int = 60
	// hide_cursor hides the terminal cursor while the program runs.
	hide_cursor bool = true
	// without_renderer stops the runtime from writing view() output. Messages
	// are still processed, which is useful for headless programs and tests.
	without_renderer bool
	// out receives view() output when without_renderer is set. When absent,
	// headless output is discarded.
	out ?fn (string)
	// cancel is checked once per frame. Returning true stops the program.
	cancel ?fn () bool
	// ctx stops the program when it is cancelled.
	ctx ?context.Context
	// init_fn runs once after term.ui is initialised.
	init_fn ?fn ()
	// cleanup_fn runs once before the program restores the terminal.
	cleanup_fn ?fn ()
	// filter can drop or transform a message before it reaches the model.
	filter ?fn (Msg) ?Msg
}
```

ProgramOpts controls how a Program is built and run.

[[Return to contents]](#Contents)

## QuitMsg
```v ignore
struct QuitMsg {}
```

QuitMsg asks the runtime to stop the program.

[[Return to contents]](#Contents)

## Renderer
```v ignore
struct Renderer {
pub mut:
	width  int
	height int
pub:
	profile ColorProfile
mut:
	cells        []Cell
	prev         []Cell
	sync_updates bool = true
	alt_screen   bool
	has_rendered bool
}
```

Renderer keeps a cell grid and emits only the cells that changed since the previous frame. It is
independent of term.ui so it can be tested with plain strings.

[[Return to contents]](#Contents)

## resize
```v ignore
fn (mut r Renderer) resize(width int, height int)
```

resize changes the grid dimensions. The diff baseline is reset so the next frame redraws the whole
screen.

[[Return to contents]](#Contents)

## clear
```v ignore
fn (mut r Renderer) clear()
```

clear resets the current grid to blank cells.

[[Return to contents]](#Contents)

## set_cell
```v ignore
fn (mut r Renderer) set_cell(x int, y int, text string, fg string, bg string, attrs u8)
```

set_cell places a string at x,y. fg and bg are SGR parameter strings (for example "31" or
"38;5;42"); empty means default. attrs is a combination of the attr_* bits.

[[Return to contents]](#Contents)

## draw_text
```v ignore
fn (mut r Renderer) draw_text(x int, y int, text string, fg string, bg string, attrs u8)
```

draw_text writes text starting at x,y. SGR color and attribute sequences in the text are parsed into
cell styles; other escape sequences are ignored. Combining marks and joiners are kept with their
base glyph in a single cell.

[[Return to contents]](#Contents)

## frame
```v ignore
fn (mut r Renderer) frame() string
```

frame returns the escape sequences needed to turn the previous grid into the current one, then swaps
the buffers. An unchanged frame returns ''.

[[Return to contents]](#Contents)

## enter
```v ignore
fn (r &Renderer) enter() string
```

enter returns the sequences used when the renderer takes over the screen.

[[Return to contents]](#Contents)

## leave
```v ignore
fn (r &Renderer) leave() string
```

leave returns the sequences used to restore the terminal.

[[Return to contents]](#Contents)

## SequenceCmd
```v ignore
struct SequenceCmd {
pub:
	cmds []Cmd
}
```

SequenceCmd runs its commands in declaration order.

[[Return to contents]](#Contents)

## TickCmd
```v ignore
struct TickCmd {
pub:
	id      int
	delay   time.Duration
	produce fn (i64) Msg = unsafe { nil }
}
```

TickCmd delivers a message once after a delay.

[[Return to contents]](#Contents)

## TickMsg
```v ignore
struct TickMsg {
pub:
	id int
	at i64
}
```

TickMsg is delivered by a tick or every command.

[[Return to contents]](#Contents)

## TitleMsg
```v ignore
struct TitleMsg {
pub:
	title string
}
```

TitleMsg asks the runtime to change the terminal window title.

[[Return to contents]](#Contents)

## WindowSizeMsg
```v ignore
struct WindowSizeMsg {
pub:
	width  int
	height int
}
```

WindowSizeMsg is delivered when the terminal is resized.

[[Return to contents]](#Contents)

## WriteLineMsg
```v ignore
struct WriteLineMsg {
pub:
	text string
}
```

WriteLineMsg asks the runtime to write a line outside the rendered frame.

[[Return to contents]](#Contents)

#### Powered by vdoc.
