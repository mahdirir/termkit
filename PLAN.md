# Plan

## Status

All six milestones are complete and the package is registered on VPM as
`mahdir-ir.TermKit`. termkit is a standalone VPM package. Future work from
rival-gap research is tracked as milestones M7–M13 below.

## Decisions

| Decision | Choice |
| --- | --- |
| Deliverable | Standalone VPM module `mahdir-ir.termkit` |
| Scope | Both TUI and CLI layers in one module |
| Placement | Standalone VPM repo; no `vlib` fold-in and no `vlang/v` PR |
| Compatibility | Independent implementation with conventional names, no copied code |

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

### M1 — Scaffolding (complete)

- [x] Clean worktree based on `V_REPO/master`.
- [x] New git repo with `v.mod`, MIT `LICENSE`, `.gitignore`.
- [x] `README.md`, `GOALS.md`, `PLAN.md`.
- [x] Verify `check-md` on all three Markdown files (0 warnings, 0 errors).
- [x] Initial commit.
- [x] Retry the master-based bootstrap and re-run validation with the
      resulting `v_master.exe` (`7ede4c6`).

### M2 — MVU core (complete)

- [x] `Msg` marker interface; `KeyMsg`, `MouseMsg`, `WindowSizeMsg`, `QuitMsg`,
      `TickMsg`, `PasteMsg`, `ErrorMsg`, `TitleMsg`, `WriteLineMsg`, `LogMsg`,
      `NoopMsg`.
- [x] `Cmd` sum type: `NoCmd`, `MsgCmd`, `CmdFn`, `BatchCmd`, `SequenceCmd`,
      `TickCmd`, `EveryCmd`.
- [x] Helpers: `no_cmd`, `msg_cmd`, `cmd_fn`, `batch`, `sequence`, `tick`,
      `every`, `quit`, `set_window_title`, `write_line`, `log_to_file`,
      `delivered_msgs`.
- [x] `Model` interface and `Program`/`new_program(...).run() !`.
- [x] `ProgramOpts`: alternate screen, mouse mode, raw mode, FPS, title,
      hide cursor, without renderer.
- [x] Map `term.ui.Event` to messages; key-name table for all `term.ui` keys.
- [x] Tests driven entirely by injected messages (no TTY required).
- [x] Keybinding map type (`KeyMap`).
- [x] Headless output injection (`ProgramOpts.out`), cancel hook and
      `context.Context` cancellation.
- [x] Bracketed paste, focus/blur and repeat decoded from raw escape reports
      without patching `term.ui`; modes enabled/disabled by the runtime.
- [x] Mutex-protected queue; `Program.send` is safe from spawned threads,
      covered by a multi-worker stress test.
- [x] `cleanup_fn` also fires on a normal `quit()`; terminal state is restored.
- [x] Renderer resizes on `WindowSizeMsg`.
- [x] Program-level `init_fn`/`cleanup_fn` and message filters.

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
- [x] Confirm, stopwatch and timer widgets.
- [x] Mouse scroll/click handling in list, viewport and file picker.
- [x] Masked text input; list multi-select.
- [x] Style color helpers: `Rgb`, `from_hex`, ANSI-256 parameters.
- [x] Renderer downgrades truecolor to ANSI-256 and basic ANSI.
- [x] Renderer keeps combining marks with their base glyph.
- [x] ANSI-256 grey mapping clamps at index 255 (no u8 overflow).
- [x] Renderer skips CSI/OSC escapes that are not SGR instead of swallowing text.
- [x] Carriage returns reset the draw column instead of entering a cell.
- [x] Rune-aware cursors in text input/area; TextArea multi-line paste.
- [x] `hstack`/`vstack` accumulate sizes for default-position rects.
- [x] Border titles truncate on rune boundaries; man pages emit valid mdoc lists.
- [x] Stopwatch/Timer do not count paused time after a restart.
- [x] Spinner/Progress views tolerate out-of-range public field values.
- [x] Table scrolls its visible window to keep the selected row in view.
- [x] Tabs and collapsible Tree widgets.

### M5 — CLI core (complete)

- [x] `cli.Command` and `cli.Flag` with error-returning `run`.
- [x] Persistent flags, shorthands, `--`, clustered shorts, aliases.
- [x] Typed getters, defaults, repeatable flags, choice sets.
- [x] Hooks and `init_fn`; positional arg rules.
- [x] Generated help and version output, man pages.
- [x] Suggestions via edit distance.
- [x] Negatable bool flags, custom validators, mutually exclusive and
      required-together flag groups.
- [x] `*_with_fn` hooks receiving the parsed command; injectable out/err
      streams; read-only `get_flag`; deprecated-flag warnings.
- [x] Unknown-command suggestions and tree-aware `__complete` traversal.
- [x] `silence_usage` and `silence_errors` options.
- [x] Typed getters reject bad values; `get_ints`/`get_floats` added.
- [x] Persistent parent hooks (before/after) for command trees.
- [x] Short-flag clusters accept value flags (next arg or attached value).
- [x] `--` also stops subcommand dispatch, not just flag parsing.
- [x] Man page generation.
- [x] Injectable streams, context cancellation.

### M6 — CLI extras, docs and release prep (complete; VPM pending approval)

- [x] Completion scripts for bash/zsh/fish/powershell and `__complete`.
- [x] Hidden/deprecated flags and commands, required flags.
- [x] Examples: `examples/counter.v`, `examples/cli_app.v`,
      `examples/widgets.v`, `examples/focus.v`.
- [x] More examples: `tabs_tree.v`, `timer.v`, `style.v`, `headless.v`,
      `cli_complete.v`; all nine compile, non-interactive ones run.
- [x] C API: exported `tk_*` ABI, generated header, shared + static builds,
      `tools/build_c.v`, C smoke test passing for both library forms.
- [x] Guides in `docs/` (getting started, MVU, widgets, CLI, styling/layout,
      C API, testing) and generated API reference in `docs/api/`.
- [x] Larger example apps in `examples/apps/`: todo, file browser, log viewer,
      CLI tool.
- [x] Full `v fmt -l`, `v check-md`, `v -silent test .` pass locally.
- [x] Every public symbol has a doc comment; `v doc -all termkit` succeeds.
- [x] Golden completion fixture for the bash script.
- [x] Push to `mahdir-ir/termkit`.
- [x] VPM registration as `mahdir-ir.TermKit` (live on vpm.vlang.io).

### M7 — Subprocess + TTY control (future)

- [x] `Exec`-style blocking subprocess: suspend TTY, run command, restore + resume.
- [x] `ReleaseTerminal` / `RestoreTerminal` public API for user-driven pauses.
- [x] Suspend/resume (`SuspendMsg`/`ResumeMsg` + methods; OS-signal wiring
      stays with term.ui, which owns the signal handlers).
- [x] Interrupt/quit split (`InterruptMsg` reaches the model, then quits).
- [x] `ClearScreen` command (cursor-home + clear without alt-screen).

### M8 — Key bindings + help foundation (done)

- [x] Declarative `Binding{keys, help}` with `Matches()`, enable/disable,
      as the source of truth for help text.
- [x] Elastic help: width-aware truncation with ellipsis, multi-column
      full-help view, auto-hide disabled bindings.

### M9 — Dynamic completion (future)

- [ ] Per-arg dynamic completion + per-flag completion funcs returning
      (values, directive).
- [ ] Completion directives + file semantics (`NoSpace`/`KeepOrder`/extension
      and directory filters, filename/dirname marking).
- [ ] `ActiveHelp` annotation lines shown during completion.
- [ ] Required-flag UX: exactly-one-required combination, surface required
      flags in completion output.

### M10 — Layout correctness (future)

- [ ] Word-wrap + render-time clamps (`MaxWidth`/`MaxHeight`/`Inline`,
      ANSI-preserving wrap).
- [ ] Fractional position + `Place` with styled whitespace; proportional joins.
- [ ] `Inherit` (unset-only) + `Unset*` + pure-value style copy.
- [ ] Geometry helpers (`Size`/`Width`/`Height`, frame/border size).

### M11 — Widget upgrades (future)

- [ ] Table: per-cell style func + scroll viewport.
- [ ] List: pluggable fuzzy filter func, match highlighting, timed status
      messages, embedded spinner, rich item delegates, infinite scroll.
- [ ] Viewport: search (highlight next/previous/ensure-visible), line-number
      gutter, per-line styling, `ScrollPercent`, alt-screen position mode.
- [ ] Text input: suggestion cycling, validation func, echo character,
      masked-aware word delete, paste command.
- [ ] File picker: permissions + humanized size columns, symlink target
      resolution, allowed-types filtering, auto height.
- [ ] Progress: multi-color gradient, static vs animated view, spring options,
      half-block hi-res. Spinner preset catalog. Tree per-level style funcs,
      custom enumerators/indenters, scroll offset. Multi-timer-safe tick IDs.

### M12 — CLI robustness (future)

- [ ] Errorable pre/post hooks aborting before validation.
- [ ] Optional-value flags + counter flags (`-vvv`); flag-name normalization.
- [ ] Child-traversing parent-local parsing; unknown-flag passthrough and
      non-parsing modes for wrapper commands.
- [ ] YAML/Markdown/reST doc generators (man pages already exist).
- [ ] Overridable help/usage/version templates; suggestion tuning
      (aliases, minimum-distance threshold); config-file convention docs.

### M13 — Color + canvas (future)

- [ ] Terminal queries (background/foreground color, cursor position,
      capability replies) enabling adaptive themes.
- [ ] Adaptive light/dark colors, color math (blend/darken/lighten/alpha),
      extra attributes (faint, blink, strikethrough, underline styles,
      hyperlinks), tab-width handling.
- [ ] Layers/canvas compositor with hit-testing; typed mouse messages
      (click/release/wheel/motion with modifiers); OSC52 clipboard.
- [ ] Static list/tree pretty-print packages; border catalog (variants,
      per-side colors, gradient blend, layout-preserving hidden border).
- [ ] Environment message + forced color-profile message (test ergonomics);
      native cursor object; OS-level progress/task-status view state.

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
| `term.ui` has no bracketed paste, focus or repeat events | Decode raw escape reports from `Event.utf8`; no stdlib patches |
| V backend quirks with interfaces and sum types | Spike each construct in M2 before building on it |
| Large public API is hard to review later | Keep packages small, document every public symbol, examples per feature |
| termkit stays standalone, outside `vlib` | Use only public `term.ui`/`vlib` APIs; no compiler or stdlib patches |

## Scope boundary

termkit is and remains a standalone VPM package. There is no plan to fold it
into `vlib`, to patch `term.ui`/`vlib/cli`, or to open a `vlang/v` PR. Input
features the stdlib does not expose (bracketed paste, focus, repeat) are decoded
by termkit from raw escape reports; no stdlib changes are required.
