import Foundation
import AppKit

@objc(HAMacBridgeImpl) final class MacBridgeImpl: NSObject, MacBridge {
    let networkMonitor = MacBridgeNetworkMonitor()

    override init() {
        super.init()

        MacBridgeAppDelegateHandler.swizzleAppDelegate()
    }

    var terminationWillBeginNotification: Notification.Name {
        MacBridgeAppDelegateHandler.terminationWillBeginNotification
    }

    var distributedNotificationCenter: NotificationCenter {
        DistributedNotificationCenter.default()
    }

    var workspaceNotificationCenter: NotificationCenter {
        NSWorkspace.shared.notificationCenter
    }

    var networkConnectivity: MacBridgeNetworkConnectivity {
        networkMonitor.networkConnectivity
    }

    var networkConnectivityDidChangeNotification: Notification.Name {
        MacBridgeNetworkMonitor.connectivityDidChangeNotification
    }

    var screens: [MacBridgeScreen] {
        NSScreen.screens.map(MacBridgeScreenImpl.init(screen:))
    }

    var screensWillChangeNotification: Notification.Name {
        NSApplication.didChangeScreenParametersNotification
    }

    var frontmostApplication: MacBridgeRunningApplication? {
        NSWorkspace.shared.frontmostApplication
    }

    var frontmostApplicationDidChangeNotification: Notification.Name {
        NSWorkspace.didActivateApplicationNotification
    }

    var activationPolicy: MacBridgeActivationPolicy {
        get {
            switch NSApplication.shared.activationPolicy() {
            case .regular: return .regular
            case .accessory: return .accessory
            case .prohibited: return .prohibited
            @unknown default: return .regular
            }
        }
        set {
            NSApplication.shared.setActivationPolicy({
                switch newValue {
                case .regular: return .regular
                case .accessory: return .accessory
                case .prohibited: return .prohibited
                }
            }())
        }
    }
}

extension NSRunningApplication: MacBridgeRunningApplication {}
