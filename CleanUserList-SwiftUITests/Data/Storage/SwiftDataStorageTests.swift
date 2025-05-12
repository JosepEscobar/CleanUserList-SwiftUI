import XCTest
import Nimble
import SwiftData
@testable import CleanUserList_SwiftUI

@MainActor
class SwiftDataStorageTests: XCTestCase {
    
    private var modelContainer: ModelContainer!
    private var storage: SwiftDataStorage!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create an in-memory test container
        let schema = Schema([UserEntity.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true, // Use in-memory storage for tests
            allowsSave: true
        )
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Initialize storage
        storage = SwiftDataStorage(testModelContainer: modelContainer)
    }
    
    override func tearDown() {
        storage = nil
        modelContainer = nil
        super.tearDown()
    }
    
    func testSaveUsers() async throws {
        // Given
        let users = [
            User.mock(id: "1", name: "Test1"),
            User.mock(id: "2", name: "Test2")
        ]
        
        // When
        try await storage.saveUsers(users)
        
        // Then
        let savedUsers = try await storage.getUsers()
        expect(savedUsers.count).to(equal(2))
        expect(savedUsers.map { $0.id }).to(contain("1"))
        expect(savedUsers.map { $0.id }).to(contain("2"))
    }
    
    func testGetUsersShouldReturnEmptyArray() async throws {
        // When
        let users = try await storage.getUsers()
        
        // Then
        expect(users).to(beEmpty())
    }
    
    func testDeleteUser() async throws {
        // Given
        let user = User.mock(id: "delete-me")
        try await storage.saveUsers([user])
        
        // Verify the user was saved
        var users = try await storage.getUsers()
        expect(users.count).to(equal(1))
        
        // When
        try await storage.deleteUser(withID: "delete-me")
        
        // Then
        users = try await storage.getUsers()
        expect(users).to(beEmpty())
    }
    
    func testDeleteNonExistentUserThrowsError() async throws {
        // When/Then
        do {
            try await storage.deleteUser(withID: "non-existent-id")
            fail("Expected error to be thrown")
        } catch {
            expect(error).to(matchError(StorageError.userNotFound))
        }
    }
    
    func testSaveDuplicateUsers() async throws {
        // Given
        let user1 = User.mock(id: "same-id", name: "First")
        let user2 = User.mock(id: "same-id", name: "Second")
        
        // When
        try await storage.saveUsers([user1])
        try await storage.saveUsers([user2])
        
        // Then
        let savedUsers = try await storage.getUsers()
        expect(savedUsers.count).to(equal(1))
    }
} 