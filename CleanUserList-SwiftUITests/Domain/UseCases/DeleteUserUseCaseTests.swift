import XCTest
import Nimble
@testable import CleanUserList_SwiftUI

@MainActor
class DeleteUserUseCaseTests: XCTestCase {
    
    private var mockRepository: MockUserRepository!
    private var useCase: DefaultDeleteUserUseCase!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        useCase = DefaultDeleteUserUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        useCase = nil
        super.tearDown()
    }
    
    func testExecuteCallsRepositoryWithCorrectUserID() async throws {
        // Given
        let userID = "test-user-123"
        
        // When
        try await useCase.execute(userID: userID)
        
        // Then
        expect(self.mockRepository.deleteUserCallCount).to(equal(1))
        expect(self.mockRepository.lastDeletedUserID).to(equal(userID))
    }
    
    func testExecutePropagatesRepositoryError() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
        mockRepository.errorToThrow = expectedError
        
        // When/Then
        do {
            try await useCase.execute(userID: "any-id")
            fail("Expected error to be thrown")
        } catch {
            expect(error).to(matchError(expectedError))
        }
    }
}

// MARK: - Test Doubles
extension DeleteUserUseCaseTests {
    @MainActor
    class MockUserRepository: UserRepository {
        var deleteUserCallCount = 0
        var lastDeletedUserID: String = ""
        var errorToThrow: Error?
        
        func deleteUser(withID id: String) async throws {
            deleteUserCallCount += 1
            lastDeletedUserID = id
            
            if let error = errorToThrow {
                throw error
            }
        }
        
        func getUsers(count: Int) async throws -> [User] { return [] }
        func saveUsers(_ users: [User]) async throws {}
        func searchUsers(query: String) async throws -> [User] { return [] }
        func getSavedUsers() async throws -> [User] { return [] }
        func loadMoreUsers(count: Int) async throws -> [User] { return [] }
        func shouldLoadMore(currentIndex: Int, totalCount: Int) -> Bool { return false }
    }
} 