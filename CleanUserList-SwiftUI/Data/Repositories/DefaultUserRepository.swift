import Foundation

@MainActor
class DefaultUserRepository: UserRepository {
    private let apiClient: APIClient
    private let userStorage: UserStorage
    private var lastRequestedCount: Int = 0
    private var retryCount: Int = 0
    private let maxRetries: Int = 3
    private var isFirstLoad: Bool = true
    
    init(apiClient: APIClient, userStorage: UserStorage) {
        self.apiClient = apiClient
        self.userStorage = userStorage
    }
    
    func getUsers(count: Int) async throws -> [User] {
        self.lastRequestedCount = count
        
        do {
            // If it's the first load and more than 20 users are requested, load directly from the API
            if isFirstLoad && count >= 20 {
                isFirstLoad = false
                // Try to load directly from the API for faster initial response
                return try await fetchAndStoreMoreUsers(count: count)
            }
            
            // For normal loads, first check if we have saved users
            let savedUsers = try await getSavedUsers()
            
            // If there are saved users and they are enough, return them immediately
            // and update in the background
            if !savedUsers.isEmpty && savedUsers.count >= count / 2 {
                // Update in the background only if it's not the first load
                Task {
                    do {
                        _ = try await fetchAndStoreMoreUsers(count: count)
                    } catch {
                        print("Error updating users in the background: \(error)")
                    }
                }
                return savedUsers
            }
            
            // If there are not enough users or we need to load more
            isFirstLoad = false
            return try await fetchAndStoreMoreUsers(count: count)
        } catch {
            // If there's an error but we have saved users, return them
            let savedUsers = try? await getSavedUsers()
            if let users = savedUsers, !users.isEmpty {
                return users
            }
            throw error
        }
    }
    
    private func fetchAndStoreMoreUsers(count: Int) async throws -> [User] {
        do {
            // Load with reduced timeout for the first load for better reactivity
            let response = try await apiClient.getUsersWithRetry(count: count)
            let newUsers = response.results.map { $0.toDomain() }
            
            // Save users in a separate task to avoid blocking the UI
            if !newUsers.isEmpty {
                Task {
                    do {
                        try await saveUsers(newUsers)
                    } catch {
                        print("Error saving users: \(error)")
                    }
                }
            }
            
            retryCount = 0 // Reset the retry counter
            return newUsers
        } catch let apiError as APIError {
            // Retry in case of network errors
            if case .networkError = apiError, retryCount < maxRetries {
                retryCount += 1
                // Wait less time on the first retry for better reactivity
                let waitTime = isFirstLoad ? 
                    UInt64(1_000_000_000) : // 1 second if it's the first load
                    UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000)
                    
                try await Task.sleep(nanoseconds: waitTime)
                return try await fetchAndStoreMoreUsers(count: count)
            }
            throw apiError
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
