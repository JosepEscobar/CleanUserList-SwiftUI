import Foundation
import SwiftUI

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

// View that displays localized text that updates when the language changes
struct LocalizedText: View {
    let key: String
    let arguments: [CVarArg]
    
    init(_ key: String, arguments: CVarArg...) {
        self.key = key
        self.arguments = arguments
    }
    
    var body: some View {
        Text(arguments.isEmpty ? key.localized : key.localized(with: arguments))
    }
}

// Simple container view
struct LocalizedView<Content: View>: View {
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
    }
} 