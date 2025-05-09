import SwiftUI

struct EmptyStateView: View {
    private enum Constants {
        static let largeIconSize: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 8
    }
    
    let isSearching: Bool
    let onAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: isSearching ? "magnifyingglass" : "person.slash")
                .font(.system(size: Constants.largeIconSize))
                .foregroundColor(.gray)
            
            if !isSearching {
                LocalizedText("no_users_available")
                    .font(.headline)
                
                LocalizedText("try_loading_users")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                LocalizedText("no_results_found")
                    .font(.headline)
                
                LocalizedText("try_another_search")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Button(action: onAction) {
                HStack {
                    Image(systemName: isSearching ? "xmark.circle" : "arrow.clockwise")
                    LocalizedText(isSearching ? "clear_search" : "load_users")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(Constants.buttonCornerRadius)
            }
            
            Spacer()
        }
    }
} 