package georesto

import (
	"std"
	"testing"
)

func TestLocationManager(t *testing.T) {
	// Test adding a location using global manager
	creator := std.Address("g1test123")
	location := locationManager.AddLocation(creator, "Test Restaurant", "A great place to eat", 48.8566, 2.3522, "restaurant")
	
	if location == nil {
		t.Fatal("Failed to create location")
	}
	
	if location.Name != "Test Restaurant" {
		t.Errorf("Expected name 'Test Restaurant', got '%s'", location.Name)
	}
	
	if location.Latitude != 48.8566 {
		t.Errorf("Expected latitude 48.8566, got %f", location.Latitude)
	}
	
	// Test retrieving the location
	retrieved := locationManager.GetLocation(location.ID)
	if retrieved == nil {
		t.Fatal("Failed to retrieve location")
	}
	
	if retrieved.Name != location.Name {
		t.Errorf("Retrieved location name mismatch")
	}
	
	// Test getting locations by user
	userLocations := locationManager.GetLocationsByUser(creator.String())
	if len(userLocations) != 1 {
		t.Errorf("Expected 1 location for user, got %d", len(userLocations))
	}
	
	// Test invalid coordinates
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("Expected panic for invalid coordinates")
		}
	}()
	locationManager.AddLocation(creator, "Invalid Location", "Bad coords", 91.0, 0.0, "test")
}

func TestLocationCategories(t *testing.T) {
	creator := std.Address("g1test123")
	
	// Add locations in different categories
	locationManager.AddLocation(creator, "Restaurant 1", "Food", 48.8566, 2.3522, "restaurant")
	locationManager.AddLocation(creator, "Museum 1", "Culture", 48.8606, 2.3376, "museum")
	locationManager.AddLocation(creator, "Restaurant 2", "More food", 48.8584, 2.2945, "restaurant")
	
	// Test getting by category
	restaurants := locationManager.GetLocationsByCategory("restaurant")
	if len(restaurants) < 2 {
		t.Errorf("Expected at least 2 restaurants, got %d", len(restaurants))
	}
	
	museums := locationManager.GetLocationsByCategory("museum")
	if len(museums) < 1 {
		t.Errorf("Expected at least 1 museum, got %d", len(museums))
	}
}

func TestLocationVisitCount(t *testing.T) {
	creator := std.Address("g1test123")
	
	location := locationManager.AddLocation(creator, "Test Location", "Test", 48.8566, 2.3522, "test")
	
	if location.VisitCount != 0 {
		t.Errorf("Expected initial visit count 0, got %d", location.VisitCount)
	}
	
	// Increment visit count
	locationManager.IncrementVisitCount(location.ID)
	
	retrieved := locationManager.GetLocation(location.ID)
	if retrieved.VisitCount != 1 {
		t.Errorf("Expected visit count 1, got %d", retrieved.VisitCount)
	}
}

func TestLocationVerification(t *testing.T) {
	creator := std.Address("g1test123")
	verifier := std.Address("g1verifier123")
	
	location := locationManager.AddLocation(creator, "Test Location", "Test", 48.8566, 2.3522, "test")
	
	if location.Verified {
		t.Error("Location should not be verified initially")
	}
	
	// Verify location
	success := locationManager.VerifyLocation(location.ID, verifier)
	if !success {
		t.Error("Failed to verify location")
	}
	
	retrieved := locationManager.GetLocation(location.ID)
	if !retrieved.Verified {
		t.Error("Location should be verified")
	}
}