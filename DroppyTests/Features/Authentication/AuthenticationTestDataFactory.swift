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
    
    
}
