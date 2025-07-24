import Foundation

struct WelcomeFeature {
    let title: String
    let description: String
    let iconName: String
    
    static let defaultFeatures = [
        WelcomeFeature(
            title: "Fotoğraf Çek",
            description: "Kıyafetlerinizi çekin, AI analiz etsin",
            iconName: "camera"
        ),
        WelcomeFeature(
            title: "Akıllı Öneriler",
            description: "Hava durumu ve planınıza göre kombin önerileri",
            iconName: "wand.and.rays"
        ),
        WelcomeFeature(
            title: "Kişisel Stil",
            description: "Tarzınızı öğrenir, size özel öneriler sunar",
            iconName: "heart"
        )
    ]
}

enum WelcomeAction {
    case getStarted
    case signIn
}