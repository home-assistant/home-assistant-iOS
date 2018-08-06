//
//  WebViewController.swift
//  HomeAssistant
//
//  Created by Robert Trencheny on 4/10/17.
//  Copyright © 2017 Robbie Trencheny. All rights reserved.
//

import UIKit
import WebKit
import KeychainAccess
import PromiseKit

// swiftlint:disable:next type_body_length
class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, ConnectionInfoChangedDelegate {

    var webView: WKWebView!

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()
        let statusBarView: UIView = UIView(frame: .zero)
        statusBarView.tag = 111
        if let themeColor = prefs.string(forKey: "themeColor") {
            statusBarView.backgroundColor = UIColor.init(hex: themeColor)
        } else {
            statusBarView.backgroundColor = UIColor(red: 0.01, green: 0.66, blue: 0.96, alpha: 1.0)
        }
        view.addSubview(statusBarView)

        statusBarView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        statusBarView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        statusBarView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        statusBarView.bottomAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true

        statusBarView.translatesAutoresizingMaskIntoConstraints = false

        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        config.userContentController = userContentController

        webView = WKWebView(frame: self.view!.frame, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        self.updateWebViewSettings()
        self.view!.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false

        webView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true

        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        webView.scrollView.bounces = false

        HomeAssistantAPI.sharedInstance.Setup(baseURLString: keychain["baseURL"],
                                              password: keychain["apiPassword"],
                                              deviceID: keychain["deviceID"])
        if HomeAssistantAPI.sharedInstance.Configured {
            HomeAssistantAPI.sharedInstance.Connect().done {_ in
                if HomeAssistantAPI.sharedInstance.notificationsEnabled {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("Connected!")
                if let baseURL = HomeAssistantAPI.sharedInstance.baseURL {
                    let myRequest = URLRequest(url: baseURL)
                    self.webView.load(myRequest)
                }
                return
            }.catch {err -> Void in
                print("Error on connect!!!", err)
                self.openSettingsWithError(error: err)
            }
        } else {
            let settingsView = SettingsViewController()
            settingsView.doneButton = true
            settingsView.delegate = self
            let navController = UINavigationController(rootViewController: settingsView)
            self.present(navController, animated: true, completion: nil)
        }
    }

    // Workaround for webview rotation issues: https://github.com/Telerik-Verified-Plugins/WKWebView/pull/263
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.webView?.setNeedsLayout()
            self.webView?.layoutIfNeeded()
        }, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var barItems: [UIBarButtonItem] = []

        var tabBarIconColor = UIColor(red: 0.01, green: 0.66, blue: 0.96, alpha: 1.0)

        if let themeColor = prefs.string(forKey: "themeColor") {
            tabBarIconColor = UIColor.init(hex: themeColor)
            if let statusBarView = self.view.viewWithTag(111) {
                statusBarView.backgroundColor = UIColor.init(hex: themeColor)
            }
        }

        if HomeAssistantAPI.sharedInstance.locationEnabled {

            let uploadIcon = getIconForIdentifier("mdi:upload",
                                                  iconWidth: 30, iconHeight: 30,
                                                  color: tabBarIconColor)

            barItems.append(UIBarButtonItem(image: uploadIcon,
                                            style: .plain,
                                            target: self,
                                            action: #selector(sendCurrentLocation(_:))
                )
            )

            let mapIcon = getIconForIdentifier("mdi:map", iconWidth: 30, iconHeight: 30, color: tabBarIconColor)

            barItems.append(UIBarButtonItem(image: mapIcon,
                                            style: .plain,
                                            target: self,
                                            action: #selector(openMapView(_:))))
        }

        barItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

        barItems.append(UIBarButtonItem(barButtonSystemItem: .refresh, target: self,
                                            action: #selector(refreshWebView(_:))))

        let settingsIcon = getIconForIdentifier("mdi:settings", iconWidth: 30, iconHeight: 30, color: tabBarIconColor)

        barItems.append(UIBarButtonItem(image: settingsIcon,
                                        style: .plain,
                                        target: self,
                                        action: #selector(openSettingsView(_:))))

        self.setToolbarItems(barItems, animated: false)
        self.navigationController?.toolbar.tintColor = tabBarIconColor

        if HomeAssistantAPI.sharedInstance.Configured {
            if let baseURL = HomeAssistantAPI.sharedInstance.baseURL {
                let myRequest = URLRequest(url: baseURL)
                self.webView.load(myRequest)
            }
        }
    }

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            openURLInBrowser(urlToOpen: navigationAction.request.url!)
        }
        return nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failure during nav", error)
        if !error.isCancelled {
            openSettingsWithError(error: error)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Failure during content load", error)
        if !error.isCancelled {
            openSettingsWithError(error: error)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        let stop = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.refreshWebView(_:)))
        var removeAt = 2
        if self.toolbarItems?.count == 3 {
            removeAt = 1
        } else if self.toolbarItems?.count == 5 {
            removeAt = 3
        }
        var items = self.toolbarItems
        items?.remove(at: removeAt)
        items?.insert(stop, at: removeAt)
        self.setToolbarItems(items, animated: true)
    }

    // for basic auth, fixes #95
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        let authMethod = challenge.protectionSpace.authenticationMethod

        guard authMethod == NSURLAuthenticationMethodDefault ||
              authMethod == NSURLAuthenticationMethodHTTPBasic ||
              authMethod == NSURLAuthenticationMethodHTTPDigest else {
            print("Not handling auth method", authMethod)
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let space = challenge.protectionSpace

        let alert = UIAlertController(title: "\(space.`protocol`!)://\(space.host):\(space.port)",
            message: space.realm, preferredStyle: .alert)

        alert.addTextField {
            $0.placeholder = L10n.usernameLabel
        }

        alert.addTextField {
            $0.placeholder = L10n.Settings.ConnectionSection.ApiPasswordRow.title
            $0.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: L10n.cancelLabel, style: .cancel) { _ in
            completionHandler(.cancelAuthenticationChallenge, nil)
        })

        alert.addAction(UIAlertAction(title: L10n.okLabel, style: .default) { _ in
            let textFields = alert.textFields!
            let credential = URLCredential(user: textFields[0].text!,
                                           password: textFields[1].text!,
                                           persistence: .forSession)
            completionHandler(.useCredential, credential)
        })

        present(alert, animated: true, completion: nil)

    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        var removeAt = 2
        if self.toolbarItems?.count == 3 {
            removeAt = 1
        } else if self.toolbarItems?.count == 5 {
            removeAt = 3
        }
        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: self,
                                      action: #selector(self.refreshWebView(_:)))
        var items = self.toolbarItems
        items?.remove(at: removeAt)
        items?.insert(refresh, at: removeAt)
        self.setToolbarItems(items, animated: true)
    }

    @objc func refreshWebView(_ sender: UIBarButtonItem) {
        if self.webView.isLoading {
            self.webView.stopLoading()
        } else {
            self.webView.reload()
        }
    }

    func openSettingsWithError(error: Error) {
        let settingsView = SettingsViewController()
        settingsView.showErrorConnectingMessage = true
        settingsView.showErrorConnectingMessageError = error
        settingsView.doneButton = true
        settingsView.delegate = self
        let navController = UINavigationController(rootViewController: settingsView)
        self.present(navController, animated: true, completion: nil)
    }

    @objc func openSettingsView(_ sender: UIButton) {
        let settingsView = SettingsViewController()
        settingsView.doneButton = true
        settingsView.hidesBottomBarWhenPushed = true
        settingsView.delegate = self

        let navController = UINavigationController(rootViewController: settingsView)
        self.present(navController, animated: true, completion: nil)
    }

    @objc func openMapView(_ sender: UIButton) {
        let devicesMapView = DevicesMapViewController()

        let navController = UINavigationController(rootViewController: devicesMapView)
        self.present(navController, animated: true, completion: nil)
    }

    @objc func sendCurrentLocation(_ sender: UIButton) {
        HomeAssistantAPI.sharedInstance.getAndSendLocation(trigger: .Manual).done {_ in
            print("Sending current location via button press")
            let alert = UIAlertController(title: L10n.ManualLocationUpdateNotification.title,
                                          message: L10n.ManualLocationUpdateNotification.message,
                                          preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: L10n.okLabel, style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            }.catch {error in
                let nserror = error as NSError
                let message = L10n.ManualLocationUpdateFailedNotification.message(nserror.localizedDescription)
                let alert = UIAlertController(title: L10n.ManualLocationUpdateFailedNotification.title,
                                              message: message,
                                              preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: L10n.okLabel, style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
        }
    }

    func userReconnected() {
        print("User reconnected! Reset the web view!")
        updateWebViewSettings()
    }

    func updateWebViewSettings() {
        if let apiPass = keychain["apiPassword"] {
            self.webView.evaluateJavaScript("localStorage.getItem(\"authToken\")") { (result, error) in
                var storedPass = ""
                if result != nil, let resString = result as? String {
                    storedPass = resString
                }
                if error != nil || result == nil || storedPass != apiPass {
                    print("Setting password into LocalStorage")
                    self.webView.evaluateJavaScript("localStorage.setItem(\"authToken\", \"\(apiPass)\")") { (_, _) in
                        self.webView.reload()
                    }
                }
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
