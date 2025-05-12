import Foundation

struct LocationDTO: Decodable {
    let street: StreetDTO
    let city: String
    let state: String
} 