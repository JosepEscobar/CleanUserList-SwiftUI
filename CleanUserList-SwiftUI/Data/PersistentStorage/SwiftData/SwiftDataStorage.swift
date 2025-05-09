import SwiftData
import Foundation

@MainActor
class SwiftDataStorage: UserStorage {
    private let modelContainer: ModelContainer
    
    init() throws {
        let schema = Schema([UserEntity.self])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    func saveUsers(_ users: [User]) async throws {
        let modelContext = modelContainer.mainContext
        
        let userEntities = users.map { UserEntity.fromDomain(user: $0) }
        
        let descriptor = FetchDescriptor<UserEntity>()
        let existingUsers = try modelContext.fetch(descriptor)
        let existingIDs = Set(existingUsers.map { $0.id })
        
        var insertCount = 0
        
        for entity in userEntities {
            if !existingIDs.contains(entity.id) {
                modelContext.insert(entity)
                insertCount += 1
            }
        }
        
        if insertCount > 0 {
            try modelContext.save()
        }
    }
    
    func getUsers() async throws -> [User] {
        let modelContext = modelContainer.mainContext
        let descriptor = FetchDescriptor<UserEntity>()
        
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
