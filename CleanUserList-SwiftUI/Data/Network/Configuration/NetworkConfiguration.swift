import Foundation

struct NetworkConfiguration {
    static func configureURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        let cache = URLCache(memoryCapacity: 5 * 1024 * 1024, // 5MB
                           diskCapacity: 20 * 1024 * 1024, // 20MB
                           directory: nil)
        
        configuration.timeoutIntervalForRequest = 15.0
        configuration.timeoutIntervalForResource = 30.0
        configuration.allowsCellularAccess = true
        configuration.httpMaximumConnectionsPerHost = 3
        configuration.waitsForConnectivity = true
        configuration.urlCache = cache
        configuration.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "CleanUserList-SwiftUI/1.0"
        ]
        
        return URLSession(configuration: configuration)
    }
} 
