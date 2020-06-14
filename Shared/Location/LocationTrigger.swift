//
//  LocationTrigger.swift
//  Shared
//
//  Created by Stephan Vanterpool on 9/15/18.
//  Copyright © 2018 Robbie Trencheny. All rights reserved.
//

import CoreLocation
import Foundation
private let prefs = UserDefaults(suiteName: Constants.AppGroupID)!
public enum LocationUpdateTrigger: String {

    public struct NotificationOptions {
        public let shouldNotify: Bool
        public let identifier: String?
        public let title: String
        public let body: String
    }

    case RegionEnter = "Region Entered"
    case RegionExit = "Region Exited"
    case GPSRegionEnter = "Geographic Region Entered"
    case GPSRegionExit = "Geographic Region Exited"
    case BeaconRegionEnter = "iBeacon Region Entered"
    case BeaconRegionExit = "iBeacon Region Exited"
    case Manual = "Manual"
    case SignificantLocationUpdate = "Significant Location Change"
    case BackgroundFetch = "Background Fetch"
    case PushNotification = "Push Notification"
    case URLScheme = "URL Scheme"
    case XCallbackURL = "X-Callback-URL"
    case Siri = "Siri"
    case Visit = "Visit"
    case AppShortcut = "App Shortcut"
    case Unknown = "Unknown"

    func oneShotTimeout(maximum: TimeInterval?) -> TimeInterval {
        if let maximum = maximum {
            // the system appears to have given us a reasonable baseline, leave some time for network call
            return max(maximum - 5.0, 1.0)
        }

        switch self {
        case .RegionEnter, .RegionExit, .GPSRegionEnter, .GPSRegionExit, .BeaconRegionEnter, .BeaconRegionExit, .Visit:
            // location events, we've probably got a bit more freedom
            return 20.0
        case .SignificantLocationUpdate, .BackgroundFetch, .PushNotification:
            // background events we know are usually time sensitive
            return 10.0
        case .Manual, .URLScheme, .XCallbackURL, .AppShortcut, .Siri:
            // user is actively doing this, so wait a little longer
            return 30.0
        case .Unknown:
            return 10.0
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func notificationOptionsFor(zoneName: String) -> NotificationOptions {
        let shouldNotify: Bool
        var identifier: String = ""
        let body: String
        let title = L10n.LocationChangeNotification.title

        switch self {
        case .BeaconRegionEnter:
            body = L10n.LocationChangeNotification.BeaconRegionEnter.body(zoneName)
            identifier = "\(zoneName)_beacon_entered"
            shouldNotify = prefs.bool(forKey: "beaconEnterNotifications")
        case .BeaconRegionExit:
            body = L10n.LocationChangeNotification.BeaconRegionExit.body(zoneName)
            identifier = "\(zoneName)_beacon_exited"
            shouldNotify = prefs.bool(forKey: "beaconExitNotifications")
        case .GPSRegionEnter:
            body = L10n.LocationChangeNotification.RegionEnter.body(zoneName)
            identifier = "\(zoneName)_entered"
            shouldNotify = prefs.bool(forKey: "enterNotifications")
        case .GPSRegionExit:
            body = L10n.LocationChangeNotification.RegionExit.body(zoneName)
            identifier = "\(zoneName)_exited"
            shouldNotify = prefs.bool(forKey: "exitNotifications")
        case .SignificantLocationUpdate:
            body = L10n.LocationChangeNotification.SignificantLocationUpdate.body
            identifier = "sig_change"
            shouldNotify = prefs.bool(forKey: "significantLocationChangeNotifications")
        case .BackgroundFetch:
            body = L10n.LocationChangeNotification.BackgroundFetch.body
            identifier = "background_fetch"
            shouldNotify = prefs.bool(forKey: "backgroundFetchLocationChangeNotifications")
        case .PushNotification:
            body = L10n.LocationChangeNotification.PushNotification.body
            identifier = "push_notification"
            shouldNotify = prefs.bool(forKey: "pushLocationRequestNotifications")
        case .URLScheme:
            body = L10n.LocationChangeNotification.UrlScheme.body
            identifier = "url_scheme"
            shouldNotify = prefs.bool(forKey: "urlSchemeLocationRequestNotifications")
        case .XCallbackURL:
            body = L10n.LocationChangeNotification.XCallbackUrl.body
            identifier = "x_callback_url"
            shouldNotify = prefs.bool(forKey: "xCallbackURLLocationRequestNotifications")
        case .AppShortcut:
            body = L10n.LocationChangeNotification.AppShortcut.body
            shouldNotify = false
        case .Visit:
            body = L10n.LocationChangeNotification.Visit.body
            shouldNotify = false
        case .Manual:
            body = L10n.LocationChangeNotification.Manual.body
            shouldNotify = false
        case .Siri:
            body = L10n.LocationChangeNotification.Siri.body
            shouldNotify = false
        case .RegionExit, .RegionEnter, .Unknown:
            body = L10n.LocationChangeNotification.Unknown.body
            shouldNotify = false
        }

        return NotificationOptions(shouldNotify: shouldNotify, identifier: identifier, title: title, body: body)
    }
}
