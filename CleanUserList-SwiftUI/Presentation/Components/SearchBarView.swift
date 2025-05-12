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
        static let clearButtonSize: CGFloat = 4
        static let clearButtonColor = Color(.systemGray2)
        static let hStackSpacing: CGFloat = 8 // horizontalPadding / 2
        static let fontSizeText: CGFloat = 18 // iconSize + 2
        static let clearButtonIconSize: CGFloat = 16 // same as icon size
        static let borderWidth: CGFloat = 1
        static let borderOpacity: Double = 0.3
        static let shadowOffsetX: CGFloat = 0
    }
    
    @Binding var searchText: String
    @State private var isFocused: Bool = false
    
    var body: some View {
        HStack(spacing: Constants.hStackSpacing) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(searchText.isEmpty ? Constants.placeholderColor : Constants.accentColor)
                .font(.system(size: Constants.iconSize, weight: .medium))
            
            TextField("search_users".localized, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .disableAutocorrection(true)
                .font(.system(size: Constants.fontSizeText, weight: .regular))
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
                        .foregroundColor(Constants.clearButtonColor)
                        .font(.system(size: Constants.clearButtonIconSize))
                        .padding(Constants.clearButtonSize)
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
                        x: Constants.shadowOffsetX, 
                        y: Constants.shadowOffsetY)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .stroke(isFocused || !searchText.isEmpty ? Constants.accentColor.opacity(Constants.borderOpacity) : Color.clear, lineWidth: Constants.borderWidth)
                )
        )
        .padding(.horizontal)
        .padding(.top, Constants.topPadding)
        .padding(.bottom, Constants.bottomPadding)
    }
} 