import Foundation

struct UserResponse: Decodable {
    let results: [UserDTO]
}

struct UserDTO: Decodable {
    let gender: String
    let name: NameDTO
    let location: LocationDTO
    let email: String
    let login: LoginDTO
    let registered: RegisteredDTO
    let phone: String
    let picture: PictureDTO
    
    func toDomain() -> User {
        return User(
            id: login.uuid,
            name: name.first,
            surname: name.last,
            fullName: "\(name.first) \(name.last)",
            email: email,
            phone: phone,
            gender: gender,
            location: Location(
                street: "\(location.street.number) \(location.street.name)",
                city: location.city,
                state: location.state
            ),
            registeredDate: registered.date,
            picture: Picture(
                large: URL(string: picture.large)!,
                medium: URL(string: picture.medium)!,
                thumbnail: URL(string: picture.thumbnail)!
            )
        )
    }
}

struct NameDTO: Decodable {
    let title: String
    let first: String
    let last: String
}

struct LocationDTO: Decodable {
    let street: StreetDTO
    let city: String
    let state: String
}

struct StreetDTO: Decodable {
    let number: Int
    let name: String
}

struct LoginDTO: Decodable {
    let uuid: String
}

struct RegisteredDTO: Decodable {
    let date: Date
}

struct PictureDTO: Decodable {
    let large: String
    let medium: String
    let thumbnail: String
} 