import Foundation
import UIKit
import Supabase

protocol WardrobeServiceProtocol {
    func uploadClothingItem(
        imageData: Data,
        userId: UUID,
        options: ImageUploadOptions,
        progressCallback: @escaping (UploadState) -> Void
    ) async throws -> ClothingItem
    
    func getUserClothingItems(userId: UUID) async throws -> [ClothingItem]
    func deleteClothingItem(itemId: UUID, userId: UUID) async throws
}

final class SupabaseWardrobeService: WardrobeServiceProtocol {
    private let client: SupabaseClient
    private let backgroundRemovalService: BackgroundRemovalServiceProtocol
    private let s3Service: S3ServiceProtocol
    private let clothingAnalysisService: ClothingAnalysisServiceProtocol
    
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
        s3Service: S3ServiceProtocol = SupabaseS3Service(),
        clothingAnalysisService: ClothingAnalysisServiceProtocol = ClothingAnalysisService()
    ) {
        self.client = client
        self.backgroundRemovalService = backgroundRemovalService
        self.s3Service = s3Service
        self.clothingAnalysisService = clothingAnalysisService
    }
    
    func uploadClothingItem(
        imageData: Data,
        userId: UUID,
        options: ImageUploadOptions,
        progressCallback: @escaping (UploadState) -> Void
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
        
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // milliseconds
        let fileNameSuffix = "\(UUID().uuidString)_\(timestamp)"
        
        if options.shouldRemoveBackground {
            // Stage 1: Upload original image (0-25%)
            await MainActor.run { progressCallback(.uploadingOriginal(progress: 0.0)) }
            
            let originalFileName = "original_\(fileNameSuffix).jpg"
            
            guard let tempURL = saveImageDataToTemporaryFile(imageData, fileName: originalFileName) else {
                throw APIError.uploadFailed("Could not save temporary file.")
            }
            
            defer {
                try? FileManager.default.removeItem(at: tempURL)
            }
            
            await MainActor.run { progressCallback(.uploadingOriginal(progress: 0.5)) }
            
            originalImageUrlString = try await uploadImageToS3(
                data: imageData,
                userId: userId,
                fileName: originalFileName,
                contentType: mimeType(for: imageData)
            )
            
            await MainActor.run { progressCallback(.uploadingOriginal(progress: 1.0)) }
            
            guard let originalImageUrl = URL(string: originalImageUrlString!) else {
                throw APIError.invalidResponse
            }
            
            // Stage 2: Remove background (25-50%)
            await MainActor.run { progressCallback(.removingBackground(progress: 0.0)) }
            
            processedImageData = try await backgroundRemovalService.removeBackground(from: originalImageUrl)
            
            await MainActor.run { progressCallback(.removingBackground(progress: 1.0)) }
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
        
        // Stage 3: Analyze clothing with AI (50-75%)
        await MainActor.run { progressCallback(.analyzingClothing(progress: 0.0)) }
        
        var analysisResult: ClothingAnalysisResult?
        do {
            guard let image = UIImage(data: processedImageData) else {
                throw APIError.uploadFailed("Could not create image from processed data")
            }
            
            await MainActor.run { progressCallback(.analyzingClothing(progress: 0.5)) }
            
            analysisResult = try await clothingAnalysisService.analyzeClothing(image: image)
            
            await MainActor.run { progressCallback(.analyzingClothing(progress: 1.0)) }
        } catch {
            print("Warning: AI analysis failed, saving without analysis: \(error)")
        }
        
        // Stage 4: Save to database (75-100%)
        await MainActor.run { progressCallback(.savingToDatabase(progress: 0.0)) }
        
        let clothingItem = ClothingItem(
            userId: userId,
            imageUrl: finalImageUrl,
            originalImageUrl: originalImageUrlString,
            description: analysisResult?.description,
            category: analysisResult?.category ?? options.category,
            color: analysisResult?.mainColor,
            secondaryColors: analysisResult?.secondaryColors,
            style: analysisResult?.style,
            occasionTypes: analysisResult?.occasionTypes,
            weatherSuitability: analysisResult?.weatherSuitability,
            fabricType: analysisResult?.fabricType,
            texture: analysisResult?.texture
        )
        
        await MainActor.run { progressCallback(.savingToDatabase(progress: 0.5)) }
        
        let savedItem = try await saveClothingItemToDatabase(clothingItem)
        
        await MainActor.run { progressCallback(.savingToDatabase(progress: 1.0)) }
        
        return savedItem
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
        // First, get the item to find the image URLs
        let item: ClothingItem
        do {
            let response: [ClothingItem] = try await client
                .from("clothing_items")
                .select()
                .eq("id", value: itemId)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            guard let clothingItem = response.first else {
                throw APIError.invalidResponse
            }
            item = clothingItem
        } catch {
            throw APIError.networkError(error)
        }
        
        // Delete from database first
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
        
        // Delete images from storage
        do {
            // Delete processed image
            if let processedKey = extractS3KeyFromUrl(item.imageUrl, userId: userId) {
                try await s3Service.deleteFile(key: processedKey)
            }
            
            // Delete original image if exists
            if let originalImageUrl = item.originalImageUrl,
               let originalKey = extractS3KeyFromUrl(originalImageUrl, userId: userId) {
                try await s3Service.deleteFile(key: originalKey)
            }
        } catch {
            // Log the error but don't fail the entire operation
            // The database record is already deleted
            print("Warning: Failed to delete images from storage: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func extractS3KeyFromUrl(_ urlString: String, userId: UUID) -> String? {
        // URL format: https://knbnmcrkyjcbihqdabld.supabase.co/storage/v1/object/public/clothing-images/userId/filename
        let prefix = "https://knbnmcrkyjcbihqdabld.supabase.co/storage/v1/object/public/clothing-images/"
        
        guard urlString.hasPrefix(prefix) else {
            return nil
        }
        
        let keyPart = String(urlString.dropFirst(prefix.count))
        return keyPart
    }
    
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
