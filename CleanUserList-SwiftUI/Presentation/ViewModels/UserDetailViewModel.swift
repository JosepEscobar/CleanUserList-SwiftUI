import Foundation
import Combine

protocol UserDetailViewModelType: ObservableObject {
    var user: User { get }
    var name: String { get }
    var email: String { get }
    var phone: String { get }
    var gender: String { get }
    var location: String { get }
    var registeredDate: String { get }
    var pictureURL: URL { get }
}

class UserDetailViewModel: UserDetailViewModelType {
    // MARK: - Published Properties
    @Published var user: User
    
    // MARK: - Formatters
    private let dateFormatter: DateFormatter
    
    // MARK: - Initializer
    init(user: User, dateFormatter: DateFormatter = UserDetailViewModel.createDefaultDateFormatter()) {
        self.user = user
        self.dateFormatter = dateFormatter
    }
    
    // MARK: - Computed Properties
    var name: String {
        return user.fullName
    }
    
    var email: String {
        return user.email
    }
    
    var phone: String {
        return user.phone
    }
    
    var gender: String {
        return user.gender
    }
    
    var location: String {
        return "\(user.location.street), \(user.location.city), \(user.location.state)"
    }
    
    var registeredDate: String {
        return dateFormatter.string(from: user.registeredDate)
    }
    
    var pictureURL: URL {
        return user.picture.large
    }
    
    // MARK: - Private Helper Methods
    private static func createDefaultDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
} 