module widgets

import termkit
import time

// Stopwatch accumulates elapsed time from TickMsg timestamps.
pub struct Stopwatch {
pub mut:
	running bool
	elapsed time.Duration
	last_at i64
}

// start begins counting.
pub fn (mut s Stopwatch) start() {
	s.running = true
}

// stop pauses counting.
pub fn (mut s Stopwatch) stop() {
	s.running = false
}

// reset clears the elapsed time.
pub fn (mut s Stopwatch) reset() {
	s.elapsed = time.Duration(0)
	s.last_at = 0
}

// update accumulates time between tick messages.
pub fn (mut s Stopwatch) update(msg termkit.Msg) {
	match msg {
		termkit.TickMsg {
			if !s.running {
				return
			}
			if s.last_at != 0 {
				delta := msg.at - s.last_at
				if delta > 0 {
					s.elapsed += time.Duration(delta)
				}
			}
			s.last_at = msg.at
		}
		else {}
	}
}

// view renders seconds with one decimal place.
pub fn (s Stopwatch) view() string {
	ms := s.elapsed.milliseconds()
	return '${ms / 1000}.${(ms % 1000) / 100}s'
}

// Timer counts down from a duration and reports completion through done().
pub struct Timer {
pub mut:
	remaining time.Duration
	last_at   i64
	running   bool
}

// new_timer creates a stopped timer for d.
pub fn new_timer(d time.Duration) Timer {
	return Timer{ remaining: d }
}

// start begins counting down.
pub fn (mut t Timer) start() {
	t.running = true
}

// stop pauses the countdown.
pub fn (mut t Timer) stop() {
	t.running = false
}

// done reports whether the countdown reached zero.
pub fn (t Timer) done() bool {
	return t.remaining <= time.Duration(0)
}

// update decrements the remaining time from tick timestamps.
pub fn (mut t Timer) update(msg termkit.Msg) {
	match msg {
		termkit.TickMsg {
			if !t.running || t.done() {
				return
			}
			if t.last_at != 0 {
				delta := msg.at - t.last_at
				if delta > 0 {
					t.remaining -= time.Duration(delta)
				}
			}
			t.last_at = msg.at
		}
		else {}
	}
}

// view renders the remaining whole seconds.
pub fn (t Timer) view() string {
	remaining := if t.remaining > time.Duration(0) { t.remaining } else { time.Duration(0) }
	return '${remaining.milliseconds() / 1000}s'
}
