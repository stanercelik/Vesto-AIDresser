import Foundation
@testable import Droppy

enum WelcomeTestDataFactory {
    static func createMockWelcomeFeature(
        title: String = "Test Feature",
        description: String = "Test Description",
        iconName: String = "star"
    ) -> WelcomeFeature {
        return WelcomeFeature(title: title, description: description, iconName: iconName)
    }
    
    static func createDefaultFeatures() -> [WelcomeFeature] {
        return WelcomeFeature.defaultFeatures
    }
    
    @MainActor
    static func createWelcomeViewModel() -> WelcomeViewModel {
        return WelcomeViewModel()
    }
}