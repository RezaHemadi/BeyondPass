//
//  MainViewController+SkyWritingViewerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/26/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

extension MainViewController: SkyWritingViewerDelegate {
    func addSkyWriting(_ skyWriting: SkyWriting, for viewer: SkyWritingViewer) {
        let position = getPosition(userLocation: self.location, userHeading: self.userHeading, to: skyWriting.location)
        self.updateQueue.async {
            self.sceneView.addInfrontOfCamera(node: skyWriting, at: position)
            // Create a new anchor with the object's current transform and add it to the session
            let newAnchor = ARAnchor(transform: skyWriting.simdWorldTransform)
            skyWriting.anchor = newAnchor
            self.session.add(anchor: newAnchor)
        }
    }
}
