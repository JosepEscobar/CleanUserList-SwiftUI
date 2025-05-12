import SwiftUI

struct ErrorView: View {
    private enum Constants {
        static let largeIconSize: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 8
        static let verticalSpacing: CGFloat = 20
        static let iconPadding: CGFloat = 0
        static let horizontalTextPadding: CGFloat = 0
        static let buttonBackgroundColor = Color.blue
        static let buttonTextColor = Color.white
        static let secondaryButtonBackgroundOpacity: Double = 0.2
        static let secondaryButtonBackgroundColor = Color.gray
        static let secondaryButtonTextColor = Color.primary
        static let errorColor = Color.red
        static let topBottomPadding: CGFloat = 0
    }
    
    let message: String
    let isNetworkError: Bool
    let savedUsersCount: Int
    let onRetry: () -> Void
    let onContinueWithSaved: () -> Void
    
    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            Spacer(minLength: Constants.topBottomPadding)
            
            Image(systemName: isNetworkError ? "wifi.exclamationmark" : "exclamationmark.triangle")
                .font(.system(size: Constants.largeIconSize))
                .foregroundColor(Constants.errorColor)
                .padding(Constants.iconPadding)
            
            Text(message)
                .foregroundColor(Constants.errorColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.horizontalTextPadding)
            
            if isNetworkError {
                LocalizedText("connection_problem")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.horizontalTextPadding)
            }
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    LocalizedText("retry")
                }
                .padding()
                .background(Constants.buttonBackgroundColor)
                .foregroundColor(Constants.buttonTextColor)
                .cornerRadius(Constants.buttonCornerRadius)
            }
            
            if savedUsersCount > 0 {
                Button(action: onContinueWithSaved) {
                    LocalizedText("continue_with_saved_users", arguments: savedUsersCount)
                        .padding()
                        .background(Constants.secondaryButtonBackgroundColor.opacity(Constants.secondaryButtonBackgroundOpacity))
                        .foregroundColor(Constants.secondaryButtonTextColor)
                        .cornerRadius(Constants.buttonCornerRadius)
                }
            }
            
            Spacer(minLength: Constants.topBottomPadding)
        }
    }
} 