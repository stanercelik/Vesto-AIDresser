import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: UUID
    let email: String
    let isOnboardingCompleted: Bool
    
    init(id: UUID = UUID(), email: String, isOnboardingCompleted: Bool = false) {
        self.id = id
        self.email = email
        self.isOnboardingCompleted = isOnboardingCompleted
    }
}

enum AuthenticationError: Error, Equatable {
    case invalidEmail
    case invalidPassword
    case userNotFound
    case emailAlreadyExists
    case networkError
    case unknownError
    case notAuthenticated
    
    var localizedDescription: String {
        switch self {
        case .invalidEmail:
            return "Geçersiz email formatı"
        case .invalidPassword:
            return "Geçersiz şifre"
        case .userNotFound:
            return "Kullanıcı bulunamadı"
        case .emailAlreadyExists:
            return "Bu email adresi zaten kullanılıyor"
        case .networkError:
            return "Bağlantı hatası. Lütfen tekrar deneyin."
        case .unknownError:
            return "Beklenmeyen bir hata oluştu"
        case .notAuthenticated:
            return "Kullanıcı oturumu bulunamadı veya geçersiz."
        }
    }
}

enum AuthenticationMode {
    case signIn
    case signUp
}