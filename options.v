module termkit

// ProgramOpts controls how a Program is built and run.
pub struct ProgramOpts {
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
}
