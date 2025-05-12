import Foundation
import SwiftData

public struct User: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let surname: String
    public let fullName: String
    public let email: String
    public let phone: String
    public let gender: String
    public let location: Location
    public let registeredDate: Date
    public let picture: Picture
    
    public init(
        id: String,
        name: String,
        surname: String,
        fullName: String,
        email: String,
        phone: String,
        gender: String,
        location: Location,
        registeredDate: Date,
        picture: Picture
    ) {
        self.id = id
        self.name = name
        self.surname = surname
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.gender = gender
        self.location = location
        self.registeredDate = registeredDate
        self.picture = picture
    }
    
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}
