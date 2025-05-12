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
            picture: Picture.createSafe(
                large: picture.large,
                medium: picture.medium,
                thumbnail: picture.thumbnail
            ),
            order: 0 // Por defecto, el orden se asignará más tarde
        )
    }
}
