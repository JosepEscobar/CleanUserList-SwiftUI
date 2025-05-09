@MainActor
protocol DeleteUserUseCase {
    func execute(userID: String) async throws
}

@MainActor
class DefaultDeleteUserUseCase: DeleteUserUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute(userID: String) async throws {
        try await repository.deleteUser(withID: userID)
    }
} 
