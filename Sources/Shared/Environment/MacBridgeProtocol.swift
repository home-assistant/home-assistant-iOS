import Foundation

// Must be @objc so we get the same reference in memory, since we're not directly loading the bundle
@objc(MacBridge) public protocol MacBridge: NSObjectProtocol {
    init()

    var distributedNotificationCenter: NotificationCenter { get }
    var workspaceNotificationCenter: NotificationCenter { get }

    var networkConnectivity: MacBridgeNetworkConnectivity { get }
    var networkConnectivityDidChangeNotification: Notification.Name { get }

    var terminationWillBeginNotification: Notification.Name { get }

    var screens: [MacBridgeScreen] { get }
    var screensWillChangeNotification: Notification.Name { get }
}

@objc(MacBridgeNetworkType) public enum MacBridgeNetworkType: Int {
    case ethernet
    case wifi
    case noNetwork
    case unknown
}

@objc(MacBridgeNetworkConnectivity) public protocol MacBridgeNetworkConnectivity: NSObjectProtocol {
    var networkType: MacBridgeNetworkType { get }
    var hasWiFi: Bool { get }
    var wifi: MacBridgeWiFi? { get }
    var interface: MacBridgeNetworkInterface? { get }
}

@objc(MacBridgeNetworkInterface) public protocol MacBridgeNetworkInterface: NSObjectProtocol {
    var name: String { get }
    var hardwareAddress: String { get }
}

@objc(MacBridgeWiFiConnectivity) public protocol MacBridgeWiFi: NSObjectProtocol {
    var ssid: String { get }
    var bssid: String { get }
}

@objc(MacBridgeScreen) public protocol MacBridgeScreen: NSObjectProtocol {
    var identifier: String { get }
    var name: String { get }
}
