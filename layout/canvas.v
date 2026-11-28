module layout

// Layer is one stacked block of text on a canvas. Higher z draws on top;
// spaces are transparent and never overwrite cells below.
pub struct Layer {
pub:
	id      string
	content string
	x       int
	y       int
	z       int
}

// layer_cell is one composited cell.
struct LayerCell {
	ch      string
	layer   string
	covered bool
}

// Compositor stacks layers into a single block and hit-tests coordinates.
pub struct Compositor {
pub mut:
	width  int
	height int
mut:
	layers []Layer
}

// add_layer stacks a layer on the canvas.
pub fn (mut c Compositor) add_layer(layer Layer) {
	c.layers << layer
}

// clear_layers removes every layer.
pub fn (mut c Compositor) clear_layers() {
	c.layers = []Layer{}
}

// layer_count returns the number of stacked layers.
pub fn (c Compositor) layer_count() int {
	return c.layers.len
}

fn sorted_layers(layers []Layer) []Layer {
	mut out := layers.clone()
	for i in 1 .. out.len {
		key := out[i]
		mut j := i - 1
		for j >= 0 && out[j].z > key.z {
			out[j + 1] = out[j]
			j--
		}
		out[j + 1] = key
	}
	return out
}

fn (c Compositor) grid() [][]LayerCell {
	mut grid := [][]LayerCell{len: c.height, init: []LayerCell{len: c.width}}
	for layer in sorted_layers(c.layers) {
		lines := layer.content.split('\n')
		for row, line in lines {
			y := layer.y + row
			if y < 0 || y >= c.height {
				continue
			}
			mut x := layer.x
			for r in line.runes() {
				ch := r.str()
				if x >= 0 && x < c.width && ch != ' ' {
					grid[y][x] = LayerCell{ ch: ch, layer: layer.id, covered: true }
				}
				x++
			}
		}
	}
	return grid
}

// render composites the layers into a width x height block. Later and higher
// layers cover earlier ones; spaces never overwrite.
pub fn (c Compositor) render() string {
	if c.width <= 0 || c.height <= 0 {
		return ''
	}
	grid := c.grid()
	mut out := []string{}
	for y in 0 .. c.height {
		mut line := ''
		for x in 0 .. c.width {
			cell := grid[y][x]
			line += if cell.covered { cell.ch } else { ' ' }
		}
		out << line
	}
	return out.join('\n')
}

// hit returns the id of the topmost layer covering x, y, or '' when the cell
// is empty or outside the canvas.
pub fn (c Compositor) hit(x int, y int) string {
	if x < 0 || y < 0 || x >= c.width || y >= c.height {
		return ''
	}
	grid := c.grid()
	cell := grid[y][x]
	if cell.covered {
		return cell.layer
	}
	return ''
}
