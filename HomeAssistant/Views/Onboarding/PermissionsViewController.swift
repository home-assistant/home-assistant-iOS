//
//  PermissionsViewController.swift
//  HomeAssistant
//
//  Created by Robert Trencheny on 4/20/19.
//  Copyright © 2019 Robbie Trencheny. All rights reserved.
//

import UIKit
import Shared
import MaterialComponents

class PermissionsViewController: UIViewController, PermissionViewChangeDelegate {
    var instance: DiscoveredHomeAssistant!
    var connectionInfo: ConnectionInfo!
    var tokenManager: TokenManager!

    @IBOutlet weak var continueButton: MDCButton!
    @IBOutlet weak var locationPermissionView: PermissionLineItemView!
    @IBOutlet weak var motionPermissionView: PermissionLineItemView!
    @IBOutlet weak var notificationsPermissionView: PermissionLineItemView!
    override func viewDidLoad() {
        super.viewDidLoad()

        if let navVC = self.navigationController as? OnboardingNavigationViewController {
            navVC.styleButton(self.continueButton)
        }

        self.locationPermissionView.delegate = self
        self.locationPermissionView.permission.updateInitial()

        self.motionPermissionView.delegate = self
        self.motionPermissionView.permission.updateInitial()

        self.notificationsPermissionView.delegate = self
        self.notificationsPermissionView.permission.updateInitial()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ConnectInstanceViewController {
            vc.instance = self.instance
            vc.connectionInfo = self.connectionInfo
            vc.tokenManager = self.tokenManager
        }
    }

    func statusChanged(_ forPermission: PermissionType, _ toStatus: PermissionStatus) {
        Current.Log.verbose("Permission \(forPermission.title) status changed to \(toStatus.description)")

        // Don't need to set .locationEnabled because it comes direct from CLLocationManager.
        if forPermission == .motion {
            Current.settingsStore.motionEnabled = toStatus == .authorized
        }
    }
}
