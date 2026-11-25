# C API guide

termkit can be consumed from C through a small ABI that uses only C types:
opaque renderer handles, `const char *` strings and plain integers. This is a
feature of the standalone `mahdir-ir.termkit` package; there is no vlib C API.

## Build

From the repository root:

```sh
v run tools/build_c.v
```

The build script compiles `capi/main.v` and writes these files to `dist/c/`:

| File | Purpose |
| --- | --- |
| `termkit.dll` / `.so` / `.dylib` | Shared library |
| `termkit.dll.a` (Windows) | Import library pointing at `termkit.dll` |
| `termkit_static.lib` / `libtermkit.a` | Static library, built with `-gc none` |
| `termkit.h` | C header (copied from `capi/include/termkit.h`) |

On Windows the import library is generated with `dlltool` from a `termkit.def`
export list. The shared build uses V's Boehm GC; the static build disables the
GC (`-gc none`), so its allocations live for the process lifetime. Prefer the
shared library for long-running hosts, and the static library when you need a
single artifact with no GC dependency.

## The header

Include `termkit.h`. It defines `TKRenderer` (an opaque `void *`), the
`TKColorProfile` enum (`TK_PROFILE_ASCII`, `ANSI`, `ANSI256`, `TRUECOLOR`), the
`TKBorder` enum (none/single/rounded/double) and the `TKAlign` enum
(start/center/end). Attribute bits are `TK_ATTR_BOLD`, `TK_ATTR_ITALIC`,
`TK_ATTR_UNDERLINE` and `TK_ATTR_REVERSE`.

Representative functions:

```c
const char *tk_version(void);
int tk_color_profile_from_env(const char *no_color, const char *colorterm,
                              const char *term_name);
TKRenderer tk_renderer_new(int width, int height, int profile);
void tk_renderer_free(TKRenderer renderer);
void tk_renderer_clear(TKRenderer renderer);
void tk_renderer_resize(TKRenderer renderer, int width, int height);
void tk_renderer_draw_text(TKRenderer renderer, int x, int y, const char *text,
                           const char *fg, const char *bg, uint8_t attrs);
const char *tk_renderer_frame(TKRenderer renderer);
const char *tk_style_render(const char *text, int border, const char *title,
                            int padding, int margin, int width, int align);
const char *tk_cli_help(const char *name, const char *description,
                        const char *version);
const char *tk_cli_suggest(const char *input, const char **candidates,
                           int count);
int tk_levenshtein(const char *a, const char *b);
const char *tk_key_name(int code);
const char *tk_rgb_fg(uint8_t r, uint8_t g, uint8_t b);
const char *tk_rgb_bg(uint8_t r, uint8_t g, uint8_t b);
uint8_t tk_rgb_to_ansi256(int r, int g, int b);
uint8_t tk_rgb_to_basic(int r, int g, int b);
```

For `tk_renderer_draw_text`, `fg` and `bg` are SGR parameter strings such as
`"31"` or `"38;5;42"`; pass `NULL` for a default color.

## C usage

```c
#include <stdio.h>
#include "termkit.h"

int main(void) {
    TKRenderer *r = tk_renderer_new(40, 1, TK_PROFILE_ANSI);
    tk_renderer_draw_text(r, 0, 0, "hello", "31", "", TK_ATTR_BOLD);
    puts(tk_renderer_frame(r));
    tk_renderer_free(r);
    return 0;
}
```

`tk_renderer_frame` returns only the escape sequences needed to turn the
previous frame into the current one, so repeated draws are cheap. An unchanged
frame returns an empty string.

## Smoke test

Build the C library first, then compile and run the bundled smoke test:

```sh
v run tools/build_c.v
gcc capi/test/smoke.c -I dist/c dist/c/termkit.dll.a -o smoke.exe
smoke.exe
```

On non-Windows platforms link with `-L dist/c -ltermkit` instead of the import
library. The smoke test checks the version, color profile detection, renderer
diff output, styled boxes, CLI help, suggestions, key names and color helpers.

## Returned-string lifetime

Strings returned by the library are owned by the library and remain valid
until the next call to the **same function**. Each exported function uses its
own buffer (frame, style, CLI, color and key results are separate), so a frame
string is not invalidated by a style call. Copy a returned string with `strdup`
if you need to retain it across another call to that function. Input strings
are borrowed for the duration of the call only.
