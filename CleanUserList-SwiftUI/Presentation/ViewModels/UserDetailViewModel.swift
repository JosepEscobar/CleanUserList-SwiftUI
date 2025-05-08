import Foundation
import Combine

class UserDetailViewModel: ObservableObject {
    @Published var user: User
    
    init(user: User) {
        self.user = user
    }
    
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: user.registeredDate)
    }
    
    var pictureURL: URL {
        return user.picture.large
    }
} 