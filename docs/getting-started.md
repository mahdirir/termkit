# Getting started

## Install

Install the module from VPM:

```sh
v install metif12.termkit
```

termkit is and remains a standalone package (`metif12.termkit`). It is not
submitted to, or folded into, the V standard library.

Import only the packages you need:

| Import | What it provides |
| --- | --- |
| `termkit` | `Program`, `Model`, `Msg`, `Cmd`, keys, renderer |
| `termkit.widgets` | Text input, list, table, tree, file picker, progress |
| `termkit.style` | Colors, attributes, borders, padding, margins |
| `termkit.layout` | Rectangles, sizes, stacking and placement |
| `termkit.cli` | Commands, typed flags, help, completion |

## A minimal MVU program

A termkit app owns its state in a model with three methods: `init`, `update`
and `view`. Save this as `main.v` in a directory with a `v.mod` that depends on
`metif12.termkit`:

```v ignore
module main

import termkit

struct Counter {
mut:
	n int
}

fn (mut m Counter) init() termkit.Cmd {
	return termkit.no_cmd
}

fn (mut m Counter) update(msg termkit.Msg) (termkit.Model, termkit.Cmd) {
	match msg {
		termkit.KeyMsg {
			match msg.key {
				'q' {
					return m, termkit.quit()
				}
				'+' {
					m.n++
				}
				'-' {
					m.n--
				}
				else {}
			}
		}
		else {}
	}
	return m, termkit.no_cmd
}

fn (mut m Counter) view() string {
	return 'Count: ${m.n}\n\n+ / - to change, q to quit'
}

fn main() {
	mut model := &Counter{}
	mut program := termkit.new_program(model, termkit.ProgramOpts{
		alt_screen: true
	})
	program.run()!
}
```

Build and run it with `v run .`, then press `+`, `-` and `q`. The full version
of this program is `examples/counter.v`.

## Running the bundled examples

From the repository root:

```sh
# Interactive MVU apps (need a terminal)
v run examples/counter.v
v run examples/widgets.v
v run examples/focus.v
v run examples/tabs_tree.v
v run examples/timer.v

# Non-interactive; safe in CI
v run examples/style.v
v run examples/headless.v

# CLI apps; pass arguments after "--"
v run examples/cli_app.v -- --help
v run examples/cli_complete.v -- serve -p 9000
v run examples/cli_complete.v -- __complete se
```

The `--` separates V's own arguments from the arguments delivered to the
example program. Interactive examples use the terminal alternate screen by
default and restore it when the program quits.

The `headless.v` example drives a model with injected messages and never opens
a TTY; it is the simplest starting point for tests.

## Where to go next

Read the [MVU guide](mvu-guide.md) to understand messages and commands, then
the [Widgets guide](widgets-guide.md) to compose an interface. For a command
line tool, start with the [CLI guide](cli-guide.md).
