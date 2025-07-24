import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = WelcomeViewModel()
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.charcoalBackground
                    .ignoresSafeArea()
                
                VStack(spacing: Spacing.xl) {
                    Spacer()
                    
                    welcomeContent
                    
                    Spacer()
                    
                    actionButtons
                }
                .padding(.horizontal, Spacing.large)
            }
        }
        .sheet(isPresented: $viewModel.shouldShowAuthentication) {
            AuthenticationView(authService: authService) {
                viewModel.dismissAuthentication()
            }
        }
    }
    
    private var welcomeContent: some View {
        VStack(spacing: Spacing.large) {
            Text(viewModel.appTitle)
                .font(.displayTitle)
                .foregroundColor(.ivoryAccent)
                .multilineTextAlignment(.center)
            
            Text(viewModel.appSubtitle)
                .font(.title2)
                .foregroundColor(.offWhiteText)
                .multilineTextAlignment(.center)
            
            VStack(spacing: Spacing.medium) {
                ForEach(viewModel.features, id: \.title) { feature in
                    FeatureRow(feature: feature)
                }
            }
            .padding(.top, Spacing.large)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: Spacing.medium) {
            PrimaryButton(viewModel.getStartedButtonTitle) {
                viewModel.handleAction(.getStarted)
            }
            
            Button(viewModel.signInButtonTitle) {
                HapticFeedback.impact(.light)
                viewModel.handleAction(.signIn)
            }
            .font(.body)
            .foregroundColor(.lightGraySecondary)
        }
    }
}

struct FeatureRow: View {
    let feature: WelcomeFeature
    
    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: feature.iconName)
                .font(.title2)
                .foregroundColor(.ivoryAccent)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundColor(.offWhiteText)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.lightGraySecondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeView(authService: SupabaseAuthenticationService())
}
