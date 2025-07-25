//
//  WardrobeViewModel.swift
//  Droppy
//
//  Created by Taner Çelik on 24.07.2025.
//

import Foundation
import SwiftUI
import UIKit
import Supabase

@MainActor
final class WardrobeViewModel: ObservableObject {
    @Published private(set) var clothingItems: [ClothingItem] = []
    @Published private(set) var uploadState: UploadState = .idle
    @Published private(set) var errorMessage: String?
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var showingActionSheet = false
    @Published var selectedImage: UIImage?
    @Published var isSelectionMode = false
    @Published var selectedItems: Set<UUID> = []
    @Published var selectedItemForNavigation: UUID? = nil
    
    private let wardrobeService: WardrobeServiceProtocol
    private let userId: UUID
    
    private enum L10n {
        static let uploadSuccess = "Kıyafet başarıyla eklendi!"
        static let uploadError = "Kıyafet yüklenirken hata oluştu"
        static let deleteSuccess = "Kıyafet başarıyla silindi"
        static let deleteError = "Kıyafet silinirken hata oluştu"
        static let loadError = "Kıyafetler yüklenirken hata oluştu"
        static let processingImage = "Görüntü işleniyor..."
        static let uploadingImage = "Görüntü yükleniyor..."
    }
    
    init(client: SupabaseClient, userId: UUID) {
        self.wardrobeService = SupabaseWardrobeService(client: client)
        self.userId = userId
    }
    
    func loadClothingItems() async {
        do {
            let items = try await wardrobeService.getUserClothingItems(userId: userId)
            clothingItems = items
        } catch {
            errorMessage = L10n.loadError
            print("Error loading clothing items: \(error.localizedDescription)")
        }
    }
    
    func showImageSourceOptions() {
        showingActionSheet = true
    }
    
    func selectFromLibrary() {
        showingImagePicker = true
    }
    
    func takePhoto() {
        showingCamera = true
    }
    
    func uploadSelectedImage(with options: ImageUploadOptions = ImageUploadOptions()) async {
        guard let image = selectedImage else { return }
        
        // Start with much smaller dimensions for network compatibility
        let resizedImage = resizeImageIfNeeded(image, maxDimension: 600)
        
        // Very aggressive size limit - 200KB max
        let maxSizeInBytes = 200 * 1024 // 200KB
        
        // Start with very low compression quality
        guard var imageData = resizedImage.jpegData(compressionQuality: 0.2) else {
            uploadState = .failed("Görüntü verisi hazırlanamadı")
            errorMessage = "Görüntü verisi hazırlanamadı"
            return
        }
        
        // Progressive compression until we get under the strict limit
        var compressionQuality: CGFloat = 0.2
        
        while imageData.count > maxSizeInBytes && compressionQuality > 0.05 {
            compressionQuality -= 0.02
            
            guard let compressedData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
                break
            }
            imageData = compressedData
        }
        
        // If still too large, try even smaller dimensions
        if imageData.count > maxSizeInBytes {
            let tinyImage = resizeImageIfNeeded(image, maxDimension: 400)
            
            compressionQuality = 0.1
            while compressionQuality > 0.05 {
                guard let finalData = tinyImage.jpegData(compressionQuality: compressionQuality) else {
                    break
                }
                
                if finalData.count <= maxSizeInBytes {
                    imageData = finalData
                    break
                }
                
                compressionQuality -= 0.01
            }
            
            if imageData.count > maxSizeInBytes {
                uploadState = .failed("Görüntü çok büyük")
                errorMessage = "Görüntü çok büyük. Lütfen daha basit bir görüntü seçin."
                return
            }
        }
        
        let finalImageData = imageData
        
        print("Debug - Image data size: \(finalImageData.count / 1024) KB")
        
        do {
            let uploadedItem = try await wardrobeService.uploadClothingItem(
                imageData: finalImageData,
                userId: userId,
                options: options,
                progressCallback: { [weak self] state in
                    self?.uploadState = state
                }
            )
            
            clothingItems.insert(uploadedItem, at: 0)
            uploadState = .completed
            selectedImage = nil
            
            await showSuccessFeedback()
            
        } catch {
            uploadState = .failed(error.localizedDescription)
            errorMessage = "\(L10n.uploadError): \(error.localizedDescription)"
            print("Error uploading clothing item: \(error)")
        }
    }
    
    func deleteClothingItem(_ item: ClothingItem) async {
        do {
            try await wardrobeService.deleteClothingItem(itemId: item.id, userId: userId)
            clothingItems.removeAll { $0.id == item.id }
            await showSuccessFeedback()
        } catch {
            errorMessage = L10n.deleteError
            print("Error deleting clothing item: \(error.localizedDescription)")
        }
    }
    
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedItems.removeAll()
        }
    }
    
    func toggleItemSelection(_ itemId: UUID) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }
    
    func navigateToDetail(itemId: UUID) {
        selectedItemForNavigation = itemId
    }
    
    func deleteSelectedItems() async {
        let itemsToDelete = clothingItems.filter { selectedItems.contains($0.id) }
        
        for item in itemsToDelete {
            do {
                try await wardrobeService.deleteClothingItem(itemId: item.id, userId: userId)
                clothingItems.removeAll { $0.id == item.id }
            } catch {
                errorMessage = L10n.deleteError
                print("Error deleting clothing item: \(error.localizedDescription)")
                return
            }
        }
        
        selectedItems.removeAll()
        isSelectionMode = false
        await showSuccessFeedback()
    }
    
    func dismissError() {
        errorMessage = nil
        if case .failed = uploadState {
            uploadState = .idle
        }
    }
    
    private func showSuccessFeedback() async {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        uploadState = .idle
    }
    
    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // If image is already smaller than max dimension, return original
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Create resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
}
