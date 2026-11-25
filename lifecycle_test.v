@[has_globals]
module termkit

struct LifecycleModel {
mut:
	exec_results []ExecDoneMsg
	interrupted  bool
}

fn (mut m LifecycleModel) init() Cmd {
	return no_cmd
}

fn (mut m LifecycleModel) update(msg Msg) (Model, Cmd) {
	match msg {
		ExecDoneMsg {
			m.exec_results << msg
		}
		InterruptMsg {
			m.interrupted = true
			return m, quit()
		}
		else {}
	}
	return m, no_cmd
}

fn (mut m LifecycleModel) view() string {
	return 'exec=${m.exec_results.len} interrupted=${m.interrupted}'
}

fn new_lifecycle_program() Program {
	mut model := &LifecycleModel{}
	return new_program(model, ProgramOpts{ without_renderer: true })
}

fn test_suspend_resume_headless_noop() {
	mut p := new_lifecycle_program()
	// No ui attached: suspend/resume/clear must be safe no-ops.
	p.send(SuspendMsg{})
	p.send(ResumeMsg{})
	p.send(ClearScreenMsg{})
	p.process_queue()
	assert !p.quitting
	assert p.view() == 'exec=0 interrupted=false'
}

fn test_interrupt_quits_distinctly() {
	mut p := new_lifecycle_program()
	assert delivered_msgs(interrupt()).len == 1
	p.send(InterruptMsg{})
	p.process_queue()
	assert p.view() == 'exec=0 interrupted=true'
	assert p.quitting
}

fn test_lifecycle_cmd_constructors() {
	assert delivered_msgs(suspend())[0] is SuspendMsg
	assert delivered_msgs(resume())[0] is ResumeMsg
	assert delivered_msgs(clear_screen())[0] is ClearScreenMsg
	assert delivered_msgs(quit())[0] is QuitMsg
}

fn test_exec_cmd_delivers_result() {
	mut model := &LifecycleModel{}
	mut p := new_program(model, ProgramOpts{ without_renderer: true })
	p.dispatch(exec_cmd(7, @VEXE, ['version']))
	p.process_queue()
	assert model.exec_results.len == 1
	assert model.exec_results[0].id == 7
	assert model.exec_results[0].exit_code == 0
	assert model.exec_results[0].output.contains('V ')
	assert p.view() == 'exec=1 interrupted=false'
}

fn test_release_restore_headless_noop() {
	mut p := new_lifecycle_program()
	p.release_terminal()
	p.restore_terminal()
	assert !p.quitting
}
