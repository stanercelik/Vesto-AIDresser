//
//  WardrobeModels.swift
//  Droppy
//
//  Created by Taner Çelik on 24.07.2025.
//

import Foundation
import UIKit

struct ClothingItem: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let imageUrl: String
    let originalImageUrl: String?
    let description: String?
    let category: ClothingCategory?
    let color: String?
    let secondaryColors: [String]?
    let style: StyleType?
    let occasionTypes: [OccasionType]?
    let weatherSuitability: [WeatherSuitability]?
    let fabricType: String?
    let texture: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case imageUrl = "image_url"
        case originalImageUrl = "original_image_url"
        case description
        case category
        case color
        case secondaryColors = "secondary_colors"
        case style
        case occasionTypes = "occasion_types"
        case weatherSuitability = "weather_suitability"
        case fabricType = "fabric_type"
        case texture
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        imageUrl: String,
        originalImageUrl: String? = nil,
        description: String? = nil,
        category: ClothingCategory? = nil,
        color: String? = nil,
        secondaryColors: [String]? = nil,
        style: StyleType? = nil,
        occasionTypes: [OccasionType]? = nil,
        weatherSuitability: [WeatherSuitability]? = nil,
        fabricType: String? = nil,
        texture: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.imageUrl = imageUrl
        self.originalImageUrl = originalImageUrl
        self.description = description
        self.category = category
        self.color = color
        self.secondaryColors = secondaryColors
        self.style = style
        self.occasionTypes = occasionTypes
        self.weatherSuitability = weatherSuitability
        self.fabricType = fabricType
        self.texture = texture
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum ClothingCategory: String, CaseIterable, Codable {
    // Üst Vücut
    case tshirt = "Tişört"
    case shirt = "Gömlek"
    case polo = "Polo"
    case sweater = "Kazak"
    case hoodie = "Kapüşonlu"
    case blazer = "Ceket"
    case cardigan = "Hırka"
    case tank = "Atlet"
    case blouse = "Bluz"
    
    // Alt Vücut
    case jeans = "Kot Pantolon"
    case trousers = "Kumaş Pantolon"
    case shorts = "Şort"
    case skirt = "Etek"
    case leggings = "Tayt"
    
    // Tek Parça
    case dress = "Elbise"
    case jumpsuit = "Tulum"
    case romper = "Şort Tulum"
    
    // Dış Giyim
    case coat = "Palto"
    case jacket = "Mont"
    case vest = "Yelek"
    case kimono = "Kimono"
    
    // Ayakkabı
    case sneakers = "Spor Ayakkabı"
    case dressShoes = "Klasik Ayakkabı"
    case boots = "Bot"
    case sandals = "Sandalet"
    case heels = "Topuklu"
    case flats = "Babet"
    
    // Aksesuar
    case bag = "Çanta"
    case hat = "Şapka"
    case scarf = "Atkı"
    case belt = "Kemer"
    case jewelry = "Takı"
    case glasses = "Gözlük"
    
    var localizedName: String {
        return self.rawValue
    }
    
    var categoryGroup: CategoryGroup {
        switch self {
        case .tshirt, .shirt, .polo, .sweater, .hoodie, .blazer, .cardigan, .tank, .blouse:
            return .tops
        case .jeans, .trousers, .shorts, .skirt, .leggings:
            return .bottoms
        case .dress, .jumpsuit, .romper:
            return .onepiece
        case .coat, .jacket, .vest, .kimono:
            return .outerwear
        case .sneakers, .dressShoes, .boots, .sandals, .heels, .flats:
            return .shoes
        case .bag, .hat, .scarf, .belt, .jewelry, .glasses:
            return .accessories
        }
    }
}

enum CategoryGroup: String, CaseIterable {
    case tops = "Üst Giyim"
    case bottoms = "Alt Giyim"
    case onepiece = "Tek Parça"
    case outerwear = "Dış Giyim"
    case shoes = "Ayakkabı"
    case accessories = "Aksesuar"
}

enum StyleType: String, CaseIterable, Codable {
    case minimalist = "Minimalist"
    case classic = "Klasik"
    case trendy = "Trend"
    case bohemian = "Bohem"
    case sporty = "Sportif"
    case elegant = "Şık"
    case casual = "Rahat"
    case vintage = "Vintage"
    case preppy = "Preppy"
    case edgy = "Cesur"
    
    var localizedName: String {
        return self.rawValue
    }
}

enum OccasionType: String, CaseIterable, Codable {
    case work = "İş"
    case casual = "Günlük"
    case formal = "Resmi"
    case sport = "Spor"
    case evening = "Akşam"
    case beach = "Plaj"
    case travel = "Seyahat"
    case date = "Randevu"
    case party = "Parti"
    case meeting = "Toplantı"
    case wedding = "Düğün"
    case shopping = "Alışveriş"
    
    var localizedName: String {
        return self.rawValue
    }
}

enum WeatherSuitability: String, CaseIterable, Codable {
    case hot = "Sıcak"      // 25°C+
    case warm = "Ilık"      // 15-25°C
    case cool = "Serin"     // 5-15°C
    case cold = "Soğuk"     // 5°C-
    case rainy = "Yağmurlu"
    case snowy = "Karlı"
    case windy = "Rüzgarlı"
    
    var localizedName: String {
        return self.rawValue
    }
    
    var temperatureRange: String {
        switch self {
        case .hot: return "25°C+"
        case .warm: return "15-25°C"
        case .cool: return "5-15°C"
        case .cold: return "5°C-"
        case .rainy: return "Yağmurlu"
        case .snowy: return "Karlı"
        case .windy: return "Rüzgarlı"
        }
    }
}

enum UploadState {
    case idle
    case selecting
    case uploading
    case processing
    case completed
    case failed(String)
    
    var isLoading: Bool {
        switch self {
        case .uploading, .processing:
            return true
        default:
            return false
        }
    }
}

struct ImageUploadOptions {
    let shouldRemoveBackground: Bool
    let category: ClothingCategory?
    
    init(shouldRemoveBackground: Bool = true, category: ClothingCategory? = nil) {
        self.shouldRemoveBackground = shouldRemoveBackground
        self.category = category
    }
}