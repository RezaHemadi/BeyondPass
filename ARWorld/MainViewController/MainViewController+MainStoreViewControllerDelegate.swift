//
//  MainViewController+MainStoreViewControllerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 8/8/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: MainStoreViewControllerDelegate {
    func mainStoreViewController(_ mainStoreViewController: MainStoreViewController, refreshARCoin: Bool) {
        self.arCoinLabel.text = PFUser.current()!["ARCoin"] as? String
    }
}
