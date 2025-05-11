import Foundation

/// Enumeration with the different available environments
enum APIEnvironment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "https://dev.api.randomuser.me"
        case .staging:
            return "https://staging.api.randomuser.me"
        case .production:
            return "https://api.randomuser.me"
        }
    }
}

/// Supported HTTP methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Structure to define an API endpoint
struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?
    let headers: [String: String]?
    let body: Data?
    let environment: APIEnvironment
    
    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil,
        body: Data? = nil,
        environment: APIEnvironment = .production
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.environment = environment
    }
    
    func urlRequest() throws -> URLRequest {
        var components = URLComponents(string: environment.baseURL)
        components?.path = path.hasPrefix("/") ? path : "/\(path)"
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw APIError.unknown("Invalid URL for endpoint: \(path)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set common default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add endpoint-specific headers
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
}

/// Namespace to organize endpoints by domain
enum APIEndpoints {} 