import Foundation

@MainActor
protocol UserStorage {
    func saveUsers(_ users: [User]) async throws
    func getUsers() async throws -> [User]
    func deleteUser(withID id: String) async throws
} 