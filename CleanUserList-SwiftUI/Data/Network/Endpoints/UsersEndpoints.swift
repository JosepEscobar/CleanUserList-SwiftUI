import Foundation

/// User-related endpoints
extension APIEndpoints {
    enum Users {
        /// Get list of users
        static func getUsers(count: Int) -> APIEndpoint {
            let queryItems = [URLQueryItem(name: "results", value: "\(count)")]
            return APIEndpoint(path: "/", queryItems: queryItems)
        }
        
        /// Get a specific user by seed
        static func getUser(seed: String) -> APIEndpoint {
            let queryItems = [
                URLQueryItem(name: "seed", value: seed),
                URLQueryItem(name: "results", value: "1")
            ]
            return APIEndpoint(path: "/", queryItems: queryItems)
        }
    }
} 