module widgets

import termkit
import time

fn test_textinput_editing() {
	mut input := TextInput{ prompt: '> ' }
	input.update(termkit.KeyMsg{ key: 'h' })
	input.update(termkit.KeyMsg{ key: 'i' })
	assert input.value == 'hi'
	input.update(termkit.KeyMsg{ key: termkit.key_left })
	assert input.position == 1
	input.update(termkit.KeyMsg{ key: 'x' })
	assert input.value == 'hxi'
	input.update(termkit.KeyMsg{ key: termkit.key_backspace })
	assert input.value == 'hi'
	input.update(termkit.KeyMsg{ key: termkit.key_end })
	input.update(termkit.PasteMsg{ text: ' there' })
	assert input.value == 'hi there'
	assert input.view().contains('hi there')
}

fn test_textinput_mask() {
	mut input := TextInput{ mask: `*`, prompt: 'pw: ' }
	input.update(termkit.KeyMsg{ key: 's' })
	input.update(termkit.KeyMsg{ key: 'e' })
	input.update(termkit.KeyMsg{ key: 'c' })
	assert input.value == 'sec'
	assert input.view().contains('***')
	assert !input.view().contains('sec')
}

fn test_textinput_blur() {
	mut input := TextInput{}
	input.blur()
	input.update(termkit.KeyMsg{ key: 'a' })
	assert input.value == ''
	input.focus()
	input.update(termkit.KeyMsg{ key: 'a' })
	assert input.value == 'a'
}

fn test_viewport_scroll() {
	mut vp := Viewport{ height: 2 }
	vp.set_content(['one', 'two', 'three'])
	assert vp.view() == 'one\ntwo'
	vp.update(termkit.KeyMsg{ key: termkit.key_down })
	assert vp.view() == 'two\nthree'
	vp.update(termkit.KeyMsg{ key: termkit.key_down })
	assert vp.view() == 'two\nthree'
}

fn test_list_navigation() {
	mut list := List{ height: 3 }
	list.set_items(['alpha', 'beta', 'gamma'])
	assert list.selected_item() == 'alpha'
	list.update(termkit.KeyMsg{ key: termkit.key_down })
	assert list.selected_item() == 'beta'
	assert list.view().contains('> beta')
}

fn test_list_multi_select() {
	mut list := List{ multi_select: true }
	list.set_items(['alpha', 'beta', 'gamma'])
	list.toggle()
	list.update(termkit.KeyMsg{ key: termkit.key_down })
	list.toggle()
	assert list.selected_items() == ['alpha', 'beta']
	assert list.view().contains('* ')
}

fn test_list_filter() {
	mut list := List{ height: 5 }
	list.set_items(['alpha', 'beta', 'gamma'])
	list.update(termkit.KeyMsg{ key: 'g' })
	assert list.selected_item() == 'gamma'
	list.update(termkit.KeyMsg{ key: termkit.key_backspace })
	assert list.selected_item() == 'gamma'
}

fn test_spinner_and_progress() {
	mut spin := Spinner{ label: 'loading' }
	before := spin.view()
	spin.update(termkit.TickMsg{ id: 1, at: 0 })
	assert spin.view() != before
	mut bar := Progress{}
	bar.set(50)
	assert bar.view().contains('50%')
}

fn test_widget_out_of_range_fields() {
	mut spin := Spinner{ frames: ['a', 'b'], frame: 7 }
	assert spin.view() == 'b'
	mut bar := Progress{ percent: 150, width: 6 }
	assert bar.view().contains('100%')
}

fn test_textarea() {
	mut area := TextArea{}
	area.set_text('one\ntwo')
	area.update(termkit.KeyMsg{ key: termkit.key_end })
	area.update(termkit.KeyMsg{ key: termkit.key_enter })
	area.update(termkit.KeyMsg{ key: 'x' })
	assert area.text() == 'one\ntwo\nx'
	assert area.view().contains('x')
}

fn test_table_and_paginator() {
	mut table := Table{}
	table.set_data(['name', 'age'], [['ann', '30'], ['bob', '40']])
	assert table.view().contains('name')
	table.update(termkit.KeyMsg{ key: termkit.key_down })
	assert table.selected == 1
	mut page := Paginator{ total: 25 }
	assert page.pages() == 3
	page.update(termkit.KeyMsg{ key: termkit.key_right })
	assert page.start() == 10
	assert page.view().contains('2/3')
}

fn test_mouse_scroll_widgets() {
	mut list := List{ height: 2 }
	list.set_items(['one', 'two', 'three'])
	list.update(termkit.MouseMsg{ action: .scroll, scroll: .down })
	assert list.selected_item() == 'two'
	mut vp := Viewport{ height: 2 }
	vp.set_content(['one', 'two', 'three'])
	vp.update(termkit.MouseMsg{ action: .scroll, scroll: .down, y: 0 })
	assert vp.view() == 'two\nthree'
}

fn test_confirm_widget() {
	mut confirm := Confirm{}
	confirm.update(termkit.KeyMsg{ key: 'y' })
	assert confirm.answered
	assert confirm.value
	assert confirm.view().contains('[Y]')
}

fn test_timer_widgets() {
	mut stopwatch := Stopwatch{}
	stopwatch.start()
	stopwatch.update(termkit.TickMsg{ id: 1, at: 1_000_000_000 })
	stopwatch.update(termkit.TickMsg{ id: 1, at: 2_500_000_000 })
	assert stopwatch.elapsed == 1_500_000_000
	assert stopwatch.view() == '1.5s'
	mut timer := new_timer(2 * time.second)
	timer.start()
	timer.update(termkit.TickMsg{ id: 1, at: 1_000_000_000 })
	timer.update(termkit.TickMsg{ id: 1, at: 3_000_000_000 })
	assert timer.done()
}

fn test_timer_pause_and_restart() {
	mut stopwatch := Stopwatch{}
	stopwatch.start()
	stopwatch.update(termkit.TickMsg{ at: 1_000_000_000 })
	stopwatch.update(termkit.TickMsg{ at: 2_000_000_000 })
	stopwatch.stop()
	stopwatch.start()
	stopwatch.update(termkit.TickMsg{ at: 10_000_000_000 })
	assert stopwatch.elapsed == 1_000_000_000

	mut timer := new_timer(5 * time.second)
	timer.start()
	timer.update(termkit.TickMsg{ at: 1_000_000_000 })
	timer.update(termkit.TickMsg{ at: 2_000_000_000 })
	timer.stop()
	timer.start()
	timer.update(termkit.TickMsg{ at: 10_000_000_000 })
	assert timer.remaining == 4 * time.second
}

fn test_focus_group() {
	mut group := new_focus_group()
	group.add(TextInput{})
	group.add(TextInput{})
	assert group.widgets[0].is_focused()
	assert !group.widgets[1].is_focused()
	group.update(termkit.KeyMsg{ key: 'a' })
	assert group.view().contains('a')
	group.update(termkit.KeyMsg{ key: termkit.key_tab })
	assert !group.widgets[0].is_focused()
	assert group.widgets[1].is_focused()
	group.update(termkit.KeyMsg{ key: 'b' })
	assert group.view().contains('b')
	mut shift := unsafe { termkit.Modifiers(0) }
	shift |= .shift
	group.update(termkit.KeyMsg{ key: termkit.key_tab, modifiers: shift })
	assert group.widgets[0].is_focused()
	assert group.view().contains('•')
}

fn test_filepicker() {
	mut picker := new_filepicker('testdata') or {
		// The package has no testdata directory; use a known directory instead.
		_ = err
		new_filepicker('.')!
	}
	assert picker.entries.len > 0
	picker.update(termkit.KeyMsg{ key: termkit.key_down })
	assert picker.cursor == 1
	picker.update(termkit.KeyMsg{ key: termkit.key_home })
	assert picker.cursor == 0
	assert picker.view().contains('.')
}

fn test_cursor_blink() {
	mut cursor := Cursor{}
	assert cursor.view() == '█'
	cursor.update(termkit.TickMsg{ id: 1, at: 0 })
	assert cursor.view() == ' '
}

fn test_utf8_editing() {
	mut input := TextInput{}
	input.update(termkit.PasteMsg{ text: '世x' })
	assert input.value == '世x'
	assert input.position == 2
	input.update(termkit.KeyMsg{ key: termkit.key_left })
	assert input.position == 1
	input.update(termkit.KeyMsg{ key: termkit.key_backspace })
	assert input.value == 'x'
	assert input.position == 0
	input.update(termkit.KeyMsg{ key: 'é' })
	assert input.value == 'éx'
	assert input.view().contains('é')

	mut area := TextArea{}
	area.set_text('世x')
	area.update(termkit.KeyMsg{ key: termkit.key_home })
	area.update(termkit.KeyMsg{ key: termkit.key_delete })
	assert area.text() == 'x'
	area.update(termkit.PasteMsg{ text: 'α\nβ' })
	assert area.text() == 'α\nβx'
}

fn test_tabs_navigation() {
	mut tabs := Tabs{}
	tabs.set_tabs(['one', 'two', 'three'])
	assert tabs.active_name() == 'one'
	assert tabs.view().contains('[one]')
	tabs.update(termkit.KeyMsg{ key: termkit.key_right })
	assert tabs.active_name() == 'two'
	tabs.update(termkit.KeyMsg{ key: termkit.key_end })
	assert tabs.active_name() == 'three'
	tabs.update(termkit.KeyMsg{ key: termkit.key_home })
	assert tabs.active_name() == 'one'
	tabs.select(1)
	assert tabs.view().contains('[two]')
	assert tabs.view().contains(' one ')
}

fn test_tree_navigation() {
	mut tree := Tree{}
	tree.add_node('root', -1)
	tree.add_node('child a', 0)
	tree.add_node('grandchild', 1)
	tree.add_node('child b', 0)
	assert tree.selected_label() == 'root'
	assert tree.view().contains('root')
	tree.update(termkit.KeyMsg{ key: termkit.key_right })
	assert tree.selected_label() == 'child a'
	tree.update(termkit.KeyMsg{ key: termkit.key_right })
	assert tree.selected_label() == 'grandchild'
	tree.update(termkit.KeyMsg{ key: termkit.key_left })
	assert tree.selected_label() == 'child a'
	tree.update(termkit.KeyMsg{ key: termkit.key_left })
	assert tree.selected_label() == 'child a'
	assert !tree.view().contains('grandchild')
	// A second left moves to the parent; a third collapses the root.
	tree.update(termkit.KeyMsg{ key: termkit.key_left })
	assert tree.selected_label() == 'root'
	tree.update(termkit.KeyMsg{ key: termkit.key_left })
	assert !tree.view().contains('child a')
	tree.update(termkit.KeyMsg{ key: termkit.key_right })
	assert tree.view().contains('child a')
	// child a is still collapsed, so the next visible node is child b.
	tree.update(termkit.KeyMsg{ key: termkit.key_down })
	assert tree.selected_label() == 'child a'
	tree.update(termkit.KeyMsg{ key: termkit.key_down })
	assert tree.selected_label() == 'child b'
}

fn test_help_view() {
	help := Help{ bindings: [Binding{ key: 'q', description: 'quit' }] }
	assert help.view().contains('q')
	assert help.view().contains('quit')
}
