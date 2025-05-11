import Foundation

/// Authentication-related endpoints
extension APIEndpoints {
    enum Auth {
        static func login(username: String, password: String) -> APIEndpoint {
            // In a real API, this would be a POST method with credentials
            let loginData = try? JSONSerialization.data(
                withJSONObject: ["username": username, "password": password],
                options: []
            )
            return APIEndpoint(path: "/login", method: .post, body: loginData)
        }
    }
} 