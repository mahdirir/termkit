# Styling and layout guide

Styling and layout are pure string and integer functions in `termkit.style` and
`termkit.layout`. They need no terminal, which makes them easy to test.

## Colors

`style.Rgb` holds 8-bit `r`, `g`, `b` channels. Create one with `style.rgb(r, g,
b)` or parse a hex string with `style.from_hex('#RRGGBB')`, which returns
`?Rgb` (`none` on a malformed string). The methods `fg()` and `bg()` return SGR
parameter strings such as `38;2;255;220;120`, suitable for a `Style` field or
for `Renderer.set_cell`:

```v ignore
import termkit.style

gold := style.rgb(255, 220, 120)
maybe := style.from_hex('#ffdc78')
if c := maybe {
	println(c.fg())
}
println(gold.bg())
```

Indexed colors use `style.ansi256_fg(index)` and `style.ansi256_bg(index)`,
producing `38;5;N` and `48;5;N`. The attribute bits are `style.attr_bold`,
`attr_italic`, `attr_underline`, `attr_reverse`, `attr_faint`, `attr_blink`
and `attr_strike`; combine them with `|` in a `Style.attrs` value.
`Style.underline_style` selects single, double, curly, dotted or dashed
underlines (SGR `4:x`), and `Style.underline_color` sets the underline color.
`Style.link` wraps `apply` output in an OSC8 hyperlink (use `apply` directly;
the cell renderer only parses SGR).

The renderer adapts truecolor to the terminal. `termkit.detect_color_profile()`
reads `NO_COLOR`, `COLORTERM` and `TERM` and returns a `ColorProfile` of
`.ascii`, `.ansi`, `.ansi256` or `.truecolor`. The pure form
`termkit.color_profile_from_env(no_color, colorterm, term_name)` is testable
without touching the process environment. Truecolor styles are downgraded to
ANSI-256 or basic ANSI as needed.

## Style

`style.Style` fields:

| Field | Meaning |
| --- | --- |
| `fg`, `bg` | SGR parameter strings for foreground/background |
| `attrs` | Combined attribute bits |
| `border` | `.none`, `.single`, `.rounded` or `.double` |
| `padding`, `margin` | Cell padding inside and space around the block |
| `width` | Target content width |
| `align` | `.start`, `.center` or `.end` |
| `title` | Label embedded in the top border |

`sgr()` returns the activating sequence, `apply(text)` wraps text with a reset,
and `render(text)` lays out the block with margin, padding, alignment and an
optional border:

```v ignore
import termkit.layout
import termkit.style

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
```

Borders use box-drawing glyphs: single `┌─┐│└┘`, rounded `╭─╮│╰╯`, double
`╔═╗║╚╝`. Padding is applied inside the border, margin outside it. `align`
controls placement of shorter lines within the computed width.

## Renderer and SGR

The termkit renderer parses SGR sequences embedded in text passed to
`draw_text`: colors (basic, ANSI-256 and 24-bit) and the bold/italic/underline/
reverse attributes become cell styles, while other escape sequences are
ignored. This is why a string produced by `Style.render()` can be returned
directly from a model's `view()` and will still look styled after diffing.
Carriage returns, newlines and tabs are interpreted as cursor movement;
combining marks and joiners stay with their base glyph in one cell.

## Layout

`layout.Rect` is a rectangle in cell coordinates with `x`, `y`, `width` and
`height`. Its helpers:

- `right()`, `bottom()`, `contains(x, y)`, `inset(n)`.
- `layout.intersect(a, b)` returns `?Rect` (none when disjoint).
- `layout.join(rects)` returns the smallest rectangle containing all inputs.

`layout.Size` is a `{ width, height }` pair. `hstack` and `vstack` lay rectangles
out left-to-right and top-to-bottom; the `x` of each rectangle after the first
acts as a horizontal gap in `hstack`, and likewise `y` in `vstack`. The result
is the enclosing rectangle. `place(outer, size, align)` positions a size inside
an outer rect with horizontal alignment and vertical centering:

```v ignore
import termkit.layout

a := layout.Rect{ width: 10, height: 2 }
b := layout.Rect{ width: 5, height: 3 }
stacked := layout.hstack([a, b])
println('hstack: ${stacked.width}x${stacked.height}')
inside := layout.place(stacked, layout.Size{ width: 4, height: 1 },
	layout.Align.center)
println(inside.contains(3, 1))
```

`layout.Align` is also the type used by `Style.align`, so the two systems
share the same `start` / `center` / `end` vocabulary.

## Clamp, wrap, inherit and measure

`Style.max_width` and `max_height` clamp block rendering, and `Style.inline`
skips block layout so only inline SGR attributes apply. `style.wrap_text(text,
width)` word-wraps to a visible width, carrying ANSI sequences along without
counting them. `child.inherit(parent)` fills every unset field from the parent
(empty strings, zero numbers and `.none` variants count as unset; attribute
bits combine).

`layout.place_full(outer, size, halign, valign)` places with independent
horizontal and vertical alignment (`place` centers vertically).
`layout.position(v)` clamps `v` into a proportional `[0, 1]` placement, and
`pos.at(total, size)` resolves it to an offset; `layout.split_at(total, pos)`
divides cells proportionally. `layout.block_width`, `block_height` and
`block_size` measure text in visible cells and lines.
