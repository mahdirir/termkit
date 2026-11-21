module widgets

import termkit

// Confirm is a yes/no prompt driven by y/n or left/right keys.
pub struct Confirm {
pub mut:
	prompt   string = 'Are you sure?'
	value    bool
	answered bool
	focused  bool = true
}

// focus marks the confirm as accepting keys.
pub fn (mut c Confirm) focus() {
	c.focused = true
}

// blur marks the confirm as not accepting keys.
pub fn (mut c Confirm) blur() {
	c.focused = false
}

// is_focused reports whether the confirm accepts keyboard input.
pub fn (c &Confirm) is_focused() bool {
	return c.focused
}

// update handles confirmation keys.
pub fn (mut c Confirm) update(msg termkit.Msg) {
	if !c.focused {
		return
	}
	match msg {
		termkit.FocusMsg {
			c.focused = true
		}
		termkit.BlurMsg {
			c.focused = false
		}
		termkit.KeyMsg {
			if msg.kind != .press {
				return
			}
			match msg.key.to_lower() {
				'y' {
					c.value = true
					c.answered = true
				}
				'n' {
					c.value = false
					c.answered = true
				}
				termkit.key_enter {
					c.answered = true
				}
				termkit.key_left, termkit.key_right {
					c.value = !c.value
				}
				else {}
			}
		}
		else {}
	}
}

// view renders the prompt and a highlighted choice.
pub fn (c Confirm) view() string {
	yes := if c.value { '[Y]' } else { '[y]' }
	no := if c.value { '[n]' } else { '[N]' }
	return '${c.prompt} ${yes} / ${no}'
}
