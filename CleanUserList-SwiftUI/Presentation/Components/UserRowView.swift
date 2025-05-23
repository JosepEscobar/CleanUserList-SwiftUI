import SwiftUI

struct UserRowView: View {
    private enum Constants {
        static let spacing: CGFloat = 16
        static let imageSize: CGFloat = 60
        static let verticalPadding: CGFloat = 8
        static let textSpacing: CGFloat = 4
    }
    
    let user: User
    let onDelete: (String) -> Void
    let viewModel: any UserListViewModelType
    
    init(user: User, onDelete: @escaping (String) -> Void, viewModel: any UserListViewModelType) {
        self.user = user
        self.onDelete = onDelete
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack(spacing: Constants.spacing) {
            UserAsyncImageView(url: user.picture.medium)
                .frame(width: Constants.imageSize, height: Constants.imageSize)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(user.fullName)
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(user.location.city)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, Constants.verticalPadding)
    }
}

#if DEBUG
struct UserRowView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUser = User(
            id: "1",
            name: "John",
            surname: "Doe",
            fullName: "John Doe",
            email: "john.doe@example.com",
            phone: "123-456-7890",
            gender: "male",
            location: Location(street: "123 Main St", city: "Anytown", state: "State"),
            registeredDate: Date(),
            picture: Picture(
                large: URL(string: "https://randomuser.me/api/portraits/men/1.jpg")!,
                medium: URL(string: "https://randomuser.me/api/portraits/med/men/1.jpg")!,
                thumbnail: URL(string: "https://randomuser.me/api/portraits/thumb/men/1.jpg")!
            )
        )
        
        let mockViewModel = MockUserListViewModel()
        
        UserRowView(user: sampleUser, onDelete: { _ in }, viewModel: mockViewModel)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

@MainActor
private class MockUserListViewModel: UserListViewModelType {
    var allUsersLoaded: Bool = true
    var users: [User] = []
    var filteredUsers: [User] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var searchText: String = ""
    var isNetworkError: Bool = false
    var hasLoadedUsers: Bool = false
    var isEmptyState: Bool = false
    var isLoadingMoreUsers: Bool = false
    
    func loadMoreUsers(count: Int = 10) {}
    func loadSavedUsers() {}
    func deleteUser(withID id: String) {}
    func retryLoading() {}
    func reset() {}
    
    func makeUserDetailViewModel(for user: User) -> UserDetailViewModel {
        // This is only for testing, never actually called
        fatalError("Not implemented for testing")
    }
    
    func loadImage(from url: URL) async throws -> Image {
        // Return placeholder image for preview
        return Image(systemName: "person.circle.fill")
    }
    
    func handleLanguageChange() {
        // No-op for preview
    }
    
    func loadInitialUsers() async {
        return
    }
    
    func shouldLoadMore(currentIndex: Int) -> Bool {
        return false
    }
}
#endif 
