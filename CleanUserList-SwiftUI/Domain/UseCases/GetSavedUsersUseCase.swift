import Foundation
import Combine

protocol GetSavedUsersUseCase {
    func execute() -> AnyPublisher<[User], Error>
}

class DefaultGetSavedUsersUseCase: GetSavedUsersUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute() -> AnyPublisher<[User], Error> {
        return repository.getSavedUsers()
    }
} 