@preconcurrency import Foundation
import SwiftUI

@MainActor
final class UserDetailViewModel: ObservableObject {
    private enum Constants {
        static let dateStyle: DateFormatter.Style = .medium
        static let timeStyle: DateFormatter.Style = .short
    }
    
    @Published var refreshID = UUID()
    let loadImageUseCase: LoadImageUseCase
    private let user: User
    
    init(user: User, loadImageUseCase: LoadImageUseCase) {
        self.user = user
        self.loadImageUseCase = loadImageUseCase
    }
    
    // Public method to manually update refreshID
    func refreshView() {
        refreshID = UUID()
    }
    
    // Image loading implementation
    func loadImage(from url: URL) async throws -> Image {
        // Capture use case locally to avoid data races
        let useCase = self.loadImageUseCase
        return try await useCase.execute(from: url)
    }
    
    // Computed properties to access user data
    var id: String {
        return user.id
    }
    
    var fullName: String {
        return user.fullName
    }
    
    var email: String {
        return user.email
    }
    
    var phone: String {
        return user.phone
    }
    
    var location: String {
        return "\(user.location.street), \(user.location.city), \(user.location.state)"
    }
    
    var registeredDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = Constants.dateStyle
        formatter.timeStyle = Constants.timeStyle
        
        // Always use system language
        formatter.locale = Locale.current
        
        return formatter.string(from: user.registeredDate)
    }
    
    var largePictureURL: URL {
        return user.picture.large
    }
    
    var mediumPictureURL: URL {
        return user.picture.medium
    }
    
    var thumbnailPictureURL: URL {
        return user.picture.thumbnail
    }
    
    var gender: String {
        return user.gender
    }
} 
