package conway

import (
	"testing"
)

func TestGridCreation(t *testing.T) {
	// Test that we can create a new grid
	grid := NewGrid()
	if grid == nil {
		t.Error("Expected NewGrid to return a non-nil grid")
	}
	
	// Test initial state
	if grid.GetCell(0, 0) {
		t.Error("Expected new grid cells to be dead initially")
	}
}

func TestGameEngineCreation(t *testing.T) {
	// Test that we can create a game engine
	engine := NewGameEngine()
	if engine == nil {
		t.Error("Expected NewGameEngine to return a non-nil engine")
	}
}

func TestPatternManagerCreation(t *testing.T) {
	// Test that we can create a pattern manager
	pm := NewPatternManager()
	if pm == nil {
		t.Error("Expected NewPatternManager to return a non-nil pattern manager")
	}
	
	// Test that it has some patterns
	patterns := pm.GetAvailablePatterns()
	if len(patterns) == 0 {
		t.Error("Expected pattern manager to have at least one pattern")
	}
}

func TestRendererCreation(t *testing.T) {
	// Test that we can create a renderer
	r := NewRenderer()
	if r == nil {
		t.Error("Expected NewRenderer to return a non-nil renderer")
	}
}