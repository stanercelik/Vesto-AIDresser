//
//  BackgroundRemovalService.swift
//  Droppy
//
//  Created by Taner Çelik on 24.07.2025.
//

import Foundation
import UIKit

protocol BackgroundRemovalServiceProtocol {
    func removeBackground(from imageUrl: URL) async throws -> Data
}

final class ReplicateBackgroundRemovalService: BackgroundRemovalServiceProtocol {
    private let apiToken: String
    private let baseURL = "https://api.replicate.com/v1"
    
    private enum APIError: LocalizedError {
        case invalidResponse
        case processingFailed(String)
        case networkError(Error)
        case invalidImageData
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Geçersiz API yanıtı alındı"
            case .processingFailed(let message):
                return "Arka plan kaldırma işlemi başarısız: \(message)"
            case .networkError(let error):
                return "Ağ hatası: \(error.localizedDescription)"
            case .invalidImageData:
                return "Geçersiz görüntü verisi"
            }
        }
    }
    
    init() {
        self.apiToken = SupabaseConfig.shared.replicateAPIToken
    }
    
    func removeBackground(from imageUrl: URL) async throws -> Data {
        // Create prediction
        let predictionURL = URL(string: "\(baseURL)/predictions")!
        var request = URLRequest(url: predictionURL)
        request.httpMethod = "POST"
        request.addValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "version": "fb8af171cfa1616ddcf1242c093f9c46bcada5ad4cf6f2fbe8b81b330ec5c003",
            "input": [
                "image": imageUrl.absoluteString
            ]
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let predictionId = json["id"] as? String else {
                throw APIError.invalidResponse
            }
            
            // Poll for completion
            return try await pollForCompletion(predictionId: predictionId)
            
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    private func pollForCompletion(predictionId: String) async throws -> Data {
        let pollURL = URL(string: "\(baseURL)/predictions/\(predictionId)")!
        var request = URLRequest(url: pollURL)
        request.addValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")
        
        for attempt in 0..<60 { // Poll for up to 2 minutes (60 * 2 seconds)
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let status = json["status"] as? String else {
                    throw APIError.invalidResponse
                }
                
                switch status {
                case "succeeded":
                    guard let output = json["output"] as? String,
                          let outputURL = URL(string: output) else {
                        throw APIError.invalidResponse
                    }
                    
                    // Download the processed image
                    let (imageData, _) = try await URLSession.shared.data(from: outputURL)
                    return imageData
                    
                case "failed", "canceled":
                    let error = json["error"] as? String ?? "Unknown error"
                    throw APIError.processingFailed(error)
                    
                case "starting", "processing":
                    // Adaptive polling: faster at start, slower later
                    let delay = attempt < 10 ? 1_000_000_000 : 2_000_000_000 // 2s then 3s
                    try await Task.sleep(nanoseconds: UInt64(delay))
                    continue
                    
                default:
                    throw APIError.invalidResponse
                }
                
            } catch {
                if error is APIError {
                    throw error
                } else {
                    throw APIError.networkError(error)
                }
            }
        }
        
        throw APIError.processingFailed("İşlem zaman aşımına uğradı")
    }
}
