# termkit

A V toolkit for building interactive terminal applications.

> **Status: core implemented.** The MVU runtime, diffing renderer, styling,
> core widgets and the CLI framework are available. See `GOALS.md` for the
> definition of done and `PLAN.md` for the remaining work.

## Why

V already ships `term.ui` (terminal input and raw drawing primitives) and
`cli` (subcommands, flags, generated help). Both stop short of what modern
terminal apps need: there is no model/view/update runtime, no reusable widgets,
no styling system, no diffing renderer, and no completions or suggestions for
command line programs.

`termkit` fills those gaps in one zero-dependency VPM module. It uses `term.ui`
for platform input and adds the missing layers on top. It is and remains a
standalone package published as `mahdir-ir.termkit`; it is not proposed for
inclusion in the V standard library.

## Install

```v ignore
v install mahdir-ir.termkit
```

## Packages

| Import | Purpose |
| --- | --- |
| `termkit` | Program runtime, messages, commands, keys, filters, lifecycle hooks |
| `termkit.style` | Foreground/background, RGB/hex/ANSI-256 colors, attributes, borders, padding, margins, alignment |
| `termkit.widgets` | Text input, viewport, list, table, file picker, focus groups, spinner, progress, timer, help |
| `termkit.layout` | Rectangles, constraints, horizontal/vertical composition |
| `termkit.cli` | Commands, typed flags, validation, flag groups, help/man, suggestions, completion |

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

## Guides

See [docs/README.md](docs/README.md) for the full guide index. Generated API
references for every package live in [docs/api](docs/api).

## Examples

- `examples/counter.v` — a full MVU app with keyboard input and diffed output.
- `examples/cli_app.v` — a command tree with flags, help, version and
  completion support.
- `examples/widgets.v` — a filterable list with a text input and help bar.
- `examples/focus.v` — tab navigation between text inputs and a file picker.
- `examples/tabs_tree.v` — tabs plus a collapsible, navigable tree.
- `examples/timer.v` — stopwatch and countdown driven by an `every` command.
- `examples/style.v` — non-interactive styling and layout, safe to run in CI.
- `examples/headless.v` — MVU driven by injected messages, no TTY required.
- `examples/cli_complete.v` — subcommands, aliases, completion, persistent
  hooks and a typed flag with a default.

Larger applications are in `examples/apps/`: `todo.v`, `file_browser.v`,
`log_viewer.v` and `cli_tool.v`.

Run them from the repository root:

```v ignore
v run examples/cli_app.v -- --help
v run examples/style.v
v run examples/headless.v
v run examples/cli_complete.v -- serve -p 9000
v run examples/cli_complete.v -- __complete se
```

## C API

termkit also ships as a C library. The exported ABI is small and uses only C
types: opaque renderer handles, `const char *` strings and plain integers.

```sh
v run tools/build_c.v
```

This writes to `dist/c/`:

| File | Purpose |
| --- | --- |
| `termkit.dll` / `.so` / `.dylib` | shared library |
| `termkit.dll.a` (Windows) | import library linking against `termkit.dll` |
| `termkit_static.lib` / `libtermkit.a` | static library (built with `-gc none`) |
| `termkit.h` | C header |

The shared library uses V's Boehm GC. The static library uses `-gc none` so it
has no GC dependency; allocations live for the process lifetime, so prefer the
shared library for long-running hosts.

Example:

```c
#include "termkit.h"

TKRenderer *r = tk_renderer_new(40, 1, TK_PROFILE_ANSI);
tk_renderer_draw_text(r, 0, 0, "hello", "31", "", TK_ATTR_BOLD);
puts(tk_renderer_frame(r));
tk_renderer_free(r);
```

Returned strings are owned by the library and remain valid until the next call
to the same function. Build and run the smoke test:

```sh
gcc capi/test/smoke.c -I dist/c dist/c/termkit.dll.a -o smoke.exe
smoke.exe
```

On non-Windows platforms link with `-L dist/c -ltermkit` instead of the import
library.

## Design notes

- **Model / Message / Command.** State is owned by the model. Events arrive as
  messages; side effects are requested as commands. This is the Elm-style
  Model / Message / Command shape.
- **Commands are values, not bare closures.** V registers closure contexts in a
  process-wide table, so a per-keystroke closure would pin memory forever.
  `batch`, `sequence`, `tick` and `every` are data, not captured functions.
- **Rendering is diffed.** A cell grid is compared against the previous frame
  so only changed cells are emitted. The grid resizes on `WindowSizeMsg` and
  truecolor styles are downgraded on ANSI-256/16-color terminals. This avoids
  the tearing described in the `term.ui` README.
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
- **Lifecycle hooks.** `init_fn` runs when term.ui starts. `cleanup_fn` runs on
  both a normal `quit()` and a shutdown signal; on normal quit termkit also
  emits the reset, cursor-show and alternate-screen-leave sequences. CLI
  commands support `persistent_before`/`persistent_after` hooks that run for
  every descendant in root-to-leaf order.
- **File logging.** `log_to_file(path, message)` appends a line without
  disturbing the rendered frame.

## Relationship to existing V modules

- `term.ui` stays the input and raw-output layer. `termkit` consumes its public
  `Event`/`Context` API and does not fork it.
- `vlib/cli` is untouched. `termkit.cli` is a parallel,
  backwards-incompatible-by-design alternative with an error-returning API.
- `vlib/flag` remains the lightweight declarative parser for simple tools.

## Inspiration

The API follows established MVU and CLI conventions, adapted to
V-specific constraints around commands and closures. This is an independent
implementation under the MIT license.

## Paste, focus and repeat

`term.ui` has no dedicated event types for bracketed paste, terminal focus or
key repeat, but it passes unrecognised escape sequences through in
`Event.utf8`. termkit uses that path — no stdlib patching:

- **Paste.** On startup the runtime requests bracketed paste (`CSI ? 2004 h`).
  The `CSI 200 ~` / `CSI 201 ~` markers are turned into internal messages; all
  key events between them are accumulated and delivered to the model as one
  `PasteMsg`. The text input and text area widgets already accept it.
- **Focus.** The runtime requests focus reporting (`CSI ? 1004 h`). `CSI I`
  and `CSI O` become `FocusMsg` and `BlurMsg`. For focus between widgets use
  `FocusGroup` and `Focusable`; Tab / Shift+Tab routing is independent of the
  terminal.
- **Repeat.** CSI-u key reports with event type 3 are delivered as `KeyMsg`
  with kind `.repeat`; type 2 reports become `.release`.

Both terminal modes are best-effort: terminals that ignore them simply keep
sending ordinary events, and the program behaves as before. Windows' native
console API does not report these sequences; Windows Terminal with the
sequences enabled is expected to work.

## Deferred work

VPM registration is the only remaining outward step. termkit stays a standalone
package; there is no plan to fold it into `vlib` or open a `vlang/v` PR.

## License

MIT. See `LICENSE`.
