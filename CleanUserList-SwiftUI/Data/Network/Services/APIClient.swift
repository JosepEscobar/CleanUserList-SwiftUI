import Foundation

enum APIError: Error, Equatable {
    case networkError
    case decodingError
    case serverError(statusCode: Int)
    case responseError
    case timeout
    case unreachable
    case unknown(String)
    
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError, .networkError),
             (.decodingError, .decodingError),
             (.responseError, .responseError),
             (.timeout, .timeout),
             (.unreachable, .unreachable):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .networkError:
            return "Error de red: comprueba tu conexión a Internet"
        case .decodingError:
            return "Error al decodificar los datos"
        case .serverError(let statusCode):
            return "Error del servidor: código \(statusCode)"
        case .responseError:
            return "Error en la respuesta del servidor"
        case .timeout:
            return "Tiempo de espera agotado para la solicitud"
        case .unreachable:
            return "No se puede conectar al servidor"
        case .unknown(let message):
            return "Error desconocido: \(message)"
        }
    }
}

protocol URLSessionProtocol {
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

protocol DateFormatterProtocol {
    func string(from date: Date) -> String
    func date(from string: String) -> Date?
}

extension DateFormatter: DateFormatterProtocol {}

@MainActor
protocol APIClient {
    func getUsers(count: Int) async throws -> UserResponse
}

@MainActor
class DefaultAPIClient: APIClient {
    private let decoder = JSONDecoder()
    
    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        decoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    func getUsers(count: Int) async throws -> UserResponse {
        let urlString = "http://api.randomuser.me/?results=\(count)&nat=es"
        guard let url = URL(string: urlString) else {
            throw APIError.unknown("URL inválida")
        }
        
        do {
            let request = URLRequest(url: url)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.responseError
            }
            
            let userResponse = try decoder.decode(UserResponse.self, from: data)
            return userResponse
            
        } catch {
            throw error
        }
    }
} 


