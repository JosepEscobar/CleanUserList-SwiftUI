import XCTest
import Combine
@testable import CleanUserList_SwiftUI

final class APIClientTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testGetUsersSuccess() {
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
        
        let mockSession = MockURLSession(data: jsonData, response: HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, error: nil)
        
        let apiClient = DefaultAPIClient(baseURL: "https://test.com", session: mockSession)
        
        let expectation = self.expectation(description: "API request completed")
        
        // When
        var receivedResponse: UserResponse?
        var receivedError: Error?
        
        apiClient.getUsers(count: 1)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { response in
                    receivedResponse = response
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertNil(receivedError)
        XCTAssertNotNil(receivedResponse)
        XCTAssertEqual(receivedResponse?.results.count, 1)
        XCTAssertEqual(receivedResponse?.results.first?.name.first, "John")
        XCTAssertEqual(receivedResponse?.results.first?.name.last, "Doe")
    }
    
    func testGetUsersInvalidURL() {
        // Given
        let apiClient = DefaultAPIClient(baseURL: "") // URL inválida
        
        let expectation = self.expectation(description: "API request completed with error")
        
        // When
        var receivedResponse: UserResponse?
        var receivedError: Error?
        
        apiClient.getUsers(count: 1)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { response in
                    receivedResponse = response
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertNil(receivedResponse)
        XCTAssertTrue(receivedError is APIError)
        if let apiError = receivedError as? APIError {
            XCTAssertEqual(apiError, APIError.invalidURL)
        }
    }
    
    func testGetUsersServerError() {
        // Given
        let mockSession = MockURLSession(data: Data(), response: HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)!, error: nil)
        
        let apiClient = DefaultAPIClient(baseURL: "https://test.com", session: mockSession)
        
        let expectation = self.expectation(description: "API request completed with server error")
        
        // When
        var receivedResponse: UserResponse?
        var receivedError: Error?
        
        apiClient.getUsers(count: 1)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { response in
                    receivedResponse = response
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertNil(receivedResponse)
        XCTAssertTrue(receivedError is APIError)
        if let apiError = receivedError as? APIError, case let APIError.serverError(statusCode) = apiError {
            XCTAssertEqual(statusCode, 500)
        } else {
            XCTFail("Expected APIError.serverError but got \(String(describing: receivedError))")
        }
    }
    
    func testGetUsersDecodingError() {
        // Given
        let invalidJSON = "invalid json".data(using: .utf8)!
        let mockSession = MockURLSession(data: invalidJSON, response: HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, error: nil)
        
        let apiClient = DefaultAPIClient(baseURL: "https://test.com", session: mockSession)
        
        let expectation = self.expectation(description: "API request completed with decoding error")
        
        // When
        var receivedResponse: UserResponse?
        var receivedError: Error?
        
        apiClient.getUsers(count: 1)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { response in
                    receivedResponse = response
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertNil(receivedResponse)
        XCTAssertTrue(receivedError is APIError)
        XCTAssertEqual(receivedError as? APIError, APIError.decodingError)
    }
}

class MockURLSession: URLSessionProtocol {
    let data: Data
    let response: URLResponse
    let error: Error?
    
    init(data: Data, response: URLResponse, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }
    
    func dataTaskPublisher(for url: URL) -> URLSession.DataTaskPublisher {
        return MockDataTaskPublisher(data: data, response: response, error: error)
    }
}

struct MockDataTaskPublisher: Publisher {
    typealias Output = URLSession.DataTaskPublisher.Output
    typealias Failure = URLSession.DataTaskPublisher.Failure
    
    let data: Data
    let response: URLResponse
    let error: Error?
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        if let error = error {
            subscriber.receive(completion: .failure(error as! Failure))
        } else {
            _ = subscriber.receive((data, response))
            subscriber.receive(completion: .finished)
        }
    }
} 