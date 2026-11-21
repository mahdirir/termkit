module main

import os

fn run(cmd []string) ! {
	res := os.exec(cmd)
	if res.exit_code != 0 {
		return error('command failed: ${cmd.join(' ')}\n${res.output}')
	}
}

fn build() ! {
	root := os.real_path(@VMODROOT)
	out := os.join_path(root, 'dist', 'c')
	workdir := os.join_path(out, 'build')
	os.mkdir_all(workdir)!

	vexe := @VEXE
	src := os.join_path(root, 'capi', 'main.v')
	base := os.join_path(out, 'termkit')

	println('building shared library...')
	run([vexe, '-memory-limit', '3000', '-shared', '-o', base, src])!

	if os.user_os() == 'windows' {
		// V's Windows shared build records an internal name of out.exe, so
		// produce a real import library that points at termkit.dll.
		symbols := [
			'tk_version',
			'tk_color_profile_from_env',
			'tk_renderer_new',
			'tk_renderer_free',
			'tk_renderer_clear',
			'tk_renderer_resize',
			'tk_renderer_draw_text',
			'tk_renderer_frame',
			'tk_style_render',
			'tk_cli_help',
			'tk_cli_suggest',
			'tk_levenshtein',
			'tk_key_name',
			'tk_rgb_fg',
			'tk_rgb_bg',
			'tk_rgb_to_ansi256',
			'tk_rgb_to_basic',
		]
		mut def_lines := ['LIBRARY termkit.dll', 'EXPORTS']
		for sym in symbols {
			def_lines << '    ${sym}'
		}
		def_path := os.join_path(out, 'termkit.def')
		os.write_file(def_path, def_lines.join('\n') + '\n')!
		implib := os.join_path(out, 'termkit.dll.a')
		run(['dlltool', '-d', def_path, '-D', 'termkit.dll', '-l', implib])!
		println('import:  ${implib}')
	}

	println('generating C source for the static library (-gc none)...')
	csrc := os.join_path(workdir, 'termkit.c')
	run([vexe, '-memory-limit', '3000', '-gc', 'none', '-o', csrc, src])!

	println('compiling static library...')
	obj := os.join_path(workdir, 'termkit.o')
	vroot := os.real_path(@VEXEROOT)
	run(['gcc', '-c', '-I', vroot, csrc, '-o', obj])!
	mut objects := [obj]
	if os.user_os() == 'windows' {
		// V's no-GC Windows runtime still needs its exception-filter helper.
		helper := os.join_path(vroot, 'vlib', 'builtin', 'core_windows.c')
		helper_obj := os.join_path(workdir, 'core_windows.o')
		run(['gcc', '-c', '-I', vroot, helper, '-o', helper_obj])!
		objects << helper_obj
	}
	archive := if os.user_os() == 'windows' {
		os.join_path(out, 'termkit_static.lib')
	} else {
		os.join_path(out, 'libtermkit.a')
	}
	run(['ar', 'rcs', archive, ...objects])!

	header := os.join_path(out, 'termkit.h')
	os.cp(os.join_path(root, 'capi', 'include', 'termkit.h'), header)!

	println('shared:  ${base} (+ platform extension)')
	println('static:  ${archive}')
	println('header:  ${header}')
}

fn main() {
	build() or { panic(err) }
}
