import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    private let authManager: AuthenticationManager
    private let onAuthenticationComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(authManager: AuthenticationManager, onAuthenticationComplete: @escaping () -> Void = {}) {
        self.authManager = authManager
        self._viewModel = StateObject(wrappedValue: AuthenticationViewModel(authManager: authManager))
        self.onAuthenticationComplete = onAuthenticationComplete
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.charcoalBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        headerSection
                        
                        CardView {
                            authenticationForm
                        }
                        
                        if let errorMessage = viewModel.errorMessage {
                            errorView(errorMessage)
                        }
                        
                        actionButtons
                        
                        Spacer(minLength: Spacing.large)
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.top, Spacing.xl)
                }
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationBarHidden(true)
        }
        .onChange(of: viewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                onAuthenticationComplete()
                dismiss()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: Spacing.medium) {
            Button("×") {
                HapticFeedback.impact(.light)
                dismiss()
            }
            .font(.title)
            .foregroundColor(.lightGraySecondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text(viewModel.screenTitle)
                .font(.title1)
                .foregroundColor(.offWhiteText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var authenticationForm: some View {
        VStack(spacing: Spacing.large) {
            VStack(spacing: Spacing.medium) {
                CustomTextField(
                    "Email",
                    text: $viewModel.email,
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    "Şifre",
                    text: $viewModel.password,
                    isSecure: true
                )
            }
            
            if viewModel.showPasswordHint {
                passwordRequirementsView
            }
        }
    }
    
    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Şifre gereksinimleri:")
                .font(.caption)
                .foregroundColor(.lightGraySecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading)
            ], alignment: .leading, spacing: Spacing.xs) {
                ForEach(Array(viewModel.getPasswordRequirements().enumerated()), id: \.offset) { index, requirement in
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(requirement.isMet ? .ivoryAccent : .lightGraySecondary)
                            .font(.caption)
                        
                        Text(requirement.text)
                            .font(.caption)
                            .foregroundColor(requirement.isMet ? .ivoryAccent : .lightGraySecondary)
                    }
                }
            }
        }
        .padding(.top, Spacing.xs)
    }
    
    private func errorView(_ message: String) -> some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.systemError)
            
            Text(message)
                .font(.body)
                .foregroundColor(.systemError)
            
            Spacer()
            
            Button("×") {
                HapticFeedback.impact(.light)
                viewModel.clearError()
            }
            .font(.headline)
            .foregroundColor(.systemError)
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.systemError.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(Color.systemError.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.slide.combined(with: .opacity))
    }
    
    private var actionButtons: some View {
        VStack(spacing: Spacing.medium) {
            PrimaryButton(
                viewModel.primaryButtonTitle,
                isEnabled: viewModel.isFormValid,
                isLoading: viewModel.isLoading
            ) {
                Task {
                    switch viewModel.authenticationMode {
                    case .signIn:
                        await viewModel.signIn()
                    case .signUp:
                        await viewModel.signUp()
                    }
                }
            }
            
            Button(viewModel.switchModeButtonTitle) {
                HapticFeedback.impact(.light)
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.switchAuthenticationMode()
                }
            }
            .font(.body)
            .foregroundColor(.lightGraySecondary)
            
            if viewModel.showForgotPassword {
                Button("Şifremi unuttum") {
                    HapticFeedback.impact(.light)
                }
                .font(.caption)
                .foregroundColor(.lightGraySecondary)
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    AuthenticationView(authManager: AuthenticationManager())
}