import XCTest
import Combine
@testable import CleanUserList_SwiftUI

final class UserListViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testLoadUsersSuccess() {
        // Given
        let expectedUsers = [createTestUser(id: "1"), createTestUser(id: "2")]
        let mockGetUsersUseCase = MockGetUsersUseCase(result: .success(expectedUsers))
        let mockGetSavedUsersUseCase = MockGetSavedUsersUseCase(result: .success([]))
        let mockDeleteUserUseCase = MockDeleteUserUseCase()
        let mockSearchUsersUseCase = MockSearchUsersUseCase()
        let testQueue = DispatchQueue.immediate
        
        let viewModel = UserListViewModel(
            getUsersUseCase: mockGetUsersUseCase,
            getSavedUsersUseCase: mockGetSavedUsersUseCase,
            deleteUserUseCase: mockDeleteUserUseCase,
            searchUsersUseCase: mockSearchUsersUseCase,
            scheduler: testQueue
        )
        
        // Se inicializa llamando a loadSavedUsers, lo reseteamos para control de prueba
        viewModel.reset()
        
        let expectation = self.expectation(description: "Users loaded")
        
        // When
        viewModel.$users
            .dropFirst() // Ignoramos el valor inicial de users (vacío)
            .sink { users in
                if users.count == expectedUsers.count {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadMoreUsers(count: 2)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(viewModel.users.count, expectedUsers.count)
        XCTAssertEqual(viewModel.users[0].id, expectedUsers[0].id)
        XCTAssertEqual(viewModel.filteredUsers.count, expectedUsers.count)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadUsersFailure() {
        // Given
        let expectedError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error loading users"])
        let mockGetUsersUseCase = MockGetUsersUseCase(result: .failure(expectedError))
        let mockGetSavedUsersUseCase = MockGetSavedUsersUseCase(result: .success([]))
        let mockDeleteUserUseCase = MockDeleteUserUseCase()
        let mockSearchUsersUseCase = MockSearchUsersUseCase()
        let testQueue = DispatchQueue.immediate
        
        let viewModel = UserListViewModel(
            getUsersUseCase: mockGetUsersUseCase,
            getSavedUsersUseCase: mockGetSavedUsersUseCase,
            deleteUserUseCase: mockDeleteUserUseCase,
            searchUsersUseCase: mockSearchUsersUseCase,
            scheduler: testQueue
        )
        
        // Se inicializa llamando a loadSavedUsers, lo reseteamos para control de prueba
        viewModel.reset()
        
        let expectation = self.expectation(description: "Error loaded")
        
        // When
        viewModel.$errorMessage
            .dropFirst() // Ignoramos el valor inicial de errorMessage (nil)
            .compactMap { $0 }
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.loadMoreUsers(count: 2)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testDeleteUser() {
        // Given
        let users = [createTestUser(id: "1"), createTestUser(id: "2")]
        let mockGetUsersUseCase = MockGetUsersUseCase(result: .success(users))
        let mockGetSavedUsersUseCase = MockGetSavedUsersUseCase(result: .success(users))
        let mockDeleteUserUseCase = MockDeleteUserUseCase()
        let mockSearchUsersUseCase = MockSearchUsersUseCase()
        let testQueue = DispatchQueue.immediate
        
        let viewModel = UserListViewModel(
            getUsersUseCase: mockGetUsersUseCase,
            getSavedUsersUseCase: mockGetSavedUsersUseCase,
            deleteUserUseCase: mockDeleteUserUseCase,
            searchUsersUseCase: mockSearchUsersUseCase,
            scheduler: testQueue
        )
        
        let expectation = self.expectation(description: "User deleted")
        
        // When
        viewModel.$users
            .dropFirst(2) // Ignoramos valores iniciales
            .sink { users in
                if users.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.deleteUser(withID: "1")
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(viewModel.users.count, 1)
        XCTAssertEqual(viewModel.users[0].id, "2")
        XCTAssertEqual(mockDeleteUserUseCase.deletedUserID, "1")
    }
    
    func testSearchUsers() {
        // Given
        let users = [
            createTestUser(id: "1", name: "John", surname: "Doe", email: "john@example.com"),
            createTestUser(id: "2", name: "Jane", surname: "Smith", email: "jane@example.com")
        ]
        let mockGetUsersUseCase = MockGetUsersUseCase(result: .success(users))
        let mockGetSavedUsersUseCase = MockGetSavedUsersUseCase(result: .success(users))
        
        let filteredUsers = [users[0]] // Solo John Doe
        let mockSearchUsersUseCase = MockSearchUsersUseCase(result: .success(filteredUsers))
        
        let mockDeleteUserUseCase = MockDeleteUserUseCase()
        let testQueue = DispatchQueue.immediate
        
        let viewModel = UserListViewModel(
            getUsersUseCase: mockGetUsersUseCase,
            getSavedUsersUseCase: mockGetSavedUsersUseCase,
            deleteUserUseCase: mockDeleteUserUseCase,
            searchUsersUseCase: mockSearchUsersUseCase,
            scheduler: testQueue
        )
        
        let expectation = self.expectation(description: "Search filter applied")
        
        // When
        viewModel.$filteredUsers
            .dropFirst(2) // Ignoramos valores iniciales
            .sink { filteredUsers in
                if filteredUsers.count == 1 && filteredUsers[0].id == "1" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.searchText = "John"
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(viewModel.filteredUsers.count, 1)
        XCTAssertEqual(viewModel.filteredUsers[0].id, "1")
        XCTAssertEqual(mockSearchUsersUseCase.lastSearchQuery, "John")
    }
    
    // MARK: - Helper Methods
    
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
    private let result: Result<[User], Error>
    
    init(result: Result<[User], Error>) {
        self.result = result
    }
    
    func execute(count: Int) -> AnyPublisher<[User], Error> {
        return result.publisher.eraseToAnyPublisher()
    }
}

class MockGetSavedUsersUseCase: GetSavedUsersUseCase {
    private let result: Result<[User], Error>
    
    init(result: Result<[User], Error>) {
        self.result = result
    }
    
    func execute() -> AnyPublisher<[User], Error> {
        return result.publisher.eraseToAnyPublisher()
    }
}

class MockDeleteUserUseCase: DeleteUserUseCase {
    var deletedUserID: String?
    
    func execute(userID: String) -> AnyPublisher<Void, Error> {
        deletedUserID = userID
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockSearchUsersUseCase: SearchUsersUseCase {
    private let result: Result<[User], Error>
    var lastSearchQuery: String?
    
    init(result: Result<[User], Error> = .success([])) {
        self.result = result
    }
    
    func execute(query: String) -> AnyPublisher<[User], Error> {
        lastSearchQuery = query
        return result.publisher.eraseToAnyPublisher()
    }
}

// MARK: - Immediate Dispatch Queue para tests
extension DispatchQueue {
    static var immediate: DispatchQueue {
        return Immediate.shared
    }
    
    private final class Immediate: DispatchQueue {
        static let shared = Immediate()
        
        private init() {
            super.init(label: "com.immediate.queue")
        }
        
        override func async(execute work: @escaping () -> Void) {
            work()
        }
    }
} 