import XCTest
@testable import CleanUserList_SwiftUI

class UserDetailViewModelTests: XCTestCase {
    
    func testUserDetailProperties() {
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
        let viewModel = UserDetailViewModel(user: user)
        
        // Then
        XCTAssertEqual(viewModel.id, "123")
        XCTAssertEqual(viewModel.fullName, "John Doe")
        XCTAssertEqual(viewModel.email, "john.doe@example.com")
        XCTAssertEqual(viewModel.phone, "123-456-7890")
        XCTAssertEqual(viewModel.gender, "male")
        XCTAssertEqual(viewModel.location, "123 Main St, New York, NY")
        XCTAssertEqual(viewModel.largePictureURL, URL(string: "https://example.com/large.jpg")!)
        XCTAssertEqual(viewModel.mediumPictureURL, URL(string: "https://example.com/medium.jpg")!)
        XCTAssertEqual(viewModel.thumbnailPictureURL, URL(string: "https://example.com/thumbnail.jpg")!)
        
        XCTAssertFalse(viewModel.registeredDate.isEmpty)
    }
} 