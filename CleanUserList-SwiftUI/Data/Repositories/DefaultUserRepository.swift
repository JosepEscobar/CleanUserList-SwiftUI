import Foundation

@MainActor
class DefaultUserRepository: UserRepository {
    private let apiClient: APIClient
    private let userStorage: UserStorage
    private var lastRequestedCount: Int = 0
    
    init(apiClient: APIClient, userStorage: UserStorage) {
        self.apiClient = apiClient
        self.userStorage = userStorage
    }
    
    func getUsers(count: Int) async throws -> [User] {
        do {
            self.lastRequestedCount = count
            
            let response = try await apiClient.getUsers(count: count)
            let users = response.results.map { $0.toDomain() }
            
            try await saveUsers(users)
            
            return users
        } catch {
            throw error
        }
    }
    
    func saveUsers(_ users: [User]) async throws {
        try await userStorage.saveUsers(users)
    }
    
    func deleteUser(withID id: String) async throws {
        try await userStorage.deleteUser(withID: id)
    }
    
    func searchUsers(query: String) async throws -> [User] {
        let users = try await getSavedUsers()
        
        let lowercasedQuery = query.lowercased()
        return users.filter { user in
            user.fullName.lowercased().contains(lowercasedQuery) ||
            user.email.lowercased().contains(lowercasedQuery)
        }
    }
    
    func getSavedUsers() async throws -> [User] {
        return try await userStorage.getUsers()
    }
}

enum RepositoryError: Error {
    case unknown
} 