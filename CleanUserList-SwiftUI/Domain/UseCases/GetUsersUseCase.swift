import Foundation
import Combine

protocol GetUsersUseCase {
    func execute(count: Int) -> AnyPublisher<[User], Error>
}

class DefaultGetUsersUseCase: GetUsersUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute(count: Int) -> AnyPublisher<[User], Error> {
        return repository.getUsers(count: count)
    }
} 