//
//  NetworkMonitor.swift
//  SimplePayment
//
//  Monitors network connectivity and quality
//

import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = false
    @Published var connectionType: ConnectionType = .none
    @Published var connectionQuality: ConnectionQuality = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case none

        var description: String {
            switch self {
            case .wifi: return "WiFi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .none: return "No Connection"
            }
        }
    }

    enum ConnectionQuality {
        case excellent  // > 5 Mbps
        case good       // 1-5 Mbps
        case poor       // < 1 Mbps (2G/3G)
        case unknown
    }

    private init() {}

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied

                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                    self?.connectionQuality = .excellent
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                    self?.estimateCellularQuality()
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .ethernet
                    self?.connectionQuality = .excellent
                } else {
                    self?.connectionType = .none
                    self?.connectionQuality = .unknown
                }

                // Notify sync manager when connection returns
                if path.status == .satisfied {
                    NotificationCenter.default.post(name: .networkConnected, object: nil)
                }
            }
        }

        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func estimateCellularQuality() {
        // Simple estimation - in production, measure actual speed
        // For now, assume cellular is "good"
        connectionQuality = .good
    }

    var isLowBandwidth: Bool {
        connectionQuality == .poor
    }
}

extension Notification.Name {
    static let networkConnected = Notification.Name("networkConnected")
}
