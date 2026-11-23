# Widgets guide

Widgets live in `termkit.widgets`. They are plain structs: construct one in your
model's `init`, forward messages to `update` and concatenate `view()` output in
the model's `view`. Most widgets return `void` from `update` and do not produce
commands of their own.

A typical model looks like this:

```v ignore
module main

import termkit
import termkit.widgets

struct App {
mut:
	input widgets.TextInput
	list  widgets.List
	help  widgets.Help
}

fn (mut m App) init() termkit.Cmd {
	m.list.set_items(['alpha', 'beta', 'gamma'])
	m.help.bindings = [widgets.Binding{ key: 'q', description: 'quit' }]
	return termkit.no_cmd
}

fn (mut m App) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.KeyMsg {
			if msg.key == 'q' {
				return m, termkit.quit()
			}
			if msg.key in [termkit.key_up, termkit.key_down] {
				m.list.update(msg)
			} else {
				m.input.update(msg)
				m.list.filter = m.input.value
			}
		}
		else {}
	}
	return m, termkit.no_cmd
}

fn (mut m App) view() string {
	return m.input.view() + '\n\n' + m.list.view() + '\n\n' + m.help.view()
}
```

## TextInput

A single-line editor. Fields: `prompt` (default `'> '`), `value`, `position`,
`mask` (a glyph byte that hides the value) and `focused`. Methods: `focus`,
`blur`, `is_focused`, `update`, `view`. Editing keys are left/right, home/end,
backspace/delete and printable UTF-8 text; it also accepts `PasteMsg`.

```v ignore
mut name := widgets.TextInput{ prompt: 'Name: ' }
name.update(msg)  // forward KeyMsg / PasteMsg
println(name.view())
println(name.value)
```

## TextArea

A small multi-line editor. Fields: `lines`, `row`, `col`, `width`, `height` and
`focused`. Methods: `set_text`, `text`, `focus`, `blur`, `is_focused`, `update`,
`view`. Add/remove lines with Enter and Backspace, navigate with arrows and
home/end. `view()` shows `height` lines (all lines when `height == 0`),
truncated and padded to `width` when `width > 0`.

## Viewport

A scrollable window over lines. Fields: `lines`, `offset`, `height` (default
10), `width`, `offset_x` and `offset_y` (screen position for mouse hit
testing). Methods: `set_content`, `line_count`, `update`, `view`. Scrolling
keys are up/down, pgup/pgdown and home/end; it also handles `WindowSizeMsg`
and scroll `MouseMsg` when the pointer is inside `offset_y .. offset_y+height`.

```v ignore
mut doc := widgets.Viewport{ height: 8, width: 60 }
doc.set_content(lines)
doc.update(msg)
println(doc.view())
```

## List

A filterable selection list. Fields: `items`, `selected`, `filter`, `height`
(default 10), `width`, `offset_x`, `offset_y`, `multi_select`, `marked` and
`focused`. Methods: `set_items`, `toggle`, `selected_items`, `selected_item`,
`focus`, `blur`, `is_focused`, `update`, `view`. Up/down move the selection;
ordinary characters extend the filter and backspace shortens it. With
`multi_select: true`, Space toggles the marked item (`*` in the view);
otherwise Space is part of the filter. Mouse scroll and left click work when
`offset_x`/`offset_y` locate the list on screen.

## Table

Rows of cells with a selectable row. Fields: `headers`, `rows`, `widths`,
`selected`, `height` and `offset`. Methods: `set_data(headers, rows)`,
`update` and `view`. Column widths are measured from the data by `set_data`.
Up/down move `selected`; `offset` is the first visible row and is clamped
automatically against `height`, so `view()` renders only the visible slice.

```v ignore
mut table := widgets.Table{ height: 6 }
table.set_data(['name', 'size'], [['a.v', '12'], ['b.v', '30']])
table.update(msg)
println(table.view())
```

## Tabs

A horizontal row of labels. Fields: `tabs` and `active`. Methods: `set_tabs`,
`select(index)`, `active_name()`, `update` and `view`. Left/right and
home/end change the active tab; brackets mark it in `view()`.

## Tree

A navigable, collapsible hierarchy. A `TreeNode` has `label`, `parent` (index
of its parent, `-1` for roots) and `expanded`. `Tree` has `nodes` and `cursor`.
Methods: `set_nodes`, `add_node(label, parent)` (returns the index),
`selected_label`, `update` and `view`. Up/down move among visible nodes;
left collapses or moves to the parent, right expands or moves to a child.

```v ignore
mut tree := widgets.Tree{}
root := tree.add_node('project', -1)
tree.add_node('src', root)
tree.add_node('main.v', 1)
tree.update(msg)
println(tree.view())
```

## FilePicker

A directory browser. Construct it with `widgets.new_filepicker(path)!`.
Fields include `path`, `entries`, `cursor`, `height` (default 10), `width`,
`show_hidden`, `selected`, `offset_x`, `offset_y` and `focused`. Methods:
`reload`, `focus`, `blur`, `is_focused`, `selection`, `update` and `view`.
Arrows move, Enter descends or selects a file, Backspace goes up; directories
are shown with a trailing `/`. Scroll and click are supported.

```v ignore
mut picker := widgets.new_filepicker('.') or { widgets.FilePicker{ path: '.' } }
picker.update(msg)
println(picker.view())
if picker.selection() != '' {
	println('chose ${picker.selection()}')
}
```

## Spinner, Progress, Stopwatch and Timer

These are display widgets driven by `TickMsg`.

- `Spinner` has `frames`, `frame` and `label`. `update` advances `frame` on any
  `TickMsg`; `view` renders the current frame with the label.
- `Progress` has `percent` and `width` (default 20). Call `set(value)` to clamp
  into 0..100; `view` renders a `█`/`░` bar with a percentage.
- `Stopwatch` accumulates elapsed time from tick timestamps. Use `start`,
  `stop`, `reset`, `update(msg)`, `view`; it shows seconds with one decimal.
- `Timer` counts down. Use `new_timer(duration)`, `start`, `stop`, `done`,
  `update(msg)`, `view`. Both time widgets ignore paused time because the
  first tick after `start` establishes a fresh baseline.

```v ignore
fn tick_message(at i64) termkit.Msg {
	return termkit.TickMsg{ id: 1, at: at }
}

fn (mut m App) init() termkit.Cmd {
	m.stopwatch.start()
	return termkit.every(1, 100 * time.millisecond, tick_message)
}

fn (mut m App) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	m.stopwatch.update(msg)
	m.spinner.update(msg)
	return m, termkit.no_cmd
}
```

## FocusGroup

`Focusable` is the interface used by `FocusGroup`: `update(Msg)`, `view()`,
`focus()`, `blur()` and `is_focused()`. `TextInput`, `TextArea`, `List` and
`FilePicker` implement it. Create a group with `new_focus_group()`, add widgets
with `add`, then forward messages to `group.update(msg)`. Tab moves to the next
widget, Shift+Tab to the previous; other messages go only to the active
widget. `focus_index(i)`, `focus_next()`, `focus_prev()` and `active_widget()`
are also available. `view()` prefixes the active widget with `•`.

```v ignore
mut group := widgets.new_focus_group()
group.add(widgets.TextInput{ prompt: 'Name: ' })
group.add(widgets.TextInput{ prompt: 'Filter: ' })
group.update(msg)
println(group.view())
```

## Help

`Binding` has a `key` and `description`. `Help` holds `bindings` and an
optional `width`. Its `view()` renders a compact two-column list, truncating
lines to `width` when set. There is no `update` method.
