module widgets

import termkit

// TreeNode is a node in a Tree. Children are nodes whose parent equals this
// node's index in the tree's node array.
pub struct TreeNode {
pub mut:
	label    string
	parent   int  = -1
	expanded bool = true
}

// Tree is a navigable, collapsible hierarchy of nodes.
pub struct Tree {
pub mut:
	nodes  []TreeNode
	cursor int
}

// set_nodes replaces the tree contents and selects the first node.
pub fn (mut t Tree) set_nodes(nodes []TreeNode) {
	t.nodes = nodes
	t.cursor = if nodes.len > 0 { 0 } else { -1 }
}

// add_node appends a node and returns its index.
pub fn (mut t Tree) add_node(label string, parent int) int {
	t.nodes << TreeNode{ label: label, parent: parent }
	if t.cursor < 0 {
		t.cursor = 0
	}
	return t.nodes.len - 1
}

fn (t &Tree) has_children(i int) bool {
	if i < 0 || i >= t.nodes.len {
		return false
	}
	for node in t.nodes {
		if node.parent == i {
			return true
		}
	}
	return false
}

fn (t &Tree) is_visible(i int) bool {
	if i < 0 || i >= t.nodes.len {
		return false
	}
	mut p := t.nodes[i].parent
	for p >= 0 && p < t.nodes.len {
		if !t.nodes[p].expanded {
			return false
		}
		p = t.nodes[p].parent
	}
	return true
}

fn (t &Tree) depth(i int) int {
	mut d := 0
	mut p := t.nodes[i].parent
	for p >= 0 && p < t.nodes.len {
		d++
		p = t.nodes[p].parent
	}
	return d
}

fn (t &Tree) visible_indices() []int {
	mut out := []int{}
	for i in 0 .. t.nodes.len {
		if t.is_visible(i) {
			out << i
		}
	}
	return out
}

fn (t &Tree) cursor_pos(vis []int) int {
	for i, idx in vis {
		if idx == t.cursor {
			return i
		}
	}
	return -1
}

fn descendant_of(t &Tree, i int, ancestor int) bool {
	mut p := t.nodes[i].parent
	for p >= 0 && p < t.nodes.len {
		if p == ancestor {
			return true
		}
		p = t.nodes[p].parent
	}
	return false
}

// selected_label returns the label of the selected node, or an empty string.
pub fn (t Tree) selected_label() string {
	if t.cursor < 0 || t.cursor >= t.nodes.len {
		return ''
	}
	return t.nodes[t.cursor].label
}

// update handles tree navigation and expansion for a key press.
pub fn (mut t Tree) update(msg termkit.Msg) {
	match msg {
		termkit.KeyMsg {
			if msg.kind != .press || t.nodes.len == 0 {
				return
			}
			vis := t.visible_indices()
			pos := t.cursor_pos(vis)
			if pos < 0 {
				if vis.len > 0 {
					t.cursor = vis[0]
				}
				return
			}
			match msg.key {
				termkit.key_up {
					if pos > 0 {
						t.cursor = vis[pos - 1]
					}
				}
				termkit.key_down {
					if pos < vis.len - 1 {
						t.cursor = vis[pos + 1]
					}
				}
				termkit.key_left {
					if t.has_children(t.cursor) && t.nodes[t.cursor].expanded {
						collapsed := t.cursor
						t.nodes[t.cursor].expanded = false
						if !t.is_visible(t.cursor) || descendant_of(t, t.cursor, collapsed) {
							t.cursor = collapsed
						}
					} else if t.nodes[t.cursor].parent >= 0 {
						t.cursor = t.nodes[t.cursor].parent
					}
				}
				termkit.key_right {
					if t.has_children(t.cursor) && !t.nodes[t.cursor].expanded {
						t.nodes[t.cursor].expanded = true
					} else {
						for i, node in t.nodes {
							if node.parent == t.cursor {
								t.cursor = i
								break
							}
						}
					}
				}
				else {}
			}
		}
		else {}
	}
}

// view renders the visible nodes with indentation and expand markers.
pub fn (t Tree) view() string {
	mut out := []string{}
	for i in t.visible_indices() {
		marker := if i == t.cursor { '> ' } else { '  ' }
		mut branch := ''
		if t.has_children(i) {
			branch = if t.nodes[i].expanded { '▾ ' } else { '▸ ' }
		} else {
			branch = '  '
		}
		out << marker + repeat('  ', t.depth(i)) + branch + t.nodes[i].label
	}
	return out.join('\n')
}
