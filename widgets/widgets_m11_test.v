module widgets

import os
import termkit
import termkit.style
import time

fn bold_red(row int, col int) style.Style {
	return style.Style{ fg: '31', attrs: style.attr_bold }
}

fn test_table_cell_styles() {
	mut t := Table{}
	t.set_data(['name', 'size'], [['a', '1'], ['b', '2']])
	plain := t.view()
	assert !plain.contains('\x1b[')
	t.style_fn = bold_red
	styled := t.view()
	assert styled.contains('\x1b[31m')
	t.style_fn = none
	t.header_style = style.Style{ attrs: style.attr_bold }
	headed := t.view()
	assert headed.contains('\x1b[1m')
}

fn deny_all(item string, query string) bool {
	return false
}

fn test_list_custom_filter() {
	mut l := List{ items: ['apple', 'banana', 'cherry'] }
	l.filter = 'a'
	assert l.match_count() == 2
	l.filter_fn = deny_all
	assert l.match_count() == 0
}

fn test_list_status_and_cycle() {
	mut l := List{ items: ['a', 'b'], cycle: true, height: 5 }
	l.set_status('2 items')
	assert l.view().contains('2 items')
	l.clear_status()
	assert !l.view().contains('2 items')
	l.selected = 1
	l.update(termkit.KeyMsg{ key: termkit.key_down, kind: .press })
	assert l.selected == 0
	l.update(termkit.KeyMsg{ key: termkit.key_up, kind: .press })
	assert l.selected == 1
}

fn test_list_highlight_matches() {
	mut l := List{ items: ['apple', 'banana'], highlight_matches: true, height: 5 }
	l.filter = 'app'
	out := l.view()
	assert out.contains('\x1b[7mapp\x1b[0m')
}

fn test_viewport_gutter_find_percent() {
	mut v := Viewport{ lines: ['one', 'two', 'three', 'four'], height: 2, gutter: true }
	assert v.view().contains('1 one')
	assert v.find('three')
	assert v.find_pos == 2
	assert v.find_next()
	assert v.find_pos == 2
	assert !v.find('missing')
	assert v.scroll_percent() >= 0
	assert v.scroll_percent() <= 100
	full := Viewport{ lines: ['a'], height: 10 }
	assert full.scroll_percent() == 100
}

fn reject_short(s string) !string {
	if s.len < 3 {
		return error('too short')
	}
	return s
}

fn test_textinput_validate() {
	mut t := TextInput{ validate: reject_short }
	t.update(termkit.KeyMsg{ key: 'a', kind: .press, utf8: 'a' })
	assert !t.is_valid()
	assert t.validation_error() == 'too short'
	assert t.view().contains('too short')
	t.update(termkit.KeyMsg{ key: 'b', kind: .press, utf8: 'b' })
	t.update(termkit.KeyMsg{ key: 'c', kind: .press, utf8: 'c' })
	assert t.is_valid()
}

fn test_textinput_suggest_complete() {
	mut t := TextInput{ suggestions: ['status', 'stash', 'commit'] }
	t.value = 'sta'
	t.position = 3
	assert t.suggest() == ['status', 'stash']
	assert t.complete()
	assert t.value == 'status'
	t.value = 'xyz'
	t.position = 3
	assert t.suggest().len == 0
	assert !t.complete()
}

fn test_filepicker_metadata_columns() {
	dir := os.join_path(os.vtmp_dir(), 'termkit_picker_test')
	os.mkdir_all(dir) or {}
	os.write_file(os.join_path(dir, 'a.v'), 'x') or {}
	os.write_file(os.join_path(dir, 'b.txt'), 'yy') or {}
	mut p := new_filepicker(dir) or { panic(err) }
	assert p.entries.len == 2
	p.allowed_exts = ['.v']
	p.reload() or { panic(err) }
	assert p.entries == ['a.v']
	p.show_size = true
	p.show_permissions = true
	assert p.view().contains('B')
	assert p.view().contains('r') || p.view().contains('-')
	p.show_target = true
	p.view()
	p.auto_height = true
	p.allowed_exts = []string{}
	p.reload() or { panic(err) }
	assert p.height == 3
	os.rm(os.join_path(dir, 'a.v')) or {}
	os.rm(os.join_path(dir, 'b.txt')) or {}
	os.rmdir(dir) or {}
}

fn test_progress_view_at_and_gradient() {
	p := Progress{ width: 6 }
	assert p.view_at(50) == p.view_at(50)
	assert p.view_at(0).contains('0%')
	assert p.view_at(100).contains('100%')
	assert p.view_at(-5).contains('0%')
	assert p.view_at(500).contains('100%')
	mut g := Progress{ width: 6, gradient: true, from: style.rgb(0, 0, 0), to: style.rgb(255, 255, 255) }
	g.set(50)
	assert g.view().contains('\x1b[38;2;')
}

fn test_spinner_presets() {
	assert spinner_preset('line') == ['-', '\\', '|', '/']
	assert spinner_preset('nope').len == 10
	mut s := Spinner{}
	s.set_preset('ellipsis')
	assert s.frames == ['', '.', '..', '...']
	assert s.frame == 0
	s.set_preset('unknown-name')
	assert s.frames.len == 10
}

fn test_tree_markers_and_window() {
	mut t := Tree{}
	root := t.add_node('root', -1)
	t.add_node('a', root)
	t.add_node('b', root)
	t.add_node('c', root)
	assert t.view().contains('▾ ')
	t.open_marker = '+ '
	t.closed_marker = '- '
	t.leaf_marker = '* '
	t.cursor_marker = '>>'
	assert t.view().contains('+ ')
	assert t.view().contains('>>')
	t.height = 2
	assert t.view().split('\n').len == 2
}

fn test_timer_ids_filter_ticks() {
	mut s := Stopwatch{ id: 5 }
	s.start()
	s.update(termkit.TickMsg{ id: 6, at: 1_000_000_000 })
	assert s.elapsed == time.Duration(0)
	s.update(termkit.TickMsg{ id: 5, at: 1_000_000_000 })
	s.update(termkit.TickMsg{ id: 5, at: 2_000_000_000 })
	assert s.elapsed == time.Duration(1_000_000_000)
	mut timer := Timer{ remaining: time.Duration(5_000_000_000), id: 7 }
	timer.start()
	timer.update(termkit.TickMsg{ id: 8, at: 1_000_000_000 })
	assert timer.remaining == time.Duration(5_000_000_000)
	timer.update(termkit.TickMsg{ id: 7, at: 1_000_000_000 })
	timer.update(termkit.TickMsg{ id: 7, at: 2_000_000_000 })
	assert timer.remaining == time.Duration(4_000_000_000)
}

fn test_paginator_styles() {
	arabic := Paginator{ page: 1, per_page: 10, total: 30 }
	assert arabic.view() == '‹ 2/3 ›'
	mut custom := Paginator{ page: 1, per_page: 10, total: 30, arabic_format: 'p%d of %d' }
	assert custom.view() == '‹ p2 of 3 ›'
	dots := Paginator{ page: 1, per_page: 10, total: 30, style: .dots }
	assert dots.view() == '○ ● ○'
	assert Paginator{}.view() == 'no items'
}
