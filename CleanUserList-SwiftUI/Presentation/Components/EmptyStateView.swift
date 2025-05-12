import SwiftUI

struct EmptyStateView: View {
    private enum Constants {
        static let largeIconSize: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 8
        static let verticalSpacing: CGFloat = 20
        static let iconColor = Color.gray
        static let backgroundColor = Color.blue
        static let textColor = Color.white
        static let secondaryTextColor = Color.gray
        static let topBottomPadding: CGFloat = 0
    }
    
    let isSearching: Bool
    let onAction: () -> Void
    
    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            Spacer(minLength: Constants.topBottomPadding)
            
            Image(systemName: isSearching ? "magnifyingglass" : "person.slash")
                .font(.system(size: Constants.largeIconSize))
                .foregroundColor(Constants.iconColor)
            
            if !isSearching {
                LocalizedText("no_users_available")
                    .font(.headline)
                
                LocalizedText("try_loading_users")
                    .font(.subheadline)
                    .foregroundColor(Constants.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                LocalizedText("no_results_found")
                    .font(.headline)
                
                LocalizedText("try_another_search")
                    .font(.subheadline)
                    .foregroundColor(Constants.secondaryTextColor)
            }
            
            Button(action: onAction) {
                HStack {
                    Image(systemName: isSearching ? "xmark.circle" : "arrow.clockwise")
                    LocalizedText(isSearching ? "clear_search" : "load_users")
                }
                .padding()
                .background(Constants.backgroundColor)
                .foregroundColor(Constants.textColor)
                .cornerRadius(Constants.buttonCornerRadius)
            }
            
            Spacer(minLength: Constants.topBottomPadding)
        }
    }
} 