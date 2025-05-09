@preconcurrency import Foundation
import SwiftUI

@MainActor
final class UserDetailViewModel: ObservableObject {
    @Published var refreshID = UUID()
    let loadImageUseCase: LoadImageUseCase
    private let user: User
    
    init(user: User, loadImageUseCase: LoadImageUseCase) {
        self.user = user
        self.loadImageUseCase = loadImageUseCase
    }
    
    // Método público para actualizar manualmente el refreshID
    func refreshView() {
        refreshID = UUID()
    }
    
    // Image loading implementation
    func loadImage(from url: URL) async throws -> Image {
        // Capturar el use case localmente para evitar data races
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
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        // Usar siempre el idioma del sistema
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
