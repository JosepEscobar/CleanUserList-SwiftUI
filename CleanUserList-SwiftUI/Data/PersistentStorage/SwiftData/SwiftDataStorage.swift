import Foundation
import SwiftData
import Combine

class SwiftDataStorage: UserStorage {
    private let modelContainer: ModelContainer
    
    init() throws {
        let schema = Schema([UserEntity.self])
        self.modelContainer = try ModelContainer(for: schema)
    }
    
    func saveUsers(_ users: [User]) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(StorageError.unknown))
                return
            }
            
            Task { @MainActor in
                do {
                    let modelContext = self.modelContainer.mainContext
                    
                    // Convertir usuarios a entidades SwiftData
                    let userEntities = users.map { UserEntity.fromDomain(user: $0) }
                    
                    // Para cada entidad, verificar si ya existe y solo agregar si no existe
                    for entity in userEntities {
                        // Buscar si existe un usuario con el mismo ID
                        let descriptor = FetchDescriptor<UserEntity>()
                        // Filtramos manualmente ya que los predicados dan problemas
                        let allUsers = try modelContext.fetch(descriptor)
                        let existingUsers = allUsers.filter { $0.id == entity.id }
                        
                        // Si no existe, agregarlo
                        if existingUsers.isEmpty {
                            modelContext.insert(entity)
                        }
                    }
                    
                    // Guardar los cambios
                    try modelContext.save()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func getUsers() -> AnyPublisher<[User], Error> {
        return Future<[User], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(StorageError.unknown))
                return
            }
            
            Task { @MainActor in
                do {
                    let modelContext = self.modelContainer.mainContext
                    let descriptor = FetchDescriptor<UserEntity>()
                    let userEntities = try modelContext.fetch(descriptor)
                    let users = userEntities.map { $0.toDomain() }
                    promise(.success(users))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteUser(withID id: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(StorageError.unknown))
                return
            }
            
            Task { @MainActor in
                do {
                    let modelContext = self.modelContainer.mainContext
                    let descriptor = FetchDescriptor<UserEntity>()
                    let allUsers = try modelContext.fetch(descriptor)
                    let usersToDelete = allUsers.filter { $0.id == id }
                    
                    for user in usersToDelete {
                        modelContext.delete(user)
                    }
                    
                    try modelContext.save()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
} 