import XCTest
import Combine
@testable import CleanUserList_SwiftUI

final class UserDetailViewModelTests: XCTestCase {
    
    func testUserDetailViewModel() {
        // Given
        let testUser = createTestUser()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        // When
        let viewModel = UserDetailViewModel(user: testUser, dateFormatter: dateFormatter)
        
        // Then
        XCTAssertEqual(viewModel.name, "John Doe")
        XCTAssertEqual(viewModel.email, "john@example.com")
        XCTAssertEqual(viewModel.phone, "123-456-7890")
        XCTAssertEqual(viewModel.gender, "male")
        XCTAssertEqual(viewModel.location, "123 Main St, Anytown, State")
        
        // Verificar el formateador de fecha
        let formattedDate = dateFormatter.string(from: testUser.registeredDate)
        XCTAssertEqual(viewModel.registeredDate, formattedDate)
        
        // Verificar URLs
        XCTAssertEqual(viewModel.pictureURL, testUser.picture.large)
    }
    
    func testUserDetailViewModelWithCustomDateFormatter() {
        // Given
        let testUser = createTestUser()
        let customDateFormatter = DateFormatter()
        customDateFormatter.dateStyle = .full
        customDateFormatter.timeStyle = .none
        
        // When
        let viewModel = UserDetailViewModel(user: testUser, dateFormatter: customDateFormatter)
        
        // Then
        // Verificar el formateador de fecha personalizado
        let formattedDate = customDateFormatter.string(from: testUser.registeredDate)
        XCTAssertEqual(viewModel.registeredDate, formattedDate)
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser() -> User {
        let dateComponents = DateComponents(
            calendar: Calendar.current,
            year: 2022, month: 1, day: 1,
            hour: 10, minute: 30, second: 0
        )
        let date = dateComponents.date!
        
        return User(
            id: "test-id",
            name: "John",
            surname: "Doe",
            fullName: "John Doe",
            email: "john@example.com",
            phone: "123-456-7890",
            gender: "male",
            location: Location(street: "123 Main St", city: "Anytown", state: "State"),
            registeredDate: date,
            picture: Picture(
                large: URL(string: "https://randomuser.me/api/portraits/men/1.jpg")!,
                medium: URL(string: "https://randomuser.me/api/portraits/med/men/1.jpg")!,
                thumbnail: URL(string: "https://randomuser.me/api/portraits/thumb/men/1.jpg")!
            )
        )
    }
} 