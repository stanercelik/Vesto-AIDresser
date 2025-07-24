import Foundation
import UIKit
import Supabase

protocol WardrobeServiceProtocol {
    func uploadClothingItem(
        imageData: Data,
        userId: UUID,
        options: ImageUploadOptions
    ) async throws -> ClothingItem
    
    func getUserClothingItems(userId: UUID) async throws -> [ClothingItem]
    func deleteClothingItem(itemId: UUID, userId: UUID) async throws
}

final class SupabaseWardrobeService: WardrobeServiceProtocol {
    private let client: SupabaseClient
    private let backgroundRemovalService: BackgroundRemovalServiceProtocol
    private let s3Service: S3ServiceProtocol
    
    private enum APIError: LocalizedError {
        case uploadFailed(String)
        case networkError(Error)
        case invalidResponse
        case unauthorized
        case dataDecodingFailed
        
        var errorDescription: String? {
            switch self {
            case .uploadFailed(let message): return "Yükleme başarısız: \(message)"
            case .networkError(let error): return "Ağ hatası: \(error.localizedDescription)"
            case .invalidResponse: return "Geçersiz yanıt alındı"
            case .unauthorized: return "Yetkilendirme hatası. Lütfen tekrar giriş yapın."
            case .dataDecodingFailed: return "Veri işlenemedi."
            }
        }
    }
    
    init(
        client: SupabaseClient = SupabaseConfig.shared.client,
        backgroundRemovalService: BackgroundRemovalServiceProtocol = ReplicateBackgroundRemovalService(),
        s3Service: S3ServiceProtocol = SupabaseS3Service()
    ) {
        self.client = client
        self.backgroundRemovalService = backgroundRemovalService
        self.s3Service = s3Service
    }
    
    func uploadClothingItem(
        imageData: Data,
        userId: UUID,
        options: ImageUploadOptions
    ) async throws -> ClothingItem {
        
        // Validate that user has a valid session
        do {
            let session = try await client.auth.session
            if session.user.id != userId {
                throw APIError.unauthorized
            }
        } catch {
            throw APIError.unauthorized
        }
        
        var processedImageData: Data = imageData
        var originalImageUrlString: String?
        
        let fileNameSuffix = UUID().uuidString
        
        if options.shouldRemoveBackground {
            let originalFileName = "original_\(fileNameSuffix).jpg"
            
            guard let tempURL = saveImageDataToTemporaryFile(imageData, fileName: originalFileName) else {
                throw APIError.uploadFailed("Could not save temporary file.")
            }
            
            defer {
                try? FileManager.default.removeItem(at: tempURL)
            }
            
            originalImageUrlString = try await uploadImageToS3(
                data: imageData,
                userId: userId,
                fileName: originalFileName,
                contentType: mimeType(for: imageData)
            )
            
            guard let originalImageUrl = URL(string: originalImageUrlString!) else {
                throw APIError.invalidResponse
            }
            
            processedImageData = try await backgroundRemovalService.removeBackground(from: originalImageUrl)
        }
        
        let finalFileName = "processed_\(fileNameSuffix).png"
        
        guard let finalTempURL = saveImageDataToTemporaryFile(processedImageData, fileName: finalFileName) else {
            throw APIError.uploadFailed("Could not save temporary file.")
        }
        
        defer {
            try? FileManager.default.removeItem(at: finalTempURL)
        }
        
        let finalImageUrl = try await uploadImageToS3(
            data: processedImageData,
            userId: userId,
            fileName: finalFileName,
            contentType: mimeType(for: processedImageData)
        )
        
        let clothingItem = ClothingItem(
            userId: userId,
            imageUrl: finalImageUrl,
            originalImageUrl: originalImageUrlString,
            category: options.category?.rawValue
        )
        
        return try await saveClothingItemToDatabase(clothingItem)
    }
    
    func getUserClothingItems(userId: UUID) async throws -> [ClothingItem] {
        do {
            let response: [ClothingItem] = try await client
                .from("clothing_items")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            return response
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func deleteClothingItem(itemId: UUID, userId: UUID) async throws {
        do {
            try await client
                .from("clothing_items")
                .delete()
                .eq("id", value: itemId)
                .eq("user_id", value: userId)
                .execute()
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func mimeType(for data: Data) -> String {
        var b: UInt8 = 0
        data.copyBytes(to: &b, count: 1)
        switch b {
        case 0xFF: return "image/jpeg"
        case 0x89: return "image/png"
        default: return "application/octet-stream"
        }
    }
    
    private func saveImageDataToTemporaryFile(_ data: Data, fileName: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving temporary file: \(error)")
            return nil
        }
    }
    
    private func uploadImageToS3(
        data: Data,
        userId: UUID,
        fileName: String,
        contentType: String
    ) async throws -> String {
        let s3Key = "\(userId)/\(fileName)"
        
        do {
            // Debug: Print S3 upload info
            print("Debug - S3 upload for user: \(userId)")
            print("Debug - S3 key: \(s3Key)")
            print("Debug - Data size: \(data.count) bytes")
            
            let publicURL = try await s3Service.uploadFile(
                data: data,
                key: s3Key,
                contentType: contentType
            )
            
            print("Debug - S3 upload successful: \(publicURL)")
            return publicURL
            
        } catch {
            print("Error uploading to S3: \(error)")
            throw APIError.uploadFailed(error.localizedDescription)
        }
    }
    
    private func saveClothingItemToDatabase(_ item: ClothingItem) async throws -> ClothingItem {
        do {
            // Debug: Print user info
            let session = try await client.auth.session
            print("Debug - Attempting to save item for user: \(item.userId)")
            print("Debug - Current session user: \(session.user.id)")
            print("Debug - Session expires at: \(Date(timeIntervalSince1970: session.expiresAt))")
            
            let response: [ClothingItem] = try await client
                .from("clothing_items")
                .insert(item, returning: .representation)
                .select()
                .execute()
                .value
            
            guard let savedItem = response.first else {
                throw APIError.dataDecodingFailed
            }
            return savedItem
        } catch {
            print("Debug - Database save error: \(error)")
            throw APIError.networkError(error)
        }
    }
}
