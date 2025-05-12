import XCTest
import Nimble
@testable import CleanUserList_SwiftUI

class APIEndpointTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEndpointCreatesCorrectURLRequest() {
        // Given
        let path = "/test-path"
        let queryItems = [URLQueryItem(name: "param1", value: "value1")]
        let headers = ["X-Custom-Header": "custom-value"]
        let body = "test-body".data(using: .utf8)
        let endpoint = APIEndpoint(
            path: path,
            method: .post,
            queryItems: queryItems,
            headers: headers,
            body: body,
            environment: .production
        )
        
        // When
        let request = try? endpoint.urlRequest()
        
        // Then
        expect(request).toNot(beNil())
        expect(request?.url?.path).to(equal(path))
        expect(request?.url?.query).to(equal("param1=value1"))
        expect(request?.httpMethod).to(equal("POST"))
        expect(request?.allHTTPHeaderFields?["X-Custom-Header"]).to(equal("custom-value"))
        expect(request?.allHTTPHeaderFields?["Accept"]).to(equal("application/json"))
        expect(request?.allHTTPHeaderFields?["Content-Type"]).to(equal("application/json"))
        expect(request?.httpBody).to(equal(body))
    }
    
    func testEndpointHandlesPathWithoutLeadingSlash() {
        // Given
        let pathWithoutSlash = "test-path"
        let endpoint = APIEndpoint(path: pathWithoutSlash)
        
        // When
        let request = try? endpoint.urlRequest()
        
        // Then
        expect(request).toNot(beNil())
        expect(request?.url?.path).to(equal("/\(pathWithoutSlash)"))
    }
    
    func testEndpointDefaultValues() {
        // Given
        let path = "/test"
        let endpoint = APIEndpoint(path: path)
        
        // When
        let request = try? endpoint.urlRequest()
        
        // Then
        expect(request).toNot(beNil())
        expect(request?.httpMethod).to(equal("GET"))
        expect(request?.url?.absoluteString).to(equal("https://api.randomuser.me/test"))
        expect(request?.httpBody).to(beNil())
    }
}

// Tests for specific endpoints
class APIEndpointsSpecificTests: XCTestCase {
    
    func testUsersGetUsersEndpoint() {
        // Given
        let count = 25
        
        // When
        let endpoint = APIEndpoints.Users.getUsers(count: count)
        let request = try? endpoint.urlRequest()
        
        // Then
        expect(request).toNot(beNil())
        expect(request?.url?.absoluteString).to(contain("results=\(count)"))
        expect(request?.httpMethod).to(equal("GET"))
    }
    
    func testUsersGetSpecificUserEndpoint() {
        // Given
        let seed = "test-seed"
        
        // When
        let endpoint = APIEndpoints.Users.getUser(seed: seed)
        let request = try? endpoint.urlRequest()
        
        // Then
        expect(request).toNot(beNil())
        expect(request?.url?.absoluteString).to(contain("seed=\(seed)"))
        expect(request?.url?.absoluteString).to(contain("results=1"))
    }
    
    func testAuthLoginEndpoint() {
        // Given
        let username = "testuser"
        let password = "testpass"
        
        // When
        let endpoint = APIEndpoints.Auth.login(username: username, password: password)
        let request = try? endpoint.urlRequest()
        
        // Then
        expect(request).toNot(beNil())
        expect(request?.url?.path).to(equal("/login"))
        expect(request?.httpMethod).to(equal("POST"))
        
        // Convert httpBody to JSON
        if let bodyData = request?.httpBody,
           let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: String] {
            expect(json["username"]).to(equal(username))
            expect(json["password"]).to(equal(password))
        } else {
            fail("Could not parse request body as JSON")
        }
    }
} 
