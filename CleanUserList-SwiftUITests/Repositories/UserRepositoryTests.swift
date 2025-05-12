import XCTest
import Nimble
@testable import CleanUserList_SwiftUI

@MainActor
class UserRepositoryTests: XCTestCase {
    
    func testGetUsers() async throws {
        // Given
        let mockAPIClient = MockAPIClient()
        let mockUserStorage = MockUserStorage()
        let userDTO = createUserDTO()
        
        let userResponse = UserResponse(results: [userDTO])
        mockAPIClient.getUsersResult = userResponse
        
        let repository = DefaultUserRepository(
            apiClient: mockAPIClient,
            userStorage: mockUserStorage
        )
        
        // When
        let users = try await repository.getUsers(count: 1)
        
        // Then
        expect(users).toNot(beEmpty(), description: "Users array should not be empty")
        expect(users.count).to(equal(1), description: "Expected exactly one user")
        expect(users.first).toNot(beNil(), description: "First user should not be nil")
        
        if let firstUser = users.first {
            expect(firstUser.id).to(equal("123"), description: "User ID should match expected value")
        }
        
        // Wait briefly to allow the background task that saves users to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        expect(mockUserStorage.savedUsers?.count).to(equal(1), description: "One user should be saved in storage")
    }
    
    func testSaveUsers() async throws {
        // Given
        let mockAPIClient = MockAPIClient()
        let mockUserStorage = MockUserStorage()
        
        let repository = DefaultUserRepository(
            apiClient: mockAPIClient,
            userStorage: mockUserStorage
        )
        
        let user = createUser()
        
        // When
        try await repository.saveUsers([user])
        
        // Then
        expect(mockUserStorage.savedUsers?.count).to(equal(1))
        expect(mockUserStorage.savedUsers?.first?.id).to(equal("123"))
    }
    
    func testDeleteUser() async throws {
        // Given
        let mockAPIClient = MockAPIClient()
        let mockUserStorage = MockUserStorage()
        
        let repository = DefaultUserRepository(
            apiClient: mockAPIClient,
            userStorage: mockUserStorage
        )
        
        // When
        try await repository.deleteUser(withID: "123")
        
        // Then
        expect(mockUserStorage.deletedUserID).to(equal("123"))
    }
    
    func testSearchUsers() async throws {
        // Given
        let mockAPIClient = MockAPIClient()
        let mockUserStorage = MockUserStorage()
        let user1 = createUser(id: "1", name: "John", surname: "Doe", email: "john@example.com")
        let user2 = createUser(id: "2", name: "Jane", surname: "Smith", email: "jane@example.com")
        
        mockUserStorage.getUsersResult = [user1, user2]
        
        let repository = DefaultUserRepository(
            apiClient: mockAPIClient,
            userStorage: mockUserStorage
        )
        
        // When
        let results = try await repository.searchUsers(query: "john")
        
        // Then
        expect(results.count).to(equal(1))
        expect(results.first?.id).to(equal("1"))
    }
    
    func testGetSavedUsers() async throws {
        // Given
        let mockAPIClient = MockAPIClient()
        let mockUserStorage = MockUserStorage()
        let user = createUser()
        
        mockUserStorage.getUsersResult = [user]
        
        let repository = DefaultUserRepository(
            apiClient: mockAPIClient,
            userStorage: mockUserStorage
        )
        
        // When
        let users = try await repository.getSavedUsers()
        
        // Then
        expect(users.count).to(equal(1))
        expect(users.first?.id).to(equal("123"))
    }
    
    // MARK: - Helper Methods
    
    private func createUser(id: String = "123", name: String = "John", surname: String = "Doe", email: String = "john.doe@example.com") -> User {
        return User(
            id: id,
            name: name,
            surname: surname,
            fullName: "\(name) \(surname)",
            email: email,
            phone: "123-456-7890",
            gender: "male",
            location: Location(
                street: "123 Main St",
                city: "New York",
                state: "NY"
            ),
            registeredDate: Date(),
            picture: Picture(
                large: URL(string: "https://example.com/large.jpg")!,
                medium: URL(string: "https://example.com/medium.jpg")!,
                thumbnail: URL(string: "https://example.com/thumbnail.jpg")!
            )
        )
    }
    
    private func createUserDTO() -> UserDTO {
        let user = createUser()
        return createUserDTO(from: user)
    }
    
    private func createUserDTO(from user: User) -> UserDTO {
        let nameDTO = NameDTO(title: "Mr", first: user.name, last: user.surname)
        let streetDTO = StreetDTO(number: 123, name: "Main St")
        let locationDTO = LocationDTO(street: streetDTO, city: user.location.city, state: user.location.state)
        let loginDTO = LoginDTO(uuid: user.id)
        let registeredDTO = RegisteredDTO(date: user.registeredDate)
        let pictureDTO = PictureDTO(
            large: user.picture.large.absoluteString,
            medium: user.picture.medium.absoluteString,
            thumbnail: user.picture.thumbnail.absoluteString
        )
        
        return UserDTO(
            gender: user.gender,
            name: nameDTO,
            location: locationDTO,
            email: user.email,
            login: loginDTO,
            registered: registeredDTO,
            phone: user.phone,
            picture: pictureDTO
        )
    }
}

// MARK: - Mocks

@MainActor
class MockAPIClient: APIClient {
    var getUsersResult: UserResponse?
    var getUsersError: Error?
    
    func getUsers(count: Int) async throws -> UserResponse {
        if let error = getUsersError {
            throw error
        }
        if let result = getUsersResult {
            return result
        }
        throw NSError(domain: "Test", code: -1)
    }
    
    func getUsersWithRetry(count: Int) async throws -> UserResponse {
        // In the mock, we simply delegate to the normal method without retries
        return try await getUsers(count: count)
    }
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        if let error = getUsersError {
            throw error
        }
        
        if T.self == UserResponse.self, let result = getUsersResult as? T {
            return result
        }
        
        throw NSError(domain: "Test", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unexpected request type: \(T.self)"])
    }
}

class MockUserStorage: UserStorage {
    var savedUsers: [User]?
    var deletedUserID: String?
    var getUsersResult: [User] = []
    var saveError: Error?
    var getError: Error?
    var deleteError: Error?
    
    func saveUsers(_ users: [User]) async throws {
        if let error = saveError {
            throw error
        }
        savedUsers = users
    }
    
    func getUsers() async throws -> [User] {
        if let error = getError {
            throw error
        }
        return getUsersResult
    }
    
    func deleteUser(withID id: String) async throws {
        if let error = deleteError {
            throw error
        }
        deletedUserID = id
    }
} 