import Foundation

/// User-related endpoints
extension APIEndpoints {
    enum Users {
        private enum Constants {
            static let rootPath = "/"
            static let resultsParameter = "results"
            static let seedParameter = "seed"
            static let singleResultValue = "1"
        }
        
        /// Get list of users
        static func getUsers(count: Int) -> APIEndpoint {
            let queryItems = [URLQueryItem(name: Constants.resultsParameter, value: "\(count)")]
            return APIEndpoint(path: Constants.rootPath, queryItems: queryItems)
        }
        
        /// Get a specific user by seed
        static func getUser(seed: String) -> APIEndpoint {
            let queryItems = [
                URLQueryItem(name: Constants.seedParameter, value: seed),
                URLQueryItem(name: Constants.resultsParameter, value: Constants.singleResultValue)
            ]
            return APIEndpoint(path: Constants.rootPath, queryItems: queryItems)
        }
    }
} 