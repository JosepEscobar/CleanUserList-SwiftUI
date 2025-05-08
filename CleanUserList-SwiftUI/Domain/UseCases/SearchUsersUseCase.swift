import Foundation
import Combine

protocol SearchUsersUseCase {
    func execute(query: String) -> AnyPublisher<[User], Error>
}

class DefaultSearchUsersUseCase: SearchUsersUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute(query: String) -> AnyPublisher<[User], Error> {
        return repository.searchUsers(query: query)
    }
} 