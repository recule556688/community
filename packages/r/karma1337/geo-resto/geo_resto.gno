package georesto

import (
	"chain/runtime"
	"strconv"
	"strings"
)

var (
	// locationManager handles all location-related operations
	locationManager = NewLocationManager()
	// visitManager manages user visits and check-ins
	visitManager = NewVisitManager()
	// eventManager handles location-based events and airdrops
	eventManager = NewEventManager()
	// renderer handles the display and formatting of geographic data
	renderer = NewRenderer()
	// authManager handles access control and proof verification
	authManager = NewAuthManager()
)

// Render displays the main interface for the geo-resto application
func Render(path string) string {
	parts := strings.Split(path, "/")
	if len(parts) == 0 {
		return renderer.RenderMainPage()
	}

	switch parts[0] {
	case "locations":
		if len(parts) > 1 {
			return renderer.RenderLocation(parts[1])
		}
		return renderer.RenderAllLocations()
	case "visits":
		if len(parts) > 1 {
			return renderer.RenderUserVisits(parts[1])
		}
		return renderer.RenderRecentVisits()
	case "events":
		if len(parts) > 1 {
			return renderer.RenderEvent(parts[1])
		}
		return renderer.RenderActiveEvents()
	case "map":
		return renderer.RenderWorldMap()
	default:
		return renderer.RenderMainPage()
	}
}

// Public API Functions

// AddLocation allows adding a new geographic location to the system
func AddLocation(name, description string, latitude, longitude float64, category string) string {
	caller := runtime.PreviousRealm().Address()
	if !authManager.CheckRateLimit(caller.String(), "add_location", 60) {
		return "Rate limit exceeded. Please try again later."
	}
	location := locationManager.AddLocation(caller, name, description, latitude, longitude, category)
	return "Location added with ID: " + location.ID
}

// CheckIn allows a user to check in at a specific location
func CheckIn(locationID, proof string) string {
	caller := runtime.PreviousRealm().Address()
	if !authManager.CheckRateLimit(caller.String(), "check_in", 60) {
		return "Rate limit exceeded. Please try again later."
	}
	visit := visitManager.CheckIn(caller, locationID, proof)
	if visit == nil {
		return "Check-in failed"
	}
	return "Successfully checked in at location: " + locationID
}

// CreateEvent creates a location-based event (like airdrops)
func CreateEvent(locationID, name, description, password string, eventType int, startTime, endTime int64) string {
	caller := runtime.PreviousRealm().Address()
	if !authManager.CheckRateLimit(caller.String(), "create_event", 300) { // 5 minute cooldown
		return "Rate limit exceeded. Please try again later."
	}
	event := eventManager.CreateEvent(caller, locationID, name, description, password, eventType, startTime, endTime)
	return "Event created with ID: " + event.ID
}

// JoinEvent allows a user to join an event with proper authentication
func JoinEvent(eventID, password string) string {
	caller := runtime.PreviousRealm().Address()
	if !authManager.CheckRateLimit(caller.String(), "join_event:"+eventID, 60) {
		return "Rate limit exceeded. Please try again later."
	}
	success := eventManager.JoinEvent(eventID, password, caller)
	if success {
		return "Successfully joined event: " + eventID
	}
	return "Failed to join event"
}

// GetUserStats returns statistics for a specific user
func GetUserStats(userAddress string) string {
	if userAddress == "" {
		userAddress = runtime.PreviousRealm().Address().String()
	}

	visitCount := visitManager.GetUserVisitCount(userAddress)
	locationCount := locationManager.GetUserLocationCount(userAddress)

	return "User " + userAddress + " - Visits: " + strconv.Itoa(visitCount) + ", Locations Added: " + strconv.Itoa(locationCount)
}

// GetEventStats returns statistics for a specific event
func GetEventStats(eventID string) string {
	if eventID == "" {
		return "Error: Event ID is required"
	}

	caller := runtime.PreviousRealm().Address()
	total, verified, rate := eventManager.GetAttendeeVerificationStats(eventID, caller)
	rateStr := strconv.Itoa(int(rate)) + "." + strconv.Itoa(int((rate-float64(int(rate)))*10))
	return "Event " + eventID + " - Total Participants: " + strconv.Itoa(total) +
		", Verified: " + strconv.Itoa(verified) +
		", Verification Rate: " + rateStr + "%"
}

// GetLocationChallenge returns a challenge for a specific location
func GetLocationChallenge(locationID string) string {
	return authManager.GenerateLocationChallenge(locationID)
}
