//
//  MainViewController+UsersProfileDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/17/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: UsersProfileDelegate {
    func visitPortal(portal: ARPortal) {
        self.portal = portal
        
        self.appMode = .portal
        
        SurfacePlane.planes.forEach { ($0.isHidden = true) }
        shouldDetectPlanes = false
        
        portal.delegate = self
        
        portal.state = .preview
        portal.visiting = false
        
        portal.setupPreview({ (preview) in
            DispatchQueue.main.async {
                self.sceneView.scene.rootNode.addChildNode(preview!)
            }
        })
        targetingSticky = false
        targetingTemple = false
        removePopUpViews()
        
        statusViewController.showMessage("Portal Mode - Tap To Close", autoHide: false)
    }
}
