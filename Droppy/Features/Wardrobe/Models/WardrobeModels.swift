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
    let category: String?
    let color: String?
    let style: String?
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
        case style
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        imageUrl: String,
        originalImageUrl: String? = nil,
        description: String? = nil,
        category: String? = nil,
        color: String? = nil,
        style: String? = nil,
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
        self.style = style
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum ClothingCategory: String, CaseIterable {
    case top = "Üst"
    case bottom = "Alt"
    case dress = "Elbise"
    case outerwear = "Dış Giyim"
    case shoes = "Ayakkabı"
    case accessories = "Aksesuar"
    
    var localizedName: String {
        return self.rawValue
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