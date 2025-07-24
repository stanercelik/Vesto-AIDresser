import Foundation

@MainActor
final class StylePreferencesViewModel: ObservableObject {
    @Published internal(set) var state = StylePreferencesState()
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let authService: AuthenticationServiceProtocol
    private let userId: UUID
    
    private enum L10n {
        static let screenTitle = "Tarzını Keşfedelim"
        static let continueButton = "Devam Et"
        static let completeButton = "Tamamla"
        static let backButton = "Geri"
        static let savingError = "Tercihler kaydedilirken hata oluştu"
    }
    
    init(authService: AuthenticationServiceProtocol, userId: UUID) {
        self.authService = authService
        self.userId = userId
    }
    
    var screenTitle: String { L10n.screenTitle }
    var currentStepDescription: String { state.currentStep.title }
    var currentOptions: [String] { state.currentStep.options }
    var primaryButtonTitle: String { state.isLastStep ? L10n.completeButton : L10n.continueButton }
    var showBackButton: Bool { state.canGoBack }
    var isFormValid: Bool { state.hasMinimumSelections }
    var progressSteps: Int { PreferenceStep.allCases.count }
    var currentStepIndex: Int { state.currentStep.rawValue }
    
    func isSelected(_ option: String) -> Bool {
        state.isSelected(option)
    }
    
    func toggleSelection(_ option: String) {
        state.toggleSelection(option)
    }
    
    func goToNextStep() {
        guard !state.isLastStep else { return }
        
        if let nextStep = PreferenceStep(rawValue: state.currentStep.rawValue + 1) {
            state.currentStep = nextStep
        }
    }
    
    func goToPreviousStep() {
        guard state.canGoBack else { return }
        
        if let previousStep = PreferenceStep(rawValue: state.currentStep.rawValue - 1) {
            state.currentStep = previousStep
        }
    }
    
    func savePreferencesAndComplete() async -> Bool {
        guard state.isLastStep && state.hasMinimumSelections else { return false }
        
        isLoading = true
        errorMessage = nil
        
        let preferences = state.toStylePreferences()
        
        do {
            try await authService.saveStylePreferences(preferences, for: userId)
            try await authService.completeOnboarding(for: userId)
            isLoading = false
            return true
        } catch {
            errorMessage = L10n.savingError
            isLoading = false
            return false
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}