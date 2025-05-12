@MainActor
protocol LoadMoreUsersUseCase {
    func execute(count: Int) async throws -> [User]
}

@MainActor
class DefaultLoadMoreUsersUseCase: LoadMoreUsersUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute(count: Int) async throws -> [User] {
        // Para paginación siempre usamos el método específico del repositorio
        return try await repository.loadMoreUsers(count: count)
    }
} 