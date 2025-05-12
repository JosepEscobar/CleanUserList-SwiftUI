@MainActor
protocol SearchUsersUseCase {
    func execute(query: String) async throws -> [User]
}

@MainActor
class DefaultSearchUsersUseCase: SearchUsersUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute(query: String) async throws -> [User] {
        return try await repository.searchUsers(query: query)
    }
} 