import SwiftUI

struct DesignSystem {
    struct Colors {
        static let background = Color(red: 0.1, green: 0.1, blue: 0.1)
        static let cardBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
        static let accent = Color(red: 0.96, green: 0.96, blue: 0.86)
        static let primaryText = Color(red: 0.95, green: 0.95, blue: 0.95)
        static let secondaryText = Color(red: 0.6, green: 0.6, blue: 0.6)
        static let success = Color.green
        static let error = Color.red
    }
    
    struct Fonts {
        static func oswald(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            return .custom("Oswald", size: size).weight(weight)
        }
        
        static let displayTitle = oswald(48, weight: .medium)
        static let title1 = oswald(34)
        static let title2 = oswald(28)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
    }
    
    struct Metrics {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 16
        
        static let spacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 24
        static let xlSpacing: CGFloat = 32
    }
}

// Keep extensions for backward compatibility
extension Color {
    static let charcoalBackground = DesignSystem.Colors.background
    static let darkGraySurface = DesignSystem.Colors.cardBackground
    static let ivoryAccent = DesignSystem.Colors.accent
    static let offWhiteText = DesignSystem.Colors.primaryText
    static let lightGraySecondary = DesignSystem.Colors.secondaryText
    static let systemSuccess = DesignSystem.Colors.success
    static let systemError = DesignSystem.Colors.error
}

extension Font {
    static func oswald(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return DesignSystem.Fonts.oswald(size, weight: weight)
    }
    
    static let displayTitle = DesignSystem.Fonts.displayTitle
    static let title1 = DesignSystem.Fonts.title1
    static let title2 = DesignSystem.Fonts.title2
}

struct CornerRadius {
    static let small = DesignSystem.Metrics.smallCornerRadius
    static let medium = DesignSystem.Metrics.cornerRadius
    static let large = DesignSystem.Metrics.largeCornerRadius
}

struct Spacing {
    static let xs: CGFloat = 4
    static let small = DesignSystem.Metrics.smallSpacing
    static let medium = DesignSystem.Metrics.spacing
    static let large = DesignSystem.Metrics.largeSpacing
    static let xl = DesignSystem.Metrics.xlSpacing
    static let xxl: CGFloat = 48
}
