import SwiftUI

// Extension to provide a placeholder user
extension User {
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
                large: URL(string: "https://randomuser.me/api/portraits/med/men/1.jpg")!,
                medium: URL(string: "https://randomuser.me/api/portraits/med/men/1.jpg")!,
                thumbnail: URL(string: "https://randomuser.me/api/portraits/med/men/1.jpg")!
            )
        )
    }
}

// Simple image cache
actor ImageCache {
    // Acceso global al actor
    static let shared = ImageCache()
    
    private let cache = NSCache<NSURL, ImageContainer>()
    
    // Clase contenedora para almacenar Image en NSCache
    class ImageContainer {
        let image: Image
        
        init(image: Image) {
            self.image = image
        }
    }
    
    private init() {
        cache.countLimit = 100
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
struct UserAsyncImageView<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    @State private var image: Image?
    @State private var isLoading = true
    @State private var loadingFailed = false
    private let viewModel: Any
    
    // Constructor para usar con ViewModels
    init(url: URL?,
         viewModel: Any, // The ViewModel to load images
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.viewModel = viewModel
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(image)
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
        .onAppear {
            if image == nil && !isLoading && loadingFailed {
                // Retry loading the image if it failed previously
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        guard let url = url, image == nil else { return }
        
        // Try to load from cache first
        Task {
            if let cachedImage = await ImageCache.shared.get(for: url) {
                self.image = cachedImage
                self.isLoading = false
                return
            }
            
            isLoading = true
            loadingFailed = false
            
            // Primero probamos usar el ViewModel si es compatible
            if let userListVM = viewModel as? any UserListViewModelType {
                do {
                    let loadedImage = try await userListVM.loadImage(from: url)
                    
                    // Save to cache
                    await ImageCache.shared.set(loadedImage, for: url)
                    
                    self.image = loadedImage
                    self.isLoading = false
                } catch {
                    // Si falla, cargar con URLSession
                    await loadImageWithURLSession(url: url)
                }
            } else if let userDetailVM = viewModel as? UserDetailViewModel {
                do {
                    let loadedImage = try await userDetailVM.loadImage(from: url)
                    
                    // Save to cache
                    await ImageCache.shared.set(loadedImage, for: url)
                    
                    self.image = loadedImage
                    self.isLoading = false
                } catch {
                    // Si falla, cargar con URLSession
                    await loadImageWithURLSession(url: url)
                }
            } else {
                // Si no es un ViewModel compatible, usar URLSession directamente
                await loadImageWithURLSession(url: url)
            }
        }
    }
    
    private func loadImageWithURLSession(url: URL) async {
        do {
            // Crear URLRequest optimizado
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.httpMethod = "GET"
            
            // Optimizar la solicitud HTTP
            request.setValue("HTTP/1.1", forHTTPHeaderField: "X-Protocol-Version")
            request.setValue("close", forHTTPHeaderField: "Connection")
            
            let config = URLSessionConfiguration.default
            config.allowsExpensiveNetworkAccess = true
            config.timeoutIntervalForRequest = 15
            config.httpMaximumConnectionsPerHost = 1
            config.httpAdditionalHeaders = [
                "Accept": "image/jpeg, image/png",
                "Connection": "close"
            ]
            
            let session = URLSession(configuration: config)
            
            // Ejecutar la solicitud de forma asíncrona
            let (data, _) = try await session.data(for: request)
            
            // Crear imagen de SwiftUI asíncronamente
            if let uiImage = createCGImage(from: data) {
                let swiftUIImage = Image(decorative: uiImage, scale: 1.0)
                
                // Guardar en caché
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
    
    // Función auxiliar para crear CGImage desde Data
    private func createCGImage(from data: Data) -> CGImage? {
        if let provider = CGDataProvider(data: data as CFData),
           let cgImage = CGImage(
            jpegDataProviderSource: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
           ) {
            return cgImage
        } else if let provider = CGDataProvider(data: data as CFData),
                  let cgImage = CGImage(
                    pngDataProviderSource: provider,
                    decode: nil,
                    shouldInterpolate: true,
                    intent: .defaultIntent
                  ) {
            return cgImage
        }
        return nil
    }
} 