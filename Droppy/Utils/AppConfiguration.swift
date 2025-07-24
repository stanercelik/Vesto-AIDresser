//
//  AppConfiguration.swift
//  Droppy
//
//  Created by Taner Çelik on 24.07.2025.
//

import Foundation

enum AppConfiguration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}

// MARK: - Supabase Configuration
extension AppConfiguration {
    static var supabaseURL: String {
        do {
            return try value(for: "SupabaseUrl")
        } catch {
            fatalError("Supabase URL not found in Info.plist. Error: \(error)")
        }
    }
    
    static var supabaseAnonKey: String {
        do {
            return try value(for: "SupabaseAnonKey")
        } catch {
            fatalError("Supabase Anonymous Key not found in Info.plist. Error: \(error)")
        }
    }
}

// MARK: - API Keys
extension AppConfiguration {
    static var replicateAPIToken: String {
        do {
            return try value(for: "ReplicateApiToken")
        } catch {
            fatalError("Replicate API Token not found in Info.plist. Error: \(error)")
        }
    }
}

// MARK: - S3 Configuration
extension AppConfiguration {
    static var s3Endpoint: String {
        do {
            return try value(for: "SupabaseS3Endpoint")
        } catch {
            fatalError("Supabase S3 Endpoint not found in Info.plist. Error: \(error)")
        }
    }
    
    static var s3AccessKeyId: String {
        do {
            return try value(for: "SupabaseS3AccessKeyId")
        } catch {
            fatalError("Supabase S3 Access Key ID not found in Info.plist. Error: \(error)")
        }
    }
    
    static var s3SecretAccessKey: String {
        do {
            return try value(for: "SupabaseS3SecretAccessKey")
        } catch {
            fatalError("Supabase S3 Secret Access Key not found in Info.plist. Error: \(error)")
        }
    }
    
    static var s3Region: String {
        do {
            return try value(for: "SupabaseS3Region")
        } catch {
            fatalError("Supabase S3 Region not found in Info.plist. Error: \(error)")
        }
    }
    
    static var s3Bucket: String {
        do {
            return try value(for: "SupabaseS3Bucket")
        } catch {
            fatalError("Supabase S3 Bucket not found in Info.plist. Error: \(error)")
        }
    }
}