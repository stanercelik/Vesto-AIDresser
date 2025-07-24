import Foundation

@MainActor
final class WelcomeViewModel: ObservableObject {
    @Published private(set) var features: [WelcomeFeature] = WelcomeFeature.defaultFeatures
    @Published var shouldShowAuthentication = false
    
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
    
    func handleAction(_ action: WelcomeAction) {
        switch action {
        case .getStarted, .signIn:
            shouldShowAuthentication = true
        }
    }
    
    func dismissAuthentication() {
        shouldShowAuthentication = false
    }
}