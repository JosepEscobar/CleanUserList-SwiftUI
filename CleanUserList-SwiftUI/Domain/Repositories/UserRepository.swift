import Foundation
import Combine

protocol UserRepository {
    func getUsers(count: Int) -> AnyPublisher<[User], Error>
    func saveUsers(_ users: [User]) -> AnyPublisher<Void, Error>
    func deleteUser(withID id: String) -> AnyPublisher<Void, Error>
    func searchUsers(query: String) -> AnyPublisher<[User], Error>
    func getSavedUsers() -> AnyPublisher<[User], Error>
} 