module main

import termkit
import termkit.widgets
import time

const tick_id = 7
const page_size = 12

fn tick_message(at i64) termkit.Msg {
	return termkit.TickMsg{ id: tick_id, at: at }
}

fn pad_left(s string, width int) string {
	if s.len >= width {
		return s
	}
	return ' '.repeat(width - s.len) + s
}

fn synthetic_line(n int) string {
	levels := ['INFO', 'WARN', 'DEBUG', 'ERROR']
	services := ['auth', 'api', 'worker', 'db', 'ui']
	level := levels[n % levels.len]
	service := services[(n / 3) % services.len]
	return '${pad_left(n.str(), 5)} [${level}] ${service}: req ${1000 + n % 9000} done in ${n % 250}ms'
}

struct Logs {
mut:
	lines        []string
	shown        []string
	filter       widgets.TextInput
	viewport     widgets.Viewport
	pager        widgets.Paginator
	counter      int
	focus_filter bool
	follow       bool
}

// refresh re-applies the filter, updates the page count and reloads the
// viewport with just the lines on the current page.
fn (mut m Logs) refresh() {
	needle := m.filter.value.to_lower()
	m.shown = []string{}
	for line in m.lines {
		if needle == '' || line.to_lower().contains(needle) {
			m.shown << line
		}
	}
	m.pager.set_total(m.shown.len)
	if m.follow && m.shown.len > 0 && m.pager.per_page > 0 {
		m.pager.page = (m.shown.len - 1) / m.pager.per_page
	}
	start := m.pager.start()
	end := m.pager.end()
	if start <= end && end <= m.shown.len {
		m.viewport.set_content(m.shown[start..end])
	} else {
		m.viewport.set_content([]string{})
	}
}

fn (mut m Logs) init() termkit.Cmd {
	m.filter = widgets.TextInput{ prompt: 'Filter: ' }
	m.viewport = widgets.Viewport{ height: 12 }
	m.pager = widgets.Paginator{ per_page: page_size }
	m.follow = true
	m.focus_filter = false
	m.filter.blur()
	for i in 0 .. 60 {
		m.lines << synthetic_line(i)
	}
	m.refresh()
	return termkit.every(tick_id, 400 * time.millisecond, tick_message)
}

fn (mut m Logs) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.TickMsg {
			m.lines << synthetic_line(m.counter)
			m.counter++
			m.refresh()
			return m, termkit.no_cmd
		}
		termkit.KeyMsg {
			match msg.key {
				'q' {
					return m, termkit.quit()
				}
				termkit.key_tab {
					m.focus_filter = !m.focus_filter
					if m.focus_filter {
						m.filter.focus()
					} else {
						m.filter.blur()
					}
					return m, termkit.no_cmd
				}
				'f' {
					if !m.focus_filter {
						m.follow = !m.follow
						m.refresh()
					}
					return m, termkit.no_cmd
				}
				else {}
			}
			if m.focus_filter {
				before := m.filter.value
				m.filter.update(msg)
				if m.filter.value != before {
					m.refresh()
				}
				return m, termkit.no_cmd
			}
			if msg.key == termkit.key_left || msg.key == termkit.key_right {
				m.pager.update(msg)
				m.refresh()
				return m, termkit.no_cmd
			}
			m.viewport.update(msg)
		}
		else {}
	}
	return m, termkit.no_cmd
}

fn (mut m Logs) view() string {
	follow := if m.follow { 'on' } else { 'off' }
	focus := if m.focus_filter { 'filter' } else { 'log' }
	return 'LOG VIEWER  (total: ${m.lines.len}, matching: ${m.shown.len}, focus: ${focus})\n\n' +
		m.filter.view() + '\n\n' + m.viewport.view() + '\n\n' +
		'${m.pager.view()}  follow: ${follow}\n\n' +
		'tab: focus filter · left/right: page · up/down: scroll · f: toggle follow · q: quit'
}

fn main() {
	mut logs := &Logs{}
	mut program := termkit.new_program(logs, termkit.ProgramOpts{})
	program.run()!
}
