import Foundation
import Network

protocol NWPathMonitorProtocol: Sendable {
    func setUpdateHandler(_ handler: @escaping @Sendable (NWPath) -> Void)
    func start(queue: DispatchQueue)
    func cancel()
}

extension NWPathMonitor: NWPathMonitorProtocol {
    func setUpdateHandler(_ handler: @escaping @Sendable (NWPath) -> Void) {
        self.pathUpdateHandler = handler
    }
}

@MainActor
final class NetworkChecker: @unchecked Sendable {
    static var shared = NetworkChecker()
    private var pathMonitor: NWPathMonitorProtocol
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isConnected: Bool = false

    init(pathMonitor: NWPathMonitorProtocol = NWPathMonitor()) {
        self.pathMonitor = pathMonitor
        pathMonitor.setUpdateHandler { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        startMonitoring()
    }
    
    func startMonitoring() {
        pathMonitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        pathMonitor.cancel()
    }
} 