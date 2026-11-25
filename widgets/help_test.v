module widgets

fn test_help_hides_disabled() {
	help := Help{
		bindings: [Binding{ key: 'q', description: 'quit' }, Binding{
			key:         'x'
			description: 'hidden'
			enabled:     false
		}]
	}
	assert help.view().contains('quit')
	assert !help.view().contains('hidden')
}

fn test_help_full_view_two_columns() {
	short := Help{
		bindings: [Binding{ key: 'q', description: 'quit' }, Binding{
			key:         'j'
			description: 'down'
		}]
	}
	full := Help{
		bindings: [Binding{ key: 'q', description: 'quit' }, Binding{
			key:         'j'
			description: 'down'
		}]
		full:     true
	}
	assert short.view().split('\n').len == 2
	assert full.view().split('\n').len == 1
	assert full.view().contains('quit')
	assert full.view().contains('down')
}

fn test_help_width_truncates_with_ellipsis() {
	help := Help{
		bindings: [Binding{ key: 'q', description: 'quit the program now' }]
		width:    10
	}
	assert help.view().contains('…')
}
