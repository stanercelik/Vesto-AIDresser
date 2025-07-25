//
//  SupabaseS3Service.swift
//  Droppy
//
//  Created by Taner Çelik on 24.07.2025.
//

import Foundation
import CryptoKit

protocol S3ServiceProtocol {
    func uploadFile(
        data: Data,
        key: String,
        contentType: String
    ) async throws -> String
    
    func deleteFile(key: String) async throws
}

final class SupabaseS3Service: S3ServiceProtocol {
    private let config = SupabaseConfig.shared
    
    private enum S3Error: LocalizedError {
        case uploadFailed(String)
        case invalidResponse
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .uploadFailed(let message): return "S3 Upload failed: \(message)"
            case .invalidResponse: return "Invalid S3 response"
            case .networkError(let error): return "S3 Network error: \(error.localizedDescription)"
            }
        }
    }
    
    func uploadFile(
        data: Data,
        key: String,
        contentType: String
    ) async throws -> String {
        
        return try await uploadFileWithRetry(data: data, key: key, contentType: contentType, attempt: 1)
    }
    
    private func uploadFileWithRetry(
        data: Data,
        key: String,
        contentType: String,
        attempt: Int
    ) async throws -> String {
        
        let finalKey = attempt > 1 ? "\(key)_retry\(attempt)" : key
        
        // Use Supabase S3 endpoint
        guard let url = URL(string: "\(config.s3Endpoint)/\(config.s3Bucket)/\(finalKey)") else {
            throw S3Error.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // Add AWS S3 signature v4 authentication
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let amzDate = dateFormatter.string(from: Date())
        
        let dateStamp = String(amzDate.prefix(8))
        
        let payloadHash = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        
        request.setValue(amzDate, forHTTPHeaderField: "x-amz-date")
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")
        
        // Create authorization header with signature
        let authorization = createAuthorizationHeader(
            method: "PUT",
            url: url,
            headers: [
                "host": url.host!,
                "x-amz-date": amzDate,
                "x-amz-content-sha256": payloadHash
            ],
            payload: data,
            dateStamp: dateStamp,
            amzDate: amzDate
        )
        
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        // Add cache control
        request.setValue("3600", forHTTPHeaderField: "Cache-Control")
        
        request.httpBody = data
        
        do {
            print("Debug - Making request to: \(url)")
            print("Debug - Content-Type: \(contentType)")
            print("Debug - Using S3 access key: \(config.s3AccessKeyId)")
            print("Debug - Method: PUT")
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw S3Error.invalidResponse
            }
            
            print("Debug - Response status: \(httpResponse.statusCode)")
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("Debug - Response body: \(responseString)")
            }
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                
                // Check for duplicate/conflict errors and retry
                if (httpResponse.statusCode == 409 || errorMessage.contains("already exists") || errorMessage.contains("duplicate")) && attempt < 3 {
                    print("Debug - File conflict detected, retrying with attempt \(attempt + 1)")
                    return try await uploadFileWithRetry(data: data, key: key, contentType: contentType, attempt: attempt + 1)
                }
                
                throw S3Error.uploadFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            // Return the public URL - use the final key that was actually uploaded
            let publicURL = "https://knbnmcrkyjcbihqdabld.supabase.co/storage/v1/object/public/\(config.s3Bucket)/\(finalKey)"
            return publicURL
            
        } catch let error as S3Error {
            throw error
        } catch {
            let nsError = error as NSError
            
            // Handle specific network errors that might indicate conflicts
            if nsError.code == 40 || nsError.localizedDescription.contains("Message too long") {
                if attempt < 3 {
                    print("Debug - Network conflict detected, retrying with attempt \(attempt + 1)")
                    // Add a small delay before retry
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    return try await uploadFileWithRetry(data: data, key: key, contentType: contentType, attempt: attempt + 1)
                }
            }
            
            throw S3Error.networkError(error)
        }
    }
    
    // MARK: - AWS S3 Signature V4
    
    private func createAuthorizationHeader(
        method: String,
        url: URL,
        headers: [String: String],
        payload: Data,
        dateStamp: String,
        amzDate: String
    ) -> String {
        
        let service = "s3"
        let region = config.s3Region
        let algorithm = "AWS4-HMAC-SHA256"
        
        // Step 1: Create canonical request
        let canonicalUri = url.path
        let canonicalQuerystring = ""
        
        let sortedHeaders = headers.sorted { $0.key < $1.key }
        let canonicalHeaders = sortedHeaders.map { "\($0.key):\($0.value)" }.joined(separator: "\n") + "\n"
        let signedHeaders = sortedHeaders.map { $0.key }.joined(separator: ";")
        
        let payloadHash = SHA256.hash(data: payload).compactMap { String(format: "%02x", $0) }.joined()
        
        let canonicalRequest = [
            method,
            canonicalUri,
            canonicalQuerystring,
            canonicalHeaders,
            signedHeaders,
            payloadHash
        ].joined(separator: "\n")
        
        // Step 2: Create string to sign
        let credentialScope = "\(dateStamp)/\(region)/\(service)/aws4_request"
        let stringToSign = [
            algorithm,
            amzDate,
            credentialScope,
            SHA256.hash(data: canonicalRequest.data(using: .utf8)!).compactMap { String(format: "%02x", $0) }.joined()
        ].joined(separator: "\n")
        
        // Step 3: Calculate signature
        let signature = calculateSignature(
            stringToSign: stringToSign,
            dateStamp: dateStamp,
            region: region,
            service: service
        )
        
        // Step 4: Create authorization header
        let authorizationHeader = "\(algorithm) Credential=\(config.s3AccessKeyId)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        
        return authorizationHeader
    }
    
    private func calculateSignature(
        stringToSign: String,
        dateStamp: String,
        region: String,
        service: String
    ) -> String {
        
        let kDate = hmacSHA256(key: "AWS4\(config.s3SecretAccessKey)".data(using: .utf8)!, data: dateStamp.data(using: .utf8)!)
        let kRegion = hmacSHA256(key: kDate, data: region.data(using: .utf8)!)
        let kService = hmacSHA256(key: kRegion, data: service.data(using: .utf8)!)
        let kSigning = hmacSHA256(key: kService, data: "aws4_request".data(using: .utf8)!)
        
        let signature = hmacSHA256(key: kSigning, data: stringToSign.data(using: .utf8)!)
        
        return signature.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func hmacSHA256(key: Data, data: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(authenticationCode)
    }
    
    func deleteFile(key: String) async throws {
        guard let url = URL(string: "\(config.s3Endpoint)/\(config.s3Bucket)/\(key)") else {
            throw S3Error.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Add AWS S3 signature v4 authentication for DELETE
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let amzDate = dateFormatter.string(from: Date())
        
        let dateStamp = String(amzDate.prefix(8))
        let emptyPayload = Data()
        let payloadHash = SHA256.hash(data: emptyPayload).compactMap { String(format: "%02x", $0) }.joined()
        
        request.setValue(amzDate, forHTTPHeaderField: "x-amz-date")
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")
        
        let authorization = createAuthorizationHeader(
            method: "DELETE",
            url: url,
            headers: [
                "host": url.host!,
                "x-amz-date": amzDate,
                "x-amz-content-sha256": payloadHash
            ],
            payload: emptyPayload,
            dateStamp: dateStamp,
            amzDate: amzDate
        )
        
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw S3Error.invalidResponse
            }
            
            guard httpResponse.statusCode == 204 || httpResponse.statusCode == 200 else {
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                throw S3Error.uploadFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
        } catch let error as S3Error {
            throw error
        } catch {
            throw S3Error.networkError(error)
        }
    }
}