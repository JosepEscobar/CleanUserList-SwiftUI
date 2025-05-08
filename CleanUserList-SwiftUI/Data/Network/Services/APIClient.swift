import Foundation
import Combine

enum APIError: Error, Equatable {
    case invalidURL
    case responseError
    case decodingError
    case serverError(statusCode: Int)
    case unknown
    
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.responseError, .responseError):
            return true
        case (.decodingError, .decodingError):
            return true
        case let (.serverError(lhsCode), .serverError(rhsCode)):
            return lhsCode == rhsCode
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}

protocol URLSessionProtocol {
    func dataTaskPublisher(for url: URL) -> URLSession.DataTaskPublisher
}

extension URLSession: URLSessionProtocol {}

protocol DateFormatterProtocol {
    func string(from date: Date) -> String
    func date(from string: String) -> Date?
}

extension DateFormatter: DateFormatterProtocol {}

protocol APIClient {
    func getUsers(count: Int) -> AnyPublisher<UserResponse, Error>
}

class DefaultAPIClient: APIClient {
    private let baseURL: String
    private let session: URLSessionProtocol
    private let decoder: JSONDecoder
    
    init(
        baseURL: String = "https://api.randomuser.me",
        session: URLSessionProtocol = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        
        // Configurar el decodificador de fechas
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        self.decoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    func getUsers(count: Int) -> AnyPublisher<UserResponse, Error> {
        guard let url = URL(string: "\(baseURL)/?results=\(count)") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.responseError
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    throw APIError.serverError(statusCode: httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: UserResponse.self, decoder: decoder)
            .mapError { error in
                if let error = error as? APIError {
                    return error
                } else if error is DecodingError {
                    return APIError.decodingError
                } else {
                    return APIError.unknown
                }
            }
            .eraseToAnyPublisher()
    }
} 