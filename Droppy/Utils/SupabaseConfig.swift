import Foundation

enum SupabaseConfig {
    static var supabaseURL: String {
        #if DEBUG
        // In debug, provide fallback values to prevent crashes during development
        return "https://knbnmcrkyjcbihqdabld.supabase.co"
        #else
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !url.isEmpty,
              !url.contains("YOUR_SUPABASE_PROJECT_URL_HERE") else {
            fatalError("SUPABASE_URL must be set in Keys.xcconfig")
        }
        return url
        #endif
    }
    
    static var supabaseAnonKey: String {
        #if DEBUG
        // In debug, provide fallback values to prevent crashes during development
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtuYm5tY3JreWpjYmlocWRhYmxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzNzE2MjAsImV4cCI6MjA2ODk0NzYyMH0.9UJrqHRiiGOZTngUG3CyIXvenSwXySzx4IFkcVWrom4"
        #else
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty,
              !key.contains("YOUR_SUPABASE_ANON_KEY_HERE") else {
            fatalError("SUPABASE_ANON_KEY must be set in Keys.xcconfig")
        }
        return key
        #endif
    }
}
