import Foundation

protocol AuthenticationServiceProtocol {
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String) async throws -> User
    func signOut() async throws
    func getCurrentUser() -> User?
    func saveStylePreferences(_ preferences: StylePreferences, for userId: UUID) async throws
    func completeOnboarding(for userId: UUID) async throws
}