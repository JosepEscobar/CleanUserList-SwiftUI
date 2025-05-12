import Foundation

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

// Extension to facilitate safe URL creation
extension Picture {
    // Safe fallback URL that will always be valid
    private static let fallbackURL = URL(string: "https://placeholder.com/user")!
    
    // Method to create URL safely
    public static func safeURL(from urlString: String) -> URL {
        URL(string: urlString) ?? fallbackURL
    }
    
    // Safe constructor from strings
    public static func createSafe(large: String, medium: String, thumbnail: String) -> Picture {
        Picture(
            large: safeURL(from: large),
            medium: safeURL(from: medium),
            thumbnail: safeURL(from: thumbnail)
        )
    }
} 