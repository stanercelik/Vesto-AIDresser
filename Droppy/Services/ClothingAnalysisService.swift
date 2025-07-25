//
//  ClothingAnalysisService.swift
//  Droppy
//
//  Created by Taner Çelik on 25.07.2025.
//

import Foundation
import UIKit
import GoogleGenerativeAI

protocol ClothingAnalysisServiceProtocol {
    func analyzeClothing(image: UIImage) async throws -> ClothingAnalysisResult
}

struct ClothingAnalysisResult {
    let category: ClothingCategory?
    let mainColor: String?
    let secondaryColors: [String]?
    let style: StyleType?
    let occasionTypes: [OccasionType]?
    let weatherSuitability: [WeatherSuitability]?
    let fabricType: String?
    let texture: String?
    let description: String?
}

final class ClothingAnalysisService: ClothingAnalysisServiceProtocol {
    private let model: GenerativeModel
    
    init() {
        self.model = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: AppConfiguration.GeminiAPIKey
        )
    }
    
    func analyzeClothing(image: UIImage) async throws -> ClothingAnalysisResult {
        let prompt = createAnalysisPrompt()
        
        let response = try await model.generateContent(prompt, image)
        
        guard let text = response.text else {
            throw ClothingAnalysisError.invalidResponse
        }
        
        return try parseAnalysisResponse(text)
    }
}

// MARK: - Private Methods
private extension ClothingAnalysisService {
    func createAnalysisPrompt() -> String {
        return """
        Bu kıyafeti analiz et ve sonucu JSON formatında ver. Türkçe terimler kullan.
        
        JSON format:
        {
            "category": "Tişört|Gömlek|Pantolon|Etek|Elbise|Mont|vb",
            "mainColor": "Ana renk",
            "secondaryColors": ["Yan renkler listesi"],
            "style": "Minimalist|Klasik|Trend|Bohem|Sportif|Şık|Rahat|Vintage|Preppy|Cesur",
            "occasionTypes": ["İş|Günlük|Resmi|Spor|Akşam|Plaj|Seyahat|Randevu|Parti|Toplantı|Düğün|Alışveriş"],
            "weatherSuitability": ["Sıcak|Ilık|Serin|Soğuk|Yağmurlu|Karlı|Rüzgarlı"],
            "fabricType": "Pamuk, polyester, denim vb",
            "texture": "Düz, çizgili, desenli vb",
            "description": "Kısa açıklama"
        }
        
        Sadece JSON formatında cevap ver, başka metin ekleme.
        """
    }
    
    func parseAnalysisResponse(_ response: String) throws -> ClothingAnalysisResult {
        let cleanedResponse = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedResponse.data(using: .utf8) else {
            throw ClothingAnalysisError.invalidResponse
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return try parseJSON(json)
        } catch {
            throw ClothingAnalysisError.parsingFailed(error)
        }
    }
    
    func parseJSON(_ json: [String: Any]?) throws -> ClothingAnalysisResult {
        guard let json = json else {
            throw ClothingAnalysisError.invalidJSON
        }
        
        let category = parseCategory(json["category"] as? String)
        let mainColor = json["mainColor"] as? String
        let secondaryColors = json["secondaryColors"] as? [String]
        let style = parseStyle(json["style"] as? String)
        let occasionTypes = parseOccasionTypes(json["occasionTypes"] as? [String])
        let weatherSuitability = parseWeatherSuitability(json["weatherSuitability"] as? [String])
        let fabricType = json["fabricType"] as? String
        let texture = json["texture"] as? String
        let description = json["description"] as? String
        
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
    
    func parseCategory(_ categoryString: String?) -> ClothingCategory? {
        guard let categoryString = categoryString else { return nil }
        
        // Direct match with enum raw values
        if let category = ClothingCategory(rawValue: categoryString) {
            return category
        }
        
        // Fuzzy matching for common variations
        let lowercased = categoryString.lowercased()
        switch lowercased {
        case let str where str.contains("tişört") || str.contains("t-shirt"):
            return .tshirt
        case let str where str.contains("gömlek") || str.contains("shirt"):
            return .shirt
        case let str where str.contains("pantolon") || str.contains("jean"):
            return categoryString.lowercased().contains("kot") ? .jeans : .trousers
        case let str where str.contains("etek"):
            return .skirt
        case let str where str.contains("elbise"):
            return .dress
        case let str where str.contains("mont") || str.contains("ceket"):
            return .jacket
        case let str where str.contains("ayakkabı"):
            return .sneakers
        default:
            return nil
        }
    }
    
    func parseStyle(_ styleString: String?) -> StyleType? {
        guard let styleString = styleString else { return nil }
        return StyleType(rawValue: styleString)
    }
    
    func parseOccasionTypes(_ occasionStrings: [String]?) -> [OccasionType]? {
        guard let occasionStrings = occasionStrings else { return nil }
        return occasionStrings.compactMap { OccasionType(rawValue: $0) }
    }
    
    func parseWeatherSuitability(_ weatherStrings: [String]?) -> [WeatherSuitability]? {
        guard let weatherStrings = weatherStrings else { return nil }
        return weatherStrings.compactMap { WeatherSuitability(rawValue: $0) }
    }
}

// MARK: - Error Types
enum ClothingAnalysisError: Error, LocalizedError {
    case invalidResponse
    case parsingFailed(Error)
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "AI'dan geçersiz yanıt alındı"
        case .parsingFailed(let error):
            return "Yanıt ayrıştırılamadı: \(error.localizedDescription)"
        case .invalidJSON:
            return "Geçersiz JSON formatı"
        }
    }
}