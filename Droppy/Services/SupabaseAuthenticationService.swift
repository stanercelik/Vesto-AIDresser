import Foundation

// NOTE: Supabase Swift SDK should be added as a dependency
// For now, we'll use URLSession for direct API calls
final class SupabaseAuthenticationService: AuthenticationServiceProtocol {
    
    // MARK: - Configuration
    
    private let supabaseURL: String
    private let supabaseAnonKey: String
    
    // MARK: - Private Properties
    
    private var currentUser: User?
    
    // MARK: - Initialization
    
    init() {
        self.supabaseURL = SupabaseConfig.supabaseURL
        self.supabaseAnonKey = SupabaseConfig.supabaseAnonKey
        // Initialize Supabase client (will be implemented when we add the dependency)
    }
    
    // MARK: - AuthenticationServiceProtocol Implementation
    
    func signUp(email: String, password: String) async throws -> User {
        // Validate email format
        guard isValidEmail(email) else {
            await logAuthenticationEvent(userId: nil, eventType: "sign_up", success: false, errorMessage: "Invalid email format")
            throw AuthenticationError.invalidEmail
        }
        
        // Validate password strength
        guard isValidPassword(password) else {
            await logAuthenticationEvent(userId: nil, eventType: "sign_up", success: false, errorMessage: "Invalid password")
            throw AuthenticationError.invalidPassword
        }
        
        do {
            // TODO: Replace with actual Supabase authentication
            let user = try await performSignUp(email: email, password: password)
            
            // Log successful sign up
            await logAuthenticationEvent(userId: user.id, eventType: "sign_up", success: true, errorMessage: nil)
            
            self.currentUser = user
            return user
            
        } catch let error as AuthenticationError {
            await logAuthenticationEvent(userId: nil, eventType: "sign_up", success: false, errorMessage: error.localizedDescription)
            throw error
        } catch {
            await logAuthenticationEvent(userId: nil, eventType: "sign_up", success: false, errorMessage: error.localizedDescription)
            throw AuthenticationError.networkError
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        // Validate email format
        guard isValidEmail(email) else {
            await logAuthenticationEvent(userId: nil, eventType: "sign_in", success: false, errorMessage: "Invalid email format")
            throw AuthenticationError.invalidEmail
        }
        
        do {
            // TODO: Replace with actual Supabase authentication
            let user = try await performSignIn(email: email, password: password)
            
            // Log successful sign in
            await logAuthenticationEvent(userId: user.id, eventType: "sign_in", success: true, errorMessage: nil)
            
            self.currentUser = user
            return user
            
        } catch let error as AuthenticationError {
            await logAuthenticationEvent(userId: nil, eventType: "sign_in", success: false, errorMessage: error.localizedDescription)
            throw error
        } catch {
            await logAuthenticationEvent(userId: nil, eventType: "sign_in", success: false, errorMessage: error.localizedDescription)
            throw AuthenticationError.networkError
        }
    }
    
    func signOut() async throws {
        let userId = currentUser?.id
        
        do {
            // TODO: Replace with actual Supabase sign out
            try await performSignOut()
            
            // Log successful sign out
            if let userId = userId {
                await logAuthenticationEvent(userId: userId, eventType: "sign_out", success: true, errorMessage: nil)
            }
            
            self.currentUser = nil
            
        } catch {
            if let userId = userId {
                await logAuthenticationEvent(userId: userId, eventType: "sign_out", success: false, errorMessage: error.localizedDescription)
            }
            throw AuthenticationError.networkError
        }
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func saveStylePreferences(_ preferences: StylePreferences, for userId: UUID) async throws {
        do {
            // TODO: Replace with actual Supabase database update
            try await performSaveStylePreferences(preferences, for: userId)
        } catch {
            throw AuthenticationError.networkError
        }
    }
    
    func completeOnboarding(for userId: UUID) async throws {
        do {
            // TODO: Replace with actual Supabase database update
            try await performCompleteOnboarding(for: userId)
        } catch {
            throw AuthenticationError.networkError
        }
    }
    
    // MARK: - Private Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 6 else { return false }
        
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialCharacters = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
        
        return hasUppercase && hasLowercase && hasNumbers && hasSpecialCharacters
    }
    
    // MARK: - Real Supabase Implementation Methods
    
    private func performSignUp(email: String, password: String) async throws -> User {
        let url = URL(string: "\(supabaseURL)/auth/v1/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthenticationError.networkError
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let user = json?["user"] as? [String: Any],
                   let id = user["id"] as? String,
                   let email = user["email"] as? String {
                    return User(id: UUID(uuidString: id) ?? UUID(), email: email, isOnboardingCompleted: false)
                }
            } else if httpResponse.statusCode == 422 {
                // User already exists
                throw AuthenticationError.emailAlreadyExists
            }
            
            // Log the error response for debugging
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Supabase signup error: \(errorData)")
            }
            
            throw AuthenticationError.networkError
        } catch {
            if error is AuthenticationError {
                throw error
            }
            throw AuthenticationError.networkError
        }
    }
    
    private func performSignIn(email: String, password: String) async throws -> User {
        let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthenticationError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let user = json?["user"] as? [String: Any],
                   let id = user["id"] as? String,
                   let email = user["email"] as? String {
                    
                    // Get profile data
                    let profile = try await getProfile(userId: UUID(uuidString: id) ?? UUID())
                    
                    return User(id: UUID(uuidString: id) ?? UUID(), email: email, isOnboardingCompleted: profile?.isOnboardingCompleted ?? false)
                }
            } else if httpResponse.statusCode == 400 {
                throw AuthenticationError.userNotFound
            }
            
            // Log the error response for debugging
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Supabase signin error: \(errorData)")
            }
            
            throw AuthenticationError.networkError
        } catch {
            if error is AuthenticationError {
                throw error
            }
            throw AuthenticationError.networkError
        }
    }
    
    private func performSignOut() async throws {
        // For now, just clear the current user
        // In a full implementation, we'd call the Supabase logout endpoint
    }
    
    private func getProfile(userId: UUID) async throws -> (isOnboardingCompleted: Bool, favoriteColors: [String], preferredStyles: [String], occasionTypes: [String])? {
        let url = URL(string: "\(supabaseURL)/rest/v1/profiles?id=eq.\(userId.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let profile = json.first else {
            return nil
        }
        
        return (
            isOnboardingCompleted: profile["is_onboarding_completed"] as? Bool ?? false,
            favoriteColors: profile["favorite_colors"] as? [String] ?? [],
            preferredStyles: profile["preferred_styles"] as? [String] ?? [],
            occasionTypes: profile["occasion_types"] as? [String] ?? []
        )
    }
    
    private func performSaveStylePreferences(_ preferences: StylePreferences, for userId: UUID) async throws {
        let url = URL(string: "\(supabaseURL)/rest/v1/profiles?id=eq.\(userId.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body = [
            "favorite_colors": preferences.favoriteColors,
            "preferred_styles": preferences.preferredStyles,
            "occasion_types": preferences.occasionTypes
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw AuthenticationError.networkError
        }
    }
    
    private func performCompleteOnboarding(for userId: UUID) async throws {
        let url = URL(string: "\(supabaseURL)/rest/v1/profiles?id=eq.\(userId.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body = [
            "is_onboarding_completed": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw AuthenticationError.networkError
        }
    }
    
    // MARK: - Logging
    
    private func logAuthenticationEvent(userId: UUID?, eventType: String, success: Bool, errorMessage: String?) async {
        // Log to console for immediate debugging
        let logMessage = """
        Auth Event:
        - User ID: \(userId?.uuidString ?? "nil")
        - Event Type: \(eventType)
        - Success: \(success)
        - Error: \(errorMessage ?? "none")
        - Timestamp: \(Date())
        """
        print(logMessage)
        
        // Log to Supabase database
        await logToSupabase(userId: userId, eventType: eventType, success: success, errorMessage: errorMessage)
    }
    
    private func logToSupabase(userId: UUID?, eventType: String, success: Bool, errorMessage: String?) async {
        guard let userId = userId else { return }
        
        let url = URL(string: "\(supabaseURL)/rest/v1/auth_logs")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        
        let body = [
            "user_id": userId.uuidString,
            "event_type": eventType,
            "success": success,
            "error_message": errorMessage as Any,
            "ip_address": await getCurrentIPAddress(),
            "user_agent": "Droppy iOS App"
        ] as [String: Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 201 {
                    print("Failed to log auth event to Supabase: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("Error logging auth event to Supabase: \(error)")
        }
    }
    
    private func getCurrentIPAddress() async -> String {
        // In a real app, you might want to get the actual IP address
        // For now, we'll return a placeholder
        return "unknown"
    }
}