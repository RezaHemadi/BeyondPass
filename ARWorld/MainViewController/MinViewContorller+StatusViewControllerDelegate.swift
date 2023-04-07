//
//  MinViewContorller+StatusViewControllerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/7/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: StatusViewControllerDelegate {
    func statusViewController(_ viewController: StatusViewController, labelTapped text: String?) {
        switch appMode {
        case .sandbox:
            exitSandboxMode()
        case .portal:
            switch portal!.state {
            case .decorating:
                hidePortalDock()
                portal!.resumeAnimations()
                portal!.state = .placed
            default:
                if text == "Tap here to end Treasure placement." {
                    portal?.endTreasurePlacementMode()
                    statusViewController.setBackgroundColor(UIColor.black)
                    let now = DispatchTime.now()
                    let when = now + 2
                    DispatchQueue.main.asyncAfter(deadline: when) {
                        self.statusViewController.showMessage("Portal Mode - Tap To Close", autoHide: false)
                    }
                } else {
                    exitPortalMode()
                }
            }
        case .pinBoard:
            exitPinboardMode()
        default:
            break
        }
    }
}
