import SwiftUI

struct SearchBarView: View {
    private enum Constants {
        static let cornerRadius: CGFloat = 12
        static let shadowOpacity: Double = 0.05
        static let shadowRadius: CGFloat = 5
        static let shadowOffsetY: CGFloat = 2
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let topPadding: CGFloat = 8
        static let iconSize: CGFloat = 16
    }
    
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: Constants.horizontalPadding) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: Constants.iconSize, weight: .medium))
            
            TextField("search_users".localized, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .disableAutocorrection(true)
                .font(.system(size: Constants.iconSize))
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: Constants.iconSize))
                }
                .transition(.opacity)
                .animation(.easeInOut, value: searchText)
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(Constants.shadowOpacity), 
                       radius: Constants.shadowRadius, 
                       x: 0, 
                       y: Constants.shadowOffsetY)
        )
        .padding(.horizontal)
        .padding(.top, Constants.topPadding)
    }
} 