import Foundation

enum StorageError: Error {
    case userNotFound
    case unknown
    case decodingError
    case encodingError
} 