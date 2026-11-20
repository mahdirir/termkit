module widgets

import termkit

// Cursor is a blinking block driven by tick messages.
pub struct Cursor {
pub mut:
	visible bool   = true
	glyph   string = '█'
}

// update toggles visibility on each tick.
pub fn (mut c Cursor) update(msg termkit.Msg) {
	match msg {
		termkit.TickMsg {
			c.visible = !c.visible
		}
		else {}
	}
}

// view renders the cursor or a blank cell.
pub fn (c Cursor) view() string {
	return if c.visible { c.glyph } else { ' ' }
}
