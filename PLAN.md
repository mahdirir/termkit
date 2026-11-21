# Plan

## Status

Phase 1 of 6: scaffolding. No runtime code exists yet.

## Decisions

| Decision | Choice |
| --- | --- |
| Deliverable now | VPM module `metif12.termkit`, no `vlang/v` PR yet |
| Scope | Both TUI and CLI layers in one module, one future stdlib PR |
| Placement | Standalone VPM repo, shaped for later stdlib inclusion |
| bobatea | Independent implementation, compatible names, no copied code |

## Environment

- `C:\Users\MR\Projects\v-termkit` — clean worktree at `V_REPO/master`
  (`7ede4c6133`), reserved as the build harness. The main `v` checkout is 404
  commits behind and is not used.
- `C:\Users\MR\Projects\termkit` — the module repository (this repo).
- The `makev.bat --local -gcc` bootstrap stalled during `v_stage.c` generation
  while other GCC builds were running. A lighter self-hosted build succeeded:
  `v_master.exe` in the harness reports `V 0.5.2 7ede4c6`, matching the
  worktree HEAD. All validation was re-run with that compiler and passed.
- No compiler sources are changed, so `v self` is not needed.
- All builds use a private `TMPDIR` under
  `LocalAppData\Temp\opencode\termkit`, explicit `VJOBS` and `-memory-limit`.

## Repository layout

```
termkit/
  v.mod, LICENSE, README.md, GOALS.md, PLAN.md
  program.v        # Program, Options, run loop, lifecycle
  msg.v            # Msg interface and built-in messages
  cmd.v            # Cmd sum type and command helpers
  key.v            # key names, modifiers, bindings
  options.v        # ProgramOpts, filters, stream injection
  renderer.v       # cell grid, diffing, color profile, fps
  layout.v         # Rect, constraints, stacks
  style/           # Style, borders, padding, alignment
  widgets/         # textinput, textarea, viewport, list, table,
                   # spinner, progress, paginator, help, cursor
  cli/             # command, flag, args, suggestions, completion,
                   # help, man, version
  examples/        # one runnable example per feature area
  *_test.v         # co-located tests and golden fixtures
```

## Milestones

### M1 — Scaffolding (in progress)

- [x] Clean worktree based on `V_REPO/master`.
- [x] New git repo with `v.mod`, MIT `LICENSE`, `.gitignore`.
- [x] `README.md`, `GOALS.md`, `PLAN.md`.
- [x] Verify `check-md` on all three Markdown files (0 warnings, 0 errors).
- [x] Initial commit.
- [x] Retry the master-based bootstrap and re-run validation with the
      resulting `v_master.exe` (`7ede4c6`).

### M2 — MVU core (mostly complete)

- [x] `Msg` marker interface; `KeyMsg`, `MouseMsg`, `WindowSizeMsg`, `QuitMsg`,
      `TickMsg`, `PasteMsg`, `ErrorMsg`, `TitleMsg`, `WriteLineMsg`, `NoopMsg`.
- [x] `Cmd` sum type: `NoCmd`, `MsgCmd`, `CmdFn`, `BatchCmd`, `SequenceCmd`,
      `TickCmd`, `EveryCmd`.
- [x] Helpers: `no_cmd`, `msg_cmd`, `cmd_fn`, `batch`, `sequence`, `tick`,
      `every`, `quit`, `set_window_title`, `write_line`, `delivered_msgs`.
- [x] `Model` interface and `Program`/`new_program(...).run() !`.
- [x] `ProgramOpts`: alternate screen, mouse mode, raw mode, FPS, title,
      hide cursor, without renderer.
- [x] Map `term.ui.Event` to messages; key-name table for all `term.ui` keys.
- [x] Tests driven entirely by injected messages (no TTY required).
- [x] Keybinding map type (`KeyMap`).
- [x] Headless output injection (`ProgramOpts.out`), cancel hook and
      `context.Context` cancellation.
- [ ] Real bracketed paste and focus/blur require stdlib input changes; the
      message types exist but are not produced yet.

### M3 — Renderer (complete)

- [x] Cell grid with visible-width calculation for CJK and combining marks.
- [x] Frame diffing: batch adjacent same-style cells, emit only changed runs.
- [x] Synchronized updates, alternate buffer, cursor show/hide, clear.
- [x] Color profile detection from `NO_COLOR`, `COLORTERM`, `TERM`.
- [x] `repaint()`, `suspend()`, `resume()`; FPS pacing comes from `term.ui`.
- [x] Golden tests that assert exact escape output for small scenes.

### M4 — Style, layout and widgets (complete)

- [x] `style`: colors, attributes, borders, padding, alignment.
- [x] `layout`: `Rect`, `Size`, alignment, hstack/vstack, join, intersect.
- [x] Widgets: textinput, viewport, list, spinner, progress, help.
- [x] Renderer parses embedded SGR so styled views survive diffing.
- [x] Each widget: pure update over `Msg`, pure `view() string`, no globals.
- [x] Tests for update transitions and rendered output.
- [x] Remaining widgets: textarea, table, paginator, cursor, file picker.
- [x] `Focusable` interface and Tab/Shift+Tab `FocusGroup`.
- [x] Style margins.

### M5 — CLI core (mostly complete)

- [x] `cli.Command` and `cli.Flag` with error-returning `run`.
- [x] Persistent flags, shorthands, `--`, clustered shorts, aliases.
- [x] Typed getters, defaults, repeatable flags, choice sets.
- [x] Hooks and `init_fn`; positional arg rules.
- [x] Generated help and version output, man pages.
- [x] Suggestions via edit distance.
- [x] Negatable bool flags, custom validators, mutually exclusive and
      required-together flag groups.
- [x] Man page generation.
- [ ] Injectable streams, context cancellation.

### M6 — CLI extras, docs and release prep (in progress)

- [x] Completion scripts for bash/zsh/fish/powershell and `__complete`.
- [x] Hidden/deprecated flags and commands, required flags.
- [x] Examples: `examples/counter.v`, `examples/cli_app.v`,
      `examples/widgets.v`, `examples/focus.v`.
- [x] Full `v fmt -l`, `v check-md`, `v -silent test .` pass locally.
- [x] Golden completion fixture for the bash script.
- [ ] Push to `metif12/termkit` and VPM registration after approval.

## Test strategy

- Unit tests for message/command semantics, key parsing, widget transitions,
  style/layout output and CLI parsing. No real TTY required.
- Golden `.out` files for help, man, completion and renderer escape output.
- A scripted in-memory driver runs a model to a fixed message sequence and
  asserts the final model and rendered string.
- Avoid real-terminal integration tests: they are unreliable on Windows CI.
- Run the smallest relevant tests after each edit; run the full suite at the
  end of each milestone.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| V closure contexts are pinned for process lifetime | `Cmd` is a sum type; `CmdFn` only for non-capturing functions |
| `term.ui` has no bracketed paste or focus events | Approximate paste from batched `utf8` events; document focus as deferred |
| V backend quirks with interfaces and sum types | Spike each construct in M2 before building on it |
| Large public API is hard to review later | Keep packages small, document every public symbol, examples per feature |
| User asked for a vlang/v PR originally | VPM phase is explicit; PR mapping is recorded below and deferred |

## Deferred vlang/v PR mapping

| Module package | Future stdlib location |
| --- | --- |
| `termkit` runtime, messages, commands | `vlib/term/ui/` (new files) |
| `termkit.style`, `termkit.layout`, `termkit.widgets` | `vlib/term/ui/widgets/` |
| `termkit.cli` | new files in `vlib/cli/` |
| renderer diffing | `vlib/term/ui/ui.c.v` (resolves existing TODO) |
| paste/focus input support | `vlib/term/ui/input_*.c.v`, `termios_nix.c.v` |
| examples | `examples/term.ui/`, `examples/cli*.v` |

The PR should be one logical change with focused commits, opened from
`metif12/v` against `vlang/v`; no branch is ever created on `vlang/v` itself.
