module cli

// levenshtein returns the edit distance between two strings.
pub fn levenshtein(a string, b string) int {
	if a == b {
		return 0
	}
	if a.len == 0 {
		return b.len
	}
	if b.len == 0 {
		return a.len
	}
	mut prev := []int{len: b.len + 1}
	mut curr := []int{len: b.len + 1}
	for j in 0 .. b.len + 1 {
		prev[j] = j
	}
	for i in 1 .. a.len + 1 {
		curr[0] = i
		for j in 1 .. b.len + 1 {
			cost := if a[i - 1] == b[j - 1] { 0 } else { 1 }
			curr[j] = min3(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost)
		}
		tmp := prev.clone()
		prev = curr.clone()
		curr = tmp.clone()
	}
	return prev[b.len]
}

fn min3(a int, b int, c int) int {
	m := if a < b { a } else { b }
	return if m < c { m } else { c }
}

// suggest returns a 'did you mean' hint for the closest candidate.
pub fn suggest(input string, candidates []string) string {
	return suggest_with(input, candidates, 2)
}

// suggest_with is suggest with an explicit maximum edit distance.
pub fn suggest_with(input string, candidates []string, max_distance int) string {
	mut best := ''
	mut best_distance := 1_000_000
	for candidate in candidates {
		d := levenshtein(input, candidate)
		if d < best_distance {
			best_distance = d
			best = candidate
		}
	}
	if best == '' || best_distance > max_distance || best_distance >= input.len {
		return ''
	}
	return 'did you mean `${best}`?'
}

// suggest_command returns a suggestion for a mistyped sub-command, including
// each sub-command's suggest_for aliases.
pub fn suggest_command(input string, commands []Command) string {
	mut names := []string{}
	for cmd in commands {
		if cmd.hidden {
			continue
		}
		names << cmd.name
		names << cmd.aliases
		names << cmd.suggest_for
	}
	return suggest(input, names)
}

// suggest_subcommand suggests a sub-command of c, honoring c's
// suggest_min_distance threshold.
pub fn (c &Command) suggest_subcommand(input string) string {
	mut names := []string{}
	for cmd in c.commands {
		if cmd.hidden {
			continue
		}
		names << cmd.name
		names << cmd.aliases
		names << cmd.suggest_for
	}
	max := if c.suggest_min_distance > 0 { c.suggest_min_distance } else { 2 }
	return suggest_with(input, names, max)
}

fn suggest_flags(input string, flags []Flag) string {
	mut names := []string{}
	for f in flags {
		if f.name != '' {
			names << f.name
		}
	}
	return suggest(input, names)
}
