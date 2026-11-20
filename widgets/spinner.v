module widgets

import termkit

// Spinner shows an animated progress indicator driven by TickMsg messages.
pub struct Spinner {
pub mut:
	frames []string = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
	frame  int
	label  string
}

// update advances the animation on any tick message.
pub fn (mut s Spinner) update(msg termkit.Msg) {
	match msg {
		termkit.TickMsg {
			if s.frames.len > 0 {
				s.frame = (s.frame + 1) % s.frames.len
			}
		}
		else {}
	}
}

// view renders the current frame.
pub fn (s Spinner) view() string {
	if s.frames.len == 0 {
		return s.label
	}
	frame := s.frames[s.frame]
	return if s.label == '' { frame } else { '${frame} ${s.label}' }
}
