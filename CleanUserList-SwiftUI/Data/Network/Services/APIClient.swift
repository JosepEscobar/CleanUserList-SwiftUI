import Foundation
import Network

// No necesitamos importar estos tipos ya que están en el mismo módulo
// import struct CleanUserList_SwiftUI.APIEndpoint
// import enum CleanUserList_SwiftUI.APIEndpoints

@MainActor
protocol APIClient {
    func getUsers(count: Int) async throws -> UserResponse
    func getUsersWithRetry(count: Int) async throws -> UserResponse
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

@MainActor
class DefaultAPIClient: APIClient {
    private enum Constants {
        static let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        static let locale = "en_US_POSIX"
        static let defaultRetries = 3
        static let defaultRetryDelay: TimeInterval = 2.0
        static let nanosecondsPerSecond: Double = 1_000_000_000
        static let successStatusCodeRange = 200...299
        static let clientErrorStatusCodeRange = 400...499
        static let serverErrorStatusCodeRange = 500...599
    }
    
    private let decoder: JSONDecoder
    private let session: URLSession
    
    init(session: URLSession = NetworkConfiguration.configureURLSession()) {
        self.session = session
        
        self.decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.dateFormat
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: Constants.locale)
        
        decoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        // Check connectivity before making the request
        guard NetworkChecker.shared.isConnected else {
            throw APIError.unreachable
        }
        
        do {
            var request = try endpoint.urlRequest()
            // Adjust cache policy to avoid simulator issues
            request.cachePolicy = .reloadIgnoringLocalCacheData
            
            let (data, response) = try await session.data(for: request, delegate: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.responseError
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case Constants.successStatusCodeRange:
                return try decoder.decode(T.self, from: data)
            case Constants.clientErrorStatusCodeRange:
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            case Constants.serverErrorStatusCodeRange:
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw APIError.responseError
            }
            
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        } catch let urlError as URLError {
            print("URL error: \(urlError)")
            switch urlError.code {
            case .timedOut:
                throw APIError.timeout
            case .notConnectedToInternet, .networkConnectionLost:
                throw APIError.networkError
            default:
                throw APIError.unknown(urlError.localizedDescription)
            }
        } catch let apiError as APIError {
            throw apiError
        } catch {
            print("Unknown error: \(error)")
            throw APIError.unknown(error.localizedDescription)
        }
    }
    
    func getUsers(count: Int) async throws -> UserResponse {
        let endpoint = APIEndpoints.Users.getUsers(count: count)
        return try await request(endpoint)
    }
    
    func getUsersWithRetry(count: Int) async throws -> UserResponse {
        let retries: Int = Constants.defaultRetries
        let delay: TimeInterval = Constants.defaultRetryDelay
        var currentAttempt = 0
        var lastError: Error?

        while currentAttempt < retries {
            do {
                return try await getUsers(count: count)
            } catch {
                lastError = error
                currentAttempt += 1
                print("Attempt \(currentAttempt) failed: \(error.localizedDescription)")
                try await Task.sleep(nanoseconds: UInt64(delay * Constants.nanosecondsPerSecond))
            }
        }

        throw lastError ?? APIError.unknown("Unknown error after \(retries) retries")
    }
}


