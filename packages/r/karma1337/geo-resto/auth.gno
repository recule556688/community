package georesto

import (
	"std"
	"crypto/sha256"
	"encoding/hex"
	"strconv"
	"strings"
	"time"
)

// AuthManager handles access control and proof verification
type AuthManager struct {
	trustedVerifiers map[string]bool // Trusted verifier addresses
	adminAddresses   map[string]bool // Admin addresses
}

// NewAuthManager creates a new authentication manager instance
func NewAuthManager() *AuthManager {
	return &AuthManager{
		trustedVerifiers: make(map[string]bool),
		adminAddresses:   make(map[string]bool),
	}
}

// AddTrustedVerifier adds a trusted verifier address
func (am *AuthManager) AddTrustedVerifier(verifierAddress string, admin std.Address) bool {
	if !am.IsAdmin(admin.String()) {
		return false
	}
	
	am.trustedVerifiers[verifierAddress] = true
	return true
}

// RemoveTrustedVerifier removes a trusted verifier address
func (am *AuthManager) RemoveTrustedVerifier(verifierAddress string, admin std.Address) bool {
	if !am.IsAdmin(admin.String()) {
		return false
	}
	
	delete(am.trustedVerifiers, verifierAddress)
	return true
}

// IsTrustedVerifier checks if an address is a trusted verifier
func (am *AuthManager) IsTrustedVerifier(address string) bool {
	return am.trustedVerifiers[address]
}

// AddAdmin adds an admin address
func (am *AuthManager) AddAdmin(adminAddress string, currentAdmin std.Address) bool {
	// Only existing admins can add new admins
	if len(am.adminAddresses) > 0 && !am.IsAdmin(currentAdmin.String()) {
		return false
	}
	
	am.adminAddresses[adminAddress] = true
	return true
}

// IsAdmin checks if an address is an admin
func (am *AuthManager) IsAdmin(address string) bool {
	return am.adminAddresses[address]
}

// VerifyLocationProof verifies a cryptographic proof for location check-in
func (am *AuthManager) VerifyLocationProof(userAddress, locationID, proof string, timestamp int64) bool {
	// Basic proof validation
	if len(proof) < 10 {
		return false
	}
	
	// In a real implementation, this would involve:
	// 1. GPS coordinate verification with tolerance
	// 2. Time-based proof validation
	// 3. Cryptographic signature verification
	// 4. QR code or beacon verification
	
	// For now, we implement a simple hash-based proof
	expectedProof := am.generateLocationProof(userAddress, locationID, timestamp)
	return strings.HasPrefix(proof, expectedProof[:8]) // Partial match for demo
}

// GenerateLocationProof generates a proof for location check-in
func (am *AuthManager) GenerateLocationProof(userAddress, locationID string, timestamp int64) string {
	return am.generateLocationProof(userAddress, locationID, timestamp)
}

// VerifyEventAccess verifies access to a password-protected event
func (am *AuthManager) VerifyEventAccess(eventID, password string, user std.Address) bool {
	event := eventManager.GetEvent(eventID)
	if event == nil {
		return false
	}
	
	// If no password required, access is granted
	if event.Password == "" {
		return true
	}
	
	// Verify password
	hashedPassword := am.hashString(password)
	return hashedPassword == event.Password
}

// CanModifyLocation checks if a user can modify a location
func (am *AuthManager) CanModifyLocation(locationID string, user std.Address) bool {
	location := locationManager.GetLocation(locationID)
	if location == nil {
		return false
	}
	
	userAddr := user.String()
	
	// Location creator can always modify
	if location.Creator.String() == userAddr {
		return true
	}
	
	// Admins can modify any location
	if am.IsAdmin(userAddr) {
		return true
	}
	
	// Trusted verifiers can modify for verification purposes
	if am.IsTrustedVerifier(userAddr) {
		return true
	}
	
	return false
}

// CanModifyEvent checks if a user can modify an event
func (am *AuthManager) CanModifyEvent(eventID string, user std.Address) bool {
	event := eventManager.GetEvent(eventID)
	if event == nil {
		return false
	}
	
	userAddr := user.String()
	
	// Event creator can always modify
	if event.Creator.String() == userAddr {
		return true
	}
	
	// Admins can modify any event
	if am.IsAdmin(userAddr) {
		return true
	}
	
	return false
}

// ValidateCoordinates validates GPS coordinates
func (am *AuthManager) ValidateCoordinates(latitude, longitude float64) bool {
	return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
}

// ValidateProximity checks if user is within acceptable range of location
func (am *AuthManager) ValidateProximity(userLat, userLon, locationLat, locationLon, maxDistanceKm float64) bool {
	// Simplified distance calculation (not precise for production)
	latDiff := userLat - locationLat
	lonDiff := userLon - locationLon
	distanceSquared := latDiff*latDiff + lonDiff*lonDiff
	
	// Rough conversion to kilometers (111 km per degree)
	roughDistanceKm := (distanceSquared * 111.0 * 111.0)
	maxDistanceSquared := maxDistanceKm * maxDistanceKm
	
	return roughDistanceKm <= maxDistanceSquared
}

// GenerateAccessToken generates a temporary access token for API access
func (am *AuthManager) GenerateAccessToken(userAddress string, expirationTime int64) string {
	data := userAddress + ":" + strconv.FormatInt(expirationTime, 10)
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])
}

// VerifyAccessToken verifies an access token
func (am *AuthManager) VerifyAccessToken(token, userAddress string, currentTime int64) bool {
	// In a real implementation, tokens would be stored with expiration times
	// For now, we just verify the format
	return len(token) == 64 // SHA256 hex string length
}

// CheckRateLimit implements basic rate limiting for API calls
func (am *AuthManager) CheckRateLimit(userAddress string, action string) bool {
	// In a real implementation, this would track API calls per user per time period
	// For now, we always allow the action
	return true
}

// Helper methods

func (am *AuthManager) generateLocationProof(userAddress, locationID string, timestamp int64) string {
	data := userAddress + ":" + locationID + ":" + strconv.FormatInt(timestamp, 10)
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])
}

func (am *AuthManager) hashString(input string) string {
	hash := sha256.Sum256([]byte(input))
	return hex.EncodeToString(hash[:])
}

// VerifyZKProof verifies a zero-knowledge proof (placeholder for future implementation)
func (am *AuthManager) VerifyZKProof(proof string, publicInputs []string) bool {
	// Placeholder for ZK proof verification
	// In a real implementation, this would verify a zk-SNARK or zk-STARK proof
	// allowing users to prove they were at a location without revealing exact coordinates
	return len(proof) > 0 && len(publicInputs) > 0
}

// GenerateLocationChallenge generates a challenge for location verification
func (am *AuthManager) GenerateLocationChallenge(locationID string) string {
	// Generate a time-based challenge that can be solved by someone physically present
	timestamp := time.Now().Unix()
	data := locationID + ":" + strconv.FormatInt(timestamp/300, 10) // 5-minute windows
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:8]) // Return first 8 bytes as challenge
}

// VerifyLocationChallenge verifies a location challenge response
func (am *AuthManager) VerifyLocationChallenge(locationID, response string) bool {
	// Check if response matches any of the last few time windows (for clock drift tolerance)
	currentTime := time.Now().Unix()
	
	for i := 0; i < 3; i++ { // Check current and previous 2 windows
		timeWindow := (currentTime / 300) - int64(i)
		data := locationID + ":" + strconv.FormatInt(timeWindow, 10)
		hash := sha256.Sum256([]byte(data))
		expectedResponse := hex.EncodeToString(hash[:8])
		
		if response == expectedResponse {
			return true
		}
	}
	
	return false
}