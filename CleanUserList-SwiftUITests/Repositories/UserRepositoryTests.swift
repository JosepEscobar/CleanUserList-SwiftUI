import XCTest
import Combine
@testable import CleanUserList_SwiftUI

final class UserRepositoryTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testGetUsersSuccess() {
        // Given
        let expectedUsers = [createTestUser(id: "1"), createTestUser(id: "2")]
        let mockAPIClient = MockAPIClient()
        let mockUserStorage = MockUserStorage()
        let repository = DefaultUserRepository(apiClient: mockAPIClient, userStorage: mockUserStorage)
        
        let response = UserResponse(results: expectedUsers.map { createUserDTO(from: $0) })
        mockAPIClient.getUsersResult = .success(response)
        
        // When
        let expectation = expectation(description: "Get users completes")
        var resultUsers: [User]?
        var resultError: Error?
        
        repository.getUsers(count: 10)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        resultError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { users in
                    resultUsers = users
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertEqual(resultUsers?.count, expectedUsers.count)
        XCTAssertEqual(resultUsers?.first?.id, expectedUsers.first?.id)
    }
    
    func testSaveUsersSuccess() {
        // Given
        let users = [createTestUser(id: "1"), createTestUser(id: "2")]
        let mockAPIClient = MockAPIClient()
        let mockUserStorage = MockUserStorage()
        let repository = DefaultUserRepository(apiClient: mockAPIClient, userStorage: mockUserStorage)
        
        // When
        let expectation = expectation(description: "Save users completes")
        var resultError: Error?
        
        repository.saveUsers(users)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        resultError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertEqual(mockUserStorage.savedUsers?.count, users.count)
    }
    
    func testDeleteUserSuccess() {
        // Given
        let userID = "1"
        let mockAPIClient = MockAPIClient()
        let mockUserStorage = MockUserStorage()
        let repository = DefaultUserRepository(apiClient: mockAPIClient, userStorage: mockUserStorage)
        
        // When
        let expectation = expectation(description: "Delete user completes")
        var resultError: Error?
        
        repository.deleteUser(withID: userID)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        resultError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertEqual(mockUserStorage.deletedUserID, userID)
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser(id: String) -> User {
        return User(
            id: id,
            name: "John",
            surname: "Doe",
            fullName: "John Doe",
            email: "john.doe@example.com",
            phone: "123-456-7890",
            gender: "male",
            location: Location(street: "123 Main St", city: "Anytown", state: "State"),
            registeredDate: Date(),
            picture: Picture(
                large: URL(string: "https://randomuser.me/api/portraits/men/1.jpg")!,
                medium: URL(string: "https://randomuser.me/api/portraits/med/men/1.jpg")!,
                thumbnail: URL(string: "https://randomuser.me/api/portraits/thumb/men/1.jpg")!
            )
        )
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

class MockAPIClient: APIClient {
    var getUsersResult: Result<UserResponse, Error> = .failure(NSError(domain: "Test", code: -1))
    
    func getUsers(count: Int) -> AnyPublisher<UserResponse, Error> {
        return getUsersResult.publisher.eraseToAnyPublisher()
    }
}

class MockUserStorage: UserStorage {
    var savedUsers: [User]?
    var deletedUserID: String?
    var getUsersResult: Result<[User], Error> = .success([])
    
    func saveUsers(_ users: [User]) -> AnyPublisher<Void, Error> {
        savedUsers = users
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getUsers() -> AnyPublisher<[User], Error> {
        return getUsersResult.publisher.eraseToAnyPublisher()
    }
    
    func deleteUser(withID id: String) -> AnyPublisher<Void, Error> {
        deletedUserID = id
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
} 