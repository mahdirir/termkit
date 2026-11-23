# module style


## Contents
- [Constants](#Constants)
- [ansi256_bg](#ansi256_bg)
- [ansi256_fg](#ansi256_fg)
- [from_hex](#from_hex)
- [rgb](#rgb)
- [BorderKind.from](#BorderKind.from)
- [BorderKind](#BorderKind)
- [Rgb](#Rgb)
  - [fg](#fg)
  - [bg](#bg)
- [Style](#Style)
  - [sgr](#sgr)
  - [apply](#apply)
  - [render](#render)

## Constants
```v ignore
const attr_bold = u8(1)
```

attr_bold marks text as bold.

[[Return to contents]](#Contents)

```v ignore
const attr_italic = u8(2)
```

attr_italic marks text as italic.

[[Return to contents]](#Contents)

```v ignore
const attr_underline = u8(4)
```

attr_underline marks text as underlined.

[[Return to contents]](#Contents)

```v ignore
const attr_reverse = u8(8)
```

attr_reverse marks text as reverse video.

[[Return to contents]](#Contents)

## ansi256_bg
```v ignore
fn ansi256_bg(index u8) string
```

ansi256_bg returns the SGR parameter for an indexed background color.

[[Return to contents]](#Contents)

## ansi256_fg
```v ignore
fn ansi256_fg(index u8) string
```

ansi256_fg returns the SGR parameter for an indexed foreground color.

[[Return to contents]](#Contents)

## from_hex
```v ignore
fn from_hex(text string) ?Rgb
```

from_hex parses a #RRGGBB string into a color.

[[Return to contents]](#Contents)

## rgb
```v ignore
fn rgb(r u8, g u8, b u8) Rgb
```

rgb creates a color from three 8-bit channels.

[[Return to contents]](#Contents)

## BorderKind.from
```v ignore
fn BorderKind.from[W](input W) !BorderKind
```

from returns the `BorderKind` value of an integer or of a field name, or an error if there is none.

[[Return to contents]](#Contents)

## BorderKind
```v ignore
enum BorderKind {
	none
	single
	rounded
	double
}
```

BorderKind selects the characters used for a box border.

[[Return to contents]](#Contents)

## Rgb
```v ignore
struct Rgb {
pub:
	r u8
	g u8
	b u8
}
```

Rgb is an 8-bit-per-channel color.

[[Return to contents]](#Contents)

## fg
```v ignore
fn (c Rgb) fg() string
```

fg returns the SGR parameter string for a 24-bit foreground color.

[[Return to contents]](#Contents)

## bg
```v ignore
fn (c Rgb) bg() string
```

bg returns the SGR parameter string for a 24-bit background color.

[[Return to contents]](#Contents)

## Style
```v ignore
struct Style {
pub mut:
	fg      string
	bg      string
	attrs   u8
	border  BorderKind = .none
	padding int
	margin  int
	align   layout.Align = .start
	width   int
	title   string
}
```

Style describes how a block of text is rendered.

[[Return to contents]](#Contents)

## sgr
```v ignore
fn (s Style) sgr() string
```

sgr returns the SGR sequence that activates this style.

[[Return to contents]](#Contents)

## apply
```v ignore
fn (s Style) apply(text string) string
```

apply wraps text in this style and a trailing reset.

[[Return to contents]](#Contents)

## render
```v ignore
fn (s Style) render(text string) string
```

render lays out text with margin, padding, alignment and an optional border. The returned string
contains SGR codes the termkit renderer parses.

[[Return to contents]](#Contents)

#### Powered by vdoc.
