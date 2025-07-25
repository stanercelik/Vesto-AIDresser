//
//  WardrobeTestDataFactory.swift
//  DroppyTests
//
//  Created by Taner Çelik on 25.07.2025.
//

import Foundation
@testable import Droppy

enum WardrobeTestDataFactory {
    
    static func createMockClothingItem(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        imageUrl: String = "https://example.com/image.jpg",
        originalImageUrl: String? = nil,
        description: String? = "Mavi V yaka pamuklu tişört",
        category: ClothingCategory? = .tshirt,
        color: String? = "Mavi",
        secondaryColors: [String]? = nil,
        style: StyleType? = .casual,
        occasionTypes: [OccasionType]? = [.casual, .shopping],
        weatherSuitability: [WeatherSuitability]? = [.warm, .hot],
        fabricType: String? = "Pamuk",
        texture: String? = "Düz",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> ClothingItem {
        return ClothingItem(
            id: id,
            userId: userId,
            imageUrl: imageUrl,
            originalImageUrl: originalImageUrl,
            description: description,
            category: category,
            color: color,
            secondaryColors: secondaryColors,
            style: style,
            occasionTypes: occasionTypes,
            weatherSuitability: weatherSuitability,
            fabricType: fabricType,
            texture: texture,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    static func createMockWorkShirt() -> ClothingItem {
        return createMockClothingItem(
            description: "Beyaz klasik iş gömlegi",
            category: .shirt,
            color: "Beyaz",
            style: .classic,
            occasionTypes: [.work, .formal, .meeting],
            weatherSuitability: [.cool, .warm],
            fabricType: "Pamuk",
            texture: "Düz"
        )
    }
    
    static func createMockCasualJeans() -> ClothingItem {
        return createMockClothingItem(
            description: "Lacivert kot pantolon",
            category: .jeans,
            color: "Lacivert",
            style: .casual,
            occasionTypes: [.casual, .shopping, .travel],
            weatherSuitability: [.cool, .warm],
            fabricType: "Denim",
            texture: "Düz"
        )
    }
    
    static func createMockEveningDress() -> ClothingItem {
        return createMockClothingItem(
            description: "Siyah şık akşam elbisesi",
            category: .dress,
            color: "Siyah",
            style: .elegant,
            occasionTypes: [.evening, .party, .date],
            weatherSuitability: [.warm],
            fabricType: "Polyester",
            texture: "Saten"
        )
    }
    
    static func createMockSneakers() -> ClothingItem {
        return createMockClothingItem(
            description: "Beyaz spor ayakkabı",
            category: .sneakers,
            color: "Beyaz",
            style: .sporty,
            occasionTypes: [.casual, .sport, .travel],
            weatherSuitability: [.warm, .cool],
            fabricType: "Sentetik deri",
            texture: "Düz"
        )
    }
    
    static func createMockAnalysisResult(
        category: ClothingCategory? = .tshirt,
        mainColor: String? = "Mavi",
        secondaryColors: [String]? = ["Beyaz"],
        style: StyleType? = .casual,
        occasionTypes: [OccasionType]? = [.casual],
        weatherSuitability: [WeatherSuitability]? = [.warm],
        fabricType: String? = "Pamuk",
        texture: String? = "Düz",
        description: String? = "Test kıyafet"
    ) -> ClothingAnalysisResult {
        return ClothingAnalysisResult(
            category: category,
            mainColor: mainColor,
            secondaryColors: secondaryColors,
            style: style,
            occasionTypes: occasionTypes,
            weatherSuitability: weatherSuitability,
            fabricType: fabricType,
            texture: texture,
            description: description
        )
    }
}