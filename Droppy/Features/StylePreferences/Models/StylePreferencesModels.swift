import Foundation

struct StylePreferences: Codable, Equatable {
    let favoriteColors: [String]
    let preferredStyles: [String]
    let occasionTypes: [String]
    
    init(favoriteColors: [String] = [], preferredStyles: [String] = [], occasionTypes: [String] = []) {
        self.favoriteColors = favoriteColors
        self.preferredStyles = preferredStyles
        self.occasionTypes = occasionTypes
    }
    
    var isEmpty: Bool {
        favoriteColors.isEmpty && preferredStyles.isEmpty && occasionTypes.isEmpty
    }
}

enum PreferenceStep: Int, CaseIterable {
    case colors = 0
    case styles = 1
    case occasions = 2
    
    var title: String {
        switch self {
        case .colors:
            return "En çok tercih ettiğin renkleri seç"
        case .styles:
            return "Hangi tarzları seviyorsun?"
        case .occasions:
            return "Hangi durumlar için kombin arıyorsun?"
        }
    }
    
    var options: [String] {
        switch self {
        case .colors:
            return ["Siyah", "Beyaz", "Mavi", "Kırmızı", "Yeşil", "Sarı", "Mor", "Turuncu", "Pembe", "Kahverengi", "Gri"]
        case .styles:
            return ["Casual", "Şık", "Spor", "Klasik", "Vintage", "Modern", "Bohem", "Minimal"]
        case .occasions:
            return ["İş", "Günlük", "Akşam", "Spor", "Tatil", "Özel Etkinlik", "Randevu"]
        }
    }
}

struct StylePreferencesState {
    var currentStep: PreferenceStep = .colors
    var selectedColors: Set<String> = []
    var selectedStyles: Set<String> = []
    var selectedOccasions: Set<String> = []
    
    var hasMinimumSelections: Bool {
        switch currentStep {
        case .colors:
            return selectedColors.count >= 1
        case .styles:
            return selectedStyles.count >= 1
        case .occasions:
            return selectedOccasions.count >= 1
        }
    }
    
    var isLastStep: Bool {
        currentStep == .occasions
    }
    
    var canGoBack: Bool {
        currentStep != .colors
    }
    
    func isSelected(_ option: String) -> Bool {
        switch currentStep {
        case .colors:
            return selectedColors.contains(option)
        case .styles:
            return selectedStyles.contains(option)
        case .occasions:
            return selectedOccasions.contains(option)
        }
    }
    
    mutating func toggleSelection(_ option: String) {
        switch currentStep {
        case .colors:
            if selectedColors.contains(option) {
                selectedColors.remove(option)
            } else {
                selectedColors.insert(option)
            }
        case .styles:
            if selectedStyles.contains(option) {
                selectedStyles.remove(option)
            } else {
                selectedStyles.insert(option)
            }
        case .occasions:
            if selectedOccasions.contains(option) {
                selectedOccasions.remove(option)
            } else {
                selectedOccasions.insert(option)
            }
        }
    }
    
    func toStylePreferences() -> StylePreferences {
        return StylePreferences(
            favoriteColors: Array(selectedColors),
            preferredStyles: Array(selectedStyles),
            occasionTypes: Array(selectedOccasions)
        )
    }
}