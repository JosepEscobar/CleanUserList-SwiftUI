import Foundation

@MainActor
protocol UserRepository {
    func getUsers(count: Int) async throws -> [User]
    func saveUsers(_ users: [User]) async throws
    func deleteUser(withID id: String) async throws
    func searchUsers(query: String) async throws -> [User]
    func getSavedUsers() async throws -> [User]
} 