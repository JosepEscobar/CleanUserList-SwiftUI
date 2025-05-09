import Foundation

enum StorageError: Error {
    case unknown
    case userNotFound
    case decodingError
    case encodingError
} 