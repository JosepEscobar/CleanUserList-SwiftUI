import Foundation
import Network

struct NetworkConfiguration {
    private enum Constants {
        static let memoryCacheCapacity = 5 * 1024 * 1024 // 5MB
        static let diskCacheCapacity = 20 * 1024 * 1024 // 20MB
        static let timeoutIntervalForRequest: TimeInterval = 15.0
        static let timeoutIntervalForResource: TimeInterval = 30.0
        static let maxConnectionsPerHost = 3
        
        enum Headers {
            static let accept = "application/json"
            static let contentType = "application/json"
        }
    }
    
    static func configureURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        let cache = URLCache(memoryCapacity: Constants.memoryCacheCapacity,
                           diskCapacity: Constants.diskCacheCapacity,
                           directory: nil)
        
        configuration.timeoutIntervalForRequest = Constants.timeoutIntervalForRequest
        configuration.timeoutIntervalForResource = Constants.timeoutIntervalForResource
        configuration.allowsCellularAccess = true
        configuration.httpMaximumConnectionsPerHost = Constants.maxConnectionsPerHost
        configuration.waitsForConnectivity = false
        configuration.urlCache = cache
        configuration.httpAdditionalHeaders = [
            "Accept": Constants.Headers.accept,
            "Content-Type": Constants.Headers.contentType,
            "Alt-Svc": ""
        ]
        
        // Force the use of HTTP/1.1 using our custom URLProtocol
        configuration.protocolClasses = [ForceHTTP11URLProtocol.self]
        
        return URLSession(configuration: configuration)
    }
} 
