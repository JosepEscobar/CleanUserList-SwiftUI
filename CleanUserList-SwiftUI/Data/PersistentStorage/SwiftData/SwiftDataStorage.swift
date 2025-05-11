import SwiftData
import Foundation

@MainActor
class SwiftDataStorage: UserStorage {
    private let modelContainer: ModelContainer
    private let maxTransactionRetries = 3
    
    init() throws {
        let schema = Schema([UserEntity.self])
        
        // Configuración básica para SwiftData
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        // Crear contenedor con la configuración básica
        self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    func saveUsers(_ users: [User]) async throws {
        var retryCount = 0
        var lastError: Error? = nil
        
        // Intentar guardar con reintentos si hay errores transaccionales
        while retryCount < maxTransactionRetries {
            do {
                try await performSaveUsers(users)
                return // Si tiene éxito, salimos de la función
            } catch {
                print("Error al guardar usuarios (intento \(retryCount + 1)): \(error)")
                lastError = error
                retryCount += 1
                
                if retryCount < maxTransactionRetries {
                    // Esperar un poco antes de reintentar
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
                }
            }
        }
        
        // Si llegamos aquí, todos los intentos fallaron
        if let error = lastError {
            throw error
        } else {
            throw StorageError.unknown
        }
    }
    
    private func performSaveUsers(_ users: [User]) async throws {
        // Usar el contexto de transacción directamente
        let transactionContext = ModelContext(modelContainer)
        transactionContext.autosaveEnabled = false
        
        let userEntities = users.map { UserEntity.fromDomain(user: $0) }
        
        // Fetch existente con el nuevo contexto
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
            // Guardar explícitamente el contexto de transacción
            try transactionContext.save()
        }
    }
    
    func getUsers() async throws -> [User] {
        let modelContext = modelContainer.mainContext
        var descriptor = FetchDescriptor<UserEntity>()
        
        // Añadir ordenación para consistencia
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
