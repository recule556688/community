package conway

// GameEngine handles the core Conway's Game of Life logic.
type GameEngine struct{}

// NewGameEngine creates a new game engine instance.
func NewGameEngine() *GameEngine {
	return &GameEngine{}
}

// CountNeighbors counts the number of living neighbors for a cell at coordinates (x, y).
func (ge *GameEngine) CountNeighbors(grid *Grid, x, y int) int {
	count := 0
	for dy := -1; dy <= 1; dy++ {
		for dx := -1; dx <= 1; dx++ {
			if dx == 0 && dy == 0 {
				continue // Skip the cell itself
			}
			if grid.GetCell(x+dx, y+dy) {
				count++
			}
		}
	}
	return count
}

// ApplyRules applies Conway's Game of Life rules to determine the next cell state.
// Returns true if the cell should be alive in the next generation, false otherwise.
func (ge *GameEngine) ApplyRules(isAlive bool, neighborCount int) bool {
	// Conway's Game of Life rules:
	// 1. Any live cell with 2-3 live neighbors survives
	// 2. Any dead cell with exactly 3 live neighbors becomes alive
	// 3. All other live cells die, all other dead cells stay dead
	if isAlive {
		return neighborCount == 2 || neighborCount == 3
	}
	return neighborCount == 3
}

// Step advances the game by one generation and returns the new grid state.
func (ge *GameEngine) Step(grid *Grid) *Grid {
	newGrid := NewGrid()
	newGrid.generation = grid.generation + 1
	
	for y := 0; y < GRID_HEIGHT; y++ {
		for x := 0; x < GRID_WIDTH; x++ {
			neighbors := ge.CountNeighbors(grid, x, y)
			alive := grid.GetCell(x, y)
			newGrid.SetCell(x, y, ge.ApplyRules(alive, neighbors))
		}
	}
	
	return newGrid
}