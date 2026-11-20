module termkit

import time

fn test_no_cmd() {
	assert delivered_msgs(no_cmd).len == 0
}

fn test_msg_cmd() {
	msgs := delivered_msgs(msg_cmd(QuitMsg{}))
	assert msgs.len == 1
	assert msgs[0] is QuitMsg
}

fn test_batch_and_sequence() {
	first := msg_cmd(KeyMsg{ key: 'a' })
	second := msg_cmd(KeyMsg{ key: 'b' })
	for cmd in [batch(first, second), sequence(first, second), batch_array([first, second]),
		sequence_array([first, second])] {
		msgs := delivered_msgs(cmd)
		assert msgs.len == 2
		match msgs[0] {
			KeyMsg {
				assert msgs[0].key == 'a'
			}
			else {
				assert false
			}
		}
		match msgs[1] {
			KeyMsg {
				assert msgs[1].key == 'b'
			}
			else {
				assert false
			}
		}
	}
}

fn tick_message(at i64) Msg {
	return TickMsg{ id: 3, at: at }
}

fn test_timers_are_values() {
	cmd := tick(3, 100 * time.millisecond, tick_message)
	match cmd {
		TickCmd {
			assert cmd.id == 3
			assert cmd.delay == 100 * time.millisecond
		}
		else {
			assert false
		}
	}
	every_cmd := every(4, time.second, tick_message)
	match every_cmd {
		EveryCmd {
			assert every_cmd.id == 4
		}
		else {
			assert false
		}
	}
	assert delivered_msgs(cmd).len == 0
}

fn test_command_helpers() {
	match quit() {
		MsgCmd {
			assert delivered_msgs(quit()).len == 1
		}
		else {
			assert false
		}
	}
	match set_window_title('hello') {
		MsgCmd {
			msgs := delivered_msgs(set_window_title('hello'))
			match msgs[0] {
				TitleMsg {
					assert msgs[0].title == 'hello'
				}
				else {
					assert false
				}
			}
		}
		else {
			assert false
		}
	}
}
