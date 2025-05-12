import SwiftUI
import Kingfisher

// Extension to provide a placeholder user
extension User {
    private enum Constants {
        static let placeholderImageURL = "https://randomuser.me/api/portraits/med/men/1.jpg"
    }
    
    static func placeholder() -> User {
        return User(
            id: "placeholder",
            name: "Placeholder",
            surname: "User",
            fullName: "Placeholder User",
            email: "placeholder@example.com",
            phone: "000-000-0000",
            gender: "none",
            location: Location(street: "", city: "", state: ""),
            registeredDate: Date(),
            picture: Picture(
                large: URL(string: Constants.placeholderImageURL)!,
                medium: URL(string: Constants.placeholderImageURL)!,
                thumbnail: URL(string: Constants.placeholderImageURL)!
            )
        )
    }
}

// Simple component for image loading using Kingfisher
struct UserAsyncImageView: View {
    private enum Constants {
        static let cacheSizeInMB: Int = 100
        static let maxDiskCacheSize: Int = 200
        static let memoryCacheExpiration: TimeInterval = 300 // 5 minutes
        static let diskCacheExpiration: TimeInterval = 86400 // 24 hours
        static let transitionDuration: TimeInterval = 0.2
        static let imageFadeDuration: TimeInterval = 0.25
        static let imageReferenceWidth: CGFloat = 300
        static let imageReferenceHeight: CGFloat = 300
        static let bytesInMB: Int = 1024 * 1024
        static let errorLoadingImage = "error_loading_image"
    }
    
    let url: URL
    
    // This function is executed once when the application initializes
    static func configureKingfisher() {
        // Global Kingfisher configuration
        KingfisherManager.shared.defaultOptions = [
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(Constants.transitionDuration)),
            .cacheOriginalImage
        ]
        
        // Configure cache limits
        ImageCache.default.memoryStorage.config.totalCostLimit = Constants.cacheSizeInMB * Constants.bytesInMB
        ImageCache.default.diskStorage.config.sizeLimit = UInt(Constants.maxDiskCacheSize * Constants.bytesInMB)
        
        // Configure expiration times
        ImageCache.default.memoryStorage.config.expiration = .seconds(Constants.memoryCacheExpiration)
        ImageCache.default.diskStorage.config.expiration = .seconds(Constants.diskCacheExpiration)
    }
    
    var body: some View {
        KFImage(url)
            .setProcessor(ResizingImageProcessor(referenceSize: CGSize(width: Constants.imageReferenceWidth, height: Constants.imageReferenceHeight), mode: .aspectFill))
            .cacheMemoryOnly(false)
            .fade(duration: Constants.imageFadeDuration)
            .onSuccess { _ in
                // Image loaded successfully
            }
            .onFailure { error in
                // Error loading image
                print("\(Constants.errorLoadingImage.localized): \(error.localizedDescription)")
            }
            .placeholder {
                ProgressView()
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
} 
