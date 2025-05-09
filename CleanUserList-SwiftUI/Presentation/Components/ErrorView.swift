import SwiftUI

struct ErrorView: View {
    private enum Constants {
        static let largeIconSize: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 8
    }
    
    let message: String
    let isNetworkError: Bool
    let savedUsersCount: Int
    let onRetry: () -> Void
    let onContinueWithSaved: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: isNetworkError ? "wifi.exclamationmark" : "exclamationmark.triangle")
                .font(.system(size: Constants.largeIconSize))
                .foregroundColor(.red)
                .padding()
            
            Text(message)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if isNetworkError {
                LocalizedText("connection_problem")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    LocalizedText("retry")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(Constants.buttonCornerRadius)
            }
            
            if savedUsersCount > 0 {
                Button(action: onContinueWithSaved) {
                    LocalizedText("continue_with_saved_users", arguments: savedUsersCount)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(Constants.buttonCornerRadius)
                }
            }
            
            Spacer()
        }
    }
} 