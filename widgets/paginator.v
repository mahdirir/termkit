module widgets

import termkit

// PaginatorStyle selects the page indicator rendering.
pub enum PaginatorStyle {
	arabic
	dots
}

// Paginator tracks a page over an item count.
pub struct Paginator {
pub mut:
	page     int
	per_page int = 10
	total    int
	// style selects arabic (`‹ 1/3 ›`) or dot indicators.
	style PaginatorStyle = .arabic
	// arabic_format renders the page numbers; it receives page and pages.
	arabic_format string = '%d/%d'
	// active_dot and inactive_dot draw the dots indicator.
	active_dot   string = '●'
	inactive_dot string = '○'
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
	if p.style == .dots {
		mut dots := []string{}
		for i in 0 .. pages {
			dots << if i == p.page { p.active_dot } else { p.inactive_dot }
		}
		return dots.join(' ')
	}
	nums := p.arabic_format.replace_once('%d', '${p.page + 1}').replace_once('%d',
		'${pages}')
	return '‹ ${nums} ›'
}
