module main

import os
import termkit
import termkit.widgets

const preview_lines = 40
const max_preview_bytes = 64 * 1024
const max_line_width = 200

// looks_binary rejects data with NUL bytes or a large share of control bytes.
fn looks_binary(data []u8) bool {
	mut suspicious := 0
	for b in data {
		if b == 0 {
			return true
		}
		if b < 9 || (b > 13 && b < 32) {
			suspicious++
		}
	}
	return suspicious * 10 > data.len
}

// read_preview reads at most 64 KiB from the start of path, so large files
// never blow up memory. Binary content is detected and skipped.
fn read_preview(path string) []string {
	mut file := os.open(path) or { return ['(cannot open file: ${err})'] }
	defer {
		file.close()
	}
	mut buf := []u8{len: max_preview_bytes}
	n := file.read(mut buf) or { return ['(cannot read file: ${err})'] }
	if n == 0 {
		return ['(empty file)']
	}
	data := buf[..n].clone()
	if looks_binary(data) {
		return ['(binary file - preview skipped)']
	}
	raw_lines := data.bytestr().split('\n')
	mut out := []string{}
	for i, raw in raw_lines {
		if i >= preview_lines {
			break
		}
		line := raw.trim_right('\r')
		if line.len > max_line_width {
			out << line[..max_line_width] + '…'
		} else {
			out << line
		}
	}
	if raw_lines.len > preview_lines {
		out << '… output truncated (showing first ${preview_lines} lines)'
	}
	if out.len == 0 {
		out << '(empty file)'
	}
	return out
}

struct Browser {
mut:
	picker        widgets.FilePicker
	preview       widgets.Viewport
	status        string
	focus_preview bool
}

fn (mut m Browser) init() termkit.Cmd {
	m.picker = widgets.new_filepicker('.') or { widgets.FilePicker{ path: '.' } }
	m.preview = widgets.Viewport{ height: 12 }
	m.preview.set_content(['Select a file, then press Enter to preview it.'])
	m.focus_preview = false
	m.status = 'arrows: move · enter: open / select · backspace: parent · tab: switch pane · q: quit'
	return termkit.no_cmd
}

fn (mut m Browser) set_focus(preview bool) {
	m.focus_preview = preview
	if preview {
		m.picker.blur()
	} else {
		m.picker.focus()
	}
}

fn (mut m Browser) show_selection() {
	path := m.picker.selection()
	if path == '' {
		return
	}
	mut lines := ['Preview of ${path}',
		'────────────────────────────────']
	lines << read_preview(path)
	m.preview.set_content(lines)
	m.status = 'previewing: ${path}  (first ${preview_lines} lines)'
}

fn (mut m Browser) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.KeyMsg {
			if msg.kind == .release {
				return m, termkit.no_cmd
			}
			match msg.key {
				'q' {
					return m, termkit.quit()
				}
				termkit.key_tab {
					m.set_focus(!m.focus_preview)
					return m, termkit.no_cmd
				}
				else {}
			}
		}
		else {}
	}
	if m.focus_preview {
		m.preview.update(msg)
		return m, termkit.no_cmd
	}
	before := m.picker.selection()
	m.picker.update(msg)
	if m.picker.selection() != '' && m.picker.selection() != before {
		m.show_selection()
	}
	return m, termkit.no_cmd
}

fn (mut m Browser) view() string {
	focus := if m.focus_preview { 'preview' } else { 'files' }
	return 'FILE BROWSER  (focus: ${focus})\n\n' + m.picker.view() + '\n\n' +
		m.preview.view() + '\n\n' + m.status
}

fn main() {
	mut app := &Browser{}
	mut program := termkit.new_program(app, termkit.ProgramOpts{})
	program.run()!
}
