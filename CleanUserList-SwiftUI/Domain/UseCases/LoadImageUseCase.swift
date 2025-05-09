import Foundation
import SwiftUI

@MainActor
protocol LoadImageUseCase {
    func execute(from url: URL) async throws -> Image
}

@MainActor
class DefaultLoadImageUseCase: LoadImageUseCase {
    private let cache = NSCache<NSURL, ImageWrapper>()
    private let session: URLSession
    private let maxRetries = 3
    private let fileManager = FileManager.default
    private let diskCachePath: URL?
    
    // Wrapper para poder guardar Image en NSCache
    private class ImageWrapper {
        let image: Image
        let cgImage: CGImage?
        
        init(image: Image, cgImage: CGImage?) {
            self.image = image
            self.cgImage = cgImage
        }
    }
    
    init() {
        // Configure larger cache
        cache.countLimit = 200
        cache.totalCostLimit = 1024 * 1024 * 100 // 100 MB
        
        // Configure disk cache directory
        if let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let imageCacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
            
            // Create directory if it doesn't exist
            if !fileManager.fileExists(atPath: imageCacheDirectory.path) {
                do {
                    try fileManager.createDirectory(at: imageCacheDirectory, withIntermediateDirectories: true)
                } catch {
                    // Directory creation failed
                }
            }
            
            diskCachePath = imageCacheDirectory
        } else {
            diskCachePath = nil
        }
        
        // Configure global URLCache with significant size
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB
        let diskCapacity = 100 * 1024 * 1024 // 100 MB
        let urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "com.josepescobar.imageCache")
        URLCache.shared = urlCache
        
        // Configure URLSession with aggressive caching and shorter timeouts
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = urlCache
        configuration.timeoutIntervalForRequest = 15.0
        configuration.timeoutIntervalForResource = 30.0
        configuration.httpMaximumConnectionsPerHost = 10
        
        // Avoid issues with QUIC/HTTP3
        if #available(iOS 15.0, *) {
            configuration.allowsExpensiveNetworkAccess = true
            configuration.allowsConstrainedNetworkAccess = true
        }
        
        // Reduce header size
        configuration.httpAdditionalHeaders = [
            "Accept": "image/webp,image/png,image/jpeg,image/*",
            "Accept-Encoding": "gzip, deflate",
            "Connection": "keep-alive"
        ]
        self.session = URLSession(configuration: configuration)
    }
    
    func execute(from url: URL) async throws -> Image {
        // Check cache first for immediate response
        if let cachedImageWrapper = cache.object(forKey: url as NSURL) {
            return cachedImageWrapper.image
        }
        
        // Try to load from URLCache to check if already in disk cache
        if let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)),
           let cgImage = createCGImage(from: cachedResponse.data) {
            let image = Image(decorative: cgImage, scale: 1.0)
            let wrapper = ImageWrapper(image: image, cgImage: cgImage)
            cache.setObject(wrapper, forKey: url as NSURL)
            return image
        }
        
        // Try to load from our own disk cache asynchronously
        if let diskImage = await loadImageFromDiskCache(url: url) {
            return diskImage
        }
        
        // Implement retries
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                // Create request with headers optimized for images
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                request.setValue("image/webp,image/png,image/jpeg,image/*", forHTTPHeaderField: "Accept")
                request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
                request.setValue("keep-alive", forHTTPHeaderField: "Connection")
                
                // Download image
                let (data, response) = try await session.data(for: request)
                
                // Verify response is valid
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw NSError(domain: "LoadImageUseCase", code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response \(String(describing: (response as? HTTPURLResponse)?.statusCode))"])
                }
                
                // Save to URLCache for future requests
                if let httpResponse = response as? HTTPURLResponse {
                    let cachedResponse = CachedURLResponse(
                        response: httpResponse,
                        data: data,
                        userInfo: nil,
                        storagePolicy: .allowed
                    )
                    URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                }
                
                guard let cgImage = createCGImage(from: data) else {
                    throw NSError(domain: "LoadImageUseCase", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Could not create image from data"])
                }
                
                let image = Image(decorative: cgImage, scale: 1.0)
                let wrapper = ImageWrapper(image: image, cgImage: cgImage)
                
                // Save to memory cache
                cache.setObject(wrapper, forKey: url as NSURL)
                
                // Save to custom disk cache asynchronously
                await saveImageToDiskCache(data: data, url: url)
                
                return image
            } catch {
                lastError = error
                
                // Wait before retrying (exponential backoff)
                if attempt < maxRetries {
                    let delaySeconds = 0.5 * pow(2.0, Double(attempt - 1))
                    try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                }
            }
        }
        
        // If we get here, all attempts have failed
        throw lastError ?? NSError(domain: "LoadImageUseCase", code: -999,
                                   userInfo: [NSLocalizedDescriptionKey: "Could not load image after \(maxRetries) attempts"])
    }
    
    // MARK: - Helper functions
    
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
    
    // MARK: - Custom disk cache
    
    private func loadImageFromDiskCache(url: URL) async -> Image? {
        guard let diskCachePath = diskCachePath else { return nil }
        
        let fileName = url.lastPathComponent
        let filePath = diskCachePath.appendingPathComponent(fileName)
        
        // Verificar primero si el archivo existe sin leer su contenido
        guard fileManager.fileExists(atPath: filePath.path) else {
            return nil
        }
        
        // Acceso asíncrono usando URLSession incluso para archivos locales
        do {
            let fileURL = URL(fileURLWithPath: filePath.path)
            var request = URLRequest(url: fileURL)
            request.cachePolicy = .returnCacheDataElseLoad
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let cgImage = createCGImage(from: data) {
                let image = Image(decorative: cgImage, scale: 1.0)
                let wrapper = ImageWrapper(image: image, cgImage: cgImage)
                cache.setObject(wrapper, forKey: url as NSURL)
                return image
            }
        } catch {
            // Error al leer la imagen desde el disco, continuar flujo
            print("Error al cargar imagen desde disco: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func saveImageToDiskCache(data: Data, url: URL) async {
        guard let diskCachePath = diskCachePath else { return }
        
        let fileName = url.lastPathComponent
        let filePath = diskCachePath.appendingPathComponent(fileName)
        
        do {
            // Escribir archivo de forma asíncrona usando Task
            try await Task {
                try data.write(to: filePath, options: .atomic)
            }.value
        } catch {
            // Falló al guardar la imagen en la caché del disco
            print("Error al guardar imagen en disco: \(error.localizedDescription)")
        }
    }
} 