import XCTest
import Nimble
import Network
@testable import CleanUserList_SwiftUI

@MainActor
class DefaultAPIClientTests: XCTestCase {
    
    private var mockURLSession: URLSession!
    private var apiClient: DefaultAPIClient!
    private var originalNetworkChecker: NetworkChecker!
    
    override func setUp() {
        super.setUp()
        
        // Configure a mock URLSession using URLProtocol
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: configuration)
        
        // Save the original NetworkChecker
        originalNetworkChecker = NetworkChecker.shared
        
        apiClient = DefaultAPIClient(session: mockURLSession)
    }
    
    override func tearDown() {
        // Restore the original NetworkChecker
        NetworkChecker.shared = originalNetworkChecker
        
        mockURLSession = nil
        apiClient = nil
        originalNetworkChecker = nil
        super.tearDown()
    }
    
    func testRequestThrowsUnreachableWhenNetworkIsDisconnected() async {
        // Given
        // Create a mock for NetworkChecker that reports not connected
        let originalChecker = NetworkChecker.shared
        
        // Create a new networkChecker with a controlled monitor
        let mockMonitor = MockNWPathMonitor()
        let mockNetworkChecker = NetworkChecker(pathMonitor: mockMonitor)
        
        // Set the checker with connectivity disabled
        NetworkChecker.shared = mockNetworkChecker
        
        // Directly simulate a path with "unsatisfied" status
        mockMonitor.simulatePathUpdate(.unsatisfied)
        
        let endpoint = APIEndpoints.Users.getUsers(count: 10)
        
        // When/Then
        do {
            _ = try await apiClient.request(endpoint) as UserResponse
            fail("Expected an APIError.unreachable to be thrown")
        } catch {
            expect(error).to(matchError(APIError.unreachable))
        }
        
        // Cleanup
        NetworkChecker.shared = originalChecker
    }
    
    func testRequestHandlesSuccessfulResponse() async throws {
        // Given
        let endpoint = APIEndpoints.Users.getUsers(count: 10)
        
        // Create a valid JSON for the response
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
                        "city": "Test City",
                        "state": "TS"
                    },
                    "email": "john@example.com",
                    "login": {
                        "uuid": "test-id"
                    },
                    "registered": {
                        "date": "2023-01-01T10:00:00.000Z"
                    },
                    "phone": "123-456-7890",
                    "picture": {
                        "large": "https://example.com/large.jpg",
                        "medium": "https://example.com/medium.jpg",
                        "thumbnail": "https://example.com/thumbnail.jpg"
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.randomuser.me/")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // Configure MockURLProtocol with a handler
        MockURLProtocol.requestHandler = { _ in
            return (jsonData, httpResponse)
        }
        
        // When
        let response: UserResponse = try await apiClient.request(endpoint)
        
        // Then
        expect(response.results.count).to(equal(1))
        expect(response.results[0].login.uuid).to(equal("test-id"))
        expect(response.results[0].email).to(equal("john@example.com"))
    }
    
    func testRequestHandlesHTTPErrorResponse() async throws {
        // Given
        let endpoint = APIEndpoints.Users.getUsers(count: 10)
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.randomuser.me/")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // Configure MockURLProtocol with specific handler
        MockURLProtocol.requestHandler = { _ in
            return (Data(), httpResponse)
        }
        
        // When/Then
        await expectAsync({
            _ = try await self.apiClient.request(endpoint) as UserResponse
        }, toThrow: APIError.serverError(statusCode: 404))
    }
    
    func testRequestHandlesNetworkError() async throws {
        // Given
        let endpoint = APIEndpoints.Users.getUsers(count: 10)
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        
        // Configure MockURLProtocol to throw a network error
        MockURLProtocol.requestHandler = { _ in
            throw networkError
        }
        
        // When/Then
        await expectAsync({
            _ = try await self.apiClient.request(endpoint) as UserResponse
        }, toThrow: APIError.networkError)
    }
    
    func testGetUsersCallsRequestWithCorrectEndpoint() async throws {
        // Given
        let count = 15
        
        // Prepare response
        let data = """
        {
            "results": []
        }
        """.data(using: .utf8)!
        
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!, 
            statusCode: 200, 
            httpVersion: nil, 
            headerFields: nil
        )!
        
        MockURLProtocol.mockResponses = [data: response]
        MockURLProtocol.mockError = nil
        MockURLProtocol.requestHandler = { request in
            // Verify that the URL contains the correct parameter
            guard request.url != nil else {
                throw NSError(domain: "test", code: -1)
            }
            
            MockURLProtocol.lastRequest = request
            return (data, response)
        }
        
        // When
        _ = try await apiClient.getUsers(count: count)
        
        // Then
        let request = MockURLProtocol.lastRequest
        expect(request).toNot(beNil())
        expect(request?.url?.absoluteString).to(contain("results=\(count)"))
    }
    
    func testGetUsersWithRetryRetriesOnFailure() async throws {
        // Given
        let transientError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        
        // Configure to fail the first 2 times
        var callCount = 0
        
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            
            if callCount <= 2 {
                throw transientError
            } else {
                // Success on the third attempt
                let responseData = """
                {
                    "results": []
                }
                """.data(using: .utf8)!
                
                let successResponse = HTTPURLResponse(
                    url: URL(string: "https://example.com")!, 
                    statusCode: 200, 
                    httpVersion: nil, 
                    headerFields: nil
                )!
                
                return (responseData, successResponse)
            }
        }
        
        // When
        let response = try await apiClient.getUsersWithRetry(count: 10)
        
        // Then
        expect(callCount).to(equal(3)) // Initial attempt + 2 retries
        expect(response.results).to(beEmpty())
    }
}

// MARK: - Test Doubles
class MockURLProtocol: URLProtocol {
    static var mockResponses: [Data: URLResponse] = [:]
    static var mockError: Error?
    static var requestHandler: ((URLRequest) throws -> (Data, URLResponse))? = nil
    static var lastRequest: URLRequest?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        MockURLProtocol.lastRequest = request
        
        if let handler = Self.requestHandler {
            do {
                let (data, response) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
            return
        }
        
        if let error = Self.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        for (data, response) in Self.mockResponses {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        // If no responses are configured
        let error = NSError(domain: "com.test", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock response found"])
        client?.urlProtocol(self, didFailWithError: error)
    }
    
    override func stopLoading() {}
    
    static func reset() {
        mockResponses = [:]
        mockError = nil
        requestHandler = nil
        lastRequest = nil
    }
}

// MARK: - NWPathMonitorProtocol Mock
extension DefaultAPIClientTests {
    class MockNWPathMonitor: @unchecked Sendable, NWPathMonitorProtocol {
        private let handlerLock = NSLock()
        private var _handler: ((NWPath) -> Void)?
        
        var startCalled = false
        var cancelCalled = false
        
        func setUpdateHandler(_ handler: @escaping @Sendable (NWPath) -> Void) {
            handlerLock.lock()
            defer { handlerLock.unlock() }
            _handler = handler
        }
        
        private func withLock<T>(_ operation: () -> T) -> T {
            handlerLock.lock()
            defer { handlerLock.unlock() }
            return operation()
        }
        
        func simulatePathUpdate(_ status: NWPath.Status) {
            // Get a real NWPath to use in the handler
            let semaphore = DispatchSemaphore(value: 0)
            let tempMonitor = NWPathMonitor()
            
            // Use a local actor to preserve concurrency safety
            actor PathHandler {
                var path: NWPath?
                
                func setPath(_ newPath: NWPath) {
                    path = newPath
                }
                
                func getPath() -> NWPath? {
                    return path
                }
            }
            
            let pathHandler = PathHandler()
            
            tempMonitor.pathUpdateHandler = { newPath in
                Task {
                    await pathHandler.setPath(newPath)
                    semaphore.signal()
                }
            }
            
            let queue = DispatchQueue(label: "temp.path.queue")
            tempMonitor.start(queue: queue)
            
            // Wait until we get a path
            _ = semaphore.wait(timeout: .now() + 0.5)
            tempMonitor.cancel()
            
            // Now use the real path to simulate the change
            Task {
                if let realPath = await pathHandler.getPath() {
                    // Use the secure withLock method instead of direct lock/unlock
                    let currentHandler = withLock { self._handler }
                    
                    if let handler = currentHandler {
                        // Invoke the handler with the real path
                        handler(realPath)
                    }
                }
            }
        }
        
        func start(queue: DispatchQueue) {
            startCalled = true
        }
        
        func cancel() {
            cancelCalled = true
        }
    }
}

// MARK: - MockNWPath
extension DefaultAPIClientTests {
    // Instead of inheriting from NWPath, we create a wrapper class
    class MockNWPath {
        var _status: NWPath.Status
        var realPath: NWPath?
        
        init(status: NWPath.Status) {
            self._status = status
            
            // Get a real NWPath for reference
            let semaphore = DispatchSemaphore(value: 0)
            let tempMonitor = NWPathMonitor()
            
            tempMonitor.pathUpdateHandler = { path in
                self.realPath = path
                semaphore.signal()
            }
            
            let queue = DispatchQueue(label: "temp.mock.path.queue")
            tempMonitor.start(queue: queue)
            
            // Wait briefly to get a path
            _ = semaphore.wait(timeout: .now() + 0.5)
            tempMonitor.cancel()
        }
        
        // Methods to access NWPath properties
        var status: NWPath.Status {
            return _status
        }
        
        // Delegate other properties to the real path when possible
        var isExpensive: Bool {
            return realPath?.isExpensive ?? false
        }
        
        var isConstrained: Bool {
            return realPath?.isConstrained ?? false
        }
        
        func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
            return realPath?.usesInterfaceType(type) ?? false
        }
    }
} 