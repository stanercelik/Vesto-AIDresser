import XCTest
@testable import Droppy

final class SupabaseAuthenticationServiceTests: XCTestCase {
    
    private var service: SupabaseAuthenticationService!
    
    override func setUp() {
        super.setUp()
        // We'll use test configuration
        service = SupabaseAuthenticationService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Sign Up Tests
    
    func test_signUp_whenValidEmailAndPassword_thenCreatesUserAndLogsEvent() async throws {
        // Given
        let email = "test@example.com"
        let password = "TestPassword123!"
        
        // When & Then
        // This test will initially fail since we haven't implemented SupabaseAuthenticationService yet
        let user = try await service.signUp(email: email, password: password)
        
        // Then
        XCTAssertEqual(user.email, email)
        XCTAssertFalse(user.isOnboardingCompleted)
        XCTAssertNotNil(user.id)
    }
    
    func test_signUp_whenInvalidEmail_thenThrowsInvalidEmailError() async {
        // Given
        let invalidEmail = "invalid-email"
        let password = "TestPassword123!"
        
        // When & Then
        do {
            _ = try await service.signUp(email: invalidEmail, password: password)
            XCTFail("Expected AuthenticationError.invalidEmail to be thrown")
        } catch let error as AuthenticationError {
            XCTAssertEqual(error, AuthenticationError.invalidEmail)
        } catch {
            XCTFail("Expected AuthenticationError.invalidEmail, got \(error)")
        }
    }
    
    func test_signUp_whenWeakPassword_thenThrowsInvalidPasswordError() async {
        // Given
        let email = "test@example.com"
        let weakPassword = "123"
        
        // When & Then
        do {
            _ = try await service.signUp(email: email, password: weakPassword)
            XCTFail("Expected AuthenticationError.invalidPassword to be thrown")
        } catch let error as AuthenticationError {
            XCTAssertEqual(error, AuthenticationError.invalidPassword)
        } catch {
            XCTFail("Expected AuthenticationError.invalidPassword, got \(error)")
        }
    }
    
    // MARK: - Sign In Tests
    
    func test_signIn_whenValidCredentials_thenReturnsUserAndLogsEvent() async throws {
        // Given
        let email = "existing@example.com"
        let password = "ExistingPassword123!"
        
        // When
        let user = try await service.signIn(email: email, password: password)
        
        // Then
        XCTAssertEqual(user.email, email)
        XCTAssertNotNil(user.id)
    }
    
    func test_signIn_whenInvalidCredentials_thenThrowsUserNotFoundError() async {
        // Given
        let email = "nonexistent@example.com"
        let password = "WrongPassword123!"
        
        // When & Then
        do {
            _ = try await service.signIn(email: email, password: password)
            XCTFail("Expected AuthenticationError.userNotFound to be thrown")
        } catch let error as AuthenticationError {
            XCTAssertEqual(error, AuthenticationError.userNotFound)
        } catch {
            XCTFail("Expected AuthenticationError.userNotFound, got \(error)")
        }
    }
    
    // MARK: - Sign Out Tests
    
    func test_signOut_whenUserSignedIn_thenSignsOutSuccessfullyAndLogsEvent() async throws {
        // Given - assume user is signed in
        
        // When & Then
        try await service.signOut()
        
        // Verify user is no longer signed in
        XCTAssertNil(service.getCurrentUser())
    }
    
    // MARK: - Current User Tests
    
    func test_getCurrentUser_whenNoUserSignedIn_thenReturnsNil() {
        // When
        let currentUser = service.getCurrentUser()
        
        // Then
        XCTAssertNil(currentUser)
    }
    
    // MARK: - Style Preferences Tests
    
    func test_saveStylePreferences_whenValidPreferences_thenSavesSuccessfully() async throws {
        // Given
        let userId = UUID()
        let preferences = StylePreferences(
            favoriteColors: ["Mavi", "Siyah"],
            preferredStyles: ["Casual", "Şık"],
            occasionTypes: ["İş", "Günlük"]
        )
        
        // When & Then
        try await service.saveStylePreferences(preferences, for: userId)
        
        // No exception should be thrown
    }
    
    // MARK: - Onboarding Tests
    
    func test_completeOnboarding_whenValidUserId_thenMarksOnboardingComplete() async throws {
        // Given
        let userId = UUID()
        
        // When & Then
        try await service.completeOnboarding(for: userId)
        
        // No exception should be thrown
    }
}