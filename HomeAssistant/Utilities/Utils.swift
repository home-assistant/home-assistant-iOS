//
//  Utils.swift
//  HomeAssistant
//
//  Created by Robbie Trencheny on 4/3/16.
//  Copyright © 2016 Robbie Trencheny. All rights reserved.
//

import Foundation
import KeychainAccess
import Shared
import RealmSwift
import SafariServices

func resetStores() {
    do {
        try keychain.removeAll()
    } catch {
        Current.Log.error("Error when trying to delete everything from Keychain!")
    }

    if let groupDefaults = UserDefaults(suiteName: Constants.AppGroupID) {
        for key in groupDefaults.dictionaryRepresentation().keys {
            groupDefaults.removeObject(forKey: key)
        }
        groupDefaults.synchronize()
    }

    Realm.reset()
}

func openURLInBrowser(_ urlToOpen: URL, _ view: UIViewController) {
    func fallback() {
        prefs.setValue(OpenInBrowser.Safari, forKey: "openInBrowser")
        prefs.synchronize()
        UIApplication.shared.open(urlToOpen, options: [:], completionHandler: nil)
        return
    }

    guard let browserPreference = prefs.object(forKey: "openInBrowser") as? OpenInBrowser else { fallback(); return }
    switch browserPreference {
    case .Chrome:
        if !OpenInChromeController.sharedInstance.isChromeInstalled() { fallback() }
        OpenInChromeController.sharedInstance.openInChrome(urlToOpen, callbackURL: nil)
        break
    case .Firefox:
        if !OpenInFirefoxControllerSwift().openInFirefox(urlToOpen) { fallback() }
        break
    case .SafariInApp:
        let sfv = SFSafariViewController(url: urlToOpen)
        view.present(sfv, animated: true)
    default:
        UIApplication.shared.open(urlToOpen, options: [:], completionHandler: nil)
        break
    }
}

func convertToDictionary(text: String) -> [String: Any]? {
    if let data = text.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            Current.Log.error("Error converting JSON string to dict: \(error)")
        }
    }
    return nil
}

func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message,
                                  preferredStyle: UIAlertController.Style.alert)
    alert.addAction(UIAlertAction(title: L10n.okLabel, style: UIAlertAction.Style.default, handler: nil))
    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true,
                                                                completion: nil)
}

func setDefaults() {
    if let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion"),
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString"),
        let stringedShortVersion = shortVersion as? String,
        let stringedBundleVersion = bundleVersion as? String {
        let combined = "\(stringedShortVersion) (\(stringedBundleVersion))"
        prefs.set(stringedBundleVersion, forKey: "lastInstalledBundleVersion")
        prefs.set(stringedShortVersion, forKey: "lastInstalledShortVersion")
        prefs.set(combined, forKey: "lastInstalledVersion")
    }

    if prefs.object(forKey: "openInBrowser") == nil {
        prefs.setValue(OpenInBrowser.Safari, forKey: "openInBrowser")
    }

    if prefs.bool(forKey: "openInChrome") {
        prefs.setValue(OpenInBrowser.Chrome, forKey: "openInBrowser")
    }

    if prefs.object(forKey: "confirmBeforeOpeningUrl") == nil {
        prefs.setValue(true, forKey: "confirmBeforeOpeningUrl")
    }

    if prefs.object(forKey: "locationUpdateOnZone") == nil {
        prefs.set(true, forKey: "locationUpdateOnZone")
    }

    if prefs.object(forKey: "locationUpdateOnBackgroundFetch") == nil {
        prefs.set(true, forKey: "locationUpdateOnBackgroundFetch")
    }

    if prefs.object(forKey: "locationUpdateOnSignificant") == nil {
        prefs.set(true, forKey: "locationUpdateOnSignificant")
    }

    if prefs.object(forKey: "locationUpdateOnNotification") == nil {
        prefs.set(true, forKey: "locationUpdateOnNotification")
    }

    if prefs.object(forKey: "analyticsEnabled") == nil {
        prefs.setValue(true, forKey: "analyticsEnabled")
    }

    if prefs.object(forKey: "messagingEnabled") == nil {
        prefs.setValue(true, forKey: "messagingEnabled")
    }

    prefs.synchronize()
}

extension UIImage {
    func scaledToSize(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}
