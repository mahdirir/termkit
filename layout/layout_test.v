module layout

fn test_rect_helpers() {
	r := Rect{ x: 2, y: 3, width: 4, height: 5 }
	assert r.right() == 6
	assert r.bottom() == 8
	assert r.contains(2, 3)
	assert r.contains(5, 7)
	assert !r.contains(6, 3)
	assert r.inset(1) == Rect{ x: 3, y: 4, width: 2, height: 3 }
}

fn test_intersect() {
	a := Rect{ x: 0, y: 0, width: 5, height: 5 }
	b := Rect{ x: 3, y: 3, width: 5, height: 5 }
	assert intersect(a, b) or { Rect{} } == Rect{ x: 3, y: 3, width: 2, height: 2 }
	assert intersect(a, Rect{ x: 10, y: 10, width: 2, height: 2 }) == none
}

fn test_join() {
	rects := [Rect{ x: 1, y: 2, width: 3, height: 4 }, Rect{ x: 8, y: 1, width: 2, height: 2 }]
	assert join(rects) == Rect{ x: 1, y: 1, width: 9, height: 5 }
}

fn test_stacks() {
	a := Rect{ x: 0, y: 0, width: 3, height: 2 }
	b := Rect{ x: 3, y: 0, width: 2, height: 4 }
	assert hstack([a, b]) == Rect{ x: 0, y: 0, width: 5, height: 4 }
	c := Rect{ x: 0, y: 2, width: 5, height: 1 }
	assert vstack([a, c]) == Rect{ x: 0, y: 0, width: 5, height: 3 }
}

fn test_place() {
	outer := Rect{ x: 0, y: 0, width: 10, height: 8 }
	size := Size{ width: 4, height: 2 }
	assert place(outer, size, .start) == Rect{ x: 0, y: 3, width: 4, height: 2 }
	assert place(outer, size, .center) == Rect{ x: 3, y: 3, width: 4, height: 2 }
	assert place(outer, size, .end) == Rect{ x: 6, y: 3, width: 4, height: 2 }
}
