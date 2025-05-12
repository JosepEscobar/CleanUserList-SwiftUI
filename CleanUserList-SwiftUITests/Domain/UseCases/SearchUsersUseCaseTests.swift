import XCTest
import Nimble
@testable import CleanUserList_SwiftUI

@MainActor
class SearchUsersUseCaseTests: XCTestCase {
    
    private var mockRepository: MockUserRepository!
    private var useCase: DefaultSearchUsersUseCase!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        useCase = DefaultSearchUsersUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        useCase = nil
        super.tearDown()
    }
    
    func testExecuteCallsRepositoryWithCorrectQuery() async throws {
        // Given
        let query = "test query"
        mockRepository.usersToReturn = []
        
        // When
        _ = try await useCase.execute(query: query)
        
        // Then
        expect(self.mockRepository.lastSearchQuery).to(equal(query))
        expect(self.mockRepository.searchUsersCallCount).to(equal(1))
    }
    
    func testExecuteReturnsMatchingUsers() async throws {
        // Given
        let matchingUsers = [
            User.mock(name: "John", surname: "Doe"),
            User.mock(name: "Jane", surname: "Doe")
        ]
        mockRepository.usersToReturn = matchingUsers
        
        // When
        let result = try await useCase.execute(query: "Doe")
        
        // Then
        expect(result.count).to(equal(matchingUsers.count))
        expect(result).to(equal(matchingUsers))
    }
    
    func testExecutePropagatesRepositoryError() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
        mockRepository.errorToThrow = expectedError
        
        // When/Then
        do {
            _ = try await useCase.execute(query: "test")
            fail("Expected error to be thrown")
        } catch {
            expect(error).to(matchError(expectedError))
        }
    }
}

// MARK: - Test Doubles
extension SearchUsersUseCaseTests {
    @MainActor
    class MockUserRepository: UserRepository {
        var searchUsersCallCount = 0
        var lastSearchQuery: String = ""
        var usersToReturn: [User] = []
        var errorToThrow: Error?
        
        func searchUsers(query: String) async throws -> [User] {
            searchUsersCallCount += 1
            lastSearchQuery = query
            
            if let error = errorToThrow {
                throw error
            }
            
            return usersToReturn
        }
        
        func getUsers(count: Int) async throws -> [User] { return [] }
        func saveUsers(_ users: [User]) async throws {}
        func deleteUser(withID id: String) async throws {}
        func getSavedUsers() async throws -> [User] { return [] }
        func loadMoreUsers(count: Int) async throws -> [User] { return [] }
        func shouldLoadMore(currentIndex: Int, totalCount: Int) -> Bool { return false }
    }
} 