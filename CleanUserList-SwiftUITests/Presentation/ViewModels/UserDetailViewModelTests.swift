import XCTest
import SwiftUI
import Nimble
@testable import CleanUserList_SwiftUI

@MainActor
class UserDetailViewModelTests: XCTestCase {
    
    private var mockLoadImageUseCase: MockLoadImageUseCase!
    
    override func setUp() async throws {
        try await super.setUp()
        mockLoadImageUseCase = MockLoadImageUseCase()
    }
    
    override func tearDown() async throws {
        mockLoadImageUseCase = nil
        try await super.tearDown()
    }
    
    func testUserDetailProperties() async {
        // Given
        let user = User(
            id: "123",
            name: "John",
            surname: "Doe",
            fullName: "John Doe",
            email: "john.doe@example.com",
            phone: "123-456-7890",
            gender: "male",
            location: Location(
                street: "123 Main St",
                city: "New York",
                state: "NY"
            ),
            registeredDate: Date(),
            picture: Picture(
                large: URL(string: "https://example.com/large.jpg")!,
                medium: URL(string: "https://example.com/medium.jpg")!,
                thumbnail: URL(string: "https://example.com/thumbnail.jpg")!
            )
        )
        
        // When
        let viewModel = UserDetailViewModel(user: user, loadImageUseCase: mockLoadImageUseCase)
        
        // Then
        await awaitExpectation {
            expect(viewModel.id).to(equal("123"))
            expect(viewModel.fullName).to(equal("John Doe"))
            expect(viewModel.email).to(equal("john.doe@example.com"))
            expect(viewModel.phone).to(equal("123-456-7890"))
            expect(viewModel.gender).to(equal("male"))
            expect(viewModel.location).to(equal("123 Main St, New York, NY"))
            expect(viewModel.largePictureURL).to(equal(URL(string: "https://example.com/large.jpg")!))
            expect(viewModel.mediumPictureURL).to(equal(URL(string: "https://example.com/medium.jpg")!))
            expect(viewModel.thumbnailPictureURL).to(equal(URL(string: "https://example.com/thumbnail.jpg")!))
            
            expect(viewModel.registeredDate.isEmpty).to(beFalse())
        }
    }
    
    func testLoadImage() async throws {
        // Given
        let user = User.mock()
        let url = URL(string: "https://example.com/image.jpg")!
        let mockImage = Image(systemName: "person")
        mockLoadImageUseCase.imageToReturn = mockImage
        
        let viewModel = UserDetailViewModel(user: user, loadImageUseCase: mockLoadImageUseCase)
        
        // When
        _ = try await viewModel.loadImage(from: url)
        
        // Then
        await awaitExpectation {
            expect(self.mockLoadImageUseCase.executeCallCount).to(equal(1))
            expect(self.mockLoadImageUseCase.lastRequestedURL).to(equal(url))
        }
    }
}

// MARK: - Mock LoadImageUseCase
extension UserDetailViewModelTests {
    class MockLoadImageUseCase: LoadImageUseCase {
        var executeCallCount = 0
        var lastRequestedURL: URL?
        var imageToReturn: Image = Image(systemName: "photo")
        var errorToThrow: Error?
        
        func execute(from url: URL) async throws -> Image {
            executeCallCount += 1
            lastRequestedURL = url
            
            if let error = errorToThrow {
                throw error
            }
            
            return imageToReturn
        }
    }
} 