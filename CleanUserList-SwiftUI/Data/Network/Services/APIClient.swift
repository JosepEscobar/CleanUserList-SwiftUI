import Foundation
import Network

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
    func getUsersWithRetry(count: Int, retries: Int, delay: TimeInterval) async throws -> UserResponse
    func getUsersWithRetry(count: Int) async throws -> UserResponse
}

@MainActor
class DefaultAPIClient: APIClient {
    private enum Constants {
        static let baseURL = "https://api.randomuser.me"
        static let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        static let locale = "en_US_POSIX"
    }
    
    private let decoder = JSONDecoder()
    private let session: URLSession
    
    init(session: URLSession = NetworkConfiguration.configureURLSession()) {
        self.session = session
        
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.dateFormat
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: Constants.locale)
        
        decoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    func getUsers(count: Int) async throws -> UserResponse {
        // Verificar la conectividad antes de realizar la solicitud
        guard NetworkChecker.shared.isConnected else {
            throw APIError.unreachable
        }
        
        // Garantizar que cada solicitud use un seed único basado en timestamp
        let urlString = "\(Constants.baseURL)/?results=\(count)"
        guard let url = URL(string: urlString) else {
            throw APIError.unknown("URL inválida")
        }
        
        do {
            var request = URLRequest(url: url)
            // Ajustar política de caché para evitar problemas con el simulador
            request.cachePolicy = .reloadIgnoringLocalCacheData
            
            let (data, response) = try await session.data(for: request, delegate: nil)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.responseError
            }
            
            let userResponse = try decoder.decode(UserResponse.self, from: data)
            return userResponse
            
        } catch let error as DecodingError {
            print("Error de decodificación: \(error)")
            throw APIError.decodingError
        } catch let urlError as URLError {
            print("Error de URL: \(urlError)")
            switch urlError.code {
            case .timedOut:
                throw APIError.timeout
            case .notConnectedToInternet, .networkConnectionLost:
                throw APIError.networkError
            default:
                throw APIError.unknown(urlError.localizedDescription)
            }
        } catch {
            print("Error desconocido: \(error)")
            throw APIError.unknown(error.localizedDescription)
        }
    }
    
    func getUsersWithRetry(count: Int, retries: Int = 3, delay: TimeInterval = 2.0) async throws -> UserResponse {
        var currentAttempt = 0
        var lastError: Error?

        while currentAttempt < retries {
            do {
                return try await getUsers(count: count)
            } catch {
                lastError = error
                currentAttempt += 1
                print("Intento \(currentAttempt) fallido: \(error.localizedDescription)")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError ?? APIError.unknown("Error desconocido tras \(retries) reintentos")
    }
    
    func getUsersWithRetry(count: Int) async throws -> UserResponse {
        return try await getUsersWithRetry(count: count, retries: 3, delay: 2.0)
    }
}


