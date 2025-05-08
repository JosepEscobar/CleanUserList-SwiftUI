import Foundation
import Combine

protocol UserStorage {
    func saveUsers(_ users: [User]) -> AnyPublisher<Void, Error>
    func getUsers() -> AnyPublisher<[User], Error>
    func deleteUser(withID id: String) -> AnyPublisher<Void, Error>
}

class UserDefaultsStorage: UserStorage {
    private let userDefaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let userDefaultsKey = "savedUsers"
    
    struct StoredUser: Codable {
        let id: String
        let name: String
        let surname: String
        let fullName: String
        let email: String
        let phone: String
        let gender: String
        let street: String
        let city: String
        let state: String
        let registeredDate: Date
        let largeImageURL: String
        let mediumImageURL: String
        let thumbnailImageURL: String
        
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
        
        static func fromDomain(user: User) -> StoredUser {
            return StoredUser(
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
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    func saveUsers(_ users: [User]) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(StorageError.unknown))
                return
            }
            
            do {
                // Obtener usuarios existentes
                var storedUsers = [StoredUser]()
                if let data = self.userDefaults.data(forKey: self.userDefaultsKey) {
                    storedUsers = try self.decoder.decode([StoredUser].self, from: data)
                }
                
                // Convertir nuevos usuarios a formato almacenable y eliminar duplicados
                let newStoredUsers = users.map { StoredUser.fromDomain(user: $0) }
                let allUsers = storedUsers + newStoredUsers
                let uniqueUsers = Array(Dictionary(uniqueKeysWithValues: allUsers.map { ($0.id, $0) }).values)
                
                // Guardar todos los usuarios
                let data = try self.encoder.encode(uniqueUsers)
                self.userDefaults.set(data, forKey: self.userDefaultsKey)
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
                if let data = self.userDefaults.data(forKey: self.userDefaultsKey) {
                    let storedUsers = try self.decoder.decode([StoredUser].self, from: data)
                    let users = storedUsers.map { $0.toDomain() }
                    promise(.success(users))
                } else {
                    promise(.success([]))
                }
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
                if let data = self.userDefaults.data(forKey: self.userDefaultsKey) {
                    var storedUsers = try self.decoder.decode([StoredUser].self, from: data)
                    storedUsers.removeAll { $0.id == id }
                    
                    let updatedData = try self.encoder.encode(storedUsers)
                    self.userDefaults.set(updatedData, forKey: self.userDefaultsKey)
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}

enum StorageError: Error {
    case decodingError
    case encodingError
    case unknown
} 