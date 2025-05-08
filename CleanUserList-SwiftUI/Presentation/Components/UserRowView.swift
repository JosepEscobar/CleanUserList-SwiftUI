import SwiftUI

struct UserRowView: View {
    let user: User
    let onDelete: (String) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: user.picture.medium) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(user.phone)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                onDelete(user.id)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
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
        
        UserRowView(user: sampleUser, onDelete: { _ in })
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif 