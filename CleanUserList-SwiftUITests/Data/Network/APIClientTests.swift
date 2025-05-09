import XCTest
@testable import CleanUserList_SwiftUI

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
        
        let mockSession = MockURLSession(data: jsonData, response: HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        
        let apiClient = DefaultAPIClient(baseURL: "https://test.com", session: mockSession)
        
        // When
        let response = try await apiClient.getUsers(count: 1)
        
        // Then
        XCTAssertNotNil(response)
        XCTAssertEqual(response.results.count, 1)
        XCTAssertEqual(response.results.first?.name.first, "John")
        XCTAssertEqual(response.results.first?.name.last, "Doe")
    }
    
    func testGetUsersInvalidURL() async {
        // Given
        let apiClient = DefaultAPIClient(baseURL: "")
        
        // When / Then
        do {
            _ = try await apiClient.getUsers(count: 1)
            XCTFail("Expected an error but the function completed successfully")
        } catch {
            XCTAssertTrue(error is APIError)
            if let apiError = error as? APIError {
                XCTAssertEqual(apiError, APIError.invalidURL)
            }
        }
    }
    
    func testGetUsersServerError() async {
        // Given
        let mockSession = MockURLSession(data: Data(), response: HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)!)
        
        let apiClient = DefaultAPIClient(baseURL: "https://test.com", session: mockSession)
        
        // When / Then
        do {
            _ = try await apiClient.getUsers(count: 1)
            XCTFail("Expected an error but the function completed successfully")
        } catch {
            XCTAssertTrue(error is APIError)
            if let apiError = error as? APIError, case let APIError.serverError(statusCode) = apiError {
                XCTAssertEqual(statusCode, 500)
            } else {
                XCTFail("Expected APIError.serverError but got \(String(describing: error))")
            }
        }
    }
    
    func testGetUsersDecodingError() async {
        // Given
        let invalidJSON = "invalid json".data(using: .utf8)!
        let mockSession = MockURLSession(data: invalidJSON, response: HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        
        let apiClient = DefaultAPIClient(baseURL: "https://test.com", session: mockSession)
        
        // When / Then
        do {
            _ = try await apiClient.getUsers(count: 1)
            XCTFail("Expected an error but the function completed successfully")
        } catch {
            XCTAssertTrue(error is APIError)
            XCTAssertEqual(error as? APIError, APIError.decodingError)
        }
    }
}

class MockURLSession: URLSessionProtocol {
    let data: Data
    let response: URLResponse
    let error: Error?
    
    init(data: Data, response: URLResponse, error: Error? = nil) {
        self.data = data
        self.response = response
        self.error = error
    }
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        return (data, response)
    }
} 