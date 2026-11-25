# termkit documentation

termkit is a standalone VPM module published as `mahdir-ir.termkit`. It provides
an MVU runtime, diffing renderer, reusable widgets, a styling/layout system and
a CLI framework for V. It stays standalone forever: it is not part
of the V standard library and is not planned for fold-in to `vlib`.

## Guides

- [Getting started](getting-started.md) — install the module, write a minimal
  MVU program, run the bundled examples.
- [MVU guide](mvu-guide.md) — the `Model` interface, `Cmd` values, program
  options, threads, filters, lifecycle hooks and paste/focus/repeat support.
- [Widgets guide](widgets-guide.md) — text editors, viewport, list, table,
  tabs, tree, file picker, progress widgets, focus groups and help bars.
- [CLI guide](cli-guide.md) — commands, flags, validation, hooks, generated
  help/man/version, suggestions and shell completion.
- [Styling and layout guide](styling-layout-guide.md) — colors, attributes,
  borders, padding/alignment and cell-based rectangle layout.
- [C API guide](c-api-guide.md) — build the shared/static libraries, read the
  header, link a C program and respect returned-string lifetimes.
- [Testing guide](testing-guide.md) — test pure functions, inject messages into
  a headless `Program`, and run the format/check/test commands.

## Conventions used here

V examples are fenced with `v ignore`. That tag keeps `v check-md` from trying
to compile fragments or programs that import `termkit` (the checker compiles
plain `v` fences in an isolated directory where the module is not installed).
Shell commands use `sh` fences and C code uses `c` fences.

The examples referenced throughout these guides live in the repository's
`examples/` directory. Run them from the repository root.
