package georesto

import (
	"std"
	"strconv"
	"strings"
	"time"
)

// Location represents a geographic point with metadata
type Location struct {
	ID          string  // Unique identifier
	Name        string  // Human-readable name
	Description string  // Detailed description
	Latitude    float64 // GPS latitude
	Longitude   float64 // GPS longitude
	Category    string  // Type of location (restaurant, landmark, etc.)
	Creator     std.Address // Address of the user who added this location
	CreatedAt   int64   // Unix timestamp
	VisitCount  int     // Number of check-ins at this location
	Verified    bool    // Whether location is verified by community
}

// LocationManager handles all location-related operations
type LocationManager struct {
	locations     map[string]*Location // ID -> Location
	locationsByUser map[string][]string // User address -> Location IDs
	nextID        int
}

// NewLocationManager creates a new location manager instance
func NewLocationManager() *LocationManager {
	return &LocationManager{
		locations:       make(map[string]*Location),
		locationsByUser: make(map[string][]string),
		nextID:          1,
	}
}

// AddLocation adds a new location to the system
func (lm *LocationManager) AddLocation(creator std.Address, name, description string, latitude, longitude float64, category string) *Location {
	// Validate coordinates
	if latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180 {
		panic("Invalid coordinates")
	}
	
	// Validate required fields
	if strings.TrimSpace(name) == "" {
		panic("Location name is required")
	}
	
	// Generate unique ID
	id := "loc_" + strconv.Itoa(lm.nextID)
	lm.nextID++
	
	location := &Location{
		ID:          id,
		Name:        strings.TrimSpace(name),
		Description: strings.TrimSpace(description),
		Latitude:    latitude,
		Longitude:   longitude,
		Category:    strings.TrimSpace(category),
		Creator:     creator,
		CreatedAt:   time.Now().Unix(),
		VisitCount:  0,
		Verified:    false,
	}
	
	lm.locations[id] = location
	
	// Track locations by user
	userAddr := creator.String()
	lm.locationsByUser[userAddr] = append(lm.locationsByUser[userAddr], id)
	
	return location
}

// GetLocation retrieves a location by ID
func (lm *LocationManager) GetLocation(id string) *Location {
	location, exists := lm.locations[id]
	if !exists {
		return nil
	}
	return location
}

// GetAllLocations returns all locations in the system
func (lm *LocationManager) GetAllLocations() []*Location {
	locations := make([]*Location, 0, len(lm.locations))
	for _, location := range lm.locations {
		locations = append(locations, location)
	}
	return locations
}

// GetLocationsByUser returns all locations created by a specific user
func (lm *LocationManager) GetLocationsByUser(userAddress string) []*Location {
	locationIDs, exists := lm.locationsByUser[userAddress]
	if !exists {
		return []*Location{}
	}
	
	locations := make([]*Location, 0, len(locationIDs))
	for _, id := range locationIDs {
		if location := lm.GetLocation(id); location != nil {
			locations = append(locations, location)
		}
	}
	return locations
}

// GetLocationsByCategory returns all locations in a specific category
func (lm *LocationManager) GetLocationsByCategory(category string) []*Location {
	locations := make([]*Location, 0)
	for _, location := range lm.locations {
		if strings.EqualFold(location.Category, category) {
			locations = append(locations, location)
		}
	}
	return locations
}

// IncrementVisitCount increases the visit count for a location
func (lm *LocationManager) IncrementVisitCount(locationID string) {
	if location := lm.GetLocation(locationID); location != nil {
		location.VisitCount++
	}
}

// GetUserLocationCount returns the number of locations created by a user
func (lm *LocationManager) GetUserLocationCount(userAddress string) int {
	locationIDs, exists := lm.locationsByUser[userAddress]
	if !exists {
		return 0
	}
	return len(locationIDs)
}

// VerifyLocation marks a location as verified (community consensus mechanism)
func (lm *LocationManager) VerifyLocation(locationID string, verifier std.Address) bool {
	location := lm.GetLocation(locationID)
	if location == nil {
		return false
	}
	
	// Simple verification - in a real system, this would involve community voting
	// or trusted verifier addresses
	location.Verified = true
	return true
}

// GetNearbyLocations returns locations within a rough distance (simplified calculation)
func (lm *LocationManager) GetNearbyLocations(latitude, longitude, radiusKm float64) []*Location {
	nearby := make([]*Location, 0)
	
	for _, location := range lm.locations {
		// Simplified distance calculation (not precise for production)
		latDiff := location.Latitude - latitude
		lonDiff := location.Longitude - longitude
		roughDistance := (latDiff*latDiff + lonDiff*lonDiff) * 111.0 // Rough km conversion
		
		if roughDistance <= radiusKm*radiusKm {
			nearby = append(nearby, location)
		}
	}
	
	return nearby
}