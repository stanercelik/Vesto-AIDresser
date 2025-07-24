//
//  AuthenticationManager.swift
//  Droppy
//
//  Created by Taner Çelik on 24.07.2025.
//

import Foundation
import SwiftUI

@MainActor
final class AuthenticationManager: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoading = true
    @Published private(set) var authenticationState: AuthenticationState = .unauthenticated
    
    let authService: AuthenticationServiceProtocol
    private let userDefaults = UserDefaults.standard
    
    private enum StorageKeys {
        static let userID = "droppy_user_id"
        static let userEmail = "droppy_user_email"
        static let isOnboardingCompleted = "droppy_onboarding_completed"
        static let lastLoginDate = "droppy_last_login"
    }
    
    enum AuthenticationState {
        case unauthenticated
        case authenticated(User)
        case onboardingRequired(User)
        
        var isAuthenticated: Bool {
            switch self {
            case .authenticated, .onboardingRequired:
                return true
            case .unauthenticated:
                return false
            }
        }
        
        var needsOnboarding: Bool {
            switch self {
            case .onboardingRequired:
                return true
            case .authenticated, .unauthenticated:
                return false
            }
        }
    }
    
    init(authService: AuthenticationServiceProtocol = SupabaseAuthenticationService()) {
        self.authService = authService
        
        Task {
            await restoreAuthenticationState()
        }
    }
    
    func signUp(email: String, password: String) async throws {
        do {
            let user = try await authService.signUp(email: email, password: password)
            await updateAuthenticationState(with: user)
        } catch {
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let user = try await authService.signIn(email: email, password: password)
            await updateAuthenticationState(with: user)
        } catch {
            throw error
        }
    }
    
    func signOut() async {
        do {
            try await authService.signOut()
            await clearAuthenticationState()
        } catch {
            // Even if remote signout fails, clear local state
            await clearAuthenticationState()
        }
    }
    
    func completeOnboarding() async throws {
        guard let user = currentUser else { return }
        
        try await authService.completeOnboarding(for: user.id)
        
        let updatedUser = User(
            id: user.id,
            email: user.email,
            isOnboardingCompleted: true
        )
        
        await updateAuthenticationState(with: updatedUser)
    }
    
    func saveStylePreferences(_ preferences: StylePreferences) async throws {
        guard let user = currentUser else { return }
        
        try await authService.saveStylePreferences(preferences, for: user.id)
    }
    
    // MARK: - Private Methods
    
    private func updateAuthenticationState(with user: User) async {
        currentUser = user
        
        // Save to UserDefaults for persistence
        userDefaults.set(user.id.uuidString, forKey: StorageKeys.userID)
        userDefaults.set(user.email, forKey: StorageKeys.userEmail)
        userDefaults.set(user.isOnboardingCompleted, forKey: StorageKeys.isOnboardingCompleted)
        userDefaults.set(Date(), forKey: StorageKeys.lastLoginDate)
        
        // Update authentication state
        if user.isOnboardingCompleted {
            authenticationState = .authenticated(user)
        } else {
            authenticationState = .onboardingRequired(user)
        }
        
        isLoading = false
    }
    
    private func clearAuthenticationState() async {
        currentUser = nil
        authenticationState = .unauthenticated
        isLoading = false
        
        // Clear UserDefaults
        userDefaults.removeObject(forKey: StorageKeys.userID)
        userDefaults.removeObject(forKey: StorageKeys.userEmail)
        userDefaults.removeObject(forKey: StorageKeys.isOnboardingCompleted)
        userDefaults.removeObject(forKey: StorageKeys.lastLoginDate)
    }
    
    private func restoreAuthenticationState() async {
        defer { isLoading = false }
        
        // Check if we have stored user data
        guard let userIDString = userDefaults.string(forKey: StorageKeys.userID),
              let userID = UUID(uuidString: userIDString),
              let email = userDefaults.string(forKey: StorageKeys.userEmail) else {
            authenticationState = .unauthenticated
            return
        }
        
        // Check if the stored session is still valid (within 7 days)
        if let lastLoginDate = userDefaults.object(forKey: StorageKeys.lastLoginDate) as? Date {
            let daysSinceLastLogin = Calendar.current.dateComponents([.day], from: lastLoginDate, to: Date()).day ?? 0
            
            if daysSinceLastLogin > 7 {
                // Session expired, clear stored data
                await clearAuthenticationState()
                return
            }
        }
        
        let isOnboardingCompleted = userDefaults.bool(forKey: StorageKeys.isOnboardingCompleted)
        
        let user = User(
            id: userID,
            email: email,
            isOnboardingCompleted: isOnboardingCompleted
        )
        
        currentUser = user
        
        // Update authentication state
        if user.isOnboardingCompleted {
            authenticationState = .authenticated(user)
        } else {
            authenticationState = .onboardingRequired(user)
        }
        
        // Optionally validate session with server
        await validateStoredSession(user: user)
    }
    
    private func validateStoredSession(user: User) async {
        do {
            // Try to get current user from Supabase to validate session
            let currentSupabaseUser = await authService.getCurrentUser()
            
            if currentSupabaseUser == nil || currentSupabaseUser?.id != user.id {
                // Session is invalid, clear stored state
                await clearAuthenticationState()
            }
        } catch {
            // Session validation failed, clear stored state
            await clearAuthenticationState()
        }
    }
}