package conway

const (
	GRID_WIDTH  = 20
	GRID_HEIGHT = 20
)

// Grid represents the game state
type Grid struct {
	cells      [GRID_HEIGHT][GRID_WIDTH]bool
	generation int
}

// NewGrid creates a new empty grid
func NewGrid() *Grid {
	return &Grid{
		cells:      [GRID_HEIGHT][GRID_WIDTH]bool{},
		generation: 0,
	}
}

// SetCell sets a cell to alive (true) or dead (false)
func (g *Grid) SetCell(x, y int, alive bool) {
	if g.isValidCoordinate(x, y) {
		g.cells[y][x] = alive
	}
}

// GetCell returns the state of a cell
func (g *Grid) GetCell(x, y int) bool {
	if g.isValidCoordinate(x, y) {
		return g.cells[y][x]
	}
	return false
}

// isValidCoordinate checks if coordinates are within grid bounds
func (g *Grid) isValidCoordinate(x, y int) bool {
	return x >= 0 && x < GRID_WIDTH && y >= 0 && y < GRID_HEIGHT
}

// GetGeneration returns the current generation number
func (g *Grid) GetGeneration() int {
	return g.generation
}

// IncrementGeneration increases the generation counter
func (g *Grid) IncrementGeneration() {
	g.generation++
}

// Clear resets the grid to all dead cells
func (g *Grid) Clear() {
	g.cells = [GRID_HEIGHT][GRID_WIDTH]bool{}
	g.generation = 0
}

// Copy creates a deep copy of the grid
func (g *Grid) Copy() *Grid {
	newGrid := &Grid{
		generation: g.generation,
	}
	newGrid.cells = g.cells // Array copy in Go
	return newGrid
}