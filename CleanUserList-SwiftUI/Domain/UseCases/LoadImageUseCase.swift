import Foundation
import SwiftUI
import Kingfisher

@MainActor
protocol LoadImageUseCase {
    func execute(from url: URL) async throws -> Image
}

@MainActor
class DefaultLoadImageUseCase: LoadImageUseCase {
    
    init() {
        // No es necesario configurar nada aquí ya que Kingfisher se configura globalmente en la App
    }
    
    func execute(from url: URL) async throws -> Image {
        return try await withCheckedThrowingContinuation { continuation in
            KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success(let imageResult):
                    let image = Image(uiImage: imageResult.image)
                    continuation.resume(returning: image)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
} 