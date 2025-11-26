package georesto

import (
	"testing"
	"time" // time.Sleep is not available in Gno
)

func TestRateLimiting(t *testing.T) {
	auth := NewAuthManager()
	user := "g1user123"
	action := "test_action"
	cooldown := int64(5) // 5 seconds

	// First call should succeed
	if !auth.CheckRateLimit(user, action, cooldown) {
		t.Error("First call should not be rate-limited")
	}

	// Immediate second call should fail
	if auth.CheckRateLimit(user, action, cooldown) {
		t.Error("Second call should be rate-limited")
	}

	// NOTE: We cannot test the cooldown expiration in the Gno test environment
	// because `time.Sleep` is not available and we cannot manipulate the block timestamp.
}

func TestAdminPermissions(t *testing.T) {
	auth := NewAuthManager()
	admin := address("g1admin")
	user := address("g1user")
	verifier := "g1verifier"

	// Initially, no admins
	if auth.IsAdmin(admin.String()) {
		t.Error("Should not be admin initially")
	}

	// Add admin (first one doesn't require an existing admin)
	auth.AddAdmin(admin.String(), address(""))
	if !auth.IsAdmin(admin.String()) {
		t.Fatal("Failed to add first admin")
	}

	// Non-admin cannot add verifier
	if auth.AddTrustedVerifier(verifier, user) {
		t.Error("Non-admin should not be able to add verifier")
	}

	// Admin can add verifier
	if !auth.AddTrustedVerifier(verifier, admin) {
		t.Error("Admin should be able to add verifier")
	}
	if !auth.IsTrustedVerifier(verifier) {
		t.Error("Failed to verify trusted verifier")
	}
}

func TestAccessToken(t *testing.T) {
	auth := NewAuthManager()
	user := "g1user123"
	currentTime := time.Now().Unix()
	expirationTime := currentTime + 3600 // 1 hour

	// Generate a token
	token := auth.GenerateAccessToken(user, expirationTime)
	if len(token) != 64 {
		t.Fatal("Generated token has incorrect length")
	}

	// Verify the valid token
	if !auth.VerifyAccessToken(token, user, currentTime) {
		t.Error("Valid token should be verified")
	}

	// Verify an invalid token
	if auth.VerifyAccessToken("invalidtoken", user, currentTime) {
		t.Error("Invalid token should not be verified")
	}

	// Verify an expired token
	expiredTime := currentTime + 3601
	if auth.VerifyAccessToken(token, user, expiredTime) {
		t.Error("Expired token should not be verified")
	}
}

func TestLocationProof(t *testing.T) {
	auth := NewAuthManager()
	user := "g1user123"
	locationID := "loc_1"
	timestamp := time.Now().Unix()

	// Generate a valid challenge
	challenge := auth.GenerateLocationChallenge(locationID)

	// The proof is the challenge itself in this implementation
	proof := challenge

	// Verify the valid proof
	if !auth.VerifyLocationProof(user, locationID, proof, timestamp) {
		t.Error("Valid location proof should be verified")
	}

	// Verify an invalid proof
	if auth.VerifyLocationProof(user, locationID, "invalidproof", timestamp) {
		t.Error("Invalid location proof should not be verified")
	}
}
