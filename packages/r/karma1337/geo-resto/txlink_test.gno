package georesto

import (
	"strings"
	"testing"
)

func TestGetAddLocationTxLink(t *testing.T) {
	link := GetAddLocationTxLink("Test Location", "A test", 48.8566, 2.3522, "restaurant")

	// Verify the link contains expected components
	if !strings.Contains(link, "$help&func=AddLocationStr") {
		t.Error("Link should contain function name AddLocationStr")
	}

	if !strings.Contains(link, "name=Test") {
		t.Error("Link should contain location name parameter")
	}

	if !strings.Contains(link, "latStr=48.8") {
		t.Error("Link should contain latStr parameter")
	}

	if !strings.Contains(link, "category=restaurant") {
		t.Error("Link should contain category parameter")
	}
}

func TestGetCheckInTxLink(t *testing.T) {
	locationID := "loc_123"
	proof := "test_proof"

	link := GetCheckInTxLink(locationID, proof)

	if !strings.Contains(link, "$help&func=CheckIn") {
		t.Error("Link should contain function name CheckIn")
	}

	if !strings.Contains(link, "locationID=loc_123") {
		t.Error("Link should contain locationID parameter")
	}

	if !strings.Contains(link, "proof=test_proof") {
		t.Error("Link should contain proof parameter")
	}
}

func TestGetCreateEventTxLink(t *testing.T) {
	link := GetCreateEventTxLink("loc_1", "Test Event", "Description", "pass123", 1, 1000, 2000)

	if !strings.Contains(link, "$help&func=CreateEventStr") {
		t.Error("Link should contain function name CreateEventStr")
	}

	if !strings.Contains(link, "locationID=loc_1") {
		t.Error("Link should contain locationID parameter")
	}

	if !strings.Contains(link, "name=Test") {
		t.Error("Link should contain event name parameter")
	}

	if !strings.Contains(link, "eventTypeStr=1") {
		t.Error("Link should contain eventTypeStr parameter")
	}

	if !strings.Contains(link, "startTimeStr=1000") {
		t.Error("Link should contain startTimeStr parameter")
	}
}

func TestGetJoinEventTxLink(t *testing.T) {
	eventID := "event_456"
	password := "secret"

	link := GetJoinEventTxLink(eventID, password)

	if !strings.Contains(link, "$help&func=JoinEvent") {
		t.Error("Link should contain function name JoinEvent")
	}

	if !strings.Contains(link, "eventID=event_456") {
		t.Error("Link should contain eventID parameter")
	}

	if !strings.Contains(link, "password=secret") {
		t.Error("Link should contain password parameter")
	}
}

func TestGetVerifyPresenceTxLink(t *testing.T) {
	eventID := "event_789"
	code := "verification123"
	attendee := "g1attendee"

	link := GetVerifyPresenceTxLink(eventID, code, attendee)

	if !strings.Contains(link, "$help&func=VerifyPresence") {
		t.Error("Link should contain function name VerifyPresence")
	}

	if !strings.Contains(link, "eventID=event_789") {
		t.Error("Link should contain eventID parameter")
	}

	if !strings.Contains(link, "verificationCode=verification123") {
		t.Error("Link should contain verificationCode parameter")
	}

	if !strings.Contains(link, "attendeeAddress=g1attendee") {
		t.Error("Link should contain attendeeAddress parameter")
	}
}

func TestTxLinkEmptyValues(t *testing.T) {
	// Test that empty values create user-editable fields in wallet
	link := GetJoinEventTxLink("event_1", "")

	if !strings.Contains(link, "$help&func=JoinEvent") {
		t.Error("Link should contain function name")
	}

	if !strings.Contains(link, "eventID=event_1") {
		t.Error("Link should contain eventID parameter")
	}

	// Empty password should still be in the URL as an empty parameter
	// This allows the wallet to prompt the user to fill it in
	if !strings.Contains(link, "password=") {
		t.Error("Link should contain password parameter (even if empty)")
	}
}
