/* Smoke test for the termkit C API.
 * Build with: v run tools/build_c.v
 * Then: gcc capi/test/smoke.c -I dist/c dist/c/termkit.dll -o dist/c/smoke.exe
 */
#include <stdio.h>
#include <string.h>

#include "termkit.h"

int main(void) {
    const char *version = tk_version();
    printf("version: %s\n", version);
    if (strcmp(version, "0.1.0") != 0) {
        return 1;
    }

    int profile = tk_color_profile_from_env("", "truecolor", "xterm");
    printf("profile: %d\n", profile);
    if (profile != TK_PROFILE_TRUECOLOR) {
        return 2;
    }

    TKRenderer renderer = tk_renderer_new(20, 1, TK_PROFILE_ANSI);
    tk_renderer_draw_text(renderer, 0, 0, "hi", "31", "", TK_ATTR_BOLD);
    const char *frame = tk_renderer_frame(renderer);
    printf("frame: %s\n", frame);
    if (strstr(frame, "hi") == NULL || strstr(frame, "\x1b[31m") == NULL) {
        return 3;
    }
    tk_renderer_free(renderer);

    const char *box = tk_style_render("hello", TK_BORDER_ROUNDED, "demo", 1, 0, 16,
                                      TK_ALIGN_CENTER);
    printf("box:\n%s\n", box);
    if (strstr(box, "╭") == NULL) {
        return 4;
    }

    const char *help = tk_cli_help("tool", "demo", "1.0");
    if (strstr(help, "tool - demo") == NULL) {
        return 5;
    }

    const char *candidates[2] = {"serve", "build"};
    const char *hint = tk_cli_suggest("serv", candidates, 2);
    if (strstr(hint, "serve") == NULL || tk_levenshtein("serv", "serve") != 1) {
        return 6;
    }

    const char *key = tk_key_name(97);
    if (strcmp(key, "a") != 0) {
        return 7;
    }

    if (strstr(tk_rgb_fg(1, 2, 3), "38;2;1;2;3") == NULL ||
        strstr(tk_rgb_bg(1, 2, 3), "48;2;1;2;3") == NULL) {
        return 8;
    }
    if (tk_rgb_to_ansi256(248, 248, 248) != 255 || tk_rgb_to_basic(255, 0, 0) != 1) {
        return 9;
    }

    puts("C API smoke test passed");
    return 0;
}
