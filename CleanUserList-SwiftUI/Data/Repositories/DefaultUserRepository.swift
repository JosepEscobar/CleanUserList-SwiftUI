import Foundation
import Combine

class DefaultUserRepository: UserRepository {
    private let apiClient: APIClient
    private let userStorage: UserStorage
    
    init(apiClient: APIClient, userStorage: UserStorage) {
        self.apiClient = apiClient
        self.userStorage = userStorage
    }
    
    func getUsers(count: Int) -> AnyPublisher<[User], Error> {
        return apiClient.getUsers(count: count)
            .map { response in
                response.results.map { $0.toDomain() }
            }
            .flatMap { [weak self] users -> AnyPublisher<[User], Error> in
                guard let self = self else {
                    return Fail(error: RepositoryError.unknown).eraseToAnyPublisher()
                }
                
                return self.saveUsers(users)
                    .map { users }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func saveUsers(_ users: [User]) -> AnyPublisher<Void, Error> {
        return userStorage.saveUsers(users)
    }
    
    func deleteUser(withID id: String) -> AnyPublisher<Void, Error> {
        return userStorage.deleteUser(withID: id)
    }
    
    func searchUsers(query: String) -> AnyPublisher<[User], Error> {
        return getSavedUsers()
            .map { users in
                let lowercasedQuery = query.lowercased()
                return users.filter { user in
                    user.fullName.lowercased().contains(lowercasedQuery) ||
                    user.email.lowercased().contains(lowercasedQuery)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getSavedUsers() -> AnyPublisher<[User], Error> {
        return userStorage.getUsers()
    }
}

enum RepositoryError: Error {
    case unknown
} 