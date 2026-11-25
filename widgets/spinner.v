module widgets

import termkit

// Spinner shows an animated progress indicator driven by TickMsg messages.
pub struct Spinner {
pub mut:
	frames []string = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
	frame  int
	label  string
	// fps is informational: ticks arrive from the program's frame loop.
	fps int = 10
}

// spinner_preset returns the frames for a named animation. Unknown names
// return the default dots.
pub fn spinner_preset(name string) []string {
	match name {
		'line' {
			return ['-', '\\', '|', '/']
		}
		'mini_dots' {
			return ['⠁', '⠉', '⠙', '⠚', '⠖', '⠦', '⠴', '⠲', '⠳', '⠓']
		}
		'jump' {
			return ['⢄', '⢂', '⢁', '⡁', '⡈', '⡐', '⡠', '⢠', '⢤', '⢦']
		}
		'pulse' {
			return ['█', '▓', '▒', '░', '▒', '▓']
		}
		'points' {
			return ['∙∙∙', '●∙∙', '∙●∙', '∙∙●']
		}
		'meter' {
			return ['▱▱▱', '▰▱▱', '▰▰▱', '▰▰▰', '▰▰▱', '▰▱▱']
		}
		'hamburger' {
			return ['☰', '☱', '☵', '☶', '☴', '☲']
		}
		'ellipsis' {
			return ['', '.', '..', '...']
		}
		else {
			return ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
		}
	}
}

// set_preset replaces the frames with a named animation.
pub fn (mut s Spinner) set_preset(name string) {
	s.frames = spinner_preset(name)
	s.frame = 0
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
	index := if s.frame < 0 { 0 } else { s.frame % s.frames.len }
	frame := s.frames[index]
	return if s.label == '' { frame } else { '${frame} ${s.label}' }
}
