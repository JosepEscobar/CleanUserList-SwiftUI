import XCTest
import Nimble
@testable import CleanUserList_SwiftUI

@MainActor
class DefaultUserRepositoryTests: XCTestCase {
    
    private var mockAPIClient: MockAPIClient!
    private var mockStorage: MockUserStorage!
    private var repository: DefaultUserRepository!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        mockStorage = MockUserStorage()
        repository = DefaultUserRepository(apiClient: mockAPIClient, userStorage: mockStorage)
    }
    
    override func tearDown() {
        mockAPIClient = nil
        mockStorage = nil
        repository = nil
        super.tearDown()
    }
    
    // MARK: - getUsers Tests
    
    func testGetUsersFirstLoadFetchesFromAPIIfCountIsLarge() async throws {
        // Given
        let testUsers = createTestUsers(count: 3)
        let userResponseDTO = UserResponse(results: testUsers.map { user in 
            createUserDTOFromUser(user)
        })
        mockAPIClient.getUsersResponse = userResponseDTO
        
        // When
        let result = try await repository.getUsers(count: 20)
        
        // Then
        await awaitExpectation {
            expect(self.mockAPIClient.getUsersWithRetryCallCount).to(equal(1))
            expect(self.mockAPIClient.lastRequestedCount).to(equal(20))
            expect(result.count).to(equal(testUsers.count))
            expect(result[0].id).to(equal(testUsers[0].id))
        }
    }
    
    func testGetUsersChecksSavedUsersFirst() async throws {
        // Given
        let savedUsers = createTestUsers(count: 5)
        mockStorage.savedUsers = savedUsers
        
        // When
        let result = try await repository.getUsers(count: 10)
        
        // Then
        await awaitExpectation {
            expect(self.mockStorage.getUsersCallCount).to(equal(1))
            expect(result.count).to(equal(savedUsers.count))
        }
    }
    
    func testGetUsersReturnsAPIResultsAndSavesThem() async throws {
        // Given
        let testUsers = createTestUsers(count: 3)
        let userResponseDTO = UserResponse(results: testUsers.map { user in 
            createUserDTOFromUser(user)
        })
        mockAPIClient.getUsersResponse = userResponseDTO
        mockStorage.savedUsers = []
        
        // When
        let result = try await repository.getUsers(count: 10)
        
        // Then
        // Wait for the background task to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Usando nuestras extensiones para expectativas asíncronas
        await expectAsync({ result.count }, toEqual: testUsers.count)
        await expectAsync({ self.mockStorage.saveUsersCallCount }, toEqual: 1)
        await expectAsync({ self.mockStorage.lastSavedUsers.count }, toEqual: testUsers.count)
    }
    
    func testGetUsersReturnsStoredUsersOnAPIError() async throws {
        // Given
        let savedUsers = createTestUsers(count: 5)
        mockStorage.savedUsers = savedUsers
        mockAPIClient.errorToThrow = NSError(domain: "test", code: 404, userInfo: nil)
        
        // When
        let result = try await repository.getUsers(count: 10)
        
        // Then
        await awaitExpectation {
            expect(result.count).to(equal(savedUsers.count))
            expect(result[0].id).to(equal(savedUsers[0].id))
        }
    }
    
    func testGetUsersThrowsErrorWhenBothAPICLientAndStorageFail() async throws {
        // Given
        let error = NSError(domain: "test", code: 404, userInfo: nil)
        mockAPIClient.errorToThrow = error
        mockStorage.errorToThrow = error
        
        // When/Then - Usando la extensión para expectativas asíncronas con errores
        await expectAsync({
            try await self.repository.getUsers(count: 10)
        }, toThrow: error)
    }
    
    // MARK: - searchUsers Tests
    
    func testSearchUsersCallsStorageAndFilters() async throws {
        // Given
        let savedUsers = [
            User.mock(name: "John", surname: "Doe", email: "john@example.com"),
            User.mock(name: "Jane", surname: "Doe", email: "jane@example.com"),
            User.mock(name: "Alice", surname: "Smith", email: "alice@example.com")
        ]
        mockStorage.savedUsers = savedUsers
        
        // When
        let result = try await repository.searchUsers(query: "doe")
        
        // Then - Usando nuestras extensiones para expectativas asíncronas
        // Combinando múltiples expectativas en una única verificación
        await awaitExpectation {
            expect(self.mockStorage.getUsersCallCount).to(equal(1))
            expect(result.count).to(equal(2))
            expect(result.map { $0.name }.sorted()).to(equal(["Jane", "John"]))
        }
    }
    
    // MARK: - deleteUser Tests
    
    func testDeleteUserCallsStorage() async throws {
        // Given
        let userID = "test-id-123"
        
        // When
        try await repository.deleteUser(withID: userID)
        
        // Then
        await awaitExpectation {
            expect(self.mockStorage.deleteUserCallCount).to(equal(1))
            expect(self.mockStorage.lastDeletedUserID).to(equal(userID))
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestUsers(count: Int) -> [User] {
        return (0..<count).map { index in
            User.mock(id: "id-\(index)", name: "User \(index)")
        }
    }
    
    // Helper para crear un UserDTO a partir de un User
    private func createUserDTOFromUser(_ user: User) -> UserDTO {
        return UserDTO(
            gender: user.gender,
            name: NameDTO(
                title: "Mr",
                first: user.name, 
                last: user.surname
            ),
            location: LocationDTO(
                street: StreetDTO(
                    number: 123, 
                    name: "Main St"
                ),
                city: user.location.city,
                state: user.location.state
            ),
            email: user.email,
            login: LoginDTO(uuid: user.id),
            registered: RegisteredDTO(date: user.registeredDate),
            phone: user.phone,
            picture: PictureDTO(
                large: user.picture.large.absoluteString,
                medium: user.picture.medium.absoluteString,
                thumbnail: user.picture.thumbnail.absoluteString
            )
        )
    }
}

// MARK: - Test Doubles
extension DefaultUserRepositoryTests {
    class MockAPIClient: APIClient {
        var getUsersWithRetryCallCount = 0
        var lastRequestedCount: Int = 0
        var getUsersResponse: UserResponse = UserResponse(results: [])
        var errorToThrow: Error?
        
        func getUsers(count: Int) async throws -> UserResponse {
            lastRequestedCount = count
            
            if let error = errorToThrow {
                throw error
            }
            
            return getUsersResponse
        }
        
        func getUsersWithRetry(count: Int) async throws -> UserResponse {
            getUsersWithRetryCallCount += 1
            return try await getUsers(count: count)
        }
        
        func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
            if let error = errorToThrow {
                throw error
            }
            
            if T.self == UserResponse.self {
                if let response = getUsersResponse as? T {
                    return response
                } else {
                    throw APIError.unknown("Could not convert getUsersResponse to requested type \(T.self)")
                }
            }
            
            fatalError("Unexpected request for type \(T.self)")
        }
    }
    
    class MockUserStorage: UserStorage {
        var getUsersCallCount = 0
        var saveUsersCallCount = 0
        var deleteUserCallCount = 0
        var lastSavedUsers: [User] = []
        var lastDeletedUserID: String = ""
        var savedUsers: [User] = []
        var errorToThrow: Error?
        
        func getUsers() async throws -> [User] {
            getUsersCallCount += 1
            
            if let error = errorToThrow {
                throw error
            }
            
            return savedUsers
        }
        
        func saveUsers(_ users: [User]) async throws {
            saveUsersCallCount += 1
            lastSavedUsers = users
            
            if let error = errorToThrow {
                throw error
            }
        }
        
        func deleteUser(withID id: String) async throws {
            deleteUserCallCount += 1
            lastDeletedUserID = id
            
            if let error = errorToThrow {
                throw error
            }
        }
    }
} 