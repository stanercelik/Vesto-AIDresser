//
//  DroppyApp.swift
//  Droppy
//
//  Created by Taner Çelik on 24.07.2025.
//

import SwiftUI

@main
struct DroppyApp: App {
    private let authService: AuthenticationServiceProtocol = SupabaseAuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            AppRootView(authService: authService)
        }
    }
}

struct AppRootView: View {
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
    }
    
    var body: some View {
        WelcomeView(authService: authService)
    }
}
