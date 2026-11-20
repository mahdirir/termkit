# termkit

A V toolkit for building terminal applications that can stand next to Go's
Bubble Tea, Bubbles, Lip Gloss and Cobra.

> **Status: in development.** Code snippets below describe the target API.
> See `GOALS.md` for the definition of done and `PLAN.md` for the build order.

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
| `termkit` | Program runtime, messages, commands, key handling, options |
| `termkit.style` | Foreground/background, attributes, borders, padding, alignment |
| `termkit.widgets` | Text input, viewport, list, table, spinner, progress, help |
| `termkit.layout` | Rectangles, constraints, horizontal/vertical composition |
| `termkit.cli` | Commands, flags, validation, help/man, suggestions, completion |

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
	termkit.new_program(mut model, termkit.ProgramOpts{
		alt_screen: true
	}).run()!
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
		flags:       [cli.Flag{name: 'loud', abbrev: 'l', flag: .bool}]
		execute:     fn (cmd cli.Command) ! {
			name := if cmd.args.len > 0 { cmd.args[0] } else { 'world' }
			println('hello, ${name}!')
		}
	})
	root.run(os.args)!
}
```

## Design notes

- **Model / Message / Command.** State is owned by the model. Events arrive as
  messages; side effects are requested as commands. This is the Elm-style
  shape made popular by Bubble Tea.
- **Commands are values, not bare closures.** V registers closure contexts in a
  process-wide table, so a per-keystroke closure would pin memory forever.
  `batch`, `sequence`, `tick` and `every` are data, not captured functions.
- **Rendering is diffed.** A cell grid is compared against the previous frame
  so only changed cells are emitted. This avoids the tearing described in the
  `term.ui` README.
- **No new C dependencies.** Everything is written in V and builds on the
  platform support already present in `term.ui`.
- **Testable without a terminal.** Rendering, widgets, parsing, help and
  completion are pure functions over buffers and strings.

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
