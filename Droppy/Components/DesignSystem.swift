import SwiftUI

extension Color {
    static let charcoalBackground = Color("DSCharcoalBackground")
    static let darkGraySurface = Color("DSDarkGraySurface")
    static let ivoryAccent = Color("DSIvoryAccent")
    static let offWhiteText = Color("DSOffWhiteText")
    static let lightGraySecondary = Color("DSLightGraySecondary")
    static let systemSuccess = Color("DSSystemSuccess")
    static let systemError = Color("DSSystemError")
}

extension Font {
    static func oswald(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .custom("Oswald", size: size).weight(weight)
    }
    
    static let displayTitle = Font.oswald(48, weight: .medium)
    static let title1 = Font.oswald(34)
    static let title2 = Font.oswald(28)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
}

struct CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
}

struct Spacing {
    static let xs: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}