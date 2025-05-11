import Foundation

final class ForceHTTP11URLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        // We intercept only once to avoid infinite loops
        return URLProtocol.property(forKey: "HandledByForceHTTP11URLProtocol", in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Mark as intercepted to avoid recursive interception
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return
        }
            
        URLProtocol.setProperty(true, forKey: "HandledByForceHTTP11URLProtocol", in: mutableRequest)
        let newRequest = mutableRequest as URLRequest

        // Create a session with forced HTTP/1.1
        let config = URLSessionConfiguration.ephemeral
        config.httpAdditionalHeaders = ["Alt-Svc": ""] // Reinforce that no alternative services are used
        config.protocolClasses = [] // Remove this protocol to avoid loops

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
