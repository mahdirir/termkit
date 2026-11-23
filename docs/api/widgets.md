# module widgets


## Contents
- [new_filepicker](#new_filepicker)
- [new_focus_group](#new_focus_group)
- [new_timer](#new_timer)
- [Focusable](#Focusable)
- [Binding](#Binding)
- [Confirm](#Confirm)
  - [focus](#focus)
  - [blur](#blur)
  - [is_focused](#is_focused)
  - [update](#update)
  - [view](#view)
- [Cursor](#Cursor)
  - [update](#update)
  - [view](#view)
- [FilePicker](#FilePicker)
  - [reload](#reload)
  - [focus](#focus)
  - [blur](#blur)
  - [is_focused](#is_focused)
  - [selection](#selection)
  - [update](#update)
  - [view](#view)
- [FocusGroup](#FocusGroup)
  - [add](#add)
  - [active_widget](#active_widget)
  - [focus_next](#focus_next)
  - [focus_prev](#focus_prev)
  - [focus_index](#focus_index)
  - [update](#update)
  - [view](#view)
- [Help](#Help)
  - [view](#view)
- [List](#List)
  - [set_items](#set_items)
  - [toggle](#toggle)
  - [selected_items](#selected_items)
  - [is_focused](#is_focused)
  - [selected_item](#selected_item)
  - [update](#update)
  - [view](#view)
- [Paginator](#Paginator)
  - [set_total](#set_total)
  - [start](#start)
  - [end](#end)
  - [update](#update)
  - [view](#view)
- [Progress](#Progress)
  - [set](#set)
  - [view](#view)
- [Spinner](#Spinner)
  - [update](#update)
  - [view](#view)
- [Stopwatch](#Stopwatch)
  - [start](#start)
  - [stop](#stop)
  - [reset](#reset)
  - [update](#update)
  - [view](#view)
- [Table](#Table)
  - [set_data](#set_data)
  - [update](#update)
  - [view](#view)
- [Tabs](#Tabs)
  - [set_tabs](#set_tabs)
  - [select](#select)
  - [active_name](#active_name)
  - [update](#update)
  - [view](#view)
- [TextArea](#TextArea)
  - [focus](#focus)
  - [blur](#blur)
  - [is_focused](#is_focused)
  - [set_text](#set_text)
  - [text](#text)
  - [update](#update)
  - [view](#view)
- [TextInput](#TextInput)
  - [focus](#focus)
  - [blur](#blur)
  - [is_focused](#is_focused)
  - [update](#update)
  - [view](#view)
- [Timer](#Timer)
  - [start](#start)
  - [stop](#stop)
  - [done](#done)
  - [update](#update)
  - [view](#view)
- [Tree](#Tree)
  - [set_nodes](#set_nodes)
  - [add_node](#add_node)
  - [selected_label](#selected_label)
  - [update](#update)
  - [view](#view)
- [TreeNode](#TreeNode)
- [Viewport](#Viewport)
  - [set_content](#set_content)
  - [line_count](#line_count)
  - [update](#update)
  - [view](#view)

## new_filepicker
```v ignore
fn new_filepicker(path string) !FilePicker
```

new_filepicker creates a picker for path, loading its entries.

[[Return to contents]](#Contents)

## new_focus_group
```v ignore
fn new_focus_group() FocusGroup
```

new_focus_group creates an empty group.

[[Return to contents]](#Contents)

## new_timer
```v ignore
fn new_timer(d time.Duration) Timer
```

new_timer creates a stopped timer for d.

[[Return to contents]](#Contents)

## Focusable
```v ignore
interface Focusable {
mut:
	update(termkit.Msg)
	view() string
	focus()
	blur()
	is_focused() bool
}
```

Focusable is a widget that can own keyboard focus.

[[Return to contents]](#Contents)

## Binding
```v ignore
struct Binding {
pub:
	key         string
	description string
}
```

Binding associates a key with a short description.

[[Return to contents]](#Contents)

## Confirm
```v ignore
struct Confirm {
pub mut:
	prompt   string = 'Are you sure?'
	value    bool
	answered bool
	focused  bool = true
}
```

Confirm is a yes/no prompt driven by y/n or left/right keys.

[[Return to contents]](#Contents)

## focus
```v ignore
fn (mut c Confirm) focus()
```

focus marks the confirm as accepting keys.

[[Return to contents]](#Contents)

## blur
```v ignore
fn (mut c Confirm) blur()
```

blur marks the confirm as not accepting keys.

[[Return to contents]](#Contents)

## is_focused
```v ignore
fn (c &Confirm) is_focused() bool
```

is_focused reports whether the confirm accepts keyboard input.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut c Confirm) update(msg termkit.Msg)
```

update handles confirmation keys.

[[Return to contents]](#Contents)

## view
```v ignore
fn (c Confirm) view() string
```

view renders the prompt and a highlighted choice.

[[Return to contents]](#Contents)

## Cursor
```v ignore
struct Cursor {
pub mut:
	visible bool   = true
	glyph   string = '█'
}
```

Cursor is a blinking block driven by tick messages.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut c Cursor) update(msg termkit.Msg)
```

update toggles visibility on each tick.

[[Return to contents]](#Contents)

## view
```v ignore
fn (c Cursor) view() string
```

view renders the cursor or a blank cell.

[[Return to contents]](#Contents)

## FilePicker
```v ignore
struct FilePicker {
pub mut:
	path        string
	entries     []string
	cursor      int
	height      int = 10
	width       int
	show_hidden bool
	selected    string
	// offset_x/offset_y locate the picker on screen for mouse hit-testing.
	offset_x int
	offset_y int
	focused  bool = true
}
```

FilePicker browses directories and selects a file. It follows the Bubbles file picker interaction
model: arrows move, Enter descends or selects and Backspace ascends.

[[Return to contents]](#Contents)

## reload
```v ignore
fn (mut p FilePicker) reload() !
```

reload refreshes the entry list from the current directory.

[[Return to contents]](#Contents)

## focus
```v ignore
fn (mut p FilePicker) focus()
```

focus marks the picker as accepting keys.

[[Return to contents]](#Contents)

## blur
```v ignore
fn (mut p FilePicker) blur()
```

blur marks the picker as not accepting keys.

[[Return to contents]](#Contents)

## is_focused
```v ignore
fn (p &FilePicker) is_focused() bool
```

is_focused reports whether the picker accepts keyboard input.

[[Return to contents]](#Contents)

## selection
```v ignore
fn (p FilePicker) selection() string
```

selection returns the last selected absolute path.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut p FilePicker) update(msg termkit.Msg)
```

update handles navigation and selection keys.

[[Return to contents]](#Contents)

## view
```v ignore
fn (p FilePicker) view() string
```

view renders a window of entries around the cursor.

[[Return to contents]](#Contents)

## FocusGroup
```v ignore
struct FocusGroup {
pub mut:
	widgets []Focusable
	active  int
}
```

FocusGroup routes input to one focused widget at a time. Tab and shift+tab move focus; any other
message is delivered only to the active widget.

[[Return to contents]](#Contents)

## add
```v ignore
fn (mut g FocusGroup) add(widget Focusable)
```

add appends a widget and focuses it when it is the first one.

[[Return to contents]](#Contents)

## active_widget
```v ignore
fn (mut g FocusGroup) active_widget() ?Focusable
```

active_widget returns the currently focused widget, if any.

[[Return to contents]](#Contents)

## focus_next
```v ignore
fn (mut g FocusGroup) focus_next()
```

focus_next moves focus to the following widget.

[[Return to contents]](#Contents)

## focus_prev
```v ignore
fn (mut g FocusGroup) focus_prev()
```

focus_prev moves focus to the previous widget.

[[Return to contents]](#Contents)

## focus_index
```v ignore
fn (mut g FocusGroup) focus_index(index int)
```

focus_index focuses the widget at index.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut g FocusGroup) update(msg termkit.Msg)
```

update routes a message to the focused widget.

[[Return to contents]](#Contents)

## view
```v ignore
fn (mut g FocusGroup) view() string
```

view renders every widget in the group, one per line.

[[Return to contents]](#Contents)

## Help
```v ignore
struct Help {
pub mut:
	bindings []Binding
	width    int
}
```

Help renders a compact two-column keybinding list.

[[Return to contents]](#Contents)

## view
```v ignore
fn (h Help) view() string
```

view renders the bindings.

[[Return to contents]](#Contents)

## List
```v ignore
struct List {
pub mut:
	items    []string
	selected int
	filter   string
	height   int = 10
	width    int
	// offset_x/offset_y locate the list on screen for mouse hit-testing.
	offset_x int
	offset_y int
	// multi_select allows several items to be marked with the space key.
	multi_select bool
	marked       []bool
	focused      bool = true
}
```

List is a filterable, scrollable selection list.

[[Return to contents]](#Contents)

## set_items
```v ignore
fn (mut l List) set_items(items []string)
```

set_items replaces the items and resets selection and filter.

[[Return to contents]](#Contents)

## toggle
```v ignore
fn (mut l List) toggle()
```

toggle marks or unmarks the selected item when multi_select is enabled.

[[Return to contents]](#Contents)

## selected_items
```v ignore
fn (l List) selected_items() []string
```

selected_items returns the values of all marked items in declaration order.

[[Return to contents]](#Contents)

## is_focused
```v ignore
fn (l &List) is_focused() bool
```

is_focused reports whether this list accepts keyboard input.

[[Return to contents]](#Contents)

## selected_item
```v ignore
fn (l List) selected_item() string
```

selected_item returns the currently selected string, if any.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut l List) update(msg termkit.Msg)
```

update handles navigation and filter editing.

[[Return to contents]](#Contents)

## view
```v ignore
fn (l List) view() string
```

view renders the visible slice, marking the selection.

[[Return to contents]](#Contents)

## Paginator
```v ignore
struct Paginator {
pub mut:
	page     int
	per_page int = 10
	total    int
}
```

Paginator tracks a page over an item count.

[[Return to contents]](#Contents)

## set_total
```v ignore
fn (mut p Paginator) set_total(total int)
```

set_total updates the item count and keeps the page in range.

[[Return to contents]](#Contents)

## start
```v ignore
fn (p Paginator) start() int
```

start returns the index of the first item on the current page.

[[Return to contents]](#Contents)

## end
```v ignore
fn (p Paginator) end() int
```

end returns the index just past the last item on the current page.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut p Paginator) update(msg termkit.Msg)
```

update handles left/right page navigation.

[[Return to contents]](#Contents)

## view
```v ignore
fn (p Paginator) view() string
```

view renders a compact page indicator.

[[Return to contents]](#Contents)

## Progress
```v ignore
struct Progress {
pub mut:
	percent int
	width   int = 20
}
```

Progress is a simple percentage bar.

[[Return to contents]](#Contents)

## set
```v ignore
fn (mut p Progress) set(value int)
```

set clamps and stores a percentage.

[[Return to contents]](#Contents)

## view
```v ignore
fn (p Progress) view() string
```

view renders the bar and percentage.

[[Return to contents]](#Contents)

## Spinner
```v ignore
struct Spinner {
pub mut:
	frames []string = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
	frame  int
	label  string
}
```

Spinner shows an animated progress indicator driven by TickMsg messages.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut s Spinner) update(msg termkit.Msg)
```

update advances the animation on any tick message.

[[Return to contents]](#Contents)

## view
```v ignore
fn (s Spinner) view() string
```

view renders the current frame.

[[Return to contents]](#Contents)

## Stopwatch
```v ignore
struct Stopwatch {
pub mut:
	running bool
	elapsed time.Duration
	last_at i64
}
```

Stopwatch accumulates elapsed time from TickMsg timestamps.

[[Return to contents]](#Contents)

## start
```v ignore
fn (mut s Stopwatch) start()
```

start begins counting. The next tick establishes a fresh baseline so time spent paused is not
counted.

[[Return to contents]](#Contents)

## stop
```v ignore
fn (mut s Stopwatch) stop()
```

stop pauses counting.

[[Return to contents]](#Contents)

## reset
```v ignore
fn (mut s Stopwatch) reset()
```

reset clears the elapsed time.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut s Stopwatch) update(msg termkit.Msg)
```

update accumulates time between tick messages.

[[Return to contents]](#Contents)

## view
```v ignore
fn (s Stopwatch) view() string
```

view renders seconds with one decimal place.

[[Return to contents]](#Contents)

## Table
```v ignore
struct Table {
pub mut:
	headers  []string
	rows     [][]string
	widths   []int
	selected int
	// offset is the first visible row when height limits the view.
	offset int
	height int
}
```

Table renders rows of cells with a selectable row.

[[Return to contents]](#Contents)

## set_data
```v ignore
fn (mut t Table) set_data(headers []string, rows [][]string)
```

set_data replaces the table contents.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut t Table) update(msg termkit.Msg)
```

update moves the selection.

[[Return to contents]](#Contents)

## view
```v ignore
fn (t Table) view() string
```

view renders the header and visible rows.

[[Return to contents]](#Contents)

## Tabs
```v ignore
struct Tabs {
pub mut:
	tabs   []string
	active int
}
```

Tabs is a horizontal row of selectable tabs.

[[Return to contents]](#Contents)

## set_tabs
```v ignore
fn (mut t Tabs) set_tabs(tabs []string)
```

set_tabs replaces the tab labels and selects the first one.

[[Return to contents]](#Contents)

## select
```v ignore
fn (mut t Tabs) select(index int)
```

select activates the tab at index, if it exists.

[[Return to contents]](#Contents)

## active_name
```v ignore
fn (t Tabs) active_name() string
```

active_name returns the label of the active tab, or an empty string.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut t Tabs) update(msg termkit.Msg)
```

update handles left/right/home/end navigation for a key press.

[[Return to contents]](#Contents)

## view
```v ignore
fn (t Tabs) view() string
```

view renders the tab row, marking the active tab with brackets.

[[Return to contents]](#Contents)

## TextArea
```v ignore
struct TextArea {
pub mut:
	lines   []string
	row     int
	col     int
	width   int
	height  int
	focused bool = true
}
```

TextArea is a small multi-line editor.

[[Return to contents]](#Contents)

## focus
```v ignore
fn (mut t TextArea) focus()
```

focus marks the text area as accepting keys.

[[Return to contents]](#Contents)

## blur
```v ignore
fn (mut t TextArea) blur()
```

blur marks the text area as not accepting keys.

[[Return to contents]](#Contents)

## is_focused
```v ignore
fn (t &TextArea) is_focused() bool
```

is_focused reports whether the text area accepts keyboard input.

[[Return to contents]](#Contents)

## set_text
```v ignore
fn (mut t TextArea) set_text(text string)
```

set_text replaces the content and moves the cursor to the end.

[[Return to contents]](#Contents)

## text
```v ignore
fn (t TextArea) text() string
```

text returns the joined content.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut t TextArea) update(msg termkit.Msg)
```

update handles editing and navigation keys.

[[Return to contents]](#Contents)

## view
```v ignore
fn (t TextArea) view() string
```

view renders a window of lines around the cursor.

[[Return to contents]](#Contents)

## TextInput
```v ignore
struct TextInput {
pub mut:
	prompt   string = '> '
	value    string
	position int
	// mask, when non-zero, replaces each character in the rendered value.
	mask    u8
	focused bool = true
}
```

TextInput is a single-line editable field.

[[Return to contents]](#Contents)

## focus
```v ignore
fn (mut t TextInput) focus()
```

focus marks the input as accepting keys.

[[Return to contents]](#Contents)

## blur
```v ignore
fn (mut t TextInput) blur()
```

blur marks the input as not accepting keys.

[[Return to contents]](#Contents)

## is_focused
```v ignore
fn (t &TextInput) is_focused() bool
```

is_focused reports whether this input accepts keyboard input.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut t TextInput) update(msg termkit.Msg)
```

update handles editing keys and printable text.

[[Return to contents]](#Contents)

## view
```v ignore
fn (t TextInput) view() string
```

view renders the prompt, value and a cursor marker. When mask is set, the value is hidden behind the
mask glyph.

[[Return to contents]](#Contents)

## Timer
```v ignore
struct Timer {
pub mut:
	remaining time.Duration
	last_at   i64
	running   bool
}
```

Timer counts down from a duration and reports completion through done().

[[Return to contents]](#Contents)

## start
```v ignore
fn (mut t Timer) start()
```

start begins counting down. The next tick establishes a fresh baseline so time spent paused is not
counted.

[[Return to contents]](#Contents)

## stop
```v ignore
fn (mut t Timer) stop()
```

stop pauses the countdown.

[[Return to contents]](#Contents)

## done
```v ignore
fn (t Timer) done() bool
```

done reports whether the countdown reached zero.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut t Timer) update(msg termkit.Msg)
```

update decrements the remaining time from tick timestamps.

[[Return to contents]](#Contents)

## view
```v ignore
fn (t Timer) view() string
```

view renders the remaining whole seconds.

[[Return to contents]](#Contents)

## Tree
```v ignore
struct Tree {
pub mut:
	nodes  []TreeNode
	cursor int
}
```

Tree is a navigable, collapsible hierarchy of nodes.

[[Return to contents]](#Contents)

## set_nodes
```v ignore
fn (mut t Tree) set_nodes(nodes []TreeNode)
```

set_nodes replaces the tree contents and selects the first node.

[[Return to contents]](#Contents)

## add_node
```v ignore
fn (mut t Tree) add_node(label string, parent int) int
```

add_node appends a node and returns its index.

[[Return to contents]](#Contents)

## selected_label
```v ignore
fn (t Tree) selected_label() string
```

selected_label returns the label of the selected node, or an empty string.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut t Tree) update(msg termkit.Msg)
```

update handles tree navigation and expansion for a key press.

[[Return to contents]](#Contents)

## view
```v ignore
fn (t Tree) view() string
```

view renders the visible nodes with indentation and expand markers.

[[Return to contents]](#Contents)

## TreeNode
```v ignore
struct TreeNode {
pub mut:
	label    string
	parent   int  = -1
	expanded bool = true
}
```

TreeNode is a node in a Tree. Children are nodes whose parent equals this node's index in the tree's
node array.

[[Return to contents]](#Contents)

## Viewport
```v ignore
struct Viewport {
pub mut:
	lines  []string
	offset int
	height int = 10
	width  int
	// offset_x/offset_y locate the viewport on screen for mouse hit-testing.
	offset_x int
	offset_y int
}
```

Viewport shows a scrollable window over a list of lines.

[[Return to contents]](#Contents)

## set_content
```v ignore
fn (mut v Viewport) set_content(lines []string)
```

set_content replaces the content and keeps the offset in range.

[[Return to contents]](#Contents)

## line_count
```v ignore
fn (v Viewport) line_count() int
```

line_count returns the total number of content lines.

[[Return to contents]](#Contents)

## update
```v ignore
fn (mut v Viewport) update(msg termkit.Msg)
```

update handles scrolling keys.

[[Return to contents]](#Contents)

## view
```v ignore
fn (v Viewport) view() string
```

view renders the visible lines.

[[Return to contents]](#Contents)

#### Powered by vdoc.
