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

fn test_help_view() {
	help := Help{ bindings: [Binding{ key: 'q', description: 'quit' }] }
	assert help.view().contains('q')
	assert help.view().contains('quit')
}
