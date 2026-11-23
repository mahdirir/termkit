# module layout


## Contents
- [hstack](#hstack)
- [intersect](#intersect)
- [join](#join)
- [place](#place)
- [vstack](#vstack)
- [Align.from](#Align.from)
- [Align](#Align)
- [Rect](#Rect)
  - [right](#right)
  - [bottom](#bottom)
  - [contains](#contains)
  - [inset](#inset)
- [Size](#Size)

## hstack
```v ignore
fn hstack(rects []Rect) Rect
```

hstack lays rectangles out left to right. A rectangle's x may place a gap after the previous
rectangle; a smaller x is treated as zero gap.

[[Return to contents]](#Contents)

## intersect
```v ignore
fn intersect(a Rect, b Rect) ?Rect
```

intersect returns the overlapping part of two rectangles.

[[Return to contents]](#Contents)

## join
```v ignore
fn join(rects []Rect) Rect
```

join returns the smallest rectangle containing all given rectangles.

[[Return to contents]](#Contents)

## place
```v ignore
fn place(outer Rect, size Size, align Align) Rect
```

place positions size inside outer using the given horizontal alignment and vertical centering.

[[Return to contents]](#Contents)

## vstack
```v ignore
fn vstack(rects []Rect) Rect
```

vstack lays rectangles out top to bottom. A rectangle's y may place a gap after the previous
rectangle; a smaller y is treated as zero gap.

[[Return to contents]](#Contents)

## Align.from
```v ignore
fn Align.from[W](input W) !Align
```

from returns the `Align` value of an integer or of a field name, or an error if there is none.

[[Return to contents]](#Contents)

## Align
```v ignore
enum Align {
	start
	center
	end
}
```

Align controls placement along an axis.

[[Return to contents]](#Contents)

## Rect
```v ignore
struct Rect {
pub:
	x      int
	y      int
	width  int
	height int
}
```

Rect is a rectangle in cell coordinates.

[[Return to contents]](#Contents)

## right
```v ignore
fn (r Rect) right() int
```

right returns the column just past the rectangle.

[[Return to contents]](#Contents)

## bottom
```v ignore
fn (r Rect) bottom() int
```

bottom returns the row just past the rectangle.

[[Return to contents]](#Contents)

## contains
```v ignore
fn (r Rect) contains(x int, y int) bool
```

contains reports whether x,y falls inside the rectangle.

[[Return to contents]](#Contents)

## inset
```v ignore
fn (r Rect) inset(n int) Rect
```

inset shrinks the rectangle by n cells on every side.

[[Return to contents]](#Contents)

## Size
```v ignore
struct Size {
pub:
	width  int
	height int
}
```

Size is a width/height pair.

[[Return to contents]](#Contents)

#### Powered by vdoc.
