package conway

import (
	"strings"
	"testing"
)

func TestNewRenderer(t *testing.T) {
	renderer := NewRenderer()
	if renderer == nil {
		t.Error("Expected NewRenderer to return a non-nil renderer")
	}
}

func TestRenderGrid(t *testing.T) {
	renderer := NewRenderer()
	grid := NewGrid()
	
	// Test rendering empty grid
	output := renderer.RenderGrid(grid)
	if len(output) == 0 {
		t.Error("Expected non-empty output from RenderGrid")
	}
	
	// Set some cells and test again
	grid.SetCell(5, 5, true)
	grid.SetCell(6, 6, true)
	
	outputWithCells := renderer.RenderGrid(grid)
	if len(outputWithCells) == 0 {
		t.Error("Expected non-empty output from RenderGrid with cells")
	}
	
	// The outputs should be different
	if output == outputWithCells {
		t.Error("Expected different outputs for empty vs populated grid")
	}
}

func TestRenderHelp(t *testing.T) {
	renderer := NewRenderer()
	patternManager := NewPatternManager()
	
	helpOutput := renderer.RenderHelp(patternManager)
	if len(helpOutput) == 0 {
		t.Error("Expected non-empty help output")
	}
	
	// Help should contain some expected text
	if !strings.Contains(helpOutput, "Available") {
		t.Error("Expected help output to contain 'Available'")
	}
}

func TestMainRenderFunction(t *testing.T) {
	// Test the main Render function
	output := Render("")
	
	// Check that output contains expected elements
	if !strings.Contains(output, "Conway's Game of Life") {
		t.Error("Expected output to contain title")
	}
	
	if !strings.Contains(output, "Generation:") {
		t.Error("Expected output to contain generation info")
	}
	
	// Output should not be empty
	if len(output) == 0 {
		t.Error("Expected non-empty render output")
	}
}