//
// NetworkMonitor.swift
// SharedKit
//
// Network reachability monitor
//

import Combine
import Network

public class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published public var isConnected = true
    @Published public var isExpensive = false

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }
}
