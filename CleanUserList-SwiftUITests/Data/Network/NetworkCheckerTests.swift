import XCTest
import Nimble
import Network
@testable import CleanUserList_SwiftUI

@MainActor
class NetworkCheckerTests: XCTestCase {
    
    private var mockPathMonitor: MockNWPathMonitor!
    private var networkChecker: NetworkChecker!
    
    override func setUp() async throws {
        try await super.setUp()
        mockPathMonitor = MockNWPathMonitor()
        networkChecker = NetworkChecker(pathMonitor: mockPathMonitor)
    }
    
    override func tearDown() async throws {
        mockPathMonitor = nil
        networkChecker = nil
        try await super.tearDown()
    }
    
    func testInitialStateFalse() async {
        // Given
        // Default value already configured in setUp
        
        // Then
        await awaitExpectation {
            expect(self.networkChecker.isConnected).to(beFalse())
        }
    }
    
    func testStartAndStopMonitoring() async {
        // When
        networkChecker.startMonitoring()
        
        // Then
        await awaitExpectation {
            expect(self.mockPathMonitor.startCalled).to(beTrue())
        }
        
        // When
        networkChecker.stopMonitoring()
        
        // Then
        await awaitExpectation {
            expect(self.mockPathMonitor.cancelCalled).to(beTrue())
        }
    }
}

// MARK: - Test Doubles
extension NetworkCheckerTests {
    
    // We use @unchecked to avoid Sendable errors, as this mock
    // is only used in tests and not in concurrent production code
    final class MockNWPathMonitor: @unchecked Sendable, NWPathMonitorProtocol {
        // Properties to track method calls
        private(set) var startCalled = false
        private(set) var cancelCalled = false
        
        // Stored handler
        private var updateHandler: ((NWPath) -> Void)?
        
        func setUpdateHandler(_ handler: @escaping (NWPath) -> Void) {
            self.updateHandler = handler
        }
        
        func start(queue: DispatchQueue) {
            startCalled = true
        }
        
        func cancel() {
            cancelCalled = true
        }
    }
}

// Extension to be able to simulate NWPath states in tests
extension NetworkChecker {
    static nonisolated(unsafe) var simulatePathStatus: NWPath.Status?
    
    static nonisolated func resetSimulation() {
        simulatePathStatus = nil
    }
}

// Hack to intercept the status property of NWPath
extension NWPath {
    public var testStatus: NWPath.Status {
        return NetworkChecker.simulatePathStatus ?? self.status
    }
} 