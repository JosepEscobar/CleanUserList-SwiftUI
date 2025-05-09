@MainActor
protocol GetUsersUseCase {
    func execute(count: Int) async throws -> [User]
}

@MainActor
class DefaultGetUsersUseCase: GetUsersUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute(count: Int) async throws -> [User] {
        return try await repository.getUsers(count: count)
    }
} 
