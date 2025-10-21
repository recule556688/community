package georesto

import (
	"std"
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
	caller := std.PreviousRealm().Address()
	location := locationManager.AddLocation(caller, name, description, latitude, longitude, category)
	return "Location added with ID: " + location.ID
}

// CheckIn allows a user to check in at a specific location
func CheckIn(locationID, proof string) string {
	caller := std.PreviousRealm().Address()
	visit := visitManager.CheckIn(caller, locationID, proof)
	if visit == nil {
		return "Check-in failed"
	}
	return "Successfully checked in at location: " + locationID
}

// CreateEvent creates a location-based event (like airdrops)
func CreateEvent(locationID, name, description, password string, eventType int, startTime, endTime int64) string {
	caller := std.PreviousRealm().Address()
	event := eventManager.CreateEvent(caller, locationID, name, description, password, eventType, startTime, endTime)
	return "Event created with ID: " + event.ID
}

// JoinEvent allows a user to join an event with proper authentication
func JoinEvent(eventID, password string) string {
	caller := std.PreviousRealm().Address()
	success := eventManager.JoinEvent(caller, eventID, password)
	if success {
		return "Successfully joined event: " + eventID
	}
	return "Failed to join event"
}

// GetUserStats returns statistics for a specific user
func GetUserStats(userAddress string) string {
	if userAddress == "" {
		userAddress = std.PreviousRealm().Address().String()
	}
	
	visitCount := visitManager.GetUserVisitCount(userAddress)
	locationCount := locationManager.GetUserLocationCount(userAddress)
	
	return "User " + userAddress + " - Visits: " + strconv.Itoa(visitCount) + ", Locations Added: " + strconv.Itoa(locationCount)
}

// VerifyVisit provides cryptographic proof that a user visited a location
func VerifyVisit(userAddress, locationID string, timestamp int64) bool {
	return visitManager.VerifyVisit(userAddress, locationID, timestamp)
}

// GetEventQRCode returns the QR code for event organizers to verify attendees
func GetEventQRCode(eventID string) string {
	caller := std.PreviousRealm().Address()
	return eventManager.GetEventQRCode(eventID, caller)
}

// GenerateAttendeeCode generates a verification code for an attendee at an event
func GenerateAttendeeCode(eventID string) string {
	caller := std.PreviousRealm().Address()
	return eventManager.GenerateAttendeeVerificationCode(eventID, caller)
}

// VerifyAttendeePresence allows event organizers to verify attendee presence using verification codes
func VerifyAttendeePresence(eventID, verificationCode, attendeeAddress string) string {
	caller := std.PreviousRealm().Address()
	success := eventManager.VerifyAttendeePresence(eventID, verificationCode, caller, attendeeAddress)
	if success {
		return "Attendee verified successfully for event: " + eventID
	}
	return "Failed to verify attendee presence"
}

// GetVerifiedAttendees returns the list of verified attendees for an event
func GetVerifiedAttendees(eventID string) string {
	caller := std.PreviousRealm().Address()
	attendees := eventManager.GetVerifiedAttendees(eventID, caller)
	if len(attendees) == 0 {
		return "No verified attendees for event: " + eventID
	}
	return "Verified attendees (" + strconv.Itoa(len(attendees)) + "): " + strings.Join(attendees, ", ")
}

// GetEventVerificationStats returns verification statistics for an event
func GetEventVerificationStats(eventID string) string {
	caller := std.PreviousRealm().Address()
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
