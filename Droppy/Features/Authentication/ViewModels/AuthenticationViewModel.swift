import Foundation

@MainActor
final class AuthenticationViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentUser: User?
    @Published private(set) var authenticationMode: AuthenticationMode = .signIn
    
    private let authService: AuthenticationServiceProtocol
    
    private enum L10n {
        static let signInTitle = "Giriş Yap"
        static let signUpTitle = "Hesap Oluştur"
        static let emailPlaceholder = "Email"
        static let passwordPlaceholder = "Şifre"
        static let signInButton = "Giriş Yap"
        static let signUpButton = "Hesap Oluştur"
        static let switchToSignUp = "Hesap oluştur"
        static let switchToSignIn = "Zaten hesabım var"
        static let forgotPassword = "Şifremi unuttum"
        static let passwordHint = "Şifreniz en az 6 karakter olmalıdır"
        static let emptyFieldsError = "Email ve şifre alanları boş olamaz"
        static let invalidEmailError = "Geçersiz email formatı"
        static let shortPasswordError = "Şifre gereksinimlerini karşılamıyor"
        static let unexpectedError = "Beklenmeyen bir hata oluştu"
        static let signOutError = "Çıkış yapılırken hata oluştu"
        static let onboardingError = "Onboarding tamamlanırken hata oluştu"
        static let preferencesError = "Stil tercihleri kaydedilirken hata oluştu"
    }
    
    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
        self.currentUser = authService.getCurrentUser()
    }
    
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    var shouldShowOnboarding: Bool {
        guard let user = currentUser else { return false }
        return !user.isOnboardingCompleted
    }
    
    var isFormValid: Bool {
        isValidEmail(email) && isValidPassword(password)
    }
    
    var screenTitle: String {
        authenticationMode == .signIn ? L10n.signInTitle : L10n.signUpTitle
    }
    
    var primaryButtonTitle: String {
        authenticationMode == .signIn ? L10n.signInButton : L10n.signUpButton
    }
    
    var switchModeButtonTitle: String {
        authenticationMode == .signIn ? L10n.switchToSignUp : L10n.switchToSignIn
    }
    
    var showPasswordHint: Bool {
        authenticationMode == .signUp
    }
    
    var showForgotPassword: Bool {
        authenticationMode == .signIn
    }
    
    func signIn() async {
        guard validateForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await authService.signIn(email: email, password: password)
        } catch let error as AuthenticationError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = L10n.unexpectedError
        }
        
        isLoading = false
    }
    
    func signUp() async {
        guard validateForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await authService.signUp(email: email, password: password)
        } catch let error as AuthenticationError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = L10n.unexpectedError
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await authService.signOut()
            currentUser = nil
            email = ""
            password = ""
            errorMessage = nil
        } catch {
            errorMessage = L10n.signOutError
        }
    }
    
    func completeOnboarding() async {
        guard let user = currentUser else { return }
        
        do {
            try await authService.completeOnboarding(for: user.id)
            currentUser = User(id: user.id, email: user.email, isOnboardingCompleted: true)
        } catch {
            errorMessage = L10n.onboardingError
        }
    }
    
    func saveStylePreferences(_ preferences: StylePreferences) async {
        guard let user = currentUser else { return }
        
        do {
            try await authService.saveStylePreferences(preferences, for: user.id)
        } catch {
            errorMessage = L10n.preferencesError
        }
    }
    
    func switchAuthenticationMode() {
        authenticationMode = authenticationMode == .signIn ? .signUp : .signIn
        clearError()
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    private func validateForm() -> Bool {
        if email.isEmpty || password.isEmpty {
            errorMessage = L10n.emptyFieldsError
            return false
        }
        
        if !isValidEmail(email) {
            errorMessage = L10n.invalidEmailError
            return false
        }
        
        if !isValidPassword(password) {
            errorMessage = L10n.shortPasswordError
            return false
        }
        
        return true
    }
    
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
    
    // MARK: - Password Requirements
    
    struct PasswordRequirement {
        let text: String
        let isMet: Bool
    }
    
    func getPasswordRequirements() -> [PasswordRequirement] {
        return [
            PasswordRequirement(text: "En az 6 karakter", isMet: password.count >= 6),
            PasswordRequirement(text: "Büyük harf (A-Z)", isMet: password.rangeOfCharacter(from: .uppercaseLetters) != nil),
            PasswordRequirement(text: "Küçük harf (a-z)", isMet: password.rangeOfCharacter(from: .lowercaseLetters) != nil),
            PasswordRequirement(text: "Sayı (0-9)", isMet: password.rangeOfCharacter(from: .decimalDigits) != nil),
            PasswordRequirement(text: "Özel karakter (!@#$...)", isMet: password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil)
        ]
    }
}