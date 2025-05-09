import SwiftUI

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

// Simple image cache
actor ImageCache {
    private enum Constants {
        static let cacheLimit = 100
    }
    
    // Global actor access
    static let shared = ImageCache()
    
    private let cache = NSCache<NSURL, ImageContainer>()
    
    // Container class to store Image in NSCache
    class ImageContainer {
        let image: Image
        
        init(image: Image) {
            self.image = image
        }
    }
    
    private init() {
        cache.countLimit = Constants.cacheLimit
    }
    
    func set(_ image: Image, for url: URL) {
        cache.setObject(ImageContainer(image: image), forKey: url as NSURL)
    }
    
    func get(for url: URL) -> Image? {
        return cache.object(forKey: url as NSURL)?.image
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}

// Simple component for reliable image loading
struct UserAsyncImageView: View {
    private enum Constants {
        static let timeoutInterval: TimeInterval = 15.0
        static let maxConnectionsPerHost = 1
        static let imageAcceptHeader = "image/jpeg, image/png"
        static let protocolVersion = "HTTP/1.1"
    }
    
    let url: URL
    @State private var image: Image?
    @State private var isLoading = true
    @State private var loadingFailed = false
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else if loadingFailed {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // Check cache first
        if let cachedImage = await ImageCache.shared.get(for: url) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        await loadImageWithURLSession(url: url)
    }
    
    private func loadImageWithURLSession(url: URL) async {
        do {
            // Create optimized URLRequest
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.httpMethod = "GET"
            
            // Optimize HTTP request
            request.setValue(Constants.protocolVersion, forHTTPHeaderField: "X-Protocol-Version")
            request.setValue("close", forHTTPHeaderField: "Connection")
            
            let config = URLSessionConfiguration.default
            config.allowsExpensiveNetworkAccess = true
            config.timeoutIntervalForRequest = Constants.timeoutInterval
            config.httpMaximumConnectionsPerHost = Constants.maxConnectionsPerHost
            config.httpAdditionalHeaders = [
                "Accept": Constants.imageAcceptHeader,
                "Connection": "close"
            ]
            
            let session = URLSession(configuration: config)
            
            // Execute request asynchronously
            let (data, _) = try await session.data(for: request)
            
            // Create SwiftUI image asynchronously
            if let uiImage = createCGImage(from: data) {
                let swiftUIImage = Image(decorative: uiImage, scale: 1.0)
                
                // Save to cache
                await ImageCache.shared.set(swiftUIImage, for: url)
                
                self.image = swiftUIImage
                self.isLoading = false
            } else {
                self.loadingFailed = true
                self.isLoading = false
            }
        } catch {
            self.loadingFailed = true
            self.isLoading = false
        }
    }
    
    // Helper function to create CGImage from Data
    private func createCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return image
    }
} 