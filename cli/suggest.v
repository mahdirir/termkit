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
	mut best := ''
	mut best_distance := 1_000_000
	for candidate in candidates {
		d := levenshtein(input, candidate)
		if d < best_distance {
			best_distance = d
			best = candidate
		}
	}
	if best == '' || best_distance > 2 || best_distance >= input.len {
		return ''
	}
	return 'did you mean `${best}`?'
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
