//
//  AppDelegate.swift
//  HomeAssistant
//
//  Created by Robbie Trencheny on 3/25/16.
//  Copyright © 2016 Robbie Trencheny. All rights reserved.
//

import UIKit
import Intents
import UserNotifications
//import Fabric
//import Crashlytics
import PromiseKit
import AlamofireNetworkActivityIndicator
import KeychainAccess
import Alamofire
import RealmSwift
import Shared

let keychain = Keychain(service: "io.robbie.homeassistant")

let prefs = UserDefaults(suiteName: Constants.AppGroupID)!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        Fabric.with([Crashlytics.self])
        HomeAssistantAPI.sharedInstance.Setup(baseURLString: keychain["baseURL"], password: keychain["apiPassword"],
                                              deviceID: keychain["deviceID"])

        if prefs.bool(forKey: "locationUpdateOnBackgroundFetch") {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }

        NetworkActivityIndicatorManager.shared.isEnabled = true

        UNUserNotificationCenter.current().delegate = self

        if #available(iOS 12.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                guard settings.authorizationStatus == .authorized else {return}

                let opts: UNAuthorizationOptions = [.providesAppNotificationSettings, .criticalAlert]

                UNUserNotificationCenter.current().requestAuthorization(options: opts) { (granted, error) in
                    print("Requested critical alert access", granted, error)
                }
            }
        }

        if #available(iOS 12.0, *) {
            INPreferences.requestSiriAuthorization { (status) in
                print("Siri Authorization status", status)
            }
        }

        setDefaults()

        window = UIWindow.init(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white

        let webView = WebViewController()

        let navController = UINavigationController(rootViewController: webView)

        navController.setToolbarHidden(false, animated: false)
        navController.setNavigationBarHidden(true, animated: false)

        self.window!.rootViewController = navController
        self.window!.makeKeyAndVisible()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        let tokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})

        prefs.setValue(tokenString, forKey: "deviceToken")

        print("Registering push with tokenString: \(tokenString)")

        _ = HomeAssistantAPI.sharedInstance.RegisterDeviceForPush(deviceToken: tokenString).done { resp in
            if let pushId = resp.PushId {
                print("Registered for push. Platform: \(resp.SNSPlatform ?? "MISSING"), PushID: \(pushId)")
//                CLSLogv("Registered for push %@:", getVaList([pushId]))
                // TO-DO Crashlytics.sharedInstance().setUserIdentifier(pushId)
                prefs.setValue(pushId, forKey: "pushID")
                HomeAssistantAPI.sharedInstance.pushID = pushId
                _ = HomeAssistantAPI.sharedInstance.IdentifyDevice()
            }
        }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Swift.Error) {
        print("Error when trying to register for push", error)
        // TO-DO Crashlytics.sharedInstance().recordError(error)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Received remote notification in completion handler!")

        if let userInfoDict = userInfo as? [String: Any],
            let hadict = userInfoDict["homeassistant"] as? [String: String], let command = hadict["command"] {
                    switch command {
                    case "request_location_update":
                        if prefs.bool(forKey: "locationUpdateOnNotification") == false {
                            completionHandler(UIBackgroundFetchResult.noData)
                        }
                        print("Received remote request to provide a location update")
                        HomeAssistantAPI.sharedInstance.Setup(baseURLString: keychain["baseURL"],
                                                              password: keychain["apiPassword"],
                                                              deviceID: keychain["deviceID"])
                        HomeAssistantAPI.sharedInstance.getAndSendLocation(trigger: .PushNotification).done { success in
                            print("Did successfully send location when requested via APNS?", success)
                            if success == true {
                                completionHandler(UIBackgroundFetchResult.newData)
                            } else {
                                completionHandler(UIBackgroundFetchResult.failed)
                            }
                        }.catch {error in
                            print("Error when attempting to submit location update")
                            // TO-DO Crashlytics.sharedInstance().recordError(error)
                            completionHandler(UIBackgroundFetchResult.failed)
                        }
                    default:
                        print("Received unknown command via APNS!", userInfo)
                        completionHandler(UIBackgroundFetchResult.noData)
                    }
        } else {
            completionHandler(UIBackgroundFetchResult.failed)
        }
    }

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if prefs.bool(forKey: "locationUpdateOnBackgroundFetch") == false {
            completionHandler(UIBackgroundFetchResult.noData)
        }
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .full)
        print("Background fetch activated at \(timestamp)!")
        HomeAssistantAPI.sharedInstance.Setup(baseURLString: keychain["baseURL"], password: keychain["apiPassword"],
                                              deviceID: keychain["deviceID"])
        if HomeAssistantAPI.sharedInstance.locationEnabled {
            HomeAssistantAPI.sharedInstance.getAndSendLocation(trigger: .BackgroundFetch).done { success in
                print("Sending location via background fetch")
                if success == true {
                    completionHandler(UIBackgroundFetchResult.newData)
                } else {
                    completionHandler(UIBackgroundFetchResult.failed)
                }
                }.catch {error in
                    print("Error when attempting to submit location update during background fetch")
                    // TO-DO Crashlytics.sharedInstance().recordError(error)
                    completionHandler(UIBackgroundFetchResult.failed)
            }
        } else {
            HomeAssistantAPI.sharedInstance.IdentifyDevice().done { _ in
                completionHandler(UIBackgroundFetchResult.newData)
            }.catch {error in
                print("Error when attempting to identify device during background fetch")
                // TO-DO Crashlytics.sharedInstance().recordError(error)
                completionHandler(UIBackgroundFetchResult.failed)
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        HomeAssistantAPI.sharedInstance.Setup(baseURLString: keychain["baseURL"], password: keychain["apiPassword"],
                                              deviceID: keychain["deviceID"])
        var serviceData: [String: String] = [:]
        if let queryItems = url.queryItems {
            serviceData = queryItems
        }
        switch url.host! {
        case "call_service": // homeassistant://call_service/device_tracker.see?entity_id=device_tracker.entity
            let domain = url.pathComponents[1].components(separatedBy: ".")[0]
            let service = url.pathComponents[1].components(separatedBy: ".")[1]

            if #available(iOS 12.0, *) {
                let intent = CallServiceIntent()
                intent.serviceName = url.pathComponents[1]
                intent.serviceData = url.query

                let interaction = INInteraction(intent: intent, response: nil)

                interaction.donate { (error) in
                    if error != nil {
                        if let error = error as NSError? {
                            print("CallService Interaction donation failed: \(error)")
                        } else {
                            print("CallService Successfully donated interaction")
                        }
                    }
                }
            }

            HomeAssistantAPI.sharedInstance.CallService(domain: domain, service: service,
                                                        serviceData: serviceData).done { _ in
                showAlert(title: L10n.UrlHandler.CallService.Success.title,
                          message: L10n.UrlHandler.CallService.Success.message(url.pathComponents[1]))
            }.catch { error in
                showAlert(title: L10n.UrlHandler.Error.title,
                          message: L10n.UrlHandler.CallService.Error.message(url.pathComponents[1],
                                                                             error.localizedDescription))
            }
        case "fire_event": // homeassistant://fire_event/custom_event?entity_id=device_tracker.entity

            if #available(iOS 12.0, *) {
                let intent = FireEventIntent()
                intent.eventName = url.pathComponents[1]
                intent.eventData = url.query

                let interaction = INInteraction(intent: intent, response: nil)

                interaction.donate { (error) in
                    if error != nil {
                        if let error = error as NSError? {
                            print("FireEvent Interaction donation failed: \(error)")
                        } else {
                            print("FireEvent Successfully donated interaction")
                        }
                    }
                }
            }

            HomeAssistantAPI.sharedInstance.CreateEvent(eventType: url.pathComponents[1],
                                                        eventData: serviceData).done { _ in
                showAlert(title: L10n.UrlHandler.FireEvent.Success.title,
                          message: L10n.UrlHandler.FireEvent.Success.message(url.pathComponents[1]))
            }.catch { error -> Void in
                showAlert(title: L10n.UrlHandler.Error.title,
                          message: L10n.UrlHandler.FireEvent.Error.message(url.pathComponents[1],
                                                                           error.localizedDescription))
            }
        case "send_location": // homeassistant://send_location/
            HomeAssistantAPI.sharedInstance.getAndSendLocation(trigger: .URLScheme).done { _ in
                showAlert(title: L10n.UrlHandler.SendLocation.Success.title,
                          message: L10n.UrlHandler.SendLocation.Success.message)
            }.catch { error in
                showAlert(title: L10n.UrlHandler.Error.title,
                          message: L10n.UrlHandler.SendLocation.Error.message(error.localizedDescription))
            }
        default:
            print("Can't route", url.host!)
            showAlert(title: L10n.UrlHandler.Error.title,
                      message: L10n.UrlHandler.NoService.message(url.host!))
        }
        return true
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        HomeAssistantAPI.sharedInstance.Setup(baseURLString: keychain["baseURL"], password: keychain["apiPassword"],
                                              deviceID: keychain["deviceID"])
        var userText: String?
        if let textInput = response as? UNTextInputNotificationResponse {
            userText = textInput.userText
        }
        let userInfo = response.notification.request.content.userInfo
        if let openUrl = userInfo["url"] as? String,
            let url = URL(string: openUrl) {
            if prefs.bool(forKey: "confirmBeforeOpeningUrl") {
                let alert = UIAlertController(title: L10n.Alerts.OpenUrlFromNotification.title,
                                              message: L10n.Alerts.OpenUrlFromNotification.message(openUrl),
                                              preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: L10n.noLabel, style: UIAlertAction.Style.default, handler: nil))
                alert.addAction(UIAlertAction(title: L10n.yesLabel, style: UIAlertAction.Style.default, handler: { _ in
                    UIApplication.shared.open(url, options: [:],
                                              completionHandler: nil)
                }))
                var rootViewController = UIApplication.shared.keyWindow?.rootViewController
                if let navigationController = rootViewController as? UINavigationController {
                    rootViewController = navigationController.viewControllers.first
                }
                if let tabBarController = rootViewController as? UITabBarController {
                    rootViewController = tabBarController.selectedViewController
                }
                rootViewController?.present(alert, animated: true, completion: nil)
            } else {
                UIApplication.shared.open(url, options: [:],
                                          completionHandler: nil)
            }
        }
        HomeAssistantAPI.sharedInstance.handlePushAction(identifier: response.actionIdentifier,
                                                         userInfo: userInfo,
                                                         userInput: userText).done { _ in
                                                            completionHandler()
            }.catch { err -> Void in
                print("Error: \(err)")
                // TO-DO Crashlytics.sharedInstance().recordError(err)
                completionHandler()
        }
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       // swiftlint:disable:next line_length
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        var methods: UNNotificationPresentationOptions = [.alert, .badge, .sound]
        if let presentationOptions = notification.request.content.userInfo["presentation_options"] as? [String] {
            methods = []
            if presentationOptions.contains("sound") || notification.request.content.sound != nil {
                methods.insert(.sound)
            }
            if presentationOptions.contains("badge") {
                methods.insert(.badge)
            }
            if presentationOptions.contains("alert") {
                methods.insert(.alert)
            }
        }
        return completionHandler(methods)
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       openSettingsFor notification: UNNotification?) {
        let view = SettingsDetailViewController()
        view.detailGroup = "notifications"
        view.doneButton = true

        var rootViewController = UIApplication.shared.keyWindow?.rootViewController
        if let navigationController = rootViewController as? UINavigationController {
            rootViewController = navigationController.viewControllers.first
        }
        if let tabBarController = rootViewController as? UITabBarController {
            rootViewController = tabBarController.selectedViewController
        }

        let navController = UINavigationController(rootViewController: view)

        rootViewController?.present(navController, animated: true, completion: nil)
    }
}
