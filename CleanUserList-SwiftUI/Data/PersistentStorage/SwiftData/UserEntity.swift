import Foundation
import SwiftData

@Model
final class UserEntity {
    #Unique<UserEntity>([\.id])
    
    #Index<UserEntity>([\.id], [\.name], [\.fullName], [\.email])
    
    @Attribute(.unique) var id: String = ""
    var name: String = ""
    var surname: String = ""
    var fullName: String = ""
    var email: String = ""
    var phone: String = ""
    var gender: String = ""
    var street: String = ""
    var city: String = ""
    var state: String = ""
    
    // Field to maintain insertion order
    var order: Int = 0
    
    @Attribute(.externalStorage) 
    var registeredDate: Date = Date()
    
    @Attribute(.externalStorage)
    var largeImageURL: String = ""
    
    @Attribute(.externalStorage)
    var mediumImageURL: String = ""
    
    @Attribute(.externalStorage)
    var thumbnailImageURL: String = ""
    
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
        thumbnailImageURL: String,
        order: Int = 0
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
        self.order = order
    }
    
    init() {
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
            picture: Picture.createSafe(
                large: largeImageURL,
                medium: mediumImageURL,
                thumbnail: thumbnailImageURL
            ),
            order: order
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
            thumbnailImageURL: user.picture.thumbnail.absoluteString,
            order: user.order
        )
    }
} 