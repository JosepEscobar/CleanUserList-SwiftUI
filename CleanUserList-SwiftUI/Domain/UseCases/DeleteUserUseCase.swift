import Foundation
import Combine

protocol DeleteUserUseCase {
    func execute(userID: String) -> AnyPublisher<Void, Error>
}

class DefaultDeleteUserUseCase: DeleteUserUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute(userID: String) -> AnyPublisher<Void, Error> {
        return repository.deleteUser(withID: userID)
    }
} 