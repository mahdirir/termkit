/*
 * termkit C API -- standalone VPM package metif12.termkit.
 *
 * Build the library with: v run tools/build_c.v
 * Output goes to dist/c/: termkit.dll (or .so/.dylib), libtermkit.a,
 * and this header.
 *
 * Strings returned by the library are owned by it and stay valid until the
 * next call to the same function. Copy them if you need to retain them.
 */
#ifndef TERMKIT_H
#define TERMKIT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void *TKRenderer;

/* Profiles returned by tk_color_profile_from_env and accepted by
 * tk_renderer_new. */
enum TKColorProfile {
    TK_PROFILE_ASCII = 0,
    TK_PROFILE_ANSI = 1,
    TK_PROFILE_ANSI256 = 2,
    TK_PROFILE_TRUECOLOR = 3
};

/* Border kinds accepted by tk_style_render. */
enum TKBorder {
    TK_BORDER_NONE = 0,
    TK_BORDER_SINGLE = 1,
    TK_BORDER_ROUNDED = 2,
    TK_BORDER_DOUBLE = 3
};

/* Alignment values accepted by tk_style_render. */
enum TKAlign {
    TK_ALIGN_START = 0,
    TK_ALIGN_CENTER = 1,
    TK_ALIGN_END = 2
};

/* Attribute bits accepted by tk_renderer_draw_text. */
#define TK_ATTR_BOLD ((uint8_t)1)
#define TK_ATTR_ITALIC ((uint8_t)2)
#define TK_ATTR_UNDERLINE ((uint8_t)4)
#define TK_ATTR_REVERSE ((uint8_t)8)

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
const char *tk_cli_suggest(const char *input, const char **candidates, int count);
int tk_levenshtein(const char *a, const char *b);

const char *tk_key_name(int code);
const char *tk_rgb_fg(uint8_t r, uint8_t g, uint8_t b);
const char *tk_rgb_bg(uint8_t r, uint8_t g, uint8_t b);
uint8_t tk_rgb_to_ansi256(int r, int g, int b);
uint8_t tk_rgb_to_basic(int r, int g, int b);

#ifdef __cplusplus
}
#endif

#endif /* TERMKIT_H */
