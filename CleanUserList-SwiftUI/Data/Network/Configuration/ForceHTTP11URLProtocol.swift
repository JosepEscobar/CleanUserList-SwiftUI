import Foundation

@MainActor
final class ForceHTTP11URLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        // Interceptamos solo una vez para evitar bucles infinitos
        return URLProtocol.property(forKey: "HandledByForceHTTP11URLProtocol", in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Marcar como interceptado para no interceptar recursivamente
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return
        }
            
        URLProtocol.setProperty(true, forKey: "HandledByForceHTTP11URLProtocol", in: mutableRequest)
        let newRequest = mutableRequest as URLRequest

        // Crear una sesión con HTTP/1.1 forzado
        let config = URLSessionConfiguration.ephemeral
        config.httpAdditionalHeaders = ["Alt-Svc": ""] // Reforzar que no se usen servicios alternativos
        config.protocolClasses = [] // Eliminar este protocolo para evitar loops

        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        session.dataTask(with: newRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else {
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }.resume()
    }

    override func stopLoading() { }
} 
