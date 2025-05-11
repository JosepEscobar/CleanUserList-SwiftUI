import Foundation

/// Authentication-related endpoints (Its Just an example for another endpoint creation)
extension APIEndpoints {
    enum Auth {
        private enum Constants {
            static let loginPath = "/login"
            static let usernameKey = "username"
            static let passwordKey = "password"
        }
        
        static func login(username: String, password: String) -> APIEndpoint {
            // In a real API, this would be a POST method with credentials
            let loginData = try? JSONSerialization.data(
                withJSONObject: [Constants.usernameKey: username, Constants.passwordKey: password],
                options: []
            )
            return APIEndpoint(path: Constants.loginPath, method: .post, body: loginData)
        }
    }
} 
