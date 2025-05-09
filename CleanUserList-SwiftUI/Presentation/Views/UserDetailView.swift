import SwiftUI

struct UserDetailView: View {
    @ObservedObject var viewModel: UserDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                // Profile image
                UserAsyncImageView(
                    url: viewModel.largePictureURL,
                    viewModel: viewModel
                ) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 160, height: 160)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8)
                .padding(.top, 32)
                
                // Information card
                VStack(alignment: .leading, spacing: 20) {
                    detailRow(icon: "person.fill", key: "name", value: viewModel.fullName)
                    Divider()
                    detailRow(icon: "envelope.fill", key: "email", value: viewModel.email)
                    Divider()
                    detailRow(icon: "phone.fill", key: "phone", value: viewModel.phone)
                    Divider()
                    detailRow(icon: "figure.wave", key: "gender", value: viewModel.gender)
                    Divider()
                    detailRow(icon: "mappin.and.ellipse", key: "address", value: viewModel.location)
                    Divider()
                    detailRow(icon: "calendar", key: "registration_date", value: viewModel.registeredDate)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                
                Spacer(minLength: 40)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("user_details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .id(viewModel.refreshID)
    }
    
    private func detailRow(icon: String, key: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon in circle
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.blue))
            
            VStack(alignment: .leading, spacing: 4) {
                LocalizedText(key)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
} 