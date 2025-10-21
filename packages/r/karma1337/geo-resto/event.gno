package georesto

import (
	"std"
	"crypto/sha256"
	"encoding/hex"
	"strconv"
	"strings"
	"time"
)

// EventType defines the type of location-based event
type EventType int

const (
	EventTypeAirdrop EventType = iota
	EventTypeMeetup
	EventTypeEmergency
	EventTypeContest
	EventTypeCheckpoint
)

// Event represents a location-based event (airdrops, meetups, etc.)
type Event struct {
	ID           string      // Unique event identifier
	LocationID   string      // Associated location ID
	Creator      std.Address // Event creator
	Name         string      // Event name
	Description  string      // Event description
	EventType    EventType   // Type of event
	Password     string      // Access password (hashed)
	StartTime    int64       // Event start timestamp
	EndTime      int64       // Event end timestamp
	CreatedAt    int64       // Creation timestamp
	Participants []string    // List of participant addresses
	MaxParticipants int      // Maximum number of participants (0 = unlimited)
	IsActive     bool        // Whether the event is currently active
	Rewards      string      // Description of rewards/airdrops
	QRCode       string      // QR code data for event verification
	VerificationSecret string // Secret key for generating verification codes
	VerifiedAttendees []string // List of verified attendee addresses
}

// EventManager handles all event-related operations
type EventManager struct {
	events          map[string]*Event   // Event ID -> Event
	eventsByLocation map[string][]string // Location ID -> Event IDs
	eventsByCreator  map[string][]string // Creator address -> Event IDs
	activeEvents     []string            // Currently active event IDs
	nextID           int
}

// NewEventManager creates a new event manager instance
func NewEventManager() *EventManager {
	return &EventManager{
		events:           make(map[string]*Event),
		eventsByLocation: make(map[string][]string),
		eventsByCreator:  make(map[string][]string),
		activeEvents:     make([]string, 0),
		nextID:           1,
	}
}

// CreateEvent creates a new location-based event
func (em *EventManager) CreateEvent(creator std.Address, locationID, name, description, password string, eventType int, startTime, endTime int64) *Event {
	// Verify the location exists
	location := locationManager.GetLocation(locationID)
	if location == nil {
		panic("Location does not exist")
	}
	
	// Validate event times
	currentTime := time.Now().Unix()
	if startTime < currentTime {
		panic("Event start time cannot be in the past")
	}
	if endTime <= startTime {
		panic("Event end time must be after start time")
	}
	
	// Validate required fields
	if strings.TrimSpace(name) == "" {
		panic("Event name is required")
	}
	
	// Generate unique event ID
	eventID := "event_" + strconv.Itoa(em.nextID)
	em.nextID++
	
	// Hash the password for security
	hashedPassword := ""
	if password != "" {
		hashedPassword = em.hashPassword(password)
	}
	
	// Generate verification secret for QR codes
	verificationSecret := em.generateVerificationSecret(eventID, creator.String())
	
	// Generate QR code data (contains event ID and verification info)
	qrData := em.generateQRCode(eventID, verificationSecret)
	
	event := &Event{
		ID:              eventID,
		LocationID:      locationID,
		Creator:         creator,
		Name:            strings.TrimSpace(name),
		Description:     strings.TrimSpace(description),
		EventType:       EventType(eventType),
		Password:        hashedPassword,
		StartTime:       startTime,
		EndTime:         endTime,
		CreatedAt:       currentTime,
		Participants:    make([]string, 0),
		MaxParticipants: 0, // Unlimited by default
		IsActive:        false,
		Rewards:         "",
		QRCode:          qrData,
		VerificationSecret: verificationSecret,
		VerifiedAttendees: make([]string, 0),
	}
	
	// Store the event
	em.events[eventID] = event
	
	// Index by location
	em.eventsByLocation[locationID] = append(em.eventsByLocation[locationID], eventID)
	
	// Index by creator
	creatorAddr := creator.String()
	em.eventsByCreator[creatorAddr] = append(em.eventsByCreator[creatorAddr], eventID)
	
	// Activate event if it should start now
	em.updateEventStatus(event)
	
	return event
}

// JoinEvent allows a user to join an event with proper authentication
func (em *EventManager) JoinEvent(user std.Address, eventID, password string) bool {
	event := em.GetEvent(eventID)
	if event == nil {
		return false
	}
	
	// Check if event is active
	em.updateEventStatus(event)
	if !event.IsActive {
		return false
	}
	
	// Verify password if required
	if event.Password != "" {
		if !em.verifyPassword(password, event.Password) {
			return false
		}
	}
	
	userAddr := user.String()
	
	// Check if user is already a participant
	for _, participant := range event.Participants {
		if participant == userAddr {
			return true // Already joined
		}
	}
	
	// Check participant limit
	if event.MaxParticipants > 0 && len(event.Participants) >= event.MaxParticipants {
		return false
	}
	
	// Add user to participants
	event.Participants = append(event.Participants, userAddr)
	return true
}

// GetEvent retrieves an event by ID
func (em *EventManager) GetEvent(eventID string) *Event {
	event, exists := em.events[eventID]
	if !exists {
		return nil
	}
	return event
}

// GetActiveEvents returns all currently active events
func (em *EventManager) GetActiveEvents() []*Event {
	em.updateActiveEvents()
	
	events := make([]*Event, 0, len(em.activeEvents))
	for _, eventID := range em.activeEvents {
		if event := em.GetEvent(eventID); event != nil {
			events = append(events, event)
		}
	}
	return events
}

// GetLocationEvents returns all events for a specific location
func (em *EventManager) GetLocationEvents(locationID string) []*Event {
	eventIDs, exists := em.eventsByLocation[locationID]
	if !exists {
		return []*Event{}
	}
	
	events := make([]*Event, 0, len(eventIDs))
	for _, id := range eventIDs {
		if event := em.GetEvent(id); event != nil {
			em.updateEventStatus(event)
			events = append(events, event)
		}
	}
	return events
}

// GetUserEvents returns all events created by a specific user
func (em *EventManager) GetUserEvents(userAddress string) []*Event {
	eventIDs, exists := em.eventsByCreator[userAddress]
	if !exists {
		return []*Event{}
	}
	
	events := make([]*Event, 0, len(eventIDs))
	for _, id := range eventIDs {
		if event := em.GetEvent(id); event != nil {
			em.updateEventStatus(event)
			events = append(events, event)
		}
	}
	return events
}

// SetEventRewards sets the rewards description for an event
func (em *EventManager) SetEventRewards(eventID, rewards string, user std.Address) bool {
	event := em.GetEvent(eventID)
	if event == nil || event.Creator.String() != user.String() {
		return false
	}
	
	event.Rewards = rewards
	return true
}

// SetMaxParticipants sets the maximum number of participants for an event
func (em *EventManager) SetMaxParticipants(eventID string, maxParticipants int, user std.Address) bool {
	event := em.GetEvent(eventID)
	if event == nil || event.Creator.String() != user.String() {
		return false
	}
	
	event.MaxParticipants = maxParticipants
	return true
}

// IsUserParticipant checks if a user is participating in an event
func (em *EventManager) IsUserParticipant(eventID, userAddress string) bool {
	event := em.GetEvent(eventID)
	if event == nil {
		return false
	}
	
	for _, participant := range event.Participants {
		if participant == userAddress {
			return true
		}
	}
	return false
}

// updateEventStatus updates the active status of an event based on current time
func (em *EventManager) updateEventStatus(event *Event) {
	currentTime := time.Now().Unix()
	wasActive := event.IsActive
	
	event.IsActive = currentTime >= event.StartTime && currentTime <= event.EndTime
	
	// Update active events list if status changed
	if wasActive != event.IsActive {
		em.updateActiveEvents()
	}
}

// updateActiveEvents refreshes the list of active events
func (em *EventManager) updateActiveEvents() {
	currentTime := time.Now().Unix()
	em.activeEvents = make([]string, 0)
	
	for eventID, event := range em.events {
		if currentTime >= event.StartTime && currentTime <= event.EndTime {
			event.IsActive = true
			em.activeEvents = append(em.activeEvents, eventID)
		} else {
			event.IsActive = false
		}
	}
}

// hashPassword creates a hash of the password for secure storage
func (em *EventManager) hashPassword(password string) string {
	hash := sha256.Sum256([]byte(password))
	return hex.EncodeToString(hash[:])
}

// verifyPassword verifies a password against its hash
func (em *EventManager) verifyPassword(password, hashedPassword string) bool {
	return em.hashPassword(password) == hashedPassword
}

// GetEventTypeString returns a string representation of the event type
func (em *EventManager) GetEventTypeString(eventType EventType) string {
	switch eventType {
	case EventTypeAirdrop:
		return "Airdrop"
	case EventTypeMeetup:
		return "Meetup"
	case EventTypeEmergency:
		return "Emergency"
	case EventTypeContest:
		return "Contest"
	case EventTypeCheckpoint:
		return "Checkpoint"
	default:
		return "Unknown"
	}
}

// generateVerificationSecret creates a unique secret for event verification
func (em *EventManager) generateVerificationSecret(eventID, creatorAddress string) string {
	// Create a unique secret using event ID, creator, and current time
	data := eventID + ":" + creatorAddress + ":" + strconv.Itoa(int(time.Now().Unix()))
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])[:16] // Use first 16 chars as secret
}

// generateQRCode creates QR code data for event verification
func (em *EventManager) generateQRCode(eventID, verificationSecret string) string {
	// QR code contains: eventID|secret|timestamp
	timestamp := strconv.Itoa(int(time.Now().Unix()))
	qrData := eventID + "|" + verificationSecret + "|" + timestamp
	return qrData
}

// GenerateAttendeeVerificationCode creates a verification code for an attendee
func (em *EventManager) GenerateAttendeeVerificationCode(eventID string, attendeeAddress std.Address) string {
	event := em.events[eventID]
	if event == nil {
		return ""
	}
	
	// Only the event creator can generate verification codes
	if event.Creator.String() != attendeeAddress.String() {
		return ""
	}
	
	// Generate verification code using event secret and current timestamp
	timestamp := strconv.Itoa(int(time.Now().Unix()))
	data := eventID + ":" + event.VerificationSecret + ":" + timestamp
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])[:12] // 12-character verification code
}

// VerifyAttendeePresence verifies an attendee using their verification code
func (em *EventManager) VerifyAttendeePresence(eventID, verificationCode string, organizerAddress std.Address, attendeeAddress string) bool {
	event := em.events[eventID]
	if event == nil {
		return false
	}
	
	// Only the event creator/organizer can verify attendees
	if event.Creator.String() != organizerAddress.String() {
		return false
	}
	
	// Check if the verification code is valid (generated within last 5 minutes)
	currentTime := time.Now().Unix()
	for i := 0; i < 5; i++ { // Check last 5 minutes
		checkTime := currentTime - int64(i*60)
		expectedData := eventID + ":" + event.VerificationSecret + ":" + strconv.Itoa(int(checkTime))
		hash := sha256.Sum256([]byte(expectedData))
		expectedCode := hex.EncodeToString(hash[:])[:12]
		
		if verificationCode == expectedCode {
			// Add to verified attendees if not already verified
			for _, verified := range event.VerifiedAttendees {
				if verified == attendeeAddress {
					return true // Already verified
				}
			}
			event.VerifiedAttendees = append(event.VerifiedAttendees, attendeeAddress)
			return true
		}
	}
	
	return false
}

// GetEventQRCode returns the QR code for an event (only for event creator)
func (em *EventManager) GetEventQRCode(eventID string, requesterAddress std.Address) string {
	event := em.events[eventID]
	if event == nil {
		return ""
	}
	
	// Only the event creator can access the QR code
	if event.Creator.String() != requesterAddress.String() {
		return ""
	}
	
	return event.QRCode
}

// GetVerifiedAttendees returns the list of verified attendees for an event
func (em *EventManager) GetVerifiedAttendees(eventID string, requesterAddress std.Address) []string {
	event := em.events[eventID]
	if event == nil {
		return []string{}
	}
	
	// Only the event creator can see verified attendees
	if event.Creator.String() != requesterAddress.String() {
		return []string{}
	}
	
	return event.VerifiedAttendees
}

// GetAttendeeVerificationStats returns verification statistics for an event
func (em *EventManager) GetAttendeeVerificationStats(eventID string, requesterAddress std.Address) (int, int, float64) {
	event := em.events[eventID]
	if event == nil {
		return 0, 0, 0.0
	}
	
	// Only the event creator can see stats
	if event.Creator.String() != requesterAddress.String() {
		return 0, 0, 0.0
	}
	
	totalParticipants := len(event.Participants)
	verifiedAttendees := len(event.VerifiedAttendees)
	verificationRate := 0.0
	
	if totalParticipants > 0 {
		verificationRate = float64(verifiedAttendees) / float64(totalParticipants) * 100.0
	}
	
	return totalParticipants, verifiedAttendees, verificationRate
}