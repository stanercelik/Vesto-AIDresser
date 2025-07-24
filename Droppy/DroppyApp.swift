//
//  DroppyApp.swift
//  Droppy
//
//  Created by Taner Çelik on 24.07.2025.
//

import SwiftUI

@main
struct DroppyApp: App {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authManager)
        }
    }
}

struct AppRootView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        ZStack {
            if authManager.isLoading {
                LoadingView()
            } else {
                switch authManager.authenticationState {
                case .unauthenticated:
                    WelcomeView()
                case .onboardingRequired(let user):
                    StylePreferencesView(user: user)
                case .authenticated(let user):
                    MainAppView(user: user)
                }
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accent))
                    .scaleEffect(1.2)
                
                Text("Yükleniyor...")
                    .font(.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
        }
    }
}

struct MainAppView: View {
    let user: User
    
    var body: some View {
        TabView {
            WardrobeView(
                client: SupabaseConfig.shared.client,
                userId: user.id
            )
            .tabItem {
                Image(systemName: "tshirt.fill")
                Text("Dolabım")
            }
            
            // Placeholder for future outfit recommendation view
            Text("Yakında")
                .font(.title)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Öneriler")
                }
            
            // Placeholder for profile view
            ProfileView(user: user)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
        }
        .accentColor(DesignSystem.Colors.accent)
    }
}

struct ProfileView: View {
    let user: User
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(DesignSystem.Colors.accent)
                    
                    Text(user.email)
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                
                Spacer()
                
                PrimaryButton(
                    "Çıkış Yap",
                    isLoading: false
                ) {
                    Task {
                        await authManager.signOut()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.Colors.background)
            .navigationTitle("Profil")
        }
    }
}
