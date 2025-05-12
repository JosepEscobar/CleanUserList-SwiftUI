import Foundation

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