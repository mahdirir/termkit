# Termkit goals

## Mission

Make V a first-class choice for interactive terminal applications by providing
one coherent, zero-dependency toolkit comparable to Go's Bubble Tea (runtime),
Bubbles (components), Lip Gloss (styling) and Cobra (command line interface).

## Goals

1. **A deterministic MVU runtime.**
   - `Model` with `init`, `update`, `view`.
   - Messages for keys, mouse, resize, focus, paste, ticks and errors.
   - Commands as values: `no_cmd`, `msg_cmd`, `batch`, `sequence`, `tick`,
     `every`, `quit`, `set_window_title`, `write_line`.
   - Lifecycle hooks, message filters, thread-safe message delivery.
   - Identical update semantics with and without a real terminal, so tests can
     drive a program by injecting messages.

2. **A diffing renderer.**
   - Cell grid with position, style and grapheme width.
   - Emit only changed cells, with cursor movement and style resets.
   - Alternate screen, synchronized updates, configurable FPS, forced repaint.
   - Color profile detection: ascii, ANSI, ANSI-256, truecolor, with
     `NO_COLOR` respected. Truecolor styles are downgraded automatically.

3. **Input parity.**
   - Key names, modifiers, repeated keys, mouse buttons and scroll, resize.
   - Bracketed paste delivered as a single message.
   - Focus, blur and repeat messages decoded from raw terminal reports without
     modifying the stdlib input layer.

4. **A useful component set.**
   - Single-line text input with optional mask and multi-line text area.
   - Scrollable viewport, list with filtering and multi-select, table, file
     picker.
   - Spinner, progress bar, paginator, confirm prompt, stopwatch/timer,
     help/keybinding display, cursor, tabs and a collapsible tree.
   - Tab/Shift+Tab focus groups over any `Focusable` widget.
   - Mouse scroll and click handling in lists, viewports and the file picker.
   - Every component is independently testable and composable.

5. **Styling and layout.**
   - Foreground, background, RGB/hex/ANSI-256 colors, bold/italic/underline/
     reverse, borders, padding, margins, alignment, fixed sizes.
   - Horizontal and vertical composition with minimum sizes and truncation.
   - Correct width handling for CJK, combining marks and ANSI sequences.

6. **A Cobra-class CLI.**
   - Nested commands with persistent and local flags, aliases and groups.
   - Typed flags with shorthands, clustered short flags, `--no-x` negation,
     `--` terminator, hidden/deprecated flags, choice sets and validators.
     Numeric getters reject malformed values instead of returning zero.
   - Argument validators, hooks, `on_initialize`, context cancellation, and
     persistent parent hooks that wrap every descendant command.
   - Generated help, man pages, version output, `did you mean` suggestions
     for both flags and sub-commands.
   - Shell completion generation and a dynamic `__complete` protocol that
     walks nested command trees.
   - Error returns instead of `exit()` inside the parser; injectable streams;
     `silence_usage` and `silence_errors` for embedding.
   - Hooks that receive the parsed command so flags are readable without
     globals; deprecation warnings for old flags and commands.

7. **Cobra-class flag semantics.**
   - Negatable bool flags (`--no-color`), custom value validators, mutually
     exclusive and required-together flag groups.
   - Hidden and deprecated flags, choice sets, repeatable flags and aliases.

8. **Cross-platform behaviour.**
   - Linux, macOS and Windows via the platform support already in `term.ui`.
   - No vendored C libraries and no new OS-level dependencies.

9. **Zero-dependency VPM module.**
   - `v install mahdir-ir.termkit` works with a stock V toolchain.
   - No module-level globals that leak between programs.

10. **Standalone package shape.**
   - Public packages stay importable as `termkit`, `termkit.style`,
   `termkit.layout`, `termkit.widgets` and `termkit.cli`.
   - Only public `term.ui` and `vlib` APIs are used; no stdlib patches.
   - No circular imports back into the module root from subpackages.

11. **Documentation and examples.**
    - README, GOALS, PLAN, doc comments on every public symbol.
    - At least one runnable example per major feature area.
    - Markdown and V sources pass `v check-md` and `v fmt -l`.

## Non-goals

- Copying code from Bubble Tea, Bubbles, Lip Gloss, Cobra or bobatea.
- Changing the V compiler or the V standard library. termkit is not proposed
   for `vlib` inclusion and no `vlang/v` PR is planned.
- ncurses/PDCurses bindings, mouse hit-testing outside widgets, SSH servers,
  GPU rendering, or a full window manager for the terminal.
- Bit-for-bit identical output to any Go library.
- Claiming complete upstream parity on day one; coverage is explicit in PLAN.

## Compatibility commitments

- Public names match bobatea where semantics match (`batch`, `sequence`,
  `tick`, `every`, `quit`, `msg_cmd`, `no_cmd`) to ease migration.
- `view()` returns a string, following Bubble Tea, rather than drawing into a
  context. The difference is documented.
- The package `termkit.cli` does not modify or shadow `vlib/cli`; both remain
  available and independent.

## Definition of done for this phase

- [x] All six PLAN milestones complete.
- [x] `v -silent test .` passes on the clean master-based worktree.
- [x] `v fmt -l` reports no unformatted V files.
- [x] `v check-md` passes on every Markdown file.
- [x] All examples compile with the master-based compiler; non-interactive
      examples can run in CI.
- [x] Module is pushed to `mahdir-ir/termkit` as a standalone package.
- [ ] VPM registration awaits explicit approval of the name and description.
      No `vlib` fold-in or `vlang/v` PR is part of this phase.
