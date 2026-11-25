module layout

fn test_position_clamps() {
	assert position(-0.5).value == 0
	assert position(1.5).value == 1
	assert position(0.25).value == 0.25
}

fn test_position_at() {
	assert position(0).at(80, 10) == 0
	assert position(1).at(80, 10) == 70
	assert position(0.5).at(80, 10) == 35
	assert position(0.5).at(5, 10) == 0
}

fn test_split_at() {
	lw, rw := split_at(80, position(0.25))
	assert lw == 20
	assert rw == 60
	zero_l, zero_r := split_at(0, position(0.5))
	assert zero_l == 0
	assert zero_r == 0
}

fn test_place_full_corners() {
	outer := Rect{ x: 0, y: 0, width: 80, height: 24 }
	size := Size{ width: 10, height: 4 }
	top_left := place_full(outer, size, .start, .start)
	assert top_left.x == 0
	assert top_left.y == 0
	bottom_right := place_full(outer, size, .end, .end)
	assert bottom_right.x == 70
	assert bottom_right.y == 20
	centered := place(outer, size, .center)
	middle := place_full(outer, size, .center, .center)
	assert centered == middle
}

fn test_block_geometry() {
	assert block_width('hi\nwider') == 5
	assert block_height('hi\nwider') == 2
	assert block_height('') == 1
	size := block_size('hi\nwider')
	assert size.width == 5
	assert size.height == 2
}
