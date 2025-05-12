import Foundation
@testable import CleanUserList_SwiftUI

extension User {
    static func mock(
        id: String = "test-id",
        name: String = "Test",
        surname: String = "User",
        email: String = "test@example.com"
    ) -> User {
        return User(
            id: id,
            name: name,
            surname: surname,
            fullName: "\(name) \(surname)",
            email: email,
            phone: "123-456-7890",
            gender: "male",
            location: Location(street: "Test St", city: "Test City", state: "TS"),
            registeredDate: Date(),
            picture: Picture.createSafe(
                large: "https://example.com/large.jpg",
                medium: "https://example.com/medium.jpg",
                thumbnail: "https://example.com/thumbnail.jpg"
            )
        )
    }
}
