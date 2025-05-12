import XCTest
import Network
import Nimble
@testable import CleanUserList_SwiftUI

// Protect the URLSession constructor
extension URLSession {
    static func createMockSession(data: Data, response: URLResponse, error: Error? = nil) -> URLSession {
        // Configure a URLProtocol mock
        let mockConfig = URLSessionConfiguration.ephemeral
        mockConfig.protocolClasses = [MockURLProtocol.self]
        
        // Configure the handler for MockURLProtocol
        MockURLProtocol.requestHandler = { request in
            if let error = error {
                throw error
            }
            return (data, response)
        }
        
        return URLSession(configuration: mockConfig)
    }
}


@MainActor
class APIClientTests: XCTestCase {
    
    func testGetUsersSuccess() async throws {
        // Given
        let jsonData = """
        {
            "results": [
                {
                    "gender": "male",
                    "name": {
                        "title": "Mr",
                        "first": "John",
                        "last": "Doe"
                    },
                    "location": {
                        "street": {
                            "number": 123,
                            "name": "Main St"
                        },
                        "city": "New York",
                        "state": "NY"
                    },
                    "email": "john.doe@example.com",
                    "login": {
                        "uuid": "abcd1234"
                    },
                    "registered": {
                        "date": "2020-01-01T10:30:00.000Z"
                    },
                    "phone": "123-456-7890",
                    "picture": {
                        "large": "https://randomuser.me/api/portraits/men/1.jpg",
                        "medium": "https://randomuser.me/api/portraits/med/men/1.jpg",
                        "thumbnail": "https://randomuser.me/api/portraits/thumb/men/1.jpg"
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        let mockSession = URLSession.createMockSession(
            data: jsonData, 
            response: HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        )
        
        let apiClient = DefaultAPIClient(session: mockSession)
        
        // When
        let response = try await apiClient.getUsers(count: 1)
        
        // Then
        expect(response).toNot(beNil())
        expect(response.results.count).to(equal(1))
        expect(response.results.first?.name.first).to(equal("John"))
        expect(response.results.first?.name.last).to(equal("Doe"))
    }
    
    func testGetUsersNetworkError() async {
        // Given
        let mockSession = URLSession.createMockSession(
            data: Data(),
            response: URLResponse(),
            error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        )
        
        let apiClient = DefaultAPIClient(session: mockSession)
        
        // When / Then
        do {
            _ = try await apiClient.getUsers(count: 1)
            fail("Expected an error but the function completed successfully")
        } catch {
            expect(error).to(beAKindOf(APIError.self))
            if let apiError = error as? APIError {
                expect(apiError).to(equal(APIError.networkError))
            }
        }
    }
    
    func testGetUsersServerError() async {
        // Given
        let mockSession = URLSession.createMockSession(
            data: Data(), 
            response: HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
        )
        
        let apiClient = DefaultAPIClient(session: mockSession)
        
        // When / Then
        do {
            _ = try await apiClient.getUsers(count: 1)
            fail("Expected an error but the function completed successfully")
        } catch {
            expect(error).to(beAKindOf(APIError.self))
            if let apiError = error as? APIError, case let APIError.serverError(statusCode) = apiError {
                expect(statusCode).to(equal(500))
            } else {
                fail("Expected APIError.serverError but got \(String(describing: error))")
            }
        }
    }
    
    func testGetUsersDecodingError() async {
        // Given
        let invalidJSON = "invalid json".data(using: .utf8)!
        let mockSession = URLSession.createMockSession(
            data: invalidJSON, 
            response: HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        )
        
        let apiClient = DefaultAPIClient(session: mockSession)
        
        // When / Then
        do {
            _ = try await apiClient.getUsers(count: 1)
            fail("Expected an error but the function completed successfully")
        } catch {
            expect(error).to(beAKindOf(APIError.self))
            expect(error as? APIError).to(equal(APIError.decodingError))
        }
    }
} 