import XCTest
import Nimble

/// Extensions to facilitate the use of Nimble with asynchronous code
extension XCTestCase {
    
    /// Executes an asynchronous expectation with custom timeout
    /// - Parameters:
    ///   - timeout: Maximum wait time in seconds
    ///   - description: Description for failure diagnostics
    ///   - asyncExpression: Asynchronous closure containing the expectations
    func awaitExpectation(
        timeout: TimeInterval = 1.0,
        description: String = "async expectation",
        file: FileString = #file,
        line: UInt = #line,
        asyncExpression: @escaping () async throws -> Void
    ) async {
        let expectation = self.expectation(description: description)
        
        Task {
            do {
                try await asyncExpression()
                expectation.fulfill()
            } catch {
                fail("Error in asynchronous expectation: \(error)", file: file, line: line)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: timeout)
    }
    
    /// Executes an expectation with asynchronous verification
    /// - Parameters:
    ///   - expression: Asynchronous closure that returns the value for the expectation
    ///   - matcher: The Nimble matcher to apply
    ///   - timeout: Maximum wait time
    ///   - pollInterval: Interval between checks
    func expectAsync<T>(
        _ expression: @escaping () async throws -> T,
        to matcher: Matcher<T>,
        timeout: DispatchTimeInterval = .seconds(1),
        pollInterval: DispatchTimeInterval = .milliseconds(100),
        file: FileString = #file,
        line: UInt = #line
    ) async {
        await awaitExpectation(description: "expectAsync") {
            var result: T?
            var capturedError: Error?
            
            do {
                result = try await expression()
            } catch {
                capturedError = error
            }
            
            if let error = capturedError {
                fail("Error in asynchronous expression: \(error)", file: file, line: line)
                return
            }
            
            guard let unwrappedResult = result else {
                fail("Asynchronous result is nil", file: file, line: line)
                return
            }
            
            expect(file: file, line: line, unwrappedResult).to(matcher)
        }
    }
    
    /// Simplified version for expectations that verify equality
    func expectAsync<T: Equatable>(
        _ expression: @escaping () async throws -> T,
        toEqual expectedValue: T,
        timeout: DispatchTimeInterval = .seconds(1),
        file: FileString = #file,
        line: UInt = #line
    ) async {
        await expectAsync(expression, to: equal(expectedValue), timeout: timeout, file: file, line: line)
    }
    
    /// Simplified version for expectations that look for error matching
    func expectAsync<T: Error & Equatable>(
        _ expression: @escaping () async throws -> Any,
        toThrow expectedError: T,
        timeout: DispatchTimeInterval = .seconds(1),
        file: FileString = #file,
        line: UInt = #line
    ) async {
        await awaitExpectation(description: "expectAsyncError") {
            do {
                let _ = try await expression()
                fail("Error was expected but the operation completed without errors", file: file, line: line)
            } catch {
                expect(file: file, line: line, error).to(matchError(expectedError))
            }
        }
    }
    
    /// Executes an asynchronous block and collects all values for testing
    func withAsyncValues<T>(
        _ asyncExpressions: [() async throws -> T]
    ) async throws -> [T] {
        var results: [T] = []
        for expression in asyncExpressions {
            results.append(try await expression())
        }
        return results
    }
} 