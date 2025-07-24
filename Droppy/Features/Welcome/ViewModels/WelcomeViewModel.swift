import Foundation

@MainActor
final class WelcomeViewModel: ObservableObject {
    enum Action {
        case getStarted
        case signIn
    }
    @Published private(set) var features: [WelcomeFeature] = WelcomeFeature.defaultFeatures
    @Published var shouldShowAuthentication = false
    
    private let authService: AuthenticationServiceProtocol
    
    private enum L10n {
        static let appTitle = "Stil Pusulası"
        static let appSubtitle = "AI destekli gardırop asistanınız"
        static let getStartedButton = "Başlayalım"
        static let signInButton = "Zaten hesabım var"
    }
    
    var appTitle: String { L10n.appTitle }
    var appSubtitle: String { L10n.appSubtitle }
    var getStartedButtonTitle: String { L10n.getStartedButton }
    var signInButtonTitle: String { L10n.signInButton }
    
    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
    }
    
    func handleAction(_ action: Action) {
        switch action {
        case .getStarted, .signIn:
            shouldShowAuthentication = true
        }
    }
    
    func dismissAuthentication() {
        shouldShowAuthentication = false
    }
}