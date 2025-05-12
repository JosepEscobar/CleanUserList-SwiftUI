import Foundation

@MainActor
class DefaultUserRepository: UserRepository {
    private enum Constants {
        static let maxRetries: Int = 3
        static let minUserCountForDirectAPILoad: Int = 20
        static let oneSecondInNanoseconds: UInt64 = 1_000_000_000
        static let userCountThresholdRatio: Int = 2 // divisor for sufficient users count (count/2)
        static let loadThreshold: Int = 8 // How many items before the end to load more
    }
    
    private let apiClient: APIClient
    private let userStorage: UserStorage
    private var lastRequestedCount: Int = 0
    private var retryCount: Int = 0
    private var isFirstLoad: Bool = true
    private var cachedUsers: [User] = []
    private var backgroundUpdateTask: Task<Void, Never>? = nil
    
    init(apiClient: APIClient, userStorage: UserStorage) {
        self.apiClient = apiClient
        self.userStorage = userStorage
    }
    
    // Main method for initial loading
    func getUsers(count: Int) async throws -> [User] {
        self.lastRequestedCount = count
        
        // First check if we have data in memory
        if !cachedUsers.isEmpty && cachedUsers.count >= count / Constants.userCountThresholdRatio {
            // If we have enough data in memory, return it immediately
            // and update in the background
            startBackgroundUpdate(count: count)
            return cachedUsers
        }
        
        // If not enough in memory, check SwiftData
        let savedUsers = try await getSavedUsers()
        
        if !savedUsers.isEmpty && savedUsers.count >= count / Constants.userCountThresholdRatio {
            // If we have enough in SwiftData, return it and update memory cache
            self.cachedUsers = savedUsers
            // Update in the background
            startBackgroundUpdate(count: count)
            return savedUsers
        }
        
        // If not enough data in cache, load from API
        isFirstLoad = false
        let newUsers = try await fetchAndStoreMoreUsers(count: count)
        return newUsers
    }
    
    // Method for pagination - always loads from API
    func loadMoreUsers(count: Int) async throws -> [User] {
        // Always load from API for pagination
        let newUsers = try await fetchAndStoreMoreUsers(count: count)
        return newUsers
    }
    
    // Method to check if we should load more content (for UI)
    func shouldLoadMore(currentIndex: Int, totalCount: Int) -> Bool {
        let threshold = totalCount - Constants.loadThreshold
        return currentIndex >= threshold
    }
    
    // Starts a background update without blocking
    private func startBackgroundUpdate(count: Int) {
        // Cancel previous task if exists
        backgroundUpdateTask?.cancel()
        
        backgroundUpdateTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                // We don't wait for the result since it's a background task
                _ = try await fetchAndStoreMoreUsers(count: count)
            } catch {
                // Just log the error without propagating to the user
                print("Error in background update: \(error)")
            }
        }
    }
    
    private func fetchAndStoreMoreUsers(count: Int) async throws -> [User] {
        do {
            // Load with reduced timeout for the first load for better reactivity
            let response = try await apiClient.getUsersWithRetry(count: count)
            
            // Get the current maximum order of users
            let savedUsers = try? await getSavedUsers()
            let maxOrder = savedUsers?.map { $0.order }.max() ?? -1
            
            // Assign sequential order to new users preserving their order
            var newUsers = [User]()
            for (index, userDTO) in response.results.enumerated() {
                // Convert to domain but maintaining the order
                var user = userDTO.toDomain()
                // Recreate the user to assign an order
                user = User(
                    id: user.id,
                    name: user.name,
                    surname: user.surname,
                    fullName: user.fullName,
                    email: user.email,
                    phone: user.phone,
                    gender: user.gender,
                    location: user.location,
                    registeredDate: user.registeredDate,
                    picture: user.picture,
                    order: maxOrder + 1 + index // Assign consecutive order
                )
                newUsers.append(user)
            }
            
            // Update memory cache
            if !newUsers.isEmpty {
                // Add only unique users to the cache
                let existingIDs = Set(self.cachedUsers.map { $0.id })
                let uniqueNewUsers = newUsers.filter { !existingIDs.contains($0.id) }
                
                if !uniqueNewUsers.isEmpty {
                    self.cachedUsers.append(contentsOf: uniqueNewUsers)
                    
                    // Save to SwiftData in the background
                    Task {
                        do {
                            try await saveUsers(uniqueNewUsers)
                        } catch {
                            print("Error saving users: \(error)")
                        }
                    }
                }
            }
            
            retryCount = 0 // Reset the retry counter
            return newUsers
        } catch let apiError as APIError {
            // Retry in case of network errors
            if case .networkError = apiError, retryCount < Constants.maxRetries {
                retryCount += 1
                // Wait less time on the first retry for better reactivity
                let waitTime = isFirstLoad ? 
                    Constants.oneSecondInNanoseconds : // 1 second if it's the first load
                    UInt64(pow(2.0, Double(retryCount)) * Double(Constants.oneSecondInNanoseconds))
                    
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
        // Also remove from memory cache
        cachedUsers.removeAll { $0.id == id }
    }
    
    func searchUsers(query: String) async throws -> [User] {
        // First try to search in memory cache
        if !cachedUsers.isEmpty {
            let lowercasedQuery = query.lowercased()
            let results = cachedUsers.filter { user in
                user.fullName.lowercased().contains(lowercasedQuery) ||
                user.email.lowercased().contains(lowercasedQuery)
            }
            
            if !results.isEmpty {
                return results
            }
        }
        
        // If no results in memory, search in SwiftData
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
