import SwiftUI

struct UserDetailView: View {
    private enum Constants {
        static let cornerRadius: CGFloat = 16
        static let shadowOpacity: Double = 0.1
        static let shadowRadius: CGFloat = 10
        static let shadowOffsetY: CGFloat = 2
        static let horizontalPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 20
        static let minSpacing: CGFloat = 40
        static let iconSize: CGFloat = 18
        static let iconCircleSize: CGFloat = 36
        static let rowSpacing: CGFloat = 16
        static let textSpacing: CGFloat = 4
        static let profileImageSize: CGFloat = 160
        static let profileImageStrokeWidth: CGFloat = 3
        static let profileImageShadowRadius: CGFloat = 8
        static let profileImageTopPadding: CGFloat = 32
        static let cardSpacing: CGFloat = 24
        static let cardContentSpacing: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let blueOpacity: Double = 0.2
    }
    
    @ObservedObject var viewModel: UserDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: Constants.cardSpacing) {
                // Profile image
                UserAsyncImageView(url: viewModel.largePictureURL)
                    .frame(width: Constants.profileImageSize, height: Constants.profileImageSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.blue.opacity(Constants.blueOpacity), lineWidth: Constants.profileImageStrokeWidth)
                    )
                    .shadow(color: Color.black.opacity(Constants.shadowOpacity), radius: Constants.profileImageShadowRadius)
                    .padding(.top, Constants.profileImageTopPadding)
                
                // Information card
                VStack(alignment: .leading, spacing: Constants.cardContentSpacing) {
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
                .padding(Constants.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(Constants.shadowOpacity), 
                               radius: Constants.shadowRadius, 
                               x: 0, 
                               y: Constants.shadowOffsetY)
                )
                .padding(.horizontal, Constants.horizontalPadding)
                
                Spacer(minLength: Constants.minSpacing)
            }
            .padding(.bottom, Constants.bottomPadding)
        }
        .navigationTitle("user_details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .id(viewModel.refreshID)
    }
    
    private func detailRow(icon: String, key: String, value: String) -> some View {
        HStack(alignment: .center, spacing: Constants.rowSpacing) {
            // Icon in circle
            Image(systemName: icon)
                .font(.system(size: Constants.iconSize, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: Constants.iconCircleSize, height: Constants.iconCircleSize)
                .background(Circle().fill(Color.blue))
            
            VStack(alignment: .leading, spacing: Constants.textSpacing) {
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