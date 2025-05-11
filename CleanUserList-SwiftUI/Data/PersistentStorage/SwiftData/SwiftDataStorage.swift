import SwiftData
import Foundation

@MainActor
class SwiftDataStorage: UserStorage {
    private let modelContainer: ModelContainer
    private let maxTransactionRetries = 3
    
    init() throws {
        let schema = Schema([UserEntity.self])
        
        // Basic configuration for SwiftData
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        // Create container with basic configuration
        self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    func saveUsers(_ users: [User]) async throws {
        var retryCount = 0
        var lastError: Error? = nil
        
        // Try to save with retries if there are transactional errors
        while retryCount < maxTransactionRetries {
            do {
                try await performSaveUsers(users)
                return // If successful, exit the function
            } catch {
                print("Error saving users (attempt \(retryCount + 1)): \(error)")
                lastError = error
                retryCount += 1
                
                if retryCount < maxTransactionRetries {
                    // Wait a bit before retrying
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
            }
        }
        
        // If we get here, all attempts failed
        if let error = lastError {
            throw error
        } else {
            throw StorageError.unknown
        }
    }
    
    private func performSaveUsers(_ users: [User]) async throws {
        // Use the transaction context directly
        let transactionContext = ModelContext(modelContainer)
        transactionContext.autosaveEnabled = false
        
        let userEntities = users.map { UserEntity.fromDomain(user: $0) }
        
        // Fetch existing with the new context
        let descriptor = FetchDescriptor<UserEntity>()
        let existingUsers = try transactionContext.fetch(descriptor)
        let existingIDs = Set(existingUsers.map { $0.id })
        
        var insertCount = 0
        
        for entity in userEntities {
            if !existingIDs.contains(entity.id) {
                transactionContext.insert(entity)
                insertCount += 1
            }
        }
        
        if insertCount > 0 {
            // Explicitly save the transaction context
            try transactionContext.save()
        }
    }
    
    func getUsers() async throws -> [User] {
        let modelContext = modelContainer.mainContext
        var descriptor = FetchDescriptor<UserEntity>()
        
        // Add sorting for consistency
        descriptor.sortBy = [SortDescriptor(\.registeredDate, order: .forward)]
        
        let userEntities = try modelContext.fetch(descriptor)
        
        if userEntities.isEmpty {
            return []
        } else {
            let users = userEntities.map { $0.toDomain() }
            return users
        }
    }
    
    func deleteUser(withID id: String) async throws {
        let modelContext = modelContainer.mainContext
        
        var descriptor = FetchDescriptor<UserEntity>()
        descriptor.predicate = #Predicate<UserEntity> { entity in
            entity.id == id
        }
        descriptor.fetchLimit = 1
        
        let usersToDelete = try modelContext.fetch(descriptor)
        
        if let userToDelete = usersToDelete.first {
            modelContext.delete(userToDelete)
            try modelContext.save()
        } else {
            throw StorageError.userNotFound
        }
    }
} 
