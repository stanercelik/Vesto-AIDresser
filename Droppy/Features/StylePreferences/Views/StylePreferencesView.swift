import SwiftUI

struct StylePreferencesView: View {
    @StateObject private var viewModel: StylePreferencesViewModel
    private let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(authService: AuthenticationServiceProtocol, userId: UUID, onComplete: @escaping () -> Void = {}) {
        self._viewModel = StateObject(wrappedValue: StylePreferencesViewModel(authService: authService, userId: userId))
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.charcoalBackground
                    .ignoresSafeArea()
                
                VStack(spacing: Spacing.xl) {
                    headerSection
                    
                    progressIndicator
                    
                    contentSection
                    
                    Spacer()
                    
                    if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    }
                    
                    navigationButtons
                }
                .padding(.horizontal, Spacing.large)
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: Spacing.medium) {
            Text(viewModel.screenTitle)
                .font(.title1)
                .foregroundColor(.offWhiteText)
                .multilineTextAlignment(.center)
            
            Text(viewModel.currentStepDescription)
                .font(.body)
                .foregroundColor(.lightGraySecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var progressIndicator: some View {
        HStack(spacing: Spacing.small) {
            ForEach(0..<viewModel.progressSteps, id: \.self) { index in
                Circle()
                    .fill(index <= viewModel.currentStepIndex ? Color.ivoryAccent : Color.lightGraySecondary)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var contentSection: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.medium) {
                ForEach(viewModel.currentOptions, id: \.self) { option in
                    SelectionChip(
                        title: option,
                        isSelected: viewModel.isSelected(option),
                        action: { 
                            viewModel.toggleSelection(option)
                        }
                    )
                }
            }
            .padding(.top, Spacing.medium)
        }
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
    
    private var navigationButtons: some View {
        VStack(spacing: Spacing.medium) {
            PrimaryButton(
                viewModel.primaryButtonTitle,
                isEnabled: viewModel.isFormValid,
                isLoading: viewModel.isLoading
            ) {
                Task {
                    if viewModel.state.isLastStep {
                        let success = await viewModel.savePreferencesAndComplete()
                        if success {
                            HapticFeedback.notification(.success)
                            onComplete()
                            dismiss()
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.goToNextStep()
                        }
                    }
                }
            }
            
            if viewModel.showBackButton {
                Button("Geri") {
                    HapticFeedback.impact(.light)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.goToPreviousStep()
                    }
                }
                .font(.body)
                .foregroundColor(.lightGraySecondary)
            }
        }
        .padding(.bottom, Spacing.large)
    }
}

struct SelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            Text(title)
                .font(.body)
                .foregroundColor(isSelected ? .charcoalBackground : .offWhiteText)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(isSelected ? Color.ivoryAccent : Color.darkGraySurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.large)
                                .stroke(
                                    isSelected ? Color.clear : Color.lightGraySecondary.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .accessibilityLabel(title)
        .accessibilityHint(isSelected ? "Seçildi, dokunarak kaldır" : "Dokunarak seç")
    }
}

#Preview {
    StylePreferencesView(authService: SupabaseAuthenticationService(), userId: UUID())
}