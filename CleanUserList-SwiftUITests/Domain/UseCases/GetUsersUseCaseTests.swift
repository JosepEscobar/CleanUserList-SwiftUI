import XCTest
import Nimble
@testable import CleanUserList_SwiftUI

@MainActor
class GetUsersUseCaseTests: XCTestCase {
    
    private var mockRepository: MockUserRepository!
    private var useCase: DefaultGetUsersUseCase!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        useCase = DefaultGetUsersUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        useCase = nil
        super.tearDown()
    }
    
    func testExecuteCallsRepositoryWithCorrectCount() async throws {
        // Given
        let expectedCount = 10
        mockRepository.usersToReturn = []
        
        // When
        _ = try await useCase.execute(count: expectedCount)
        
        // Then
        await awaitExpectation {
            expect(self.mockRepository.lastRequestedCount).to(equal(expectedCount))
            expect(self.mockRepository.getUsersCallCount).to(equal(1))
        }
    }
    
    func testExecuteReturnsCorrectUsers() async throws {
        // Given
        let expectedUsers = [
            User.mock(id: "1"),
            User.mock(id: "2")
        ]
        mockRepository.usersToReturn = expectedUsers
        
        // When
        let result = try await useCase.execute(count: 10)
        
        // Then
        await awaitExpectation {
            expect(result.count).to(equal(expectedUsers.count))
            expect(result[0].id).to(equal(expectedUsers[0].id))
            expect(result[1].id).to(equal(expectedUsers[1].id))
        }
    }
    
    func testExecutePropagatesToRepositoryError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
        mockRepository.errorToThrow = expectedError
        
        // When/Then
        await expectAsync({
            try await self.useCase.execute(count: 10)
        }, toThrow: expectedError)
    }
}

// MARK: - Test Doubles
extension GetUsersUseCaseTests {
    class MockUserRepository: UserRepository {
        var getUsersCallCount = 0
        var lastRequestedCount: Int = 0
        var usersToReturn: [User] = []
        var errorToThrow: Error?
        
        func getUsers(count: Int) async throws -> [User] {
            getUsersCallCount += 1
            lastRequestedCount = count
            
            if let error = errorToThrow {
                throw error
            }
            
            return usersToReturn
        }
        
        func saveUsers(_ users: [User]) async throws {}
        func deleteUser(withID id: String) async throws {}
        func searchUsers(query: String) async throws -> [User] { return [] }
        func getSavedUsers() async throws -> [User] { return [] }
        func loadMoreUsers(count: Int) async throws -> [User] { return [] }
        func shouldLoadMore(currentIndex: Int, totalCount: Int) -> Bool { return false }
    }
}
