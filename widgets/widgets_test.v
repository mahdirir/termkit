module widgets

import termkit

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

fn test_help_view() {
	help := Help{ bindings: [Binding{ key: 'q', description: 'quit' }] }
	assert help.view().contains('q')
	assert help.view().contains('quit')
}
