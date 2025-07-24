import Foundation
@testable import Droppy

enum AuthenticationTestDataFactory {
    static func createMockUser(
        id: UUID = UUID(),
        email: String = "test@example.com",
        isOnboardingCompleted: Bool = false
    ) -> User {
        return User(id: id, email: email, isOnboardingCompleted: isOnboardingCompleted)
    }
    
    static func createValidEmailPassword() -> (email: String, password: String) {
        return ("test@example.com", "validpassword123.")
    }
    
    static func createInvalidEmailPassword() -> (email: String, password: String) {
        return ("invalid-email", "123")
    }
    
    static func createMockAuthenticationService() -> MockAuthenticationService {
        return MockAuthenticationService()
    }
}

class MockAuthenticationService: AuthenticationServiceProtocol {
    var signInResult: Result<User, AuthenticationError> = .success(AuthenticationTestDataFactory.createMockUser())
    var signUpResult: Result<User, AuthenticationError> = .success(AuthenticationTestDataFactory.createMockUser())
    var saveStylePreferencesResult: Result<Void, AuthenticationError> = .success(())
    var completeOnboardingResult: Result<Void, AuthenticationError> = .success(())
    
    var signInCalled = false
    var signUpCalled = false
    var saveStylePreferencesCalled = false
    var completeOnboardingCalled = false
    var savedPreferences: StylePreferences?
    var currentUser: User?
    
    func signIn(email: String, password: String) async throws -> User {
        signInCalled = true
        switch signInResult {
        case .success(let user):
            currentUser = user
            return user
        case .failure(let error):
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws -> User {
        signUpCalled = true
        switch signUpResult {
        case .success(let user):
            currentUser = user
            return user
        case .failure(let error):
            throw error
        }
    }
    
    func signOut() async throws {
        currentUser = nil
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func saveStylePreferences(_ preferences: StylePreferences, for userId: UUID) async throws {
        saveStylePreferencesCalled = true
        savedPreferences = preferences
        switch saveStylePreferencesResult {
        case .success():
            return
        case .failure(let error):
            throw error
        }
    }
    
    func completeOnboarding(for userId: UUID) async throws {
        completeOnboardingCalled = true
        switch completeOnboardingResult {
        case .success():
            currentUser = currentUser.map { User(id: $0.id, email: $0.email, isOnboardingCompleted: true) }
        case .failure(let error):
            throw error
        }
    }
}
