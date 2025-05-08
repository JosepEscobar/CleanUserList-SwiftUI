import Foundation

struct User: Identifiable, Equatable {
    let id: String
    let name: String
    let surname: String
    let fullName: String
    let email: String
    let phone: String
    let gender: String
    let location: Location
    let registeredDate: Date
    let picture: Picture
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Location: Equatable {
    let street: String
    let city: String
    let state: String
}

struct Picture: Equatable {
    let large: URL
    let medium: URL
    let thumbnail: URL
} 