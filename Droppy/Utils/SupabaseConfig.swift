import Foundation
import Supabase

final class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    lazy var client: SupabaseClient = {
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL: \(supabaseURL)")
        }
        return SupabaseClient(supabaseURL: url, supabaseKey: supabaseAnonKey)
    }()
    
    private init() {}
    
    // MARK: - Supabase Configuration
    
    var supabaseURL: String {
        return AppConfiguration.supabaseURL
    }
    
    var supabaseAnonKey: String {
        return AppConfiguration.supabaseAnonKey
    }
    
    // MARK: - API Tokens
    
    var replicateAPIToken: String {
        return AppConfiguration.replicateAPIToken
    }
    
    // MARK: - S3 Configuration
    
    var s3Endpoint: String {
        return AppConfiguration.s3Endpoint
    }
    
    var s3AccessKeyId: String {
        return AppConfiguration.s3AccessKeyId
    }
    
    var s3SecretAccessKey: String {
        return AppConfiguration.s3SecretAccessKey
    }
    
    var s3Region: String {
        return AppConfiguration.s3Region
    }
    
    var s3Bucket: String {
        return AppConfiguration.s3Bucket
    }
}
