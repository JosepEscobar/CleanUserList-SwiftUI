@MainActor
protocol GetSavedUsersUseCase {
    func execute() async throws -> [User]
}

@MainActor
class DefaultGetSavedUsersUseCase: GetSavedUsersUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> [User] {
        return try await repository.getSavedUsers()
    }
} 
