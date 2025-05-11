import SwiftUI

struct SearchBarView: View {
    private enum Constants {
        static let cornerRadius: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let topPadding: CGFloat = 8
        static let bottomPadding: CGFloat = 16
        static let iconSize: CGFloat = 16
        static let backgroundColor = Color.white
        static let placeholderColor = Color(UIColor.placeholderText)
        static let accentColor = Color(UIColor.systemGray)
        static let shadowRadius: CGFloat = 5
        static let shadowOpacity: Double = 0.1
        static let shadowOffsetY: CGFloat = 2
        static let animationDuration: Double = 0.2
    }
    
    @Binding var searchText: String
    @State private var isFocused: Bool = false
    
    var body: some View {
        HStack(spacing: Constants.horizontalPadding / 2) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(searchText.isEmpty ? Constants.placeholderColor : Constants.accentColor)
                .font(.system(size: Constants.iconSize, weight: .medium))
            
            TextField("search_users".localized, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .disableAutocorrection(true)
                .font(.system(size: Constants.iconSize + 2, weight: .regular))
                .onChange(of: searchText) { _, _ in
                    withAnimation(.easeInOut(duration: Constants.animationDuration)) {
                        isFocused = true
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.systemGray2))
                        .font(.system(size: Constants.iconSize))
                        .padding(4)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: searchText)
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Constants.backgroundColor)
                .shadow(color: Color.black.opacity(Constants.shadowOpacity), 
                        radius: Constants.shadowRadius, 
                        x: 0, 
                        y: Constants.shadowOffsetY)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .stroke(isFocused || !searchText.isEmpty ? Constants.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.top, Constants.topPadding)
        .padding(.bottom, Constants.bottomPadding)
    }
} 