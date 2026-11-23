# Testing guide

termkit is designed to be testable without a terminal. Rendering, widgets,
parsing, help, completion and layout are pure functions over buffers and
strings, and the MVU runtime can be driven with injected messages.

## Pure functions

Test these directly, with no `Program` and no TTY:

- `style.Style.render`, `apply` and `sgr`; `style.from_hex` and the color
  helpers.
- `layout.Rect` helpers, `hstack`, `vstack`, `intersect`, `join`, `place`.
- `termkit.new_renderer(...).draw_text(...).frame()` — the diffed frame is a
  string you can assert on.
- `termkit.delivered_msgs(cmd)` — inspect the messages a command would emit
  without running timers.
- `cli.Command.help_message()` and `manpage()`, `cli.completion_result(...)`,
  `cli.suggest(...)` and `cli.levenshtein(...)`.
- Widget `view()` output after feeding `update()` synthetic messages.

## Injected messages

For runtime behaviour, build a headless `Program` with `without_renderer: true`
and optionally an `out` callback. Call `send` for each message, then
`process_queue()` to deliver them, then assert on `view()`:

```v ignore
module termkit

struct Echo {
mut:
	seen []string
}

fn (mut m Echo) init() Cmd {
	return no_cmd
}

fn (mut m Echo) update(msg Msg) (Model, Cmd) {
	match msg {
		KeyMsg {
			m.seen << msg.key
		}
		else {}
	}
	return m, no_cmd
}

fn (mut m Echo) view() string {
	return m.seen.join(' ')
}

fn test_echo_processes_keys() {
	mut p := new_program(&Echo{}, ProgramOpts{ without_renderer: true })
	p.send(KeyMsg{ key: 'h' })
	p.send(KeyMsg{ key: 'i' })
	p.process_queue()
	assert p.view() == 'h i'
}
```

A test inside the module can omit the `termkit.` qualifier, as above. Because
no renderer or term.ui context is created, this works in CI.

Other useful techniques from termkit's own tests:

- Drive timers with `p.dispatch(tick(id, duration, producer))` followed by
  `p.pump_timers()` and `p.process_queue()`.
- Test pasting and focus by sending `PasteStartMsg`, key messages,
  `PasteEndMsg`, `FocusMsg` and `BlurMsg`.
- Use `os.vtmp_dir()` for temporary files such as the target of `LogMsg`.
- `send` is thread-safe; tests spawn threads and join them before calling
  `process_queue()`.

The `examples/headless.v` program demonstrates the same pattern outside tests.

## Commands to run

Run these from the repository root:

```sh
# Format every touched V file, then confirm none need formatting
v fmt -w .
v fmt -l

# Compile V examples in Markdown, including this guide
v check-md .

# Run the test suite
v test .
```

`v check-md` compiles fenced V blocks in an isolated directory. Snippets
that import `termkit` cannot resolve it there, so this documentation uses
`v ignore` fences; use plain `v` fences only for code that needs no module
imports. `v fmt -w` rewrites files, so read the resulting diff before
committing.

No TTY, alternate screen or special environment variables are required for any
of these commands.
