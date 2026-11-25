module layout

import term

// Align controls placement along an axis.
pub enum Align {
	start
	center
	end
}

// Rect is a rectangle in cell coordinates.
pub struct Rect {
pub:
	x      int
	y      int
	width  int
	height int
}

// Size is a width/height pair.
pub struct Size {
pub:
	width  int
	height int
}

// right returns the column just past the rectangle.
pub fn (r Rect) right() int {
	return r.x + r.width
}

// bottom returns the row just past the rectangle.
pub fn (r Rect) bottom() int {
	return r.y + r.height
}

// contains reports whether x,y falls inside the rectangle.
pub fn (r Rect) contains(x int, y int) bool {
	return x >= r.x && x < r.right() && y >= r.y && y < r.bottom()
}

// inset shrinks the rectangle by n cells on every side.
pub fn (r Rect) inset(n int) Rect {
	if r.width <= n * 2 || r.height <= n * 2 {
		return Rect{}
	}
	return Rect{
		x:      r.x + n
		y:      r.y + n
		width:  r.width - n * 2
		height: r.height - n * 2
	}
}

// intersect returns the overlapping part of two rectangles.
pub fn intersect(a Rect, b Rect) ?Rect {
	x := if a.x > b.x { a.x } else { b.x }
	y := if a.y > b.y { a.y } else { b.y }
	right := if a.right() < b.right() { a.right() } else { b.right() }
	bottom := if a.bottom() < b.bottom() { a.bottom() } else { b.bottom() }
	if right <= x || bottom <= y {
		return none
	}
	return Rect{ x: x, y: y, width: right - x, height: bottom - y }
}

// join returns the smallest rectangle containing all given rectangles.
pub fn join(rects []Rect) Rect {
	if rects.len == 0 {
		return Rect{}
	}
	mut min_x := rects[0].x
	mut min_y := rects[0].y
	mut max_x := rects[0].right()
	mut max_y := rects[0].bottom()
	for r in rects[1..] {
		if r.x < min_x {
			min_x = r.x
		}
		if r.y < min_y {
			min_y = r.y
		}
		if r.right() > max_x {
			max_x = r.right()
		}
		if r.bottom() > max_y {
			max_y = r.bottom()
		}
	}
	return Rect{ x: min_x, y: min_y, width: max_x - min_x, height: max_y - min_y }
}

fn min_or_zero(a int, b int) int {
	return if a < b { a } else { b }
}

fn max_or_zero(a int, b int) int {
	return if a > b { a } else { b }
}

// hstack lays rectangles out left to right. A rectangle's x may place a gap
// after the previous rectangle; a smaller x is treated as zero gap.
pub fn hstack(rects []Rect) Rect {
	if rects.len == 0 {
		return Rect{}
	}
	mut end := rects[0].right()
	mut height := 0
	for r in rects {
		height = max_or_zero(height, r.height)
	}
	for r in rects[1..] {
		mut gap := r.x - end
		if gap < 0 {
			gap = 0
		}
		end += gap + r.width
	}
	return Rect{ x: rects[0].x, y: rects[0].y, width: end - rects[0].x, height: height }
}

// vstack lays rectangles out top to bottom. A rectangle's y may place a gap
// after the previous rectangle; a smaller y is treated as zero gap.
pub fn vstack(rects []Rect) Rect {
	if rects.len == 0 {
		return Rect{}
	}
	mut end := rects[0].bottom()
	mut width := 0
	for r in rects {
		width = max_or_zero(width, r.width)
	}
	for r in rects[1..] {
		mut gap := r.y - end
		if gap < 0 {
			gap = 0
		}
		end += gap + r.height
	}
	return Rect{ x: rects[0].x, y: rects[0].y, width: width, height: end - rects[0].y }
}

// place positions size inside outer using the given horizontal alignment and
// vertical centering.
pub fn place(outer Rect, size Size, align Align) Rect {
	return place_full(outer, size, align, .center)
}

// place_full positions size inside outer using horizontal and vertical
// alignment, clamping the result to outer.
pub fn place_full(outer Rect, size Size, halign Align, valign Align) Rect {
	x := match halign {
		.start { outer.x }
		.center { outer.x + (outer.width - size.width) / 2 }
		.end { outer.right() - size.width }
	}
	y := match valign {
		.start { outer.y }
		.center { outer.y + (outer.height - size.height) / 2 }
		.end { outer.bottom() - size.height }
	}
	return Rect{
		x:      if x < outer.x { outer.x } else { x }
		y:      if y < outer.y { outer.y } else { y }
		width:  min_or_zero(size.width, outer.width)
		height: min_or_zero(size.height, outer.height)
	}
}

// Position is a proportional placement in [0, 1]: 0 is start, 0.5 is center
// and 1 is end. Intermediate values split proportionally.
pub struct Position {
pub:
	value f32
}

// position clamps v into a valid Position.
pub fn position(v f32) Position {
	return Position{
		value: if v < 0 {
			0
		} else if v > 1 {
			1
		} else {
			v
		}
	}
}

// at returns the offset of a size-wide object inside total cells.
pub fn (p Position) at(total int, size int) int {
	if total <= size {
		return 0
	}
	return int(p.value * f32(total - size))
}

// split_at divides total cells proportionally: the left part gets
// pos.at(total, 0) cells and the right part gets the rest.
pub fn split_at(total int, pos Position) (int, int) {
	if total <= 0 {
		return 0, 0
	}
	mut lw := pos.at(total, 0)
	if lw < 0 {
		lw = 0
	}
	if lw > total {
		lw = total
	}
	return lw, total - lw
}

// block_width returns the visible width of the widest line in text.
pub fn block_width(text string) int {
	mut width := 0
	for line in text.split('\n') {
		w := term.printable_len(line)
		if w > width {
			width = w
		}
	}
	return width
}

// block_height returns the number of lines in text.
pub fn block_height(text string) int {
	return text.split('\n').len
}

// block_size returns the visible width and line count of text.
pub fn block_size(text string) Size {
	return Size{ width: block_width(text), height: block_height(text) }
}
