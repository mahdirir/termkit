# termkit

A V toolkit for building terminal applications that can stand next to Go's
Bubble Tea, Bubbles, Lip Gloss and Cobra.

> **Status: core implemented.** The MVU runtime, diffing renderer, styling,
> core widgets and the CLI framework are available. See `GOALS.md` for the
> definition of done and `PLAN.md` for the remaining work.

## Why

V already ships `term.ui` (terminal input and raw drawing primitives) and
`cli` (subcommands, flags, generated help). Both stop short of what modern
terminal apps need: there is no model/view/update runtime, no reusable widgets,
no styling system, no diffing renderer, and no completions or suggestions for
command line programs.

`termkit` fills those gaps in one zero-dependency VPM module. It uses
`term.ui` for platform input, adds the missing layers on top, and is structured
so it can later be folded into the V standard library without a rewrite.

## Install

```v ignore
v install metif12.termkit
```

## Packages

| Import | Purpose |
| --- | --- |
| `termkit` | Program runtime, messages, commands, keys, filters, lifecycle hooks |
| `termkit.style` | Foreground/background, RGB/hex/ANSI-256 colors, attributes, borders, padding, margins, alignment |
| `termkit.widgets` | Text input, viewport, list, table, file picker, focus groups, spinner, progress, timer, help |
| `termkit.layout` | Rectangles, constraints, horizontal/vertical composition |
| `termkit.cli` | Commands, flags, validation, flag groups, help/man, suggestions, completion |

## Quickstart: an MVU app

```v ignore
module main

import termkit

struct Model {
mut:
	count int
	quit  bool
}

fn (mut m Model) init() termkit.Cmd {
	return termkit.no_cmd
}

fn (mut m Model) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.KeyMsg {
			match msg.key {
				'q' { return m, termkit.quit() }
				'+' { m.count++ }
				'-' { m.count-- }
				else {}
			}
		}
		else {}
	}
	return m, termkit.no_cmd
}

fn (mut m Model) view() string {
	return 'count: ${m.count}\npress + / - / q'
}

fn main() {
	mut model := &Model{}
	mut program := termkit.new_program(model, termkit.ProgramOpts{
		alt_screen: true
	})
	program.run()!
}
```

## Quickstart: a CLI app

```v ignore
module main

import os
import termkit.cli as cli

fn main() {
	mut root := cli.Command{
		name:        'demo'
		description: 'a small demo'
		version:     '0.1.0'
	}
	root.add_command(cli.Command{
		name:        'greet'
		description: 'greet someone'
		args_rule:   .at_least_one
		flags:       [cli.Flag{name: 'loud', abbrev: 'l', flag: .bool}]
		execute_fn:  fn () ! {
			println('hello!')
		}
	})
	root.run(os.args)!
}
```

## Examples

- `examples/counter.v` — a full MVU app with keyboard input and diffed output.
- `examples/cli_app.v` — a command tree with flags, help, version and
  completion support.
- `examples/widgets.v` — a filterable list with a text input and help bar.
- `examples/focus.v` — tab navigation between text inputs and a file picker.

Run them from the repository root:

```v ignore
v run examples/cli_app.v -- --help
```

## Design notes

- **Model / Message / Command.** State is owned by the model. Events arrive as
  messages; side effects are requested as commands. This is the Elm-style
  shape made popular by Bubble Tea.
- **Commands are values, not bare closures.** V registers closure contexts in a
  process-wide table, so a per-keystroke closure would pin memory forever.
  `batch`, `sequence`, `tick` and `every` are data, not captured functions.
- **Rendering is diffed.** A cell grid is compared against the previous frame
  so only changed cells are emitted. The grid resizes on `WindowSizeMsg`.
  This avoids the tearing described in the `term.ui` README.
- **No new C dependencies.** Everything is written in V and builds on the
  platform support already present in `term.ui`.
- **Testable without a terminal.** Rendering, widgets, parsing, help and
  completion are pure functions over buffers and strings.
- **Composable focus.** `Focusable` widgets are grouped with Tab / Shift+Tab
  routing, and the file picker plugs into the same group.
- **Mouse-aware widgets.** Lists, viewports and the file picker handle scroll
  and click messages using on-screen offsets.
- **Context-aware hooks.** `execute_with_fn` and friends receive the parsed
  command, and `out`/`err_out` capture generated output in tests.
- **Thread-safe messages.** `Program.send` can be called from spawned threads;
  the queue is mutex-protected and an optional filter can drop messages.
- **Lifecycle hooks.** `init_fn` and `cleanup_fn` run at the term.ui boundaries.

## Relationship to existing V modules

- `term.ui` stays the input and raw-output layer. `termkit` consumes its public
  `Event`/`Context` API and does not fork it.
- `vlib/cli` stays untouched in this phase. `termkit.cli` is a parallel,
  backwards-incompatible-by-design alternative with an error-returning API.
- `vlib/flag` remains the lightweight declarative parser for simple tools.

## Inspiration

The API is inspired by Bubble Tea, Bubbles, Lip Gloss and Cobra, and by
`tauraamui.bobatea` for the V-specific constraints around commands and
closures. No code from those projects is used; this is an independent
implementation under the MIT license.

## Deferred work

Publishing to VPM and proposing the layers for inclusion in `vlang/v` are
deliberate later steps. `PLAN.md` records the mapping from this module's
packages to future stdlib locations, including the small `term.ui` input
changes needed for true bracketed paste and focus events.

## License

MIT. See `LICENSE`.
