package conway

import (
	"strconv"
	"strings"
)

// Helper function to convert letter to column number (A=0, B=1, etc.)
func letterToColumn(letter string) int {
	if len(letter) == 0 {
		return -1
	}
	// Convert to uppercase and get first character
	upper := strings.ToUpper(letter)
	col := int(upper[0] - 'A')
	if col < 0 || col >= GRID_WIDTH {
		return -1
	}
	return col
}

// Helper function to convert column number to letter (0=A, 1=B, etc.)
func columnToLetter(col int) string {
	if col < 0 || col >= GRID_WIDTH {
		return ""
	}
	return string(rune('A' + col))
}

// Global game state
var (
	currentGrid    *Grid
	gameEngine     *GameEngine
	patternManager *PatternManager
	renderer       *Renderer
)

// Initialize the game components
func init() {
	currentGrid = NewGrid()
	gameEngine = NewGameEngine()
	patternManager = NewPatternManager()
	renderer = NewRenderer()
}

// NewGame initializes a new Conway's Game of Life with an empty grid
func NewGame(_ realm) {
	currentGrid = NewGrid()
}

// SetCell sets a cell to alive (true) or dead (false)
func SetCell(_ realm, x, y int, alive bool) {
	currentGrid.SetCell(x, y, alive)
}

// GetCell returns the state of a cell
func GetCell(_ realm, x, y int) bool {
	return currentGrid.GetCell(x, y)
}

// Step advances the game by one generation according to Conway's rules
func Step(_ realm) {
	currentGrid = gameEngine.Step(currentGrid)
}

// GetGeneration returns the current generation number
func GetGeneration(_ realm) int {
	return currentGrid.GetGeneration()
}

// Clear resets the grid to all dead cells
func Clear(_ realm) {
	currentGrid.Clear()
}

// LoadPattern loads a predefined pattern into the grid at the specified position
func LoadPattern(_ realm, pattern string, startX, startY int) bool {
	return patternManager.LoadPattern(currentGrid, pattern, startX, startY)
}

// GetAvailablePatterns returns a list of available pattern names
func GetAvailablePatterns(_ realm) []string {
	return patternManager.GetAvailablePatterns()
}

// SetCellAt sets a cell using letter-number coordinates (e.g., "F5")
func SetCellAt(_ realm, coordinate string, alive bool) bool {
	col, row, valid := parseCoordinate(coordinate)
	if !valid {
		return false
	}
	currentGrid.SetCell(col, row, alive)
	return true
}

// GetCellAt returns the state of a cell using letter-number coordinates (e.g., "F5")
func GetCellAt(_ realm, coordinate string) (bool, bool) {
	col, row, valid := parseCoordinate(coordinate)
	if !valid {
		return false, false
	}
	return currentGrid.GetCell(col, row), true
}

// LoadPatternAt loads a pattern using letter-number coordinates (e.g., "F5")
func LoadPatternAt(_ realm, pattern string, coordinate string) bool {
	col, row, valid := parseCoordinate(coordinate)
	if !valid {
		return false
	}
	return patternManager.LoadPattern(currentGrid, pattern, col, row)
}

// Helper function to parse coordinates like "F5" into column and row numbers
func parseCoordinate(coordinate string) (int, int, bool) {
	if len(coordinate) < 2 {
		return -1, -1, false
	}
	
	// Extract letter part and number part
	letter := coordinate[:1]
	numberStr := coordinate[1:]
	
	// Convert letter to column
	col := letterToColumn(letter)
	if col == -1 {
		return -1, -1, false
	}
	
	// Convert number string to row
	row, err := strconv.Atoi(numberStr)
	if err != nil || row < 0 || row >= GRID_HEIGHT {
		return -1, -1, false
	}
	
	return col, row, true
}

// Render displays the current state of the game
func Render(path string) string {
	var output strings.Builder
	
	output.WriteString("# Conway's Game of Life\n\n")
	output.WriteString("Generation: " + strconv.Itoa(currentGrid.GetGeneration()) + "\n\n")
	
	output.WriteString(renderer.RenderHelp(patternManager))
	output.WriteString(renderer.RenderGrid(currentGrid))
	
	return output.String()
}