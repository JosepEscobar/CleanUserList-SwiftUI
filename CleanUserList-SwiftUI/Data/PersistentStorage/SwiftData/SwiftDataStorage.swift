import Foundation
import SwiftData
import Combine

@Model
final class UserEntity {
    @Attribute(.unique) var id: String
    var name: String
    var surname: String
    var fullName: String
    var email: String
    var phone: String
    var gender: String
    var street: String
    var city: String 
    var state: String
    var registeredDate: Date
    var largeImageURL: String
    var mediumImageURL: String
    var thumbnailImageURL: String
    
    init(
        id: String,
        name: String,
        surname: String,
        fullName: String,
        email: String,
        phone: String,
        gender: String,
        street: String,
        city: String,
        state: String,
        registeredDate: Date,
        largeImageURL: String,
        mediumImageURL: String,
        thumbnailImageURL: String
    ) {
        self.id = id
        self.name = name
        self.surname = surname
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.gender = gender
        self.street = street
        self.city = city
        self.state = state
        self.registeredDate = registeredDate
        self.largeImageURL = largeImageURL
        self.mediumImageURL = mediumImageURL
        self.thumbnailImageURL = thumbnailImageURL
    }
    
    func toDomain() -> User {
        return User(
            id: id,
            name: name,
            surname: surname,
            fullName: fullName,
            email: email,
            phone: phone,
            gender: gender,
            location: Location(
                street: street,
                city: city,
                state: state
            ),
            registeredDate: registeredDate,
            picture: Picture(
                large: URL(string: largeImageURL)!,
                medium: URL(string: mediumImageURL)!,
                thumbnail: URL(string: thumbnailImageURL)!
            )
        )
    }
    
    static func fromDomain(user: User) -> UserEntity {
        return UserEntity(
            id: user.id,
            name: user.name,
            surname: user.surname,
            fullName: user.fullName,
            email: user.email,
            phone: user.phone,
            gender: user.gender,
            street: user.location.street,
            city: user.location.city,
            state: user.location.state,
            registeredDate: user.registeredDate,
            largeImageURL: user.picture.large.absoluteString,
            mediumImageURL: user.picture.medium.absoluteString,
            thumbnailImageURL: user.picture.thumbnail.absoluteString
        )
    }
}

class SwiftDataStorage: UserStorage {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() throws {
        let schema = Schema([UserEntity.self])
        self.modelContainer = try ModelContainer(for: schema)
        self.modelContext = modelContainer.mainContext
    }
    
    func saveUsers(_ users: [User]) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(StorageError.unknown))
                return
            }
            
            do {
                // Convertir usuarios a entidades SwiftData
                let userEntities = users.map { UserEntity.fromDomain(user: $0) }
                
                // Para cada entidad, verificar si ya existe y solo agregar si no existe
                for entity in userEntities {
                    // Buscar si existe un usuario con el mismo ID
                    let descriptor = FetchDescriptor<UserEntity>(predicate: #Predicate { $0.id == entity.id })
                    let existingUsers = try self.modelContext.fetch(descriptor)
                    
                    // Si no existe, agregarlo
                    if existingUsers.isEmpty {
                        self.modelContext.insert(entity)
                    }
                }
                
                // Guardar los cambios
                try self.modelContext.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func getUsers() -> AnyPublisher<[User], Error> {
        return Future<[User], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(StorageError.unknown))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<UserEntity>()
                let userEntities = try self.modelContext.fetch(descriptor)
                let users = userEntities.map { $0.toDomain() }
                promise(.success(users))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteUser(withID id: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(StorageError.unknown))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<UserEntity>(predicate: #Predicate { $0.id == id })
                let usersToDelete = try self.modelContext.fetch(descriptor)
                
                for user in usersToDelete {
                    self.modelContext.delete(user)
                }
                
                try self.modelContext.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
} 