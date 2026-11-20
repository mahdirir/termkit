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
     `every`, `quit`, `set_window_title`, `print`.
   - Identical update semantics with and without a real terminal, so tests can
     drive a program by injecting messages.

2. **A diffing renderer.**
   - Cell grid with position, style and grapheme width.
   - Emit only changed cells, with cursor movement and style resets.
   - Alternate screen, synchronized updates, configurable FPS, forced repaint.
   - Color profile detection: ascii, ANSI, ANSI-256, truecolor, with
     `NO_COLOR` respected.

3. **Input parity.**
   - Key names, modifiers, repeated keys, mouse buttons and scroll, resize.
   - Bracketed paste delivered as a single message.
   - Focus and blur messages once the stdlib input layer supports them; before
     that, a documented fallback path.

4. **A useful component set.**
   - Single-line text input and multi-line text area.
   - Scrollable viewport, list with filtering, table.
   - Spinner, progress bar, paginator, help/keybinding display, cursor.
   - Every component is independently testable and composable.

5. **Styling and layout.**
   - Foreground, background, bold/italic/underline/reverse, borders, padding,
     margins, alignment, fixed and percentage sizes.
   - Horizontal and vertical composition with minimum sizes and truncation.
   - Correct width handling for CJK, combining marks and ANSI sequences.

6. **A Cobra-class CLI.**
   - Nested commands with persistent and local flags, aliases and groups.
   - Typed flags with shorthands, clustered short flags, `--no-x` negation,
     `--` terminator, hidden/deprecated flags, choice sets and validators.
   - Argument validators, hooks, `on_initialize`, context cancellation.
   - Generated help, man pages, version output, `did you mean` suggestions.
   - Shell completion generation and a dynamic `__complete` protocol.
   - Error returns instead of `exit()` inside the parser; injectable streams.

7. **Cross-platform behaviour.**
   - Linux, macOS and Windows via the platform support already in `term.ui`.
   - No vendored C libraries and no new OS-level dependencies.

8. **Zero-dependency VPM module.**
   - `v install metif12.termkit` works with a stock V toolchain.
   - No module-level globals that leak between programs.

9. **Stdlib-ready shape.**
   - Package boundaries match the eventual `term.ui` and `cli` extensions.
   - `PLAN.md` records the exact file-to-stdlib mapping.
   - No circular imports back into the module root from subpackages.

10. **Documentation and examples.**
    - README, GOALS, PLAN, doc comments on every public symbol.
    - At least one runnable example per major feature area.
    - Markdown and V sources pass `v check-md` and `v fmt -l`.

## Non-goals

- Copying code from Bubble Tea, Bubbles, Lip Gloss, Cobra or bobatea.
- Changing the V compiler or the V standard library in this phase.
- ncurses/PDCurses bindings, mouse hit-testing outside widgets, SSH servers,
  GPU rendering, or a full window manager for the terminal.
- Bit-for-bit identical output to any Go library.
- Claiming complete upstream parity on day one; coverage is explicit in PLAN.

## Compatibility commitments

- Public names match bobatea where semantics match (`batch`, `sequence`,
  `tick`, `every`, `quit`, `msg_cmd`, `no_cmd`) to ease migration.
- `view()` returns a string, following Bubble Tea, rather than drawing into a
  context. The difference is documented.
- The package `termkit.cli` does not modify or shadow `vlib/cli`.

## Definition of done for this phase

- [ ] All six PLAN milestones complete.
- [ ] `v -silent test .` passes on the clean master-based worktree.
- [ ] `v fmt -l` reports no unformatted V files.
- [ ] `v check-md` passes on every Markdown file.
- [ ] Examples compile and the non-interactive ones run in CI.
- [ ] Module is ready to push to `metif12/termkit` and register on VPM after
      explicit approval of the name and description.
