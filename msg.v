module termkit

// Msg is the marker interface for everything that can be delivered to a
// model's update method. Any type that implements it can be sent.
pub interface Msg {}

// KeyEventKind distinguishes presses from releases and auto-repeat events.
pub enum KeyEventKind {
	press
	release
	repeat
}

// Modifiers records the control keys held during a key or mouse event.
@[flag]
pub enum Modifiers {
	ctrl
	shift
	alt
}

// MouseAction describes what a MouseMsg represents.
pub enum MouseAction {
	down
	up
	move
	drag
	scroll
}

// MouseButton identifies which button was involved in a mouse event.
pub enum MouseButton {
	unknown
	left
	middle
	right
}

// ScrollDirection is the direction of a mouse scroll event.
pub enum ScrollDirection {
	none
	up
	down
	left
	right
}

// KeyMsg is delivered for a key press, release or repeat.
pub struct KeyMsg {
pub:
	key       string
	code      int
	modifiers Modifiers
	kind      KeyEventKind
	utf8      string
}

// is_ctrl reports whether ctrl was held for this key event.
pub fn (m KeyMsg) is_ctrl() bool {
	return m.modifiers.has(.ctrl)
}

// is_shift reports whether shift was held for this key event.
pub fn (m KeyMsg) is_shift() bool {
	return m.modifiers.has(.shift)
}

// is_alt reports whether alt was held for this key event.
pub fn (m KeyMsg) is_alt() bool {
	return m.modifiers.has(.alt)
}

// is_press reports whether this is a key press rather than a release.
pub fn (m KeyMsg) is_press() bool {
	return m.kind == .press
}

// MouseMsg is delivered for mouse activity.
pub struct MouseMsg {
pub:
	x         int
	y         int
	button    MouseButton
	action    MouseAction
	scroll    ScrollDirection
	modifiers Modifiers
}

// WindowSizeMsg is delivered when the terminal is resized.
pub struct WindowSizeMsg {
pub:
	width  int
	height int
}

// QuitMsg asks the runtime to stop the program.
pub struct QuitMsg {}

// PasteMsg carries text that arrived as a single bracketed paste.
pub struct PasteMsg {
pub:
	text string
}

// ErrorMsg carries an error that a model may want to display.
pub struct ErrorMsg {
pub:
	message string
}

// TickMsg is delivered by a tick or every command.
pub struct TickMsg {
pub:
	id int
	at i64
}

// FocusMsg is delivered when the terminal gains focus.
pub struct FocusMsg {}

// BlurMsg is delivered when the terminal loses focus.
pub struct BlurMsg {}

// TitleMsg asks the runtime to change the terminal window title.
pub struct TitleMsg {
pub:
	title string
}

// WriteLineMsg asks the runtime to write a line outside the rendered frame.
pub struct WriteLineMsg {
pub:
	text string
}

// NoopMsg is produced for input the runtime does not translate. Models can
// safely ignore it.
pub struct NoopMsg {}
