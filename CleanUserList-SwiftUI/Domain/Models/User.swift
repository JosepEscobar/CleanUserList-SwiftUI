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

public struct Location: Equatable, Sendable {
    public let street: String
    public let city: String
    public let state: String
    
    public init(street: String, city: String, state: String) {
        self.street = street
        self.city = city
        self.state = state
    }
}

public struct Picture: Equatable, Sendable {
    public let large: URL
    public let medium: URL
    public let thumbnail: URL
    
    public init(large: URL, medium: URL, thumbnail: URL) {
        self.large = large
        self.medium = medium
        self.thumbnail = thumbnail
    }
} 