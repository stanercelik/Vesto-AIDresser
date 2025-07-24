import Foundation
@testable import Droppy

enum StylePreferencesTestDataFactory {
    static func createMockStylePreferences(
        favoriteColors: [String] = ["Mavi", "Siyah"],
        preferredStyles: [String] = ["Casual", "Şık"],
        occasionTypes: [String] = ["İş", "Günlük"]
    ) -> StylePreferences {
        return StylePreferences(
            favoriteColors: favoriteColors,
            preferredStyles: preferredStyles,
            occasionTypes: occasionTypes
        )
    }
    
    static func createEmptyStylePreferences() -> StylePreferences {
        return StylePreferences()
    }
    
    static func createStylePreferencesState(
        currentStep: PreferenceStep = .colors,
        selectedColors: Set<String> = [],
        selectedStyles: Set<String> = [],
        selectedOccasions: Set<String> = []
    ) -> StylePreferencesState {
        var state = StylePreferencesState()
        state.currentStep = currentStep
        state.selectedColors = selectedColors
        state.selectedStyles = selectedStyles
        state.selectedOccasions = selectedOccasions
        return state
    }
    
    static func createFilledStylePreferencesState() -> StylePreferencesState {
        return createStylePreferencesState(
            currentStep: .occasions,
            selectedColors: ["Mavi", "Siyah"],
            selectedStyles: ["Casual"],
            selectedOccasions: ["İş"]
        )
    }
    
    static func createMockAuthenticationService() -> MockAuthenticationService {
        return MockAuthenticationService()
    }
}