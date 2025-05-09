import XCTest
@testable import CleanUserList_SwiftUI

@MainActor
class UserListViewModelTests: XCTestCase {
    
    func testLoadMoreUsers() async {
        // Given
        let users = [createTestUser(id: "1"), createTestUser(id: "2")]
        let mockGetUsersUseCase = MockGetUsersUseCase(users: users)
        let mockGetSavedUsersUseCase = MockGetSavedUsersUseCase(users: [])
        let mockDeleteUserUseCase = MockDeleteUserUseCase()
        let mockSearchUsersUseCase = MockSearchUsersUseCase(users: [])
        
        let viewModel = UserListViewModel(
            getUsersUseCase: mockGetUsersUseCase,
            getSavedUsersUseCase: mockGetSavedUsersUseCase,
            deleteUserUseCase: mockDeleteUserUseCase,
            searchUsersUseCase: mockSearchUsersUseCase
        )
        
        // When
        viewModel.loadMoreUsers(count: 2)
        
        await Task.yield()
        
        // Then
        XCTAssertEqual(viewModel.users.count, 2)
        XCTAssertEqual(viewModel.filteredUsers.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.hasLoadedUsers)
    }
    
    func testLoadMoreUsersError() async {
        // Given
        let mockError = NSError(domain: "test", code: -1)
        let mockGetUsersUseCase = MockGetUsersUseCase(error: mockError)
        let mockGetSavedUsersUseCase = MockGetSavedUsersUseCase(users: [])
        let mockDeleteUserUseCase = MockDeleteUserUseCase()
        let mockSearchUsersUseCase = MockSearchUsersUseCase(users: [])
        
        let viewModel = UserListViewModel(
            getUsersUseCase: mockGetUsersUseCase,
            getSavedUsersUseCase: mockGetSavedUsersUseCase,
            deleteUserUseCase: mockDeleteUserUseCase,
            searchUsersUseCase: mockSearchUsersUseCase
        )
        
        // When
        viewModel.loadMoreUsers(count: 2)
        
        await Task.yield()
        
        // Then
        XCTAssertEqual(viewModel.users.count, 0)
        XCTAssertEqual(viewModel.filteredUsers.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.hasLoadedUsers)
    }
    
    func testLoadSavedUsers() async {
        // Given
        let users = [createTestUser(id: "1"), createTestUser(id: "2")]
        let mockGetUsersUseCase = MockGetUsersUseCase(users: [])
        let mockGetSavedUsersUseCase = MockGetSavedUsersUseCase(users: users)
        let mockDeleteUserUseCase = MockDeleteUserUseCase()
        let mockSearchUsersUseCase = MockSearchUsersUseCase(users: [])
        
        let viewModel = UserListViewModel(
            getUsersUseCase: mockGetUsersUseCase,
            getSavedUsersUseCase: mockGetSavedUsersUseCase,
            deleteUserUseCase: mockDeleteUserUseCase,
            searchUsersUseCase: mockSearchUsersUseCase
        )
        
        // When
        viewModel.loadSavedUsers()
        
        await Task.yield()
        
        // Then
        XCTAssertEqual(viewModel.users.count, 2)
        XCTAssertEqual(viewModel.filteredUsers.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.hasLoadedUsers)
    }
    
    func testLoadSavedUsersEmpty() async {
        // Given
        let mockGetUsersUseCase = MockGetUsersUseCase(users: [createTestUser(id: "1")])
        let mockGetSavedUsersUseCase = MockGetSavedUsersUseCase(users: [])
        let mockDeleteUserUseCase = MockDeleteUserUseCase()
        let mockSearchUsersUseCase = MockSearchUsersUseCase(users: [])
        
        let viewModel = UserListViewModel(
            getUsersUseCase: mockGetUsersUseCase,
            getSavedUsersUseCase: mockGetSavedUsersUseCase,
            deleteUserUseCase: mockDeleteUserUseCase,
            searchUsersUseCase: mockSearchUsersUseCase
        )
        
        // When
        viewModel.loadSavedUsers()
        
        await Task.yield()
        await Task.sleep(nanoseconds: 500_000_000) 
        
        // Then
        XCTAssertEqual(viewModel.users.count, 1)
        XCTAssertEqual(viewModel.filteredUsers.count, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.hasLoadedUsers)
    }
    
    func testDeleteUser() async {
        // Given
        let users = [createTestUser(id: "1"), createTestUser(id: "2")]
        let mockGetUsersUseCase = MockGetUsersUseCase(users: [])
        let mockGetSavedUsersUseCase = MockGetSavedUsersUseCase(users: users)
        let mockDeleteUserUseCase = MockDeleteUserUseCase()
        let mockSearchUsersUseCase = MockSearchUsersUseCase(users: [])
        
        let viewModel = UserListViewModel(
            getUsersUseCase: mockGetUsersUseCase,
            getSavedUsersUseCase: mockGetSavedUsersUseCase,
            deleteUserUseCase: mockDeleteUserUseCase,
            searchUsersUseCase: mockSearchUsersUseCase
        )
        
        viewModel.loadSavedUsers()
        await Task.yield()
        
        // When
        viewModel.deleteUser(withID: "1")
        
        await Task.yield()
        
        // Then
        XCTAssertEqual(viewModel.users.count, 1)
        XCTAssertEqual(viewModel.filteredUsers.count, 1)
        XCTAssertEqual(viewModel.users.first?.id, "2")
        XCTAssertEqual(mockDeleteUserUseCase.deletedUserID, "1")
    }
    
    func testSearchUsers() async {
        // Given
        let users = [
            createTestUser(id: "1", name: "John", surname: "Doe"),
            createTestUser(id: "2", name: "Jane", surname: "Smith")
        ]
        let mockGetUsersUseCase = MockGetUsersUseCase(users: [])
        let mockGetSavedUsersUseCase = MockGetSavedUsersUseCase(users: users)
        let mockDeleteUserUseCase = MockDeleteUserUseCase()
        let mockSearchUsersUseCase = MockSearchUsersUseCase(
            searchHandler: { query in
                return users.filter { $0.fullName.lowercased().contains(query.lowercased()) }
            }
        )
        
        let viewModel = UserListViewModel(
            getUsersUseCase: mockGetUsersUseCase,
            getSavedUsersUseCase: mockGetSavedUsersUseCase,
            deleteUserUseCase: mockDeleteUserUseCase,
            searchUsersUseCase: mockSearchUsersUseCase
        )
        
        viewModel.loadSavedUsers()
        await Task.yield()
        
        // When
        viewModel.searchText = "john"
        
        await Task.yield()
        await Task.sleep(nanoseconds: 400_000_000)
        
        // Then
        XCTAssertEqual(viewModel.filteredUsers.count, 1)
        XCTAssertEqual(viewModel.filteredUsers.first?.id, "1")
    }
    
    private func createTestUser(id: String, name: String = "John", surname: String = "Doe", email: String = "john@example.com") -> User {
        return User(
            id: id,
            name: name,
            surname: surname,
            fullName: "\(name) \(surname)",
            email: email,
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
}

// MARK: - Mocks

class MockGetUsersUseCase: GetUsersUseCase {
    private let users: [User]
    private let error: Error?
    
    init(users: [User] = [], error: Error? = nil) {
        self.users = users
        self.error = error
    }
    
    func execute(count: Int) async throws -> [User] {
        if let error = error {
            throw error
        }
        return users
    }
}

class MockGetSavedUsersUseCase: GetSavedUsersUseCase {
    private let users: [User]
    private let error: Error?
    
    init(users: [User] = [], error: Error? = nil) {
        self.users = users
        self.error = error
    }
    
    func execute() async throws -> [User] {
        if let error = error {
            throw error
        }
        return users
    }
}

class MockDeleteUserUseCase: DeleteUserUseCase {
    var deletedUserID: String?
    var error: Error?
    
    func execute(userID: String) async throws {
        if let error = error {
            throw error
        }
        deletedUserID = userID
    }
}

class MockSearchUsersUseCase: SearchUsersUseCase {
    private let users: [User]
    private let error: Error?
    private let searchHandler: ((String) -> [User])?
    
    init(users: [User] = [], error: Error? = nil, searchHandler: ((String) -> [User])? = nil) {
        self.users = users
        self.error = error
        self.searchHandler = searchHandler
    }
    
    func execute(query: String) async throws -> [User] {
        if let error = error {
            throw error
        }
        if let searchHandler = searchHandler {
            return searchHandler(query)
        }
        return users
    }
} 