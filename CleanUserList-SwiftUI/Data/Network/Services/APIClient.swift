import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case responseError
    case decodingError
    case serverError(statusCode: Int)
    case unknown
}

protocol APIClient {
    func getUsers(count: Int) -> AnyPublisher<UserResponse, Error>
}

class DefaultAPIClient: APIClient {
    private let baseURL = "https://api.randomuser.me"
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
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