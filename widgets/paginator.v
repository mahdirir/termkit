module widgets

import termkit

// Paginator tracks a page over an item count.
pub struct Paginator {
pub mut:
	page     int
	per_page int = 10
	total    int
}

fn (p Paginator) pages() int {
	if p.per_page <= 0 {
		return 0
	}
	return (p.total + p.per_page - 1) / p.per_page
}

// set_total updates the item count and keeps the page in range.
pub fn (mut p Paginator) set_total(total int) {
	p.total = total
	pages := p.pages()
	if pages > 0 && p.page >= pages {
		p.page = pages - 1
	}
	if p.page < 0 {
		p.page = 0
	}
}

// start returns the index of the first item on the current page.
pub fn (p Paginator) start() int {
	return p.page * p.per_page
}

// end returns the index just past the last item on the current page.
pub fn (p Paginator) end() int {
	e := p.start() + p.per_page
	return if e > p.total { p.total } else { e }
}

// update handles left/right page navigation.
pub fn (mut p Paginator) update(msg termkit.Msg) {
	match msg {
		termkit.KeyMsg {
			if msg.kind != .press {
				return
			}
			match msg.key {
				termkit.key_left {
					if p.page > 0 {
						p.page--
					}
				}
				termkit.key_right {
					if p.page < p.pages() - 1 {
						p.page++
					}
				}
				else {}
			}
		}
		else {}
	}
}

// view renders a compact page indicator.
pub fn (p Paginator) view() string {
	pages := p.pages()
	if pages == 0 {
		return 'no items'
	}
	return '‹ ${p.page + 1}/${pages} ›'
}
