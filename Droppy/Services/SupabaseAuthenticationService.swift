import Foundation
import Supabase

final class SupabaseAuthenticationService: AuthenticationServiceProtocol {
    
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseConfig.shared.client) {
        self.client = client
    }
    
    func signUp(email: String, password: String) async throws -> User {
        do {
            let session = try await client.auth.signUp(email: email, password: password)
            let user = User(
                id: session.user.id,
                email: session.user.email ?? "",
                isOnboardingCompleted: false
            )
            await logAuthenticationEvent(userId: user.id, eventType: "sign_up", success: true)
            return user
        } catch {
            await logAuthenticationEvent(userId: nil, eventType: "sign_up", success: false, errorMessage: error.localizedDescription)
            throw mapError(error)
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            let profile = try await getProfile(userId: session.user.id)
            let user = User(
                id: session.user.id,
                email: session.user.email ?? "",
                isOnboardingCompleted: profile?.isOnboardingCompleted ?? false
            )
            await logAuthenticationEvent(userId: user.id, eventType: "sign_in", success: true)
            return user
        } catch {
            await logAuthenticationEvent(userId: nil, eventType: "sign_in", success: false, errorMessage: error.localizedDescription)
            throw mapError(error)
        }
    }
    
    func signOut() async throws {
        let userId = try? await client.auth.session.user.id
        do {
            try await client.auth.signOut()
            await logAuthenticationEvent(userId: userId, eventType: "sign_out", success: true)
        } catch {
            await logAuthenticationEvent(userId: userId, eventType: "sign_out", success: false, errorMessage: error.localizedDescription)
            throw mapError(error)
        }
    }
    
    func getCurrentUser() async -> User? {
        guard let sessionUser = try? await client.auth.session.user else {
            return nil
        }
        
        let profile = try? await getProfile(userId: sessionUser.id)
        return User(
            id: sessionUser.id,
            email: sessionUser.email ?? "",
            isOnboardingCompleted: profile?.isOnboardingCompleted ?? false
        )
    }
    
    func getAccessToken() async throws -> String? {
        try await client.auth.session.accessToken
    }
    
    func saveStylePreferences(_ preferences: StylePreferences, for userId: UUID) async throws {
        let profileUpdate = ProfileUpdate(
            userId: userId,
            favoriteColors: preferences.favoriteColors,
            preferredStyles: preferences.preferredStyles,
            occasionTypes: preferences.occasionTypes
        )
        do {
            try await client
                .from("profiles")
                .update(profileUpdate)
                .eq("id", value: userId)
                .execute()
        } catch {
            throw mapError(error)
        }
    }
    
    func completeOnboarding(for userId: UUID) async throws {
        let profileUpdate = ProfileUpdate(userId: userId, isOnboardingCompleted: true)
        do {
            try await client
                .from("profiles")
                .update(profileUpdate)
                .eq("id", value: userId)
                .execute()
        } catch {
            throw mapError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func getProfile(userId: UUID) async throws -> Profile? {
        do {
            let response: [Profile] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value
            return response.first
        } catch {
            throw mapError(error)
        }
    }
    
    private func mapError(_ error: Error) -> AuthenticationError {
        if let authError = error as? AuthError {
            // Handle specific AuthError cases if the library provides them.
            // For now, we inspect the localized description for common messages.
            // This is less robust than switching on enum cases, but works as a fallback.
            let description = authError.localizedDescription.lowercased()
            if description.contains("user already exists") || description.contains("422") {
                return .emailAlreadyExists
            }
            if description.contains("invalid login credentials") || description.contains("400") {
                return .userNotFound
            }
        }
        return .networkError
    }
    
    private func logAuthenticationEvent(userId: UUID?, eventType: String, success: Bool, errorMessage: String? = nil) async {
        let logMessage = "Auth Event: \(eventType), User: \(userId?.uuidString ?? "N/A"), Success: \(success), Error: \(errorMessage ?? "None")"
        print(logMessage)
        
        guard let userId = userId else { return }
        
        let log = AuthLog(
            userId: userId,
            eventType: eventType,
            success: success,
            errorMessage: errorMessage,
            ipAddress: "unknown", // Placeholder
            userAgent: "Droppy iOS App"
        )
        
        do {
            try await client.from("auth_logs").insert(log).execute()
        } catch {
            print("Failed to log auth event to Supabase: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Structs
    
    private struct Profile: Codable {
        let id: UUID
        let isOnboardingCompleted: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case isOnboardingCompleted = "is_onboarding_completed"
        }
    }
    
    private struct ProfileUpdate: Encodable {
        let userId: UUID
        var favoriteColors: [String]? = nil
        var preferredStyles: [String]? = nil
        var occasionTypes: [String]? = nil
        var isOnboardingCompleted: Bool? = nil
        
        enum CodingKeys: String, CodingKey {
            case userId = "id"
            case favoriteColors = "favorite_colors"
            case preferredStyles = "preferred_styles"
            case occasionTypes = "occasion_types"
            case isOnboardingCompleted = "is_onboarding_completed"
        }
    }
    
    private struct AuthLog: Encodable {
        let userId: UUID
        let eventType: String
        let success: Bool
        let errorMessage: String?
        let ipAddress: String
        let userAgent: String
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case eventType = "event_type"
            case success
            case errorMessage = "error_message"
            case ipAddress = "ip_address"
            case userAgent = "user_agent"
        }
    }
}