module main

import termkit.layout
import termkit.style

// A non-interactive example: styling and layout are pure string functions.
fn main() {
	title := style.Style{
		fg:    style.rgb(255, 220, 120).fg()
		attrs: style.attr_bold
		align: layout.Align.center
		width: 28
	}
	box := style.Style{
		border:  .rounded
		title:   'termkit style'
		padding: 1
		margin:  1
		width:   32
		align:   layout.Align.center
	}
	println(box.render(title.render('Hello, termkit!')))

	a := layout.Rect{ width: 10, height: 2 }
	b := layout.Rect{ width: 5, height: 3 }
	stacked := layout.hstack([a, b])
	println('hstack: ${stacked.width}x${stacked.height}')
	println('contains(3,1): ${a.contains(3, 1)}')
}
